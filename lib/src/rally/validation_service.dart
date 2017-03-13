import 'dart:async';
import 'package:angular2/core.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/rally/rally_service.dart';

class IssueLevel {

  static final IssueLevel IMPORTANT = new IssueLevel._internal(
      'Important', 3);
  static final IssueLevel WARN = new IssueLevel._internal(
      'Warn', 2);
  static final IssueLevel INFO = new IssueLevel._internal(
      'Info', 1);

  static final List<IssueLevel> VALUES = new List.unmodifiable(
      [IMPORTANT, INFO]
  );

  static IssueLevel parse(String value) {
    for (IssueLevel v in VALUES) {
      if (v.name == value) {
        return v;
      }
    }
    return null;
  }

  String _name;
  int _order;

  String get name => _name;

  int get order => _order;

  IssueLevel._internal (this._name, this._order);

  operator >(IssueLevel s) => _order > s._order;

  operator <(IssueLevel s) => _order < s._order;

  operator >=(IssueLevel s) => _order >= s._order;

  operator <=(IssueLevel s) => _order <= s._order;

}

class Issue {

  IssueLevel _level;
  String _name;

  String get name => _name;

  IssueLevel get issueLevel => _level;

  Issue(this._level, this._name);

}

class Report {

  List<Issue> _issues;

  List<Issue> get issues => _issues;

  Map<IssueLevel, int> _flags;

  bool get hasIssues => _issues != null && _issues.length > 0;

  Report(List<Issue> issues) {
    _issues =
    issues != null && issues.length > 0 ? new List.unmodifiable(issues) : null;
    _flags = new Map<IssueLevel, int>();
  }

  Iterable<Issue> getIssuesByLevel(IssueLevel level) {
    if (has(level)) {
      return _issues.where((Issue issue) {
        return issue.issueLevel == level;
      });
    }
    return null;
  }

  bool has(IssueLevel level) {
    if (!hasIssues) return false;
    if (_flags[level] != null) return _flags[level] > 0;
    _flags[level] = 0;
    _issues.where((Issue issue) {
      return issue.issueLevel == level;
    }).forEach((Issue issue) {
      _flags[level]++;
    });
    return _flags[level] > 0;
  }
}

@Injectable()
class WorkItemValidationService {

  static final List<double> _estimationSeries = [
    1.0, 2.0, 3.0, 5.0, 8.0, 13.0, 20.0];

  static final Report _noWorkItemReport = new Report(
      [new Issue(IssueLevel.INFO, "No workitem provided.")]);

  static final RDUser _productOwner = new RDUser.DTO(
      55503983146, "David Pinczes");
  static final RDUser _userStoryValidator = _productOwner;
  static final RDUser _defectValidator = new RDUser.DTO(
      58761211860, "Lacramioara-Iulia");
  static final RDUser _qaDeployer = new RDUser.DTO(
      55504055635, "QA / Deployer");
  static final RDProject _project = new RDProject.DTO(55308115013, "Gordon");

  RDUser get productOwner => _productOwner;

  RDUser get userStoryValidator => _userStoryValidator;

  RDUser get defectValidator => _defectValidator;

  RDUser get qaDeployer => _qaDeployer;

  RDProject get project => _project;

  RallyService _rallyService;

  WorkItemValidationService(this._rallyService);

  Future<Report> validate(RDWorkItem workItem) {
    if (workItem != null) {
      List<Issue> issues = new List<Issue>();
      _checkProject(issues, workItem);
      _checkDeployment(issues, workItem);
      _checkExpedite(issues, workItem);
      _checkEstimation(issues, workItem);
      _checkOwner(issues, workItem);
      Completer<Report> completer = new Completer<Report>();
      _checkSchedule(issues, workItem).then((value) {
        completer.complete(new Report(issues));
      }).catchError((error) {
        completer.completeError(error);
      });
      return completer.future;
    }
    return new Future.value(_noWorkItemReport);
  }

