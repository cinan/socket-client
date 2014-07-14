part of connection_manager;

class Messager extends Object with EventControllersAndStreams {

  bool get connected        => _caller.connected;
  String get transportName  => _caller.transportName;

  LinkedHashMap<int, Message> _messageBuffer    = new LinkedHashMap<int, Message>();
  Map<int, Completer>         _completers       = new Map<dynamic, Completer>();
  MessageContainer            _messageContainer = new MessageContainer();

  Caller _caller = new Caller();
  int _nextSendId = 0;

  Logger _log = new Logger('Messager');

  void registerConnection(int priority, TransportBuilder connection) {
    _caller.registerConnection(priority, connection);
  }

  void connect() {
    _caller.connect();
    _setupListeners();
  }

  Future<int> send(dynamic data) {
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

      if (_messageContainer.length > 1) {
        print('sending package');
        _caller.send(_messageContainer.wrapped.toString());
      } else {
        print('sending one');
        _caller.send(_messageContainer.first.toString());
      }

      _messageContainer.clear();
    });

    return _completers[_nextSendId].future;
  }

  void disconnect() {
    _caller.disconnect();
  }

  void _finalizeMessage(int messageID) {
    if (_completers.containsKey(messageID)) {
      _completers[messageID].complete(messageID);
      _completers.remove(messageID);
    }

    _messageBuffer.remove(messageID);
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

  void _onMessageProcess(MessageEvent event) {
    JsonObject decodedMessage;
    try {
      decodedMessage = new JsonObject.fromJsonString(event.data);
      _decodeMessageEvent(decodedMessage, event);
    } on FormatException {
      _log.warning('Malformatted message received');
    }
  }

  ErrorEvent _onErrorProcess(ErrorEvent event) => event;
  CloseEvent _onCloseProcess(CloseEvent event) => event;

  void _sendMessageBuffer() {
    MessageContainer container = new MessageContainer();
    for (Message msg in _messageBuffer.values) {
      container.add(msg);
    }

    if (container.isNotEmpty) {
      _caller.send(container.wrapped.toString());
    }
  }

  void _decodeMessageEvent(JsonObject decodedMessage, MessageEvent event) {
    if (ConfirmationMessage.matches(decodedMessage)) {
      _finalizeMessage(decodedMessage['body']['confirmID']);
      return null;
    }

    if (DataMessage.matches(decodedMessage)) {
      MessageEvent e = new MessageEvent(decodedMessage['body'], event.origin);
      _onMessageController.add(e);

      _sendConfirmation(decodedMessage['id']);
    } else if (MessageContainer.matches(decodedMessage)) {
      decodedMessage['messages'].forEach((Message m) {
        _decodeMessageEvent(m, event);
      });
    }
  }

  void _sendConfirmation(int messageID) {
    _log.info('sending confirmation to $messageID');

    ConfirmationMessage confirmation = new ConfirmationMessage(_nextSendId++);
    confirmation.confirmID = messageID;
    _caller.send(confirmation.toString());
  }
}

