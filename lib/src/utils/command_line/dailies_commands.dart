import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdout;

import 'package:logging/logging.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'package:resource/resource.dart';

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/daily/comparators.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/utils/mailer.dart';

Printer _p = new Printer();

class ListDailies extends UtilOptionCommand {

  String get abbr => r"d";

  String get help =>
      r'Utility for listing daylies. An integer number must be provided.';

  const ListDailies();

  void executeOption(String option) {
    bool formatted = !(hasValue(option) && option.startsWith(r'r'));
    DateTime refDate = () {
      if (!hasValue(option) || option.indexOf(r't') > -1)
        return new DateTime.now();
      if (option.length > 9) {
        return DateTime.parse(
            option.startsWith(r'r') || option.startsWith(r'd') ? option
                .substring(1) : option);
      }
      return null;
    }();
    int number = () {
      if (refDate == null)
        return int.parse(
            option.startsWith(r'r') || option.startsWith(r'd') ? option
                .substring(1) : option);
      return null;
    }();

    if (formatted) {
      if (refDate != null) {
        _printFormattedByDate(refDate);
      } else if (number != null) {
        // TODO
      }
    } else {
      if (refDate != null) {
        _printRawByDate(refDate);
      } else if (number != null) {
        _printRawByNumber(number);
      }
    }
  }

  _printRawByNumber(int value) async {
    List<String> list = await dailyDAO.getLastDailyReportsAsJson(number: value);
    _p.writeln(list);
  }

  _printRawByDate(DateTime value) async {
    List<String> list = await dailyDAO.getLastDailyReportsAsJson(
        dateReference: value, number: 2);
    _p.writeln(list);
  }

