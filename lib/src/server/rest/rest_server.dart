import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:start/start.dart';
import 'package:logging/logging.dart';

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/server/dao/daily_dao.dart';

typedef void _postHandler(Completer<Map<String, dynamic>> completer,
    Map<String, dynamic> content);

typedef void _getHandler(Completer completer, Map<String, String> params);

Logger _log = new Logger(r'rest_server');

class RestServer {

  static const Map<String, dynamic> OK_RESPONSE = const {r"status": r"OK"};
  String _pathRoot;
  Map<String, _postHandler> _postHandlers;
  Map<String, _getHandler> _getHandlers;
  DailyDAO _dao;

  RestServer(this._dao, [this._pathRoot = '/rest']) {
    _postHandlers = {
      r'/saveDaily': _saveDaily,
      r'/saveTimeReport': _saveTimeReport
    };
    _getHandlers = {
      r'/getDaily': _getDaily
    };
  }

  void init(Server appServer) {
    // ignore: conflicting_dart_import
    appServer.post(new RegExp("${_pathRoot}/.*")).listen((Request request) {
      String requestKey = _requestedKey(request);
      _postHandler handler = _postHandlers[requestKey];
      Response response = request.response;
      response.header(r'Content-Type', r'application/json; charset=UTF-8');

      if (handler != null) {
        HttpRequest httpRequest = request.input;
        StringBuffer data = new StringBuffer();
        httpRequest.transform(UTF8.decoder).listen((content) {
          data.write(content);
        }, onDone: () {
          Map<String, dynamic> requestMap = JSON.decode(data.toString());
          Completer<Map<String, dynamic>> completer = new Completer
          <Map<String, dynamic>>();
          completer.future.then((Map<String, dynamic> responseMap) {
            String responseString = JSON.encode(responseMap);
            response.send(responseString);
          }).catchError((error) {
            _error(error, response);
          });
          handler(completer, requestMap);
        });
      } else {
        _error(r"No POST handler found.", response);
      }
    });
    appServer.get(new RegExp("${_pathRoot}/.*")).listen((Request request) {
      String requestKey = _requestedKey(request);
      _getHandler handler = _getHandlers[requestKey];
      Response response = request.response;
      response.header(r'Content-Type', r'application/json; charset=UTF-8');

      if (handler != null) {
        Completer completer = new Completer();
        completer.future.then((_) {
          String responseString = () {
            if (_ == null) return r'';
            if (_ is String) return (_ as String);
            try {
              if (_ is Mappable) {
                return JSON.encode((_ as Mappable).toMap());
              }
              if (_ is Map<String, dynamic>) {
                return JSON.encode(_ as Map<String, dynamic>);
              }
              if (_ is List) {
                List list = _ as List;
                if (list.isEmpty) return '[]';
                if (list[1] is String) {
                  return JSON.encode(list);
                }
                if (list[1] is Mappable) {
                  List<Map<String, dynamic>> newList = [];
                  list.forEach((Mappable mappable) {
                    newList.add(mappable.toMap());
                  });
                  return JSON.encode(newList);
                }
              }
            } catch (error) {
              _log.severe(error);
            }
            return null;
          }();
          if (responseString != null) {
            response.send(responseString);
          } else {
            _error(r"Object enconding not supported.", response);
          }
        }).catchError((error) {
          _error(error, response);
        });
        handler(completer, request.uri.queryParameters);
      } else {
        _error(r"No GET handler found.", response);
      }
    });

    _log.info('REST server ready at [${_pathRoot}].');
  }

  String _requestedKey(Request request) {
    String requestedUri = request.input.requestedUri.toString();
    String uriPart = requestedUri.substring(
        requestedUri.indexOf('${_pathRoot}/') + _pathRoot.length);
    if (uriPart.indexOf(r'?') > -1) {
      uriPart = uriPart.substring(0, uriPart.indexOf(r'?'));
    }
    return uriPart;
  }

  void _error(dynamic error, Response response) {
    _log.severe(error);
    response.status(500);
    Map<String, dynamic> map = {r"status": r"ERROR", r"message": error.toString()};
    String responseString = JSON.encode(map);
    response.send(responseString);
  }

  //================================================================
/*
  int _getInt(String name, Map<String, String> params) {
    if (params != null) {
      String s = params['name'];
      if (s != null) {
        return int.parse(s, onError: (_) {});
      }
    }
    return null;
  }
*/
  //================================================================

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
    throw r"A date must be provided!";
  }

/*
  void _getLastDaily(Completer completer, Map<String, String> params) {
    _dao.getLastDailyReport().then((_) {
      if (_ is DailyReport) {
        completer.complete((_ as DailyReport).toMap());
      } else {
        completer.complete(_);
      }
    }).catchError((error) {
      completer.completeError(error);
    });
  }

  void _getLastDailies(Completer completer, Map<String, String> params) {
    int number = _getInt('number', params);
    if (number == null || number < 1) {
      completer.completeError(
          "An integer positive 'number' greater than 0 must be provided.");
    } else {
      _dao.getLastDailyReports(number).then((_) {
        completer.complete(_);
      }).catchError((error) {
        completer.completeError(error);
      });
    }
  }
  */
}