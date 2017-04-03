import 'package:scrum_tools/src/utils/helpers.dart';

String displayDescription(DailyEntry entry) {
  if (hasValue(entry.workItemCode)) return entry.workItemCode;
  if (hasValue(entry.statement)) return '* ${entry.statement}';
  return '~ ${entry.notes}';
}

String trackingKey(DailyEntry entry) =>
    '${entry.process.toString()} # ${displayDescription(entry)}';

class Environment implements Comparable<Environment> {

  static const LOCAL = const Environment._internal('LOCAL', 0);
  static const QA = const Environment._internal('QA', 1);
  static const UAT = const Environment._internal('UAT', 2);
  static const PRE = const Environment._internal('PRE', 3);
  static const PRO = const Environment._internal('PRO', 4);

  static final List<Environment> VALUES = new List.unmodifiable(
      [LOCAL, QA, UAT, PRE, PRO]);

  final String _value;
  final int _order;

  String get value => _value;

  int get order => _order;

  const Environment._internal(this._value, this._order);

  factory Environment(String value) {
    return parse(value);
  }

  static Environment parse(String value) {
    for (Environment v in VALUES) {
      if (v.value == value) {
        return v;
      }
    }
    return null;
  }

  operator >(Environment s) => _order > s._order;

  operator <(Environment s) => _order < s._order;

  operator >=(Environment s) => _order >= s._order;

  operator <=(Environment s) => _order <= s._order;

  int compareTo(Environment other) {
    return order - other.order;
  }

  @override
  String toString() {
    return value;
  }
}

class Scope implements Comparable<Scope> {

  static const PAST = const Scope._internal('PAST');
  static const TODAY = const Scope._internal('TODAY');

  static final List<Scope> VALUES = new List.unmodifiable([PAST, TODAY]);

  final String _value;

  String get value => _value;

  const Scope._internal(this._value);

  factory Scope(String value) {
    return parse(value);
  }

  static Scope parse(String value) {
    for (Scope v in VALUES) {
      if (v.value == value) {
        return v;
      }
    }
    return null;
  }

  int compareTo(Scope other) {
    if (this == other) return 0;
    if (this == PAST) return -1;
    return 1;
  }

  @override
  String toString() {
    return value;
  }
}

class Process implements Comparable<Process> {

  static const DEFINITION = const Process._internal(0, 'DEFINITION');
  static const OPERATIONS = const Process._internal(1, 'OPERATIONS');
  static const DEVELOPMENT = const Process._internal(2, 'DEVELOPMENT');
  static const CI = const Process._internal(3, 'CI');
  static const DEPLOYMENT = const Process._internal(4, 'DEPLOYMENT');
  static const INQUIRIES = const Process._internal(5, 'INQUIRIES');

  static final List<Process> VALUES = new List.unmodifiable(
      [DEFINITION, OPERATIONS, DEVELOPMENT, CI, DEPLOYMENT, INQUIRIES]);

  final String _value;
  final int _order;

  String get value => _value;

  const Process._internal(this._order, this._value);

  factory Process(String value) {
    return parse(value);
  }

  static Process parse(String value) {
    for (Process v in VALUES) {
      if (v.value == value) {
        return v;
      }
    }
    return null;
  }

  int compareTo(Process other) => this._order - other._order;

  @override
  String toString() {
    return value;
  }
}

class Status implements Comparable<Status> {

  static const BLOCKED = const Status._internal("BLOCKED", 0);
  static const WIP = const Status._internal("WIP", 1);
  static const RTP = const Status._internal("RTP", 2);
  static const COMPLETED = const Status._internal("COMPLETED", 3);
  static const MERGED = const Status._internal("MERGED", 4);
  static const DEPLOYED = const Status._internal("DEPLOYED", 5);

  static final List<Status> VALUES = new List.unmodifiable(
      [BLOCKED, WIP, RTP, COMPLETED, MERGED, DEPLOYED]
  );

  final String _value;
  final int _order;

  String get value => _value;

  int get order => _order;

  const Status._internal(this._value, this._order);