  _printFormattedByDate(DateTime value) async {
    List<DailyReport> list = await dailyDAO.getLastDailyReports(
        dateReference: value, number: 2);
    if (hasValue(list)) {
      _digest(list).then((Map<String, dynamic> digested) {
        if (hasValue(digested) && hasValue(digested['team-members-map'])) {
          if (digested['previous-date'] == null) {
            _p.title('Daily report ${formatDate(
                list[0].date)}. Hours: ${digested['hours-a'] +
                digested['hours-b']} [A:${digested['hours-a']}/B:${digested['hours-b']}]');
          } else {
            _p.title('Daily report ${formatDate(list[1].date)} >> ${formatDate(
                list[0].date)}. Hours: ${digested['hours-a'] +
                digested['hours-b']} [A:${digested['hours-a']}/B:${digested['hours-b']}]');
          }
          if (!hasValue(list[0].entries)) {
            _p.section(r'Current plan -NONE-');
          } else {
            List<String> teamMembers = new List.from(
                digested['team-members-map'].keys);
            teamMembers.sort();
            teamMembers.forEach((String teamMember) {
              Map<String,
                  dynamic> tmMap = digested['team-members-map'][teamMember];
              _p.section('Current plan for ${teamMember}', r'··············');
              List<DailyEntry> currentPlan =
              tmMap[r'plan'];
              if (hasValue(currentPlan)) {
                List<PrinterColumn> cols = [
                  _p.column(r'Process', 11),
                  _p.column(r'Description', 100),
                  _p.column(r'Planned S.', 10),
                ];
                cols.forEach((PrinterColumn col) => col.writeTitle());
                _p.writeln();
                cols.forEach((PrinterColumn col) => col.writeSeparator());
                _p.writeln();
                currentPlan.sort(composeComparator(processPart, keyPart));
                currentPlan.forEach((DailyEntry entry) {
                  cols[0].write(entry.process);
                  if (hasValue(entry.workItemCode)) {
                    cols[1].write(
                        '${entry.workItemCode} ${digested['work-items'][entry
                            .workItemCode].name}');
                  } else {
                    cols[1].write(_desc(entry));
                  }
                  cols[2].write(entry.status);
                  _p.writeln();
                  if (hasValue(entry.workItemCode) &&
                      hasValue(entry.statement)) {
                    cols[0].write(r'             ');
                    cols[1].write('* ${entry.statement}');
                    _p.writeln();
                  }
                  if ((hasValue(entry.workItemCode) ||
                      hasValue(entry.statement)) && hasValue(entry.notes)) {
                    cols[0].write(r'             ');
                    cols[1].write('~ ${entry.notes}');
                    _p.writeln();
                  }
                });
                _p.writeln();
              } else {
                _p.writeln(r'- NONE -');
              }

              //##############################################################
              //_p.writeln(r'*****************************************');
              //##############################################################
              _p.section(
                  'Report from ${teamMember}. Hours: ${tmMap['hours-a'] +
                      tmMap['hours-b']} [A:${tmMap['hours-a']}/B:${tmMap['hours-b']}]',
                  r'··············');
              List<DailyEntry> reported = tmMap[r'reported'];
              if (hasValue(reported)) {
                List<PrinterColumn> cols = [
                  _p.column(r'Process', 11),
                  _p.column(r'Description', 81),
                  _p.column(r'Prev. Sta.', 10),
                  _p.column(r'Report. Sta.', 12),
                  _p.column(r' Hours', 6),
                ];
                cols.forEach((PrinterColumn col) => col.writeTitle());
                _p.writeln();
                cols.forEach((PrinterColumn col) => col.writeSeparator());
                _p.writeln();
                reported.sort(composeComparator(processPart, keyPart));
                reported.forEach((DailyEntry entry) {
                  cols[0].write(entry.process);
                  if (hasValue(entry.workItemCode)) {
                    cols[1].write(
                        '${entry.workItemCode} ${digested['work-items'][entry
                            .workItemCode].name}');
                  } else {
                    cols[1].write(_desc(entry));
                  }
                  String key = _key(entry);
                  Status prevStatus = tmMap['previous-plan'] != null &&
                      tmMap['previous-plan'][key] != null ?
                  tmMap['previous-plan'][key] : null;
                  cols[2].write(
                      prevStatus == null ? '-' : prevStatus.toString());
                  cols[3].write(
                      '${_progressSymbol(prevStatus, entry.status)} ${entry
                          .status.toString()}');
                  cols[4].writeRight(entry.hours == null ? '-' : entry.hours);
                  if (!hasValue(entry.workItemCode) &&
                      !hasValue(entry.statement))
                    _p.write(r':');
                  _p.writeln();
                  if (hasValue(entry.workItemCode) &&
                      hasValue(entry.statement)) {
                    cols[0].write(r' ');
                    cols[1].write('* ${entry.statement}');
                    _p.writeln();
                  }
                  if ((hasValue(entry.workItemCode) ||
                      hasValue(entry.statement)) && hasValue(entry.notes)) {
                    cols[0].write(r' ');
                    cols[1].write('~ ${entry.notes}');
                    _p.writeln();
                  }
                });
                List<DailyEntry> unreported = tmMap[r'unreported'];
                if (hasValue(unreported)) {
                  List<PrinterColumn> cols = [
                    _p.column(r'Process', 11),
                    _p.column(r'Description', 81),
                    _p.column(r'Prev. Sta.', 10),
                    _p.column(r'Report. Sta.', 12),
                    _p.column(r' Hours', 6),
                  ];
                  unreported.sort(composeComparator(processPart, keyPart));
                  unreported.forEach((DailyEntry entry) {
                    cols[0].write(entry.process);
                    if (hasValue(entry.workItemCode)) {
                      cols[1].write(
                          '${entry.workItemCode} ${digested['work-items'][entry
                              .workItemCode].name}');
                    } else {
                      cols[1].write(_desc(entry));
                    }
                    cols[2].write(entry.status);
                    cols[3].write('${_progressSymbol(entry.status, null)} -');
                    _p.writeln();
                    if (hasValue(entry.workItemCode) &&
                        hasValue(entry.statement)) {
                      cols[0].write(r' ');
                      cols[1].write('* ${entry.statement}');
                      _p.writeln();
                    }
                    if ((hasValue(entry.workItemCode) ||
                        hasValue(entry.statement)) && hasValue(entry.notes)) {
                      cols[0].write(r' ');
                      cols[1].write('~ ${entry.notes}');
                      _p.writeln();
                    }
                  });
                }
                _p.writeln();
              } else {
                _p.writeln(r'- NONE -');
              }
              _p.writeln(formatString(r'################', 125, r'##########'));
            });
          }
        } else {
          // TODO no team member digested
        }
      });
    }
  }

  String _desc(DailyEntry entry) {
    if (hasValue(entry.workItemCode)) return entry.workItemCode;
    if (hasValue(entry.statement)) return '* ${entry.statement}';
    return '~ ${entry.notes}';
  }

  String _key(DailyEntry entry) {
    return '${entry.process.toString()} # ${_desc(entry)}';
  }

  Future<Map<String, dynamic>> _digest(List<DailyReport> list) {
    Set<String> workItemCodes = new Set<String>();
    double hoursA = 0.0;
    double hoursB = 0.0;
    Map<String, dynamic> byTeamMember = {};
    list[0].entries.forEach((DailyEntry entry) {
      if (hasValue(entry.workItemCode)) workItemCodes.add(entry.workItemCode);
      Map<String, dynamic> teamMemberRecord = byTeamMember.putIfAbsent(
          entry.teamMemberCode, () {
        return {'hours-a': 0.0, 'hours-b': 0.0};
      });
      if (entry.scope == Scope.TODAY) {
        List<DailyEntry> currentPlan = teamMemberRecord.putIfAbsent(
            r'plan', () {
          return [];
        });
        currentPlan.add(entry);
      } else {
        Set<String> reportedKeys = teamMemberRecord.putIfAbsent(
            r'reported-keys', () => new Set<String>());
        reportedKeys.add(_key(entry));
        List<DailyEntry> reported = teamMemberRecord.putIfAbsent(
            r'reported', () => []);
        reported.add(entry);
        if (entry.hours != null) {
          if (hasValue(entry.workItemCode) || hasValue(entry.statement)) {
            teamMemberRecord['hours-a'] += entry.hours;
            hoursA += entry.hours;
          } else {
            teamMemberRecord['hours-b'] += entry.hours;
            hoursB += entry.hours;
          }
        }
      }
    });
    Map<String, dynamic> map = {
      'date': list[0].date.toIso8601String(),
      'hours-a': hoursA,
      'hours-b': hoursB,
      'team-members-map': byTeamMember
    };

    if (list.length > 1) {
      map['previous-date'] = list[1].date.toIso8601String();
      if (hasValue(list[1].entries)) {
        list[1].entries.forEach((DailyEntry entry) {
          if (entry.scope == Scope.TODAY) {
            if (hasValue(entry.workItemCode)) workItemCodes.add(
                entry.workItemCode);
            Map<String, dynamic> teamMemberRecord = byTeamMember.putIfAbsent(
                entry.teamMemberCode, () {
              return {'hours-a': 0.0, 'hours-b': 0.0};
            });
            Map<String, Status> previousPlan = teamMemberRecord.putIfAbsent(
                r'previous-plan', () {
              return {};
            });
            String key = _key(entry);
            Set<String> reportedKeys = teamMemberRecord[r'reported-keys'];
            if (hasValue(reportedKeys) && reportedKeys.contains(key)) {
              Status stat = previousPlan.putIfAbsent(key, () => entry.status);
              if (stat < entry.status) previousPlan[key] = entry.status;
            } else {
              List<DailyEntry> unreported = teamMemberRecord.putIfAbsent(
                  'unreported', () => []);
              unreported.add(entry);
            }
          }
        });
      }
    }

    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    if (hasValue(workItemCodes)) {
      map['work-item-codes'] = workItemCodes;
      _findWorkItems(workItemCodes).then((Map<String, RDWorkItem> wItems) {
        map['work-items'] = wItems;
        completer.complete(map);
      }).whenComplete(() {
        rallyService.close();
      });
    } else {
      completer.complete(map);
    }
    return completer.future;
  }
}

