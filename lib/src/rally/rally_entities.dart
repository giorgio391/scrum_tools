import 'dart:collection';

int _idFromUrl(String url) {
  return int.parse(url.substring(url.lastIndexOf(r'/') + 1));
}

class RDScheduleState {

  static final RDScheduleState UNDEFINED = new RDScheduleState._internal(
      'Undefined', 'U', 0);
  static final RDScheduleState DEFINED = new RDScheduleState._internal(
      'Defined', 'D', 1);
  static final RDScheduleState IN_PROGRESS = new RDScheduleState._internal(
      'In-Progress', 'P', 2);
  static final RDScheduleState COMPLETED = new RDScheduleState._internal(
      'Completed', 'P', 3);
  static final RDScheduleState ACCEPTED = new RDScheduleState._internal(
      'Accepted', 'A', 4);
  static final RDScheduleState ACCEPTED_BY_OWNER = new RDScheduleState
      ._internal(
      'Accepted by Product Owner', 'O', 5);

  static final List<RDScheduleState> VALUES = new List.unmodifiable(
      [UNDEFINED, DEFINED, IN_PROGRESS, COMPLETED, ACCEPTED, ACCEPTED_BY_OWNER]
  );

  static RDScheduleState parse(String value) {
    for (RDScheduleState v in VALUES) {
      if (v.name == value) {
        return v;
      }
    }
    return null;
  }

  String _name, _abbr;
  int _order;

  String get name => _name;

  String get abbr => _abbr;

  int get order => _order;


  RDScheduleState._internal (this._name, this._abbr, this._order);

  operator >(RDScheduleState s) => _order > s._order;

  operator <(RDScheduleState s) => _order < s._order;

  operator >=(RDScheduleState s) => _order > s._order || _order == s._order;

  operator <=(RDScheduleState s) => _order < s._order || _order == s._order;
}

class RDSeverity {

  static final RDSeverity CRASH = new RDSeverity._internal(
      'Crash/Data Loss', 5);
  static final RDSeverity MAJOR_PROBLEM = new RDSeverity._internal(
      'Major Problem', 4);
  static final RDSeverity MINOR_PROBLEM = new RDSeverity._internal(
      'Minor Problem', 3);
  static final RDSeverity COSMETIC = new RDSeverity._internal('Cosmetic', 2);
  static final RDSeverity NONE = new RDSeverity._internal('None', 1);

  static final List<RDSeverity> VALUES = new List.unmodifiable(
      [CRASH, MAJOR_PROBLEM, MINOR_PROBLEM, COSMETIC, NONE]
  );

  static RDSeverity parse(String value) {
    for (RDSeverity v in VALUES) {
      if (v.name == value) {
        return v;
      }
    }
    return null;
  }

  String _name;
  int _order;

  String get name => _name;

  int get order => _order;

  RDSeverity._internal (this._name, this._order);

  operator >(RDSeverity s) => _order > s._order;

  operator <(RDSeverity s) => _order < s._order;

  operator >=(RDSeverity s) => _order >= s._order;

  operator <=(RDSeverity s) => _order <= s._order;

}

class RDPriority {

  static final RDPriority RESOLVE_IMMEDIATELY = new RDPriority._internal(
      'Resolve Immediately', 4);
  static final RDPriority HIGH_ATTENTION = new RDPriority._internal(
      'High Attention', 3);
  static final RDPriority NORMAL = new RDPriority._internal('Normal', 2);
  static final RDPriority LOW = new RDPriority._internal('Low', 1);
  static final RDPriority NONE = new RDPriority._internal('None', 0);

  static final List<RDPriority> VALUES = new List.unmodifiable(
      [RESOLVE_IMMEDIATELY, HIGH_ATTENTION, NORMAL, LOW, NONE]
  );

  static RDPriority parse(String value) {
    for (RDPriority v in VALUES) {
      if (v.name == value) {
        return v;
      }
    }
    return null;
  }

  String _name;
  int _order;

  String get name => _name;

  int get order => _order;

  RDPriority._internal(this._name, this._order);

  operator >(RDPriority p) => _order > p._order;

  operator <(RDPriority p) => _order < p._order;

  operator >=(RDPriority p) => _order >= p._order;

  operator <=(RDPriority p) => _order <= p._order;

}

class RDState {

  static final RDState SUBMITTED = new RDState._internal('Submitted', 0);
  static final RDState OPEN = new RDState._internal('Open', 1);
  static final RDState FIXED = new RDState._internal('Fixed', 2);
  static final RDState CLOSED = new RDState._internal('Closed', 3);

