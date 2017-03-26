import 'dart:io';
import 'package:args/args.dart';

import 'package:scrum_tools/src/utils/command_line/config.dart';
import 'package:scrum_tools/src/utils/command_line/utils_command.dart';

void main(List<String> args) {
  ArgParser argParser = new ArgParser();

  commands.forEach((String commandName, UtilOptionCommand command) {
    argParser.addOption(commandName, abbr: command.abbr, help: command.help);
  });

  final ArgResults argResults = () {
    try {
      return argParser.parse(args);
    } on FormatException {
      print(argParser.usage);
      exit(0);
    }
  }();

  loadConfig().then((_) {
    bool commandFound = false;
    for (String commandName in commands.keys) {
      String option = argResults[commandName];
      if (option != null) {
        try {
          commands[commandName].execute(commandName, argResults, option);
          commandFound = true;
        } on FormatException {}
      }
    }

    if (!commandFound) print(argParser.usage);
  });
}
