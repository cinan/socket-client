part of connection_manager;

class Messager extends Object with EventControllersAndStreams {

  bool get connected        => _caller.connected;

  String get transportName  => _caller.transportName;

  LinkedHashMap<int, Message> _messageBuffer    = new LinkedHashMap<int, Message>();
  MessageContainer            _messageContainer = new MessageContainer();
  Map<int, Completer>         _completers       = new Map<dynamic, Completer>();

  Caller _caller = new Caller();
  int _nextSendId = 0;

  Logger _log = new Logger('Messager');

  Messager();

  void registerConnection(int priority, TransportBuilder connection) {
    _caller.registerConnection(priority, connection);
  }

  void connect() {
    _caller.connect();
    _setupListeners();
  }

  Future<int> send(data) {
    _nextSendId++;

    DataMessage message = new DataMessage(_nextSendId);
    message.body = data;

    _log.info('adding to the message queue: $message');
    _messageBuffer[_nextSendId] = message;
    _completers[_nextSendId] = new Completer<int>();

    _messageContainer.add(message);

    new Future.delayed(Duration.ZERO, () {
      if (_messageContainer.isEmpty)
        return;

      _messageContainer.length > 1
        ? _caller.send(_messageContainer.wrapped.toString())
        : _caller.send(_messageContainer.first.toString());

      _messageContainer.clear();
    });

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
    _caller.onOpen.pipe(new MyStreamConsumer(_onOpenController, _onOpenProcess));
    _caller.onMessage.pipe(new MyStreamConsumer(_onMessageController, _onMessageProcess));
    _caller.onError.pipe(new MyStreamConsumer(_onErrorController, _onErrorProcess));
    _caller.onClose.pipe(new MyStreamConsumer(_onCloseController, _onCloseProcess));
  }

  OpenEvent _onOpenProcess(OpenEvent event) {
    _log.info('som (znova) pripojeny, odosielam neodoslane spravy');
    _sendMessageBuffer();

    return event;
  }

  MessageEvent _onMessageProcess(MessageEvent event) {
    return _decodeMessageEvent(event);
  }

  ErrorEvent _onErrorProcess(ErrorEvent event) => event;
  CloseEvent _onCloseProcess(CloseEvent event) => event;

  void _sendMessageBuffer() {
    for (Message msg in _messageBuffer.values) {
      _caller.send(msg.toString());
    }
  }

  MessageEvent _decodeMessageEvent(MessageEvent event) {
    try {
      JsonObject decodedMessage = new JsonObject.fromJsonString(event.data);

      if (ConfirmationMessage.matches(decodedMessage)) {
        _finalizeMessage(decodedMessage);
        return null;
      }

      // ak ide o potvrdenie spravy, tak to je sprava iba pre mna a moje Futures
      if (decodedMessage.containsKey('body')) {
        return new MessageEvent.fromExisting(event, preserveTimestamp: true);
      } else {
        throw new FormatException();
      }
    } on FormatException {
      _log.warning('Malformatted message received');
      return null;
    }
  }
}

