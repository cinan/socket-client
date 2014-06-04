library client_tests;

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:mock/mock.dart';

import 'package:logging/logging.dart';

import '../lib/connection_manager.dart';

part 'connection_manager_tests.dart';
part 'async_helper.dart';

main() {
  useHtmlConfiguration();

  connection_manager_tests();
}