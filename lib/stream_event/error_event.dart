part of connection_manager;

class ErrorEvent extends Event {

  int get errNo   => _errNo;
  int get message => _message;

  int _errNo;
  String _message;

  ErrorEvent([this._errNo = 0, this._message = '']) : super('error');

  ErrorEvent.fromExisting(ErrorEvent event, {preserveTimestamp: false})
    : super.fromExisting(event, preserveTimestamp: preserveTimestamp),
      _errNo = event.errNo,
      _message = event.message;

  ErrorEvent.fromExistingHtmlEvent(Html.Event event, [int this._errNo = 0, String this._message = ''])
    : super.fromExistingHtmlEvent(event) {
    _type = 'error';
  }

}
