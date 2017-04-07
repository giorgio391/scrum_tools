import 'package:angular2/core.dart';
import 'package:scrum_tools/src/rally/rally_service.dart';
import 'package:scrum_tools/src/rally/wi_validator.dart';

@Injectable()
class WorkItemValidationService extends WorkItemValidator {

  WorkItemValidationService(RallyService rallyService) : super(rallyService);

}
