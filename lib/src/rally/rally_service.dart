import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular2/core.dart';
import 'package:scrum_tools/utils/cache.dart';
import 'package:scrum_tools/src/runtime_service.dart';

import 'rally_entities.dart';

@Injectable()
class RallyService {

  static const int _projectId = 55308115013;

  String _pathRoot;

  RegExp _defectRegExp = new RegExp(r'^DE[0-9][0-9][0-9][0-9]$');
  RegExp _hierarchicalRequirementRegExp = new RegExp(
      r'^US[0-9][0-9][0-9][0-9][0-9]$');

  Cache<int, RDIteration> _iterationsCache;
  Cache<String, RDUser> _usersCache;
  Cache<String, RDDefect> _defectsCache;
  Cache<String, RDHierarchicalRequirement> _hierarchicalRequirementCache;
  Cache<String, RDPortfolioItem> _portfolioItemCache;
  RDIteration _currentIteration;

  RallyService(RuntimeService runtimeService) {
    assert(() {
      return true;
    });

    _pathRoot =
    runtimeService.debugMode ? _pathRoot = 'http://localhost:3000/rd' : '/rd';

    _iterationsCache = new Cache<int, RDIteration>.ready(_iterationRetriever);
    _usersCache = new Cache<String, RDUser>.ready(_userRetriever);
    _defectsCache = new Cache<String, RDDefect>.ready(_defectRetriever);
    _hierarchicalRequirementCache =
    new Cache<String, RDHierarchicalRequirement>.ready(
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
  }

  Future<RDIteration> getIteration(int id) {
    return _iterationsCache.get(id);
  }

  Future<RDIteration> get currentIteration {
    if (_currentIteration == null) {
      Completer<RDIteration> completer = new Completer<RDIteration>();
      _genericIDRetriever('iteration', '(Project.ObjectID = ${_projectId}) AND ((StartDate <= today) AND (EndDate >= today))').then((int id) {
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

  Future<RDDefect> getDefect(String key) {
    return _defectsCache.get(key);
  }

  Future<RDHierarchicalRequirement> getHierarchicalRequirement(String key) {
    return _hierarchicalRequirementCache.get(key);
  }

  Future<RDPortfolioItem> getPortfolioItem(String key) {
    return _portfolioItemCache.get(key);
  }

  Future<RDIteration> _iterationRetriever(int key) {
    Completer<RDIteration> completer = new Completer<RDIteration>();
    HttpRequest.getString('$_pathRoot/iteration/$key').then((String json) {
      Map map = JSON.decode(json);
      RDIteration iteration = new RDIteration.fromMap(map['Iteration']);
      completer.complete(iteration);
    });
    return completer.future;
  }

  Future<RDUser> _userRetriever(String key) {
    Completer<RDUser> completer = new Completer<RDUser>();
    HttpRequest.getString('$_pathRoot/user/$key').then((String json) {
      Map map = JSON.decode(json);
      RDUser user = new RDUser.fromMap(map['User']);
      completer.complete(user);
    });
    return completer.future;
  }

  Future<int> _genericIDRetriever(String name, String query) {
    Completer<int> completer = new Completer<int>();
    HttpRequest.getString(
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

  Future<Map<String, dynamic>> _entityMapRetriever(String name, int id) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    HttpRequest.getString(
        '$_pathRoot/$name/$id').then((String json) {
      Map<String, dynamic> map = JSON.decode(json);
      completer.complete(map);
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDDefect> _defectRetriever(String key) {
    Completer<RDDefect> completer = new Completer<RDDefect>();
    _idRetrieverByKey('defect', key).then((int id) {
      _entityMapRetriever('defect', id).then((Map<String, dynamic> map) {
        RDDefect value = new RDDefect.fromMap(map['Defect']);
        completer.complete(value);
      }).catchError((error) {
        _handleError(completer, error);
      });
    }).catchError((error) {
      _handleError(completer, error);
    });
    return completer.future;
  }

  Future<RDHierarchicalRequirement> _hierarchicalRequirementRetriever(
      String key) {
    Completer<RDHierarchicalRequirement> completer = new Completer<
        RDHierarchicalRequirement>();
    _idRetrieverByKey('hierarchicalrequirement', key).then((int id) {
      _entityMapRetriever('hierarchicalrequirement', id).then((
          Map<String, dynamic> map) {
        Map<String, dynamic> sub = map['HierarchicalRequirement'];
        RDHierarchicalRequirement value = new RDHierarchicalRequirement.fromMap(
            sub);
        completer.complete(value);
      }).catchError((error) {
        _handleError(completer, error);
      });
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
    if (error is ProgressEvent) {
      ProgressEvent pe = error as ProgressEvent;
      if (pe.target is HttpRequest) {
        HttpRequest request = pe.target as HttpRequest;
        completer.completeError(
            "${request.status} - ${request.statusText} ::: ${request
                .responseUrl}");
        return;
      }
    }
    completer.completeError(error.toString());
  }

}