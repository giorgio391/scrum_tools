import 'dart:async';

/// Typedef to define functions to retrieve values from the original
/// repository by their keys.
typedef Future<V> Retriever<K, V> (K key);

/// This class supports cache implementation.
/// A not [null] retriever must be provided using the [retriever] property
/// after construction.
class Cache<K, V> {

  Map<K, V> _map = new Map<K, V>();

  Retriever<K, V> _retriever;

  Cache();

  Cache.ready(this._retriever);

  void set retriever(Retriever<K, V> newRetriever) {
    _retriever = newRetriever;
  }

  /// Get the value from the cache. If it is not in the cache yet an attempt
  /// to retrieve it from the original repository will be done.
  Future<V> get(K key) {
    if (!_map.containsKey(key)) {
      if (_retriever == null) return null;
      Completer<V> completer = new Completer<V>();
      _retriever(key).then((V value) {
        if (value != null) {
          _map[key] = value;
          completer.complete(value);
        } else {
          completer.completeError('No value found for [${key}]!');
        }
      }).catchError((error) {
        completer.completeError(error);
      });
      return completer.future;
    }
    return new Future.value(_map[key]);
  }

  /// Clear all cached items.
  void clearCache() {
    _map.clear();
  }

  /// Clear the specified key and its associated value from the cache.
  /// Returns the value cached if any, [null] otherwise.
  V clearItem(K key) {
    return _map.remove(key);
  }

  /// Put the item into the cache replacing it if necessary as long as
  /// the key and the item are not [null].
  void cacheItem(K key, V item) {
    if (key != null && item != null) {
      _map[key] = item;
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

}
