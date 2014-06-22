part of connection_manager;

class CloseEvent extends Event {

  int get code      => _code;
  String get reason => _reason;

  int _code;
  String _reason;

  CloseEvent([this._code = 0, this._reason = '']) : super('close');

  CloseEvent.fromExisting(CloseEvent event, {preserveTimestamp: false})
    : super.fromExisting(event, preserveTimestamp: preserveTimestamp),
      _code = event.code,
      _reason = event.reason;

  CloseEvent.fromExistingHtmlEvent(Html.CloseEvent event)
    : super.fromExistingHtmlEvent(event),
      _code = event.code,
      _reason = event.reason {
    _type = 'close';
  }
}
