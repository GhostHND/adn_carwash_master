import 'dart:convert';

import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Login guarda el token en memoria y pagina colecciones autenticadas',
    () async {
      final requests = <http.Request>[];
      final client = MasterApiClient(
        baseUrl: 'https://master.test/api/v1',
        httpClient: MockClient((request) async {
          requests.add(request);
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

          final page = int.parse(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'product-$page'},
              ],
              'meta': {'last_page': 2},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      final user = await client.login(email: 'admin@test', password: 'secret');
      final products = await client.getCollection('products');

      expect(user.name, 'Admin');
      expect(client.isAuthenticated, isTrue);
      expect(products.map((product) => product['id']), [
        'product-1',
        'product-2',
      ]);
      expect(
        requests.where((request) => request.url.path.endsWith('/products')),
        hasLength(2),
      );
      expect(
        requests
            .where((request) => request.url.path.endsWith('/products'))
            .every(
              (request) =>
                  request.headers['authorization'] == 'Bearer test-token',
            ),
        isTrue,
      );
    },
  );

  test('Devuelve error HTTP y errores de validacion en lugar de fallar en silencio', () async {
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'message': 'Los datos no son válidos.',
            'errors': {
              'code': ['El código ya existe.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);

    await expectLater(
      client.post('products', body: const {'code': 'duplicate'}),
      throwsA(
        isA<MasterApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having((error) => error.errors['code'], 'validation error', [
              'El código ya existe.',
            ]),
      ),
    );
  });

  test('PUT envía el cuerpo autenticado para reemplazar partidas', () async {
    http.Request? savedRequest;
    final client = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        savedRequest = request;
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
            'data': {'items': []},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);

    await client.login(email: 'admin@test', password: 'secret');
    await client.put('subscriptions/sub-id/items', body: const {'items': []});

    expect(savedRequest?.method, 'PUT');
    expect(savedRequest?.headers['authorization'], 'Bearer test-token');
    expect(jsonDecode(savedRequest!.body), {'items': []});
  });
}
