part of connection_manager;

class Heart {

  Duration _interval;

  Timer _timer;

  int _lastResponseTime = 0;

  Function _sendBeatCallback;
  Function _deathCallback;
  Function _responseCallback;

  Timer get timer => _timer;

  bool get isBeating => (timer == null) ? false : timer.isActive;

  void set beatCallback(callback(String pingData)) {
    _sendBeatCallback = callback;
  }

  void set deathMessageCallback(callback) {
    _deathCallback = callback;
  }

  void set responseCallback(callback(DateTime time)) {
    _responseCallback = callback;
  }

  Heart(Duration this._interval);

  void startBeating() {
    if (isBeating)
      return;

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
  }

  void die() {
    if (_timer != null)
      _timer.cancel();
  }

  void addResponse() {
    DateTime now = new DateTime.now();
    _lastResponseTime = now.millisecondsSinceEpoch;

    if (_responseCallback != null) {
      _responseCallback(now);
    }
  }

  bool _isAlive() {
    if (_lastResponseTime == 0)
      return true;

    int now = new DateTime.now().millisecondsSinceEpoch;
    return (now - _lastResponseTime <= (2 * _interval.inMilliseconds));
  }

  void _sendDeathMessage() {
    if (_deathCallback != null) {
      _deathCallback();
    }
  }
}