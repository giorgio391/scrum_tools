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

  void handleError(Completer completer, dynamic error) {
    if (error is ProgressEvent) {
      ProgressEvent pe = error as ProgressEvent;
      if (pe.target is HttpRequest) {
        HttpRequest request = pe.target as HttpRequest;
        completer.completeError(
            "${request.status} - ${request.statusText} ::: ${request
                .responseUrl}");
        return;
      }
    }
    completer.completeError(error.toString());
  }

  void close({bool force: false}) {
  }
}