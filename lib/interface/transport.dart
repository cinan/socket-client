part of connection_manager;

abstract class Transport {

  static const int CLOSED = 3;
  static const int CLOSING = 2;
  static const int CONNECTING = 0;
  static const int OPEN = 1;

  bool get supported;

  int get readyState;
  String get url;
  String get humanType;

  Stream<Event> get onOpen;
  Stream<MessageEvent> get onMessage;
  Stream<Event> get onError;
  Stream<CloseEvent> get onClose;

  Transport(String host, [settings]);

  void connect();
  void disconnect([int code, String reason]);

  void send(data);
}
