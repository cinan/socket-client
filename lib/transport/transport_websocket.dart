part of connection_manager;

class TransportWebsocket implements Transport {

  WebSocket _socket;
  Logger _log = new Logger('ConnectionWebsocket');

  Completer _supportedCompleter;

  String _url;
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
      return new Future.value(false);

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

  TransportWebsocket(String this._url, [this._settings]);

  void connect() {
    if (_url == null) {
      throw new FormatException('Host has not been initialized');
    }

    _socket = new WebSocket(_url, _settings);
  }

  void disconnect([int code, String reason]) {
    _socket.close(code, reason);
  }

  void send(String data) {
    _socket.send(data);
  }
}
