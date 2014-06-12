part of connection_manager;

class WebsocketTestingTransport extends WebsocketTransport {

  Logger _log = new Logger('WeboscketTestingTransport');

  bool _forceDisconnected = false;
  bool _initOnCreate      = true;
  bool _supported         = true;

  Duration _delayedResponse;

  Future get supported => new Future.value(_supported);
  void set supported(isSupported) {
    _supported = isSupported;
  }

  int get readyState => _forceDisconnected ? Transport.CLOSED : super.readyState;

  WebsocketTestingTransport(String url, [settings]) : super(url, settings);

  void asDisconnected([bool disconnect = true]) {
    _forceDisconnected = disconnect;
  }

  void set pollingInterval(Duration interval) {
    _heart = new Heart(interval);
  }

  void responseTime(Duration responseTime) {
    _delayedResponse = responseTime;
  }

  MessageEvent _onMessageProcess(MessageEvent event) {
    if (_delayedResponse == null) {
      return super._onMessageProcess(event);
    } else {
      new Timer(_delayedResponse, () {
        _onMessageController.add(event);
      });
      return null;
    }
  }
}