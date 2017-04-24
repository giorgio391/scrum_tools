import 'dart:collection';

int _idFromUrl(String url) {
  return int.parse(url.substring(url.lastIndexOf(r'/') + 1));
}

DateTime _parseDate(String value) {
  if (value != null) return DateTime.parse(value);
  return null;
}

class RDScheduleState implements Comparable<RDScheduleState> {

  static const RDScheduleState UNDEFINED = const RDScheduleState._internal(
      r'Undefined', r'U', 0);
  static const RDScheduleState DEFINED = const RDScheduleState._internal(
      r'Defined', r'D', 1);
  static const RDScheduleState IN_PROGRESS = const RDScheduleState._internal(
      r'In-Progress', r'P', 2);
  static const RDScheduleState COMPLETED = const RDScheduleState._internal(
      r'Completed', r'C', 3);
  static const RDScheduleState ACCEPTED = const RDScheduleState._internal(
      r'Accepted', r'A', 4);
  static const RDScheduleState ACCEPTED_BY_OWNER = const RDScheduleState
      ._internal(
      r'Accepted by Product Owner', r'O', 5);
  static const VALUES = const [
    UNDEFINED, DEFINED, IN_PROGRESS, COMPLETED, ACCEPTED, ACCEPTED_BY_OWNER
  ];

  static RDScheduleState parse(String value) {
    for (RDScheduleState v in VALUES) {
      if (v._name == value) {
        return v;
      }
    }
    return null;
  }

  final String _name, _abbr;
  final int _order;

  String get name => _name;

  String get abbr => _abbr;

  int get order => _order;

  const RDScheduleState._internal (this._name, this._abbr, this._order);

  operator >(RDScheduleState s) => _order > s._order;

  operator <(RDScheduleState s) => _order < s._order;

  operator >=(RDScheduleState s) => _order >= s._order;

  operator <=(RDScheduleState s) => _order <= s._order;

  int compareTo(RDScheduleState other) {
    return order - other.order;
  }

  @override
  String toString() {
    return "$abbr - $name";
  }
}

class RDRisk implements Comparable<RDRisk> {

  static const RDRisk SHOWSTOPPER = const RDRisk._internal(
      r'Showstopper', 0, RDPriority.RESOLVE_IMMEDIATELY);
  static const RDRisk HIGH = const RDRisk._internal(
      r'High', 1, RDPriority.HIGH_ATTENTION);
  static const RDRisk MEDIUM = const RDRisk._internal(
      r'Medium', 2, RDPriority.NORMAL);
  static const RDRisk LOW = const RDRisk._internal(r'Low', 3, RDPriority.LOW);
  static const RDRisk NONE = const RDRisk._internal(
      r'-- No Entry --', 4, RDPriority.NONE);

  static const RDRisk MAX_RISK = SHOWSTOPPER;

  static const VALUES = const [NONE, LOW, MEDIUM, HIGH, SHOWSTOPPER];

  final String _name;
  final int _order;
  final RDPriority _equivalentPriority;

  const RDRisk._internal (this._name, this._order, this._equivalentPriority);

  String get name => _name;

  int get order => _order;

  RDPriority get equivalentPriority => _equivalentPriority;

  int compareTo(RDRisk other) {
    return order - other.order;
  }

  @override
  String toString() {
    return _name;
  }

  static RDRisk parse(String value) {
    if (value == null) return NONE;
    for (RDRisk v in VALUES) {
      if (v._name == value) {
        return v;
      }
    }
    return null;
  }
}

class RDSeverity implements Comparable<RDSeverity> {

  static const RDSeverity CRASH = const RDSeverity._internal(
      r'Crash/Data Loss', 0);
  static const RDSeverity MAJOR_PROBLEM = const RDSeverity._internal(
      r'Major Problem', 1);
  static const RDSeverity MINOR_PROBLEM = const RDSeverity._internal(
      r'Minor Problem', 2);
  static const RDSeverity COSMETIC = const RDSeverity._internal(r'Cosmetic', 3);
  static const RDSeverity NONE = const RDSeverity._internal(r'None', 4);

