part of client_tests;

pollingTransportTests() {
  group('polling transport tests', () {

    String url = 'http://dartserver.dev:4040/polling';
    PollingTestingTransport t;

    setUp(() {
      t = new PollingTestingTransport(url);
      t.pollingInterval = new Duration(milliseconds: 100);
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
      bool wasOpened = false;

      t.onOpen.listen((_) {
        wasOpened = true;
        t.disconnect(1000, 'disconnect', true);
      });

      t.onClose.listen((_) {
        state = t.readyState;
      });

      t.connect();

      retryAsync(() {
        expect(wasOpened, isTrue);
        expect(state, Transport.CLOSED);
      });
    });

    test('new request is not made until the previous one is completed', () {
      t.connect();

      bool hasRun = false;

      t.onOpen.listen((_) {
        String message = new JsonObject.fromMap({
            'type': 'test'
        }).toString();

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
  });
}