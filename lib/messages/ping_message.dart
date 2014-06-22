part of connection_manager;

class PingMessage extends Message {

  Map<String, dynamic> get data => {
      'type': 'ping',
  };

  static matches(Map map) => map['type'] == 'ping';
}