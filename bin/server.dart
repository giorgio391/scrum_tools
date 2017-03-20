import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:prompt/prompt.dart';
import 'package:start/start.dart';
import 'package:scrum_tools/src/utils/cache.dart';

const webDirArg = 'web-dir';
const hostArg = 'host';
const portArg = 'port';
const webSocketArg = 'web-socket';
const helpArg = 'help';
const rdProxyArg = 'rd-proxy';
const rdUserArg = 'rd-user';
const rdPassArg = 'rd-pass';

typedef void ServerInitializer(Server appServer);

/// Allows to run a simple server to serve the assets of the different tools.
/// Run this class passing "-h" as an argument to display the usage.
///
/// The most simple usage would be passing "-w!" as arguments after a plain
/// _dart build_.
Future main(List<String> arguments) async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  // ----
  Logger _log = new Logger('main');
  // ----

  // Parse arguments
  ArgParser argParser = new ArgParser()
    ..addOption(webDirArg, abbr: 'w',
        help: 'Allows to set the root of the web directory. '
            'A value after the option must be provided. '
            'If the value provided is "!" the current script '
            'directory appended with '
            '"..${Platform.pathSeparator}build${Platform.pathSeparator}web" '
            'will be used. '
            'If his option was ommited, no web directory would be served.'
    )..addOption(hostArg,
        help: 'Allows to set the host address to bind the server.'
    )..addOption(portArg, abbr: 'p',
        help: 'Allows to set the port used by the server. '
            'An integer positive value after the option must be provided.',
        defaultsTo: '3000'
    )
    ..addFlag(helpArg, negatable: false, abbr: 'h',
        help: 'Display usage help.'
    )
    ..addOption(webSocketArg, abbr: 'z',
        help: 'Allows to set up the path for web sockets. '
            'A value after the option must be provided to define the path to '
            'invoke web sockets (i.e. "ws" for "/ws"). '
            'If his option was ommited, no web socket service would be started.'
    )
    ..addFlag(rdProxyArg, abbr: 'r',
        help: 'Starts the Rallydev proxy service.')
    ..addOption(rdUserArg, help: 'Username to be used to connect to Rallydev.')
    ..addOption(rdPassArg, help: 'Password of the user to be used to connect to Rallydev.');
  ArgResults argResults = () {
    try {
      return argParser.parse(arguments);
    } on FormatException {
      print(argParser.usage);
      exit(0);
    }
  }();
  //--

  // Need help?
  if (argResults[helpArg] == true) {
    print(argParser.usage);
    exit(0);
  }
  // ----

  // Server port
  int port = () {
    try {
      int p = int.parse(argResults[portArg]);
      if (p < 0) throw new FormatException();
      return p;
    } on FormatException {
      _log.severe('port: "${argResults[portArg]}" is not a valid value!');
      exit(2);
    }
  }();
  // ----

  List<ServerInitializer> initializers = new List<ServerInitializer>();

  // Serve from file system directory?
  if (argResults[webDirArg] != null) {
    String resolveDefaultDir() {
      File script = new File.fromUri(Platform.script);
      return '${script.parent.parent.path}'
          '${Platform.pathSeparator}build${Platform.pathSeparator}web';
    };

    String webPath = argResults[webDirArg] == '!'
        ? resolveDefaultDir()
        : argResults[webDirArg];

    Directory webDir = new Directory(webPath);
    if (!await webDir.exists()) {
      _log.severe('error: $webPath is not a directory!');
      exit(2);
    }

    initializers.add((Server appServer) {
      appServer.static(webPath, jail: true);
      _log.info('Serving files from [$webPath].');
    });
  }
  // ----

  // Start web sockets?
  if (argResults[webSocketArg] != null) {
    _WebSocketController wsController = new _WebSocketController(
        argResults[webSocketArg]);
    initializers.add(wsController._initializeWebSockets);
  }

  // Start Rallydev proxy?
  if (argResults[rdProxyArg] == true) {
    String user = () {
      if (argResults[rdUserArg] == null) {
        return askSync(new Question('Username for Rallydev'));
      }
     return argResults[rdUserArg];
    }();
    String pass = () {
      if (argResults[rdPassArg] == null) {
        return askSync(new Question('[${argResults[rdUserArg]}] password', secret: true));
      }
      return argResults[rdPassArg];
    }();
    _RDProxy rdProxy = new _RDProxy(user, pass);
    initializers.add(rdProxy.init);
  }

  // Resolve host
  String host = await () async {
    if (argResults[hostArg] == null) {
      List<String> addresses = new List<String>();
      addresses.add(InternetAddress.LOOPBACK_IP_V4.address);
      addresses.add(InternetAddress.ANY_IP_V4.address);
      for (NetworkInterface nif in await NetworkInterface.list()) {
        for (InternetAddress addr in nif.addresses) {
          addresses.add(addr.address);
        }
      }
      return askSync(new Question('Host address', allowed: addresses));
    }
    return argResults[hostArg];
  }();

  close(); // Prompt close

  // ###################### INITIATE SERVICES *** START ***********

  if (initializers.length > 0) {
    start(host: host, port: port).then((Server appServer) {
      for (ServerInitializer initializer in initializers) {
        initializer(appServer);
      }
    });
  } else {
    _log.info('Nothing to do! Server stopped.');
    exit(0);
  }

  // ###################### INITIATE SERVICES *** END ***********
}

