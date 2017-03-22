class ChangeRecord <T> {

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