part of connection_manager;

abstract class Transport {

  static const int CLOSED = 3;
  static const int CLOSING = 2;
  static const int CONNECTING = 0;
  static const int OPEN = 1;

  Future<bool> get supported;

  int get readyState;
  String get url;
  String get humanType;

  Stream<OpenEvent> get onOpen;
  Stream<MessageEvent> get onMessage;
  Stream<ErrorEvent> get onError;
  Stream<CloseEvent> get onClose;

  Transport(String host, [settings]);

  void connect();
  void disconnect([int code, String reason, bool forceDisconnect]);

  void send(String data);
}
