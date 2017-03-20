import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:angular2/core.dart';

/// Provides a service to retrieve configuration data.
@Injectable()
class ScrumService {

  /// Provides a [Future] to obtain a [ScrumConfig] object.
  Future<ScrumConfig> get config {
    Completer<ScrumConfig> completer;
    if (completer == null) {
      completer = new Completer();
      HttpRequest.getString('scrum_config.json').then((String json) {
        Map values = JSON.decode(json);
        ScrumConfig config = new ScrumConfig()
          ..teamMemberNames = new List.unmodifiable(values['team'] as List);
        completer.complete(config);
      });
    }
    return completer.future;
  }
}

/// Objects of this class hold the configuration.
class ScrumConfig {
  /// List of team members names.
  List<String> teamMemberNames;
}
