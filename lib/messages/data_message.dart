part of connection_manager;

class DataMessage extends Message {

  int _id;

  dynamic body;

  int get id => _id;

  Map<String, dynamic> get data => {
    'type': 'msg',
    'id':   _id,
    'body': body
  };

  DataMessage(int this._id);

  static matches(Map map) =>
    map['type'] == 'msg' &&
    map.containsKey('body') &&
    map.containsKey('id') &&
    (map['id'] is int || int.parse(map['id'], onError: (_) => false) != false);
}