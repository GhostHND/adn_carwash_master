import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/features/customers/master_api_customers_screen.dart';
import 'package:adn_carwash_master/features/products/master_api_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Muestra productos cargados desde la API', (tester) async {
    final apiClient = await _authenticatedClient((request) async {
      expect(request.url.path, endsWith('/products'));
      return _collectionResponse([
        {
          'id': 'product-1',
          'code': 'adn-fidelidad',
          'name': 'ADN Fidelidad',
          'category': 'Fidelización',
          'description': 'Programas de fidelidad.',
          'status': 'draft',
        },
      ]);
    });
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiProductsScreen(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ADN Fidelidad'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
  });

  testWidgets('El servidor valida códigos del catálogo al crear productos', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final apiClient = await _authenticatedClient((request) async {
      if (request.method == 'POST') {
        saved = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return http.Response(
          jsonEncode({'data': saved}),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return _collectionResponse([]);
    });
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiProductsScreen(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product_name')),
      'ADN CarWash',
    );
    await tester.enterText(
      find.byKey(const Key('product_code')),
      'adn-carwash',
    );
    await tester.enterText(
      find.byKey(const Key('product_category')),
      'Servicios',
    );
    await tester.ensureVisible(find.byKey(const Key('product_validate')));
    await tester.tap(find.byKey(const Key('product_validate')));
    await tester.pumpAndSettle();

    expect(saved?['code'], 'adn-carwash');
    expect(saved?['status'], 'draft');
  });

  testWidgets('Activa un producto borrador y actualiza el catálogo', (
    tester,
  ) async {
    var status = 'draft';
    var patches = 0;
    final apiClient = await _authenticatedClient((request) async {
      if (request.method == 'PATCH') {
        expect(request.url.path, endsWith('/products/product-1'));
        expect(jsonDecode(request.body), {'status': 'active'});
        patches++;
        status = 'active';
        return http.Response(
          jsonEncode({
            'data': {'status': status},
          }),
          200,
        );
      }
      return _collectionResponse([
        {
          'id': 'product-1',
          'code': 'adn-fidelidad',
          'name': 'ADN Fidelidad',
          'status': status,
        },
      ]);
    });
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiProductsScreen(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(patches, 0);

    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
    await tester.pumpAndSettle();

    expect(patches, 1);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Producto activado.'), findsOneWidget);
    expect(find.text('Activar'), findsNothing);
  });

  testWidgets('Muestra el error del servidor si no se puede activar', (
    tester,
  ) async {
    final apiClient = await _authenticatedClient((request) async {
      if (request.method == 'PATCH') {
        return http.Response(
          jsonEncode({'message': 'Operación no autorizada.'}),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return _collectionResponse([
        {
          'id': 'product-1',
          'code': 'adn-fidelidad',
          'name': 'ADN Fidelidad',
          'status': 'draft',
        },
      ]);
    });
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiProductsScreen(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
    await tester.pumpAndSettle();

    expect(find.text('Operación no autorizada.'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
  });

  testWidgets('Muestra clientes cargados desde la API', (tester) async {
    final apiClient = await _authenticatedClient((request) async {
      expect(request.url.path, endsWith('/customers'));
      return _collectionResponse([
        {
          'id': 'customer-1',
          'legal_name': 'Lavado Ejemplo S.A.',
          'trade_name': 'CarWash Centro',
          'email': 'contacto@ejemplo.test',
          'phone': '5550000',
          'status': 'active',
        },
      ]);
    });
    addTearDown(apiClient.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterApiCustomersScreen(apiClient: apiClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CarWash Centro'), findsOneWidget);
    expect(find.textContaining('contacto@ejemplo.test'), findsOneWidget);
  });
}

Future<MasterApiClient> _authenticatedClient(
  Future<http.Response> Function(http.Request request) collectionHandler,
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

      expect(request.headers['authorization'], 'Bearer test-token');
      return collectionHandler(request);
    }),
  );
  await client.login(email: 'admin@test', password: 'secret');
  return client;
}

http.Response _collectionResponse(List<Map<String, dynamic>> data) {
  return http.Response(
    jsonEncode({
      'data': data,
      'meta': {'last_page': 1},
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}
