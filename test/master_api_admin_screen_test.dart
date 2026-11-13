import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/master_users/master_api_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Carga el directorio de usuarios desde el servidor', (
    tester,
  ) async {
    final client = await _authenticatedClient();
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MasterApiAdminScreen(
          apiClient: client,
          mode: MasterAdminMode.users,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usuarios Master'), findsOneWidget);
    expect(find.text('No hay usuarios registrados.'), findsOneWidget);
  });

  testWidgets('Carga el catálogo de roles conectado a permisos del servidor', (
    tester,
  ) async {
    final client = await _authenticatedClient();
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MasterApiAdminScreen(
          apiClient: client,
          mode: MasterAdminMode.roles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roles y permisos'), findsOneWidget);
    expect(find.text('No hay roles registrados.'), findsOneWidget);
  });
}

Future<MasterApiClient> _authenticatedClient() async {
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
  await client.login(email: 'admin@test', password: 'secret');
  return client;
}
