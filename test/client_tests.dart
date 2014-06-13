library client_tests;

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:mock/mock.dart';
import 'package:json_object/json_object.dart';

import 'package:logging/logging.dart';

import '../lib/connection_manager.dart';

part 'async_helper.dart';

part 'transport_finder_tests.dart';
part 'connection_manager_tests.dart';
part 'polling_transport_tests.dart';
part 'websocket_transport_tests.dart';
part 'heartbeat_tests.dart';

main() {
  bool verboseConsole = false;

  if (verboseConsole) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.loggerName} ${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  useHtmlConfiguration();

  transportFinderTests();
  connectionManagerTests();
  pollingTransportTests();
  websocketTransportTests();
  heartbeatTests();
}

disconnect(Transport t) {
  t.disconnect(1000, 'disconnect', true);
}