import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/system/master_api_audit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Muestra la bitácora del servidor sin inventar eventos', (
    tester,
  ) async {
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'data': {
                'token': 'test-token',
                'user': {'id': 7, 'name': 'Admin', 'email': 'admin@test'},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({
            'data': [],
            'meta': {'last_page': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await client.login(email: 'admin@test', password: 'secret');

    await tester.pumpWidget(
      MaterialApp(home: MasterApiAuditScreen(apiClient: client)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auditoría del servidor'), findsOneWidget);
    expect(find.text('Sin eventos registrados.'), findsOneWidget);
  });
}
