import 'dart:async';
import 'dart:convert' show UTF8;

import 'package:resource/resource.dart';
import 'package:yaml/yaml.dart';

import 'package:logging/logging.dart';

import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/dailies_commands.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/server/rally_proxy.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';

import 'package:scrum_tools/src/utils/helpers.dart';

import 'package:scrum_tools/src/rally/basic_rally_service.dart';

// **************************************************************************

const Map<String, UtilOptionCommand> commands = const {
  'daily': const ListDailies(),
  'sdaily': const SpreadDaily()
};

// **************************************************************************

Map<String, dynamic> _cfgMap;
Map<String, dynamic> _passMap;

Logger _log;

dynamic cfgValue(String key) => _cfgMap[key];

Future loadConfig() async {
  Resource cfgResource = new Resource(
      "package:scrum_tools/src/utils/command_line/config-utils.yaml");

  Resource passResource = new Resource("package:scrum_tools/assets/pass.yaml");

  String cfgString = await cfgResource.readAsString(encoding: UTF8);
  _cfgMap = loadYaml(cfgString);

  String passString = await passResource.readAsString(encoding: UTF8);
  _passMap = loadYaml(passString);

  // --------------------
  String logLevel = _cfgMap['log']['level'];
  Level level = _resolveLogLevelByName(logLevel);
  Logger.root.level = level;
  Logger.root.onRecord.listen((rec) {
    // ignore: conflicting_dart_import
    print('${rec.level.name} :: ${rec.loggerName} : ${rec.time}: ${rec.message}');
  });
  _log = new Logger("utils-cfg");
  _log.info('Root log level [${Logger.root.level}]');
  _customizeLogs();
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

void _customizeLogs() {
  Iterable<Map<String, String>> list = _cfgMap['log']['custom'];
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

Function _cfgResolver = () => _cfgMap;

String getPass(String key) => _passMap[key];

Function _scrumHttpClientResolver = () {
  Map<String, dynamic> cfg = _cfgResolver();
  String user = cfg['rallydev']['user'];
  String pass = getPass(cfg['rallydev']['pass']);
  ScrumHttpClient scrumHttpClient = new RallyDevProxy(user, pass);
  _scrumHttpClientResolver = () => scrumHttpClient;
  return scrumHttpClient;
};

Function _rallyServiceResolver = () {
  BasicRallyService service = new BasicRallyService(
      _scrumHttpClientResolver());
  _rallyServiceResolver = () => service;
  return service;
};

Function _dailyDAOResolver = () {
  DailyDAO dailyDAO = new DailyFileDAO();
  _dailyDAOResolver = () => dailyDAO;
  return dailyDAO;
};

// **************************************************************************

DailyDAO get dailyDAO => _dailyDAOResolver();

BasicRallyService get rallyService => _rallyServiceResolver();
