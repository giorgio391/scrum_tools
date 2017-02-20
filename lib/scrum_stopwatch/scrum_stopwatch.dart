import 'dart:html';
import 'package:angular2/core.dart';

import 'model/timer_stopwatch.dart';
import 'stopwatch_pipe.dart';

/// This class provides a countdown stop watch web component.
///
/// As part of the component there are controls to let the user
/// start, stop, pause, reset, reset current and 'go to the next'.
/// These controls are hooked to the corresponding methods that, in turns,
/// trigger the corresponding events that can be 'subscribed' from outside the
/// component.
@Component(selector: 'stop-watch',
    templateUrl: 'scrum_stopwatch.html',
    styleUrls: const ['scrum_stopwatch.css'],
    pipes: const [StopwatchPipe])
class ScrumStopwatch implements OnInit {

  /// HTML audio element with the sound for the _horn_.
  @Input()
  AudioElement hornAudio;

  /// HTML audio element with the sound for the _alert_.
  @Input()
  AudioElement alertAudio;

  /// Threshold for the _horn_ to be played, in milliseconds.
  @Input()
  int hornThreshold;

  /// Threshold for the _alert_ to be played, in milliseconds.
  @Input()
  int alertThreshold;

  /// HTML audio element with the sound for the initial _beep_.
  @Input()
  AudioElement beepAudio;

  /// The initial number of milliseconds to start the countdown.
  @Input()
  int targetUnitDuration;

  /// A [DurationProvider] to get the offset upon _next_ events.
  @Input()
  DurationProvider startOffsetProvider;

  /// Before _next_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> beforeNext = new EventEmitter<
      ScrumStopwatch>(false);

  /// _Start_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> startAction = new EventEmitter<
      ScrumStopwatch>(false);

  /// _Stop_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> stopAction = new EventEmitter<
      ScrumStopwatch>(false);

  /// _Reset_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> resetAction = new EventEmitter<
      ScrumStopwatch>(false);

  /// _Reset current_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> resetCurrentAction = new EventEmitter<
      ScrumStopwatch>(false);

  /// _Pause_ event emitter.
  @Output()
  final EventEmitter<ScrumStopwatch> pauseAction = new EventEmitter<
      ScrumStopwatch>(false);

  _ScrumStopwatchDelegate _delegate = new _ScrumStopwatchDelegate();

  /// Initialize the component.
  void ngOnInit() {
    _delegate = new _ScrumStopwatchInitializedDelegate(this,
        targetUnitDuration, beepAudio, hornAudio, hornThreshold, alertAudio,
        alertThreshold);
  }

  /// [true] if the stopwatch has been already started, false otherwise.
  bool get started => _delegate.started;

  /// [true] if the stopwatch has been already initialized, false otherwise.
  bool get initialized => _delegate.initialized;

  /// The initial [Duration] for the stopwatch.
  Duration get unitDuration => _delegate.unitDuration;

  /// The [Duration] currently left.
  Duration get unitLeftDuration => _delegate.unitLeftDuration;

  /// Net (without paused time) total [Duration] of this stopwatch since it
  /// was started.
  Duration get netDuration => _delegate.netDuration;

  /// Total [Duration] of this stopwatch since it was started.
  Duration get grossDuration => _delegate.grossDuration;

  /// [true] if this stopwatch is currently paused, [false] otherwise.
  bool get paused => _delegate.paused;

  /// Method that triggers the _start_ event.
  void start() {
    _delegate.start();
    startAction.add(this);
  }

  /// Method that triggers the _stop_ event.
  void stop() {
    _delegate.stop();
    stopAction.add(this);
  }

  /// Method that triggers the _reset_ event.
  void reset() {
    _delegate.reset();
    resetAction.add(this);
  }

  /// Method that triggers the _reset current_ event.
  void resetCurrent() {
    _delegate.resetCurrent();
    resetCurrentAction.add(this);
  }

  /// Method that triggers the _next_ event.
  void next() {
    beforeNext.add(this);
    _delegate.next();
  }

  /// Method that triggers the _toggle pause_ event.
  void togglePause() {
    _delegate.togglePause();
    pauseAction.add(this);
  }
}

