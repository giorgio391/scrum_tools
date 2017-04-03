import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

typedef int DailyComparator(DailyEntry entry1, DailyEntry entry2);

int teamMemberPart(DailyEntry entry1, DailyEntry entry2) {
  return compareString(entry1.teamMemberCode, entry2.teamMemberCode);
}

int teamMemberPartDesc(DailyEntry entry1, DailyEntry entry2) {
  return -teamMemberPart(entry1, entry2);
}

int scopePart(DailyEntry entry1, DailyEntry entry2) {
  return entry1.scope.compareTo(entry2.scope);
}

int scopePartDesc(DailyEntry entry1, DailyEntry entry2) {
  return -scopePart(entry1, entry2);
}

int processPart(DailyEntry entry1, DailyEntry entry2) {
  return entry1.process.compareTo(entry2.process);
}

int processPartDesc(DailyEntry entry1, DailyEntry entry2) {
  return -processPart(entry1, entry2);
}

int keyPart(DailyEntry entry1, DailyEntry entry2) {
  int c = compareString(entry1.workItemCode, entry2.workItemCode);
  if (c != 0) return c;

  c = compareString(entry1.statement, entry2.statement);
  if (c != 0) return c;

  c = compareString(entry1.notes, entry2.notes);
  if (c != 0) return c;

  return 0;
}

int keyPartDesc(DailyEntry entry1, DailyEntry entry2) {
  return -keyPart(entry1, entry2);
}

DailyComparator wrapWIComparator(
    int wiComparator(RDWorkItem wi1, RDWorkItem wi2),
    Map<String, RDWorkItem> wiMap) =>
        (DailyEntry e1, DailyEntry e2) {
      RDWorkItem w1 = wiMap[e1.workItemCode];
      RDWorkItem w2 = wiMap[e2.workItemCode];
      return wiComparator(w1, w2);
    };

DailyComparator composeComparator(DailyComparator part1,
    [DailyComparator part2, DailyComparator part3, DailyComparator part4,
      DailyComparator part5, DailyComparator part6]) {
  List<DailyComparator> list = [_common, part1];
  if (part2 != null) list.add(part2);
  if (part3 != null) list.add(part3);
  if (part4 != null) list.add(part4);
  if (part5 != null) list.add(part5);
  if (part6 != null) list.add(part6);
  return (DailyEntry entry1, DailyEntry entry2) {
    for (DailyComparator part in list) {
      int c = part(entry1, entry2);
      if (c != 0) return c;
    }
    return 0;
  };
}

int _common(DailyEntry entry1, DailyEntry entry2) {
  if (entry1 == null && entry2 == null) return 0;
  if (entry1 != null && entry2 == null) return -1;
  if (entry1 == null && entry2 != null) return 1;
  return 0;
}

int compareString(String s1, String s2) {
  if (hasValue(s1) && !hasValue(s2))
    return -1;
  if (!hasValue(s1) && hasValue(s2))
    return 1;
  if (hasValue(s1) && hasValue(s2) && s1 != s2)
    return s1.compareTo(s2);
  return 0;
}