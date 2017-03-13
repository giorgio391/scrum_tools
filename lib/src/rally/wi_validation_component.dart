import 'package:angular2/core.dart';
import 'package:scrum_tools/scrum_tools_rally.dart';

@Component(selector: 'rd-wi-validation',
    templateUrl: 'wi_validation_component.html',
    styleUrls: const ['wi_validation_component.css']
)
class WorkItemValidation implements OnInit {

  Report report;

  bool get hasImportant => report != null && report.has(IssueLevel.IMPORTANT);

  bool get hasWarn => report != null && report.has(IssueLevel.WARN);

  Iterable<Issue> get important =>
      report != null ? report.getIssuesByLevel(IssueLevel.IMPORTANT) : null;
  Iterable<Issue> get warn =>
      report != null ? report.getIssuesByLevel(IssueLevel.WARN) : null;

  //@Output()
  //final EventEmitter<Report> reportChange = new EventEmitter<Report>(false);

  WorkItemValidationService _validationService;

  WorkItemValidation(this._validationService);

  @override
  void ngOnInit() {
  }

  RDWorkItem _workItem;

  RDWorkItem get workItem => _workItem;

  @Input()
  void set workItem(RDWorkItem workItem) {
    _workItem = workItem;
    if (workItem != null) {
      _validationService.validate(workItem).then((Report report) {
        _updateReport(report);
      });
    } else {
      _updateReport(null);
    }
  }

  void _updateReport(Report report) {
    this.report = report;
   // reportChange.add(this.report);
  }

}