part of connection_manager;

class Caller extends Object with EventControllersAndStreams {

  Transport _transport;

  String _url;
  var _settings;
  bool _forceDisconnect = false;

  HashMap<int, TransportBuilder> _availableConnections = new HashMap();

  TransportFinder _transportFinder;

  Logger _log = new Logger('Caller');

  bool get connected {
    if (_transport == null)
      return false;

    return _transport.readyState == Transport.OPEN;
  }

  String get transportName => (_transport == null) ? '' : _transport.humanType;

  void registerConnection(int priority, TransportBuilder connection) {
    _availableConnections[priority] = connection;
  }

  void connect() {
    _forceDisconnect = false;

    _transportFinder = new TransportFinder(timeout: 3);
    _transportFinder.transports = _availableConnections;
    _findConnection();
  }

  void send(String data) {
    if (connected) {
      _transport.send(data);
    }
  }

  void disconnect() {
    if (connected) {
      _transport.disconnect(1000, 'disconnect', true);
    }

    _transport = null;
    _forceDisconnect = true;

    _log.info('Disconnected.');
  }

  void _setupConnection(TransportBuilder connection) {
    _transport = connection();

    _transport.connect();

    // Must be after transport connect
    _setupListeners();

    _log.fine('Using transport: ${_transport.humanType}');
  }

  void _setupListeners() {
    _transport.onOpen.pipe(new MyStreamConsumer(_onOpenController));
    _transport.onMessage.pipe(new MyStreamConsumer(_onMessageController));
    _transport.onError.pipe(new MyStreamConsumer(_onErrorController));
    _transport.onClose.pipe(new MyStreamConsumer(_onCloseController, (CloseEvent event) {
      if (!_forceDisconnect) {
        _log.info('Disconnected, trying to reconnect');
        connect();
      }

      return event;
    }));
  }

  void _findConnection() {
    // TODO skusam znova alebo vyhodim vynimku po x-tom opakovani

    _transportFinder.findConnection().then((TransportBuilder conn) {
      (conn == null) ? _findConnection() : _setupConnection(conn);
    });
  }
}
