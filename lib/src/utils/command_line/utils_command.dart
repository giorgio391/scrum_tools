import 'package:args/args.dart';

abstract class UtilOptionCommand {
  String get abbr;
  String get help;

  const UtilOptionCommand();

  void execute(String name, ArgResults args, String option) {
    executeOption(option);
  }
  void executeOption(String option);
}