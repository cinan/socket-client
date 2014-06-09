part of connection_manager;

class WebsocketTestingTransport extends WebsocketTransport {

  Logger _log = new Logger('WeboscketTestingTransport');

  bool _forceDisconnected = false;
  bool _initOnCreate      = true;
  bool _supported         = true;

  Future get supported => new Future.value(_supported);
  void set supported(isSupported) {
    _supported = isSupported;
  }

  int get readyState => _forceDisconnected ? Transport.CLOSED : _socket.readyState;

  WebsocketTestingTransport(String url, [settings]) : super(url, settings);

  void asDisconnected([bool disconnect = true]) {
    _forceDisconnected = disconnect;
  }
}