library connection_manager;

import 'dart:html' hide Event, MessageEvent, CloseEvent, ErrorEvent;
import 'dart:html' as Html show Event, MessageEvent, CloseEvent, ErrorEvent;
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:json_object/json_object.dart';

part 'interface/transport.dart';

part 'wrapper/messager.dart';
part 'wrapper/caller.dart';

part 'stream_event/event.dart';
part 'stream_event/open_event.dart';
part 'stream_event/message_event.dart';
part 'stream_event/error_event.dart';
part 'stream_event/close_event.dart';

part 'heart.dart';
part 'my_stream_consumer.dart';

part 'mixin/event_controllers_and_streams.dart';

part 'transport_finder.dart';
part 'transport/websocket_transport.dart';
part 'transport/polling_transport.dart';

part 'transport/websocket_testing_transport.dart';
part 'transport/polling_testing_transport.dart';

typedef Transport TransportBuilder();

class ConnectionManager {

  Messager _messager;

  String get transportName => _messager.transportName;

  ConnectionManager() {
    _messager = new Messager();
  }

  bool get connected => _messager.connected;

  Stream<OpenEvent>     get onOpen    => _messager.onOpen;
  Stream<MessageEvent>  get onMessage => _messager.onMessage;
  Stream<ErrorEvent>    get onError   => _messager.onError;
  Stream<CloseEvent>    get onClose   => _messager.onClose;

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
