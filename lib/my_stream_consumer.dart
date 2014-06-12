part of connection_manager;

class MyStreamConsumer implements StreamConsumer {

  StreamController _streamController;
  Function _callback;

  MyStreamConsumer(this._streamController, [this._callback]);

  Future addStream(Stream s) {
    s.listen((event) {
      if (_callback != null) {
        event = _callback(event);
      }

      if (event != null) {
        _streamController.add(event);
      }
    });

    return new Completer().future;
  }

  Future close() {
    return _streamController.close();
  }
}
