import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/console/master_commercial_console.dart';
import 'package:adn_carwash_master/features/customers/companies_customer_hub.dart';
import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';

void main() {
  setUp(() {
    MasterCustomerRegistry.resetForTesting();
  });

  tearDown(() {
    MasterCustomerRegistry.resetForTesting();
  });

  Future<void> openCustomers(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 950));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MasterCustomersScreen())),
    );

    await tester.pumpAndSettle();
  }

  group('Software Master - Empresas', () {
    testWidgets('Abre el directorio actual desde el menu', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      final sidebar = find.byType(MasterSidebar);

      final scrollable = find.descendant(
        of: sidebar,
        matching: find.byType(Scrollable),
      );

      final option = find.widgetWithText(InkWell, 'Empresas');

      await tester.scrollUntilVisible(
        option,
        150.0,
        scrollable: scrollable,
        maxScrolls: 20,
      );

      await tester.pumpAndSettle();

      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(find.byType(MasterCustomersScreen), findsOneWidget);

      expect(find.text('Directorio de clientes'), findsOneWidget);
    });

    testWidgets('No muestra clientes inexistentes', (
      WidgetTester tester,
    ) async {
      await openCustomers(tester);

      expect(find.text('Sin clientes registrados'), findsOneWidget);

      expect(find.text('Clientes registrados en sesión: 0'), findsOneWidget);
    });

    testWidgets('Exige el nombre al registrar cliente', (
      WidgetTester tester,
    ) async {
      await openCustomers(tester);

      await tester.tap(find.byKey(const Key('unified_customer_add')));

      await tester.pumpAndSettle();

      expect(find.byType(MasterCustomerFormDialog), findsOneWidget);

      final save = find.byKey(const Key('master_customer_save'));

      await tester.ensureVisible(save);
      await tester.pumpAndSettle();

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el nombre del cliente.'), findsOneWidget);

      expect(MasterCustomerRegistry.all, isEmpty);
    });

    testWidgets('Registra y muestra un cliente en el directorio', (
      WidgetTester tester,
    ) async {
      await openCustomers(tester);

      await tester.tap(find.byKey(const Key('unified_customer_add')));

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('customer_legal_name')),
        'Empresa de Prueba',
      );

      await tester.enterText(
        find.byKey(const Key('customer_trade_name')),
        'Negocio de Prueba',
      );

      final save = find.byKey(const Key('master_customer_save'));

      await tester.ensureVisible(save);
      await tester.pumpAndSettle();

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(MasterCustomerFormDialog), findsNothing);

      expect(MasterCustomerRegistry.all.length, 1);

      expect(
        find.byKey(const Key('unified_customer_CLI-0001')),
        findsOneWidget,
      );

      expect(find.text('Negocio de Prueba'), findsOneWidget);
    });

    test('Rechaza clientes con nombre legal duplicado', () {
      final first = MasterCustomerRegistry.register(
        legalName: 'Empresa de Prueba',
      );

      final second = MasterCustomerRegistry.register(
        legalName: ' EMPRESA DE PRUEBA ',
      );

      expect(first.success, isTrue);

      expect(second.status, CustomerRegistrationStatus.duplicate);

      expect(MasterCustomerRegistry.all.length, 1);
    });
  });
}
