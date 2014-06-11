part of client_tests;

pollingTransportTests() {
  String url = 'http://localhost:4040/polling';
  PollingTestingTransport t;

  setUp(() {
    t = new PollingTestingTransport(url);
  });

  tearDown(() {
    t.disconnect();
  });

  test('state is closed', () {
    expect(t.readyState, Transport.CLOSED);
  });

  test('if is supported', () {
    retryAsync(() {
      bool isSupported = false;
      t.supported.then(expectAsync((bool result) {
        isSupported = result;
      })).whenComplete(() {
        expect(isSupported, isTrue);
      });
    });
  });

  test('after connecting is state OPEN', () {
    int state = -1;

    t.onOpen.listen((_) {
      state = t.readyState;
    });

    t.connect();

    retryAsync(() => expect(state, Transport.OPEN));
  });

  test('after disconnecting is state CLOSED', () {
    int state = -1;

    t.onOpen.listen((_) {
      t.disconnect();
    });

    t.onClose.listen((_) {
      state = t.readyState;
    });

    t.connect();

    retryAsync(() => expect(state, Transport.CLOSED));
  });

  test('close connection if server is not responding', () {
    t.pollingInteral = new Duration(milliseconds: 100);

    var emitEvent;

    t.onOpen.listen((_) {
      t.invokeTimeout();
    });

    t.onClose.listen((e) {
      emitEvent = e;
    });

    t.connect();

    retryAsync(() {
      expect(emitEvent, isNotNull);
      expect(emitEvent.type, 'close');
      expect(t.readyState, Transport.CLOSED);
    });
  });

  test('new request is not made until the previous one is completed', () {
    t.pollingInteral = new Duration(milliseconds: 200);
    t.connect();

    bool hasRun = false;

    t.onOpen.listen((_) {
      String message = new JsonObject.fromMap({'type': 'test'}).toString();

      // wait for requests and responses
      new Timer(new Duration(milliseconds: 500), expectAsync(() {
        t.responseTime(new Duration(milliseconds: 300));

        t.send(message);
        expect(t.inQueue, isEmpty);

        t.send(message);
        expect(t.inQueue, hasLength(1));

        hasRun = true;
      }));
    });

    retryAsync(() => expect(hasRun, isTrue));
  });
}