  static final List<RDState> VALUES = new List.unmodifiable(
      [SUBMITTED, OPEN, FIXED, CLOSED]
  );

  static RDState parse(String value) {
    for (RDState v in VALUES) {
      if (v.name == value) {
        return v;
      }
    }
    return null;
  }

  String _name;
  int _order;

  String get name => _name;

  int get order => _order;

  RDState._internal(this._name, this._order);

  operator >(RDState s) => _order > s._order;

  operator <(RDState s) => _order < s._order;

  operator >=(RDState s) => _order >= s._order;

  operator <=(RDState s) => _order <= s._order;

}

/// This is the common type for any Rallydev entity.
abstract class RDEntity {

  int _objectID;

  int get objectID => _objectID;

  int get ID => _objectID;

  RDEntity._internal(this._objectID);

  RDEntity._internalFromMap(Map<String, dynamic> map) {
    _objectID = map['ObjectID'];
  }

  operator ==(RDEntity entity) =>
      entity != null && entity._objectID == _objectID;
}

class RDIteration extends RDEntity {

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
    _name = map['Name'];
    _state = map['State'];
    _creationDate = DateTime.parse(map['CreationDate']);
    _startDate = DateTime.parse(map['StartDate']);
    _endDate = DateTime.parse(map['EndDate']);
    _taskEstimateTotal = map['TaskEstimateTotal'];
    _planEstimate = map['PlanEstimate'];
    _plannedVelocity = map['PlannedVelocity'];
  }
}


/// Objects of this class represents Rallydev projects.
class RDProject extends RDEntity {
  String _name;

  String get name => _name;

  RDProject.DTO(int id, this._name) : super._internal(id);
}

/// Objects of this class represents Rallydev users.
class RDUser extends RDEntity {

  String _userName, _displayName, _emailAddress;

  String get userName => _userName;

  String get displayName => _displayName;

  String get emailAddress => _emailAddress;

  RDUser.DTO(int id, this._displayName) : super._internal(id);

  RDUser.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _userName = map['UserName'];
    _displayName = map['DisplayName'];
    _emailAddress = map['EmailAddress'];
  }
}

/// Base class for user stories and defect entities.abstract
abstract class RDWorkItem extends RDEntity {

  String _formattedID, _name, _blockedReason;
  bool _ready, _blocked;
  RDUser _owner;
  RDProject _project;
  DateTime _creationDate, _lastUpdateDate;
  double _planEstimate;
  bool _expedite;
  RDIteration _iteration;
  RDScheduleState _scheduleState;

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

  RDWorkItem._internalFromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
    _formattedID = map['FormattedID'];
    _name = map['Name'];
    _blocked = map['Blocked'];
    _blockedReason = map['BlockedReason'];
    _scheduleState = RDScheduleState.parse(map['ScheduleState']);
    _ready = map['Ready'];
    _creationDate = DateTime.parse(map['CreationDate']);
    _lastUpdateDate = DateTime.parse(map['LastUpdateDate']);
    List myTags = map['Tags']['_tagsNameArray'];
    if (myTags != null && myTags.length > 0) {
      _tags = new SplayTreeSet<String>((String v1, String v2) {
        if ((v1 != v2) && (v1 == 'UAT' || v2 == 'UAT')) {
          if (v1 == 'UAT') return -1000;
          if (v2 == 'UAT') return 1000;
        }
        return v1.compareTo(v2);
      });
      myTags.forEach((value) {
        _tags.add(value['Name']);
      });
    }
    if (map['Owner'] != null) {
      _owner = new RDUser.DTO(
          _idFromUrl(map['Owner']['_ref']), map['Owner']['_refObjectName']);
    }
    if (map['Project'] != null) {
      _project = new RDProject.DTO(
          _idFromUrl(map['Project']['_ref']), map['Project']['_refObjectName']);
    }
    if (map['Iteration'] != null) {
      _iteration = new RDIteration._internal(
          _idFromUrl(map['Iteration']['_ref']),
          map['Iteration']['_refObjectName']);
    }
    _planEstimate = map['PlanEstimate'];
    _expedite = map['Expedite'];
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
    _resolution = map['Resolution'];
    _state = RDState.parse(map['State']);
    _priority = RDPriority.parse(map['Priority']);
    _severity = RDSeverity.parse(map['Severity']);
  }
}

class RDHierarchicalRequirement extends RDWorkItem {

  bool _hasParent;

  bool get hasParent => _hasParent;

  RDHierarchicalRequirement.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
    _hasParent = map['HasParent'];
  }

}

class RDPortfolioItem extends RDWorkItem {

  RDPortfolioItem.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
  }

}
