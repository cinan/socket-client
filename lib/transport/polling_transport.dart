part of connection_manager;

class PollingTransport implements Transport {

  Logger _log = new Logger('PollingTransport');

  String _url;
  var _settings;

  Heart _heart = new Heart(new Duration(seconds: 10), 'PT');

  bool _isPending = false;
  Queue<String> _messageQueue = new Queue<String>();

  Completer _supportedCompleter;

  Future get supported {
    _log.info('Is Polling supported?');
    return _supported.then((Future res) {
      _supportedCompleter = null;
      disconnect();
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
      _readyState = Transport.OPEN;
      _heart.die();
      _supportedCompleter.complete(true);
    };

    _heart.startBeating();

    return _supportedCompleter.future;
  }

  int _readyState = Transport.CLOSED;

  int get readyState    => _readyState;
  String get url        => _url;
  String get humanType  => 'polling';

  StreamController<OpenEvent>    _onOpenController     = new StreamController<OpenEvent>();
  Stream<OpenEvent>              get onOpen            => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController  = new StreamController<MessageEvent>();
  Stream<MessageEvent>           get onMessage         => _onMessageController.stream;

  StreamController<ErrorEvent>   _onErrorController    = new StreamController<ErrorEvent>();
  Stream<ErrorEvent>             get onError           => _onErrorController.stream;

  StreamController<CloseEvent>   _onCloseController    = new StreamController<CloseEvent>();
  Stream<CloseEvent>             get onClose           => _onCloseController.stream;

  PollingTransport(String this._url, [this._settings]);

  void connect() {
    _isPending = false;
    _messageQueue = new Queue();

    _startHeartbeat();

    // so Caller knows I'm up
    _onOpenController.add(new OpenEvent());

    _readyState = Transport.OPEN;
  }

  void disconnect([int code, String reason, bool forceDisconnect = false]) {
    _heart.die();

    if (forceDisconnect && ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING))) {
      _onCloseController.add(new CloseEvent(code, reason));
    }

    _readyState = Transport.CLOSED;
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
    MessageEvent e = new MessageEvent(resp.responseText, _url);

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
    _heart.deathMessageCallback = () => disconnect(1000, 'timeout', true);
    _heart.beatCallback = _ping;
  }

  void _ping(String data) {
    _log.info('Sending ping');
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