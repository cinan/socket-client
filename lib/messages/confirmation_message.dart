part of connection_manager;

class ConfirmationMessage extends Message {

  int _id;

  get id => _id;

  int confirmID;

  Map<String, dynamic> get data => {
      'type': 'confirm',
      'id':   _id,
      'body': {
        'confirmID': confirmID
      }
  };

  ConfirmationMessage(int this._id);

  static matches(Map map) =>
    map['type'] == 'confirm' &&
    (map['id'] is int || int.parse(map['id'], onError: (_) => false) != false) &&
    map['body'] is Map &&
    (map['body']['confirmID'] is int || int.parse(map['body']['confirmID'], onError: (_) => false) != false);
}