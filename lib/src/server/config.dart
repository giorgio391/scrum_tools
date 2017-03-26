import 'dart:async';
import 'dart:convert' show UTF8;
import 'package:logging/logging.dart';

import 'package:scrum_tools/src/server/rest/rest_server.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';
import 'package:resource/resource.dart';
import 'package:yaml/yaml.dart';

class Config {

  static Config _config;

  Map<String, dynamic> _cfgMap;

  factory Config() {
    if (_config != null) return _config;
    _config = new Config._internal();
    return _config;
  }

  Config._internal() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((rec) {
      print('${rec.level.name} :: ${rec.loggerName} : ${rec.time}: ${rec.message}');
    });
    _loadConfig();
  }

  Future _loadConfig() async {
    Resource cfgResource = new Resource(
        "package:scrum_tools/src/server/config.yaml");
    String cfgString = await cfgResource.readAsString(encoding: UTF8);
    _cfgMap = loadYaml(cfgString);
  }

  //***************************************************************************
  RestServer get restServer => _restServerResolver();
//***************************************************************************

}

//***************************************************************************
//***************************************************************************
Function _dailyDAOResolver = () {
  DailyDAO dao = new DailyFileDAO();
  _dailyDAOResolver = () => dao;
  return dao;
};

Function _restServerResolver = () {
  RestServer restServer = new RestServer(_dailyDAOResolver());
  _restServerResolver = () => restServer;
  return restServer;
};
