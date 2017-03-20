import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:scrum_tools/src/utils/cache.dart';

typedef Future<Map<String, dynamic>> JSONFetcher(Uri uri);

class RallydevService {

  static const String _baseUrl = 'https://rally1.rallydev.com/slm/webservice/v2.0';

  static final Uri _baseUri = Uri.parse(_baseUrl);

  static final HttpClientBasicCredentials _credentials = new
  HttpClientBasicCredentials('mruiz1@emergya.com', 'EmergyaG0rd0n');

  HttpClient _httpClient;

  Users _users;

  Users get users => _users;

  void initialize() {
    _httpClient = new HttpClient();
    _httpClient.addCredentials(_baseUri, 'Rally ALM', _credentials);
    _users = new Users._internal(_fetch);
  }

  Future<Map<String, dynamic>> _fetch(Uri uri) {
    Completer <Map<String, dynamic>> completer =
    new Completer <Map<String, dynamic>>();
    _httpClient.getUrl(uri).then((HttpClientRequest request) {
      request.close().then((HttpClientResponse response) {
        StringBuffer sb = new StringBuffer();
        response.transform(UTF8.decoder).listen((content) {
          sb.write(content);
        })
          ..onDone(() {
            Map <String, dynamic> map = JSON.decode(sb.toString());
            completer.complete(map);
          });
      });
    });
    return completer.future;
  }
}

//===========================

class Users extends Cache<int, User> {

  static const String _usersUrl = '${RallydevService._baseUrl}/user';

  JSONFetcher _fetcher;

  Users._internal(this._fetcher) {
    retriever = _fetchUser;
  }

  Future<User> _fetchUser(int id) async {
    Completer<User> completer = new Completer<User>();
    _fetcher(Uri.parse('$_usersUrl/$id')).then((Map<String, dynamic> map) {
      Map<String, dynamic> map2 = map['User'];
      User user = new User();
      user._objectID = map2['ObjectID'];
      user._userName = map2['UserName'];
      user._displayName = map2['DisplayName'];
      user._emailAddress = map2['EmailAddress'];
      completer.complete(user);
    });
    return completer.future;
  }
}

/// Objects of this class represents Rallydev [User]s.
class User {
  int _objectID;
  String _userName, _displayName, _emailAddress;

  int get objectID => _objectID;

  int get ID => _objectID;

  String get userName => _userName;

  String get displayName => _displayName;

  String get emailAddress => _emailAddress;
}

//===========================

/// A common sub-class or [UserStory]s or [Defect]s to hold common properties.
/// Usually an object of this class will be used as a DTO.
abstract class WorkItem {

  String _id, _name, _blockedReason, _iteration;
  bool _ready, _blocked;
  User _owner;
  Set<String> _tags;

  String get formattedID => _id;

  String get name => _name;

  bool get ready => _ready;
  bool get blocked => _blocked;

  User get owner => _owner;

  String get blockedReason => _blockedReason;

  String get iteration => _iteration;

  Set<String> get tags => _tags;

}

//===========================

void main(List<String> args) { // For test
  // darellano -> 55307558173
  // jmurcia -> 55503987479

  /*RallydevService service = new RallydevService();
  service.initialize();
  service.users.get(55503987479).then((User user) {
    print(user.ID);
  });
  new Future.delayed(new Duration(seconds: 1), () {
    service.users.get(55503987479).then((User user) {
      print(user.ID);
    });
  });
  */

  String s = 'wi:{"id":96809681196,"ref":"US19723"}';
  int i = s.indexOf(r":");
  String key = s.substring(0, i);
  print(key);
  String o = s.substring(i+1);
  var v = JSON.decode(o);
  print(v);
}