  void _checkProject(List<Issue> issues, RDWorkItem workItem) {
    if (workItem.project == null) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "No project assigned."));
    } else if (workItem.project != project) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "The project is [${workItem.project.ID}-${workItem.project
              .name}] while it should be [${project.ID}-${project.name}]."));
    }
  }

  void _checkDeployment(List<Issue> issues, RDWorkItem workItem) {
    bool tagUAT = false;
    bool tagPRE = false;
    bool tagPRO = false;
    bool tagNOT_TO_DEPLOY = false;

    if (workItem.tags != null) {
      workItem.tags.forEach((String tag) {
        tagUAT = tagUAT || "UAT" == tag.toUpperCase();
        tagPRE = tagPRE || "PRE" == tag.toUpperCase();
        tagPRO = tagPRO || "PRO" == tag.toUpperCase();
        tagNOT_TO_DEPLOY =
            tagNOT_TO_DEPLOY || "NOT TO DEPLOY" == tag.toUpperCase();
      });
    }

    if (workItem.scheduleState < RDScheduleState.COMPLETED &&
        (tagUAT || tagPRE || tagPRO)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Tagged as deployed while the schedule states is [${workItem
              .scheduleState.abbr}]."));
    }

    if (workItem.scheduleState > RDScheduleState.COMPLETED &&
        !tagUAT && !tagPRE && !tagPRO && !tagNOT_TO_DEPLOY) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "No deployment tag while schedule state beyond [C]."));
    }

    if (tagPRO && !tagPRE && !tagUAT) {
      issues.add(new Issue(IssueLevel.WARN,
          "Tagged as deployed in PRO while not in PRE nor in UAT."));
    }

    if (tagNOT_TO_DEPLOY && (tagPRO || tagPRE || tagUAT)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Tagged as 'NOT TO DEPLOY' while tagged as deployed."));
    }
  }

  void _checkExpedite(List<Issue> issues, RDWorkItem workItem) {
    if (workItem is RDDefect && !workItem.expedite) {
      issues.add(new Issue(IssueLevel.WARN,
          "Not 'expedite' defect."));
    }
    if (workItem is RDHierarchicalRequirement && workItem.expedite) {
      issues.add(new Issue(IssueLevel.WARN,
          "'Expedite' user story."));
    }
  }

  void _checkEstimation(List<Issue> issues, RDWorkItem workItem) {
    if (workItem.scheduleState > RDScheduleState.UNDEFINED &&
        workItem.planEstimate == null) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Does not have any plan estimate while the schedule state is [${workItem
              .scheduleState.abbr}]."));
    }
    if (workItem.scheduleState > RDScheduleState.UNDEFINED &&
        workItem.planEstimate != null &&
        !_estimationSeries.contains(workItem.planEstimate)) {
      issues.add(new Issue(IssueLevel.WARN,
          "The estimation value ${workItem.planEstimate} is not standard."));
    }
    if (workItem.scheduleState == RDScheduleState.UNDEFINED &&
        workItem.planEstimate != null) {
      issues.add(new Issue(IssueLevel.WARN,
          "Has a plan estimate while the schedule state is [${workItem
              .scheduleState.abbr}]."));
    }
  }

  void _checkOwner(List<Issue> issues, RDWorkItem workItem) {
    if (workItem.scheduleState > RDScheduleState.DEFINED &&
        workItem.scheduleState < RDScheduleState.ACCEPTED &&
        !workItem.blocked && assignedToClient(workItem)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Assigned to client while it is not blocked and schedule state is [${workItem
              .scheduleState.abbr}]."));
    }

    if (workItem.blocked && (workItem.blockedReason == null ||
        workItem.blockedReason.trim() == 0)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Blocked while the blocked reason is empty."));
    }

    if (workItem.scheduleState == RDScheduleState.IN_PROGRESS &&
        !workItem.blocked && assignedToClient(workItem)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Assigned to client while in progress."));
    }
    if (workItem.blocked && !assignedToClient(workItem)) {
      issues.add(new Issue(IssueLevel.WARN,
          "Blocked while assigned to the dev team."));
    }

    if (workItem.scheduleState == RDScheduleState.UNDEFINED &&
        workItem.owner != null) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Has owner [${workItem.owner
              .displayName}] while in schedule state [${workItem
              .scheduleState.abbr}]."));
    }
    if (workItem.scheduleState == RDScheduleState.DEFINED &&
        workItem.iteration != null && assignedToClient(workItem)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Assigned to client while ready to progress (iteration and schedule state)."));
    }
    if ((workItem.scheduleState < RDScheduleState.DEFINED ||
        workItem.iteration == null) && !assignedToClient(workItem)) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Assigned to dev team while not ready to progress (iteration and schedule state)."));
    }

    if (workItem is RDDefect &&
        workItem.scheduleState == RDScheduleState.ACCEPTED &&
        taggedAsDeployed(workItem) && workItem.owner != defectValidator) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Defect not correctly assigned while ready for validation."));
    }
    if (workItem is RDHierarchicalRequirement &&
        workItem.scheduleState == RDScheduleState.ACCEPTED &&
        taggedAsDeployed(workItem) && workItem.owner != userStoryValidator) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "User strory not correctly assigned while ready for validation."));
    }
  }

  Future _checkSchedule(List<Issue> issues, RDWorkItem workItem) async {
    RDIteration currentIteration = await _rallyService.currentIteration;

    if (workItem.iteration != null && currentIteration != null &&
        workItem.iteration != currentIteration) {
      issues.add(new Issue(IssueLevel.WARN,
          "Workitem iteration [${workItem.iteration
              .name}] is not the current one [${currentIteration.name}]."));
    }
    if (workItem.iteration != null && workItem.iteration == currentIteration &&
        workItem.planEstimate == null) {
      issues.add(new Issue(IssueLevel.IMPORTANT,
          "Workitem scheduled for current iteration [${workItem.iteration
              .name}] while not estimated yet."));
    } else if (workItem.iteration != null && workItem.planEstimate == null) {
      issues.add(new Issue(IssueLevel.WARN,
          "Workitem scheduled for [${workItem.iteration
              .name}] while not estimated yet."));
    }
  }

  bool assignedToClient(RDWorkItem workItem) =>
      workItem.owner != null &&
          (workItem.owner == productOwner || workItem.project ==
              userStoryValidator || workItem.project == defectValidator);

  bool taggedAsDeployed(RDWorkItem workItem) {
    bool tagUAT = false;
    bool tagPRE = false;
    bool tagPRO = false;
    bool tagNOT_TO_DEPLOY = false;

    if (workItem.tags != null) {
      workItem.tags.forEach((String tag) {
        tagUAT = tagUAT || "UAT" == tag.toUpperCase();
        tagPRE = tagPRE || "PRE" == tag.toUpperCase();
        tagPRO = tagPRO || "PRO" == tag.toUpperCase();
        tagNOT_TO_DEPLOY =
            tagNOT_TO_DEPLOY || "NOT TO DEPLOY" == tag.toUpperCase();
      });
    }
    return tagUAT || tagPRE || tagPRO;
  }
}