  factory Status(String value) {
    return parse(value);
  }

  static Status parse(String value) {
    for (Status v in VALUES) {
      if (v._value == value) {
        return v;
      }
    }
    return null;
  }

  operator >(Status s) => _order > s._order;

  operator <(Status s) => _order < s._order;

  operator >=(Status s) => _order >= s._order;

  operator <=(Status s) => _order <= s._order;

  int compareTo(Status other) {
    return order - other.order;
  }

  @override
  String toString() {
    return value;
  }
}

class DailyEntry implements Mappable {

  static const defaultStatus = null;
  static const defaultProcess = Process.DEVELOPMENT;

  Process process = defaultProcess;
  Scope scope = Scope.PAST;
  String teamMemberCode;
  String workItemCode;
  Status status = defaultStatus;
  double hours;
  String notes;
  String statement;
  List<Environment> environments;
  bool workItemPending = false;

  DailyEntry();

  factory DailyEntry.fromMap(Map<String, Object> map) {
    return _fromMap(map);
  }

  factory DailyEntry.clone(DailyEntry entry) {
    return entry != null ? new DailyEntry.fromMap(entry.toMap()) : null;
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {};
    if (process != null) {
      map['process'] = process.value;
    }
    if (scope != null) {
      map['scope'] = scope.value;
    }
    if (teamMemberCode != null && teamMemberCode.isNotEmpty) {
      map['teamMemberCode'] = teamMemberCode;
    }
    if (workItemCode != null && workItemCode.isNotEmpty) {
      map['workItemCode'] = workItemCode;
    }
    if (status != null) {
      map['status'] = status.value;
    }
    if (hours != null) {
      map['hours'] = hours;
    }
    if (environments != null && environments.isNotEmpty) {
      List list = [];
      environments.forEach((Environment env) {
        list.add(env.value);
      });
      list.sort();
      map['environment'] = list;
    }
    if (notes != null && notes.isNotEmpty) {
      map['notes'] = notes;
    }
    if (statement != null && statement.isNotEmpty) {
      map['statement'] = statement;
    }
    map['workItemPending'] = workItemPending;
    return map;
  }

  static DailyEntry _fromMap(Map<String, Object> map) {
    if (map != null) {
      DailyEntry entry = new DailyEntry();
      entry.changeFromMap(map);
      return entry;
    }
    return null;
  }

  void changeFrom(DailyEntry entry) {
    if (entry != null && entry != this) {
      changeFromMap(entry.toMap());
    }
  }

  void changeFromMap(Map<String, Object> map) {
    if (map != null) {
      Function buildEnvironments = (List<String> stringsList) {
        if (stringsList != null && stringsList.isNotEmpty) {
          List<Environment> list = [];
          stringsList.forEach((String value) {
            Environment env = new Environment(value);
            if (env != null) list.add(env);
          });
          if (list.isNotEmpty) {
            list.sort();
            return list;
          }
        }
        return null;
      };
      this
        ..process = Process.parse(map['process'])
        ..scope = Scope.parse(map['scope'])
        ..teamMemberCode = map['teamMemberCode']
        ..workItemCode = map['workItemCode']
        ..status = Status.parse(map['status'])
        ..hours = map['hours'] is int
            ? (map['hours'] as int).toDouble()
            : map['hours']
        ..environments = buildEnvironments(map['environment'])
        ..notes = map['notes']
        ..statement = map['statement']
        ..workItemPending = map['workItemPending']
      ;
    }
    return null;
  }
}

class TimeReportEntry implements Mappable {
  static const int _serialVer = 1;
  Duration netDuration;
  String teamMemberCode;

  TimeReportEntry();

  factory TimeReportEntry.fromMap(Map<String, Object> map) {
    if (map != null) {
      return new TimeReportEntry()
        ..netDuration = map['netDuration'] == null ? null :
        parseDuration(map['netDuration'])
        ..teamMemberCode = map['teamMemberCode'];
    }
    return null;
  }

