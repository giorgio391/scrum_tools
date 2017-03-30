import 'package:test/test.dart';

import 'package:scrum_tools/src/rally/basic_rally_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';

void main() {
  List<String> ranks = [
    "O~}-X~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    // 1- DE6031
    "O~}-]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    // 3- US19802
    "O~}.%8O~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    // 7- DE6005
    "O~}.%J,gO~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" // 9- US19642
  ];

  String now = (new DateTime.now()).toIso8601String();
  Map basicWi = {
    'CreationDate': now,
    'LastUpdateDate': now,
    'Tags': {'_tagsNameArray': []}
  };

  Map basicDefect = new Map.from(basicWi)
    ..addAll({
      'Priority': RDPriority.NONE.toString(),
      'Severity': RDSeverity.NONE.toString()
    });

  test('Priorities', () {
    expect(RDPriority.LOW.compareTo(RDPriority.NONE), lessThan(0));
    expect(RDPriority.RESOLVE_IMMEDIATELY.compareTo(RDPriority.HIGH_ATTENTION),
        lessThan(0));

    RDDefect defect1 = new RDDefect.fromMap(new Map.from(basicDefect)
      ..addAll({'ObjectID': 1,
        'FormattedID': 'DE0001'}));
    RDDefect defect2 = new RDDefect.fromMap(new Map.from(basicDefect)
      ..addAll({'ObjectID': 2,
        'FormattedID': 'DE0002'}));
    expect(compareWIByPrioritization(defect1, defect2), 0);

    defect2 = new RDDefect.fromMap(new Map.from(basicDefect)
      ..addAll({
        'ObjectID': 2,
        'FormattedID': 'DE0002',
        'Priority': RDPriority.LOW.toString()
      }));
    expect(compareWIByPrioritization(defect2, defect1), lessThan(0));

    RDHierarchicalRequirement us1 = new RDHierarchicalRequirement.fromMap(
        new Map.from(basicWi)
          ..addAll({'ObjectID': 3, 'FormattedID': 'US00001'}));

    expect(compareWIByPrioritization(defect2, us1), lessThan(0));

    us1 = new RDHierarchicalRequirement.fromMap
      (new Map.from(basicWi)..addAll({'c_Risk': 'High'}));

    expect(compareWIByPrioritization(us1, defect2), lessThan(0));
  });
}