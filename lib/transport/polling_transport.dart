part of connection_manager;

class PollingTransport implements Transport {

  Logger _log = new Logger('PollingTransport');

  String _url;

  Timer _pollingTimer;
  Duration _pollingInterval = new Duration(seconds: 10);

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

  // TODO
  int _readyState = Transport.CLOSED;

  int get readyState    => _readyState;
  String get url        => _url;
  String get humanType  => 'polling';

  StreamController<Event> _onOpenController = new StreamController.broadcast();
  Stream<Event>        get onOpen     => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController = new StreamController.broadcast();
  Stream<MessageEvent> get onMessage  => _onMessageController.stream;

  StreamController<Event> _onErrorController = new StreamController.broadcast();
  Stream<Event>        get onError    => _onErrorController.stream;

  StreamController<CloseEvent> _onCloseController = new StreamController.broadcast();
  Stream<CloseEvent>   get onClose    => _onCloseController.stream;

  StreamController<MessageEvent> _onPongController = new StreamController();
  Stream<MessageEvent> get _onPong => _onPongController.stream;

  PollingTransport(String this._url);

  void connect() {
    if (_url == null) {
      throw new FormatException('Host has not been initialized');
    }

    _startPolling();
    _onOpenController.add(new Event('open'));

    _readyState = Transport.OPEN;
  }

  void disconnect([int code, String reason]) {
    // TODO send message about disconnecting

    _endPolling();
    _readyState = Transport.CLOSED;

    _onCloseController.add(new Event('close'));
  }

  void send(String data) {
    /*
      bug https://code.google.com/p/dart/issues/detail?id=13069
      cannot use responseType: 'json' (then response.response crashes)
     */
    HttpRequest.postFormData(_url, _wrapData(data)).then((HttpRequest resp) {
      _log.fine('Response returned');

      MessageEvent e = _Transformer.responseToMessageEvent(resp, _url);

      if (_isPong(resp)) {
        _onPongController.add(e);
      } else {
        _onMessageController.add(e);
      }
    }).catchError((ProgressEvent e) {
      HttpRequest res = e.target;
      _log.warning('Message sending/receiving error');
    });
  }

  void _startPolling() {
    _pollingTimer = new Timer.periodic(_pollingInterval, (_) {
      _ping();
    });
  }

  void _endPolling() {
    _pollingTimer.cancel();
  }

  void _ping() {
    String data = JSON.encode({
        'type': 'ping'
    });

    send(data);
  }

  // TODO presunut do messagera ako staicka metoda?
  Map<String, String> _wrapData(String data) {
    return {'data': data};
  }

  bool _isPong(HttpRequest response) {
    Map<String,String> jsonResp = JSON.decode(response.responseText);
    return (jsonResp['type'] == 'pong');
  }
}

class _Transformer {

  static responseToMessageEvent(HttpRequest response, String origin) {
    return new MessageEvent('message', cancelable: false, data: response.responseText, origin: origin, lastEventId: '');
  }

}