typedef Future _entriesPrinter();

class SpreadDaily extends UtilOptionCommand {

  static const String logName = "spread-daily";

  static Logger _log = new Logger(logName);

  const SpreadDaily();

  String get abbr => r"s";

  String get help => r'Utility to spread dailies.';

  void executeOption(String option) {
    Map<String, dynamic> conf = cfgValue('spread_daily')['conf-${option}'];
    int number = conf['number'];
    _executeOption(number, conf);
  }

  void _executeOption(int number, Map<String, dynamic> conf) {
    dailyDAO.getLastDailyReports(number: number).then((
        List<DailyReport> reports) {
      if (!hasValue(reports)) {
        _p.writeln(r'No daily report found!.');
      } else {
        switch (conf['mode']) {
          case 'html':
            _ConsolidatedDailyReportsDigester digester =
            new _ConsolidatedDailyReportsDigester(reports);
            _HtmlWorker htmlW = new _HtmlWorker(digester, conf['template']);
            htmlW._process().then((String html) {
              _ResultWorker resultW = new _ResultWorker(conf,
                  '[PSNow] Daily report ${formatDate(
                      digester._startDate)} >> ${formatDate(
                      digester._endDate)}', html);
              resultW._process();
            }).catchError((error) {});
            break;
          case 'html-member':
            break;
          default:
            _ConsolidatedDailyReportsDigester digester =
            new _ConsolidatedDailyReportsDigester(reports);
            _printReport(digester);
        }
      }
    });
  }

  void _printReport(_ConsolidatedDailyReportsDigester digester) {
    if (digester != null) {
      _p.writeln(r'====================================================');
      _p.writeln(
          'Daily report ${formatDate(digester._startDate)} >> ${formatDate(
              digester._endDate)} - Hours: ${formatDouble(digester._hours)}');
      _p.writeln(r'====================================================');
      List<_entriesPrinter> entriesPrinter = [];
      Iterable<_StandardDailyEntry> devEntries = digester._devEntriesByRank;
      if (hasValue(devEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'DEVELOPMENT', devEntries);
        });
      }
      Iterable<_StandardDailyEntry> inquiryEntries = digester
          ._inquiriesEntriesByRank;
      if (hasValue(inquiryEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'INQUIRIES', inquiryEntries);
        });
      }
      entriesPrinter.add(() {
        return _printDeployments(digester);
      });
      entriesPrinter.add(() {
        return _printHours(digester);
      });
      if (!hasValue(entriesPrinter)) {
        _p.writeln(r"*** No entries. ***");
      } else {
        Future.forEach(entriesPrinter, (_entriesPrinter) {
          return _entriesPrinter();
        }).whenComplete(() {
          rallyService.close();
        });
      }
    } else {
      _p.writeln(r"*** 'null' consolidate report. ***");
    }
  }

  _printDeployments(_ConsolidatedDailyReportsDigester digester) {
    if (digester != null) {
      _p.section(r'DEPLOYMENTS');
      if ((hasValue(digester._deploymentPlan) ||
          hasValue(digester._deploymentReported))) {
        if (hasValue(digester._deploymentReported)) {
          _p.write('[REPORTED: ');
          Environment.VALUES.forEach((Environment env) {
            if (digester._deploymentReported[env] != null) {
              _p.write(
                  '- ${env.value} >> ${digester._deploymentReported[env]
                      .value} ');
            }
          });
          _p.write(']');
        }
        if (hasValue(digester._deploymentPlan)) {
          _p.write('[PLANNED: ');
          Environment.VALUES.forEach((Environment env) {
            if (digester._deploymentPlan[env] != null) {
              _p.write(
                  '- ${env.value} >> ${digester._deploymentPlan[env].value} ');
            }
          });
          _p.write(']');
        }
        _p.writeln().writeln();
      } else {
        _p.writeln('-- NONE --').writeln();
      }
    }
  }

  Future _printEntries(String title, Iterable<_StandardDailyEntry> entries) {
    Completer completer = new Completer();
    if (hasValue(entries)) {
      _p.section(title);
      _p.writeln(
          r'Description                                                                      Prev. Plan   Reported st. Plan status   Hours');
      _p.writeln(
          r'-------------------------------------------------------------------------------- ------------ ------------ ------------ --------');

      _findWorkItems(_extractWorkItemCodes(entries)).then((
          Map<String, RDWorkItem> workItems) {
        entries.forEach((_StandardDailyEntry entry) {
          _printEntry(entry, workItems);
        });
        _p.writeln();
        completer.complete();
      }).catchError((error) {
        _log.severe(error);
        _p.errorln(error);
        completer.completeError(error);
      });
    } else {
      _p.writeln(r"--- No entry. --");
      completer.complete();
    }
    return completer.future;
  }

  void _printEntry(_StandardDailyEntry entry,
      Map<String, RDWorkItem> workItems) {
    String description = () {
      if (entry._hasWorkItem) {
        return "${formatString(entry._workItemCode, 7)} - "
            "${workItems == null || workItems[entry._workItemCode] == null ?
        '*** Work item not found [${entry._workItemCode}].***' :
        workItems[entry._workItemCode].name}";
      } else {
        return entry._statement;
      }
    }();

    String s = "${formatString(description, 80)} :: "
        "${formatStatus(entry._previousPlannedStatus)} "
        "${_reportedSymbol(entry)}> "
        "${formatStatus(entry._reportedStatus)} "
        "${_plannedSymbol(entry)} "
        "${formatStatus(entry._plannedStatus)} :: "
        "${formatDouble(entry._hours)}";
    _p.writeln(s);
  }

  _printHours(_ConsolidatedDailyReportsDigester digester) {
    if (digester != null) {
      _p.section(r'HOURS');
      double total = 0.0;
      new List.from(digester._teamMemberHours.keys)
        ..sort()
        ..forEach((String s) {
          double value = digester._teamMemberHours[s];
          _p.writeln('${formatString(s, 10)} -> ${formatDouble(value)}');
          if (value != null) total += value;
        });
      _p.writeln(r'----------------------------------');
      _p.writeln('${formatString(r'  Total', 10)} -> ${formatDouble(total)}');
      _p.writeln();
    }
  }
}

