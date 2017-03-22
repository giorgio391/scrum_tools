import 'package:angular2/core.dart';

@Injectable()
class RuntimeService {

  bool get debugMode {
    bool value = false;

    assert(() {
      value = true;
      return true;
    });

    return value;
  }

  String contextUri(String context, [String schemeParam]) {
    String scheme = schemeParam ?? Uri.base.scheme;
    String host = Uri.base.host;
    int port = Uri.base.port;
    String portString =
      (scheme == 'http' && (port == null || port == 80)) ||
      (scheme == 'https' && (port == null || port == 443)) ?
      '' : ':$port';
    return '$scheme://$host$portString$context';
  }

}