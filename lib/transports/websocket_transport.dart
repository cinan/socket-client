part of connection_manager;

class WebsocketTransport implements Transport {

  WebSocket _socket;
  Logger _log = new Logger('WebsocketTransport');

  Completer _supportedCompleter;

  String _url;
  var _settings;

  Heart _heart = new Heart(new Duration(seconds: 10), 'WS');

  Future get supported {
    _log.info('Is Websocket supported?');
    return _supported.then((res) {
      _supportedCompleter = null;
      disconnect();
      return res;
    });
  }

  Future get _supported {
    if (_supportedCompleter != null) {
      return _supportedCompleter.future;
    }

    if (!WebSocket.supported)
      return new Future.value(false);

    connect();

    onOpen.listen((Event e) {
      _supportedCompleter.complete(true);
    }, onError: (err) {
      _supportedCompleter.complete(false);
    }, cancelOnError: true);

    _supportedCompleter = new Completer();
    return _supportedCompleter.future;
  }

  int get readyState    => (_socket == null) ? Transport.CLOSED : _socket.readyState;
  String get url        => _url;
  String get humanType  => 'websocket';

  StreamController<OpenEvent>    _onOpenController     = new StreamController<OpenEvent>();
  Stream<OpenEvent>              get onOpen            => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController  = new StreamController<MessageEvent>();
  Stream<MessageEvent>           get onMessage         => _onMessageController.stream;

  StreamController<ErrorEvent>   _onErrorController    = new StreamController<ErrorEvent>();
  Stream<ErrorEvent>             get onError           => _onErrorController.stream;

  StreamController<CloseEvent>   _onCloseController    = new StreamController<CloseEvent>();
  Stream<CloseEvent>             get onClose           => _onCloseController.stream;

  WebsocketTransport(String this._url, [this._settings]);

  void connect() {
    _socket = new WebSocket(_url, _settings);
    _setupListeners();
  }

  void disconnect([int code, String reason, bool forceDisconnect = false]) {
    _heart.die();

    if (forceDisconnect && ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING))) {
      _socket.close(code, reason);
    }
  }

  void send(String data) {
    if (_socket != null) {
      print('send');
      _socket.send(data);
    }
  }

  void _setupListeners() {
    _socket.onOpen.pipe(new MyStreamConsumer(_onOpenController, _onOpenProcess));
    _socket.onMessage.pipe(new MyStreamConsumer(_onMessageController, _onMessageProcess));
    _socket.onError.pipe(new MyStreamConsumer(_onErrorController, _onErrorProcess));
    _socket.onClose.pipe(new MyStreamConsumer(_onCloseController, _onCloseProcess));
  }

  void _startHeartbeat() {
    _heart.startBeating();
    _heart.deathMessageCallback = () => disconnect(1000, 'timeout', true);
    _heart.beatCallback = _ping;
  }

  void _ping(String data) {
    send(data);
  }

  bool _isPong(MessageEvent event) {
    JsonObject jsonResp = new JsonObject.fromJsonString(event.data);
    return PongMessage.matches(jsonResp);
  }

  OpenEvent _onOpenProcess(Event event) {
    _log.fine('Im opened');

    _startHeartbeat();
    return new OpenEvent.fromExistingHtmlEvent(event);
  }

  MessageEvent _onMessageProcess(Html.MessageEvent event) {
    MessageEvent transformedEvent = new MessageEvent.fromExistingHtmlEvent(event);

    if (_isPong(transformedEvent)) {
      _heart.addResponse();
      return null;
    }

    _log.fine('Message received');
    return transformedEvent;
  }

  ErrorEvent _onErrorProcess(Html.Event event) => new ErrorEvent.fromExistingHtmlEvent(event);

  CloseEvent _onCloseProcess(Html.CloseEvent event) {
    disconnect();
    return new CloseEvent.fromExistingHtmlEvent(event);
  }

}