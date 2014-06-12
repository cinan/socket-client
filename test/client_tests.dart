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
part 'connection_manager_tests.dart';
part 'polling_transport_tests.dart';
part 'websocket_transport_tests.dart';
part 'heartbeat_tests.dart';

main() {
  useHtmlConfiguration();

  connectionManagerTests();
  pollingTransportTests();
  websocketTransportTests();
  heartbeatTests();
}