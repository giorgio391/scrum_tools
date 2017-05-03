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
          !hasValue(entry.workItemCode) && !hasValue(entry.statement)) ||
          !validWorkItem;

  bool get hasStatement => hasValue(entry.statement);

  bool get validWorkItem =>
      entry.workItemCode == null || () {
        RDWorkItem wi = _rallyService.getCachedWorkItem(entry.workItemCode);
        return wi != null && wi.project.ID == _rallyService.defaultProjectID;
      }();

  bool get workExists {
    if (hasValue(entry.workItemCode)) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(entry.workItemCode);
      return workItem != null;
    }
    return false;
  }

  bool get inquiry {
    if (hasValue(entry.workItemCode)) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(entry.workItemCode);
      if (workItem != null) {
        return workItem.inquiry;
      }
    }
    return false;
  }

  bool get operation {
    if (hasValue(entry.workItemCode)) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(entry.workItemCode);
      if (workItem != null) {
        return workItem.operation;
      }
    }
    return false;
  }

  bool get mismatch {
    if (hasValue(entry.workItemCode)) {
      RDWorkItem workItem = _rallyService.getCachedWorkItem(entry.workItemCode);
      if (workItem != null) {
        if ((workItem.inquiry && entry.process != Process.INQUIRIES) ||
            (!workItem.inquiry && entry.process == Process.INQUIRIES) ||
            (workItem.operation && entry.process != Process.OPERATIONS) ||
            (!workItem.operation && entry.process == Process.OPERATIONS))
          return true;
      }
    }
    return false;
  }

  DailyEntryView(this._rallyService);

  String get workItemName =>
      hasValue(entry.workItemCode)
          ? _workItemNameByKey(entry.workItemCode)
          : null;

  String _workItemNameByKey(String key) {
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