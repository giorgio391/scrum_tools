import 'dart:async';
import 'dart:convert';

import 'package:scrum_tools/src/utils/cache.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'rally_entities.dart';

class BasicRallyService {

  static const int _projectId = 55308115013;

  int get defaultProjectID => _projectId;

  String _pathRoot;

  RegExp _defectRegExp = new RegExp(r'^DE[0-9][0-9][0-9][0-9]$');
  RegExp _hierarchicalRequirementRegExp = new RegExp(
      r'^US[0-9][0-9][0-9][0-9][0-9]$');

  Cache<int, RDIteration> _iterationsCache;
  Cache<String, RDUser> _usersCache;
  Cache<String, int> _workItemCodesCache;
  Cache<int, RDDefect> _defectsCache;
  Cache<int, RDHierarchicalRequirement> _hierarchicalRequirementCache;
  Cache<String, RDPortfolioItem> _portfolioItemCache;
  RDIteration _currentIteration;
  ScrumHttpClient _httpClient;

  BasicRallyService(this._httpClient, [this._pathRoot = '']) {
    _iterationsCache = new Cache<int, RDIteration>.ready(_iterationRetriever);
    _usersCache = new Cache<String, RDUser>.ready(_userRetriever);
    _workItemCodesCache = new Cache<String, int>.ready(getWorkItemID);
    _defectsCache = new Cache<int, RDDefect>.ready(_defectRetriever);
    _hierarchicalRequirementCache =
    new Cache<int, RDHierarchicalRequirement>.ready(
        _hierarchicalRequirementRetriever);
    _portfolioItemCache =
    new Cache<String, RDPortfolioItem>.ready(_portfolioItemRetriever);
  }

  void clearAllCaches() {
    _iterationsCache.clearCache();
    _usersCache.clearCache();
    _defectsCache.clearCache();
    _hierarchicalRequirementCache.clearCache();
    _portfolioItemCache.clearCache();
    _currentIteration = null;
    _workItemCodesCache.clearCache();
  }

  Future clearWorkItemCache(String key) {
    Completer completer = new Completer();
    getWorkItemID(key).then((int id) {
      if (key.startsWith('DE'))
        _defectsCache.clearItem(id);
      else
        _hierarchicalRequirementCache.clearItem(id);
      completer.complete();
    }).catchError((error) {
      completer.complete(error);
    });
    return completer.future;
  }

  Future<RDIteration> getIteration(int id) {
    return _iterationsCache.get(id);
  }

  Future<RDIteration> get currentIteration {
    if (_currentIteration == null) {
      Completer<RDIteration> completer = new Completer<RDIteration>();
      _genericIDRetriever('iteration',
          '(Project.ObjectID = ${_projectId}) AND ((StartDate <= today) AND (EndDate >= today))')
          .then((int id) {
        getIteration(id).then((RDIteration iteration) {
          _currentIteration = iteration;
          completer.complete(iteration);
        }).catchError((error) {
          completer.completeError(error);
        });
      }).catchError((error) {
        completer.completeError(error);
      });
      return completer.future;
    }
    return new Future.value(_currentIteration);
  }

  Future<RDUser> getUser(String key) {
    return _usersCache.get(key);
  }

  Future<RDWorkItem> getWorkItem(String key) {
    if (key == null) return (new Completer()
      ..completeError("Null key provided!")).future;
    if (_defectRegExp.hasMatch(key)) {
      return getDefect(key);
    }
    if (_hierarchicalRequirementRegExp.hasMatch(key)) {
      return getHierarchicalRequirement(key);
    }
    return (new Completer()
      ..completeError("Key [$key] does not match a valid pattern!")).future;
  }

  RDWorkItem getCachedWorkItem(String key) {
    if (key != null) {
      int id = _workItemCodesCache.getCached(key);
      if (id != null) {
        if (_defectRegExp.hasMatch(key)) {
          return _defectsCache.getCached(id);
        }
        if (_hierarchicalRequirementRegExp.hasMatch(key)) {
          return _hierarchicalRequirementCache.getCached(id);
        }
      }
    }
    return null;
  }

