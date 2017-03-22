import 'dart:async';

import 'package:scrum_tools/src/daily/daily_entities.dart';

abstract class DailyDAO {

  Future saveDailyReport(DailyReport report);

  Future saveTimeReport(TimeReport report);

  Future<DailyReport> getDailyReport(DateTime date);

  Future<List<DailyReport>> getLastDailyReports(DateTime date, int number);

}