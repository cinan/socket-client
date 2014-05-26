part of connection_manager;

class Messager {

  bool get connected => _caller.connected;

  // Mam zarucene, ze iterujem v takom poradi, ako boli elementy vlozene
  LinkedHashMap<dynamic, String> _messageBuffer = new LinkedHashMap<dynamic, String>();

  StreamController _onOpenController = new StreamController();
  Stream<Event> get onOpen => _onOpenController.stream;

  Stream<MessageEvent> get onMessage {
    var transformer = new StreamTransformer.fromHandlers(handleData: (MessageEvent value, sink) {
      try {
        Map decodedMessage = JSON.decode(value.data);

        if (_isConfirmation(decodedMessage)) {
          _confirmMessage(decodedMessage);
          return;
        }

        // ak ide o potvrdenie spravy, tak to je sprava iba pre mna a moje Futures
        if (decodedMessage.containsKey('body')) {
          MessageEvent modifiedEvent = new MessageEvent(
              value.type,
              cancelable: false,
              data: decodedMessage['body'],
              origin: value.origin,
              lastEventId: '');

          sink.add(modifiedEvent);
        } else {
          throw new FormatException();
        }
      } on FormatException {
        _log.warning('Malformatted message received');
      }
    });

    return _caller.onMessage.transform(transformer);
  }

  Stream<Event> get onError => _caller.onError;

  Stream<CloseEvent> get onClose => _caller.onClose;

  Caller _caller = new Caller();
  int _nextSendId = 0;
  Map<dynamic, Completer> _completers = new Map<dynamic, Completer>();

  Logger _log = new Logger('Messager');

  Messager() {
  }

  void registerConnection(int priority, TransportBuilder connection) {
    _caller.registerConnection(priority, connection);
  }

  void connect() {
    _caller.connect();
    _setupListeners();
  }

  Future send(data) {
    // TODO tu skor nejaky hash dat namiesto incrementu
    _nextSendId++;

    String message = JSON.encode({
        'id': _nextSendId,
        'body': data
    });

    _log.info('pridavam do buffera $message');
    _messageBuffer[_nextSendId] = message;
    _completers[_nextSendId] = new Completer();

    _caller.send(message);
    return _completers[_nextSendId].future;
  }

  bool _isConfirmation(Map decodedMessage) {
    String messageType = decodedMessage['type'];
    var messageId = decodedMessage['id'];

    return ((messageType == 'confirmation') && (messageId != null));
  }

  void _confirmMessage(Map decodedConfirmation) {
    var messageId = decodedConfirmation['id'];

    if (_completers.containsKey(messageId)) {
      _completers[messageId].complete(messageId);
      _completers.remove(messageId);
    }

    if (_messageBuffer.containsKey(messageId)) {
      _messageBuffer.remove(messageId);
    }
  }

  void _setupListeners() {
    _caller.onOpen.pipe(new MessagerConnectionListener(_onOpenController, () {
      _log.info('som (znova) pripojeny, odosielam neodoslane spravy');
      _sendMessageBuffer();
    }));
  }

  void _sendMessageBuffer() {
    for (String msg in _messageBuffer.values) {
      _caller.send(msg);
    }
  }
}

class MessagerConnectionListener implements StreamConsumer {

  StreamController _streamController;
  Function _callback;

  MessagerConnectionListener(this._streamController, this._callback);

  Future addStream(Stream s) {
    s.listen((event) {
      _callback();

      _streamController.add(event);
    });

    return new Completer().future;
  }

  Future close() {
    _streamController.close();
  }
}
