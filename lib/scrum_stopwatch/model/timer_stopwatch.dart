import 'dart:async';

/// This is an utility class for firing _tic tac_ events to be consumed by any
/// time aware client code.
///
/// The client code should provide a [Duration] to specify the frequency and a
/// callback function.
///
/// Internally it uses a [Timer].
class TimeStopWatch {

  static const int _MAGIC = 5;

  /// This is the default duration used if a [null] is provided.
  static const Duration DEFAULT_DURATION = const Duration(seconds: 1);

  Timer _timer;
  bool _paused = false;
  Stopwatch _stopwatch = new Stopwatch();

  /// Indicates if the stopwatch model is currently paused.
  bool get paused => _paused;

  /// Indicates the total running time since the start (including the initial
  /// offset, if any). Paused time does not count.
  Duration get elapsed =>
      _offset == null ?
      _stopwatch.elapsed : _stopwatch.elapsed + _offset;

  Duration _offset;

  /// Starts the stopwatch model and reset its current internal state.
  ///
  /// [duration] provides how much time should pass between every single
  /// callback event. [callback()] is the function that will be called to
  /// notify each event. [offset] is an optional parameter that defines the
  /// initial start time.
  void start(Duration duration, void callback(), [Duration offset]) {
    _offset = offset;
    _timer?.cancel();
    _paused = false;
    if (duration == null || duration.inMilliseconds < _MAGIC) {
      duration = DEFAULT_DURATION;
    }
    Duration interval = new Duration(
        milliseconds: (duration.inMilliseconds / _MAGIC).round());
    _stopwatch.reset();
    _stopwatch.start();
    DateTime lastCallback = new DateTime.now();
    callback();
    _timer = new Timer.periodic(interval, (Timer timer) {
      DateTime now = new DateTime.now();
      if (callback != null && !_paused &&
          now.difference(lastCallback) >= duration) {
        lastCallback = now;
        callback();
      }
    });
  }

  /// Stops the stopwatch model.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    _paused = false;
  }

  /// Toggle pause on/off.
  void togglePause() {
    _paused = !_paused;
    if (_paused)
      _stopwatch.stop();
    else
      _stopwatch.start();
  }
}