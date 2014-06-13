part of client_tests;

heartbeatTests() {
  group('heartbeat tests', () {
    Heart heart;

    setUp(() {
      heart = new Heart(new Duration(milliseconds: 100));
    });

    tearDown(() {
    });

    test('heart is in calm after creation', () {
      expect(heart.isBeating, isFalse);
    });

    test('heart is beating after heartbeat started', () {
      heart.startBeating();
      expect(heart.isBeating, isTrue);
    });

    test('heart has stopped after heartbeat stopped', () {
      heart.startBeating();
      heart.die();
      expect(heart.isBeating, isFalse);
    });

    test('after start beats are sent periodically', () {
      int i = 0;
      int j = 0;

      heart.beatCallback = (_) => i++;
      heart.startBeating();

      new Timer.periodic(new Duration(milliseconds: 80), expectAsync((Timer t) {
        heart.addResponse();
        j++;

        if (j == 10) {
          t.cancel();
        }
      }, count: 10));

      retryAsync(() => expect(i, greaterThan(8)));
    });

    test('action after response is received', () {
      bool done = false;
      heart.responseCallback = (_) {
        done = true;
      };

      heart.startBeating();
      heart.addResponse();

      expect(done, isTrue);
    });

    test('death message callback is called if no pongs are received', () {
      bool deathHappened = false;
      int i = 0;

      heart.deathMessageCallback = () {
        deathHappened = true;
      };

      heart.startBeating();

      new Timer.periodic(new Duration(milliseconds: 80), expectAsync((Timer t) {
        heart.addResponse();
        i++;

        if (i == 10) {
          t.cancel();

          expect(heart.isBeating, isTrue);

          new Timer(new Duration(milliseconds: 500), expectAsync(() {
            expect(heart.isBeating, isFalse);
            expect(deathHappened, isTrue);
          }));
        }
      }, count: 10));
    });
  });
}