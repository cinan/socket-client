part of client_tests;

websocketTransportTests() {
  group('websocket transport tests', () {

    String url = 'ws://dartserver.dev:4040/ws';
    WebsocketTestingTransport t;

    setUp(() {
      t = new WebsocketTestingTransport(url);
    });

    tearDown(() {
      t.disconnect();
    });

    test('state is closed right after construct', () {
      expect(t.readyState, Transport.CLOSED);
    });

    test('disconnect if server is not responding', () {
      t.pollingInterval = new Duration(milliseconds: 100);
      t.connect();

      bool hasRun = false;

      t.onOpen.listen((_) {
        t.responseTime(new Duration(milliseconds: 500));

        new Timer(new Duration(seconds: 1), expectAsync(() {
          hasRun = true;
          expect(t.readyState, Transport.CLOSED);
        }));
      });

      retryAsync(() => expect(hasRun, isTrue));
    });
  });
}