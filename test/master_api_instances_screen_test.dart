import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/instances/master_api_instances_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('creates and reloads a draft instance through the API', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final requests = <http.Request>[];
    Map<String, dynamic>? storedInstance;
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/customers')) {
          return _jsonResponse({
            'data': [
              {
                'id': 'customer-id',
                'legal_name': 'ADN Cliente',
                'status': 'active',
              },
            ],
          });
        }
        if (path.endsWith('/products')) {
          return _jsonResponse({
            'data': [
              {
                'id': 'product-id',
                'code': 'adn-carwash',
                'name': 'ADN CarWash',
                'status': 'draft',
              },
            ],
          });
        }
        if (path.endsWith('/plans')) {
          return _jsonResponse({
            'data': [
              {
                'id': 'plan-id',
                'product_id': 'product-id',
                'product_code': 'adn-carwash',
                'code': 'basic',
                'name': 'Básico',
                'status': 'draft',
              },
            ],
          });
        }
        if (request.method == 'POST' && path.endsWith('/instances')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          storedInstance = {
            'id': 'instance-id',
            'name': body['name'],
            'domain': body['domain'],
            'provisioning_status': 'draft',
            'customer': {'id': body['customer_id'], 'name': 'ADN Cliente'},
            'product': {'code': body['product_code'], 'name': 'ADN CarWash'},
            'plan': {'id': body['plan_id'], 'name': 'Básico'},
            'infrastructure': body['infrastructure'],
          };
          return _jsonResponse({'data': storedInstance}, statusCode: 201);
        }
        if (request.method == 'PATCH' &&
            path.endsWith('/instances/instance-id')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          storedInstance = {
            ...storedInstance!,
            ...body,
            'customer': {'id': 'customer-id', 'name': 'ADN Cliente'},
            'product': {'code': 'adn-carwash', 'name': 'ADN CarWash'},
            'plan': {'id': 'plan-id', 'name': 'Básico'},
          };
          return _jsonResponse({'data': storedInstance});
        }

        return _jsonResponse({
          'data': storedInstance == null ? [] : [storedInstance],
        });
      }),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiInstancesScreen(apiClient: client)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No hay instancias registradas'),
      findsOneWidget,
    );
    await tester.tap(find.text('Nueva instancia'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('api_instance_name')),
      'Sede principal',
    );
    await tester.enterText(
      find.byKey(const Key('api_instance_domain')),
      'sede.example.hn',
    );
    await tester.tap(find.byKey(const Key('api_instance_save')));
    await tester.pumpAndSettle();

    expect(find.text('Sede principal'), findsOneWidget);
    expect(find.textContaining('sede.example.hn'), findsOneWidget);
    final createRequest = requests.firstWhere(
      (request) =>
          request.method == 'POST' && request.url.path.endsWith('/instances'),
    );
    final body = jsonDecode(createRequest.body) as Map<String, dynamic>;
    expect(body['customer_id'], 'customer-id');
    expect(body['plan_id'], 'plan-id');
    expect(body['infrastructure']['hosting_cost_cents'], 0);
    expect(body['infrastructure']['domain_charge_cents'], 0);

    await tester.tap(find.byTooltip('Editar instancia'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('api_instance_name')),
      'Sede actualizada',
    );
    await tester.tap(find.byKey(const Key('api_instance_save')));
    await tester.pumpAndSettle();

    expect(find.text('Sede actualizada'), findsOneWidget);
    final updateRequest = requests.firstWhere(
      (request) =>
          request.method == 'PATCH' &&
          request.url.path.endsWith('/instances/instance-id'),
    );
    expect(
      (jsonDecode(updateRequest.body) as Map<String, dynamic>)['name'],
      'Sede actualizada',
    );
  });

  testWidgets('links the selected Fidelidad business and reports errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var linkAttempts = 0;
    final requests = <http.Request>[];
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/fidelidad/search')) {
          return _jsonResponse({
            'data': [
              {
                'uuid': 'business-id',
                'name': 'GUZA',
                'master_business_id': null,
              },
              {
                'uuid': 'other-id',
                'name': 'Otro',
                'master_business_id': 'other-instance',
              },
            ],
          });
        }
        if (path.endsWith('/fidelidad/link')) {
          linkAttempts++;
          if (linkAttempts == 1) {
            return _jsonResponse({
              'message': 'No se pudo vincular.',
              'errors': {
                'fidelidad': ['Conflicto de vinculación.'],
              },
            }, statusCode: 422);
          }
          return _jsonResponse({
            'data': {'uuid': 'business-id'},
          });
        }
        if (path.endsWith('/instances')) {
          return _jsonResponse({
            'data': [
              {
                'id': 'instance-id',
                'name': 'Instancia GUZA',
                'provisioning_status': 'draft',
                'product': {'code': 'adn-fidelidad', 'name': 'Fidelidad'},
              },
            ],
          });
        }
        return _jsonResponse({'data': []});
      }),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiInstancesScreen(apiClient: client)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vincular Fidelidad'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GUZA');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Vinculado a otra instancia'), findsOneWidget);
    final buttons = tester
        .widgetList<TextButton>(find.widgetWithText(TextButton, 'Seleccionar'))
        .toList();
    expect(buttons[0].onPressed, isNotNull);
    expect(buttons[1].onPressed, isNull);

    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.tap(find.text('Seleccionar').first);
      await tester.pumpAndSettle();
      expect(find.text('Confirmar vinculación'), findsOneWidget);
      await tester.tap(find.text('Vincular'));
      await tester.pumpAndSettle();
      if (attempt == 0) {
        expect(
          find.textContaining('Conflicto de vinculación.'),
          findsOneWidget,
        );
      }
    }
    expect(find.textContaining('Negocio vinculado.'), findsOneWidget);
    final linkRequest = requests.lastWhere(
      (request) => request.url.path.endsWith('/fidelidad/link'),
    );
    expect(jsonDecode(linkRequest.body)['business_uuid'], 'business-id');
  });
}

http.Response _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