  static const RDSeverity MAX_SEVERITY = CRASH;

  static const VALUES = const
  [NONE, COSMETIC, MINOR_PROBLEM, MAJOR_PROBLEM, CRASH];

  final String _name;
  final int _order;

  String get name => _name;

  int get order => _order;

  const RDSeverity._internal (this._name, this._order);

  operator >(RDSeverity s) => _order > s._order;

  operator <(RDSeverity s) => _order < s._order;

  operator >=(RDSeverity s) => _order >= s._order;

  operator <=(RDSeverity s) => _order <= s._order;

  int compareTo(RDSeverity other) {
    return order - other.order;
  }

  @override
  String toString() {
    return _name;
  }

  static RDSeverity parse(String value) {
    for (RDSeverity v in VALUES) {
      if (v._name == value) {
        return v;
      }
    }
    return null;
  }
}

class RDPriority implements Comparable<RDPriority> {

  static const RDPriority RESOLVE_IMMEDIATELY = const RDPriority._internal(
      r'Resolve Immediately', 0);
  static const RDPriority HIGH_ATTENTION = const RDPriority._internal(
      r'High Attention', 1);
  static const RDPriority NORMAL = const RDPriority._internal(r'Normal', 2);
  static const RDPriority LOW = const RDPriority._internal(r'Low', 3);
  static const RDPriority NONE = const RDPriority._internal(r'None', 4);

  static const RDPriority MAX_PRIORITY = RESOLVE_IMMEDIATELY;

  static const VALUES = const [
    NONE, LOW, NORMAL, HIGH_ATTENTION, RESOLVE_IMMEDIATELY];

  final String _name;
  final int _order;

  String get name => _name;

  int get order => _order;

  const RDPriority._internal(this._name, this._order);

  operator >(RDPriority p) => _order > p._order;

  operator <(RDPriority p) => _order < p._order;

  operator >=(RDPriority p) => _order >= p._order;

  operator <=(RDPriority p) => _order <= p._order;

  int compareTo(RDPriority other) {
    return order - other.order;
  }

  @override
  String toString() {
    return _name;
  }

  static RDPriority parse(String value) {
    for (RDPriority v in VALUES) {
      if (v._name == value) {
        return v;
      }
    }
    return null;
  }
}

class RDState implements Comparable<RDState> {

  static const RDState SUBMITTED = const RDState._internal(r'Submitted', 0);
  static const RDState OPEN = const RDState._internal(r'Open', 1);
  static const RDState FIXED = const RDState._internal(r'Fixed', 2);
  static const RDState CLOSED = const RDState._internal(r'Closed', 3);

  static const VALUES = const [CLOSED, FIXED, OPEN, SUBMITTED];

  final String _name;
  final int _order;

  String get name => _name;

  int get order => _order;

  const RDState._internal(this._name, this._order);

  operator >(RDState s) => _order > s._order;

  operator <(RDState s) => _order < s._order;

  operator >=(RDState s) => _order >= s._order;

  operator <=(RDState s) => _order <= s._order;

  int compareTo(RDState other) {
    return order - other.order;
  }

  @override
  String toString() {
    return _name;
  }

  static RDState parse(String value) {
    for (RDState v in VALUES) {
      if (v._name == value) {
        return v;
      }
    }
    return null;
  }
}

/// This is the common type for any Rallydev entity.
abstract class RDEntity {

  int _objectID;

  int get objectID => _objectID;

  int get ID => _objectID;

  RDEntity._internal(this._objectID);

  RDEntity._internalFromMap(Map<String, dynamic> map) {
    _objectID = map[r'ObjectID'];
  }

  operator ==(RDEntity entity) =>
      entity != null && entity._objectID == _objectID &&
          this.runtimeType == entity.runtimeType;

  @override
  String toString() {
    return "${this.runtimeType} - $ID";
  }
}

class RDRevision extends RDEntity {

  DateTime _creationDate;
  String _description;
  int _revisionNumber;
  RDUser _user;

