part of connection_manager;

class Messager {

  bool get connected => _caller.connected;

  // Mam zarucene, ze iterujem v takom poradi, ako boli elementy vlozene
  LinkedHashMap<dynamic, String> _messageBuffer = new LinkedHashMap<dynamic, String>();

  StreamController _onOpenController = new StreamController();
  Stream<Event> get onOpen => _onOpenController.stream;

  StreamController _onMessageController = new StreamController();
  Stream<Event> get onMessage => _onMessageController.stream;

  Stream<Event> get onError => _caller.onError;

  Stream<CloseEvent> get onClose => _caller.onClose;

  Caller _caller = new Caller();
  int _nextSendId = 0;
  Map<dynamic, Completer> _completers = new Map<dynamic, Completer>();

  Logger _log = new Logger('Messager');

  Messager();

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

    String message = new JsonObject.fromMap({
        'id': _nextSendId,
        'body': data
    }).toString();

    _log.info('pridavam do buffera $message');
    _messageBuffer[_nextSendId] = message;
    _completers[_nextSendId] = new Completer();

    _caller.send(message);
    return _completers[_nextSendId].future;
  }

  void disconnect() {
    _caller.disconnect();
  }

  bool _isConfirmation(JsonObject decodedMessage) {
    String messageType = decodedMessage['type'];

    var messageId = null;
    if (decodedMessage['body'] != null) {
      messageId = decodedMessage['body']['id'];
    }

    return ((messageType == 'confirmation') && (messageId != null));
  }

  void _finalizeMessage(JsonObject decodedConfirmation) {
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
    _caller.onOpen.pipe(new MyStreamConsumer(_onOpenController, (event) {
      _log.info('som (znova) pripojeny, odosielam neodoslane spravy');
      _sendMessageBuffer();

      return event;
    }));

    _caller.onMessage.pipe(new MyStreamConsumer(_onMessageController, (MessageEvent event) {
      return _decodeIncomingEventMessage(event);
    }));
  }

  void _sendMessageBuffer() {
    for (String msg in _messageBuffer.values) {
      _caller.send(msg);
    }
  }

  MessageEvent _decodeIncomingEventMessage(MessageEvent event) {

    try {
      JsonObject decodedMessage = new JsonObject.fromJsonString(event.data);

      if (_isConfirmation(decodedMessage)) {
        _finalizeMessage(decodedMessage);
        return event;
      }

      // ak ide o potvrdenie spravy, tak to je sprava iba pre mna a moje Futures
      if (decodedMessage.containsKey('body')) {
        MessageEvent modifiedEvent = new MessageEvent(
            event.type,
            cancelable: false,
            data: decodedMessage['body'],
            origin: event.origin,
            lastEventId: '');

        return modifiedEvent;
      } else {
        throw new FormatException();
      }
    } on FormatException {
      _log.warning('Malformatted message received');
      return null;
    }
  }
}

