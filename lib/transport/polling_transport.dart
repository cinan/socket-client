part of connection_manager;

class PollingTransport implements Transport {

  Logger _log = new Logger('PollingTransport');

  String _url;
  var _settings;

  Timer _pollingTimer;
  Duration _pollingInterval = new Duration(seconds: 10);

  int _lastReqTime = 0;
  int _lastRespTime = 0;

  bool _isPending = false;
  Queue<String> _messageQueue = new Queue<String>();

  Completer _supportedCompleter;

  Future get supported {
    return _supported.then((Future res) {
      _supportedCompleter = null;
      return res;
    });
  }

  Future get _supported {
    if (_supportedCompleter != null) {
      return _supportedCompleter.future;
    }

    _supportedCompleter = new Completer();

    _readyState = Transport.CONNECTING;
    _ping();

    StreamSubscription<MessageEvent> pongListener = _onPong.listen(null);
    pongListener.onData((MessageEvent event) {

      Map<String,String> resp =  JSON.decode(event.data);
      if (resp['type'] == 'pong') {
        _supportedCompleter.complete(true);
        _readyState = Transport.OPEN;
      } else {
        _supportedCompleter.complete(false);
        _readyState = Transport.CLOSED;
      }

      pongListener.cancel();
    });

    return _supportedCompleter.future;
  }

  int _readyState = Transport.CLOSED;

  int get readyState    => _readyState;
  String get url        => _url;
  String get humanType  => 'polling';

  StreamController<Event> _onOpenController = new StreamController();
  Stream<Event>        get onOpen     => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController = new StreamController();
  Stream<MessageEvent> get onMessage  => _onMessageController.stream;

  StreamController<Event> _onErrorController = new StreamController();
  Stream<Event>        get onError    => _onErrorController.stream;

  StreamController<Event> _onCloseController = new StreamController();
  Stream<Event>   get onClose         => _onCloseController.stream;

  StreamController<MessageEvent> _onPongController = new StreamController();
  Stream<MessageEvent> get _onPong => _onPongController.stream;

  PollingTransport(String this._url, [this._settings]);

  void connect() {
    if (_url == null) {
      throw new FormatException('Host has not been initialized');
    }

    _isPending = false;
    _messageQueue = new Queue();

    _startHeartbeat();

    // so Caller knows I'm up
    _onOpenController.add(new Event('open'));

    _readyState = Transport.OPEN;
  }

  void disconnect([int code, String reason]) {
    if ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING)) {
      _killHeartbeat();
      _readyState = Transport.CLOSED;

      // TODO: custom events, CloseEvent is reserved for Websocket usage only
      _onCloseController.add(new Event('close'));
    }
  }

  void send(String data) {
    (_isPending == true) ? _addToQueue(data) : _makeRequest(data);
  }

  void _addToQueue(String data) {
    _log.info('Adding to queue');
    _messageQueue.addLast(data);
  }

  void _sendNextFromQueue() {
    if (_messageQueue.isNotEmpty) {
      String message = _messageQueue.removeFirst();
      _makeRequest(message);
    }
  }

  void _makeRequest(String data, [bool isPing = false]) {
    _lastReqTime = new DateTime.now().millisecondsSinceEpoch;

    if (!isPing) {
      // Pings aren't queued
      _isPending = true;
      _log.info('Making no-ping request');
    }

    // TODO if there's pending operation and I switch transports, I drop listener onMessage
    HttpRequest.postFormData(_url, _wrapData(data))
        .then(_handleRequestResponse)
        .catchError(_handleRequestError)
        .whenComplete(() => _handleRequestCompleted(isPing));
  }

  void _handleRequestResponse(HttpRequest resp) {
    // TODO what if long timeout?

    _lastRespTime = new DateTime.now().millisecondsSinceEpoch;

    MessageEvent e = _Transformer.responseToMessageEvent(resp, _url);

    if (_isPong(resp)) {
      _onPongController.add(e);
    } else {
      _log.fine('Response returned');
      _onMessageController.add(e);
    }
  }

  void _handleRequestError(ProgressEvent e) {
//    HttpRequest res = e.target;
    _log.warning('Message sending/receiving error');
  }

  void _handleRequestCompleted([bool pingRequest = false]) {
    if (!pingRequest) {
      // Pings aren't queued
      _isPending = false;
    }
    _sendNextFromQueue();
  }

  void _startHeartbeat() {
    _pollingTimer = new Timer.periodic(_pollingInterval, (_) {
      _checkResponseTimeout() ? _ping() : disconnect(1000, 'timeout');
    });
  }

  void _killHeartbeat() {
    if (_pollingTimer != null) {
      _pollingTimer.cancel();
    }
  }

  bool _checkResponseTimeout() {
    if (_lastReqTime == 0)
      return true;

    int now = new DateTime.now().millisecondsSinceEpoch;
    return (now - _lastReqTime <= (1.5 * _pollingInterval.inMilliseconds));
  }

  // Otestovat, ze ping nevola send ale makerequest priamo
  void _ping() {
    String data = new JsonObject.fromMap({
        'type': 'ping'
    }).toString();

    _makeRequest(data, true);
  }

  Map<String, String> _wrapData(String data) {
    return {'data': data};
  }

  bool _isPong(HttpRequest response) {
    JsonObject jsonResp = new JsonObject.fromJsonString(response.responseText);
    return (jsonResp['type'] == 'pong');
  }
}

class _Transformer {

  static responseToMessageEvent(HttpRequest response, String origin) {
    return new MessageEvent('message', cancelable: false, data: response.responseText, origin: origin, lastEventId: '');
  }

}