  DateTime get creationDate => _creationDate;
  String get description => _description;
  int get revisionNumber => _revisionNumber;
  RDUser get user => _user;

  RDRevision(int id) : super._internal(id);
  RDRevision.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _creationDate = _parseDate(map[r'CreationDate']);
    _description = map[r'Description'];
    _revisionNumber = int.parse(map[r'RevisionNumber']);
    _user = new RDUser.DTO(
        _idFromUrl(map[r'User'][r'_ref']), map[r'User'][r'_refObjectName']);
  }

}

class RDIteration extends RDEntity implements Comparable<RDIteration> {

  String _name, _state;
  DateTime _creationDate, _startDate, _endDate;
  double _taskEstimateTotal, _planEstimate, _plannedVelocity;

  String get name => _name;

  String get state => _state;

  DateTime get creationDate => _creationDate;

  DateTime get startDate => _startDate;

  DateTime get endDate => _endDate;

  double get taskEstimateTotal => _taskEstimateTotal;

  double get planEstimate => _planEstimate;

  double get plannedVelocity => _plannedVelocity;

  RDIteration._internal(int id, this._name) : super._internal(id);

  RDIteration.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _name = map[r'Name'];
    _state = map[r'State'];
    _creationDate = _parseDate(map[r'CreationDate']);
    _startDate = _parseDate(map[r'StartDate']);
    _endDate = _parseDate(map[r'EndDate']);
    _taskEstimateTotal = map[r'TaskEstimateTotal'];
    _planEstimate = map[r'PlanEstimate'];
    _plannedVelocity = map[r'PlannedVelocity'];
  }

  operator >(RDIteration other) {
    if (startDate != null && other.endDate != null) {
      return (startDate.isAfter(other.endDate) || startDate == other.endDate);
    }
    return name.compareTo(other.name) > 0;
  }

  operator <(RDIteration other) {
    if (endDate != null && other.startDate != null) {
      return endDate.isBefore(other.startDate) || endDate == other.startDate;
    }
    return name.compareTo(other.name) < 0;
  }

  operator >=(RDIteration other) => objectID == other.objectID || this > other;

  operator <=(RDIteration other) => objectID == other.objectID || this < other;

  int compareTo(RDIteration other) {
    if (this < other) return -1;
    if (this > other) return 1;
    return 0;
  }

  @override
  String toString() {
    return "${super.toString()} - $name";
  }
}


/// Objects of this class represents Rallydev projects.
class RDProject extends RDEntity {
  String _name;

  String get name => _name;

  RDProject.DTO(int id, this._name) : super._internal(id);

  @override
  String toString() {
    return "${super.toString()} - $name";
  }
}

/// Objects of this class represents Rallydev users.
class RDUser extends RDEntity {

  String _userName, _displayName, _emailAddress;

  String get userName => _userName;

  String get displayName => _displayName;

  String get emailAddress => _emailAddress;

  RDUser.DTO(int id, this._displayName) : super._internal(id);

  RDUser.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _userName = map[r'UserName'];
    _displayName = map[r'DisplayName'];
    _emailAddress = map[r'EmailAddress'];
  }

  @override
  String toString() {
    return "${super.toString()} - $displayName";
  }
}

/// Base class for user stories and defect entities.abstract
abstract class RDWorkItem extends RDEntity {

  String _formattedID, _name, _blockedReason, _notes;
  bool _ready, _blocked;
  RDUser _owner;
  RDProject _project;
  DateTime _creationDate, _lastUpdateDate;
  double _planEstimate;
  bool _expedite;
  RDIteration _iteration;
  RDScheduleState _scheduleState;
  String _rank;
  bool _isDeployed;
  int _revisionHistoryID;

  String get name => _name;

  bool get expedite => _expedite;

  DateTime get creationDate => _creationDate;

  DateTime get lastUpdateDate => _lastUpdateDate;

  Set<String> _tags;

  String get formattedID => _formattedID;

  bool get ready => _ready;

  bool get blocked => _blocked;