String _progressSymbol(Status prevStatus, Status status) =>
    prevStatus == null && status == null ? r':' :
    prevStatus == null && status != null ? r'*' :
    prevStatus != null && status != null && status > prevStatus ? r'+' :
    prevStatus != null && status != null && status < prevStatus ? r'-' :
    prevStatus != null && status == null ? r'-' :
    r'>';

String _reportedSymbol(_StandardDailyEntry entry) =>
    _progressSymbol(entry._previousPlannedStatus, entry._reportedStatus);

String _plannedSymbol(_StandardDailyEntry entry) =>
    entry._plannedStatus == null ? r'::' : entry._reportedStatus !=
        null && entry._plannedStatus != null &&
        entry._plannedStatus > entry._reportedStatus ? r'+>' : entry
        ._reportedStatus != null && entry._plannedStatus != null &&
        entry._plannedStatus < entry._reportedStatus ? r'->' : r'>>';

Iterable<String> _extractWorkItemCodes(Iterable<_StandardDailyEntry> entries) {
  Set<String> codes = new Set<String>();
  entries.forEach((_StandardDailyEntry entry) {
    if (entry._hasWorkItem) codes.add(entry._workItemCode);
  });
  return hasValue(codes) ? codes : null;
}

Future<Map<String, RDWorkItem>> _findWorkItems(Iterable<String> wiCodes) async {
  if (!hasValue(wiCodes)) return null;
  Map<String, RDWorkItem> map = {};
  await for (RDWorkItem workItem in rallyService.getWorkItems(wiCodes)) {
    map[workItem.formattedID] = workItem;
    stdout.write("${workItem.formattedID}     \r");
  }
  return map;
}

