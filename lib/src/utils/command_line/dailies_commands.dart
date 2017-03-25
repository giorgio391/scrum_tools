import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';

class ListDailies extends UtilOptionCommand {

  String get name => "daily";

  String get abbr => "d";

  String get help =>
      'Utility for listing daylies. An integer number must be provided.';

  const ListDailies();

  void executeOption(String option) {
    int value = int.parse(option);
    _printLast(value);
  }

  _printLast(int value) async {
    List<String> list = await dailyDAO.getLastDailyReportsAsJson(
        new DateTime.now(), value);
    print(list);
  }

}