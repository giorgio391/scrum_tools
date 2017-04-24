import 'dart:async';

import 'package:logging/logging.dart';

import 'package:scrum_tools/src/utils/configurer.dart' as cfg;
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/dailies_commands.dart';
import 'package:scrum_tools/src/utils/command_line/wi_commands.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/server/rally_proxy.dart';
import 'package:scrum_tools/src/rally/wi_validator.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';

import 'package:scrum_tools/src/utils/helpers.dart';

import 'package:scrum_tools/src/rally/basic_rally_service.dart';

// **************************************************************************

const Map<String, UtilOptionCommand> commands = const {
  'daily': const ListDailies(),
  'sdaily': const SpreadDaily(),
  'wi': const WorkItemsCommands()
};

// **************************************************************************

Logger _log;
cfg.ConfigMap _cfgMap;
dynamic cfgValue(String key) => _cfgMap[key];
Future loadConfig() async {
  _cfgMap = await cfg.loadConfig(
      r"package:scrum_tools/src/utils/command_line/config-utils.yaml");
}
// **************************************************************************

Function _cfgResolver = () => _cfgMap;

String getPass(String key) => _cfgMap.getPass(key);

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

Function _workItemValidatorResolver = () {
  WorkItemValidator validator = new WorkItemValidator(rallyService);
  _workItemValidatorResolver = () => validator;
  return validator;
};

// **************************************************************************

DailyDAO get dailyDAO => _dailyDAOResolver();

BasicRallyService get rallyService => _rallyServiceResolver();

WorkItemValidator get workItemValidator => _workItemValidatorResolver();
