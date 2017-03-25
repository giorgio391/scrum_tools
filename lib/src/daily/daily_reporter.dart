import 'dart:convert';
import 'dart:html';
import 'package:angular2/core.dart';
import 'package:scrum_tools/src/rally/rally_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/web_socket_service.dart';
import 'package:scrum_tools/src/daily/daily_form.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/daily/daily_entry.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command.dart';
import 'package:scrum_tools/src/rest_service.dart';

@Component(selector: 'daily-reporter',
    templateUrl: 'daily_reporter.html',
    styleUrls: const['daily_reporter.css'],
    directives: const [DailyForm, DailyEntryView],
    providers: const [
      RallyService,
      DailyEventBus,
      WebSocketService,
      CommandsService,
      RestService
    ]
)
class DailyReporter {

  DailyEventBus _eventBus;
  RallyService _rallyService;
  RDWorkItem _currentWorkItem;
  CommandsService _commands;
  RestService _restService;

  RDWorkItem get currentWorkItem => _currentWorkItem;

  String _currentTeamMemberCode;
  String _preferredWorkItemCode;

  String get currentTeamMemberCode => _currentTeamMemberCode;

  String get preferredWorkItemCode => _preferredWorkItemCode;

  List<DailyEntry> entries;

  List<DailyEntry> selected = [];

  Map<String, DailyEntry> _statusControl = {};

  DailyEntry onEditing;

  String get workItemCode =>
      _currentWorkItem == null ? null : _currentWorkItem.formattedID;

  bool get hasEntries => entries != null && entries.isNotEmpty;

  bool get editing => onEditing != null;

  bool get validWorkItem =>
      _currentWorkItem == null ||
          _currentWorkItem.project.ID == _rallyService.defaultProjectID;

  @ViewChild(DailyForm)
  DailyForm dailyForm;

  DailyReporter(this._rallyService, this._eventBus, this._commands,
      this._restService) {
    _eventBus.addTeamMemberListener(teamMemberCodeReceived);
  }

  void teamMemberCodeReceived(String code) {
    _currentTeamMemberCode = code;
  }

  void stopwatchRequest(String command) {
    _eventBus.sendStopwatchCommandMessage(command);
  }

  @Input()
  void set workItemCode(String workItemCode) {
    if (workItemCode == null) {
      _currentWorkItem = null;
      _eventBus.sendWorkItemMessage(null);
    } else {
      _rallyService.getWorkItem(workItemCode).then((RDWorkItem workItem) {
        _currentWorkItem = workItem;
        _eventBus.sendWorkItemMessage(workItem);
      }); //.catchError((error) {
      // TODO
      //});
    }
  }

  void entryWorkItemClicked(DailyEntry entry) {
    if (entry.workItemCode != null && entry.workItemCode.isNotEmpty) {
      dailyForm.workItemCode = entry.workItemCode;
    }
  }

  void entryStatusClicked(DailyEntry entry) {
    if (entry.scope == Scope.PAST && entry.status == Status.WIP) {
      DailyEntry template = new DailyEntry.clone(entry);
      template.scope = Scope.TODAY;
      template.status = DailyEntry.defaultStatus;
      template.hours = null;
      template.notes = null;
      template.statement = null;
      template.environments = null;
      dailyForm.changeModel(template);
    }
  }

  void entryClick(DailyEntry entry, MouseEvent event) {
    if (event.button == 0) {
      if (event.ctrlKey && !event.shiftKey) {
        toggleSelected(entry);
      } else if (event.ctrlKey && event.shiftKey) {
        if (entry.workItemCode != null) {
          _preferredWorkItemCode = entry.workItemCode;
        }
      } else {
        setSelection(entry);
      }
    } else {
      startEditing(entry);
    }
  }

  void entryDblClick(DailyEntry entry, MouseEvent event) {
    if (event.ctrlKey) {
      DailyEntry entryClone = new DailyEntry.clone(entry);
      entryEdited(new ChangeRecord(null, entryClone));
      startEditing(entryClone);
    } else {
      startEditing(entry);
    }
  }

  void startEditing(DailyEntry entry) {
    if (entry != null) {
      onEditing = entry;
    }
  }

  bool isOnEdit(DailyEntry entry) => onEditing != null && onEditing == entry;

  bool statusBehind(DailyEntry entry) {
    return hasValue(entry.workItemCode) && entry.scope == Scope.PAST &&
        _statusControl[entry.workItemCode] != null &&
        entry.status < _statusControl[entry.workItemCode].status;
  }

  void listKeyUp(KeyboardEvent event) {
    if (!event.ctrlKey) {
      if (event.keyCode == KeyCode.DELETE)
        if (selected != null && selected.isNotEmpty) {
          _commands.doNewCommand(new _RemoveSelectedCommand(this, selected));
        }
    }
  }

  void keyUp(KeyboardEvent event) {
    if (event.ctrlKey) {
      if (event.keyCode == KeyCode.Z) {
        _commands.undo();
      } else if (event.keyCode == KeyCode.Y) {
        _commands.redo();
      }
    } else {
      if (event.keyCode == KeyCode.ESC) {
        dailyForm.cancel();
      }
    }
  }

  void toggleSelected(DailyEntry entry) {
    if (entry != null && entries != null && entries.isNotEmpty &&
        entries.contains(entry)) {
      if (selected.contains(entry)) {
        selected.remove(entry);
      } else {
        selected.add(entry);
      }
    }
  }

