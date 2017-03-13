import 'package:angular2/core.dart';

import 'package:scrum_tools/scrum_tools_rally.dart';

@Component(selector: 'rd-work-item',
    templateUrl: 'work_item_component.html',
    styleUrls: const ['work_item_component.css']
)
class WorkItem {

  @Input()
  RDWorkItem workItem;

  bool get isDefect => workItem is RDDefect;

  bool get isUserStory => workItem is RDHierarchicalRequirement;

}