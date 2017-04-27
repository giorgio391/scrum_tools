import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/repository/repository.dart';

Logger _log = new Logger(r'file-repository');

const int _maxBackupAttempts = 200;

String _home = Platform.environment[r'HOME'] ??
    Platform.environment[r'USERPROFILE'];
String _user = Platform.environment[r'USER'];
JsonEncoder _jsonEncoder = new JsonEncoder.withIndent(r'  ');

class _PersistedData implements PersistedData {
  DateTime _timestamp;
  String _author;
  Map<String, dynamic> _data;

  @override
  String get author => _author;

  @override
  DateTime get timestamp => _timestamp;

  @override
  Map<String, dynamic> get data => _data;

  _PersistedData([this._author, this._timestamp]) {
    _timestamp ??= new DateTime.now();
    _author ??= _user;
  }

  _PersistedData._fromJson(String json) : this._fromMap(JSON.decode(json));

  _PersistedData._fromMap(Map<String, dynamic> map) {
    _author = map[r'author'];
    _timestamp = DateTime.parse(map[r'timestamp']);
    _data = map[r'data'];
  }

  factory _PersistedData._fromFile(File file) {
    return new _PersistedData._fromJson(file.readAsStringSync());
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map<String, dynamic>();
    if (_author != null) map[r'author'] = _author;
    map[r'timestamp'] = _timestamp.toIso8601String();
    map[r'data'] = data;
    return map;
  }

  String toJson() {
    return _jsonEncoder.convert(toMap());
  }

  void toFile(File file) {
    file.writeAsStringSync(toJson(), flush: true);
  }

}

class FileRepository implements RepositorySync {

  Directory _dataDir;
  Directory _backupDir;
  File _deleteLog;
  String _name;

  FileRepository(this._name, [String rootDirectory]) {
    String root = rootDirectory ??
        '${_home}${Platform.pathSeparator}scrum_repo${Platform
            .pathSeparator}${_name}';
    _dataDir = new Directory(root);
    _backupDir = new Directory('${root}${Platform.pathSeparator}backup');
    if (!_dataDir.existsSync()) {
      _dataDir.createSync(recursive: true);
    }
    if (!_backupDir.existsSync()) {
      _backupDir.createSync(recursive: true);
    }
    _deleteLog = new File('${root}${Platform.pathSeparator}_delete.log');
    if (!_deleteLog.existsSync()) {
      _deleteLog.writeAsStringSync(r'', flush: true);
    }
  }

  String get name => _name;

  void _logDelete(String key, [String author]) {
    String who = author == null ? _user : author;
    RandomAccessFile raf = _deleteLog.openSync(mode: FileMode.APPEND);
    raf.writeStringSync(
        '${new DateTime.now().toIso8601String()} - ${key}${who != null
            ? ' - ${who}'
            : '' }\n');
    raf.flushSync();
    raf.closeSync();
  }

  @override
  PersistedData save(String key, Map<String, dynamic> data, [String author]) {
    if (hasValue(key) && hasValue(data)) {
      _PersistedData pData = new _PersistedData(author)
        .._data = data;
      File file = _getClearFile(key);
      pData.toFile(file);
      return pData;
    }
    return null;
  }

  @override
  PersistedData get(String key) {
    File file = _getKeyFile(key);
    if (file != null) {
      return new _PersistedData._fromFile(file);
    }
    return null;
  }

  @override
  PersistedData delete(String key, [String author]) {
    File file = _getKeyFile(key);
    if (file != null) {
      _PersistedData _pData = new _PersistedData._fromFile(file);
      _logDelete(key, author);
      _getClearFile(key); // To trigger backup.
      return _pData;
    }
    return null;
  }

  @override
  PersistedData operator [](String key) => get(key);

  File _getKeyFile(String key) {
    File file = new File(
        '${_dataDir.path}${Platform.pathSeparator}${key}.json');
    return file.existsSync() ? file : null;
  }

  File _getClearFile(String key) {
    File file = new File(
        '${_dataDir.path}${Platform.pathSeparator}${key}.json');
    if (file.existsSync()) {
      for (int i = 1; i <= _maxBackupAttempts; i++) {
        String backupPath = '${_backupDir.path}${Platform
            .pathSeparator}${key}_$i.json';
        File backupFile = new File(backupPath);
        if (!backupFile.existsSync()) {
          file.renameSync(backupPath);
          break;
        }
        if (i == _maxBackupAttempts) {
          String message = 'Too many attempts to bakup [${file.path}].';
          _log.severe(message);
          throw message;
        }
      }
    }
    return file;
  }
}

void main(List<String> args) {
  Platform.environment.keys.forEach((String key) {
    print('${key} -> ${Platform.environment[key]}');
  });

  FileRepository repo = new FileRepository(r'prueba');
  repo._logDelete("AAA", null);
  repo._logDelete("AAA", "BBB");
}