typedef bool _EntryFilter(DailyEntry entry);

bool _defaultFilter(DailyEntry entry) => true;

abstract class _DailyReportsDigester {

  DateTime _startDate;
  DateTime _endDate;
  _EntryFilter _entryFilter;
  Iterable<DailyReport> _reports;

  double get hours;

  _DailyReportsDigester(this._reports, [this._entryFilter = _defaultFilter]) {
    _entryFilter ??= _defaultFilter;
    _digestDailyReports(_reports);
  }

  void _digestDailyReports(Iterable<DailyReport> reports) {
    if (hasValue(reports)) {
      reports.forEach((DailyReport report) {
        if (report.date == null) throw r"Daily report w/o a date.";
        if (_startDate == null || _startDate.isAfter(report.date))
          _startDate = report.date;
        if (_endDate == null || _endDate.isBefore(report.date))
          _endDate = report.date;
      });
      reports.forEach((DailyReport report) {
        _digestDailyReport(report);
      });
      _doAfter();
    }
  }

  void _doAfter();

  void _digestDailyReport(DailyReport report) {
    if (report != null) {
      _digestDailyEntries(report.date, report.entries);
    }
  }

  void _digestDailyEntries(DateTime date, Iterable<DailyEntry> entries) {
    if (hasValue(entries)) {
      Iterable<DailyEntry> filtered = entries.where((DailyEntry entry) =>
          _entryFilter(entry));
      filtered.forEach((DailyEntry entry) {
        _digestDailyEntry(date, entry);
      });
    }
  }

