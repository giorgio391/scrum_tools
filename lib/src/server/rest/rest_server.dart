import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:start/start.dart';
import 'package:logging/logging.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

typedef void POSTHandler(RESTContext context);

typedef void GETHandler(RESTContext context);

Logger _log = new Logger(r'rest_server');

const Map<String, dynamic> OK_RESPONSE = const {r"status": r"OK"};

class RestServer {

  String _pathRoot;
  Map<String, POSTHandler> _postHandlers;
  Map<String, GETHandler> _getHandlers;

  RestServer(
      {String pathRoot: r'/rest', Map<String, POSTHandler> postHandlers: const {
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
          RESTContext restContext = new RESTContext(httpRequest, requestMap);
          restContext._completer.future.then((String responseString) {
            response.send(responseString);
          }).catchError((error) {
            _error(error, response);
          });
          handler(restContext);
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
        RESTContext restContext = new RESTContext(request.input);
        restContext._completer.future.then((String responseString) {
          response.send(responseString);
        }).catchError((error) {
          _error(error, response);
        });
        handler(restContext);
      } else {
        _error(r"No GET handler found.", response);
      }
    });

    _log.info('REST server ready at [${_pathRoot}].');
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

  String _requestedKey(Request request) {
    String requestedUri = request.input.requestedUri.toString();
    String uriPart = requestedUri.substring(
        requestedUri.indexOf('${_pathRoot}/') + _pathRoot.length);
    if (uriPart.indexOf(r'?') > -1) {
      uriPart = uriPart.substring(0, uriPart.indexOf(r'?'));
    }
    return uriPart;
  }
}

class RESTContext {

  Completer<String> _completer = new Completer<String>();

  Map<String, dynamic> _payload;

  Map<String, dynamic> get payload => _payload;

  HttpRequest _request;

  RESTContext(this._request, [this._payload]);

  Map<String, String> get parameters => _request.uri.queryParameters;

  Map<String, List<String>> get parametersAll =>
      _request.uri.queryParametersAll;

  RESTSession _session;

  RESTSession get session {
    if (_session == null) _session = new RESTSession(_request);
    return _session;
  }

  void respondOK() {
    respondObject(OK_RESPONSE);
  }

  void respondError(dynamic error) {
    _completer.completeError(error);
  }

  void respondString(String string) {
    _completer.complete(string == null ? r'' : string);
  }

  void respondObject(dynamic object) {
    String responseString = () {
      if (object == null) return r'';
      if (object is String) return (object as String);
      try {
        if (object is Mappable) {
          return JSON.encode((object as Mappable).toMap());
        }
        if (object is Map<String, dynamic>) {
          return JSON.encode(object as Map<String, dynamic>);
        }
        if (object is List) {
          List list = object as List;
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
    respondString(responseString);
  }
}

class RESTSession {

  static const String SESSION_KEY = r'SCRUM_REST_SESSION';

  HttpSession _session;

  RESTSession(HttpRequest request) {
    this._session = request.session;
  }

  bool get isNew => _session.isNew;

  bool get isEmpty =>
      _session == null || !_session.containsKey(SESSION_KEY) ||
          !hasValue(_session[SESSION_KEY]);

  operator [](Object key) =>
      _session == null || !_session.containsKey(SESSION_KEY)
          ? null
          : _session[SESSION_KEY][key];

  operator []=(Object key, dynamic value) {
    if (!_session.containsKey(SESSION_KEY))
      _session[SESSION_KEY] = new Map<Object, dynamic>();
    _session[SESSION_KEY][key] = value;
  }

  void destroy() => _session.destroy();

  dynamic remove(Object key) {
    if (_session != null &&
        _session.containsKey(SESSION_KEY)) return (_session[SESSION_KEY] as Map)
        .remove(key);
    return null;
  }

  void set onTimeout(void callback()) {
    _session.onTimeout = callback;
  }

}