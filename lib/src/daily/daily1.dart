import 'package:angular2/core.dart';
import 'package:scrum_tools/src/daily_timer/daily_timer.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';

import 'package:scrum_tools/src/runtime_service.dart';

@Component(selector: 'daily1',
    templateUrl: 'daily1.html',
    providers: const [RuntimeService],
    directives: const [DailyTimer, WorkItemInspector]
)
class Daily1 {

  final String name = 'Daily1 app';

  Daily1();

}
