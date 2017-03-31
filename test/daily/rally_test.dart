import 'package:test/test.dart';

import 'package:scrum_tools/src/rally/basic_rally_service.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';

String now = (new DateTime.now()).toIso8601String();

Map<String, dynamic> i1 = {'_ref': '/2', '_refObjectName': 'Sprint 01'};
Map<String, dynamic> i2 = {'_ref': '/1', '_refObjectName': 'Sprint 02'};
Map<String, dynamic> i3 = {'_ref': '/0', '_refObjectName': 'Sprint 03'};

Map basicWi = {
  'ObjectID': 1,
  'CreationDate': now,
  'LastUpdateDate': now,
  'Tags': {'_tagsNameArray': []}
};

RDDefect defect([Map<String, dynamic> values]) {
  Map basicDefectMap = new Map.from(basicWi)
    ..addAll({
      'FormattedID': 'DE0001',
      'Priority': RDPriority.NONE.toString(),
      'Severity': RDSeverity.NONE.toString()
    });

  if (values != null)
    basicDefectMap.addAll(values);
  return new RDDefect.fromMap(basicDefectMap);
}

RDHierarchicalRequirement us([Map<String, dynamic> values]) {
  Map basicUsMap = new Map.from(basicWi)
    ..addAll({
      'ObjectID': 100,
      'FormattedID': 'US00001'
    });

  if (values != null)
    basicUsMap.addAll(values);
  return new RDHierarchicalRequirement.fromMap(basicUsMap);
}

List<String> rank = [
  "O~}-X~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
  // 1- DE6031
  "O~}-]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
  // 3- US19802
  "O~}.%8O~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
  // 7- DE6005
  "O~}.%J,gO~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" // 9- US19642
];

void main() {
  PrioritizationComparator comparator = new PrioritizationComparator(
      new RDIteration.fromMap({'ObjectID': 1, 'Name': i2['_refObjectName']}));
  Function compare = comparator.compare;

  test('Priorities', () {
    expect(RDPriority.LOW.compareTo(RDPriority.NONE), lessThan(0));
    expect(RDPriority.RESOLVE_IMMEDIATELY.compareTo(RDPriority.HIGH_ATTENTION),
        lessThan(0));
    expect((RDRisk.LOW.compareTo(RDRisk.NONE)), lessThan(0));
    expect((RDRisk.SHOWSTOPPER.compareTo(RDRisk.HIGH)), lessThan(0));
    expect((RDSeverity.COSMETIC.compareTo(RDSeverity.NONE)), lessThan(0));
    expect((RDSeverity.CRASH.compareTo(RDSeverity.MAJOR_PROBLEM)), lessThan(0));

    RDDefect d1 = defect();
    RDDefect d2 = defect({'ObjectID': 2, 'FormattedID': 'DE0002'});

    expect(compare(d1, d2), 0);

    d2 = defect({
      'ObjectID': 2,
      'FormattedID': 'DE0002',
      'PlanEstimate': 0.0
    });

    expect(compare(d2, d1), lessThan(0));

    d1 = defect({'PlanEstimate': 8.0});

    expect(compare(d1, d2), lessThan(0));

    expect(compare(
        defect({'Severity': RDSeverity.MINOR_PROBLEM.toString()}), us()),
        lessThan(0));

    expect(compare(
        defect({'Expedite': true}), defect({'ObjectID': 2})),
        lessThan(0));

    expect(compare(
        defect({'DragAndDropRank': rank[2]}),
        defect({'ObjectID': 2, 'DragAndDropRank': rank[3]})), lessThan(0));
    expect(compare(
        defect({'DragAndDropRank': rank[1]}),
        defect({'ObjectID': 2, 'DragAndDropRank': rank[0]})), greaterThan(0));

    expect(compare(
        defect({'Iteration': i1}), defect({'ObjectID': 2})),
        lessThan(0));
    expect(compare(
        defect(), defect({'ObjectID': 2, 'Iteration': i1})), greaterThan(0));
    expect(compare(
        defect({'Iteration': i1}), defect({'ObjectID': 2, 'Iteration': i3})),
        lessThan(0));

    expect(compare(
        defect({'Severity': RDSeverity.NONE.toString()}),
        defect({'ObjectID': 2, 'Severity': RDSeverity.COSMETIC.toString()})),
        greaterThan(0));
    expect(compare(
        defect({'Severity': RDSeverity.CRASH.toString()}),
        defect(
            {'ObjectID': 2, 'Severity': RDSeverity.MAJOR_PROBLEM.toString()})),
        lessThan(0));

    d2 = defect({
      'ObjectID': 2,
      'FormattedID': 'DE0002',
      'Priority': RDPriority.LOW.toString()
    });

    expect(compare(d2, d1), lessThan(0));

    RDHierarchicalRequirement us1 = us(
        {'ObjectID': 3, 'FormattedID': 'US00001'});

    expect(compare(d2, us1), lessThan(0));

    us1 = us(
        {'ObjectID': 3, 'FormattedID': 'US00001', 'c_Risk': 'High'});

    expect(compare(us1, d2), lessThan(0));

    expect(compare(
        defect(), defect({'ObjectID': 2, 'Iteration': i1})), greaterThan(0));

    expect(compare(
        defect({
          'Iteration': i3,
          'Priority': RDPriority.RESOLVE_IMMEDIATELY.toString()
        }), defect({'ObjectID': 2, 'Iteration': i2})),
        greaterThan(0));
  });
}