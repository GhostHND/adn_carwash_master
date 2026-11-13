import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/plans/master_api_plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('creates and reloads a draft plan through the API', (
    tester,
  ) async {
    final requests = <http.Request>[];
    Map<String, dynamic>? storedPlan;
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/products')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'product-id',
                  'code': 'adn-carwash',
                  'name': 'ADN CarWash',
                  'status': 'draft',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'POST' && request.url.path.endsWith('/plans')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          storedPlan = {
            'id': 'plan-id',
            'product_id': 'product-id',
            'product_code': body['product_code'],
            'code': body['code'],
            'name': body['name'],
            'price_cents': body['price_cents'],
            'currency': body['currency'],
            'billing_period': body['billing_period'],
            'status': body['status'],
            'features': body['features'],
          };
          return http.Response(
            jsonEncode({'data': storedPlan}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(
          jsonEncode({
            'data': storedPlan == null ? [] : [storedPlan],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiPlansScreen(apiClient: client)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Aún no hay planes en la base de datos.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nuevo plan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('plan_code')), 'basico');
    await tester.enterText(find.byKey(const Key('plan_name')), 'Básico');
    await tester.tap(find.byKey(const Key('plan_save')));
    await tester.pumpAndSettle();

    expect(find.text('Básico'), findsOneWidget);
    expect(find.textContaining('Precio por definir'), findsOneWidget);
    expect(
      requests.any(
        (request) =>
            request.method == 'POST' &&
            request.url.path.endsWith('/plans') &&
            jsonDecode(request.body)['price_cents'] == null,
      ),
      isTrue,
    );
  });
}
