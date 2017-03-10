import 'package:angular2/core.dart';
import 'package:scrum_tools/daily_timer/daily_timer.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';
import 'package:scrum_tools/utils/simple_editor.dart';

/// Main application class.
@Component(selector: 'my-app',
    templateUrl: 'app_component.html',
    providers: const [WorkItem, RallyService],
    directives: const [DailyTimer, WorkItem, SimpleEditor]
)
class AppComponent {

  var name = 'Scrum tools';
  String wiCode ;

  @ContentChildren(WorkItem)
  QueryList<WorkItem> workItem;

  void setWI(String wiCode) {
    this.wiCode = wiCode;
  }
}





