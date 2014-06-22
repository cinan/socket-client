part of client_tests;

messageConstructorTests() {

  group('message constructor (message type) tests', () {
    DataMessage m;

    test('setting message body', () {
      int id = 3;
      m = new DataMessage(id);

      var body = {'example': 'body'};
      m.body = body;

      expect(m.body, equals(body));
      expect(m.data['type'], equals('msg'));
      expect(m.data['id'], equals(id));
      expect(m.data['body'], equals(body));
    });

    test('matching map object', () {
      Map map = {
        'type': 'msg',
        'id':   '123',
        'body': {}
      };

      expect(DataMessage.matches(map), isTrue);
    });
  });

  group('message constructor (confirmation type) tests', () {
    ConfirmationMessage m;

    test('setting confirmation ID', () {
      int msgID = 4;
      int confirmID = 22;

      m = new ConfirmationMessage(msgID);

      m.confirmID = confirmID;

      expect(m.confirmID, equals(confirmID));
      expect(m.data['type'], equals('confirm'));
      expect(m.data['id'], equals(msgID));
      expect(m.data['body']['confirmID'], equals(confirmID));
    });

    test('matching map object', () {
      Map map = {
          'type': 'confirm',
          'id':   77,
          'body': {
            'confirmID': 78
          }
      };

      expect(ConfirmationMessage.matches(map), isTrue);
    });
  });

  group('message constructor (ping type) tests', () {
    PingMessage m;

    setUp(() {
      m = new PingMessage();
    });

    test('message type is set to `ping`', () {
      expect(m.data['type'], equals('ping'));
    });

    test('matching map object', () {
      Map map = {
          'type': 'ping'
      };

      expect(PingMessage.matches(map), isTrue);
    });
  });

  group('message constructor (pong type) tests', () {
    PingMessage m;

    setUp(() {
      m = new PongMessage();
    });

    test('message type is set to `ping`', () {
      expect(m.data['type'], equals('pong'));
    });

    test('matching map object', () {
      Map map = {
          'type': 'pong'
      };

      expect(PongMessage.matches(map), isTrue);
    });
  });
}