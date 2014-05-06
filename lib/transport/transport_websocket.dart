part of connection_manager;

class TransportWebsocket implements Transport {

  WebSocket _socket;
  Logger _log = new Logger('ConnectionWebsocket');

  Completer _supportedCompleter;

  String _host;
  int _port;
  var _settings;

  Future get supported {
    return _supported.then((res){
      _supportedCompleter = null;
      return res;
    });
  }


  Future get _supported {
    _log.info('Checking if websocket is supported');

    if (_supportedCompleter != null) {
      return _supportedCompleter.future;
    }

    if (!WebSocket.supported)
      return new Future(false);

    connect();

    onOpen.listen((Event e) {
      _log.info('Websocket transport is supported');
      disconnect();
      _supportedCompleter.complete(true);
    }, onError: (err) {
      _log.info('Websocket transport is NOT supported');
      disconnect();
      _supportedCompleter.complete(false);
    }, cancelOnError: true);

    _supportedCompleter = new Completer();
    return _supportedCompleter.future;
  }

  int get readyState    => _socket.readyState;
  String get url        => _socket.url;
  String get humanType  => 'websocket';

  Stream<Event>        get onOpen     => _socket.onOpen;
  Stream<MessageEvent> get onMessage  => _socket.onMessage;
  Stream<Event>        get onError    => _socket.onError;
  Stream<CloseEvent>   get onClose    => _socket.onClose;

  TransportWebsocket() {
  }

  TransportWebsocket initialize(String host, [int port = 80, settings]) {
    this._host = host;
    this._port = port;
    this._settings = settings;

    return this;
  }

  void connect() {
    if (_host == null) {
      throw new FormatException('Host has not been initialized');
    }

    String protocol = 'ws';
    String host = _host.replaceAll(new RegExp(r'/+$'), '');
    String port = (_port == null) ? '' : ':$_port';
    String path = 'ws';

    String url = '$protocol://$host$port/$path';

    _socket = new WebSocket(url, _settings);
  }

  void disconnect([int code, String reason]) {
    _socket.close(code, reason);
  }

  void send(data) {
    _socket.send(data);
  }
}