  factory TimeReportEntry.clone(TimeReportEntry entry) {
    return entry != null ? new TimeReportEntry.fromMap(entry.toMap()) : null;
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {'_serialVer': _serialVer};
    if (teamMemberCode != null) map['teamMemberCode'] = teamMemberCode;
    if (netDuration != null) map['netDuration'] = netDuration.toString();
    return map;
  }
}

class TimeReport implements MappableWithDate {

  static const int _serialVer = 1;

  DateTime _date;

  List<TimeReportEntry> _entries;

  Iterable<TimeReportEntry> get entries => _entries;

  Duration _total, _grossDuration;

  DateTime get date => _date;

  Duration get grossDuration => _grossDuration;

  TimeReport(DateTime this._date, this._grossDuration,
      Iterable<TimeReportEntry> entries) {
    _entries = entries == null ? null : new List.unmodifiable(entries);
  }

  factory TimeReport.fromMap(Map<String, Object> map) {
    return buildFromMap(map);
  }

  static TimeReport buildFromMap(Map<String, Object> map) {
    if (map != null) {
      return new TimeReport(
          map['date'] == null ? null : DateTime.parse(map['date']),
          parseDuration(map['grossDuration']),
              () {
            List<Map<String, Object>> entryMaps = map['entries'];
            if (entryMaps != null && entryMaps.isNotEmpty) {
              List<TimeReportEntry> entries = [];
              entryMaps.forEach((Map<String, Object> entryMap) {
                entries.add(new TimeReportEntry.fromMap(entryMap));
              });
              return entries;
            }
            return null;
          }());
    }
    return null;
  }

  factory TimeReport.clone(TimeReport report) {
    return report != null ? new TimeReport.fromMap(report.toMap()) : null;
  }

  Duration get totalDuration {
    if (_total == null && _entries != null && _entries.length > 0) {
      _total = new Duration();
      _entries.forEach((TimeReportEntry entry) {
        if (entry.netDuration != null) _total = _total + entry.netDuration;
      });
    }
    return _total;
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {'_serialVer': _serialVer};
    if (date != null) map['date'] = date.toIso8601String();
    if (grossDuration != null) map['grossDuration'] = grossDuration.toString();
    if (_entries != null && _entries.length > 0) {
      List<Map<String, Object>> entryMaps = [];
      _entries.forEach((TimeReportEntry entry) {
        entryMaps.add(entry.toMap());
      });
      map['entries'] = entryMaps;
    }
    return map;
  }
}

class DailyReport implements MappableWithDate {

  static const int _serialVer = 1;

  DateTime _date;
  List<DailyEntry> _entries;

  Iterable<DailyEntry> get entries => _entries;

  DateTime get date => _date;

  DailyReport(this._date, this._entries);

  DailyReport._internal();

  factory DailyReport.fromMap(Map<String, Object> map) {
    return buildFromMap(map);
  }

  static DailyReport buildFromMap(Map<String, Object> map) {
    if (map != null) {
      Function createEntries = (Iterable<Map<String, Object>> entryMaps) {
        if (entryMaps != null && entryMaps.length > 0) {
          List<DailyEntry> entries = [];
          entryMaps.forEach((Map<String, Object> entryMap) {
            entries.add(new DailyEntry.fromMap(entryMap));
          });
          return entries;
        }
        return null;
      };
      return new DailyReport._internal()
        .._date = map['date'] == null ? null : DateTime.parse(map['date'])
        .._entries = createEntries(map['entries']);
    }
    return null;
  }

  factory DailyReport.clone(DailyReport report) {
    return report != null ? new DailyReport.fromMap(report.toMap()) : null;
  }

  void sortEntries(Comparator<DailyEntry> comparator) {
    if (_entries != null) _entries.sort(comparator);
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {'_serialVer': _serialVer};
    if (date != null) map['date'] = date.toIso8601String();
    if (_entries != null && _entries.length > 0) {
      List<Map<String, Object>> entryMaps = [];
      _entries.forEach((DailyEntry entry) {
        entryMaps.add(entry.toMap());
      });
      map['entries'] = entryMaps;
    }
    return map;
  }
}