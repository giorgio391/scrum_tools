import 'package:angular2/core.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/runtime_service.dart';

import 'package:scrum_tools/src/rally/basic_rally_service.dart';

@Injectable()
class RallyService extends BasicRallyService {

  RallyService(ScrumHttpClient httpClient, RuntimeService runtimeService)
      :super(httpClient,
      pathRoot: runtimeService.debugMode ? r'http://localhost:3000/rd' :
      runtimeService.contextUri(r'/rd'));

}
