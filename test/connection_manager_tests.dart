part of client_tests;

connection_manager_tests() {
  String wsUrl = 'ws://localhost:4040/ws';
  ConnectionManager cm;
  WebsocketTestingTransport t;

  setUp(() {
    cm = new ConnectionManager();
    t = new WebsocketTestingTransport(wsUrl);
    cm.registerConnection(0, () => t);
  });

  test('listen to onOpen stream', () {
    bool hasRun = false;

    cm.onOpen.listen((_) {
      hasRun = true;
    });

    cm.connect();

    retryAsync(() => expect(hasRun, isTrue));
  });

  test('listen to onClose stream', () {
    bool hasRun = false;

    cm.onOpen.listen((_) {
      cm.disconnect();
    });

    cm.onClose.listen((_) {
      hasRun = true;
    });

    cm.connect();

    retryAsync(() => expect(hasRun, isTrue));
  });

  // TODO onMessage, onError listener test

  test('connect and disconnect', () {
    bool connected = null;

    cm.connect();

    cm.onOpen.listen((_) {
      cm.disconnect();
      connected = cm.connected;
    });

    retryAsync(() {
      expect(connected, isNotNull);
      expect(connected, isFalse);
    });
  });

  test('sending message when connected', () {
    cm.connect();

    bool hasRun = false;

    cm.send('weee').then(expectAsync((_) {
      hasRun = true;
    })).whenComplete(() {
      expect(hasRun, isTrue);
    });
  });

  test('sending message when disconnected', () {
    Mock tSpy = new Mock.spy(t);
    cm.registerConnection(0, () => tSpy);

    cm.connect();

    cm.onOpen.listen((_) {
      tSpy.asDisconnected();

      cm.send('message for you');
      tSpy.getLogs(callsTo('send')).verify(neverHappened);
    });
  });
}