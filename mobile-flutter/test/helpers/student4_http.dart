import 'dart:convert';

import 'package:chargesync/core/api/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void prepareStudent4Test() {
  FlutterSecureStorage.setMockInitialValues({
    ApiConfig.kAccessToken: 'test-token',
  });
  GoogleFonts.config.allowRuntimeFetching = false;
}

http.Response jsonResponse(Object? data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> showTestScreen(WidgetTester tester, Widget screen) async {
  // A tall viewport keeps checkout and confirmation controls visible.
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
  await tester.pumpAndSettle();
}
