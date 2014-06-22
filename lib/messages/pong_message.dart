part of connection_manager;

class PongMessage extends Message {

  Map<String, dynamic> get data => {
      'type': 'pong',
  };

  static matches(Map map) => map['type'] == 'pong';
}