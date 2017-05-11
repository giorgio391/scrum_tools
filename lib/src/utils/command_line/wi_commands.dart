import 'dart:async';
import 'dart:io';
import 'package:prompt/prompt.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/server/rally_proxy.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/mailer.dart';
import 'package:scrum_tools/src/utils/repository/repository.dart';
import 'package:scrum_tools/src/utils/repository/impl/file_repository.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/rally/basic_rally_service.dart';
import 'package:scrum_tools/src/rally/wi_validator.dart';

Printer _p = new Printer();

List <String> _wimeta1 = [
  r'psnow/master',
  r'psnow/live',
  r'prepro-master/docs',
  r'prepro-master/products',
  r'prepro-live/docs',
  r'prepro-live/products'
];

List<String> _wimeta2 = [
  r'db/gordon',
  r'db/pmaster',
  r'solr/pmaster',
  r'solr/cdplus',
  r'solr/darassets',
  r'sh/pmaster',
  r'sh/cdplus',
  r'sh/darassets'
];

List<String> _wimeta3 = [
  r'notes'
];

List<String> _wimeta = new List<String>.from(_wimeta1)
  ..addAll(_wimeta2)..addAll(_wimeta3);

typedef Future _ExtraRow(RDWorkItem workItem);

typedef Future _ExtraAction(Iterable<RDWorkItem> workItems);

class WorkItemsCommands extends UtilOptionCommand {

  @override
  String get abbr => r"w";

  @override
  String get help => r'Utility for managing work items.';

  const WorkItemsCommands();

