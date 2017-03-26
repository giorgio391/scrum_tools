import 'dart:async';
import 'dart:io' show stdout, stderr;
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

class ListDailies extends UtilOptionCommand {

  String get abbr => "d";

  String get help =>
      'Utility for listing daylies. An integer number must be provided.';

  const ListDailies();

  void executeOption(String option) {
    int value = int.parse(option);
    _printLast(value);
  }

  _printLast(int value) async {
    List<String> list = await dailyDAO.getLastDailyReportsAsJson(number: value);
    print(list);
  }
}

class SpreadDaily extends UtilOptionCommand {

  const SpreadDaily();

  String get abbr => "s";

  String get help => 'Utility to spread dailies.';

  void executeOption(String option) {
    _executeOption().whenComplete(() {
      rallyService.close();
    }).catchError((error) {
      stderr.write(error);
    });
  }

  Future _executeOption() {
    Completer completer = new Completer();
    dailyDAO.getLastDailyReports(number: 2).then((List<DailyReport> reports) {
      if (!hasValue(reports)) {
        print('No daily report found!.');
        completer.complete();
      } else {
        _ConsolidatedDailyReport cReport = new _ConsolidatedDailyReport(
            reports);
        _printReport(cReport).then((_) {
          completer.complete();
        }).catchError((error) {
          completer.completeError(error);
        });
      }
    });

    return completer.future;
  }

  Future _printReport(_ConsolidatedDailyReport report) {
    Completer completer = new Completer();
    if (report != null) {
      print(r'=====================================');
      print('Daily report ${_formatDate(report._startDate)} >> ${_formatDate(
          report._endDate)}');
      print(r'=====================================');
      final Iterable<_DevelopmentDailyEntry> entries = report._entriesByRank;
      if (hasValue(entries)) {
        print(
            'Description                                                                      Prev. Plan   Current stat Plan status  C. hours');
        print(
            '-------------------------------------------------------------------------------- ------------ ------------ ------------ --------');
        _findWorkItemNames(entries).then((Map<String, String> names) {
          entries.forEach((_DevelopmentDailyEntry entry) {
            _printEntry(entry, names);
          });
          completer.complete();
        }).catchError((error) {
          completer.completeError(error);
        });
      } else {
        print("--- No entry. --");
        completer.complete();
      }
    } else {
      print("*** 'null' consolidates report. ***");
      completer.complete();
    }
    return completer.future;
  }

  // DE5887                                                                           :: N/A       >> RTP       >> N/A       ::   N/A
  // Description                                                                      Prev. Plan   Current stat Plan status  C. hours
  // -------------------------------------------------------------------------------- ------------ ------------ ------------ --------

  void _printEntry(_DevelopmentDailyEntry entry,
      Map<String, String> workItemNames) {
    String description = () {
      if (entry._isWorkItem) {
        return "${_formatString(entry._key, 7)} - "
            "${workItemNames == null || workItemNames[entry._key] == null ?
        '*** Work item not found.***' : workItemNames[entry._key]}";
      } else {
        return entry._key;
      }
    }();

    //String description = entry._key;
    String s = "${_formatString(description, 80)} :: "
        "${_formatStatus(entry._previousPlannedStatus)} >> "
        "${_formatStatus(entry._currentStatus)} >> "
        "${_formatStatus(entry._plannedStatus)} :: "
        "${_formatDouble(entry._hours)}";
    print(s);
  }

  Future<Map<String, String>> _findWorkItemNames(
      Iterable<_DevelopmentDailyEntry> entries) {
    if (hasValue(entries)) {
      List<Future<RDWorkItem>> futures = [];
      entries.forEach((_DevelopmentDailyEntry entry) {
        if (entry._isWorkItem) {
          Future<RDWorkItem> future = rallyService.getWorkItem(entry._key);
          futures.add(future);
          future.whenComplete(() {
            stdout.write("${entry._key}\r");
          });
        }
      });
      Completer<Map<String, String>> completer = new Completer();
      Future.wait(futures, eagerError: false).then((
          List<RDWorkItem> workItems) {
        if (hasValue(workItems)) {
          Map<String, String> result = {};
          workItems.forEach((RDWorkItem workItem) {
            result[workItem.formattedID] = workItem.name;
          });
          completer.complete(result);
        } else {
          completer.complete(null);
        }
      }).catchError((error) {
        completer.completeError(error);
      });

      return completer.future;
    }
    return null;
  }
}

