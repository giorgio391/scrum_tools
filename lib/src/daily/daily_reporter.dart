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

@Component(selector: 'daily-reporter',
    templateUrl: 'daily_reporter.html',
    styleUrls: const['daily_reporter.css'],
    directives: const [DailyForm, DailyEntryView],
    providers: const [RallyService, DailyEventBus, WebSocketService, CommandsService]
)
class DailyReporter {

  DailyEventBus _eventBus;
  RallyService _rallyService;
  RDWorkItem _currentWorkItem;
  CommandsService _commands;

  RDWorkItem get currentWorkItem => _currentWorkItem;

  String _currentTeamMemberCode;

  String get currentTeamMemberCode => _currentTeamMemberCode;

  List<DailyEntry> entries;

  List<DailyEntry> selected = [];

  DailyEntry onEditing;

  String get workItemCode =>
      _currentWorkItem == null ? null : _currentWorkItem.formattedID;

  DailyReporter(this._rallyService, this._eventBus, this._commands) {
    _eventBus.addTeamMemberListener(teamMemberCodeReceived);
  }

  void teamMemberCodeReceived(String code) {
    _currentTeamMemberCode = code;
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

  void stopwatchRequest(String command) {
    _eventBus.sendStopwatchCommandMessage(command);
  }

  void entryClick(DailyEntry entry, MouseEvent event) {
    if (event.ctrlKey || event.shiftKey) {
      toggleSelected(entry);
    } else {
      setSelection(entry);
    }
  }

  void startEditing(DailyEntry entry) {
    if (entry != null) {
      onEditing = entry;
    }
  }

  bool isOnEdit(DailyEntry entry) => onEditing != null && onEditing == entry;

  void listKeyUp(KeyboardEvent event) {
    if (!event.ctrlKey) {
      if (event.keyCode == KeyCode.DELETE)
        if (selected != null && selected.isNotEmpty) {
          _commands.doNewCommand(new _RemoveSelectedCommand(entries, selected));
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
        _commands.doNewCommand(new _AddCommand(entries, changeRecord.newValue));
      } else
      if (changeRecord.newValue != null && changeRecord.oldValue != null &&
          entries != null && entries.isNotEmpty) {
        _commands.doNewCommand(new _EditedCommand(
            entries, changeRecord.oldValue, changeRecord.newValue));
      }
    }
  }

  bool get hasEntries => entries != null && entries.isNotEmpty;
}

class _AddCommand implements Command {

  List<DailyEntry> _list;
  DailyEntry _newValue;

  _AddCommand(this._list, this._newValue);

  @override
  void doCommand() {
    _list.add(_newValue);
  }

  @override
  void undo() {
    _list.remove(_newValue);
  }
}

class _EditedCommand implements Command {

  List<DailyEntry> _list;
  DailyEntry _newValue;
  DailyEntry _oldValue;

  _EditedCommand(this._list, this._oldValue, this._newValue);

  @override
  void doCommand() {
    int index = _list.indexOf(_oldValue);
    if (index > -1) {
      _list.removeAt(index);
      _list.insert(index, _newValue);
    }
  }

  @override
  void undo() {
    int index = _list.indexOf(_newValue);
    if (index > -1) {
      _list.removeAt(index);
      _list.insert(index, _oldValue);
    }
  }
}

class _RemoveCommand implements Command {

  List<DailyEntry> _list;
  DailyEntry _value;
  int _index;

  _RemoveCommand(this._list, this._value);

  @override
  void doCommand() {
    int index = _list.indexOf(_value);
    if (index > -1) {
      this._index = index;
      _list.removeAt(index);
    }
  }

  @override
  void undo() {
    if (_index > -1) {
      _list.insert(_index, _value);
    }
  }
}

class _RemoveSelectedCommand extends GroupCommand {

  List<DailyEntry> _selection;
  List<DailyEntry> _selected;

  _RemoveSelectedCommand(List<DailyEntry> list, this._selection)
      : super (buildCommands(list, _selection)) {
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

  static List<Command> buildCommands(List<DailyEntry> list,
      List<DailyEntry> _selection) {
    List<Command> commands = [];
    _selection.forEach((DailyEntry entry) {
      commands.add(new _RemoveCommand(list, entry));
    });
    return commands;
  }

}