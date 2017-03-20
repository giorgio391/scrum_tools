import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular2/core.dart';
import 'package:scrum_tools/src/runtime_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';

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
      } else
        sendData(key, data.toString());
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
        String objectString = sData.substring(splitIndex + 1);
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

typedef void idCodeListener(int id, String code);
typedef void codeListener(String code);

@Injectable()
class DailyEventBus {

  static const _workItemKey = 'wi';
  static const _teamMemberKey = 'tm';
  static const _stopwatchKey = 'sw';

  WebSocketService _webSocketService;
  WSSocket _wsSocket;
  Set <idCodeListener> _workItemListeners = new Set<idCodeListener>();
  Set <codeListener> _teamMemberListeners = new Set<codeListener>();
  Set <codeListener> _stopwatchListeners = new Set<codeListener>();

  DailyEventBus(this._webSocketService) {
    _webSocketService.connect().then((WSSocket wsSocket) {
      _wsSocket = wsSocket;
      _wsSocket.addListener(_dataReceived);
      _wsSocket.joinGroup(25);
    });
  }

  void _dataReceived(String key, Map<String, dynamic>data) {
    if (key != null) {
      switch (key) {
        case _workItemKey:
          _workItemListeners.forEach((idCodeListener listener) {
            listener((data['id'] as int), (data['ref'] as String));
          });
          break;
        case _teamMemberKey:
          _teamMemberListeners.forEach((codeListener listener) {
            listener((data['ref'] as String));
          });
          break;
        case _stopwatchKey:
          _stopwatchListeners.forEach((codeListener listener) {
            listener((data['command'] as String));
          });
          break;
      }
    }
  }

  void _sendIdCodeMessage(String key, int id, String ref) {
    _wsSocket.message({key: {"id": id, "ref": ref}});
  }

  void _sendCodeMessage(String key, String ref) {
    _wsSocket.message({key: {"ref": ref}});
  }

  void sendWorkItemMessage(RDWorkItem workItem) {
    if (workItem == null)
      _wsSocket.message({_workItemKey: null});
    else
      _sendIdCodeMessage(_workItemKey, workItem.ID, workItem.formattedID);
  }

  void sendTeamMemberMessage(String code) {
    _sendCodeMessage(_teamMemberKey, code);
  }

  void sendStopwatchCommandMessage(String command) {
    _wsSocket.message({_stopwatchKey: {"command": command}});
  }

  void addWorkItemListener(idCodeListener listener) {
    if (listener != null) {
      _workItemListeners.add(listener);
    }
  }

  void removeWorkItemListener(idCodeListener listener) {
    if (listener != null) {
      _workItemListeners.remove(listener);
    }
  }

  void addTeamMemberListener(codeListener listener) {
    if (listener != null) {
      _teamMemberListeners.add(listener);
    }
  }

  void removeTeamMemberListener(codeListener listener) {
    if (listener != null) {
      _teamMemberListeners.remove(listener);
    }
  }

  void addStopwatchListener(codeListener listener) {
    if (listener != null) {
      _stopwatchListeners.add(listener);
    }
  }

  void removeStopwatchListener(codeListener listener) {
    if (listener != null) {
      _stopwatchListeners.remove(listener);
    }
  }
}
