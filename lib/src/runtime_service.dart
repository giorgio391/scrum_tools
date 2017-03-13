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

}