import 'dart:html';

import 'package:angular2/core.dart';

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

@Component(selector: 'daily-entry',
    templateUrl: 'daily_entry.html',
    styleUrls: const['daily_entry.css']
)
class DailyEntryView {

  RallyService _rallyService;

  @Input()
  DailyEntry entry;

  @Input()
  bool statusBehind;

  @Output()
  EventEmitter<DailyEntry> onWorkItemClicked = new EventEmitter<DailyEntry>(
      false);

  @Output()
  EventEmitter<DailyEntry> onStatusClicked = new EventEmitter<DailyEntry>(
      false);

  bool get hoursNeeded => entry.hours == null && entry.scope == Scope.PAST;

  bool get workItemNeeded =>
      entry.workItemPending || (entry.process == Process.DEVELOPMENT &&
          !hasValue(entry.workItemCode) && !hasValue(entry.statement));

  bool get hasStatement => hasValue(entry.statement);

  DailyEntryView(this._rallyService);

  String workItemName(String key) {
    if (key != null) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(key);
      return workItem == null ? null : workItem.name;
    }
    return null;
  }

  void workItemClicked(MouseEvent event) {
    event.stopPropagation();
    if (entry.workItemCode != null && entry.workItemCode.isNotEmpty) {
      onWorkItemClicked.add(entry);
    }
  }

  void statusClicked(MouseEvent event) {
    event.stopPropagation();
    onStatusClicked.add(entry);
  }
}