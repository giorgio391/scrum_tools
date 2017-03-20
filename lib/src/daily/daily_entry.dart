import 'package:angular2/core.dart';

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';

@Component(selector: 'daily-entry',
    templateUrl: 'daily_entry.html',
    styleUrls: const['daily_entry.css']
)
class DailyEntryView {

  RallyService _rallyService;

  @Input()
  DailyEntry entry;

  DailyEntryView(this._rallyService);

  String workItemName(String key) {
    if (key != null) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(key);
      return workItem == null ? null : workItem.name;
    }
    return null;
  }
}