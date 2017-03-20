import 'package:angular2/core.dart';

abstract class Command {
  void doCommand();
  void undo();
}

abstract class GroupCommand extends Command {

  List<Command> _commands;

  GroupCommand(List<Command> commands) {
    _commands = new List.unmodifiable(commands);
  }

  @override
  void doCommand() {
    if (_commands != null) _commands.forEach((Command command) {command.doCommand();});
  }
  @override
  void undo() {
    if (_commands != null) _commands.reversed.forEach((Command command) {command.undo();});
  }
}

@Injectable()
class CommandsService {
  List<Command> _commands = [];
  int _currentIndex = 0;

  void doNewCommand(Command command) {
    command.doCommand();
    if (_currentIndex < _commands.length) {
      _commands.removeRange(_currentIndex, _commands.length);
    }
    _commands.add(command);
    _currentIndex++;
  }

  Command redo() {
    if (_currentIndex < _commands.length) {
      Command command = _commands.elementAt(_currentIndex);
      command.doCommand();
      _currentIndex++;
      return command;
    }
    return null;
  }

  Command undo() {
    if (_currentIndex > 0) {
      Command command = _commands.elementAt(_currentIndex - 1);
      command.undo();
      _currentIndex--;
      return command;
    }
    return null;
  }

  int get length => _commands.length;

  int get index => _currentIndex;
}