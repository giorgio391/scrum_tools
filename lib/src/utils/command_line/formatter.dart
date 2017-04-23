import 'dart:io' show stdout, stderr;

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

String formatDate(DateTime date) {
  if (date != null) {
    String s = "${date.day < 10 ? r'0' : r''}${date.day}-"
        "${date.month < 10 ? r'0' : r''}${date.month}-${date.year}";
    return s;
  }
  return null;
}

String formatString(String string, int length, [String fill = r'           ']) {
  if (string != null) {
    if (string.length > length) return string.substring(0, length);
    if (string.length < length) {
      StringBuffer buffer = new StringBuffer();
      for (int x = 0; x <= length - string.length; x++) buffer.write(fill);
      return formatString('${string}${buffer.toString()}', length);
    }
    return string;
  }
  return null;
}

String formatStringRight(String string, int length, [String fill = r'      ']) {
  if (string != null) {
    if (string.length > length) return string.substring(string.length-length);
    if (string.length < length) {
      StringBuffer buffer = new StringBuffer();
      for (int x = 0; x <= length - string.length; x++) buffer.write(fill);
      return formatStringRight('${buffer.toString()}${string}', length);
    }
    return string;
  }
  return null;
}

String formatStatus(Status status) {
  if (status != null) {
    return formatString('${status.toString()}                 ', 9);
  }
  return formatString(r'···', 9);
}

String formatDouble(double value, [int length = 5]) {
  if (value != null) {
    String s = value.toString();
    int i = s.indexOf(r'.');
    if (i == s.length - 2) s = '${s}0';
    return formatStringRight(s, length);
  }
  return formatStringRight(r'n/a', length);
}

String formatList(List value) {
  if (hasValue(value)) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(r'[');
    int counter = 0;
    value.forEach((val) {
      buffer.write(format(val));
      counter++;
      if (counter < value.length) buffer.write(r', ');
    });
    buffer.write(r']');
    return buffer.toString();
  }
  return null;
}

String format(dynamic value) {
  if (value is String) return value;
  if (value is double) return formatDouble(value);
  if (value is DateTime) return formatDate(value);
  if (value is Status) return formatStatus(value);
  if (value is List) return formatList(value);
  return value.toString();
}

class Printer {

  StringSink _sink;
  StringSink _sinkError;

  Printer({sink, sinkError}) {
    _sink = sink == null ? stdout : sink;
    _sinkError = sinkError == null ? stderr : sinkError;
  }

  Printer write(dynamic value) {
    _sink.write(format(value));
    return this;
  }
  Printer writeln([dynamic value]) {
    if (value == null) _sink.writeln();
    else _sink.writeln(format(value));
    return this;
  }
  Printer error(dynamic value) {
    _sinkError.write(format(value));
    return this;
  }
  Printer errorln([dynamic value]) {
    if (value == null) _sinkError.writeln();
    else _sinkError.writeln(format(value));
    return this;
  }

  Printer section(String title, [String line = r'-------------------------']) {
    if (hasValue(title)) {
      String lineString = '+${formatString(line, title.length+2, line)}+';
      writeln(lineString);
      writeln('| ${title} |');
      writeln(lineString);
    }
    return this;
  }

  Printer title(String title, [String line = r'===========================']) {
    if (hasValue(title)) {
      String lineString = '${formatString(line, title.length, line)}';
      writeln(lineString);
      writeln(title);
      writeln(lineString);
    }
    return this;
  }

  PrinterColumn column(String title, int length) {
    return new PrinterColumn(this, title, length);
  }

  Printer bold([String text]) {
    return style(r'[1m', text);
  }

  Printer black([String text]) {
    return style(r'[30m', text);
  }

  Printer red([String text]) {
    return style(r'[31m', text);
  }

  Printer green([String text]) {
    return style(r'[32m', text);
  }

  Printer blue([String text]) {
    return style(r'[34m', text);
  }

  Printer cyan([String text]) {
    return style(r'[36m', text);
  }

  Printer lgreen([String text]) {
    return style(r'[92m', text);
  }

  Printer yellow([String text]) {
    return style(r'[93m', text);
  }

  Printer grey([String text]) {
    return style(r'[90m', text);
  }

  Printer backRed([String text]) {
    return style(r'[41m', text);
  }

  Printer backGreen([String text]) {
    return style(r'[42m', text);
  }

  Printer backBlue([String text]) {
    return style(r'[44m', text);
  }

  Printer backGrey([String text]) {
    return style(r'[100m', text);
  }

  Printer backLgreen([String text]) {
    return style(r'[102m', text);
  }

  Printer backLblue([String text]) {
    return style(r'[104m', text);
  }

  Printer backWhite([String text]) {
    return style(r'[107m', text);
  }

  Printer blink([String text]) {
    return style(r'[5m', text);
  }

  Printer inverted([String text]) {
    return style(r'[7m', text);
  }

  Printer style(String code, [String text]) {
    stdout.writeCharCode(27);
    stdout.write(code);
    if (text != null) {
      write(text);
      reset();
    }
    return this;
  }

  Printer reset() {
    stdout.writeCharCode(27);
    stdout.write(r'[0m');
    return this;
  }
}

class PrinterColumn {

  static const String colSeparator = r' ';

  Printer _p;
  int _length;
  String _title;

  PrinterColumn(this._p, this._title, this._length);

  Printer writeTitle() {
    _p.write(formatString(_title, _length));
    return _p.write(colSeparator);
  }

  Printer writeSeparator() {
    _p.write(formatString(r'-------------------', _length, r'--------------'));
    return _p.write(colSeparator);
  }

  Printer write(dynamic value) {
    String s = value.toString();
    if (s.length > _length) s = '${s.substring(0,_length-1)}\\';
    _p.write(formatString(s, _length));
    return _p.write(colSeparator);
  }

  Printer writeRight(dynamic value) {
    if (value is double) {
      _p.write(formatDouble(value, _length));
    } else {
      _p.write(formatStringRight(value.toString(), _length));
    }
    return _p.write(colSeparator);
  }
}