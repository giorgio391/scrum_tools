class Environment implements Comparable<Environment> {

  static final LOCAL = new Environment._internal('LOCAL', 0);
  static final QA = new Environment._internal('QA', 1);
  static final UAT = new Environment._internal('UAT', 2);
  static final PRE = new Environment._internal('PRE', 3);
  static final PRO = new Environment._internal('PRO', 4);

  static final List<Environment> VALUES = new List.unmodifiable(
      [LOCAL, QA, UAT, PRE, PRO]);

  String _value;
  int _order;

  String get value => _value;

  int get order => _order;

  Environment._internal(this._value, this._order);

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

class Scope {

  static final PAST = new Scope._internal('PAST');
  static final TODAY = new Scope._internal('TODAY');

  static final List<Scope> VALUES = new List.unmodifiable([PAST, TODAY]);

  String _value;

  String get value => _value;

  Scope._internal(this._value);

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

  @override
  String toString() {
    return value;
  }
}

class Process {

  static final CI = new Process._internal('CI');
  static final DEFINITION = new Process._internal('DEFINITION');
  static final DEPLOYMENT = new Process._internal('DEPLOYMENT');
  static final DEVELOPMENT = new Process._internal('DEVELOPMENT');
  static final INQUIRIES = new Process._internal('INQUIRIES');


  static final List<Process> VALUES = new List.unmodifiable(
      [CI, DEFINITION, DEPLOYMENT, DEVELOPMENT, INQUIRIES]);

  String _value;

  String get value => _value;

  Process._internal(this._value);

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

  @override
  String toString() {
    return value;
  }
}

class Status implements Comparable<Status> {

  static final BLOCKED = new Status._internal("BLOCKED", 0);
  static final WIP = new Status._internal("WIP", 1);
  static final RTP = new Status._internal("RTP", 2);
  static final COMPLETED = new Status._internal("COMPLETED", 3);
  static final MERGED = new Status._internal("MERGED", 4);
  static final DEPLOYED = new Status._internal("DEPLOYED", 5);

  static final List<Status> VALUES = new List.unmodifiable(
      [BLOCKED, WIP, RTP, COMPLETED, MERGED, DEPLOYED]
  );

  String _value;
  int _order;

  String get value => _value;

  int get order => _order;

  Status._internal(this._value, this._order);

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

class DailyEntry {

  Process process = Process.DEVELOPMENT;
  Scope scope = Scope.PAST;
  String teamMemberCode;
  String workItemCode;
  Status status = Status.WIP;
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
      Function buildEnvironments = (List<String> stringsList) {
        if (stringsList != null && stringsList.isNotEmpty) {
          List<Environment> list = [];
          stringsList.forEach((String value) {
            Environment env = new Environment(value);
            if(env != null) list.add(env);
          });
          if (list.isNotEmpty) {
            list.sort();
            return list;
          }
          return null;
        }
        return null;
      };
      DailyEntry entry = new DailyEntry()
        ..process = Process.parse(map['process'])
        ..scope = Scope.parse(map['scope'])
        ..teamMemberCode = map['teamMemberCode']
        ..workItemCode = map['workItemCode']
        ..status = Status.parse(map['status'])
        ..hours = map['hours']
        ..environments = buildEnvironments(map['environment'])
        ..notes = map['notes']
        ..statement = map['statement']
        ..workItemPending = map['workItemPending']
      ;
      return entry;
    }
    return null;
  }
}

class TimeReportEntry {
  DateTime startTime;
  Duration netDuration;
  Duration grossDuration;
  String teamMemberCode;

  TimeReportEntry();

  factory TimeReportEntry.fromMap(Map<String, Object> map) {
    if (map != null) {
      return new TimeReportEntry()
        ..startTime = map['startTime'] == null ? null :
        DateTime.parse(map['startTime'])
        ..netDuration = map['netDuration'] == null ? null :
        new Duration(milliseconds: map['netDuration'])
        ..grossDuration = map['grossDuration'] == null ? null :
        new Duration(milliseconds: map['grossDuration'])
        ..teamMemberCode = map['teamMemberCode'];
    }
    return null;
  }

  factory TimeReportEntry.clone(TimeReportEntry entry) {
    return entry != null ? new TimeReportEntry.fromMap(entry.toMap()) : null;
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {};
    if (startTime != null) map['startTime'] = startTime.toIso8601String();
    if (netDuration != null) map['netDuration'] = netDuration.inMilliseconds;
    if (grossDuration != null)
      map['grossDuration'] = grossDuration.inMilliseconds;
    if (teamMemberCode != null) map['teamMemberCode'] = teamMemberCode;
    return map;
  }
}

class TimeReport {

  List<TimeReportEntry> _entries;

  Iterable<TimeReportEntry> get entries => _entries;

  Duration _total;

  TimeReport(Iterable<TimeReportEntry> entries) {
    _entries = new List.unmodifiable(entries);
  }

  factory TimeReport.fromMap(Map<String, Object> map) {
    if (map != null) {
      List<Map<String, Object>> entryMaps = map['entries'];
      if (entryMaps != null && entryMaps.length > 0) {
        List<TimeReportEntry> entries = [];
        entryMaps.forEach((Map<String, Object> entryMap) {
          entries.add(new TimeReportEntry.fromMap(entryMap));
        });
        return new TimeReport(entries);
      }
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
    Map<String, Object> map = {};
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

class DailyReport {
  DateTime date;
  TimeReport timeReport;
  List<DailyEntry> _entries;

  Iterable<DailyEntry> get entries => _entries;

  DailyReport();

  factory DailyReport.fromMap(Map<String, Object> map) {
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
      return new DailyReport()
        ..date = map['date'] == null ? null : DateTime.parse(map['date'])
        ..timeReport = new TimeReport.fromMap(map['timeReport'])
        .._entries = createEntries(map['entries']);
    }
    return null;
  }

  factory DailyReport.clone(DailyReport report) {
    return report != null ? new DailyReport.fromMap(report.toMap()) : null;
  }

  Map<String, Object> toMap() {
    Map<String, Object> map = {};
    if (date != null) map['date'] = date.toIso8601String();
    if (timeReport != null) map['timeReport'] = timeReport.toMap();
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