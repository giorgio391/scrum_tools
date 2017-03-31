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
        switch (conf['mode']) {
          case 'html':
            _ConsolidatedDailyReportsDigester digester =
            new _ConsolidatedDailyReportsDigester(reports);
            _HtmlWorker htmlW = new _HtmlWorker(digester, conf['template']);
            htmlW._process().then((String html) {
              _ResultWorker resultW = new _ResultWorker(conf,
                  '[PSNow] Daily report ${_formatDate(
                      digester._startDate)} >> ${_formatDate(
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
      print(r'====================================================');
      print('Daily report ${_formatDate(digester._startDate)} >> ${_formatDate(
          digester._endDate)} - Hours: ${_formatDouble(digester._hours)}');
      print(r'====================================================');
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

  _printDeployments(_ConsolidatedDailyReportsDigester digester) {
    if (digester != null) {
      _printTitle(r'DEPLOYMENTS');
      if ((hasValue(digester._deploymentPlan) ||
          hasValue(digester._deploymentReported))) {
        if (hasValue(digester._deploymentReported)) {
          stdout.write('[REPORTED: ');
          Environment.VALUES.forEach((Environment env) {
            if (digester._deploymentReported[env] != null) {
              stdout.write(
                  '- ${env.value} >> ${digester._deploymentReported[env]
                      .value} ');
            }
          });
          stdout.write(']');
        }
        if (hasValue(digester._deploymentPlan)) {
          stdout.write('[PLANNED: ');
          Environment.VALUES.forEach((Environment env) {
            if (digester._deploymentPlan[env] != null) {
              stdout.write(
                  '- ${env.value} >> ${digester._deploymentPlan[env].value} ');
            }
          });
          stdout.write(']');
        }
        stdout.writeln();
        stdout.writeln();
      } else {
        stdout.writeln('-- NONE --');
      }
    }
  }

  Future _printEntries(String title, Iterable<_StandardDailyEntry> entries) {
    Completer completer = new Completer();
    if (hasValue(entries)) {
      _printTitle(title);
      print(
          r'Description                                                                      Prev. Plan   Reported st. Plan status   Hours');
      print(
          r'-------------------------------------------------------------------------------- ------------ ------------ ------------ --------');

      _findWorkItems(_extractWorkItemCodes(entries)).then((
          Map<String, RDWorkItem> workItems) {
        entries.forEach((_StandardDailyEntry entry) {
          _printEntry(entry, workItems);
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
      Map<String, RDWorkItem> workItems) {
    String description = () {
      if (entry._hasWorkItem) {
        return "${_formatString(entry._workItemCode, 7)} - "
            "${workItems == null || workItems[entry._workItemCode] == null ?
        '*** Work item not found [${entry._workItemCode}].***' : workItems[entry
            ._workItemCode]
            .name}";
      } else {
        return entry._statement;
      }
    }();

    String s = "${_formatString(description, 80)} :: "
        "${_formatStatus(entry._previousPlannedStatus)} "
        "${_reportedSymbol(entry)}> "
        "${_formatStatus(entry._reportedStatus)} "
        "${_plannedSymbol(entry)} "
        "${_formatStatus(entry._plannedStatus)} :: "
        "${_formatDouble(entry._hours)}";
    print(s);
  }
}

String _reportedSymbol(_StandardDailyEntry entry) =>
    entry._previousPlannedStatus == null && entry._reportedStatus != null
        ? r'*' :
    entry._previousPlannedStatus != null && entry._reportedStatus != null &&
        entry._reportedStatus > entry._previousPlannedStatus ? r'+' :
    entry._previousPlannedStatus != null && entry._reportedStatus != null &&
        entry._reportedStatus < entry._previousPlannedStatus ? r'-' :
    entry._previousPlannedStatus != null && entry._reportedStatus == null ?
    r'-' :
    entry._previousPlannedStatus == null && entry._reportedStatus == null
        ? r':' : r'>';

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
  return _formatString(r'···', 9);
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
        'startDate': _formatDate(digester._startDate),
        'endDate': _formatDate(digester._endDate)
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
    map['hours'] = _formatDouble(entry._hours);
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
        stderr.writeln('No context for HTML.');
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
    if (_conf['out']) print(_result);
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
