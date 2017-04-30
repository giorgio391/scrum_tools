import 'dart:async';
import 'dart:convert';

import 'package:scrum_tools/src/utils/cache.dart';
import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/rally/const.dart';
import 'rally_entities.dart';

RegExp _defectRegExp = new RegExp(r'^DE[0-9][0-9][0-9][0-9]$');
RegExp _hierarchicalRequirementRegExp = new RegExp(
    r'^US[0-9][0-9][0-9][0-9][0-9]$');
RegExp _3DRegExp = new RegExp(r'^[0-9][0-9][0-9]$');
RegExp _4DRegExp = new RegExp(r'^[0-9][0-9][0-9][0-9]$');
RegExp _5DRegExp = new RegExp(r'^[0-9][0-9][0-9][0-9][0-9]$');

class BasicRallyService {

  static const String _defect = RDDefect.RDTypeKey;
  static const String _us = RDHierarchicalRequirement.RDTypeKey;

  //static const int _qaDeployerID = 55504055635;

  static const String _limitDate = r'"2016-12-31T23:59:59.000Z"';

  static const String _devTeamPendingQuery = '(((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(ScheduleState%20<%20"Accepted"))%20AND%20(Iteration.StartDate%20<=%20nextweek))&pagesize=200&fetch=true';

  static const String _proDeploymentPendingQuery = '((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>%20${_limitDate}))%20AND%20(Tags.Name%20=%20"PRE"))%20AND%20(Tags.Name%20!=%20"PRO"))&pagesize=200&fetch=true';

  static const String _uat2preDeploymentPendingQuery = '((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>%20${_limitDate}))%20AND%20(Tags.Name%20=%20"UAT"))%20AND%20(Tags.Name%20!=%20"PRE"))&pagesize=200&fetch=true';

  static const String _uat2proDeploymentPendingQuery = '((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>%20${_limitDate}))%20AND%20(Tags.Name%20=%20"UAT"))%20AND%20(Tags.Name%20!=%20"PRO"))&pagesize=200&fetch=true';

  static const String _preDeploymentPendingQuery = '((((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>%20${_limitDate}))%20AND%20(ScheduleState%20>=%20"Completed"))%20AND%20(Tags.Name%20!=%20"PRE"))%20AND%20(Tags.Name%20!=%20"NOT%20TO%20DEPLOY"))%20AND%20(Expedite%20=%20true))&pagesize=200&fetch=true';

  static const String _uatDeploymentPendingQuery = '(((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>%20${_limitDate}))%20AND%20(ScheduleState%20>=%20"Completed"))%20AND%20(Tags.Name%20!=%20"UAT"))%20AND%20(Tags.Name%20!=%20"NOT%20TO%20DEPLOY"))&pagesize=200&fetch=true';