  Future<RDDefect> getDefect(String key) {
    Completer<RDDefect> completer = new Completer<RDDefect>();
    _workItemCodesCache.get(key).then((int id) {
      getDefectById(id).then((RDDefect wi) {
        completer.complete(wi);
      }).catchError((error) {
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<RDDefect> getDefectById(int id) {
    return _defectsCache.get(id);
  }

  Future<RDHierarchicalRequirement> getHierarchicalRequirement(String key) {
    Completer<RDHierarchicalRequirement> completer = new Completer<
        RDHierarchicalRequirement>();
    _workItemCodesCache.get(key).then((int id) {
      getHierarchicalRequirementById(id).then((RDHierarchicalRequirement wi) {
        completer.complete(wi);
      }).catchError((error) {
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<RDHierarchicalRequirement> getHierarchicalRequirementById(int id) {
    return _hierarchicalRequirementCache.get(id);
  }

  Future<RDPortfolioItem> getPortfolioItem(String key) {
    return _portfolioItemCache.get(key);
  }

  Future<RDIteration> _iterationRetriever(int key) {
    Completer<RDIteration> completer = new Completer<RDIteration>();
    _httpClient.getString('$_pathRoot/iteration/$key').then((String json) {
      Map map = JSON.decode(json);
      RDIteration iteration = new RDIteration.fromMap(map['Iteration']);
      completer.complete(iteration);
    });
    return completer.future;
  }

  Future<RDUser> _userRetriever(String key) {
    Completer<RDUser> completer = new Completer<RDUser>();
    _httpClient.getString('$_pathRoot/user/$key').then((String json) {
      Map map = JSON.decode(json);
      RDUser user = new RDUser.fromMap(map['User']);
      completer.complete(user);
    });
    return completer.future;
  }

  Future<int> _genericIDRetriever(String name, String query) {
    Completer<int> completer = new Completer<int>();
    _httpClient.getString(
        '$_pathRoot/${name}?query=(${query.replaceAll(
            " ", "%20")})&fetch=ObjectID,FormattedID')
        .then((String json) {
      Map map = JSON.decode(json);
      if (map['QueryResult']['TotalResultCount'] > 0) {
        int id = map['QueryResult']['Results'][0]['ObjectID'];
        completer.complete(id);
      } else {
        completer.completeError('Error when querying [$name] for [$query]!');
      }
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<int> _idRetrieverByKey(String name, String key) {
    return _genericIDRetriever(name, "FormattedID%20=%20${key}");
  }

  Future<int> getWorkItemID(String key) {
    Completer<int> completer = new Completer<int>();
    if (key != null && (key.startsWith('US') || key.startsWith('DE'))) {
      _idRetrieverByKey(
          key.startsWith('US') ? 'hierarchicalrequirement' : 'defect', key)
          .then((int id) {
        completer.complete(id);
      }).catchError((error) {
        _handleError(completer, error);
      });
    } else {
      completer.completeError('The key [${key == null
          ? 'null'
          : key}] is not valid for a work item.');
    }
    return completer.future;
  }

  Future<Map<String, dynamic>> _entityMapRetriever(String name, int id) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    _httpClient.getString(
        '$_pathRoot/$name/$id').then((String json) {
      Map<String, dynamic> map = JSON.decode(json);
      completer.complete(map);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDDefect> _defectRetriever(int id) {
    Completer<RDDefect> completer = new Completer<RDDefect>();
    _entityMapRetriever('defect', id).then((Map<String, dynamic> map) {
      RDDefect value = new RDDefect.fromMap(map['Defect']);
      completer.complete(value);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDHierarchicalRequirement> _hierarchicalRequirementRetriever(int id) {
    Completer<RDHierarchicalRequirement> completer = new Completer<
        RDHierarchicalRequirement>();
    _entityMapRetriever('hierarchicalrequirement', id).then((
        Map<String, dynamic> map) {
      Map<String, dynamic> sub = map['HierarchicalRequirement'];
      RDHierarchicalRequirement value = new RDHierarchicalRequirement.fromMap(
          sub);
      completer.complete(value);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDPortfolioItem> _portfolioItemRetriever(String key) {
    Completer<RDPortfolioItem> completer = new Completer<RDPortfolioItem>();
    _idRetrieverByKey('portfolioitem/feature', key).then((int id) {
      _entityMapRetriever('portfolioitem/feature', id).then((
          Map<String, dynamic> map) {
        RDPortfolioItem value = new RDPortfolioItem.fromMap(map['Feature']);
        completer.complete(value);
      }).catchError((error) {
        _handleError(completer, error);
      });
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  void _handleError(Completer completer, error) {
    _httpClient.handleError(completer, error);
  }

  void close({bool force: false}) {
    _httpClient.close(force: force);
  }

  Stream<RDWorkItem> getWorkItems(Iterable<String> wiCodes) {
    if (!hasValue(wiCodes)) return null;
    Set<String> toRetrieve = new Set.from(wiCodes);
    int counter = toRetrieve.length;
    StreamController<RDWorkItem> streamController = new StreamController<
        RDWorkItem>();
    toRetrieve.forEach((String wiCode) {
      getWorkItem(wiCode).then((RDWorkItem workItem) {
        streamController.add(workItem);
      }).catchError((error) {
        streamController.addError(error);
      }).whenComplete(() {
        counter--;
        if (counter < 1) streamController.close();
      });
    });
    return streamController.stream;
  }
}

int compareWIByFormattedID(RDWorkItem wi1, RDWorkItem wi2) {
  if (wi1 == null && wi2 == null) return 0;
  if (wi1 != null && wi2 == null) return -1;
  if (wi1 == null && wi2 != null) return 1;
  return wi1.formattedID.compareTo(wi2.formattedID);
}

int compareWIByPrioritization(RDWorkItem wi1, RDWorkItem wi2) {
  if (wi1 == null && wi2 == null) return 0;
  if (wi1 != null && wi2 == null) return -1;
  if (wi1 == null && wi2 != null) return 1;
  if (wi1.ID == wi2.ID) return 0;

  int comparison = _compareByPriorityRisk(wi1, wi2);

  if (comparison != 0) return comparison;

  RDSeverity severity1 = _inferSeverity(wi1);
  RDSeverity severity2 = _inferSeverity(wi2);
  if (severity1 != severity2) return severity1.compareTo(severity2);

  RDIteration iteration1 = wi1.iteration;
  RDIteration iteration2 = wi2.iteration;
  if (iteration1 != iteration2) return iteration1.compareTo(iteration2);

  String rank1 = wi1.rank;
  String rank2 = wi2.rank;
  if (rank1 != rank2) return rank1.compareTo(rank2);

  if (wi1.expedite != wi2.expedite) return wi1.expedite ? -1 : 1;

  if (wi1 is RDDefect && !(wi2 is RDDefect)) return -1;
  if (!(wi1 is RDDefect) && wi2 is RDDefect) return 1;

  if (wi1.planEstimate != null && wi2.planEstimate == null) return -1;
  if (wi1.planEstimate == null && wi2.planEstimate != null) return 1;
  if (wi1.planEstimate != null && wi2.planEstimate != null) {
    return wi1.planEstimate > wi2.planEstimate ? -1 :
    wi1.planEstimate < wi2.planEstimate ? 1 : 0;
  }

  return 0;
}

int _compareByPriorityRisk(RDWorkItem wi1, RDWorkItem wi2) {
  if (wi1 == null && wi2 == null) return 0;
  if (wi1 != null && wi2 == null) return -1;
  if (wi1 == null && wi2 != null) return 1;

  RDPriority p1 = _inferWIPriority(wi1);
  RDPriority p2 = _inferWIPriority(wi2);

  if ((wi1.scheduleState == RDScheduleState.IN_PROGRESS ||
      wi2.scheduleState == RDScheduleState.IN_PROGRESS) &&
      wi1.scheduleState != wi2.scheduleState && p1 != RDPriority.MAX_PRIORITY &&
      p2 != RDPriority.MAX_PRIORITY) {
    return wi1.scheduleState == RDScheduleState.IN_PROGRESS ? -1 : 1;
  }

  return p1.compareTo(p2);
}

RDPriority _inferWIPriority(RDWorkItem workItem) {
  if (workItem is RDDefect) {
    return workItem.priority;
  }
  if (workItem is RDHierarchicalRequirement) {
    return workItem.risk.equivalentPriority;
  }
  return null;
}

RDSeverity _inferSeverity(RDWorkItem workItem) =>
    workItem is RDDefect ? workItem.severity : RDSeverity.MINOR_PROBLEM;


