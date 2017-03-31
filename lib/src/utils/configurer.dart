import 'dart:async';
import 'dart:collection';
import 'dart:convert' show UTF8;

import 'package:resource/resource.dart';
import 'package:yaml/yaml.dart';

import 'package:logging/logging.dart';

import 'package:scrum_tools/src/utils/helpers.dart';

// **************************************************************************

class ConfigMap extends UnmodifiableMapBase<String, dynamic> {

  static const String extendsKey = r'~extends';

  Map<String, dynamic> _superMap;
  Map<String, dynamic> _innerMap;
  Map<String, dynamic> _cache = {};
  Iterable<String> _keys;

  ConfigMap._internal(this._innerMap) {
    _keys = new UnmodifiableListView(
        _innerMap.keys.where((String key) => key != extendsKey));
    String superMapPath = _innerMap[extendsKey];
    if (hasValue(superMapPath)) {
      Iterable<String> pathItems = superMapPath.split(r'/');
      Map<String, dynamic> map;
      pathItems.forEach((String s) {
        if (map == null)
          map = new ConfigMap._internal(_originalConfigMap[s]);
        else
          map = map[s];
      });
      _superMap = map;
    }
  }

  @override
  Iterable<String> get keys => _keys;

  @override
  dynamic operator [](String key) {
    if (extendsKey == key) throw new UnsupportedError(
        'Unsupported key [${key}] for this kind of map.');

    dynamic value = _cache[key];

    if (value == null) {
      value = !_innerMap.containsKey(key) && _superMap != null
          ? _superMap[key]
          : _innerMap[key];
      if (value != null) {
        if (value is Map<String, dynamic> && !(value is ConfigMap)) {
          value = new ConfigMap._internal(value as Map<String, dynamic>);
        }
        _cache[key] = value;
      }
    }
    return value;
  }

  String getPass(String key) => _passMap[key];
}

// **************************************************************************
Map<String, dynamic> _originalConfigMap;
Map<String, dynamic> _passMap;

Logger _log;

Future<ConfigMap> loadConfig(String resource,
    [String passResourceLocation = r'package:scrum_tools/assets/pass.yaml']) async {
  Resource cfgResource = new Resource(resource);

  Resource passResource = new Resource(passResourceLocation);

  String cfgString = await cfgResource.readAsString(encoding: UTF8);
  _originalConfigMap = loadYaml(cfgString);
  ConfigMap _cfgMap = new ConfigMap._internal(_originalConfigMap);

  String passString = await passResource.readAsString(encoding: UTF8);
  _passMap = loadYaml(passString);

  // --------------------
  String logLevel = _cfgMap[r'log'][r'level'];
  Level level = _resolveLogLevelByName(logLevel);
  Logger.root.level = level;
  Logger.root.onRecord.listen((rec) {
    print('${rec.level.name} :: ${rec.loggerName} : ${rec.time}: ${rec
        .message}');
  });
  _log = new Logger(r"configurer");
  _customizeLogs(_cfgMap);
  _log.info('Root log level [${Logger.root.level}].');
  return new Future.value(_cfgMap);
}

Level _resolveLogLevelByName(String name) {
  if (name != null) {
    for (Level level in Level.LEVELS) {
      if (level.name == name) {
        return level;
      }
    }
  }
  return Level.WARNING;
}

void _customizeLogs(ConfigMap cfgMap) {
  Iterable<Map<String, String>> list = cfgMap[r'log'][r'custom'];
  if (hasValue(list)) {
    hierarchicalLoggingEnabled = true;
    list.forEach((Map<String, String> map) {
      if (hasValue(map)) {
        map.forEach((String logName, String logLevel) {
          Logger log = new Logger(logName);
          log.level = _resolveLogLevelByName(logLevel);
          log.fine('Log [${logName}] :: level -> ${logLevel}');
        });
      }
    });
  }
}
// **************************************************************************

