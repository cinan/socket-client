part of client_tests;

connectionManagerTests() {
  group('connection manager tests', () {

    String wsUrl = 'ws://localhost:4040/ws';
    String psUrl = 'http://localhost:4040/polling';

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

      retryAsync(() {
        expect(hasRun, isTrue);
        cm.disconnect();
      });
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

      retryAsync(() {
        expect(hasRun, isTrue);
      });
    });

    test('connect and disconnect', () {
      cm.connect();

      cm.onOpen.listen((_) {
        cm.disconnect();
      });

      retryAsync(() {
        expect(cm.connected, isNotNull);
        expect(cm.connected, isFalse);
      });
    });

    test('send many messages in one event loop', () {
      Mock tSpy = new Mock.spy(t);

      bool hasRun = false;

      cm.registerConnection(0, () => tSpy);
      cm.connect();

      cm.onOpen.listen((_) {
        for (int i in [1,2,3,4,5]) {
          cm.send(i);
        }

        retryAsync(() => tSpy.getLogs(callsTo('send')).verify(happenedOnce));
        hasRun = true;
      });

      retryAsync(() => expect(hasRun, isTrue));
    });

//    test('sending message when connected', () {
//      cm.connect();
//
//      bool hasRun = false;
//
//      cm.send('weee').then(expectAsync((_) {
//        hasRun = true;
//      })).whenComplete(expectAsync(() {
//        expect(hasRun, isTrue);
//        cm.disconnect();
//      }));
//    });

//    test('behaviour of sending message when disconnected', () {
//      Mock tSpy = new Mock.spy(t);
//      Completer result = new Completer();
//      cm.registerConnection(0, () => tSpy);
//
//      cm.connect();
//
//      cm.onOpen.listen((_) {
//        tSpy.asDisconnected();
//        cm.send('message for you');
//
//        tSpy.getLogs(callsTo('send')).verify(neverHappened);
//        tSpy.asDisconnected(false);
//
//        cm.disconnect();
//        result.complete();
//      });
//      return result.future; // test pocka, kym skonci tento test
//    });

//    test('switching transports when one transport fails', () {
//      WebsocketTestingTransport ws = new WebsocketTestingTransport(wsUrl);
//      PollingTestingTransport ps = new PollingTestingTransport(psUrl);
//
//      Duration pollingInterval = new Duration(milliseconds: 500);
//      ws.responseTime(pollingInterval);
//      ps.responseTime(pollingInterval);
//
//      cm.registerConnection(0, () => ws);
//      cm.registerConnection(10, () => ps);
//
//      int onOpenCount = 0;
//      int onCloseCount = 0;
//
//      cm.onOpen.listen((_) {
//        onOpenCount++;
//
//        if (onOpenCount == 1) {
//          expect(cm.transportName, equals(ws.humanType));
//
//          ws.supported = false;
//          ws.disconnect(1000, 'disconnect ws', true);
//        } else if (onOpenCount == 2) {
//          expect(cm.transportName, equals(ps.humanType));
//        }
//      });
//
//      cm.onClose.listen((CloseEvent e) {
//        onCloseCount++;
//
//        if (onCloseCount == 1) {
//          expect(e.code, equals(1000));
//        }
//      });
//
//      cm.connect();
//
//      retryAsync(() {
//        expect(onCloseCount, equals(1));
//        expect(onOpenCount, equals(2));
//
//        cm.disconnect();
//      });
//    });
  });
}