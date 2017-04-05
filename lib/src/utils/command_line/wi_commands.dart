import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/rally/basic_rally_service.dart';

Printer _p = new Printer();


class WorkItemsCommands extends UtilOptionCommand {

  String get abbr => r"w";

  String get help => r'Utility for managing work items.';

  const WorkItemsCommands();

  void executeOption(String option) {
    String action = option;

    if (r'dep-pro' == action) {
      rallyService.getPRODeploymentPending().then((Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite);
      });
    } else if (r'dep-uat->pre' == action) {
      rallyService.getUAT2PREDeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite);
      });
    } else if (r'dep-uat->pro' == action) {
      rallyService.getUAT2PRODeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite);
      });
    } else if (r'dev-pending' == action) {
      rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite);
      });
    } else if (action.startsWith(r'dev-pending-')) {
      String iterationName = action.substring(action.lastIndexOf(r'-') + 1)
          .trim();
      rallyService.getDevTeamPendingInIteration(iterationName).then((
          Iterable<RDWorkItem> ite) {
        _printIterableAndClose(ite);
      });
    } else {
      _p.errorln('Unsupported!');
    }
  }

  void _printIterableAndClose(Iterable<RDWorkItem> ite) {
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
      _p.write(formatString(s == null ? r' ' : s.name.split(r' ')[0], 5));
      _p.write(r' > ');
      //_p.writeln(formatDate(wi.lastUpdateDate));
      _p.writeln(formatDouble(wi.planEstimate));
    });
    rallyService.close();
  }

}