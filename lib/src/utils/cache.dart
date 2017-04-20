import 'dart:async';

import 'package:logging/logging.dart';

/// Typedef to define functions to retrieve values from the original
/// repository by their keys.
typedef Future<V> Retriever<K, V> (K key);

/// This class supports cache implementation.
/// A not [null] retriever must be provided using the [retriever] property
/// after construction.
class Cache<K, V> {

  Map<K, V> _map = new Map<K, V>();

  Retriever<K, V> _retriever;

  CacheListener _listener;

  Cache({CacheListener listener: noOpsCacheListener}) {
    _listener = listener;
  }

  Cache.ready(this._retriever,
      {CacheListener listener: noOpsCacheListener}) {
    _listener = listener;
    _listener.ready(this);
  }

  void set retriever(Retriever<K, V> newRetriever) {
    _retriever = newRetriever;
    _listener.ready(this);
  }

  /// Get the value from the cache. If it is not in the cache yet an attempt
  /// to retrieve it from the original repository will be done.
  Future<V> get(K key) {
    if (!_map.containsKey(key)) {
      if (_retriever == null) return null;
      Completer<V> completer = new Completer<V>();
      _retriever(key).then((V value) {
        if (value != null) {
          cacheItem(key, value);
          completer.complete(value);
        } else {
          completer.completeError('No value found for [${key}]!');
        }
      }).catchError((error) {
        completer.completeError(error);
      });
      return completer.future;
    }
    V value = _map[key];
    _listener.keyAccess(key, value);
    return new Future.value(value);
  }

  /// Clear all cached items.
  void clearCache() {
    _map.clear();
    _listener.cacheCleared();
  }

  /// Clear the specified key and its associated value from the cache.
  /// Returns the value cached if any, [null] otherwise.
  V clearItem(K key) {
    V v = _map.remove(key);
    _listener.keyCleared(key, v);
    return v;
  }

  /// Put the item into the cache replacing it if necessary as long as
  /// the key and the item are not [null].
  void cacheItem(K key, V item) {
    if (key != null && item != null) {
      V oldValue = _map[key];
      _map[key] = item;
      if (oldValue != null) _listener.keyCleared(key, oldValue);
      _listener.keyCached(key, item);
    }
  }

  /// Asynchronously put the item into the cache replacing it if necessary as
  /// long as the key and the item are not [null].
  void cacheItemAsync(K key, Future<V> future) {
    if (key != null && future != null) {
      future.then((V item) {
        cacheItem(key, item);
      });
    }
  }

  /// Returns the total number os cached items.
  int get count => _map.length;

  /// Get the value from the cache. If it is not in the cache yet
  /// [null] is returned.
  V getCached(K key) {
    if (key != null) {
      V value = _map[key];
      _listener.keyAccess(key, value);
      return value;
    }
    return null;
  }

  /// Same as [getCached].
  V operator [](K key) => getCached(key);

  /// Same as [cacheItem].
  void operator []=(K key, V item) => cacheItem(key, item);
}

const CacheListener noOpsCacheListener = const _NoOpListener();

class _NoOpListener<K, V> implements CacheListener <K, V> {

  const _NoOpListener();

  void ready(Cache<K, V> cache) {}

  void keyCached(K key, V value) {}

  void keyAccess(K key, V value) {}

  void keyCleared(K key, V value) {}

  void cacheCleared() {}
}


abstract class CacheListener<K, V> {

  void ready(Cache<K, V> cache);

  void keyCached(K key, V value);

  void keyAccess(K key, V value);

  void keyCleared(K key, Value);

  void cacheCleared();
}

const Duration defaultEvictTimeout = const Duration(minutes: 20);
const Duration defaultEvictFrequency = const Duration(minutes: 2);

class CachedTimeoutEvict<K, V> implements CacheListener <K, V> {

  static const String loggerName = "cache-cached-timeout";

  Logger _log = new Logger(loggerName);

  Cache <K, V> _cache;

  Duration _timeout;
  Duration _frequency;
  List<K> _queue;
  Map<K, DateTime> _referenceTime;
  bool _paused = false;
  String _name;

  DateTime _lastEvictCycle;

  CachedTimeoutEvict(
      {Duration timeout: defaultEvictTimeout, Duration frequency: defaultEvictFrequency, String name: r'CachedTimeoutEvict'}) {
    this._timeout = timeout;
    this._frequency = frequency;
    this._name = name;
  }

  String get name => _name;

  bool get paused => _paused;

  void stop() {
    paused = true;
  }

  void set paused(bool val) {
    _paused = val;
    if (!val) _evict();
    _log.fine(() => '${_name} pause status: ${_paused}');
  }

  @override
  void ready(Cache<K, V> cache) {
    _cache = cache;
    _referenceTime = new Map<K, DateTime>();
    _queue = [];
    _lastEvictCycle = new DateTime.now();
    _evict();
  }

  @override
  void keyCached(K key, V value) {
    _referenceTime[key] = new DateTime.now();
    _queue.add(key);
    _log.fine(() => '${_name}: Key ${key} cached at ${new DateTime.now()
        .toIso8601String()}');
  }

  @override
  void keyAccess(K key, V value) {
    _log.fine(() => '${_name}: Key ${key} access at ${new DateTime.now()
        .toIso8601String()}');
  }

  @override
  void keyCleared(K key, V value) {
    _referenceTime.remove(key);
    _queue.remove(key);
    _log.fine(() => '${_name}: Key ${key} cleared at ${new DateTime.now()
        .toIso8601String()}');
  }
  @override
  void cacheCleared() {
    _referenceTime.clear();
    _queue.clear();
    _log.fine(() => '${_name}: Cache cleared at ${new DateTime.now()
        .toIso8601String()}');
  }

  void _evict() {
    if (!paused) {
      try {
        DateTime now = new DateTime.now();
        if (now.difference(_lastEvictCycle) > _frequency) {
          _log.fine(() => '${_name} evict cycle at ${new DateTime.now()
              .toIso8601String()}');
          _lastEvictCycle = now;
          List<K> toEvict = _toEvict(now);
          new Future(() {
            toEvict.forEach((K key) {
              new Future(() {
                _log.fine(() => '${_name} evicts key ${key} at ${new DateTime
                    .now().toIso8601String()}');
                _cache.clearItem(key);
              });
            });
          });
        }
      } finally {
        if (!paused) {
          new Future(_evict);
        }
      }
    } else {
      _log.fine(() => '${_name} evict skip at ${new DateTime.now()
          .toIso8601String()}');
    }
  }

  List<K> _toEvict(DateTime now) {
    List<K> toEvict = [];
    for (K key in _queue) {
      DateTime time = _referenceTime[key];
      if (now.difference(time) > _timeout) {
        toEvict.add(key);
      } else {
        break;
      }
    }
    return toEvict;
  }
}

class AccessTimeoutEvict<K, V> extends CachedTimeoutEvict <K, V> {

  AccessTimeoutEvict(
      {Duration timeout: defaultEvictTimeout, Duration frequency: defaultEvictFrequency, String name: r'AccessTimeoutEvict'})
      : super(timeout: timeout, frequency: frequency, name: name);

  @override
  void keyAccess(K key, V value) {
    super.keyAccess(key, value);
    _referenceTime[key] = new DateTime.now();
    _queue.remove(key);
    _queue.add(key);
  }

}