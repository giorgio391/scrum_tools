import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

class ListDailies extends UtilOptionCommand {

  String get abbr => "d";

  String get help =>
      'Utility for listing daylies. An integer number must be provided.';

  const ListDailies();

  void executeOption(String option) {
    int value = int.parse(option);
    _printLast(value);
  }

  _printLast(int value) async {
    List<String> list = await dailyDAO.getLastDailyReportsAsJson(number: value);
    print(list);
  }

}

class SpreadDaily extends UtilOptionCommand {

  const SpreadDaily();

  String get abbr => "s";

  String get help =>
      'Utility to spread dailies.';

  void executeOption(String option) {
    _executeOption();
  }

  _executeOption() async {
    List<DailyReport> reports = await dailyDAO.getLastDailyReports(number: 2);
    if (!hasValue(reports)) {
      print('No daily report found!.');
      return;
    }
  }

}