// ******** WEB SOCKET GROUPS SERVICE *** START ******************
class _WebSocketController {

  Logger _log = new Logger("web-sockets");
  String _wsPath;

  _WebSocketController(this._wsPath);

  void _initializeWebSockets(Server serverApp) {
    // Normalize path
    _wsPath = _wsPath == null || _wsPath
        .trim()
        .length == 0 ? '/ws' : _wsPath.trim();
    if (_wsPath.substring(0, 1) != '/') {
      _wsPath = '/$_wsPath';
    }

    // ignore: conflicting_dart_import
    serverApp.ws(_wsPath).listen((Socket socket) {
      socket.on('ping').listen((Map data) {
        _log.finer('pong: $data');
        socket.send('pong', data);
      });
      socket.on('group').listen((data) {
        String id = () {
          if (data is String) return data;
          if (data is int) return data.toString();
          if ((data is Map) && data.containsKey('id')) return data['id'];
          return null;
        }();
        if (id == null) {
          socket.send(
              'error', 'To create or join a group an [id] must be provided.');
        } else {
          new _Group(socket, id);
          socket.send('info', 'Added to group [$id].');
        }
      });
    });

    _log.info('Listening for web sockets at [$_wsPath].');

    // ----
  }
}

class _Group {

  static Expando<_Group> _group = new Expando<_Group>();
  static Map<String, _Group> _groups = new Map<String, _Group>();

  Logger _log = new Logger("group");

  Set<Socket> _sockets = new Set<Socket>();
  String _id;

  String get id => _id;

  // ignore: conflicting_dart_import
  factory _Group(Socket socket, String id) {
    if (_groups.containsKey(id)) {
      _Group group = _groups[id];
      group._add(socket);
      return group;
    }
    _Group newGroup = new _Group._internal(socket, id);
    _groups[id] = newGroup;
    return newGroup;
  }

  _Group._internal(Socket socket, this._id) {
    _add(socket);
  }

  // ignore: conflicting_dart_import
  void _add(Socket socket) {
    if (_sockets.contains(socket)) return;
    if (_group[socket] != null) {
      _group[socket]._remove(socket);
    }
    _group[socket] = this;
    _sockets.add(socket);
    socket.on('close').listen((Map data) {
      _remove(socket);
      socket.close(1000, 'Close requested.');
      _log.finer('Socket closed upon request.');
    });
    socket.on('message').listen((Map data) {
      _Group group = _group[socket];
      if (group != null) {
        String key = data.keys.first;
        group._sockets.where((Socket s) => s != socket).forEach((Socket s) =>
            s.send(key, data[key]));
      }
    });
  }

  void _remove(Socket socket) {
    if (_sockets.remove(socket)) {
      _group[socket] = null;
    }
  }

}
// ******** WEB SOCKET GROUPS SERVICE *** END ******************

// ******** RALLYDEV PROXY SERVICE *** START *******************

class _RDProxy {

  static const String _baseUrl =
      'https://rally1.rallydev.com/slm/webservice/v2.0';

  static final Uri _baseUri = Uri.parse(_baseUrl);

  Logger _log = new Logger("rd-proxy");

  Cache<String, String> _cache;
  HttpClient _httpClient;

  String _user, _pass, _pathRoot;

  _RDProxy(this._user, this._pass, [this._pathRoot = '/rd']);

  void init(Server appServer) {
    _cache = new Cache<String, String>();
    _cache.retriever = _handle;

    HttpClientBasicCredentials credentials =
    new HttpClientBasicCredentials(_user, _pass);

    _httpClient = new HttpClient();
    _httpClient.addCredentials(_baseUri, 'Rally ALM', credentials);

    // Process any 'get' request.
    appServer.get(new RegExp("${_pathRoot}/.*")).listen((Request request) {
      Response response = request.response;
      String path = request.path;
      response.header('Content-Type', 'application/json; charset=UTF-8');
      if (path == '${_pathRoot}/status') {
        response.send('{"status": "OK"}');
      } else {
        String requestedUri = request.input.requestedUri.toString();
        String uriPart = requestedUri.substring(
            requestedUri.indexOf('${_pathRoot}/') + _pathRoot.length);
        _cache.get(uriPart).then((String value) {
          response.send(value);
        });
      }
    });
    _log.info('Rallydev proxy ready at [${_pathRoot}].');
  }

  // Delegate the call to the Rallydev server.
  Future<String> _handle(String uriPart) {
    Uri uri = Uri.parse('${_baseUrl}${uriPart}');
    Completer <String> completer = new Completer <String>();
    _httpClient.getUrl(uri).then((HttpClientRequest request) {
      request.close().then((HttpClientResponse response) {
        StringBuffer sb = new StringBuffer();
        response.transform(UTF8.decoder).listen((content) {
          sb.write(content);
        })..onDone(() {
            completer.complete(sb.toString());
          });
      });
    });
    return completer.future;
  }
}

// ******** RALLYDEV PROXY SERVICE *** END *********************