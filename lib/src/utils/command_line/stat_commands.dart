import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:prompt/prompt.dart';

import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';

Printer _p = new Printer();

class StatisticsCommands extends UtilOptionCommand {

  @override
  String get abbr => r"t";

  @override
  String get help => r'Utility for statistcis.';

  const StatisticsCommands();

  @override
  void executeOption(String options) {
    if (options.startsWith(r'e-')) {
      processEffort(options.substring(r'e-'.length)).then((_) =>
          rallyService.close());
    }
  }

  Future processEffort(String options) {
    Completer completer = new Completer();
    Map<String, dynamic> optionsMap = hasValue(options)
        ? JSON.decode(options)
        : {};
    DateTime date = !hasValue(optionsMap[r'date']) ||
        optionsMap[r'date'] == r'now' || optionsMap[r'date'] == r'today'
        ? new DateTime.now()
        : DateTime.parse(optionsMap[r'date']);
    int days = optionsMap[r'days'] ?? 31;

    List<List> list4CSV = hasValue(optionsMap[r'csv']) ? [] : null;

    dailyDAO.getLastDailyReports(dateReference: date, number: days).then((
        List<DailyReport> reports) {
      if (!hasValue(reports)) {
        _p.red('No daily report found [${date}][${days}]');
        completer.complete();
        return;
      }
      _p.pln();
      Map<String, double> sums = {};
      DateTime firstDate = null;
      DateTime lastDate = null;
      reports.forEach((DailyReport report) {
        DateTime date = report.date;
        firstDate =
        firstDate == null || firstDate.isAfter(date) ? date : firstDate;
        lastDate =
        lastDate == null || lastDate.isBefore(date) ? date : lastDate;
        Iterable<DailyEntry> entries = report.entries;
        if (hasValue(entries)) {
          entries.where((DailyEntry entry) =>
          entry.scope == Scope.PAST && hasValue(entry.workItemCode) &&
              entry.hours != null &&
              entry.hours != 0.0).forEach((DailyEntry entry) {
            _p.p('Calculating: ${date.toIso8601String()} - ${entry
                .workItemCode}                       \r');
            sums[entry.workItemCode] =
            sums[entry.workItemCode] == null ? entry.hours : sums[entry
                .workItemCode] + entry.hours;
          });
        }
      });
      _p.p(r'First date: ').bold(formatDateYMD(firstDate))
          .p(r' Last date: ')
          .bold(formatDateYMD(lastDate));
      if (!hasValue(sums)) {
        _p.red('No sum!');
        completer.complete();
        return;
      }

      _p.p(r'                                                     ').pln();

      List<String> wiCodes = new List<String>.from(sums.keys)
        ..sort();

      Map<String, RDWorkItem> wiMap = {};

      rallyService.getWorkItems(wiCodes).listen((RDWorkItem workItem) {
        _p.p('Retrieving: [${workItem.formattedID}]                   \r');
        if (workItem.scheduleState > RDScheduleState.ACCEPTED &&
            !workItem.creationDate.isBefore(firstDate))
          wiMap[workItem.formattedID] = workItem;
      }).onDone(() {
        if (hasValue(wiMap)) {
          wiCodes = new List<String>.from(wiMap.keys)
            ..sort();
          _p.cyan('${formatString(r'WI Code', 7)} | ${formatString(
              r' Spent', 7)} | ${formatString(
              r'Points', 7)} | ${formatString(r' Hours', 7)} | ${formatString(
              r'Actual', 7)}'
              ' | ${formatString(r' Creation', 10)} | ${formatString(
              r' Update', 10)} | ${formatString(
              r'Sprint', 9)} | WI Name').pln();

          if (list4CSV != null) list4CSV.add(
              [
                r'WI Code',
                r'Spent',
                r'Points',
                r'Hours',
                r'Actual',
                r'Creation',
                r'Update',
                r'Sprint',
                r'WI Name'
              ]);


          wiCodes.forEach((String wiCode) {
            RDWorkItem workItem = wiMap[wiCode];

            _p.cyan(formatString(wiCode, 7)).write(r' | ')
                .bold(formatDouble(sums[wiCode], 7));

            if (workItem != null) {
              if (workItem.planEstimate != null) {
                _p.p(r' | ').green().bold(
                    formatDouble(workItem.planEstimate, 7));
              } else {
                _p.p(r' | ').green().bold(
                    formatString(r'           ', 7));
              }
              if (workItem.taskEstimateTotal != null) {
                _p.p(r' | ').yellow().bold(
                    formatDouble(workItem.taskEstimateTotal, 7));
              } else {
                _p.p(r' | ').green().bold(
                    formatString(r'           ', 7));
              }

              if (workItem.taskActualTotal != null) {
                _p.p(r' | ').yellow().bold(
                    formatDouble(workItem.taskActualTotal, 7));
              }
              else {
                _p.p(r' | ').green().bold(formatString(r'        ', 7));
              }

              _p.p(r' | ').p(formatDateYMD(workItem.creationDate));
              _p.p(r' | ').p(formatDateYMD(workItem.lastUpdateDate));

              if (workItem.iteration != null) {
                _p.p(r' | ').p(formatString(workItem.iteration.name, 9));
              }

              _p.p(r' | ').p(workItem.name);
            }
            _p.pln();

            if (list4CSV != null) {
              list4CSV.add([
                workItem.formattedID,
                sums[wiCode],
                workItem.planEstimate ?? r'',
                workItem.taskEstimateTotal ?? r'',
                workItem.taskActualTotal ?? r'',
                formatDateYMD(workItem.creationDate),
                formatDateYMD(workItem.lastUpdateDate),
                workItem.iteration == null ? r'' : workItem.iteration.name,
                workItem.name
              ]);
            }
          });
        } else {
          _p.red('All work items filtered out!');
        }
        if (hasValue(list4CSV)) {
          File csvFile = new File (optionsMap[r'csv']);
          if (csvFile.existsSync() && !askSync(
              new Question.confirm(red('Overwrite [${csvFile.path}]?')))) {
            completer.complete();
            return;
          }
          ListToCsvConverter csvConverter = const ListToCsvConverter(
              textDelimiter: r'"', eol: '\n');
          csvFile.writeAsStringSync(
              csvConverter.convert(list4CSV));
          _p.p(r'CSV generated in [').bold(csvFile.path).p(r'].').pln();
        }
        completer.complete();
      });
    });
    return completer.future;
  }
}