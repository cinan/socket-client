part of connection_manager;

class Event {

  String _type;
  final int _timestamp;

  int get type      => _type;
  int get timestamp => _timestamp;

  Event(String this._type)
    : _timestamp = new DateTime.now().millisecondsSinceEpoch;

  Event.fromExisting(MessageEvent event, {preserveTimestamp: false})
    : _timestamp = preserveTimestamp ? event.timestamp : new DateTime.now().millisecondsSinceEpoch,
      _type = event.type;

  Event.fromExistingHtmlEvent(Html.Event event)
    : _timestamp = event.timeStamp;
}
