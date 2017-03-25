import "package:test/test.dart";
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

void main() {
  group("Helpers", () {
    test("Duration parser", () {
      Duration duration = new Duration(
          minutes: 2, seconds: 23, microseconds: 57);
      String string = duration.toString();
      Duration parsedDuration = parseDuration(string);
      expect(parsedDuration, duration);
      int integer = duration.inMicroseconds;
      parsedDuration = parseDuration(integer);
      expect(parsedDuration, duration);
    });
  });

  DateTime now = new DateTime.now();

  group("DailyReport", () {
    DailyReport report = new DailyReport(now, null);

    test("Report date", () {
      expect(now, equals(report.date));
    });

    test("Report serialization", () {
      Map<String, dynamic> map = report.toMap();
      expect(map, isNotNull);
      expect(map, isNotEmpty);
      expect(map['_serialVer'], greaterThan(0));
    });

    test("Report deserialization", () {
      Map<String, dynamic> map = report.toMap();
      DailyReport r = new DailyReport.fromMap(map);
      expect(r.date, report.date);
    });
  });
}