import 'dart:async';

RegExp _durationRegExp = new RegExp(
    r'^[0-9]:[0-9][0-9]:[0-9][0-9]\.[0-9][0-9][0-9][0-9][0-9][0-9]$');
RegExp _splitDurationRegExp = new RegExp(r':|\.');

RegExp _splitCLSExp = new RegExp(r'\s*,\s*'); // Comma Separated List
List<String> asList(String string) =>
    string == null ? null : string.split(_splitCLSExp);

Duration parseDuration(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    String string = value as String;
    if (!_durationRegExp.hasMatch(string)) throw new FormatException(
        "Format not feasible for a 'Duration' [${value}]");
    List<String> parts = string.split(_splitDurationRegExp);
    return new Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
        microseconds: int.parse(parts[3])
    );
  }
  if (value is int) {
    return new Duration(microseconds: (value as int));
  }
  if (value is double) {
    return new Duration(microseconds: (value as double).round());
  }
  throw new FormatException(
      "Value not feasible for a 'Duration' [${value.runtimeType
          .toString()}, ${value.toString()}].");
}

bool hasValue(dynamic value) {
  if (value == null) return false;
  if (value is String) return (value as String).isNotEmpty;
  if (value is Iterable) return (value as Iterable).isNotEmpty;
  if (value is Map) return (value as Map).isNotEmpty;
  throw new ArgumentError.value(value, 'value', 'Value type not supported.');
}

class ChangeRecord<T> {

  T _oldValue;
  T _currentValue;

  T get oldValue => _oldValue;

  T get newValue => _currentValue;

  ChangeRecord(this._oldValue, this._currentValue);
}

abstract class Mappable {
  Map<String, dynamic> toMap();
}

abstract class MappableWithDate extends Mappable {
  DateTime get date;
}

abstract class ScrumHttpClient {

  Future<String> getString(String url);

  String handleError(dynamic error);

  void close({bool force});

}

