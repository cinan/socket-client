part of client_tests;

void retryAsync(Function callback) {
  List<int> waitTimes = [1, 50, 100, 250, 500, 1000, 5000];

  Iterator<int> iter = waitTimes.iterator;
  iter.moveNext();

  _retry(callback, iter);
}

void _retry(Function callback, Iterator<int> waitTimeIter) {
  int waitTime = waitTimeIter.current;
  Duration duration = new Duration(milliseconds: waitTime);

  new Timer(duration, expectAsync(() {
    try {
      callback();
    } on TestFailure catch(e) {
      if (!waitTimeIter.moveNext()) {
        throw e;
      }
      _retry(callback, waitTimeIter);
    }
  }));
}