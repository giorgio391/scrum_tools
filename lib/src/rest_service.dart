import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:angular2/core.dart';
import 'package:scrum_tools/src/runtime_service.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

@Injectable()
class RestService {

  String _connectUrl;

  RestService(RuntimeService runtimeService) {
    _connectUrl = runtimeService.debugMode ? 'http://localhost:3000/rest' :
    runtimeService.contextUri('/rest');
  }

  void saveDaily(DailyReport report) {
    if (report != null) {
      String s = JSON.encode(report.toMap());
      HttpRequest.request(
          '$_connectUrl/saveDaily', method: 'POST', sendData: s);
    }
  }

  Future<DailyReport> getDaily(DateTime date) {
    Completer<DailyReport> completer = new Completer<DailyReport>();
    if (date != null) {
      HttpRequest.getString(
          '$_connectUrl/getDaily?date=${_dateParam(date)}').then((
          String string) {
        if (hasValue(string)) {
          Map<String, dynamic> map = JSON.decode(string);
          DailyReport report = new DailyReport.fromMap(map);
          completer.complete(report);
        } else {
          completer.complete(null);
        }
      }).catchError((error) {
        completer.completeError(error);
      });
    } else {
      completer.complete(null);
    }
    return completer.future;
  }

  void saveTimeReport(TimeReport report) {
    if (report != null) {
      String s = JSON.encode(report.toMap());
      HttpRequest.request(
          '$_connectUrl/saveTimeReport', method: 'POST', sendData: s);
    }
  }

  String _dateParam(DateTime date) {
    String s = date.toIso8601String();
    s = s.substring(0, s.indexOf(r'T'));
    return s;
  }
}