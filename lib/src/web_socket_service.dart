import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular2/core.dart';
import 'package:scrum_tools/src/runtime_service.dart';

typedef void listener(String key, Map<String, Object> data);

class WSSocket {

  WebSocket _webSocket;

  Set<listener> _listeners = new Set<listener>();

  WSSocket._internal(this._webSocket) {
    _webSocket.onMessage.listen((MessageEvent event) {
      _receivedData(event.data);
    });
  }

  void addListener(listener) {
    if (listener != null) {
      _listeners.add(listener);
    }
  }

  void removeListener(listener) {
    if (listener != null) {
      _listeners.remove(listener);
    }
  }

  void sendRawData(String data) {
    if (_webSocket != null && _webSocket.readyState == WebSocket.OPEN) {
      _webSocket.send(data);
    } else {
      throw 'WebSocket not connected, message ::$data:: not sent';
    }
  }

  void sendData(String key, [data]) {
    if (data == null)
      sendRawData(key);
    else {
      if (data is String && (data as String).length > 0) {
        String str = data as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          sendRawData('$key: $data');
        } else {
          sendRawData('$key: "$data"');
        }
      } else if (data is Map<String, Object>) {
        String jsonString = JSON.encode(data);
        sendRawData('$key: $jsonString');
      } else if (data is int || data is double || data is bool) {
        sendRawData('$key: $data');
      } else if (data is DateTime) {
        sendRawData('$key: "$data"');
      } else sendData(key, data.toString());
    }
  }

  void ping([data]) {
      sendData('ping', data);
  }

  void message(data) {
    sendData('message', data);
  }

  void joinGroup(int id) {
    sendData('group', id);
  }

  void close() {
    _webSocket.close();
  }

  void _receivedData(rawData) {
    String key = 'null';
    Map<String, Object> data;
    if (rawData is String) {
      String sData = rawData as String;
      int splitIndex = sData.indexOf(r':');
      if (splitIndex < 0) {
        data = {key: sData};
      } else {
        key = sData.substring(0, splitIndex);
        String objectString = sData.substring(splitIndex+1);
        var parsedData = JSON.decode(objectString);
        if (parsedData is Map) {
          data = parsedData;
        } else {
          data = {key: parsedData.toString()};
        }
      }
    } else {
      data = {key: rawData.toString()};
    }
    _listeners.forEach((listener l) {
      l(key, data);
    });
  }
}

@Injectable()
class WebSocketService {

  String _connectUrl;

  WebSocketService(RuntimeService runtimeService) {
    _connectUrl = runtimeService.debugMode ? 'ws://localhost:3000/ws' : '/ws';
  }

  Future<WSSocket> connect() {
    Completer<WSSocket> completer = new Completer<WSSocket>();
    WebSocket webSocket = new WebSocket(_connectUrl);
    webSocket.onOpen.listen((event) {
      completer.complete(new WSSocket._internal(webSocket));
    });
    return completer.future;
  }
}