  RDUser get owner => _owner;

  RDProject get project => _project;

  String get blockedReason => _blockedReason;

  Set<String> get tags => _tags;

  double get planEstimate => _planEstimate;

  RDIteration get iteration => _iteration;

  RDScheduleState get scheduleState => _scheduleState;

  String get rank => _rank;

  bool get isDeployed => _isDeployed;

  int get revisionHistoryID => _revisionHistoryID;

  String get notes => _notes;

  RDWorkItem._internalFromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
    _formattedID = map[r'FormattedID'];
    _name = map[r'Name'];
    _blocked = map[r'Blocked'];
    _blockedReason = map[r'BlockedReason'];
    _scheduleState = RDScheduleState.parse(map[r'ScheduleState']);
    _ready = map[r'Ready'];
    _creationDate = DateTime.parse(map[r'CreationDate']);
    _lastUpdateDate = DateTime.parse(map[r'LastUpdateDate']);
    _rank = map[r'DragAndDropRank'];
    _revisionHistoryID = _idFromUrl(map[r'RevisionHistory'][r'_ref']);
    _notes = map[r'Notes'];
    List myTags = map[r'Tags'][r'_tagsNameArray'];
    if (myTags != null && myTags.length > 0) {
      _tags = new SplayTreeSet<String>((String v1, String v2) {
        if ((v1 != v2) && (v1 == r'UAT' || v2 == r'UAT')) {
          if (v1 == r'UAT') return -1000;
          if (v2 == r'UAT') return 1000;
        }
        return v1.compareTo(v2);
      });
      myTags.forEach((value) {
        String s = value[r'Name'];
        if (s == r'UAT' || s == r'PRE' || s == r'PRO') _isDeployed = true;
        _tags.add(s);
      });
    }
    if (map[r'Owner'] != null) {
      _owner = new RDUser.DTO(
          _idFromUrl(map[r'Owner'][r'_ref']), map[r'Owner'][r'_refObjectName']);
    }
    if (map[r'Project'] != null) {
      _project = new RDProject.DTO(
          _idFromUrl(map[r'Project'][r'_ref']), map[r'Project'][r'_refObjectName']);
    }
    if (map[r'Iteration'] != null) {
      _iteration = new RDIteration._internal(
          _idFromUrl(map[r'Iteration']['_ref']),
          map[r'Iteration'][r'_refObjectName']);
    }
    _planEstimate = map[r'PlanEstimate'];
    _expedite = map[r'Expedite'];
  }

  @override
  String toString() {
    return "${super.toString()} - $formattedID";
  }

}

class RDDefect extends RDWorkItem {

  RDPriority _priority;
  RDSeverity _severity;
  RDState _state;
  String _resolution;

  String get resolution => _resolution;

  RDPriority get priority => _priority;

  RDSeverity get severity => _severity;

  RDDefect.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _resolution = map[r'Resolution'];
    _state = RDState.parse(map[r'State']);
    _priority = RDPriority.parse(map[r'Priority']);
    _severity = RDSeverity.parse(map[r'Severity']);
  }
}

class RDHierarchicalRequirement extends RDWorkItem {

  RDRisk _risk;
  bool _hasParent;
  int _predecessorsCount = 0;

  RDRisk get risk => _risk;

  bool get hasParent => _hasParent;

  int get predecessorsCount => _predecessorsCount;

  RDHierarchicalRequirement.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
    _hasParent = map[r'HasParent'];
    _risk = RDRisk.parse(map[r'c_Risk']);
    _predecessorsCount = map[r'Predecessors'][r'Count'];
  }
}

class RDPortfolioItem extends RDWorkItem {

  RDPortfolioItem.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
  }

}

void main(List<String> args) {
  // To test
  RDIteration ite1 = new RDIteration._internal(555, "Ite1");
  RDIteration ite2 = new RDIteration._internal(555, "Ite2");

  RDProject pro1 = new RDProject.DTO(555, "Pro1");

  assert(ite1 == ite2);
  assert(ite1 != pro1);
}
