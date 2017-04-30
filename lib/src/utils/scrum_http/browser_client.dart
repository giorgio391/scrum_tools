import 'dart:async';
import 'dart:html';
import 'package:angular2/angular2.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

@Injectable()
class BrowserScrumHttpClient implements ScrumHttpClient {

  Future<String> getString(String url) {
    if (hasValue(url)) {
      return HttpRequest.getString(url);
    }
    return null;
  }

  Future<Map<String, dynamic>> post(String part, String payload) {
    // TODO
    return null;
  }

  String handleError(dynamic error) {
    if (error is ProgressEvent) {
      ProgressEvent pe = error as ProgressEvent;
      if (pe.target is HttpRequest) {
        HttpRequest request = pe.target as HttpRequest;
        return "${request.status} - ${request.statusText} ::: ${request
            .responseUrl}";
      }
    }
    return error.toString();
  }

  void close({bool force: false}) {
  }
}