part of connection_manager;

class PollingTransport extends Object with EventControllersAndStreams implements Transport {

  Logger _log = new Logger('PollingTransport');

  String _url;
  var _settings;

  Heart _heart = new Heart(new Duration(seconds: 10));

  String _sessionId = '';
  final String _cookieName = 'sessionID';

  bool _isPending = false;
  Queue<String> _messageQueue = new Queue<String>();

  Completer _supportedCompleter;

  Future<bool> get supported {
    _log.info('Is Polling supported?');
    return _supported.then((Future res) {
      _supportedCompleter = null;
      disconnect(1000, 'try-end', true);
      return res;
    });
  }

  Future<bool> get _supported {
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

  PollingTransport(String this._url, [this._settings]);

  void connect() {
    _isPending = false;
    _messageQueue = new Queue();

    _startHeartbeat();

    _onOpenController.add(new OpenEvent());

    _readyState = Transport.OPEN;
  }

  void disconnect([int code, String reason, bool forceDisconnect = false]) {
    _heart.die();

    if (forceDisconnect) {
      if ((readyState == Transport.OPEN) || (readyState == Transport.CONNECTING)) {
        _onCloseController.add(new CloseEvent(code, reason));
      }

      _forgetSession();
    }

    _readyState = Transport.CLOSED;
  }

  void send(String data) {
    (_isPending == true) ? _addToQueue(data) : _makeRequest(data);
  }

  void _addToQueue(String data) {
    // TODO: make like the server does, this is not good
    _log.info('Adding to queue');
    _messageQueue.addLast(data);
  }

  void _sendNextFromQueue() {
    // TODO: if many messages, wrap them into one
    if (_messageQueue.isNotEmpty) {
      String message = _messageQueue.removeFirst();
      _makeRequest(message);
    }
  }

  void _makeRequest(String data, [bool isPing = false]) {
    _isPending = true;

    _setSessionCookie();

    // TODO if there's pending operation and I switch transports, I drop listener onMessage. REALLY?
    HttpRequest.postFormData(_url, _wrapData(data), withCredentials: true)
        .then(_handleRequestResponse)
        .catchError(_handleRequestError)
        .whenComplete(() => _handleRequestCompleted(isPing));
  }

  void _handleRequestResponse(HttpRequest resp) {
    MessageEvent e = new MessageEvent(resp.responseText, _url);

    _saveSessionId();

    _heart.addResponse();

    _log.fine('Response returned');
    _onMessageController.add(e);
  }

  void _handleRequestError(ProgressEvent e) {
//    HttpRequest res = e.target;
    _log.warning('Message sending/receiving error');
  }

  void _handleRequestCompleted([bool pingRequest = false]) {
    _isPending = false;

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
    return PongMessage.matches(jsonResp);
  }

  void _setSessionCookie() {
    cookie.set(_cookieName, _sessionId);
  }

  void _forgetSession() {
    _log.info('removing session cookie');
    cookie.remove(_cookieName);
  }

  void _saveSessionId() {
    String sessionId = cookie.get(_cookieName);
    if ((sessionId != null) && (sessionId.isNotEmpty)) {
      _log.info('saving session cookie: $sessionId');
      _sessionId = sessionId;
    }
  }
}