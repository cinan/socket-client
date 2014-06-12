part of connection_manager;

class PollingTransport implements Transport {

  Logger _log = new Logger('PollingTransport');

  String _url;
  var _settings;

  Heart _heart = new Heart(new Duration(seconds: 10));

  bool _isPending = false;
  Queue<String> _messageQueue = new Queue<String>();

  Completer _supportedCompleter;

  Future get supported {
    return _supported.then((Future res) {
      return res;
    });
  }

  Future get _supported {
    if (_supportedCompleter != null) {
      return _supportedCompleter.future;
    }

    _supportedCompleter = new Completer();

    _readyState = Transport.CONNECTING;

    _heart.beatCallback = _ping;
    _heart.responseCallback = (_) {
      _supportedCompleter.complete(true);
      _readyState = Transport.OPEN;
    };

    _heart.startBeating();

    return _supportedCompleter.future;
  }

  int _readyState = Transport.CLOSED;

  int get readyState    => _readyState;
  String get url        => _url;
  String get humanType  => 'polling';

  StreamController<Event> _onOpenController = new StreamController();
  Stream<Event>         get onOpen          => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController = new StreamController();
  Stream<MessageEvent>  get onMessage                 => _onMessageController.stream;

  StreamController<Event> _onErrorController  = new StreamController();
  Stream<Event>         get onError           => _onErrorController.stream;

  StreamController<Event> _onCloseController  = new StreamController();
  Stream<Event>         get onClose           => _onCloseController.stream;

  PollingTransport(String this._url, [this._settings]);

  void connect() {
    _isPending = false;
    _messageQueue = new Queue();

    _startHeartbeat();

    // so Caller knows I'm up
    _onOpenController.add(new Event('open'));

    _readyState = Transport.OPEN;
  }

  void disconnect([int code, String reason]) {
    _heart.die();
    if ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING)) {
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
    MessageEvent e = _Transformer.responseToMessageEvent(resp, _url);

    if (_isPong(resp)) {
      _heart.addResponse();
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
    _heart.startBeating();
    _heart.deathMessageCallback = () => disconnect(1000, 'timeout');
    _heart.beatCallback = _ping;
  }

  void _ping(String data) {
    _makeRequest(data, true);
  }

  Map<String, String> _wrapData(String data) {
    return {'data': data};
  }

  bool _isPong(HttpRequest response) {
    JsonObject jsonResp = new JsonObject.fromJsonString(response.responseText);
    if (jsonResp.containsKey('type')) {
      return (jsonResp['type'] == 'pong');
    }
    return false;
  }
}

class _Transformer {

  static responseToMessageEvent(HttpRequest response, String origin) {
    return new MessageEvent('message', cancelable: false, data: response.responseText, origin: origin, lastEventId: '');
  }

}