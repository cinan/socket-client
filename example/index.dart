import 'dart:async';
import 'dart:html';
import 'package:client/connection_manager.dart' hide MessageEvent, OpenEvent, CloseEvent, ErrorEvent;
import 'package:client/connection_manager.dart' as CM show MessageEvent, OpenEvent, CloseEvent, ErrorEvent;
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.loggerName} ${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  ConnectionManager cm = new ConnectionManager();
  cm.registerConnection(0, () => new WebsocketTransport('ws://localhost:4040/ws'));
//  cm.registerConnection(0, () => new PollingTransport('http://localhost:4040/polling'));

  cm.connect();

  cm.onOpen.listen((CM.OpenEvent e) {
    print('I\'m opened');
  });

  cm.onMessage.listen((CM.MessageEvent e) {
    print('Message received:');
    print(e.data);
  });

  cm.onClose.listen((e) {
    print('closed');
  });

  cm.send({
      'type': 'sync',
      'data': ['pulp', 'fiction']
  }).then((id) {
    print('spravu s ideckom $id server prijal!');
  });

  var i = 0;
//  new Timer.periodic(new Duration(seconds: 1), (timer) {
//    cm.send('test $i').then((id) {
//      print('spravu s ideckom $id server prijal!');
//    });
//    i++;
//  });
}