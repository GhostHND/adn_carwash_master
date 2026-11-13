import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/payments/master_api_billing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Carga la facturación persistida desde la API autenticada', (
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
      MaterialApp(home: MasterApiBillingScreen(apiClient: client)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suscripciones y facturación'), findsOneWidget);
    expect(find.text('No hay suscripciones.'), findsOneWidget);
    expect(find.text('No hay cargos.'), findsOneWidget);
    expect(find.text('No hay pagos registrados.'), findsOneWidget);
  });

  testWidgets('Permite anular un cargo sin eliminarlo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var status = 'issued';
    Map<String, dynamic>? voidBody;
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/void')) {
          voidBody = jsonDecode(request.body) as Map<String, dynamic>;
          status = 'void';
          return http.Response(jsonEncode({'data': {}}), 200);
        }
        final data = path.endsWith('/charges')
            ? [
                {
                  'id': 'charge-id',
                  'subscription_id': 'subscription-id',
                  'concept': 'Cargo inicial',
                  'status': status,
                  'currency': 'HNL',
                  'amount_cents': 60000,
                  'allocated_cents': 0,
                  'due_date': '2026-11-04',
                },
              ]
            : [];
        return http.Response(jsonEncode({'data': data}), 200);
      }),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiBillingScreen(apiClient: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anular'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motivo de anulación'),
      'Fecha incorrecta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anular cargo'));
    await tester.pumpAndSettle();

    expect(voidBody, {'reason': 'Fecha incorrecta'});
    expect(find.textContaining('Cargo inicial · Anulado'), findsOneWidget);
    expect(find.text('Anular'), findsNothing);
  });
}