String _formatDate(DateTime date) {
  if (date != null) {
    String s = "${date.day < 10 ? '0' : ''}${date.day}-"
        "${date.month < 10 ? '0' : ''}${date.month}-${date.year}";
    return s;
  }
  return null;
}

String _formatString(String string, int length) {
  if (string != null) {
    if (string.length > length) return string.substring(0, length);
    return _formatString(
        '${string}                                  ', length);
  }
  return null;
}

String _formatStatus(Status status) {
  if (status != null) {
    return _formatString('${status.toString()}                 ', 9);
  }
  return _formatString('N/A', 9);
}

String _formatDouble(double value) {
  String s = "           ${value == null ? 'N/A' : value.toString()}";
  int i = s.lastIndexOf('.');
  if (i > -1 && i == s.length - 2) {
    s = '${s}0';
  }
  s = s.substring(s.length - 5);
  return s;
}


class _ConsolidatedDailyReport {

  DateTime _startDate;
  DateTime _endDate;
  Map<String, _DevelopmentDailyEntry> _devEntriesMap = {};

  _ConsolidatedDailyReport(Iterable<DailyReport> reports) {
    _digestDailyReports(reports);
  }

  Iterable<_DevelopmentDailyEntry> get _entriesByRank {
    if (hasValue(_devEntriesMap)) {
      List<_DevelopmentDailyEntry> list = new List<_DevelopmentDailyEntry>.
      from(_devEntriesMap.values);
      list.sort((_DevelopmentDailyEntry entry1, _DevelopmentDailyEntry entry2) {
        return entry1._rank.compareTo(entry2._rank);
      });
      return list;
    }
    return null;
  }

  void _digestDailyReports(Iterable<DailyReport> reports) {
    if (hasValue(reports)) {
      reports.forEach((DailyReport report) {
        if (report.date == null) throw "Daily report w/o a date.";
        if (_startDate == null || _startDate.isAfter(report.date))
          _startDate = report.date;
        if (_endDate == null || _endDate.isBefore(report.date))
          _endDate = report.date;
      });
      reports.forEach((DailyReport report) {
        _digestDailyReport(report);
      });
    }
  }

  void _digestDailyReport(DailyReport report) {
    if (report != null) {
      _digestDailyEntries(report.date, report.entries);
    }
  }

  void _digestDailyEntries(DateTime date, Iterable<DailyEntry> entries) {
    if (hasValue(entries)) {
      entries.forEach((DailyEntry entry) {
        _digestDailyEntry(date, entry);
      });
    }
  }

  void _digestDailyEntry(DateTime date, DailyEntry entry) {
    if (entry != null) {
      if (entry.process == Process.DEVELOPMENT &&
          (hasValue(entry.workItemCode) || hasValue(entry.statement))) {
        String key = hasValue(entry.workItemCode) ? entry.workItemCode :
        entry.statement;

        _DevelopmentDailyEntry devEntry = _devEntriesMap[key];
        if (devEntry == null) {
          devEntry = new _DevelopmentDailyEntry()
            .._key = key
            .._rank = 'z$key'
            .._isWorkItem = hasValue(entry.workItemCode);
          _devEntriesMap[key] = devEntry;
        }
        if (entry.scope == Scope.PAST) {
          if (entry.hours != null) devEntry._hours = devEntry._hours == null ?
          entry.hours : devEntry._hours + entry.hours;
          if (devEntry._currentStatus == null ||
              devEntry._currentStatusDate.isBefore(date) ||
              (devEntry._currentStatusDate == date &&
                  devEntry._currentStatus < entry.status)) {
            devEntry._currentStatus = entry.status;
            devEntry._currentStatusDate = date;
          }
        } else {
          if (date == _endDate) {
            if (devEntry._plannedStatus == null ||
                devEntry._plannedStatus < entry.status) {
              devEntry._plannedStatus = entry.status;
            }
          } else {
            if (devEntry._previousPlannedStatus == null ||
                devEntry._previousPlannedStatusDate.isBefore(date) ||
                (devEntry._previousPlannedStatusDate == date &&
                    devEntry._previousPlannedStatus < entry.status)) {
              devEntry._previousPlannedStatus = entry.status;
              devEntry._previousPlannedStatusDate = date;
            }
          }
        }
      }
    }
  }
}

class _DevelopmentDailyEntry {

  bool _isWorkItem;
  String _rank;
  String _key;
  Status _plannedStatus;
  Status _previousPlannedStatus;
  DateTime _previousPlannedStatusDate;
  Status _currentStatus;
  DateTime _currentStatusDate;
  double _hours;

}

void main(List<String> args) {

  print("\[\033[0;34m\]");

}