  void _digestDailyEntry(DateTime date, DailyEntry entry);
}


class _ConsolidatedDailyReportsDigester extends _DailyReportsDigester {

  Map<String, _StandardDailyEntry> _devEntriesMap = {};
  Map<String, _StandardDailyEntry> _inquiriesEntriesMap = {};
  Map<Environment, Status> _deploymentPlan = {};
  Map<Environment, Status> _deploymentReported = {};

  Map<String, double> _teamMemberHours = {};

  double _hours = 0.0;

  double get hours => _hours;

  _ConsolidatedDailyReportsDigester(Iterable<DailyReport> reports,
      [_EntryFilter _entryFilter]) : super (reports, _entryFilter);

  Iterable<_StandardDailyEntry> get _devEntriesByRank =>
      _entriesByRank(_devEntriesMap);

  Iterable<_StandardDailyEntry> get _inquiriesEntriesByRank =>
      _entriesByRank(_inquiriesEntriesMap);

  Iterable<_StandardDailyEntry> _entriesByRank(
      Map<String, _StandardDailyEntry> targetMap) {
    if (hasValue(targetMap)) {
      List<_StandardDailyEntry> list = new List<_StandardDailyEntry>.
      from(targetMap.values);
      list.sort((_StandardDailyEntry entry1, _StandardDailyEntry entry2) {
        return entry1._rank.compareTo(entry2._rank);
      });
      return list;
    }
    return null;
  }

  @override
  void _doAfter() {
    // Clean unnecessary maps entries
    Iterable<String> ite = new List.from(_devEntriesMap.keys);
    ite.forEach((String s) {
      _StandardDailyEntry entry = _devEntriesMap[s];
      if (entry._reportedStatus == null && entry._plannedStatus == null &&
          entry._previousPlannedStatus == null)
        _devEntriesMap.remove(s);
    });
    ite = new List.from(_inquiriesEntriesMap.keys);
    ite.forEach((String s) {
      _StandardDailyEntry entry = _inquiriesEntriesMap[s];
      if (entry._reportedStatus == null && entry._plannedStatus == null &&
          entry._previousPlannedStatus == null)
        _inquiriesEntriesMap.remove(s);
    });
  }

  void _digestDailyEntry(DateTime date, DailyEntry entry) {
    if (entry != null) {
      if (entry.scope == Scope.PAST && entry.hours != null &&
          date == _endDate) {
        _teamMemberHours[entry.teamMemberCode] =
        _teamMemberHours[entry.teamMemberCode] == null ? entry.hours :
        _teamMemberHours[entry.teamMemberCode] + entry.hours;
      }
      if ((entry.process == Process.DEVELOPMENT ||
          entry.process == Process.INQUIRIES) &&
          (hasValue(entry.workItemCode) || hasValue(entry.statement))) {
        String key = hasValue(entry.workItemCode) ? entry.workItemCode :
        entry.statement;

        Map<String, _StandardDailyEntry> targetMap = entry.process ==
            Process.INQUIRIES ? _inquiriesEntriesMap : _devEntriesMap;

        _StandardDailyEntry myEntry = targetMap[key];
        if (myEntry == null) {
          myEntry = new _StandardDailyEntry()
          //.._entryKey = key
            .._rank = hasValue(entry.workItemCode) ? key : 'z$key'
            .._notes = entry.notes
            .._statement = entry.statement
            .._workItemCode = entry.workItemCode;
          targetMap[key] = myEntry;
        }
        if (entry.scope == Scope.PAST) {
          if ((date == _endDate) &&
              (myEntry._reportedStatus == null ||
                  myEntry._reportedStatus < entry.status)) {
            myEntry._reportedStatus = entry.status;
            if (entry.hours != null) {
              myEntry._hours =
              myEntry._hours == null ? entry.hours : myEntry._hours +
                  entry.hours;
              _hours += entry.hours;
            }
          }
        } else {
          if (date == _endDate) {
            if (myEntry._plannedStatus == null ||
                myEntry._plannedStatus < entry.status) {
              myEntry._plannedStatus = entry.status;
            }
          } else {
            if (myEntry._previousPlannedStatus == null ||
                myEntry._previousPlannedStatusDate.isBefore(date) ||
                (myEntry._previousPlannedStatusDate == date &&
                    myEntry._previousPlannedStatus < entry.status)) {
              myEntry._previousPlannedStatus = entry.status;
              myEntry._previousPlannedStatusDate = date;
            }
          }
        }
      } else if (entry.process == Process.DEPLOYMENT && date == _endDate &&
          hasValue(entry.environments)) {
        if (entry.scope == Scope.TODAY) {
          entry.environments.forEach((Environment env) {
            if (_deploymentPlan[env] == null ||
                _deploymentPlan[env] < entry.status) {
              _deploymentPlan[env] = entry.status;
            }
          });
        } else {
          entry.environments.forEach((Environment env) {
            if (_deploymentReported[env] == null ||
                _deploymentReported[env] < entry.status) {
              _deploymentReported[env] = entry.status;
            }
          });
        }
      }
    }
  }
}