  void setSelection(DailyEntry entry) {
    if (entry != null && entries != null && entries.isNotEmpty &&
        entries.contains(entry)) {
      selected.clear();
      selected.add(entry);
    }
  }

  void clearSelection() {
    selected.clear();
  }

  bool isSelected(DailyEntry entry) =>
      entry != null && entries != null && entries.isNotEmpty &&
          entries.contains(entry) && selected.contains(entry);

  void entryEdited(ChangeRecord<DailyEntry> changeRecord) {
    if (changeRecord != null) {
      onEditing = null;
      if (changeRecord.newValue != null && changeRecord.oldValue == null) {
        if (entries == null) entries = [];
        _commands.doNewCommand(new _AddCommand(this, changeRecord.newValue));
      } else
      if (changeRecord.newValue != null && changeRecord.oldValue != null &&
          entries != null && entries.isNotEmpty) {
        _commands.doNewCommand(new _EditedCommand(
            this, changeRecord.oldValue, changeRecord.newValue));
      }
    }
  }

  void save() {
    // TODO
    List l = [];
    entries.forEach((DailyEntry entry) {
      l.add(entry.toMap());
    });
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String s = encoder.convert(l);
    print(s);
    // TODO
    DailyReport report = new DailyReport(new DateTime.now(), entries);
    _restService.saveDaily(report);
  }
}

class _AddCommand implements Command {

  DailyReporter _reporter;
  DailyEntry _newValue;
  DailyEntry _oldStatusControl;
  int _index;

  _AddCommand(this._reporter, this._newValue, [this._index = 0]);

  @override
  void doCommand() {
    _reporter.entries.insert(_index, _newValue);
    if (_newValue.scope == Scope.PAST && hasValue(_newValue.workItemCode)) {
      _oldStatusControl = _reporter._statusControl[_newValue.workItemCode];
      if (_oldStatusControl == null ||
          _oldStatusControl.status < _newValue.status) {
        _reporter._statusControl[_newValue.workItemCode] = _newValue;
      }
    }
  }

  @override
  void undo() {
    if (_oldStatusControl != null) {
      _reporter._statusControl[_newValue.workItemCode] = _oldStatusControl;
    } else {
      _reporter._statusControl.remove(_newValue.workItemCode);
    }
    _reporter.entries.remove(_newValue);
  }
}

class _EditedCommand implements Command {

  _RemoveCommand _removeCommand;
  _AddCommand _addCommand;

  _EditedCommand(DailyReporter reporter, DailyEntry oldValue,
      DailyEntry newValue) {
    int index = reporter.entries.indexOf(oldValue);
    if (index > -1) {
      _removeCommand = new _RemoveCommand(reporter, oldValue);
      _addCommand = new _AddCommand(reporter, newValue, index);
    }
  }

  @override
  void doCommand() {
    if (_removeCommand != null) {
      _removeCommand.doCommand();
    }
    if (_addCommand != null) {
      _addCommand.doCommand();
    }
  }

  @override
  void undo() {
    if (_addCommand != null) {
      _addCommand.undo();
    }
    if (_removeCommand != null) {
      _removeCommand.undo();
    }
  }
}

class _RemoveCommand implements Command {

  DailyReporter _reporter;
  DailyEntry _value;
  int _index;
  DailyEntry _oldStatusControl, _newStatusControl;

  _RemoveCommand(this._reporter, this._value);

  @override
  void doCommand() {
    int index = _reporter.entries.indexOf(_value);
    if (index > -1) {
      this._index = index;
      _reporter.entries.removeAt(index);
      if (_value.scope == Scope.PAST && hasValue(_value.workItemCode)) {
        if (_reporter._statusControl[_value.workItemCode] == _value) {
          _oldStatusControl = _reporter._statusControl[_value.workItemCode];
          _newStatusControl =
              _findStatusControl(_reporter.entries, _value.workItemCode);
          if (_newStatusControl != null) {
            _reporter._statusControl[_value.workItemCode] = _newStatusControl;
          } else {
            _reporter._statusControl.remove(_value.workItemCode);
          }
        }
      }
    }
  }

  @override
  void undo() {
    if (_index > -1) {
      if (_oldStatusControl != null) {
        _reporter._statusControl[_value.workItemCode] = _oldStatusControl;
      } else {
        _reporter._statusControl.remove(_value.workItemCode);
      }
      _reporter.entries.insert(_index, _value);
    }
  }

  static DailyEntry _findStatusControl(List<DailyEntry> list,
      String workItemCode) {
    if (!hasValue(list) || !hasValue(workItemCode)) return null;
    DailyEntry control = null;
    list.forEach((DailyEntry entry) {
      if (entry.scope == Scope.PAST && entry.workItemCode == workItemCode &&
          (control == null || control.status < entry.status))
        control = entry;
    });
    return control;
  }
}

class _RemoveSelectedCommand extends GroupCommand {

  List<DailyEntry> _selection;
  List<DailyEntry> _selected;

  _RemoveSelectedCommand(DailyReporter reporter, this._selection)
      : super (_buildCommands(reporter, _selection)) {
    this._selected = new List.unmodifiable(_selection);
  }

  @override
  void doCommand() {
    super.doCommand();
    _selection.clear();
  }

  @override
  void undo() {
    super.undo();
    _selection.clear();
    _selection.addAll(_selected);
  }

  static List<Command> _buildCommands(DailyReporter reporter,
      List<DailyEntry> _selection) {
    List<Command> commands = [];
    _selection.forEach((DailyEntry entry) {
      commands.add(new _RemoveCommand(reporter, entry));
    });
    return commands;
  }

}
