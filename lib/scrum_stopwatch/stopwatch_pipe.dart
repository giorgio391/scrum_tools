import 'package:angular2/core.dart';

/// Pipe to format [Duration] objects as MM:SS (MM-> minutes, SS->seconds).
@Pipe(name: 'stopwatch')
class StopwatchPipe extends PipeTransform {
  /// Perform the transformation. If the provided value is not a [Duration] it
  /// returns '--:--'.
  String transform(val, [List args]) {
    if (val is! Duration) {
      return "-:-";
    }

    final Duration duration = val;

    String twoDigitMinutes = twoDigits(
        duration.inMinutes.abs().remainder(Duration.MINUTES_PER_HOUR));
    String twoDigitSeconds = twoDigits(
        duration.inSeconds.abs().remainder(Duration.SECONDS_PER_MINUTE));
    String sign = duration.isNegative ? "-" : "";
    return "$sign$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Returns a two digits string form an integer, prepending '0' if needed.
  static String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

}