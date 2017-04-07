import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/rally/basic_rally_service.dart';
import 'package:scrum_tools/src/rally/wi_validator.dart';

Printer _p = new Printer();

class WorkItemsCommands extends UtilOptionCommand {

  String get abbr => r"w";

  String get help => r'Utility for managing work items.';

  const WorkItemsCommands();

  void executeOption(String option) {
    List<String> options = option.split(r'+');
    String action = options[0];
    bool chk = options.length > 1 && options[1] == r'chk';

    if (r'dep-pro' == action) {
      rallyService.getPRODeploymentPending().then((Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite, chk);
      });
    } else if (r'dep-pre' == action) {
      rallyService.getPREDeploymentPending().then((Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite, chk);
      });
    } else if (r'dep-uat' == action) {
      rallyService.getUATDeploymentPending().then((Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite, chk);
      });
    } else if (r'dep-uat->pre' == action) {
      rallyService.getUAT2PREDeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite, chk);
      });
    } else if (r'dep-uat->pro' == action) {
      rallyService.getUAT2PRODeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite, chk);
      });
    } else if (r'dev-pending' == action) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          _printIterableAndClose(ite, chk);
        });
      });
    } else if (action.startsWith(r'dev-pending-')) {
      String iterationName = _resolveIterationName(action);
      _checkMissedIteration(() {
        rallyService.getDevTeamPendingInIteration(iterationName).then((
            Iterable<RDWorkItem> ite) {
          _printIterableAndClose(ite, chk);
        });
      });
    } else if (action.startsWith(r'rtd')) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          rallyService.getPREDeploymentPending().then((Iterable<RDWorkItem> ite) {
            _p.writeln(r'>>>>>>>>>>> PRE >>>>>>>>>>>>>>');
            _printIterableAndClose(ite, chk);
            rallyService.getUATDeploymentPending().then((Iterable<RDWorkItem> ite) {
              _p.writeln(r'>>>>>>>>>>> UAT >>>>>>>>>>>>>>');
              _printIterableAndClose(ite, chk);
            });
          });
        });
      });
    } else if (action.startsWith(r'rtp')) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          _p.writeln(r'>>>>>>> LIVE & MASTER >>>>>>>>>');
          _printIterableAndClose(
              ite.where((RDWorkItem workItem) =>
              workItem.ready && workItem.expedite), chk);
          _p.writeln(r'>>>>>>>>>> MASTER >>>>>>>>>>>>>');
          _printIterableAndClose(
              ite.where((RDWorkItem workItem) =>
              workItem.ready && !workItem.expedite), chk);
        });
      });
    } else if (action.startsWith(r'ite-')) {
      String iterationName = _resolveIterationName(action);
      _checkMissedIteration(() {
        rallyService.getByIteration(iterationName).then((
            Iterable<RDWorkItem> ite) {
          _printIterableAndClose(ite, chk);
        });
      });
    } else {
      _p.errorln('Unsupported!');
    }
  }

  String _resolveIterationName(String string) {
    String iterationName = string.substring(string.lastIndexOf(r'-') + 1)
        .trim();
    if (!iterationName.startsWith(r'Sprint '))
      iterationName = 'Sprint ${iterationName}';
    return iterationName;
  }

  void _checkMissedIteration(after()) {
    rallyService.getMissedIteration().then((Iterable<RDWorkItem> ite) {
      if (hasValue(ite)) {
        _p.writeln(
            '**** TOP PRIORITIZATION WITHOUT ITERATION ** [${ite
                .length}]  ****');
        _p.writeln(formatString(r'***************', 82));
        ite.forEach((RDWorkItem wi) {
          _p.write(r'* ');
          _p.write(formatString(wi.formattedID, 8));
          _p.write(formatString(wi.name, 70));
          _p.write(r' *');
        });
        _p.writeln(formatString(r'***************', 82));
      } else {
        _p.writeln(r'No top prioritization w/o iteration found. OK!');
      }
      if (after != null) after();
    });
  }

  void _printIterableAndClose(Iterable<RDWorkItem> ite, bool chk) {
    if (hasValue(ite)) {
      ite.forEach((RDWorkItem wi) {
        RDPriority p = inferWIPriority(wi);
        RDSeverity s = inferSeverity(wi);
        _p.write(wi.scheduleState < RDScheduleState.IN_PROGRESS ? r'*' : r' ');
        _p.write(wi.scheduleState < RDScheduleState.COMPLETED ? r'*' : r' ');
        _p.write(wi.expedite ? r'+' : r' ');
        _p.write(wi.blocked ? r'B' : r' ');
        _p.write(r' ');
        _p.write(formatString(wi.formattedID, 8));
        _p.write(formatString(wi.name, 70));
        _p.write(r' > ');
        _p.write(
            formatString(wi.owner != null ? wi.owner.displayName : r' ', 18));
        _p.write(wi.ready ? r'^' : r' ');
        _p.write(wi.scheduleState.abbr);
        _p.write(r' ');
        _p.write(formatString(
            wi.iteration == null ? r' ' : 'S${wi.iteration.name.substring(
                wi.iteration.name.length - 3).trim()}', 5));
        _p.write(formatString(p == null ? r' ' : p.name.split(r' ')[0], 8));
        _p.write(formatString(s == null ? r' ' : s.name.split(r' ')[0], 8));
        _p.write(r' > ');
        //_p.writeln(formatDate(wi.lastUpdateDate));
        _p.write(formatDouble(wi.planEstimate));

        if (hasValue(wi.tags)) {
          _p.write(r' ');
          new List.from(wi.tags)
            ..sort()
            ..forEach((String tag) {
              _p.write('·${tag}');
            });
        }
        _p.writeln();


        if (chk) {
          _printValidation(wi);
        }
      });
      _p.writeln('Count: ${ite.length}');
    } else {
      _p.writeln(r'No work item available!');
    }
    rallyService.close();
  }

  void _printValidation(RDWorkItem workItem) {
    Report report = WorkItemValidator.validateWI(workItem);
    if (report.hasIssues) {
      report.issues.where((Issue issue) =>
      issue.issueLevel == IssueLevel.IMPORTANT).forEach((Issue issue) {
        _p.writeln('         >>> ${formatString(issue.name, 70)}');
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.WARN)
          .forEach((Issue issue) {
        _p.writeln('          >> ${formatString(issue.name, 70)}');
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.INFO)
          .forEach((Issue issue) {
        _p.writeln('           > ${formatString(issue.name, 70)}');
      });
    }
  }

}