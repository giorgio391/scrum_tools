import 'dart:async';
import 'package:start/start.dart';
import 'package:logging/logging.dart';
import 'package:scrum_tools/src/server/rest/rest_server.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';

Logger _log = new Logger(r'scrum_rest_server');

class ScrumRestServer {

  DailyDAO _dao;
  RestServer _restServer;

  ScrumRestServer(this._dao) {
    _restServer = new RestServer(postHandlers : {
      r'/saveDaily': _saveDaily,
      r'/saveTimeReport': _saveTimeReport
    }, getHandlers : {
      r'/getDaily': _getDaily
    });
  }

  void init(Server appServer) {
    _restServer.init(appServer);
  }


  void _saveDaily(Completer<Map<String, dynamic>> completer,
      Map<String, dynamic> map) {
    DailyReport report = new DailyReport.fromMap(map);
    _log.finest(report);
    _dao.saveDailyReport(report).then((_) {
      completer.complete(OK_RESPONSE);
    }).catchError((error) {
      completer.completeError(error);
    });
  }

  void _saveTimeReport(Completer<Map<String, dynamic>> completer,
      Map<String, dynamic> map) {
    TimeReport report = new TimeReport.fromMap(map);
    _log.finest(report);
    _dao.saveTimeReport(report).then((_) {
      completer.complete(OK_RESPONSE);
    }).catchError((error) {
      completer.completeError(error);
    });
  }

  void _getDaily(Completer completer, Map<String, String> params) {
    if (hasValue(params)) {
      String sDate = params['date'];
      if (hasValue(sDate)) {
        DateTime date = DateTime.parse(sDate);
        _dao.getDailyReport(date).then((DailyReport report) {
          completer.complete(report);
        }).catchError((error) => completer.completeError(error));
        return;
      }
    }
    throw r"To retrieve a daily, a date must be provided!";
  }
}