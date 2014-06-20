part of client_tests;

streamEventObjectsTests() {
  group('stream event objects tests', () {
    test('creating OpenEvent', () {
      OpenEvent e = new OpenEvent();
      expect(e.type, equals('open'));
    });

    test('creating MessageEvent', () {
      MessageEvent e = new MessageEvent('msg', 'ori');
      expect(e.type, equals('message'));
      expect(e.data, equals('msg'));
      expect(e.origin, equals('ori'));
    });

    test('creating ErrorEvent', () {
      ErrorEvent e = new ErrorEvent(500, 'err');
      expect(e.type, equals('error'));
      expect(e.errNo, equals(500));
      expect(e.message, equals('err'));
    });

    test('creating CloseEvent', () {
      CloseEvent e = new CloseEvent(1000, 'exit');
      expect(e.type, equals('close'));
      expect(e.code, equals(1000));
      expect(e.reason, equals('exit'));
    });

    test('duplicate existing MessageEvent', () {
      MessageEvent e = new MessageEvent('msg', 'ori');

      new Timer(new Duration(milliseconds: 1), expectAsync(() {
        MessageEvent ed = new MessageEvent.fromExisting(e);

        expect(ed.type, equals(e.type));
        expect(ed.data, equals(e.data));
        expect(ed.origin, equals(e.origin));
        expect(ed.timestamp, isNot(e.timestamp));
      }));
    });

    test('duplicate existing ErrorEvent with preserving timestamp', () {
      ErrorEvent e = new ErrorEvent(403, 'msg');

      new Timer(new Duration(milliseconds: 1), expectAsync(() {
        ErrorEvent ed = new ErrorEvent.fromExisting(e, preserveTimestamp: true);

        expect(ed.type, equals(e.type));
        expect(ed.errNo, equals(e.errNo));
        expect(ed.message, equals(e.message));
        expect(ed.timestamp, equals(e.timestamp));
      }));
    });

    test('trasform Html.Event to ErrorEvent', () {
      Html.Event e = new Html.Event('type');
      ErrorEvent et = new ErrorEvent.fromExistingHtmlEvent(e, 2, 'err');

      expect(et.type, equals('error'));
      expect(et.errNo, equals(2));
      expect(et.message, equals('err'));
      expect(et.timestamp, equals(e.timeStamp));
    });

    test('trasform Html.MessageEvent to MessageEvent', () {
      Html.MessageEvent e = new Html.MessageEvent('type', origin: 'origin', data: 'bang', lastEventId: '');
      MessageEvent et = new MessageEvent.fromExistingHtmlEvent(e);

      expect(et.type, equals('message'));
      expect(et.data, equals(e.data));
      expect(et.origin, equals(e.origin));
      expect(et.timestamp, equals(e.timeStamp));
    });

    test('trasform Html.Event to OpenEvent', () {
      Html.Event e = new Html.Event('type');
      OpenEvent et = new OpenEvent.fromExistingHtmlEvent(e);

      expect(et.type, equals('open'));
      expect(et.timestamp, equals(e.timeStamp));
    });
  });
}