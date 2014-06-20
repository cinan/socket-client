part of connection_manager;

class OpenEvent extends Event {

  OpenEvent() : super('open');

  OpenEvent.fromExisting(MessageEvent event, {preserveTimestamp: false})
    : super.fromExisting(event, preserveTimestamp: preserveTimestamp),
      _data = event.data,
      _origin = event.origin;

  OpenEvent.fromExistingHtmlEvent(Html.Event event)
    : super.fromExistingHtmlEvent(event) {
    _type = 'open';
  }
}
