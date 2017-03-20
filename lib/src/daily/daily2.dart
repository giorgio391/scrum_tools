import 'package:angular2/core.dart';
import 'package:scrum_tools/src/runtime_service.dart';
import 'package:scrum_tools/src/scrum_service.dart';
import 'package:scrum_tools/src/daily/daily_reporter.dart';

@Component(selector: 'daily2',
    template: '''
      <div style="margin: 10px; height: 99%;">
        <daily-reporter></daily-reporter>
      </div>
    ''',
    providers: const [RuntimeService, ScrumService],
    directives: const [DailyReporter]
)
class Daily2 {

  final String name = 'Daily2 app';

  Daily2();

}
