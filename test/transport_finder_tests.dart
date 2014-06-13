part of client_tests;

transportFinderTests() {
  group('transport finder tests', () {

    TransportFinder tf;

    WebsocketTransport ws;
    PollingTransport ps;

    String wsUrl = 'ws://localhost:4040/ws';
    String psUrl = 'http://localhost:4040/polling';

    setUp(() {
      tf = new TransportFinder();

      ws = new WebsocketTransport(wsUrl);
      ps = new PollingTransport(psUrl);
    });

    test('transports are sorted by priority into iterable', () {
      Map transports = {0: ws, 10: ps };
      tf.transports = transports;

      expect(tf.sortedTransports.length, equals(2));
      expect(tf.sortedTransports.first['conn'], equals(ws));
      expect(tf.sortedTransports.first['isSupported'], isNull);
      expect(tf.sortedTransports.last['conn'], equals(ps));
      expect(tf.sortedTransports.last['isSupported'], isNull);
    });

    test('find connection if transports are all right', () {
      Map transports = {0: () => ps, 10: () => ws };
      tf.transports = transports;

      Future<TransportBuilder> fc = tf.findConnection();

      retryAsync(() => fc.then((TransportBuilder t) {
        expect(t().humanType, equals('polling'));

        disconnect(ps);
        disconnect(ws);
      }));
    });

    test('find connection with unreachable most preferred transport', () {
      WebsocketTestingTransport ws = new WebsocketTestingTransport(psUrl);
      ws.supported = false;

      Map transports = {0: () => ws, 10: () => ps };
      tf.transports = transports;

      Future<TransportBuilder> fc = tf.findConnection();

      retryAsync(() => fc.then((TransportBuilder t) {
        expect(t().humanType, equals('polling'));

        disconnect(ps);
        disconnect(ws);
      }));
    });
  });
}
