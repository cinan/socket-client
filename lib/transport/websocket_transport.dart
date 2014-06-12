part of connection_manager;

class WebsocketTransport implements Transport {

  WebSocket _socket;
  Logger _log = new Logger('WebsocketTransport');

  Completer _supportedCompleter;

  String _url;
  var _settings;

  Heart _heart = new Heart(new Duration(seconds: 10));

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

  int get readyState    => (_socket == null) ? Transport.CLOSED : _socket.readyState;
  String get url        => _url;
  String get humanType  => 'websocket';

  StreamController<Event>         _onOpenController     = new StreamController<Event>();
  Stream<Event>                   get onOpen            => _onOpenController.stream;

  StreamController<MessageEvent>  _onMessageController  = new StreamController<MessageEvent>();
  Stream<MessageEvent>            get onMessage         => _onMessageController.stream;

  StreamController<Event>         _onErrorController    = new StreamController<Event>();
  Stream<Event>                   get onError           => _onErrorController.stream;

  StreamController<CloseEvent>    _onCloseController    = new StreamController<CloseEvent>();
  Stream<CloseEvent>              get onClose           => _onCloseController.stream;

  WebsocketTransport(String this._url, [this._settings]);

  void connect() {
    _socket = new WebSocket(_url, _settings);
    _setupListeners();
  }

  void disconnect([int code, String reason]) {
    _heart.die();

    if ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING)) {
      _socket.close(code, reason);
    }
  }

  void send(String data) {
    if (_socket != null) {
      _socket.send(data);
    }
  }

  void _setupListeners() {

    // TODO still repeating this pattern. Replace _Listener class with generic one
    _socket.onOpen.pipe(new MyStreamConsumer(_onOpenController, _onOpenProcess));
    _socket.onMessage.pipe(new MyStreamConsumer(_onMessageController, _onMessageProcess));
    _socket.onError.pipe(new MyStreamConsumer(_onErrorController, _onErrorProcess));
    _socket.onClose.pipe(new MyStreamConsumer(_onCloseController, _onCloseProcess));
  }

  void _startHeartbeat() {
    _heart.startBeating();
    _heart.deathMessageCallback = () => disconnect(1000, 'timeout');
    _heart.beatCallback = _ping;
  }

  void _ping(String data) {
    send(data);
  }

  bool _isPong(String response) {
    JsonObject jsonResp = new JsonObject.fromJsonString(response);
    if (jsonResp.containsKey('type')) {
      return (jsonResp['type'] == 'pong');
    }
    return false;
  }

  Event _onOpenProcess(Event event) {
    _log.fine('Im opened');

    _startHeartbeat();
    return event;
  }

  int _onMessageProcess(MessageEvent event) {
    _log.fine('Message received');

    if (_isPong(event.data)) {
      _heart.addResponse();
      return null;
    }

    _log.fine('Message received');
    return event;
  }

  Event _onErrorProcess(Event event) => event;

  CloseEvent _onCloseProcess(CloseEvent event) {
    disconnect();
    return event;
  }

}