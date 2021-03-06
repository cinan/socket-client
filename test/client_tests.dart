library client_tests;

import 'dart:html' hide Event, MessageEvent, CloseEvent, ErrorEvent;
import 'dart:html' as Html show Event, MessageEvent, CloseEvent, ErrorEvent;
import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:mock/mock.dart';
import 'package:json_object/json_object.dart';
import 'package:cookie/cookie.dart' as cookie;
import 'package:logging/logging.dart';

import '../lib/connection_manager.dart';

part 'async_helper.dart';

part 'transport_finder_tests.dart';
part 'connection_manager_tests.dart';
part 'polling_transport_tests.dart';
part 'websocket_transport_tests.dart';
part 'heartbeat_tests.dart';
part 'stream_event_objects_tests.dart';

main() {
  bool verboseConsole = false;

  if (verboseConsole) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.loggerName} ${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  useHtmlEnhancedConfiguration();

  transportFinderTests();
  connectionManagerTests();
  pollingTransportTests();
  websocketTransportTests();
  heartbeatTests();
  streamEventObjectsTests();
}

disconnect(Transport t) {
  t.disconnect(1000, 'disconnect', true);
}