  @override
  void executeOption(String option) {
    List<String> options = option.split(r'+');
    String action = options[0];
    bool chk = options.length > 1 && options[1] == r'chk';

    if (r'dep-pro' == action) {
      rallyService.getPRODeploymentPending().then((Iterable<RDWorkItem> ite) {
        RepositorySync repo = _getWiMetaRepo();
        _printIterableAndClose(ite, chk, wiMetaRepo: _getWiMetaRepo(),
            extraAction: new DeployExtraAction(
                r'PRO deployment', RDTag.PRO, r'psnow/live', repo)
                .doAction);
      });
    } else if (r'dep-pre' == action) {
      rallyService.getPREDeploymentPending().then((Iterable<RDWorkItem> ite) {
        RepositorySync repo = _getWiMetaRepo();
        _printIterableAndClose(ite, chk, wiMetaRepo: _getWiMetaRepo(),
            extraAction: new DeployExtraAction(
                r'PRE deployment', RDTag.PRE, r'psnow/live', repo)
                .doAction);
      });
    } else if (r'dep-uat' == action) {
      rallyService.getUATDeploymentPending().then((Iterable<RDWorkItem> ite) {
        RepositorySync repo = _getWiMetaRepo();
        _printIterableAndClose(ite, chk, wiMetaRepo: _getWiMetaRepo(),
            extraAction: new DeployExtraAction(
                r'UAT deployment', RDTag.UAT, r'psnow/master', repo)
                .doAction);
      });
    } else if (r'dep-uat->pre' == action) {
      rallyService.getUAT2PREDeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        RepositorySync repo = _getWiMetaRepo();
        _printIterableAndClose(ite, chk, wiMetaRepo: repo,
            extraAction: new DeployExtraAction(
                r'UAT->PRE deployment', RDTag.PRE, r'psnow/master', repo)
                .doAction);
      });
    } else if (r'dep-uat->pro' == action) {
      rallyService.getUAT2PRODeploymentPending().then((
          Iterable<RDWorkItem> ite) {
        RepositorySync repo = _getWiMetaRepo();
        _printIterableAndClose(ite, chk, wiMetaRepo: repo,
            extraAction: new DeployExtraAction(
                r'UAT->PRO deployment', RDTag.PRO, r'psnow/live', repo)
                .doAction);
      });
    } else if (r'dev-pending' == action) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          _printIterableAndClose(ite, chk,
              extraAction: new _MailExtraAction('Pending').mail);
        });
      });
    } else if (action.startsWith(r'dev-pending-')) {
      String iterationName = _resolveIterationName(action);
      _checkMissedIteration(() {
        rallyService.getDevTeamPendingInIteration(iterationName).then((
            Iterable<RDWorkItem> ite) {
          _printIterableAndClose(ite, chk,
              extraAction: new _MailExtraAction('Pending ${iterationName}')
                  .mail);
        });
      });
    } else if (action.startsWith(r'rtd')) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          RepositorySync wiMetaRepo = _getWiMetaRepo();
          rallyService.getPREDeploymentPending().then((
              Iterable<RDWorkItem> ite) {
            _p.backWhite().bold()
                .red(r'>>>>>>>>>>> PRE >>>>>>>>>>>>>>')
                .writeln();
            _printIterableAndClose(ite, chk, wiMetaRepo: wiMetaRepo).then((_) {
              rallyService.getUATDeploymentPending().then((
                  Iterable<RDWorkItem> ite) {
                _p.backWhite().bold()
                    .blue(r'>>>>>>>>>>> UAT >>>>>>>>>>>>>>')
                    .writeln();
                _printIterableAndClose(ite, chk, wiMetaRepo: wiMetaRepo);
              });
            });
          });
        });
      });
    } else if (action.startsWith(r'rtp')) {
      _checkMissedIteration(() {
        rallyService.getDevTeamPending().then((Iterable<RDWorkItem> ite) {
          RepositorySync wiMetaRepo = _getWiMetaRepo();
          _p.backWhite().bold()
              .red(r'>>>>>>> LIVE & MASTER >>>>>>>>>')
              .writeln();
          _printIterableAndClose(
              ite.where((RDWorkItem workItem) =>
              workItem.ready && workItem.expedite), chk,
              wiMetaRepo: wiMetaRepo).then((_) {
            _p.backWhite().bold()
                .blue(r'>>>>>>>>>> MASTER >>>>>>>>>>>>>')
                .writeln();
            _printIterableAndClose(
                ite.where((RDWorkItem workItem) =>
                workItem.ready && !workItem.expedite), chk,
                wiMetaRepo: wiMetaRepo);
          });
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
    } else if (action == r'meta') {
      _meta();
    } else if (action.startsWith(r'meta-')) {
      Set<String> list = _resolveList(action);
      _meta(list);
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

  Future _printIterableAndClose(Iterable<RDWorkItem> ite, bool chk,
      {_ColumnPrinter extraCol, RepositorySync wiMetaRepo, _ExtraRow extraRow, _ExtraAction extraAction}) async {
    if (hasValue(ite)) {
      for (RDWorkItem workItem in ite) {
        await _printWorkItem
          (workItem, chk, extraCol: extraCol, wiMetaRepo: wiMetaRepo);
        if (extraRow != null) {
          await extraRow(workItem);
        }
      }
      _p.writeln();
      _p.write(r'  ').dim(r'| ')
          .write(r"* Below 'In progress'").dim(r' | ')
          .write(r"** Below 'Completed'").dim(r' | ')
          .bold(r'*').write(r'/').bold(r'**').write(r" No owner").dim(r' | ')
          .inverted(r'+').write(r" Expedite").dim(r' | ')
          .red().inverted(r'B').write(r' Blocked').dim(r' | ')
          .green().inverted(r'R').write(r' RTP').dim(r' | ')
          .blink().bold().red('Top priority').dim(r' | ')
          .bold().yellow().inverted(r'I').write(r'nquiry/')
          .bold().yellow().inverted(r'O').write(r'peration')
          .writeln(r' |');
      if (extraAction != null) {
        await extraAction(ite);
      }
    } else {
      _p.writeln(r'No work item available!');
    }
    rallyService.close();
  }

  Future _printWorkItem(RDWorkItem workItem, bool chk,
      {_ColumnPrinter extraCol, RepositorySync wiMetaRepo}) async {
    if (extraCol != null) {
      extraCol(_p, workItem);
    }
    bool assignedToClient = WorkItemValidator.assignedToClient(workItem);
    RDPriority p = inferWIPriority(workItem);
    RDSeverity s = inferSeverity(workItem);
    if ((assignedToClient && !workItem.blocked) || workItem.owner == null) _p
        .blink()
        .bold();
    _p.write(
        workItem.scheduleState < RDScheduleState.IN_PROGRESS ? r'*' : r' ');
    _p.write(workItem.scheduleState < RDScheduleState.COMPLETED ? r'*' : r' ');
    _p.reset();
    if (workItem is RDHierarchicalRequirement &&
        workItem.predecessorsCount > 0) {
      _p.bold();
    }
    _p.write(formatString(workItem.formattedID, 8));
    _p.reset();
    _p.write(formatString(workItem.name, 70));
    _p.grey(r' > ');
    if (workItem.owner != null) {
      if (assignedToClient) {
        _p.yellow();
      } else if (WorkItemValidator.assignedQADeployer(workItem)) {
        _p.cyan();
      } else {
        _p.blue();
      }
      _p.write(formatString(workItem.owner.displayName, 18));
      _p.reset();
    } else {
      _p.write(formatString(r' ', 18));
    }
    if (workItem.expedite) {
      _p.inverted(r'+');
    } else {
      _p.write(r' ');
    }
    if (workItem.blocked) {
      _p.bold().red().inverted(r'B');
    } else {
      _p.write(r' ');
    }
    if (workItem.ready) {
      _p.green().bold().inverted(r'R');
    } else {
      _p.write(r' ');
    }
    _p.bold().inverted();
    if (workItem.scheduleState == RDScheduleState.UNDEFINED) {
      _p.grey();
    } else if (workItem.scheduleState == RDScheduleState.COMPLETED) {
      _p.green();
    } else if (workItem.scheduleState == RDScheduleState.ACCEPTED) {
      //_p.grey();
    } else if (workItem.scheduleState == RDScheduleState.ACCEPTED_BY_OWNER) {
      _p.cyan();
    } else {
      _p.blue();
    }
    _p.write(workItem.scheduleState.abbr);
    _p.reset();
    _p.write(r' ');
    _p.write(formatString(
        workItem.iteration == null ? r' ' : 'S${workItem.iteration.name
            .substring(
            workItem.iteration.name.length - 3).trim()}', 5));
    if (hasMaxPrioritization(workItem)) _p.blink().bold().red();
    _p.write(formatString(p == null ? r' ' : p.name.split(r' ')[0], 8));
    _p.reset();
    _p.write(formatString(s == null ? r' ' : s.name.split(r' ')[0], 8));
    _p.grey(r' > ');
    //_p.writeln(formatDate(wi.lastUpdateDate));
    if (workItem.planEstimate != null && workItem.planEstimate > 5.0)
      _p.bold();
    else if (workItem.planEstimate != null && workItem.planEstimate < 2.0)
      _p.cyan();
    else if (workItem.planEstimate == null && !workItem.blocked &&
        !workItem.inquiry) _p.bold().red();
    _p.write(formatDouble(workItem.planEstimate));
    _p.reset();
    _p.write(r' ');
    if (workItem.inquiry) {
      _p.bold().yellow().inverted(r'I');
    }
    if (workItem.operation) {
      _p.bold().yellow().inverted(r'O');
    }

    if (hasValue(workItem.tags)) {
      _p.writeln();
      _p.write(r'     ');
      new List.from(workItem.tags)
        ..sort()
        ..forEach((String tag) {
          _p.write(r'·');
          _p.blue().inverted(tag);
        });
    }
    if (hasValue(workItem.milestones)) {
      if (hasValue(workItem.tags)) {
        _p.write(r' >< ');
      } else {
        _p.writeln();
        _p.write(r'     ');
      }
      workItem.milestones.forEach((RDMilestone milestone) {
        _p.write(r'·');
        _p.cyan().inverted(
            '${milestone.name} ${formatDateYMD(milestone.targetDate)}');
      });
    }
    _p.writeln();

    if (chk) {
      await _printValidation(workItem);
    }

    if (wiMetaRepo != null) {
      _printWimeta(wiMetaRepo, workItem.formattedID);
    }
  }

  Future _printValidation(RDWorkItem workItem) async {
    Report report = await workItemValidator.validate(workItem);
    if (report.hasIssues) {
      report.issues.where((Issue issue) =>
      issue.issueLevel == IssueLevel.IMPORTANT).forEach((Issue issue) {
        _p.red('     >> ${formatString(issue.name, 70)}');
        _p.writeln();
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.WARN)
          .forEach((Issue issue) {
        _p.yellow('     >> ${formatString(issue.name, 70)}');
        _p.writeln();
      });
      report.issues.where((Issue issue) => issue.issueLevel == IssueLevel.INFO)
          .forEach((Issue issue) {
        _p.cyan('           > ${formatString(issue.name, 70)}');
        _p.writeln();
      });
    }
  }

  void _meta([Iterable<String> wiCodes]) {
    if (hasValue(wiCodes)) {
      wiCodes.forEach((String wiCode) {
        String code = normalizeWorkItemCodeFormat(wiCode);
        if (validWorkItemCodePattern(code)) {
          _singleMeta(code);
        } else {
          _p.red('Work item code not valid [${wiCode} -> ${code}]!').writeln();
        }
      });
    } else {
      _singleMeta();
    }
  }

  void _singleMeta([String wiCode]) {
    _p.writeln();
    if (!hasValue(wiCode) || !hasValue(wiCode.trim())) {
      String code = askSync(
          new Question(r'  Work item code:', defaultsTo: r''));
      if (!hasValue(code) || !hasValue(code.trim())) return;
      code = normalizeWorkItemCodeFormat(code);
      if (validWorkItemCodePattern(code)) {
        _singleMeta(code);
      } else {
        _p.red(r'Work item code not valid!').writeln();
        _singleMeta();
      }
    } else {
      _p.up('                                                           \r');
      rallyService.getWorkItem(wiCode).then((RDWorkItem wi) {
        if (wi != null) {
          _printWorkItem(wi, true).then((_) {
            RepositorySync repo = _getWiMetaRepo();
            PersistedData pData = repo.get(wiCode);
            bool alreadyPersisted = pData != null;
            Map<String, String> map = pData?.data;

            map ??= new Map<String, String>();

            Function options = alreadyPersisted ?
                () =>
                askSync(new Question(
                    '  ${bold(r's')}ave/${bold(r'e')}dit/${bold(r'c')}ancel/${bold(
                        r'd')}elete')) :
                () =>
                askSync(new Question(
                    '  ${bold(r's')}ave/${bold(r'e')}dit/${bold(r'c')}ancel'));

            String action = alreadyPersisted ? () {
              _p.blue()
                  .dim('   - ${pData.author} - ${formatTimestamp(pData.timestamp)}')
                  .writeln();
              _printMap(map, _wimeta1);
              _printMap(map, _wimeta2);
              _printMap(map, _wimeta3);
              return askSync(new Question(
                  '  ${bold(r'e')}dit/${bold(r'c')}ancel/${bold(
                      r'd')}elete'));
            }() : r'e';

            if (action == r's') {
              _p.writeln('No need to save because no change was done!');
            } else {
              while (action == r'e') {
                _edit(map, _wimeta);
                _printMap(map, _wimeta1);
                _printMap(map, _wimeta2);
                _printMap(map, _wimeta3);
                if (!alreadyPersisted && !hasValue(map)) {
                  action = r'c';
                  break;
                }
                action = options();
                while (![r's', r'e', r'c', r'd'].contains(action)) {
                  action = options();
                }
              }

              if (action == r'd' || (!hasValue(map) && alreadyPersisted)) {
                if (!alreadyPersisted) {
                  _p.writeln('No need to delete because it was not persisted!');
                } else {
                  bool confirm = askSync(new Question.confirm(red(r'Delete?')));
                  if (confirm) {
                    repo.delete(wiCode);
                    _p.red(r'Meta for [').bold(wiCode).red(r'] deleted!').writeln();
                  }
                }
              } else if (action == r's') {
                repo.save(wiCode, map);
                _p.yellow(r'Meta for [').bold(wiCode).yellow(r'] saved!').writeln();
              }
            }
            rallyService.close(force: true);
          });
        } else {
          _p.red(r'Work item code not found!').writeln();
          _singleMeta();
        }
      });
    }
  }

  void _edit(Map<String, String> map, List<String> prompts) {
    prompts.forEach((String prompt) {
      String currentValue = map[prompt];
      currentValue ??= r'';
      String value = askSync(
          new Question('  ${prompt}:', defaultsTo: currentValue));
      _p.up('                                                              \r');
      if (value != null && value.length > 0 && value
          .trim()
          .length == 0) {
        map.remove(prompt);
      }
      if (hasValue(value) && hasValue(value.trim())) {
        map[prompt] = value;
        _p.write('  ${prompt} [').bold(value).writeln(r'].             ');
      }
    });
  }

  void _printWimeta(RepositorySync repo, String wiCode) {
    PersistedData pData = repo.get(wiCode);
    if (pData != null) {
      _p.blue().dim(
          '     - ${pData.author} - ${formatTimestamp(pData.timestamp)}')
          .writeln();
      _printMap(pData.data, _wimeta1);
      _printMap(pData.data, _wimeta2);
      _printMap(pData.data, _wimeta3);
    }
  }

  void _printMap(Map<String, String> map, [List<String> keys]) {
    StringBuffer sb = new StringBuffer();
    Printer p = new Printer(sink: sb);
    (hasValue(keys) ? keys : map.keys).forEach((String key) {
      String value = map[key];
      if (hasValue(value)) {
        p.write(r' · ').blue(key).write(r' [').bold(value).write(r']');
      }
    });
    if (sb.length > 0) {
      _p.blue().dim(r'       >').write(sb.toString()).writeln();
    }
  }
}

RepositorySync _getWiMetaRepo() {
  String name = cfgValue(r'wi_commands')[r'meta-repo'][r'name'];
  String dir = cfgValue(r'wi_commands')[r'meta-repo'][r'dir'];
  FileRepository repo = new FileRepository(name, dir);
  return repo;
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

class DeployExtraAction {

  _MailExtraAction _mail;
  _SummaryPrinter _summary;

  DeployExtraAction(String subject, RDTag tag, String appVersionKey,
      RepositorySync repo) {
    _mail = new _MailExtraAction(subject, false);
    _summary = new _SummaryPrinter(tag, repo, appVersionKey);
  }

  Future doAction(Iterable<RDWorkItem> workItems) {
    _summary._print(workItems);
    String action = askSync(new Question(
        ' ${bold(r'')}get list by ${bold(r'e')}mail/${bold(
            r't')}ag deployment/${bold(r'c')}ancel'));
    switch (action) {
      case r'e':
        _mail.mail(workItems);
        break;
      case r't':
        return doTagAction(workItems);
      case r'c':
        break;
    }
    return new Future.value(null);
  }

  Future doTagAction(Iterable<RDWorkItem> workItems) {
    Completer completer = new Completer();
    _createRDService().then((BasicRallyService rs) {
      rs.createMilestone(_summary._milestoneName, artifacts: workItems).then((
          RDMilestone milestone) {
        _p.cyan(r'Milestone code: ').bold(milestone.formattedID).pln();
        rs.tagDeployments(workItems, _summary._tag).listen((RDWorkItem wi) {
          _p.yellow(wi.formattedID).write(r' -> ')
              .bold(_summary._tag.name)
              .p(r' | ')
              .inverted().blue()
              .bold(wi.scheduleState.abbr)
              .p(r' | ')
              .bold(wi.owner.displayName)
              .p(r' | ')
              .pln();
        }, onDone: () {
          completer.complete();
          rs.close();
        }, onError: (error) => _p.red(error));
      }).catchError((error) {
        _p.red(error);
      });
    });
    return completer.future;
  }
}

class _MailExtraAction {

  String _subject;
  Mailer _mailer;
  bool _confirm;

  _MailExtraAction(this._subject, [this._confirm = true]) {
    _mailer = new Mailer.fromMap(cfgValue(r'mailer-1'));
  }

  Future mail(Iterable<RDWorkItem> workItems) {
    String recipient = platformUserEmail;
    if (!_confirm || askSync(new Question.confirm(
        'Confirm list email sending to [${recipient}]:'))) {
      String html = formatSimpleWIHtmlList(workItems);
      Message message = new Message(_subject, html)
        ..recipients = [recipient];
      return _mailer.send(message);
    }
    return new Future.value(null);
  }

}

class _SummaryPrinter {
  RDTag _tag;
  RepositorySync _wiMetaRepo;
  String _appVersionKey;
  _ExtraAction _extraAction;
  Map<String, dynamic> _maxValues;
  String _milestoneName;

  _SummaryPrinter(this._tag, this._wiMetaRepo, this._appVersionKey,
      [this._extraAction]);

  Future _print(Iterable<RDWorkItem> workItems) {
    _calculate(workItems);
    _printDeploymentSummary(_tag, _appVersionKey, workItems);
    if (_extraAction != null) _extraAction(workItems);
    return new Future.value(null);
  }

  void _calculate(Iterable<RDWorkItem> workItems) {
    if (hasValue(workItems)) {
      _maxValues = {};
      workItems.forEach((RDWorkItem workItem) {
        PersistedData data = _wiMetaRepo.get(workItem.formattedID);
        if (data != null && hasValue(data.data)) {
          Map<String, dynamic> m = data.data;
          m.keys.forEach((String key) {
            if (hasValue(m[key]) && hasValue(m[key].trim())) {
              if (key == r'notes') {
                if (_maxValues[key] == null) _maxValues[key] = [];
                _maxValues[key].add('[${workItem.formattedID}] -> ${m[key]}#~');
              } else if (key.startsWith(r'db/')) {
                if (_maxValues[key] == null) _maxValues[key] = [];
                _maxValues[key].add(m[key]);
              } else {
                if (_maxValues[key] == null ||
                    _maxValues[key].compareTo(m[key]) < 0)
                  _maxValues[key] = m[key];
              }
            }
          });
        }
      });
      _maxValues.keys.where((String key) => key.startsWith(r'db/')).forEach((
          String key) {
        _maxValues[key].sort();
      });
      _milestoneName = _createMilestoneName(_tag, _maxValues[_appVersionKey]);
    }
  }

  void _printDeploymentSummary(RDTag tag, String appVersionKey,
      Iterable<RDWorkItem> workItems) {
    String appVersion = _maxValues[appVersionKey];
    if (hasValue(appVersion)) {
      _p.inverted(r'  *** SUMMARY ***  ').pln();
      _p.cyan(r'Count: ').bold(workItems.length.toString()).pln();
      _p.cyan(r'Milestone: ').bold(_milestoneName).pln();
      _p.cyan(r'Tag: ').bold(tag.name).pln();
      _p.dim(r'Versions:¬').pln();
      _wimeta1.forEach((String key) {
        if (hasValue(_maxValues[key])) _p.p(r'· ').cyan(key).p(r' [')
            .bold(_maxValues[key])
            .p(
            r'] ')
            .pln();
      });
      _wimeta2.forEach((String key) {
        if (hasValue(_maxValues[key])) _p.p(r'· ').cyan(key).p(r' [')
            .bold(_maxValues[key])
            .p(
            r'] ')
            .pln();
      });
      if (hasValue(_maxValues[r'notes'])) {
        _p.cyan(r'Notes:¬').pln();
        _maxValues[r'notes'].forEach((String note) {
          _p.bold(note).pln();
        });
        _p.ln;
      }
    }
  }
}

String _createMilestoneName(RDTag tag, String appVersion) {
  StringBuffer sb = new StringBuffer(tag.name);
  sb.write(r'-[V:');
  sb.write(appVersion);
  sb.write(r']');
  return sb.toString();
}

Future<BasicRallyService> _createRDService() {
  Completer<BasicRallyService> completer = new Completer<BasicRallyService>();
  rallyService.getDeveloperByEmail(platformUserEmail).then((RDUser user) {
    if (user == null) {
      return completer.completeError(
          'User by email [${platformUserEmail}] not found!');
    }
    String password = askSync(
        new Question('RD Password for [${user.userName}]', secret: true));
    if (password.length > 2) {
      RallyDevProxy proxy = new RallyDevProxy(user.userName, password);
      BasicRallyService service = new BasicRallyService(proxy);
      service.getUser(user.ID).then((RDUser u) {
        if (u != null) return completer.complete(service);
        return completer.complete('User not found [${user.ID}]');
      }).catchError((error) => completer.completeError(error));
    }
  });
  return completer.future;
}