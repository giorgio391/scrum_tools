import 'package:angular2/core.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';
import 'package:scrum_tools/utils/simple_editor.dart';

@Component(selector: 'wi-inspector',
    templateUrl: 'wi_inspector_component.html',
    styleUrls: const ['wi_inspector_component.css'],
    providers: const [RallyService, WorkItemValidationService],
    directives: const [SimpleEditor, WorkItem, WorkItemValidation]
)
class WorkItemInspector {

  String errorMessage;
  String infoMessage;

  RallyService _service;

  @Input()
  RDWorkItem workItem;

  WorkItemInspector(this._service);

  void set workItemCode(String wiCode) {
    workItem = null;
    this.errorMessage = null;
    this.infoMessage = null;
    if (wiCode != null) {
      String wic = wiCode.toUpperCase().trim();
      switch (wic.length) {
        case 3:
          wic = "US19$wic";
          break;
        case 4:
          wic = "DE$wic";
          break;
        case 5:
          wic = "US$wic";
          break;
      }
      this.infoMessage = "Waiting for [$wic].";
      _service.getWorkItem(wic).then((RDWorkItem wi) {
        this.infoMessage = null;
        this.workItem = wi;
        //workItemChanged.add(wi);
      }).catchError((String error) {
        this.infoMessage = null;
        this.errorMessage = error;
      });
    }
  }
}
