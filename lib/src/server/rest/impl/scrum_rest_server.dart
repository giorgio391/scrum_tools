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

  void _saveDaily(RESTContext context) {
    DailyReport report = new DailyReport.fromMap(context.payload);
    _log.finest(report);
    _dao.saveDailyReport(report).then((_) {
      context.respondOK();
    }).catchError((dynamic error) {
      context.respondError(error);
    });
  }

  void _saveTimeReport(RESTContext context) {
    TimeReport report = new TimeReport.fromMap(context.payload);
    _log.finest(report);
    _dao.saveTimeReport(report).then((_) {
      context.respondOK();
    }).catchError((dynamic error) {
      context.respondError(error);
    });
  }

  void _getDaily(RESTContext context) {
    Map<String, String> params = context.parameters;
    if (hasValue(params)) {
      String sDate = params['date'];
      if (hasValue(sDate)) {
        DateTime date = DateTime.parse(sDate);
        _dao.getDailyReport(date).then((DailyReport report) {
          context.respondObject(report);
        }).catchError((error) => context.respondError(error));
      }
    } else {
      context.respondError(r"To retrieve a daily, a date must be provided!");
    }
  }
}