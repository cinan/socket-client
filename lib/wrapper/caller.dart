part of connection_manager;

class Caller {

  StreamController _onOpenController = new StreamController();
  Stream<Event> get onOpen => _onOpenController.stream;

  StreamController _onMessageController = new StreamController();
  Stream<MessageEvent> get onMessage => _onMessageController.stream;

  StreamController _onErrorController = new StreamController();
  Stream<Event> get onError => _onErrorController.stream;

  StreamController _onCloseController = new StreamController();
  Stream<CloseEvent> get onClose => _onCloseController.stream;

  Transport _transport;

  String _url;
  var _settings;
  bool _forceDisconnect = false;

  HashMap<int, TransportBuilder> _availableConnections = new HashMap();

  TransportFinder _transportFinder = new TransportFinder(timeout: 3);

  Logger _log = new Logger('Caller');

  bool get connected {
    if (_transport == null)
      return false;

    return _transport.readyState == Transport.OPEN;
  }

  void registerConnection(int priority, TransportBuilder connection) {
    _availableConnections[priority] = connection;
  }

  void connect() {
    _forceDisconnect = false;

    _transportFinder.connections = _availableConnections;
    _findConnection();
  }

  void send(data) {
    if (connected) {
      _transport.send(data);
    }
  }

  void disconnect() {
    if (connected) {
      _transport.disconnect();
    }

    _transport = null;
    _forceDisconnect = true;

    _log.info('Disconnected.');
  }

  void _setupConnection(TransportBuilder connection) {
    _transport = connection();

    // Must be before transport connect
    _setupListeners();

    _transport.connect();

    _log.fine('Using transport: ${_transport.humanType}');
  }

  void _setupListeners() {
    _transport.onOpen.pipe(new ConnectionListener(_onOpenController));
    _transport.onMessage.pipe(new ConnectionListener(_onMessageController));
    _transport.onError.pipe(new ConnectionListener(_onErrorController));
    _transport.onClose.pipe(new ConnectionListener(_onCloseController));

    _transport.onClose.listen((_) {
      if (!_forceDisconnect) {
        _log.info('Disconnected, trying to reconnect');

        _findConnection();
      }
    });
  }

  void _findConnection() {
    // TODO skusam znova alebo vyhodim vynimku po x-tom opakovani

    _transportFinder.findConnection().then((TransportBuilder conn) {
      (conn == null) ? _findConnection() : _setupConnection(conn);
    });
  }
}

class ConnectionListener implements StreamConsumer {

  StreamController _streamController;

  ConnectionListener(this._streamController);

  Future addStream(Stream s) {
    s.listen((event) {
      _streamController.add(event);
    });

    return new Completer().future;
  }

  Future close() {
    return _streamController.close();
  }
}
