import 'dart:collection';
import 'package:scrum_tools/src/rally/const.dart';

int idFromRef(String url) {
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

  final int _objectID;

  int get objectID => _objectID;

  int get ID => _objectID;

  const RDEntity._internal(this._objectID);

  RDEntity._internalFromMap(Map<String, dynamic> map)
      : this._internal(map[r'ObjectID']);

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
        idFromRef(map[r'User'][r'_ref']), map[r'User'][r'_refObjectName']);
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

  static const String RDTypeKey = r'project';

  static const RDProject Gordon = const RDProject._internal(
      gordonProjectId, r'Gordon');

  final String _name;

  const RDProject._internal(int id, this._name) : super._internal(id);

  factory RDProject.DTO(int id, String name) {
    if (id == Gordon.ID) return Gordon;
    return new RDProject._internal(id, name);
  }

  String get name => _name;

  String get ref => '/${RDTypeKey}/${ID}';

  @override
  String toString() {
    return "${super.toString()} - $name";
  }
}

class RDMilestone extends RDEntity implements Comparable<RDMilestone> {

  static const String RDTypeKey = r'milestone';

  String _notes;
  DateTime _targetDate, _creationDate;
  String _name;
  String _formattedID;

  RDMilestone.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _name = map[r'Name'];
    _notes = map[r'Notes'];
    _formattedID = map[r'FormattedID'];
    _creationDate = DateTime.parse(map[r'CreationDate']);
    if (map[r'TargetDate'] != null) {
      _targetDate = DateTime.parse(map[r'TargetDate']);
    }
  }

  RDMilestone.DTO(int id, this._name, this._targetDate) : super._internal(id);

  String get name => _name;

  DateTime get creationDate => _creationDate;

  String get notes => _notes;

  DateTime get targetDate => _targetDate;

  String get formattedID => _formattedID;

  String get ref => '/${RDTypeKey}/${ID}';

  operator >(RDMilestone other) {
    if (_targetDate != null && other._targetDate != null) {
      return _targetDate.isAfter(other._targetDate);
    }
    return _name.compareTo(other._name) > 0;
  }

  operator <(RDMilestone other) {
    if (_targetDate != null && other._targetDate != null) {
      return _targetDate.isBefore(other._targetDate);
    }
    return _name.compareTo(other._name) < 0;
  }

  operator >=(RDMilestone other) => objectID == other.objectID || this > other;

  operator <=(RDMilestone other) => objectID == other.objectID || this < other;

  int compareTo(RDMilestone other) {
    if (this < other) return -1;
    if (this > other) return 1;
    return 0;
  }

}

class RDTag extends RDEntity implements Comparable<RDTag> {

  static const String RDTypeKey = r'tag';

  static const UAT = const RDTag._internal(55550759656, r'UAT', 1);
  static const PRE = const RDTag._internal(55550758971, r'PRE', 2);
  static const PRO = const RDTag._internal(55550759466, r'PRO', 3);
  static const NOT_TO_DEPLOY = const RDTag._internal(
      98533801960, r'NOT TO DEPLOY', 4);

  final String _name;
  final int _order;

  const RDTag._internal(int id, this._name, this._order) : super._internal(id);

  factory RDTag.DTO(int id, String name) {
    if (id == UAT.ID)
      return UAT;
    else if (id == PRE.ID)
      return PRE;
    else if (id == PRO.ID)
      return PRO;
    else if (id == NOT_TO_DEPLOY.ID) return NOT_TO_DEPLOY;
    RDTag tag = new RDTag._internal(id, name, 10);
    return tag;
  }

  String get name => _name;

  String get ref => '/${RDTypeKey}/${ID}';

  operator >(RDTag t) => compareTo(t) > 0;

  operator <(RDTag t) => compareTo(t) < 0;

  operator >=(RDTag t) => compareTo(t) >= 0;

  operator <=(RDTag t) => compareTo(t) <= 0;

  @override
  int compareTo(RDTag other) {
    if (_order == other._order) return _name.compareTo(other._name);
    return _order - other._order;
  }

  @override
  String toString() => name;

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

  String _name;
  String _formattedID, _blockedReason, _notes;
  bool _ready, _blocked;
  RDUser _owner;
  RDProject _project;
  DateTime _creationDate, _lastUpdateDate;
  double _planEstimate;
  bool _expedite;
  RDIteration _iteration;
  RDScheduleState _scheduleState;
  RDPortfolioItem _portfolioItem;
  String _rank;
  bool _isDeployed;
  int _revisionHistoryID;
  Set<RDTag> _tags;
  Set<RDMilestone> _milestones;

  String get name => _name;

  bool get expedite => _expedite;

  DateTime get creationDate => _creationDate;

  DateTime get lastUpdateDate => _lastUpdateDate;

  String get formattedID => _formattedID;

  bool get ready => _ready;

  bool get blocked => _blocked;

  RDUser get owner => _owner;

  RDProject get project => _project;

  String get blockedReason => _blockedReason;

  Set<RDTag> get tags => _tags;

  Set<RDMilestone> get milestones => _milestones;

  double get planEstimate => _planEstimate;

  RDIteration get iteration => _iteration;

  RDScheduleState get scheduleState => _scheduleState;

  String get rank => _rank;

  bool get isDeployed => _isDeployed;

