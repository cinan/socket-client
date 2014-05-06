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

  String _host;
  int _port;
  var _settings;

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

  void connect(String host, [int port, settings]) {
    _host = host;
    _port = port;
    _settings = settings;

    _transportFinder.connections = _availableConnections;
    _findConnection();

//    new Timer(new Duration(seconds: 5), () {
//      _connection.disconnect();
//    });
  }

  void send(data) {
    if (connected) {
      _transport.send(data);
    }
  }

  void _setupConnection(TransportBuilder connection) {
    //TODO: merge TransportBuilder and initialize into one callable
    _transport = connection();
    _transport.initialize(_host, _port, _settings).connect();

    _setupListeners();
  }

  void _setupListeners() {
    _transport.onOpen.pipe(new ConnectionListener(_onOpenController));
    _transport.onMessage.pipe(new ConnectionListener(_onMessageController));
    _transport.onError.pipe(new ConnectionListener(_onErrorController));
    _transport.onClose.pipe(new ConnectionListener(_onCloseController));

    _transport.onClose.listen((_) {
      _log.info('som odpojeny, skusam sa pripojit znova');

      _findConnection();
    });
  }

  void _findConnection() {
    // TODO skusam znova alebo vyhodim vynimku po x-tom opakovani

    _transportFinder.findConnection(_host, _port, _settings).then((TransportBuilder conn) {
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
    _streamController.close();
  }
}
