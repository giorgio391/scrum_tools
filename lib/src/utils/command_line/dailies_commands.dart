import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdout, stderr;

import 'package:logging/logging.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'package:resource/resource.dart';

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/mailer.dart';


class ListDailies extends UtilOptionCommand {

  String get abbr => "d";

  String get help =>
      r'Utility for listing daylies. An integer number must be provided.';

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
        print(r'No daily report found!.');
      } else {
        _ConsolidatedDailyReport cReport = new _ConsolidatedDailyReport(
            reports);
        /*if ('html' == conf['mode']) {
          _HtmlBuilder _htmlBuilder = new _HtmlBuilder();
          _htmlBuilder._consolidatedReportHtml(cReport).then((String html) {
            if (conf['out']) print(html);
          }).catchError((error) {
            _log.severe(error);
          });
        } else {
          _printReport(cReport);
        }*/
        if ('html' == conf['mode']) {
          _ContextMapBuilder builder = new _ContextMapBuilder();
          builder._createMap(cReport).then((Map<String, dynamic> context) {
            if (context != null) {
              String resourceKey = 'package:${cfgValue(
                  'templates')}/${conf['template']}';
              Resource cfgResource = new Resource(resourceKey);
              cfgResource.readAsString(encoding: UTF8).then((String template) {
                String html = render(template, context);
                if (conf['out']) print(html);
                if (conf['mail'] != null) {
                  Mailer mailer = new Mailer.fromMap(conf['mail']);
                  mailer.sendHtml('[PSNow] Daily report ${_formatDate(
                      cReport._startDate)} >> ${_formatDate(cReport._endDate)}',
                      html).then((_) {
                    print("Email sent. OK!");
                  }).catchError((error) {
                    _log.severe(error);
                  });
                }
              }).catchError((error) {
                _log.severe(error);
              });
            } else {
              stderr.writeln('No context for HTML.');
            }
          }).catchError((error) {
            _log.severe(error);
          });
        } else {
          _printReport(cReport);
        }
      }
    });
  }

  void _printReport(_ConsolidatedDailyReport report) {
    if (report != null) {
      print(r'=====================================');
      print('Daily report ${_formatDate(report._startDate)} >> ${_formatDate(
          report._endDate)}');
      print(r'=====================================');
      List<_entriesPrinter> entriesPrinter = [];
      Iterable<_StandardDailyEntry> devEntries = report._devEntriesByRank;
      if (hasValue(devEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'DEVELOPMENT', devEntries);
        });
      }
      Iterable<_StandardDailyEntry> inquiryEntries = report
          ._inquiriesEntriesByRank;
      if (hasValue(inquiryEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'INQUIRIES', inquiryEntries);
        });
      }
      entriesPrinter.add(() {
        return _printDeployments(report);
      });
      if (!hasValue(entriesPrinter)) {
        print(r"*** No entries. ***");
      } else {
        Future.forEach(entriesPrinter, (_entriesPrinter) {
          return _entriesPrinter();
        }).whenComplete(() {
          rallyService.close();
        });
      }
    } else {
      print(r"*** 'null' consolidate report. ***");
    }
  }

  void _printTitle(String title) {
    if (hasValue(title)) {
      String line = '+-${_formatString(
          r'----------------------------------------------', title.length)}-+';
      print(line);
      print('| ${title} |');
      print(line);
    }
  }

  _printDeployments(_ConsolidatedDailyReport report) {
    if (report != null && (hasValue(report._deploymentPlan) ||
        hasValue(report._deploymentReported))) {
      _printTitle(r'DEPLOYMENTS');
      if (hasValue(report._deploymentReported)) {
        stdout.write('[REPORTED: ');
        Environment.VALUES.forEach((Environment env) {
          if (report._deploymentReported[env] != null) {
            stdout.write(
                '- ${env.value} >> ${report._deploymentReported[env].value} ');
          }
        });
        stdout.write(']');
      }
      if (hasValue(report._deploymentPlan)) {
        stdout.write('[PLANNED: ');
        Environment.VALUES.forEach((Environment env) {
          if (report._deploymentPlan[env] != null) {
            stdout.write(
                '- ${env.value} >> ${report._deploymentPlan[env].value} ');
          }
        });
        stdout.write(']');
      }
      stdout.writeln();
      stdout.writeln();
    }
  }

  Future _printEntries(String title, Iterable<_StandardDailyEntry> entries) {
    Completer completer = new Completer();
    if (hasValue(entries)) {
      _printTitle(title);
      print(
          r'Description                                                                      Prev. Plan   Reported st. Plan status  C. hours');
      print(
          r'-------------------------------------------------------------------------------- ------------ ------------ ------------ --------');
      _findWorkItemNames(entries).then((Map<String, String> names) {
        entries.forEach((_StandardDailyEntry entry) {
          _printEntry(entry, names);
        });
        stdout.writeln();
        completer.complete();
      }).catchError((error) {
        _log.severe(error);
        stderr.writeln(error);
        completer.completeError(error);
      });
    } else {
      print(r"--- No entry. --");
      completer.complete();
    }
    return completer.future;
  }

  void _printEntry(_StandardDailyEntry entry,
      Map<String, String> workItemNames) {
    String description = () {
      if (entry._isWorkItem) {
        return "${_formatString(entry._key, 7)} - "
            "${workItemNames == null || workItemNames[entry._key] == null ?
        r'*** Work item not found.***' : workItemNames[entry._key]}";
      } else {
        return entry._key;
      }
    }();

    //String description = entry._key;
    String s = "${_formatString(description, 80)} :: "
        "${_formatStatus(entry._previousPlannedStatus)} >> "
        "${_formatStatus(entry._reportedStatus)} >> "
        "${_formatStatus(entry._plannedStatus)} :: "
        "${_formatDouble(entry._hours)}";
    print(s);
  }
}

