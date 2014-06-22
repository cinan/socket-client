part of connection_manager;

class EventControllersAndStreams {

  StreamController<OpenEvent>    _onOpenController     = new StreamController<OpenEvent>();
  Stream<OpenEvent>              get onOpen            => _onOpenController.stream;

  StreamController<MessageEvent> _onMessageController  = new StreamController<MessageEvent>();
  Stream<MessageEvent>           get onMessage         => _onMessageController.stream;

  StreamController<ErrorEvent>   _onErrorController    = new StreamController<ErrorEvent>();
  Stream<ErrorEvent>             get onError           => _onErrorController.stream;

  StreamController<CloseEvent>   _onCloseController    = new StreamController<CloseEvent>();
  Stream<CloseEvent>             get onClose           => _onCloseController.stream;

}