  static final String _defectIterationMissingQuery = '((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>=%20${_limitDate}))%20AND%20(Priority%20=%20"${RDPriority
      .MAX_PRIORITY.name.replaceAll(
      r' ', r'%20')}"))%20AND%20(Iteration%20=%20null))&pagesize=20&fetch=true';
  static final String _usIterationMissingQuery = '((((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(LastUpdateDate%20>=%20${_limitDate}))%20AND%20(Risk%20=%20"${RDRisk
      .MAX_RISK.name.replaceAll(
      r' ', r'%20')}"))%20AND%20(Iteration%20=%20null))&pagesize=20&fetch=true';

  int get defaultProjectID => gordonProjectId;

  String _pathRoot;

  Cache<int, RDIteration> _iterationsCache;
  Cache<String, RDUser> _usersCache;
  Cache<String, int> _workItemCodesCache;
  Cache<int, RDDefect> _defectsCache;
  Cache<int, RDHierarchicalRequirement> _hierarchicalRequirementCache;
  Cache<String, RDPortfolioItem> _portfolioItemCache;
  RDIteration _currentIteration;
  ScrumHttpClient _httpClient;

  BasicRallyService(this._httpClient,
      {String pathRoot: r'', bool evictCache: false}) {
    _pathRoot = pathRoot;

    Function evictFactory = evictCache ?
        () => new CachedTimeoutEvict() : () => noOpsCacheListener;

    _iterationsCache = new Cache<int, RDIteration>.ready(
        _iterationRetriever, listener: evictFactory());
    _usersCache = new Cache<String, RDUser>.ready(
        _userRetriever, listener: evictFactory());
    _workItemCodesCache = new Cache<String, int>.ready(
        getWorkItemID, listener: evictFactory());
    _defectsCache = new Cache<int, RDDefect>.ready(
        _defectRetriever, listener: evictFactory());
    _hierarchicalRequirementCache =
    new Cache<int, RDHierarchicalRequirement>.ready(
        _hierarchicalRequirementRetriever, listener: evictFactory());
    _portfolioItemCache =
    new Cache<String, RDPortfolioItem>.ready(
        _portfolioItemRetriever, listener: evictFactory());
  }

  String _byIterationNameQuery(String iterationName) =>
      '((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(Iteration.Name%20=%20"${iterationName
          .replaceAll(r' ', '%20')}"))&pagesize=250&fetch=true';

  String _pendingByIterationNameQuery(String iterationName) =>
      '(((Project.ObjectID%20=%20${gordonProjectId})%20AND%20(ScheduleState%20<%20"Accepted"))%20AND%20(Iteration.Name%20=%20"${iterationName
          .replaceAll(r' ', '%20')}"))&pagesize=200&fetch=true';

  Future<RDIteration> _iterationRetriever(int key) {
    Completer<RDIteration> completer = new Completer<RDIteration>();
    _httpClient.getString('$_pathRoot/iteration/$key').then((String json) {
      Map map = JSON.decode(json);
      RDIteration iteration = new RDIteration.fromMap(map[r'Iteration']);
      completer.complete(iteration);
    });
    return completer.future;
  }

  Future<RDUser> _userRetriever(String key) {
    Completer<RDUser> completer = new Completer<RDUser>();
    _httpClient.getString('$_pathRoot/user/$key').then((String json) {
      Map map = JSON.decode(json);
      RDUser user = new RDUser.fromMap(map[r'User']);
      completer.complete(user);
    });
    return completer.future;
  }

  Future<int> _genericIDRetriever(String name, String query) {
    Completer<int> completer = new Completer<int>();
    _httpClient.getString(
        '$_pathRoot/${name}?query=(${query.replaceAll(
            r" ", r"%20")})&fetch=ObjectID,FormattedID')
        .then((String json) {
      Map map = JSON.decode(json);
      if (map[r'QueryResult'][r'TotalResultCount'] > 0) {
        int id = map[r'QueryResult'][r'Results'][0][r'ObjectID'];
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
    _entityMapRetriever(_defect, id).then((Map<String, dynamic> map) {
      RDDefect value = new RDDefect.fromMap(map[r'Defect']);
      completer.complete(value);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDHierarchicalRequirement> _hierarchicalRequirementRetriever(int id) {
    Completer<RDHierarchicalRequirement> completer = new Completer<
        RDHierarchicalRequirement>();
    _entityMapRetriever(_us, id).then((Map<String, dynamic> map) {
      Map<String, dynamic> sub = map[r'HierarchicalRequirement'];
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
    _idRetrieverByKey(r'portfolioitem/feature', key).then((int id) {
      _entityMapRetriever(r'portfolioitem/feature', id).then((
          Map<String, dynamic> map) {
        RDPortfolioItem value = new RDPortfolioItem.fromMap(map[r'Feature']);
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
    completer.completeError(_httpClient.handleError(error));
  }

  Future<List<RDWorkItem>> _queryWorkItems(String query, [bool fresh = false]) {
    Completer<List<RDWorkItem>> completer = new Completer<List<RDWorkItem>>();
    Future<List<RDWorkItem>> defectsFuture = _queryWorkItemsByType(
        _defect, query, fresh);
    Future<List<RDWorkItem>> usFuture = _queryWorkItemsByType(
        _us, query, fresh);
    Future.wait([defectsFuture, usFuture]).then((List<List<RDWorkItem>> list) {
      List<RDWorkItem> compiledList = new List<RDWorkItem>();
      list.forEach((Iterable<RDWorkItem> ite) => compiledList.addAll(ite));
      completer.complete(compiledList);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<List<RDWorkItem>> _queryWorkItemsByType(String typeName,
      String query, [bool fresh = false]) {
    WiBuilder wiBuilder = typeName == _defect ? _defectBuilder : _usBuilder;
    Completer <List<RDWorkItem>> completer = new Completer<List<RDWorkItem>>();
    String url = '$_pathRoot'
        '${fresh ? r'/fresh/' : r'/'}'
        '${typeName}?query=${query}';
    _httpClient.getString(url).then((String json) {
      Map map = JSON.decode(json);
      List<RDWorkItem> list = [];
      if (map[r'QueryResult'][r'TotalResultCount'] > 0) {
        map[r'QueryResult'][r'Results'].forEach((Map<String, dynamic> wiMap) {
          RDWorkItem wi = wiBuilder(wiMap);
          list.add(wi);
        });
      }
      completer.complete(list);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  RDWorkItem _defectBuilder(Map<String, dynamic> map) =>
      new RDDefect.fromMap(map);

  RDWorkItem _usBuilder(Map<String, dynamic> map) =>
      new RDHierarchicalRequirement.fromMap(map);

  Future<Iterable<RDWorkItem>> _queryWorkItemsSortByCode(String query,
      [bool fresh = false]) {
    Completer<Iterable<RDWorkItem>> completer = new Completer<
        Iterable<RDWorkItem>>();
    _queryWorkItems(query, fresh).then((List<RDWorkItem> list) {
      list.sort(FormattedIDComparator);
      completer.complete(list);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<List<RDWorkItem>> _queryWorkItemsSortPrioritization(String query,
      [bool fresh = false]) {
    Completer<List<RDWorkItem>> completer = new Completer<List<RDWorkItem>>();
    _queryWorkItems(query, fresh).then((List<RDWorkItem> list) {
      list.sort(new PrioritizationComparator().compare);
      completer.complete(list);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  void close({bool force: false}) {
    _httpClient.close(force: force);
  }

  Future<int> getWorkItemID(String key) {
    Completer<int> completer = new Completer<int>();
    if (key != null && (key.startsWith(r'US') || key.startsWith(r'DE'))) {
      _idRetrieverByKey(key.startsWith(r'US') ? _us : _defect, key).
      then((int id) {
        completer.complete(id);
      }).catchError((error) {
        _handleError(completer, error);
      });
    } else {
      completer.completeError('The key [${key == null
          ? r'null'
          : key}] is not valid for a work item.');
    }
    return completer.future;
  }

  Stream<RDWorkItem> getWorkItems(Iterable<String> wiCodes) {
    StreamController<RDWorkItem> streamController = new StreamController<
        RDWorkItem>();
    if (!hasValue(wiCodes)) {
      streamController.addError(r'A list of work item codes must be provided!');
      streamController.close();
    } else {
      Set<String> toRetrieve = new Set.from(wiCodes);
      int counter = toRetrieve.length;
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
    }
    return streamController.stream;
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
      if (key.startsWith(r'DE'))
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
      _genericIDRetriever(r'iteration',
          '(Project.ObjectID = ${gordonProjectId}) AND ((StartDate <= today) AND (EndDate >= today))')
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
      ..completeError(r"Null key provided!")).future;
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

  Future<List<RDHierarchicalRequirement>> getPredecessors(
      RDHierarchicalRequirement us) {
    if (us == null || us.predecessorsCount < 1) {
      return new Future.value(null);
    }

    Completer<List<RDHierarchicalRequirement>> completer = new Completer<
        List<RDHierarchicalRequirement>>();
    _httpClient.getString(
        '${_pathRoot}/HierarchicalRequirement/${us
            .objectID}/Predecessors?fetch=true').then((String json) {
      Map<String, dynamic> map = JSON.decode(json);
      if (map[r'QueryResult'][r'TotalResultCount'] > 0) {
        List<Map<String, dynamic>> list = map[r'QueryResult'][r'Results'];
        List<RDHierarchicalRequirement> resultList = [];
        list.forEach((Map<String, dynamic> map) {
          RDHierarchicalRequirement pUS = new RDHierarchicalRequirement.fromMap(
              map);
          resultList.add(pUS);
        });
        completer.complete(resultList);
      } else {
        completer.complete(null);
      }
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<List<RDRevision>> getRevisions(RDWorkItem wi) {
    if (wi == null) {
      return null;
    }
    Completer<List<RDRevision>> completer = new Completer<List<RDRevision>>();
    _httpClient.getString(
        '${_pathRoot}/RevisionHistory/${wi.revisionHistoryID}/Revisions').then((
        String json) {
      List<Map<String, dynamic>> list = JSON.decode(json);
      List<RDRevision> resultList = [];
      list.forEach((Map<String, dynamic> map) {
        RDRevision revision = new RDRevision.fromMap(map);
        resultList.add(revision);
      });
      resultList.sort((RDRevision r1, RDRevision r2) {
        return r1.revisionNumber.compareTo(r2.revisionNumber);
      });
      completer.complete(resultList);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDPortfolioItem> getPortfolioItem(String key) {
    return _portfolioItemCache.get(key);
  }

  Future<Iterable<RDWorkItem>> getDevTeamPendingInIteration(
      String iterationName) {
    String query = _pendingByIterationNameQuery(iterationName);
    return _queryWorkItemsSortPrioritization(query, true);
  }

  Future<Iterable<RDWorkItem>> getMissedIteration() {
    Completer<List<RDWorkItem>> completer = new Completer<List<RDWorkItem>>();
    Future<List<RDWorkItem>> defectsFuture = _queryWorkItemsByType(
        _defect, _defectIterationMissingQuery, true);
    Future<List<RDWorkItem>> usFuture = _queryWorkItemsByType(
        _us, _usIterationMissingQuery, true);
    Future.wait([defectsFuture, usFuture]).then((List<List<RDWorkItem>> list) {
      List<RDWorkItem> compiledList = new List<RDWorkItem>();
      list.forEach((Iterable<RDWorkItem> ite) => compiledList.addAll(ite));
      if (hasValue(compiledList)) {
        compiledList.sort(FormattedIDComparator);
        completer.complete(compiledList);
      } else {
        completer.complete(null);
      }
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<Iterable<RDWorkItem>> getByIteration(String iterationName) =>
      _queryWorkItemsSortByCode(_byIterationNameQuery(iterationName), true);

  Future<Iterable<RDWorkItem>> getDevTeamPending() =>
      _queryWorkItemsSortPrioritization(_devTeamPendingQuery, true);

  Future<Iterable<RDWorkItem>> getPRODeploymentPending() =>
      _queryWorkItemsSortByCode(_proDeploymentPendingQuery, true);

  Future<Iterable<RDWorkItem>> getPREDeploymentPending() =>
      _queryWorkItemsSortByCode(_preDeploymentPendingQuery, true);

  Future<Iterable<RDWorkItem>> getUATDeploymentPending() =>
      _queryWorkItemsSortByCode(_uatDeploymentPendingQuery, true);

  Future<Iterable<RDWorkItem>> getUAT2PREDeploymentPending() =>
      _queryWorkItemsSortByCode(_uat2preDeploymentPendingQuery, true);

  Future<Iterable<RDWorkItem>> getUAT2PRODeploymentPending() =>
      _queryWorkItemsSortByCode(_uat2proDeploymentPendingQuery, true);

  Future<Map<String, dynamic>> _operation(String operation,
      Map<String, dynamic> data) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    String json = JSON.encode(data);
    _httpClient.post(operation, json).then((Map<String, dynamic> result) {
      if (!hasValue(result))
        completer.completeError(
            r'Empty result when a map was expected!');
      else if (result.length > 1)
        completer.completeError(
            r'One entry value map expected!');
      else {
        result.forEach((String key, dynamic data) {
          Map<String, dynamic> map = data;
          if (hasValue(map[r'Errors'])) {
            completer.completeError({r'Rally API errors': map[r'Errors']});
          } else {
            Map<String, dynamic> objectMap = map[r'Object'];
            completer.complete(objectMap);
          }
        });
      }
    });
    return completer.future;
  }

  Future<RDMilestone> createMilestone(String name, {DateTime targetDate,
    Iterable<RDWorkItem> artifacts, String notes}) {
    DateTime date = targetDate == null ? new DateTime.now() : targetDate;
    Map<String, dynamic> data = {
      r'Milestone': {
        r'TargetProject': {r'_ref': '/project/${gordonProjectId}'},
        r'Name': name,
        r'TargetDate': '${date.toIso8601String()}'
      }
    };
    if (hasValue(artifacts)) {
      List<Map<String, String>> refs = [];
      artifacts.forEach((RDWorkItem workItem) {
        refs.add({r'_ref': workItem.ref});
      });
      data[r'Milestone'][r'Artifacts'] = refs;
    }
    if (hasValue(notes)) {
      data[r'Milestone'][r'Notes'] = notes;
    }
    Completer<RDMilestone> completer = new Completer<RDMilestone>();
    _operation(r'/milestone/create', data).then((Map<String, dynamic> map) {
      completer.complete(new RDMilestone.fromMap(map));
    });
    return completer.future;
  }

  Future<RDWorkItem> addTag(RDWorkItem workItem, RDTag tag) {
    Completer<RDWorkItem> completer = new Completer<RDWorkItem>();
    if (workItem == null || tag == null) {
      completer.completeError(r'A work item and a tag must be provided!');
    } else {
      if (hasValue(workItem.tags) && workItem.tags.contains(tag)) {
        completer.complete(workItem);
      } else {
        List<RDTag> tags = hasValue(workItem.tags) ? new List<RDTag>.from(
            workItem.tags) : new List<RDTag>();
        tags.add(tag);
        tags.sort();
        List<Map<String, String>> list = [];
        tags.forEach((RDTag t) {
          list.add({'_ref': t.ref});
        });
        Map data = {
          workItem.typeName: {
            r'Tags': list
          }
        };
        _operation('/${workItem.typeKey}/${workItem.ID}', data).then((
            Map<String, dynamic> map) {
          completer.complete(workItem is RDDefect ? new RDDefect.fromMap(map) :
          workItem is RDHierarchicalRequirement ? new RDHierarchicalRequirement
              .fromMap(map) :
          new RDPortfolioItem.fromMap(map));
        });
      }
    }
    return completer.future;
  }

  Stream<RDWorkItem> addTagToWorkItems(Iterable<RDWorkItem> workItems,
      RDTag tag) {
    StreamController<RDWorkItem> streamController = new StreamController<
        RDWorkItem>();
    if (!hasValue(workItems) || tag == null) {
      streamController.addError(
          r'A list with work items and a tag must be supplied!');
      streamController.close();
    } else {
      Set<RDWorkItem> toTag = new Set.from(workItems);
      int counter = toTag.length;
      StreamController<RDWorkItem> streamController = new StreamController<
          RDWorkItem>();
      toTag.forEach((RDWorkItem workItem) {
        addTag(workItem, tag).then((RDWorkItem workItem) {
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
}

bool validWorkItemCodePattern(String code) {
  if (hasValue(code) && hasValue(code.trim())) {
    return _defectRegExp.hasMatch(code) ||
        _hierarchicalRequirementRegExp.hasMatch(code);
  }
  return false;
}

String normalizeWorkItemCodeFormat(String ref) {
  if (hasValue(ref)) {
    String code = ref.trim().toUpperCase();
    if (_defectRegExp.hasMatch(code) ||
        _hierarchicalRequirementRegExp.hasMatch(code)) {
      return code;
    } else if (_3DRegExp.hasMatch(code)) {
      return "US19${code}";
    } else if (_4DRegExp.hasMatch(code)) {
      return "DE${code}";
    } else if (_5DRegExp.hasMatch(code)) {
      return "US${code}";
    }
  }
  return null;
}


int FormattedIDComparator(RDWorkItem workItem1, RDWorkItem workItem2) {
  if (workItem1 == null && workItem2 == null) return 0;
  if (workItem1 != null && workItem2 == null) return -1;
  if (workItem1 == null && workItem2 != null) return 1;
  if (workItem1.formattedID == null && workItem2.formattedID == null) return 0;
  if (workItem1.formattedID != null && workItem2.formattedID == null) return -1;
  if (workItem1.formattedID == null && workItem2.formattedID != null) return 1;
  return workItem1.formattedID.compareTo(workItem2.formattedID);
}

typedef RDWorkItem WiBuilder (Map<String, dynamic> map);

int compareWIByFormattedID(RDWorkItem wi1, RDWorkItem wi2) {
  if (wi1 == null && wi2 == null) return 0;
  if (wi1 != null && wi2 == null) return -1;
  if (wi1 == null && wi2 != null) return 1;
  return wi1.formattedID.compareTo(wi2.formattedID);
}

class PrioritizationComparator {

  RDIteration _currentIteration;

  PrioritizationComparator([this._currentIteration]);

  int compare(RDWorkItem wi1, RDWorkItem wi2) {
    if (wi1 == null && wi2 == null) return 0;
    if (wi1 != null && wi2 == null) return -1;
    if (wi1 == null && wi2 != null) return 1;
    if (wi1.ID == wi2.ID) return 0;

    RDIteration iteration1 = wi1.iteration;
    RDIteration iteration2 = wi2.iteration;

    if (iteration1 != null && iteration2 == null) return -1;
    if (iteration1 == null && iteration2 != null) return 1;

    if (_currentIteration != null && iteration1 != null && iteration2 != null) {
      if (iteration1 <= _currentIteration && iteration2 > _currentIteration)
        return -1;
      if (iteration1 > _currentIteration && iteration2 <= _currentIteration)
        return 1;
    }

    int priorityComparison = _compareByPriorityRisk(wi1, wi2);

    if (priorityComparison != 0) return priorityComparison;

    RDSeverity severity1 = inferSeverity(wi1);
    RDSeverity severity2 = inferSeverity(wi2);
    if (severity1 != severity2) return severity1.compareTo(severity2);

    if (iteration1 != null && iteration2 == null) return -1;
    if (iteration1 == null && iteration2 != null) return 1;
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

    RDPriority p1 = inferWIPriority(wi1);
    RDPriority p2 = inferWIPriority(wi2);

    if ((wi1.scheduleState == RDScheduleState.IN_PROGRESS ||
        wi2.scheduleState == RDScheduleState.IN_PROGRESS) &&
        wi1.scheduleState != wi2.scheduleState &&
        p1 != RDPriority.MAX_PRIORITY &&
        p2 != RDPriority.MAX_PRIORITY) {
      return wi1.scheduleState == RDScheduleState.IN_PROGRESS ? -1 : 1;
    }

    return p1.compareTo(p2);
  }

}

bool hasMaxPrioritization(RDWorkItem workItem) =>
    (workItem is RDDefect && workItem.priority == RDPriority.MAX_PRIORITY) ||
        (workItem is RDHierarchicalRequirement &&
            workItem.risk == RDRisk.MAX_RISK);

RDPriority inferWIPriority(RDWorkItem workItem) {
  if (workItem is RDDefect) {
    return workItem.priority;
  }
  if (workItem is RDHierarchicalRequirement) {
    return workItem.risk.equivalentPriority;
  }
  return null;
}

RDSeverity inferSeverity(RDWorkItem workItem) =>
    workItem is RDDefect ? workItem.severity :
    workItem is RDHierarchicalRequirement ? RDSeverity.MINOR_PROBLEM
        : null;

