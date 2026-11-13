import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/instances_screen.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';

void main() {
  const pricing = InstancePricing(
    softwareMonthlyChargeCents: 500000,
    hostingMonthlyCostCents: 2000,
    hostingMonthlyChargeCents: 60000,
    domainAnnualCostCents: 20000,
    domainAnnualChargeCents: 100000,
  );

  setUp(() {
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  tearDown(() {
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  String createCustomer(String name) {
    final result = MasterCustomerRegistry.register(legalName: name);

    return result.customer!.id;
  }

  InstanceRegistrationResult createInstance({
    required String customerId,
    String name = 'Sede principal',
    String productCode = 'adn-carwash',
    String planCode = 'basico',
    String domain = 'ejemplo.hn',
    String hostingProvider = 'Hosting de prueba',
  }) {
    return MasterInstanceRegistry.register(
      name: name,
      customerId: customerId,
      productCode: productCode,
      planCode: planCode,
      domain: domain,
      hostingProvider: hostingProvider,
      pricing: pricing,
    );
  }

  group('Software Master - Registro de instancias', () {
    test('Registra una instancia sin activar licencia', () {
      final customerId = createCustomer('Empresa A');

      final result = createInstance(customerId: customerId);

      expect(result.success, isTrue);
      expect(result.instance?.id, 'INS-0001');
      expect(result.instance?.customerId, customerId);

      expect(result.instance?.statusLabel, 'Borrador local · Sin licencia');

      expect(MasterInstanceRegistry.all.length, 1);

      expect(result.instance?.pricing.customerAnnualChargeCents, 6820000);
    });

    test('Rechaza nombres duplicados del mismo cliente y producto', () {
      final customerId = createCustomer('Empresa A');

      createInstance(customerId: customerId);

      final duplicate = createInstance(
        customerId: customerId,
        name: 'SEDE PRINCIPAL',
        domain: 'otro.hn',
      );

      expect(duplicate.status, InstanceRegistrationStatus.duplicateName);

      expect(MasterInstanceRegistry.all.length, 1);
    });

    test('Impide reutilizar un dominio', () {
      final firstCustomer = createCustomer('Empresa A');
      final secondCustomer = createCustomer('Empresa B');

      createInstance(customerId: firstCustomer, domain: 'MiDominio.HN');

      final duplicate = createInstance(
        customerId: secondCustomer,
        domain: 'midominio.hn',
      );

      expect(duplicate.status, InstanceRegistrationStatus.duplicateDomain);

      expect(MasterInstanceRegistry.all.length, 1);
    });

    test('Diferentes clientes pueden usar nombres de instancia iguales', () {
      final firstCustomer = createCustomer('Empresa A');
      final secondCustomer = createCustomer('Empresa B');

      final first = createInstance(customerId: firstCustomer, domain: 'a.hn');

      final second = createInstance(customerId: secondCustomer, domain: 'b.hn');

      expect(first.success, isTrue);
      expect(second.success, isTrue);
      expect(MasterInstanceRegistry.all.length, 2);
    });

    test('Rechaza clientes inexistentes', () {
      final result = createInstance(customerId: 'CLI-INEXISTENTE');

      expect(result.status, InstanceRegistrationStatus.unknownCustomer);

      expect(MasterInstanceRegistry.all, isEmpty);
    });

    test('Rechaza planes inexistentes', () {
      final customerId = createCustomer('Empresa A');

      final result = createInstance(
        customerId: customerId,
        planCode: 'plan-inexistente',
      );

      expect(result.status, InstanceRegistrationStatus.invalidPlan);
    });

    test('Rechaza productos no registrados', () {
      final customerId = createCustomer('Empresa A');

      final result = createInstance(
        customerId: customerId,
        productCode: 'producto-inexistente',
      );

      expect(result.status, InstanceRegistrationStatus.unknownProduct);
    });

    test('Rechaza dominios invalidos', () {
      final customerId = createCustomer('Empresa A');

      final result = createInstance(
        customerId: customerId,
        domain: 'https://ejemplo.hn/ruta',
      );

      expect(result.status, InstanceRegistrationStatus.invalidDomain);
    });
  });

  group('Software Master - Formulario de instancias', () {
    Future<void> openForm(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstancesScreen())),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva instancia'));

      await tester.pumpAndSettle();
    }

    testWidgets('No guarda sin seleccionar cliente', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('instance_name')),
        'Sede de prueba',
      );

      await tester.tap(find.byKey(const Key('instance_save_session')));

      await tester.pumpAndSettle();

      expect(MasterInstanceRegistry.all, isEmpty);

      expect(find.byType(InstanceFormDialog), findsOneWidget);
    });

    testWidgets('Guarda y muestra una instancia en el directorio', (
      WidgetTester tester,
    ) async {
      createCustomer('Empresa de Prueba');

      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('instance_name')),
        'Sede principal',
      );

      final customerSelector = find.byKey(const Key('instance_customer'));

      await tester.tap(customerSelector);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Empresa de Prueba').last);

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('instance_domain')),
        'sede.hn',
      );

      final amounts = <Key, String>{
        const Key('instance_software_fee'): '5000',
        const Key('instance_host_cost'): '20',
        const Key('instance_host_charge'): '600',
        const Key('instance_domain_cost'): '200',
        const Key('instance_domain_charge'): '1000',
      };

      for (final entry in amounts.entries) {
        final field = find.byKey(entry.key);

        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }

      final save = find.byKey(const Key('instance_save_session'));

      await tester.ensureVisible(save);
      await tester.pumpAndSettle();

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(InstanceFormDialog), findsNothing);

      expect(MasterInstanceRegistry.all.length, 1);

      expect(find.byKey(const Key('instance_record_INS-0001')), findsOneWidget);

      expect(find.text('Borrador local · Sin licencia'), findsOneWidget);
    });
  });
}
