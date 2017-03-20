import 'dart:async';
import 'package:angular2/core.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';
import 'package:scrum_tools/src/utils/simple_editor.dart';
import 'package:scrum_tools/src/web_socket_service.dart';

@Component(selector: 'wi-inspector',
    templateUrl: 'wi_inspector_component.html',
    styleUrls: const ['wi_inspector_component.css'],
    providers: const [RallyService, WorkItemValidationService, WebSocketService
    ],
    directives: const [SimpleEditor, WorkItem, WorkItemValidation]
)
class WorkItemInspector {

  String errorMessage;
  String infoMessage;

  RallyService _rallyService;
  WebSocketService _wsService;
  WSSocket _wsSocket;

  @Input()
  RDWorkItem workItem;

  WorkItemInspector(this._rallyService, this._wsService) {
    _wsService.connect().then((WSSocket wsSocket) {
      _wsSocket = wsSocket;
      _wsSocket.addListener(_dataReceived);
      _wsSocket.joinGroup(25);
    });
  }

  void _dataReceived(String key, Map<String, Object> data) {
    if (key == 'wi') {
      Function finder = (data['ref'] as String).startsWith('DE') ?
      _rallyService.getDefectById : _rallyService
          .getHierarchicalRequirementById;
      Future<RDWorkItem> future = finder(data['id']);
      future.then((RDWorkItem workItem) {
        this.workItem = workItem;
      }).catchError((error) {
        infoMessage = null;
        errorMessage = error.toString();
      });
    }
  }

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
      _rallyService.getWorkItem(wic).then((RDWorkItem wi) {
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
