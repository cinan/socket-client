part of connection_manager;

class PollingTestingTransport extends PollingTransport {

  get inQueue => _messageQueue;

  Logger _log = new Logger('PollingTestingTransport');

  Duration _delayedResponse;

  PollingTestingTransport(String url, [settings]) : super(url, settings);

  void set pollingInterval(Duration interval) {
    _heart = new Heart(interval);
  }

  void responseTime(Duration responseTime) {
    _delayedResponse = responseTime;
  }

  void _handleRequestResponse(Html.HttpRequest resp) {
    if (_delayedResponse == null) {
      super._handleRequestResponse(resp);
    } else {
      new Timer(_delayedResponse, () => super._handleRequestResponse(resp));
    }
  }
}