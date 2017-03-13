import 'package:angular2/core.dart';
import 'package:scrum_tools/daily_timer/daily_timer.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';

import 'package:scrum_tools/src/runtime_service.dart';

/// Main application class.
@Component(selector: 'my-app',
    template: '''
      <div><daily-timer></daily-timer></div>
      <div><wi-inspector></wi-inspector></div>
    ''',
    providers: const [RuntimeService],
    directives: const [DailyTimer, WorkItemInspector]
)
class AppComponent {

  var name = 'Scrum tools';

  AppComponent();

}