class _ScrumStopwatchDelegate {

  static const Duration DURATION_0 = const Duration();

  bool get initialized => false;

  bool get started => false;

  Duration get unitDuration => DURATION_0;

  Duration get unitLeftDuration => DURATION_0;

  Duration get netDuration => DURATION_0;

  Duration get grossDuration => DURATION_0;

  bool get paused => false;

  void start() {}

  void stop() {}

  void reset() {}

  void resetCurrent() {}

  void next() {}

  void togglePause() {}
}

class _ScrumStopwatchInitializedDelegate extends _ScrumStopwatchDelegate {

  final AudioElement _beepAudio;

  final TimeStopWatch _tsw = new TimeStopWatch();
  Duration _targetUnitDuration;
  final Stopwatch _gross = new Stopwatch(),
      _net = new Stopwatch();
  final List<_AudioItem> _audioItems = new List<_AudioItem>();

  final ScrumStopwatch parent;

  _ScrumStopwatchInitializedDelegate(this.parent, int targetUnitDuration,
      this._beepAudio,
      AudioElement hornAudio, int hornTreshold,
      AudioElement alertAudio, int alertTreshold) {
    _targetUnitDuration = new Duration(seconds: targetUnitDuration);
    if (hornAudio != null) {
      _audioItems.add(new _AudioItem(this, hornAudio, hornTreshold));
    }
    if (alertAudio != null) {
      _audioItems.add(new _AudioItem(this, alertAudio, alertTreshold));
    }
  }

  @override
  bool get initialized => true;

  bool get started => _gross.isRunning;

  @override
  Duration get unitLeftDuration => _targetUnitDuration - _tsw.elapsed;

  @override
  Duration get unitDuration => _tsw.elapsed;

  @override
  Duration get netDuration => _net.elapsed;

  @override
  Duration get grossDuration => _gross.elapsed;

  @override
  bool get paused => _tsw.paused;

  @override
  void start() {
    _audioItems.forEach((item) => item.reset());
    _beepAudio?.play();
    _gross.reset();
    _net.reset();
    _gross.start();
    _net.start();
    _tsw.start(new Duration(seconds: 1), _timeChanged, startOffset);
  }

  @override
  void stop() {
    _audioItems.forEach((item) => item.reset());
    _tsw.stop();
    _gross.stop();
    _net.stop();
  }

  @override
  void reset() {
    stop();
    start();
  }

  @override
  void resetCurrent() {
    if (started) {
      _tsw.start(new Duration(seconds: 1), _timeChanged);
      _audioItems.forEach((item) => item.reset());
    }
  }

  @override
  void next() {
    if (!started) {
      start();
    } else {
      if (_tsw.paused) _net.start();
      _tsw.start(new Duration(seconds: 1), _timeChanged, startOffset);
      _audioItems.forEach((item) => item.reset());
      _beepAudio?.play();
    }
  }

  Duration get startOffset {
    return parent.startOffsetProvider ==  null ? null : parent.startOffsetProvider();
  }

  @override
  void togglePause() {
    if (!started) {
      start();
    } else {
      if (_tsw.paused) {
        _net.start();
      } else {
        _net.stop();
      }
      _tsw.togglePause();
    }
  }

  void _timeChanged() {
    _audioItems.forEach((item) => item.check());
  }

}

class _AudioItem {

  _ScrumStopwatchDelegate _scrumStopwatch;
  AudioElement _audioElement;
  bool _alreadyPlayed = false;
  int _treshold;

  _AudioItem(this._scrumStopwatch, this._audioElement, this._treshold);

  void check() {
    if (_audioElement != null && !_alreadyPlayed &&
        _scrumStopwatch.unitLeftDuration.inMilliseconds < _treshold) {
      _alreadyPlayed = true;
      _audioElement.play();
    }
  }

  void reset() {
    if (_audioElement != null) {
      if (_alreadyPlayed) _audioElement.pause();
      _audioElement.currentTime = 0;
    }
    _alreadyPlayed = false;
  }


}

typedef Duration DurationProvider();