Future<Map<String, String>> _findWorkItemNames(
    Iterable<_StandardDailyEntry> entries) {
  if (hasValue(entries)) {
    List<Future<RDWorkItem>> futures = [];
    entries.forEach((_StandardDailyEntry entry) {
      if (entry._isWorkItem) {
        Future<RDWorkItem> future = rallyService.getWorkItem(entry._key);
        futures.add(future);
        future.whenComplete(() {
          stdout.write("${entry._key}\r");
        });
      }
    });
    Completer<Map<String, String>> completer = new Completer();
    Future.wait(futures, eagerError: false).then((List<RDWorkItem> workItems) {
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

String _formatDate(DateTime date) {
  if (date != null) {
    String s = "${date.day < 10 ? r'0' : r''}${date.day}-"
        "${date.month < 10 ? r'0' : r''}${date.month}-${date.year}";
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
  return _formatString(r'n/a', 9);
}

String _formatDouble(double value) {
  String s = "           ${value == null ? r'n/a' : value.toString()}";
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
  Map<String, _StandardDailyEntry> _devEntriesMap = {};
  Map<String, _StandardDailyEntry> _inquiriesEntriesMap = {};
  Map<Environment, Status> _deploymentPlan = {};
  Map<Environment, Status> _deploymentReported = {};

  _ConsolidatedDailyReport(Iterable<DailyReport> reports) {
    _digestDailyReports(reports);
  }

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
            .._key = key
            .._rank = hasValue(entry.workItemCode) ? key : 'z$key'
            .._isWorkItem = hasValue(entry.workItemCode);
          targetMap[key] = myEntry;
        }
        if (entry.scope == Scope.PAST) {
          if (entry.hours != null) myEntry._hours = myEntry._hours == null ?
          entry.hours : myEntry._hours + entry.hours;
          if (myEntry._reportedStatus == null ||
              myEntry._reportedStatusDate.isBefore(date) ||
              (myEntry._reportedStatusDate == date &&
                  myEntry._reportedStatus < entry.status)) {
            myEntry._reportedStatus = entry.status;
            myEntry._reportedStatusDate = date;
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

  bool _isWorkItem;
  String _rank;
  String _key;
  Status _plannedStatus;
  Status _previousPlannedStatus;
  DateTime _previousPlannedStatusDate;
  Status _reportedStatus;
  DateTime _reportedStatusDate;
  double _hours;

}

class _HtmlBuilder {

  static const int _columns = 6;

  static Logger _log = SpreadDaily._log;

  HtmlEscape _htmlEscape = new HtmlEscape();
  StringBuffer _buffer = new StringBuffer();


  Future<String> _consolidatedReportHtml(_ConsolidatedDailyReport report) {
    Completer<String> completer = new Completer<String>();
    if (report != null) {
      _buffer.write(
          '<table style="font-family: Helvetica, Arial, Sans-Serif; '
              'border: 1px solid lightgrey; padding: 5px;">'
              '<thead><tr style="font-size: larger;">'
              '<th class="report-title" colspan="${_columns}">');
      _buffer.write(_htmlEscape.convert(
          'Daily report ${_formatDate(report._startDate)} >> ${_formatDate(
              report._endDate)}'));
      _buffer.writeln(r'</th></tr></thead><tbody>');
      List<_entriesPrinter> entriesPrinter = [];
      Iterable<_StandardDailyEntry> devEntries = report._devEntriesByRank;
      if (hasValue(devEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'DEVELOPMENT', devEntries);
        });
      }
      Iterable<_StandardDailyEntry> inquiryEntries = report
          ._inquiriesEntriesByRank;
      if (hasValue(inquiryEntries)) {
        entriesPrinter.add(() {
          return _printEntries(r'INQUIRIES', inquiryEntries);
        });
      }
      if (hasValue(report._deploymentPlan)) {
        entriesPrinter.add(() {
          return _printDeployments(report);
        });
      }
      if (!hasValue(entriesPrinter)) {
        _buffer.write('<tr><td class="no-entries" colspan="${_columns}">');
        _buffer.write(_htmlEscape.convert(r'*** No entries. ***'));
        _buffer.writeln(r'</td></tr></tbody></table>');
        completer.complete(_buffer.toString());
      } else {
        Future.forEach(entriesPrinter, (_entriesPrinter) {
          return _entriesPrinter();
        }).whenComplete(() {
          _buffer.writeln(r'</tbody></table>');
          rallyService.close();
          completer.complete(_buffer.toString());
        });
      }
    } else {
      completer.complete(null);
    }
    return completer.future;
  }

  Future _printEntries(String title, Iterable<_StandardDailyEntry> entries) {
    Completer completer = new Completer();
    if (hasValue(entries)) {
      _printTitle(title);
      _buffer.write(r'<tr style="color: white; font-weight: bold; '
      r'font-size: smaller;">');
      /*_buffer.write(r'<td class="key">');
      _buffer.write(_htmlEscape.convert(r'Key'));
      _buffer.write(r'</td>');*/
      _buffer.write(r'<td class="description-title" colspan="2" '
      r'style="background: darkgrey; padding: 4px;">');
      _buffer.write(_htmlEscape.convert(r'Description'));
      _buffer.write(r'</td>');
      _buffer.write(
          r'<td class="previous-plan-status-title" title="Previously '
          r'planned status." style="background: darkgrey; padding: 4px; '
          r'text-align: center;">');
      _buffer.write(_htmlEscape.convert(r'Prev. Plan'));
      _buffer.write(r'</td>');
      _buffer.write(
          r'<td class="reported-status-title" title="Reported status." '
          r'style="background: darkgrey; padding: 4px;  text-align: center;">');
      _buffer.write(_htmlEscape.convert(r'Reported st.'));
      _buffer.write(r'</td>');
      _buffer.write(
          r'<td class="next-status-title" title="Planned next status." '
          r'style="background: darkgrey; padding: 4px;  text-align: center;">');
      _buffer.write(_htmlEscape.convert(r'Plan status'));
      _buffer.write(r'</td>');
      _buffer.write(r'<td class="hours-title" title="Cumulated hours." '
      r'style="background: darkgrey; padding: 4px;  text-align: center;">');
      _buffer.write(_htmlEscape.convert(r'C. hours'));
      _buffer.writeln(r'</td></tr>');
      _findWorkItemNames(entries).then((Map<String, String> names) {
        bool back = true;
        entries.forEach((_StandardDailyEntry entry) {
          String style = back ? r'style="background: #ECECEC;"' : '';
          _buffer.write('<tr ${style}>');
          _printEntry(entry, names);
          _buffer.writeln(r'</tr>');
          back = !back;
        });
        stdout.writeln();
        completer.complete();
      }).catchError((error) {
        _log.severe(error);
        stderr.writeln(error);
        completer.completeError(error);
      });
    } else {
      _buffer.write('<tr><td class="no-entry" colspan="${_columns}">');
      _buffer.write(_htmlEscape.convert(r'No entry'));
      _buffer.write(r'</td></tr>');
      completer.complete();
    }
    return completer.future;
  }

  void _printEntry(_StandardDailyEntry entry,
      Map<String, String> workItemNames) {
    if (entry._isWorkItem) {
      _buffer.write(r'<td class="wi-code" title="Work item code." '
      r'style="font-weight: bold; padding: 4px;" valign="top">');
      _buffer.write(
          '<a href="https://rally1.rallydev.com/#/55308115013d/search?keywords='
              '${entry._key}" target="_blank" style="text-decoration: none;">');
      _buffer.write(_htmlEscape.convert(entry._key));
      _buffer.write(r'</a></td>');
      _buffer.write(r'<td class="wi-title" title="Work item title." '
      r'valign="top" style="padding: 4px;">');
      if (hasValue(workItemNames[entry._key])) {
        _buffer.write(_htmlEscape.convert(workItemNames[entry._key]));
      }
      _buffer.write(r'</td>');
    } else {
      _buffer.write(r'<td class="statement" title="Statement." colspan="2" '
      r'valign="top" style="padding: 4px;">');
      _buffer.write(_htmlEscape.convert(entry._key));
      _buffer.write(r'</td>');
    }

    _buffer.write(
        r'<td class="previous-plan-status" title="Previously planned status." '
        r'style="text-align: center; padding: 4px;" valign="top">');
    _buffer.write(
        entry._previousPlannedStatus == null ? r'-' :
        _htmlEscape.convert(entry._previousPlannedStatus.toString()));
    _buffer.write(r'</td>');
    _buffer.write(
        r'<td class="reported-status" title="Reported status." '
        r'style="text-align: center; padding: 4px;" valign="top">');
    _buffer.write(entry._reportedStatus == null ? r'-' :
    _htmlEscape.convert(entry._reportedStatus.toString()));
    _buffer.write(r'</td>');
    _buffer.write(
        r'<td class="next-status" title="Planned next status." '
        r'style="text-align: center; padding: 4px;" valign="top">');
    _buffer.write(entry._plannedStatus == null ? r'-' :
    _htmlEscape.convert(entry._plannedStatus.toString()));
    _buffer.write(r'</td>');
    _buffer.write(r'<td class="hours" title="Cumulated hours." '
    r'style="text-align: right; padding: 4px;" valign="top">');
    _buffer.write(_htmlEscape.convert(_formatDouble(entry._hours)));
    _buffer.write(r'</td>');
  }

  void _printTitle(String title, {int col: _columns}) {
    if (hasValue(title)) {
      _buffer.write(
          '<tr><td class="title" style="text-align: center; '
              'border-top: 1px solid lightgrey; '
              'border-bottom: 1px solid lightgrey; '
              'font-size: smaller; font-weight: bold;" colspan="${col}">');
      _buffer.write(_htmlEscape.convert(title));
      _buffer.writeln(r'</td></tr>');
    }
  }

  void _printDeployments(_ConsolidatedDailyReport report) {
    if (report != null && (hasValue(report._deploymentPlan) ||
        hasValue(report._deploymentReported))) {
      _printTitle(r'DEPLOYMENTS');
      int col1 = (_columns / 2).floor();
      int col2 = _columns - col1;
      _buffer.write(r'<tr>');
      _buffer.write('<td colspane="${col1}"><table><body>');
      _printTitle(r'REPORTED', col: 1);
      if (hasValue(report._deploymentReported)) {
        _buffer.write('<tr><td class="deployments" colspan="${_columns}" '
            'style="text-align: center; font-size: smaller;"'
            '><span style="color: darkgrey;">|</span>');
        Environment.VALUES.forEach((Environment env) {
          if (report._deploymentReported[env] != null) {
            _buffer.write(
                '&nbsp;${env.toString()}&nbsp;${_htmlEscape.convert(
                    '>>')}&nbsp;${report._deploymentReported[env]
                    .toString()}&nbsp;<span style="color: darkgrey;">|</span>');
          }
        });
        _buffer.writeln(r'</td></tr>');
      }
      _buffer.write('</body></table></td>');
      _buffer.write('<td colspane="${col2}"><table><body>');
      _printTitle(r'PLANNED', col: 1);
      if (hasValue(report._deploymentPlan)) {
        _buffer.write('<tr><td class="deployments" colspan="${_columns}" '
            'style="text-align: center; font-size: smaller;"'
            '><span style="color: darkgrey;">|</span>');
        Environment.VALUES.forEach((Environment env) {
          if (report._deploymentPlan[env] != null) {
            _buffer.write(
                '&nbsp;${env.toString()}&nbsp;${_htmlEscape.convert(
                    '>>')}&nbsp;${report._deploymentPlan[env]
                    .toString()}&nbsp;<span style="color: darkgrey;">|</span>');
          }
        });
        _buffer.writeln(r'</td></tr>');
      }
      _buffer.write('</body></table></td>');
    }
  }
}

class _ContextMapBuilder {

  static Logger _log = SpreadDaily._log;

  Future<Map<String, dynamic>> _createMap(_ConsolidatedDailyReport report) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    if (report != null) {
      Map<String, dynamic> map = {
        'startDate': _formatDate(report._startDate),
        'endDate': _formatDate(report._endDate)
      };
      List generatorModel = [];


      Iterable<_StandardDailyEntry> devEntries = report._devEntriesByRank;
      if (hasValue(devEntries)) {
        map['development?'] = true;
        generatorModel.add(() {
          return _entries(devEntries)
              .then((List list) {
            map['developmentEntries'] = list;
          });
        });
      }

      Iterable<_StandardDailyEntry> inquiryEntries = report
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
        map['deployments'] = _deployments(report);
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
    _findWorkItemNames(entries).then((Map<String, String> names) {
      List list = [];
      bool back = true;
      entries.forEach((_StandardDailyEntry entry) {
        Map map = _entryToMap(entry, names);
        back = !back;
        map ['backColor'] = back ? '#ECECEC' : 'white';
        list.add(map);
      });
      stdout.writeln();
      completer.complete(list);
    }).catchError((error) {
      _log.severe(error);
      stderr.writeln(error);
      completer.completeError(error);
    });

    return completer.future;
  }

  Map<String, dynamic> _entryToMap(_StandardDailyEntry entry,
      Map<String, String> names) {
    Map<String, dynamic> map = {};
    if (entry._isWorkItem) {
      map['workItem?'] = true;
      map['workItemCode'] = entry._key;
      map['workItemTitle'] = names[entry._key];
    } else {
      map['statement'] = entry._key;
    }
    map['previousPlannedStatus'] = entry._previousPlannedStatus == null ? r'-' :
    entry._previousPlannedStatus.toString();
    map['reportedStatus'] = entry._reportedStatus == null ? r'-' :
    entry._reportedStatus.toString();
    map['plannedStatus'] = entry._plannedStatus == null ? r'-' :
    entry._plannedStatus.toString();
    map['hours'] = _formatDouble(entry._hours);
    return map;
  }


  Map _deployments(_ConsolidatedDailyReport report) {
    Map map = {};
    if (hasValue(report._deploymentReported)) {
      List list = [];
      Environment.VALUES.forEach((Environment env) {
        if (report._deploymentReported[env] != null) {
          list.add({
            'environment': env.toString(),
            'status': report._deploymentReported[env].toString()
          });
        }
      });
      map['reported?'] = true;
      map['reported'] = list;
    }
    if (hasValue(report._deploymentPlan)) {
      List list = [];
      Environment.VALUES.forEach((Environment env) {
        if (report._deploymentPlan[env] != null) {
          list.add({
            'environment': env.toString(),
            'status': report._deploymentPlan[env].toString()
          });
        }
      });
      map['planned?'] = true;
      map['planned'] = list;
    }
    return map;
  }
}
