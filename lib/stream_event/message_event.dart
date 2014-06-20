part of connection_manager;

class MessageEvent extends Event {

  final Object _data;
  final String _origin;

  Object get data   => _data;
  String get origin => _origin;

  MessageEvent(Object this._data, [String this._origin = '']) : super('message');

  MessageEvent.fromExisting(MessageEvent event, {preserveTimestamp: false})
    : super.fromExisting(event, preserveTimestamp: preserveTimestamp),
      _data = event.data,
      _origin = event.origin;

  MessageEvent.fromExistingHtmlEvent(Html.MessageEvent event)
    : super.fromExistingHtmlEvent(event),
      _data = event.data,
      _origin = event.origin {
    _type = 'message';
  }
}
