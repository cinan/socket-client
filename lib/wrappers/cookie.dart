part of connection_manager;

class Cookie extends Object with EventControllersAndStreams {

  Caller _caller = new Caller();
  Logger _log = new Logger('Cookie');

  String _sessionID;

  bool _firstStart = true;
  bool _forceDisconnect = false;

  bool get connected        => _caller.connected;
  String get transportName  => _caller.transportName;

  void registerConnection(int priority, TransportBuilder connection) {
    _caller.registerConnection(priority, connection);
  }

  void connect() {
    _forceDisconnect = false;

    if (_firstStart)
      Session.forget();

    _firstStart = false;

    _caller.connect();
    _setupListeners();
  }

  void send(String data) {
    _caller.send(data);
  }

  void disconnect() {
    _forceDisconnect = true;
    _caller.disconnect();
  }

  void _setupListeners() {
    _caller.onOpen.pipe(new MyStreamConsumer(_onOpenController, (OpenEvent event) {
      String sessionID = cookie.get('sessionID');
      if (sessionID != null) {
        Session.set(sessionID);
      }
      return event;
    }));
    _caller.onMessage.pipe(new MyStreamConsumer(_onMessageController));
    _caller.onError.pipe(new MyStreamConsumer(_onErrorController));
    _caller.onClose.pipe(new MyStreamConsumer(_onCloseController, (CloseEvent event) {
      if (_forceDisconnect) {
        Session.forget();
      }
      return event;
    }));
  }
}

