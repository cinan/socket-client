part of connection_manager;

class Heart {

  Logger _log = new Logger('Heartbeat');

  Duration _interval;

  Timer _timer;

  int _lastResponseTime = 0;

  Function _sendBeatCallback;
  Function _deathCallback;
  Function _responseCallback;

  Timer get timer => _timer;

  bool get isBeating => (timer == null) ? false : timer.isActive;

  void set beatCallback(callback(String pingData)) {
    _lastResponseTime = new DateTime.now().millisecondsSinceEpoch;
    _sendBeatCallback = callback;
  }

  void set deathMessageCallback(callback) {
    _deathCallback = callback;
  }

  void set responseCallback(callback(DateTime time)) {
    _responseCallback = callback;
  }

  String n = '';

  Heart(Duration this._interval, [this.n = '']);

  void startBeating() {
    if (isBeating)
      return;

    _log.finest('${n} start heartbeat');

    // Ping must be send right now, Timer.periodic calls callback after _interval pass
    _beat();

    _timer = new Timer.periodic(_interval, (_) {
      if (_isAlive()) {
        _beat();
      } else {
        die(); // yeah, kill me twice
        _sendDeathMessage();
      }
    });
  }

  void _beat() {
    String pingData = new JsonObject.fromMap({
        'type': 'ping'
    }).toString();

    if (_sendBeatCallback != null)
      _sendBeatCallback(pingData);

    _log.finest('${n} sent beat');
  }

  void die() {
    if ((_timer != null) && (_timer.isActive)) {
      _log.finest('${n} heartbeat stopped');
      _timer.cancel();
    }
  }

  void addResponse() {
   _log.finest('pong received');

    DateTime now = new DateTime.now();
    _lastResponseTime = now.millisecondsSinceEpoch;

    if (_responseCallback != null) {
      _responseCallback(now);
    }
  }

  bool _isAlive() {
    int now = new DateTime.now().millisecondsSinceEpoch;
    return (now - _lastResponseTime <= (2 * _interval.inMilliseconds));
  }

  void _sendDeathMessage() {
    if (_deathCallback != null) {
      _deathCallback();
    }
  }
}