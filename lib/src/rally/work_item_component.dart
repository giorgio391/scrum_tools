import 'package:angular2/core.dart';

import 'package:scrum_tools/scrum_tools_rally.dart';
import 'package:scrum_tools/utils/simple_editor.dart';

@Component(selector: 'rd-work-item',
    templateUrl: 'work_item_component.html',
    styleUrls: const ['work_item_component.css'],
    providers: const [RallyService],
    directives: const [SimpleEditor]
)
class WorkItem implements OnInit {

  RallyService _service;
  String _message;

  String get message => _message;

  @Input()
  RDWorkItem workItem;

  bool get isDefect => workItem is RDDefect;

  bool get isUserStory => workItem is RDHierarchicalRequirement;

  WorkItem(this._service);

  void ngOnInit() {
  }

  @Input()
  void set workItemCode(String wiCode) {
    workItem = null;
    this._message = null;
    if (wiCode != null) {
      String wic = wiCode.toUpperCase().trim();
      if (wic.length == 3) wic = "US19$wic";
      if (wic.length == 4) wic = "DE$wic";
      this._message = "Waiting for [$wic].";
      _service.getWorkItem(wic).then((RDWorkItem wi) {
        this._message = null;
        this.workItem = wi;
      }).catchError((String error) {
        this._message = error;
      });
    }
  }

  String get workItemCode => workItem == null ? null : workItem.formattedID;

}