  int get revisionHistoryID => _revisionHistoryID;

  String get notes => _notes;

  String get ref;

  RDPortfolioItem get portfolioItem => _portfolioItem;

  bool get inquiry => RDPortfolioItem.INQUIRIES == _portfolioItem;
  bool get operation => RDPortfolioItem.OPERATIONS == _portfolioItem;

  RDWorkItem.DTO(int id, this._name, this._formattedID) : super._internal(id);

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
    _revisionHistoryID = idFromRef(map[r'RevisionHistory'][r'_ref']);
    _notes = map[r'Notes'];
    List myTags = map[r'Tags'][r'_tagsNameArray'];
    if (myTags != null && myTags.length > 0) {
      _tags = new SplayTreeSet<RDTag>();
      myTags.forEach((value) {
        RDTag tag = new RDTag.DTO(idFromRef(value[r'_ref']), value[r'Name']);
        if (tag == RDTag.UAT || tag == RDTag.PRE || tag == RDTag.PRO)
          _isDeployed = true;
        _tags.add(tag);
      });
    }
    List myMilestones = map[r'Milestones'][r'_tagsNameArray'];
    if (myMilestones != null && myMilestones.length > 0) {
      _milestones = new SplayTreeSet<RDMilestone>();
      myMilestones.forEach((value) {
        RDMilestone milestone = new RDMilestone.DTO(
            idFromRef(value[r'_ref']), value[r'Name'],
            DateTime.parse(value[r'TargetDate']));
        _milestones.add(milestone);
      });
    }
    if (map[RDPortfolioItem.RDTypeName] != null) {
      _portfolioItem = new RDPortfolioItem.DTO(
          idFromRef(map[RDPortfolioItem.RDTypeName][r'_ref']),
          map[RDPortfolioItem.RDTypeName][r'_refObjectName'], null);
    }
    if (map[r'Owner'] != null) {
      _owner = new RDUser.DTO(
          idFromRef(map[r'Owner'][r'_ref']), map[r'Owner'][r'_refObjectName']);
    }
    if (map[r'Project'] != null) {
      _project = new RDProject.DTO(
          idFromRef(map[r'Project'][r'_ref']),
          map[r'Project'][r'_refObjectName']);
    }
    if (map[r'Iteration'] != null) {
      _iteration = new RDIteration._internal(
          idFromRef(map[r'Iteration']['_ref']),
          map[r'Iteration'][r'_refObjectName']);
    }
    _planEstimate = map[r'PlanEstimate'];
    _expedite = map[r'Expedite'];
  }

  String get typeKey;

  String get typeName;

  @override
  String toString() {
    return "${super.toString()} - $formattedID";
  }
}

class RDDefect extends RDWorkItem {

  static const String RDTypeKey = r'defect';
  static const String RDTypeName = r'Defect';

  RDPriority _priority;
  RDSeverity _severity;
  RDState _state;
  String _resolution;

  RDDefect.fromMap(Map<String, dynamic> map) : super._internalFromMap(map) {
    _resolution = map[r'Resolution'];
    _state = RDState.parse(map[r'State']);
    _priority = RDPriority.parse(map[r'Priority']);
    _severity = RDSeverity.parse(map[r'Severity']);
  }

  String get resolution => _resolution;

  RDPriority get priority => _priority;

  RDSeverity get severity => _severity;

  @override
  String get ref => '/${RDTypeKey}/${ID}';

  @override
  String get typeKey => RDTypeKey;

  @override
  String get typeName => RDTypeName;

}

class RDHierarchicalRequirement extends RDWorkItem {

  static const String RDTypeKey = r'hierarchicalrequirement';
  static const String RDTypeName = r'HierarchicalRequirement';

  RDRisk _risk;
  bool _hasParent;
  int _predecessorsCount = 0;

  RDHierarchicalRequirement.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map) {
    _hasParent = map[r'HasParent'];
    _risk = RDRisk.parse(map[r'c_Risk']);
    _predecessorsCount = map[r'Predecessors'][r'Count'];
  }

  RDRisk get risk => _risk;

  bool get hasParent => _hasParent;

  int get predecessorsCount => _predecessorsCount;

  @override
  String get ref => '/${RDTypeKey}/${ID}';

  @override
  String get typeKey => RDTypeKey;

  @override
  String get typeName => RDTypeName;
}

class RDPortfolioItem extends RDWorkItem {

  static final INQUIRIES = new RDPortfolioItem._internal(
      95036827264, r'Inquiries', r'F45');

  static final OPERATIONS = new RDPortfolioItem._internal(
      110441207448, r'Operations', r'F48');

  static const String RDTypeKey = r'portfolioitem/feature';
  static const String RDTypeName = r'PortfolioItem';

  RDPortfolioItem._internal(int id, String name, String formattedID)
      : super.DTO(id, name, formattedID);

  RDPortfolioItem.fromMap(Map<String, dynamic> map)
      : super._internalFromMap(map);

  factory RDPortfolioItem.DTO(int id, String name, String formattedID) {
    if (id == INQUIRIES.ID) return INQUIRIES;
    return new RDPortfolioItem._internal(id, name, formattedID);
  }

  @override
  String get ref => '/${RDTypeKey}/${ID}';

  @override
  String get typeKey => RDTypeKey;

  @override
  String get typeName => RDTypeName;
}
