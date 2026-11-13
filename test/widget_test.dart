import 'dart:convert';

import 'package:adn_carwash_master/features/console/master_commercial_console.dart';
import 'package:adn_carwash_master/features/payments/master_api_billing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:adn_carwash_master/core/master_identity.dart';
import 'package:adn_carwash_master/core/master_api_client.dart';
import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/plans/plans_screen.dart';
import 'package:adn_carwash_master/features/products/software_products_screen.dart';

void main() {
  testWidgets('Suscripciones autenticadas usan las instancias de la API', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final apiClient = MasterApiClient(
      baseUrl: 'https://master.test/api/v1',
      httpClient: MockClient((request) async {
        final data = request.url.path.endsWith('/instances')
            ? [
                {
                  'id': 'instance-id',
                  'name': 'Guza - Principal',
                  'customer': {'id': 'customer-id', 'name': 'GUZA'},
                },
              ]
            : [];
        return http.Response(
          jsonEncode({'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(apiClient.dispose);
    await tester.pumpWidget(AdnCarWashMaster(apiClient: apiClient));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MasterSidebar),
        matching: find.widgetWithText(InkWell, 'Suscripciones'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MasterApiBillingScreen), findsOneWidget);
    await tester.tap(find.text('Nueva suscripción'));
    await tester.pumpAndSettle();
    expect(find.text('Guza - Principal · GUZA'), findsOneWidget);
  });

  testWidgets('La barra distingue una sesión API de la vista local', (
    tester,
  ) async {
    Widget topBar(MasterUser? user) => MaterialApp(
      home: Scaffold(
        body: MasterTopBar(
          isMobile: false,
          onOpenMenu: () {},
          onOpenGuide: () {},
          currentUser: user,
        ),
      ),
    );

    await tester.pumpWidget(topBar(null));
    expect(find.text('VISTA LOCAL'), findsOneWidget);

    await tester.pumpWidget(
      topBar(
        const MasterUser(id: 1, name: 'Admin', email: 'admin@example.test'),
      ),
    );
    expect(find.text('SESIÓN API'), findsOneWidget);
    expect(find.text('VISTA LOCAL'), findsNothing);
  });

  group('ADN Publicidad Software Master', () {
    Future<void> openDesktop(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();
    }

    testWidgets('El dashboard muestra la identidad general', (
      WidgetTester tester,
    ) async {
      await openDesktop(tester);

      expect(find.text(MasterIdentity.fullName), findsOneWidget);

      expect(find.byType(MasterDashboard), findsOneWidget);

      expect(find.text('Panel general'), findsOneWidget);

      expect(find.text('Instancias recientes'), findsOneWidget);
    });

    testWidgets('El menu abre el catalogo de software', (
      WidgetTester tester,
    ) async {
      await openDesktop(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Productos de software'));

      await tester.pumpAndSettle();

      expect(find.byType(SoftwareProductsScreen), findsOneWidget);

      expect(find.text('Catálogo de productos'), findsOneWidget);
    });

    testWidgets('El menu conserva el modulo Empresas', (
      WidgetTester tester,
    ) async {
      await openDesktop(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Empresas'));

      await tester.pumpAndSettle();

      expect(find.byType(MasterCustomersScreen), findsOneWidget);

      expect(find.text('Directorio de clientes'), findsOneWidget);
    });

    testWidgets('El menu conserva los planes', (WidgetTester tester) async {
      await openDesktop(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Planes'));

      await tester.pumpAndSettle();

      expect(find.byType(PlansScreen), findsOneWidget);

      expect(find.text('Básico'), findsWidgets);

      expect(find.text('Intermedio'), findsWidgets);

      expect(find.text('Pro'), findsWidgets);
    });

    testWidgets('El dashboard utiliza navegacion movil', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      expect(find.byTooltip('Abrir menú'), findsOneWidget);

      expect(find.text('Panel general'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
