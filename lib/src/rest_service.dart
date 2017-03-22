import 'dart:html';
import 'dart:convert';

import 'package:angular2/core.dart';
import 'package:scrum_tools/src/runtime_service.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';

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

}