class _StandardDailyEntry {

  //String _entryKey;
  String _rank;
  Status _plannedStatus;
  Status _previousPlannedStatus;
  DateTime _previousPlannedStatusDate;
  Status _reportedStatus;
  double _hours;
  String _workItemCode;
  String _statement;
  String _notes;

  bool get _hasWorkItem => hasValue(_workItemCode);

  bool get _hasStatement => hasValue(_statement);

}

class _ContextMapBuilder {

  static Logger _log = SpreadDaily._log;

  Future<Map<String, dynamic>> _createMap(
      _ConsolidatedDailyReportsDigester digester) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    if (digester != null) {
      Map<String, dynamic> map = {
        'startDate': formatDate(digester._startDate),
        'endDate': formatDate(digester._endDate)
      };
      List generatorModel = [];


      Iterable<_StandardDailyEntry> devEntries = digester._devEntriesByRank;
      if (hasValue(devEntries)) {
        map['development?'] = true;
        generatorModel.add(() {
          return _entries(devEntries)
              .then((List list) {
            map['developmentEntries'] = list;
          });
        });
      }

      Iterable<_StandardDailyEntry> inquiryEntries = digester
          ._inquiriesEntriesByRank;
      if (hasValue(inquiryEntries)) {
        map['inquiries?'] = true;
        generatorModel.add(() {
          return _entries(inquiryEntries)
              .then((List list) {
            map['inquiriesEntries'] = list;
          });
        });
      }

      generatorModel.add(() {
        map['deployments'] = _deployments(digester);
        map['reportedDeployments'] = map['deployments']['reported'];
        map['plannedDeployments'] = map['deployments']['planned'];
        map['reportedDeployments?'] = hasValue(map['reportedDeployments']);
        map['plannedDeployments?'] = hasValue(map['plannedDeployments']);
        return map;
      });


      if (!hasValue(generatorModel)) {
        completer.complete(null);
      } else {
        Future.forEach(generatorModel, (_mapGenerator) {
          return _mapGenerator();
        }).whenComplete(() {
          rallyService.close();
          completer.complete(map);
        });
      }
    } else {
      completer.complete(null);
    }
    return completer.future;
  }

  Future<List> _entries(Iterable<_StandardDailyEntry> entries) {
    Completer<List> completer = new Completer<List>();
    _findWorkItems(_extractWorkItemCodes(entries)).then((
        Map<String, RDWorkItem> workItems) {
      List list = [];
      bool back = true;
      entries.forEach((_StandardDailyEntry entry) {
        Map map = _entryToMap(entry, workItems);
        back = !back;
        map ['backColor'] = back ? '#ECECEC' : 'white';
        list.add(map);
      });
      _p.writeln();
      completer.complete(list);
    }).catchError((error) {
      _log.severe(error);
      _p.errorln(error);
      completer.completeError(error);
    });

    return completer.future;
  }

  Map<String, dynamic> _entryToMap(_StandardDailyEntry entry,
      Map<String, RDWorkItem> workItems) {
    Map<String, dynamic> map = {};
    if (entry._hasWorkItem) {
      map['workItem?'] = true;
      map['workItemCode'] = entry._workItemCode;
      map['workItemTitle'] = workItems[entry._workItemCode].name;
    }
    map['statement?'] = entry._hasStatement;
    map['statement'] = entry._statement;
    map['previousPlannedStatus'] = entry._previousPlannedStatus == null ? r'-' :
    entry._previousPlannedStatus.toString();
    map['reportedStatus'] = entry._reportedStatus == null ? r'-' :
    entry._reportedStatus.toString();
    map['plannedStatus'] = entry._plannedStatus == null ? r'-' :
    entry._plannedStatus.toString();
    map['hours'] = formatDouble(entry._hours);
    String reportedSymbol = _reportedSymbol(entry);
    String plannedSymbol = _plannedSymbol(entry);
    map['reportedStatusSymbol'] = reportedSymbol;
    map['plannedStatusSymbol'] = plannedSymbol;
    map['reportedStatusSymbolStyle'] =
    reportedSymbol[0] == r'-' ? 'color: white; background: red;' :
    reportedSymbol[0] == r'+' ? 'color: black; background: LightGreen;' :
    reportedSymbol[0] == r'*' ? 'color: black; background: gold;' :
    reportedSymbol[0] == r'>' ? 'color: white; background: green;' : '';
    map['plannedStatusSymbolStyle'] =
    r'-'.indexOf(plannedSymbol[0]) > -1 ? 'color: red;' : '';
    return map;
  }

  Map _deployments(_ConsolidatedDailyReportsDigester digester) {
    Map map = {};
    if (hasValue(digester._deploymentReported)) {
      List list = [];
      Environment.VALUES.forEach((Environment env) {
        if (digester._deploymentReported[env] != null) {
          list.add({
            'environment': env.toString(),
            'status': digester._deploymentReported[env].toString()
          });
        }
      });
      map['reported?'] = true;
      map['reported'] = list;
    }
    if (hasValue(digester._deploymentPlan)) {
      List list = [];
      Environment.VALUES.forEach((Environment env) {
        if (digester._deploymentPlan[env] != null) {
          list.add({
            'environment': env.toString(),
            'status': digester._deploymentPlan[env].toString()
          });
        }
      });
      map['planned?'] = true;
      map['planned'] = list;
    }
    return map;
  }
}

