import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:angular2/core.dart';
import 'package:scrum_tools/utils/cache.dart';

import 'rally_entities.dart';

@Injectable()
class RallyService {

  String _pathRoot = '/rd';
  //String _pathRoot = 'http://localhost:3000/rd';

  RegExp _defectRegExp = new RegExp(r'^DE[0-9][0-9][0-9][0-9]$');
  RegExp _hierarchicalRequirementRegExp = new RegExp(
      r'^US[0-9][0-9][0-9][0-9][0-9]$');

  Cache<String, RDUser> _usersCache;
  Cache<String, RDDefect> _defectsCache;
  Cache<String, RDHierarchicalRequirement> _hierarchicalRequirementCache;
  Cache<String, RDPortfolioItem> _portfolioItemCache;

  RallyService() {
    _usersCache = new Cache<String, RDUser>.ready(_userRetriever);
    _defectsCache = new Cache<String, RDDefect>.ready(_defectRetriever);
    _hierarchicalRequirementCache =
    new Cache<String, RDHierarchicalRequirement>.ready(
        _hierarchicalRequirementRetriever);
    _portfolioItemCache =
    new Cache<String, RDPortfolioItem>.ready(_portfolioItemRetriever);
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

  Future<RDUser> _userRetriever(String key) {
    Completer<RDUser> completer = new Completer<RDUser>();
    HttpRequest.getString('$_pathRoot/user/$key').then((String json) {
      Map map = JSON.decode(json);
      RDUser user = new RDUser.fromMap(map['User']);
      completer.complete(user);
    });
    return completer.future;
  }

  Future<int> _genericIDRetriever(String name, String key) {
    Completer<int> completer = new Completer<int>();
    HttpRequest.getString(
        '$_pathRoot/${name}?query=(FormattedID%20=%20${key})&fetch=ObjectID,FormattedID')
        .then((String json) {
      Map map = JSON.decode(json);
      if (map['QueryResult']['TotalResultCount'] > 0) {
        int id = map['QueryResult']['Results'][0]['ObjectID'];
        completer.complete(id);
      } else {
        completer.completeError('Key [$key] not found for [$name]!');
      }
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> _entityMapRetriever(String name, int id) {
    Completer<Map<String, dynamic>> completer = new Completer<
        Map<String, dynamic>>();
    HttpRequest.getString(
        '$_pathRoot/$name/$id').then((String json) {
      Map<String, dynamic> map = JSON.decode(json);
      completer.complete(map);
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<RDDefect> _defectRetriever(String key) {
    Completer<RDDefect> completer = new Completer<RDDefect>();
    _genericIDRetriever('defect', key).then((int id) {
      _entityMapRetriever('defect', id).then((Map<String, dynamic> map) {
        RDDefect value = new RDDefect.fromMap(map['Defect']);
        completer.complete(value);
      }).catchError((error) {
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<RDHierarchicalRequirement> _hierarchicalRequirementRetriever(
      String key) {
    Completer<RDHierarchicalRequirement> completer = new Completer<RDHierarchicalRequirement>();
    _genericIDRetriever('hierarchicalrequirement', key).then((int id) {
      _entityMapRetriever('hierarchicalrequirement', id).then((Map<String, dynamic> map) {
        Map<String, dynamic> sub = map['HierarchicalRequirement'];
        RDHierarchicalRequirement value = new RDHierarchicalRequirement.fromMap(sub);
        completer.complete(value);
      }).catchError((error) {
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

  Future<RDPortfolioItem> _portfolioItemRetriever(String key) {
    Completer<RDPortfolioItem> completer = new Completer<RDPortfolioItem>();
    _genericIDRetriever('portfolioitem/feature', key).then((int id) {
      _entityMapRetriever('portfolioitem/feature', id).then((Map<String, dynamic> map) {
        RDPortfolioItem value = new RDPortfolioItem.fromMap(map['Feature']);
        completer.complete(value);
      }).catchError((error) {
        completer.completeError(error);
      });
    }).catchError((error) {
      completer.completeError(error);
    });
    return completer.future;
  }

}