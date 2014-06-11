part of connection_manager;

class PollingTestingTransport extends PollingTransport {

  get inQueue => _messageQueue;

  Logger _log = new Logger('PollingTestingTransport');

  bool _invokeTimeout = false;

  Duration _delayedResponse;

  PollingTestingTransport(String url, [settings]) : super(url, settings);

  void set pollingInteral(Duration interval) {
    _pollingInterval = interval;
  }

  void invokeTimeout([bool invoke = true]) {
    _invokeTimeout = invoke;
  }

  bool _checkResponseTimeout() {
    return _invokeTimeout ? false : super._checkResponseTimeout();
  }

  void responseTime(Duration responseTime) {
    _delayedResponse = responseTime;
  }

  void _handleRequestResponse(HttpRequest resp) {
    if (_delayedResponse == null) {
      super._handleRequestResponse(resp);
    } else {
      new Timer(_delayedResponse, () => super._handleRequestResponse(resp));
    }
  }
}