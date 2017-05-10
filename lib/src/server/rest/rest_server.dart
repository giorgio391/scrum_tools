import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:start/start.dart';
import 'package:logging/logging.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

typedef void POSTHandler(Completer<Map<String, dynamic>> completer,
    Map<String, dynamic> content);

typedef void GETHandler(Completer completer, Map<String, String> params);

Logger _log = new Logger(r'rest_server');

const Map<String, dynamic> OK_RESPONSE = const {r"status": r"OK"};

class RestServer {

  String _pathRoot;
  Map<String, POSTHandler> _postHandlers;
  Map<String, GETHandler> _getHandlers;

  RestServer({String pathRoot: r'/rest', Map<String, POSTHandler> postHandlers: const {
      }, Map<String, GETHandler> getHandlers: const {} }) {
    _pathRoot = pathRoot;
    _postHandlers = postHandlers;
    _getHandlers = getHandlers;
  }

  void init(Server appServer) {
    // ignore: conflicting_dart_import
    appServer.post(new RegExp("${_pathRoot}/.*")).listen((Request request) {
      String requestKey = _requestedKey(request);
      POSTHandler handler = _postHandlers[requestKey];
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
      GETHandler handler = _getHandlers[requestKey];
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
    Map<String, dynamic> map = {
      r"status": r"ERROR",
      r"message": error.toString()
    };
    String responseString = JSON.encode(map);
    response.send(responseString);
  }
}