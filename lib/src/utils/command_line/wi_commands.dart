import 'dart:io';
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
          rallyService.getPREDeploymentPending().then((
              Iterable<RDWorkItem> ite) {
            _p.backWhite().bold()
                .red(r'>>>>>>>>>>> PRE >>>>>>>>>>>>>>')
                .writeln();
            _printIterableAndClose(ite, chk);
            rallyService.getUATDeploymentPending().then((
                Iterable<RDWorkItem> ite) {
              _p.backWhite().bold()
                  .blue(r'>>>>>>>>>>> UAT >>>>>>>>>>>>>>')
                  .writeln();
              _printIterableAndClose(ite, chk);
            });
          });
        });
      });
    } else if (action.startsWith(r'rtp')) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          _p.backWhite().bold()
              .red(r'>>>>>>> LIVE & MASTER >>>>>>>>>')
              .writeln();
          _printIterableAndClose(
              ite.where((RDWorkItem workItem) =>
              workItem.ready && workItem.expedite), chk);
          _p.backWhite().bold()
              .blue(r'>>>>>>>>>> MASTER >>>>>>>>>>>>>')
              .writeln();
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
    } else if (action.startsWith(r'list-')) {
      Set<String> list = _resolveList(action);
      rallyService.currentIteration.then((RDIteration currentIteration) {
        List<RDWorkItem> workItems = [];
        rallyService.getWorkItems(list).forEach((RDWorkItem wi) {
          workItems.add(wi);
        }).then((_) {
          PrioritizationComparator comparator = new PrioritizationComparator(
              currentIteration);
          workItems.sort(comparator.compare);
          Expando<int> pRank = new Expando<int>();
          int count = 0;
          workItems.forEach((RDWorkItem wi) => pRank[wi] = ++count);
          workItems.sort(compareWIByFormattedID);
          _PRankColumnHandler extra = new _PRankColumnHandler(pRank);
          _printIterableAndClose(workItems, chk, extraCol: extra.print);
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

  Set<String> _resolveList(String string) {
    String sList = string.substring(string.lastIndexOf(r'-') + 1)
        .trim();
    if (sList.startsWith(r'f:')) {
      String fileName = sList.substring(sList.lastIndexOf(r'f:') + 2)
          .trim();
      File file = new File(fileName);
      return new Set<String>.from(
          file.readAsLinesSync().where((String s) => hasValue(s.trim())));
    }

    return new Set<String>.from(sList.split(r','));
  }

  void _checkMissedIteration(after()) {
    rallyService.getMissedIteration().then((Iterable<RDWorkItem> ite) {
      if (hasValue(ite)) {
        _p.blink().red(
            '**** TOP PRIORITIZATION WITHOUT ITERATION ** [${ite
                .length}]  ****');
        _p.writeln();
        _p.writeln(formatString(r'***************', 82));
        ite.forEach((RDWorkItem wi) {
          _p.write(r'* ');
          _p.write(formatString(wi.formattedID, 8));
          _p.write(formatString(wi.name, 70));
          _p.write(r' *');
        });
        _p.writeln(formatString(r'***************', 82));
      } else {
        _p.grey(r'No top prioritization w/o iteration found. OK!');
        _p.writeln();
      }
      if (after != null) after();
    });
  }

  void _printIterableAndClose(Iterable<RDWorkItem> ite, bool chk,
      {_ColumnPrinter extraCol}) {
    if (hasValue(ite)) {
      ite.forEach((RDWorkItem wi) {
        if (extraCol != null) {
          extraCol(_p, wi);
        }
        bool assignedToClient = WorkItemValidator.assignedToClient(wi);
        RDPriority p = inferWIPriority(wi);
        RDSeverity s = inferSeverity(wi);
        if ((assignedToClient && !wi.blocked) || wi.owner == null) _p.blink()
            .bold();
        _p.write(wi.scheduleState < RDScheduleState.IN_PROGRESS ? r'*' : r' ');
        _p.write(wi.scheduleState < RDScheduleState.COMPLETED ? r'*' : r' ');
        _p.reset();
        _p.write(wi.expedite ? r'+' : r' ');
        if (wi.blocked) {
          _p.bold().red().inverted(r'B');
        } else {
          _p.write(r' ');
        }
        _p.write(r' ');
        _p.write(formatString(wi.formattedID, 8));
        _p.write(formatString(wi.name, 70));
        _p.grey(r' > ');
        if (wi.owner != null) {
          if (assignedToClient) {
            _p.yellow();
          } else if (WorkItemValidator.assignedQADeployer(wi)) {
            _p.cyan();
          } else {
            _p.blue();
          }
          _p.write(formatString(wi.owner.displayName, 18));
          _p.reset();
        } else {
          _p.write(formatString(r' ', 18));
        }

        if (wi.ready) {
          _p.green().bold().inverted(r'^');
        } else {
          _p.write(r' ');
        }
        _p.bold().inverted();
        if (wi.scheduleState == RDScheduleState.UNDEFINED) {
          _p.grey();
        } else if (wi.scheduleState == RDScheduleState.COMPLETED) {
          _p.green();
        } else if (wi.scheduleState == RDScheduleState.ACCEPTED) {
          //_p.grey();
        } else if (wi.scheduleState == RDScheduleState.ACCEPTED_BY_OWNER) {
          _p.cyan();
        } else {
          _p.blue();
        }
        _p.write(wi.scheduleState.abbr);
        _p.reset();
        _p.write(r' ');
        _p.write(formatString(
            wi.iteration == null ? r' ' : 'S${wi.iteration.name.substring(
                wi.iteration.name.length - 3).trim()}', 5));
        if (hasMaxPrioritization(wi)) _p.blink().bold().red();
        _p.write(formatString(p == null ? r' ' : p.name.split(r' ')[0], 8));
        _p.reset();
        _p.write(formatString(s == null ? r' ' : s.name.split(r' ')[0], 8));
        _p.grey(r' > ');
        //_p.writeln(formatDate(wi.lastUpdateDate));
        if (wi.planEstimate != null && wi.planEstimate > 5.0)
          _p.bold();
        else if (wi.planEstimate != null && wi.planEstimate < 2.0)
          _p.cyan();
        else if (wi.planEstimate == null && !wi.blocked) _p.bold().red();
        _p.write(formatDouble(wi.planEstimate));
        _p.reset();

        if (hasValue(wi.tags)) {
          _p.write(r' ');
          new List.from(wi.tags)
            ..sort()
            ..forEach((String tag) {
              _p.write(r'·');
              _p.blue().inverted(tag);
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
        _p.red('         >>> ${formatString(issue.name, 70)}');
        _p.writeln();
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.WARN)
          .forEach((Issue issue) {
        _p.yellow('          >> ${formatString(issue.name, 70)}');
        _p.writeln();
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.INFO)
          .forEach((Issue issue) {
        _p.cyan('           > ${formatString(issue.name, 70)}');
        _p.writeln();
      });
    }
  }

}

typedef void _ColumnPrinter(Printer p, RDWorkItem workItem);

class _PRankColumnHandler {

  Expando<int> _pRank;

  _PRankColumnHandler(this._pRank);

  void print(Printer p, RDWorkItem workItem) {
    int pRank = _pRank[workItem];
    if (pRank < 10) p.write(r' ');
    p.write(pRank);
    p.write(r' ');
  }

}