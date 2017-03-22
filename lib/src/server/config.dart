import 'dart:async';
import 'dart:convert' show UTF8;

import 'package:scrum_tools/src/server/rest/rest_server.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';
import 'package:resource/resource.dart';
import 'package:yaml/yaml.dart';

class Config {

  static Config _config;

  Map<String, dynamic> _cfgMap;
  RestServer _restServer;

  factory Config() {
    if (_config != null) return _config;
    _config = new Config._internal();
    return _config;
  }

  Config._internal() {
    _loadConfig();
    _doConfig();
  }

  Future _loadConfig() async {
    Resource cfgResource = new Resource("package:scrum_tools/src/server/config.yaml");
    String cfgString = await cfgResource.readAsString(encoding: UTF8);
    _cfgMap = loadYaml(cfgString);
  }

  //***************************************************************************
  RestServer get restServer => _restServer;
  //***************************************************************************

  void _doConfig() {
    DailyFileDAO dao = new DailyFileDAO();
    _restServer = new RestServer(dao);
  }
  //***************************************************************************
  //***************************************************************************
}

void main(List<String> args) {
  Config cfg = new Config();
}