class _HtmlWorker {

  static const String logName = "html-worker";

  static Logger _log = new Logger('${SpreadDaily.logName}.$logName');

  _DailyReportsDigester _cReport;
  String _template;

  _HtmlWorker(this._cReport, this._template);

  Future<String> _process() {
    _ContextMapBuilder builder = new _ContextMapBuilder();
    Completer <String> completer = new Completer<String>();
    builder._createMap(_cReport).then((Map<String, dynamic> context) {
      if (context != null) {
        String resourceKey = 'package:${cfgValue(
            'templates')}/${_template}';
        Resource cfgResource = new Resource(resourceKey);
        cfgResource.readAsString(encoding: UTF8).then((String template) {
          String html = render(template, context);
          completer.complete(html);
        }).catchError((error) {
          _log.severe(error);
          completer.completeError(error);
        });
      } else {
        _p.errorln('No context for HTML.');
        completer.complete();
      }
    }).catchError((error) {
      _log.severe(error);
      completer.completeError(error);
    });
    return completer.future;
  }
}

class _ResultWorker {

  static const String logName = "result-worker";

  static Logger _log = new Logger('${SpreadDaily.logName}.$logName');

  Map<String, dynamic> _conf;
  String _subject, _result;

  _ResultWorker(this._conf, this._subject, this._result);

  Future _process() {
    Completer completer = new Completer();
    if (_conf['out']) _p.writeln(_result);
    if (_conf['mail'] != null) {
      Mailer mailer = new Mailer.fromMap(_conf['mail']);
      mailer.sendHtml(_subject, _result).then((_) {
        completer.complete();
      }).catchError((error) {
        completer.complete(error);
      });
    } else {
      completer.complete();
    }
    return completer.future;
  }
}
