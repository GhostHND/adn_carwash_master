import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/customers/companies_customer_hub.dart';
import 'package:adn_carwash_master/features/instances/instances_screen.dart';

void main() {
  setUp(() {
    MasterCustomerRegistry.resetForTesting();
  });

  tearDown(() {
    MasterCustomerRegistry.resetForTesting();
  });

  // ==========================================================
  // REGLAS DEL REGISTRO
  // ==========================================================

  group('Software Master - Registro de clientes', () {
    test('Registra un cliente con identificador único', () {
      final result = MasterCustomerRegistry.register(
        legalName: 'Empresa de Prueba S. de R.L.',
        tradeName: 'Negocio de Prueba',
        email: 'contacto@ejemplo.com',
      );

      expect(result.success, isTrue);

      expect(result.customer?.id, 'CLI-0001');

      expect(result.customer?.displayName, 'Negocio de Prueba');

      expect(MasterCustomerRegistry.all.length, 1);
    });

    test('Impide registrar nombres legales duplicados', () {
      MasterCustomerRegistry.register(legalName: 'Empresa de Prueba');

      final duplicate = MasterCustomerRegistry.register(
        legalName: '  EMPRESA DE PRUEBA  ',
      );

      expect(duplicate.status, CustomerRegistrationStatus.duplicate);

      expect(MasterCustomerRegistry.all.length, 1);
    });

    test('Rechaza registros sin nombre o con correo inválido', () {
      final withoutName = MasterCustomerRegistry.register(legalName: '');

      final invalidEmail = MasterCustomerRegistry.register(
        legalName: 'Empresa Ejemplo',
        email: 'correo-invalido',
      );

      expect(withoutName.status, CustomerRegistrationStatus.invalidName);

      expect(invalidEmail.status, CustomerRegistrationStatus.invalidEmail);

      expect(MasterCustomerRegistry.all, isEmpty);
    });

    test('Permite consultar clientes por identificador', () {
      final registered = MasterCustomerRegistry.register(
        legalName: 'Cliente de Prueba',
      );

      final id = registered.customer!.id;

      expect(
        MasterCustomerRegistry.findById(id)?.legalName,
        'Cliente de Prueba',
      );

      expect(MasterCustomerRegistry.findById('CLI-INEXISTENTE'), isNull);
    });
  });

  // ==========================================================
  // INTEGRACION VISUAL
  // ==========================================================

  group('Software Master - Empresas e Instancias', () {
    Future<void> openCompanies(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CompaniesCustomerHub())),
      );

      await tester.pumpAndSettle();
    }

    Future<void> registerFromDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('master_customer_add')));

      await tester.pumpAndSettle();

      expect(find.byType(MasterCustomerFormDialog), findsOneWidget);

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
    }

    testWidgets('Empresas conserva su pantalla anterior', (
      WidgetTester tester,
    ) async {
      await openCompanies(tester);

      expect(find.text('Clientes de Software Master'), findsOneWidget);

      expect(find.byKey(const Key('master_customer_add')), findsOneWidget);

      expect(MasterCustomerRegistry.all, isEmpty);
    });

    testWidgets('Un cliente registrado aparece en Instancias', (
      WidgetTester tester,
    ) async {
      await openCompanies(tester);

      await registerFromDialog(tester);

      expect(MasterCustomerRegistry.all.length, 1);

      expect(find.text('Clientes en esta sesión: 1'), findsOneWidget);

      // Cambiamos de pantalla sin cerrar la aplicación.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstancesScreen())),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva instancia'));

      await tester.pumpAndSettle();

      final customerSelector = find.byKey(const Key('instance_customer'));

      expect(customerSelector, findsOneWidget);

      await tester.tap(customerSelector);
      await tester.pumpAndSettle();

      expect(find.text('Negocio de Prueba'), findsWidgets);

      await tester.tap(find.text('Negocio de Prueba').last);

      await tester.pumpAndSettle();

      final selected = tester.state<FormFieldState<String>>(customerSelector);

      expect(selected.value, 'CLI-0001');
    });
  });
}
