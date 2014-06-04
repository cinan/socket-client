library connection_manager;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:logging/logging.dart';

part 'interface/transport.dart';

part 'wrapper/messager.dart';
part 'wrapper/caller.dart';

part 'transport_finder.dart';
part 'transport/transport_websocket.dart';
part 'transport/transport_websocket_testing.dart';

typedef Transport TransportBuilder();

class ConnectionManager {

  Messager _messager;

  ConnectionManager() {
    _messager = new Messager();
  }

  bool get connected => _messager.connected;

  Stream<dynamic> get onError => _messager.onError;

  Stream<dynamic> get onOpen => _messager.onOpen;

  Stream<dynamic> get onMessage => _messager.onMessage;

  Stream<dynamic> get onClose => _messager.onClose;

  void registerConnection(int priority, TransportBuilder connection) {
    _messager.registerConnection(priority, connection);
  }

  void connect() {
    _messager.connect();
  }

  Future send(data) {
    return _messager.send(data);
  }

  void disconnect() {
    _messager.disconnect();
  }

}
