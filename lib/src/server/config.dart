import 'dart:async';

import 'package:scrum_tools/src/utils/configurer.dart' as cfg;
import 'package:scrum_tools/src/server/rest/rest_server.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';

Future<cfg.ConfigMap> loadConfig() {

  return cfg.loadConfig(r'package:scrum_tools/src/server/config.yaml');

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

//***************************************************************************
RestServer get restServer => _restServerResolver();
//***************************************************************************