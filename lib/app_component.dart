import 'package:angular2/core.dart';
import 'daily_timer/daily_timer.dart';

/// Main application class.
@Component(selector: 'my-app',
    template: '<daily-timer></daily-timer>',
    directives: const [DailyTimer]
)
class AppComponent {
  var name = 'Daily timer';
}
