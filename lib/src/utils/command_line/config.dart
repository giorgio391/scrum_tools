import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/dailies_commands.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/server/dao/impl/daily_file_dao.dart';

const Map<String, UtilOptionCommand> commands = const {
  'daily' : const ListDailies()
};

DailyDAO _dailyDAO = new DailyFileDAO();

DailyDAO get dailyDAO => _dailyDAO;
