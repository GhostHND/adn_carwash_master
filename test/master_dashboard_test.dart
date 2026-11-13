import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/dashboard/master_dashboard_screen.dart';
import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscription_registry.dart';
import 'package:adn_carwash_master/features/payments/billing_preview_registry.dart';

void main() {
  setUp(() {
    BillingPreviewRegistry.resetForTesting();
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  tearDown(() {
    BillingPreviewRegistry.resetForTesting();
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  Future<void> openDashboard(
    WidgetTester tester, {
    ValueChanged<int>? onNavigate,
    Size size = const Size(1440, 1000),
  }) async {
    await tester.binding.setSurfaceSize(size);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MasterDashboardScreen(onNavigate: onNavigate)),
      ),
    );

    await tester.pumpAndSettle();
  }

  String createSubscription() {
    final customer = MasterCustomerRegistry.register(
      legalName: 'Empresa de Prueba',
      tradeName: 'Negocio de Prueba',
    );

    final instance = MasterInstanceRegistry.register(
      name: 'Sede Centro',
      customerId: customer.customer!.id,
      productCode: 'adn-carwash',
      planCode: 'basico',
      domain: 'centro.hn',
      hostingProvider: 'Proveedor de prueba',
      pricing: const InstancePricing(
        softwareMonthlyChargeCents: 500000,
        hostingMonthlyCostCents: 2000,
        hostingMonthlyChargeCents: 60000,
        domainAnnualCostCents: 20000,
        domainAnnualChargeCents: 100000,
      ),
    );

    expect(instance.success, isTrue);

    final subscription = LinkedSubscriptionRegistry.register(
      instanceId: instance.instance!.id,
      firstMonthlyDueDate: DateTime(2026, 11, 15),
      firstDomainDueDate: DateTime(2027, 1, 10),
    );

    expect(subscription.success, isTrue);

    return subscription.draft!.id;
  }

  group('ADN Software Master - Dashboard', () {
    testWidgets('Muestra la identidad y las secciones principales', (
      tester,
    ) async {
      await openDashboard(tester);

      expect(find.text('Panel general'), findsOneWidget);

      expect(find.text('Resumen financiero'), findsOneWidget);

      expect(find.text('Flujo comercial'), findsOneWidget);

      expect(find.text('Estado de la infraestructura'), findsOneWidget);
    });

    testWidgets('No presenta registros ni operaciones inventadas', (
      tester,
    ) async {
      await openDashboard(tester);

      expect(
        find.byKey(const Key('dashboard_empty_instances')),
        findsOneWidget,
      );

      expect(find.text('Sin conectar'), findsOneWidget);

      expect(find.text('L 0.00'), findsWidgets);

      expect(BillingPreviewRegistry.all, isEmpty);
    });

    testWidgets('Muestra una instancia registrada', (tester) async {
      createSubscription();

      await openDashboard(tester);

      expect(find.text('Sede Centro'), findsOneWidget);

      expect(find.text('Negocio de Prueba'), findsOneWidget);

      expect(find.text('1 borradores'), findsWidgets);
    });

    testWidgets('Calcula la proyeccion economica real del borrador', (
      tester,
    ) async {
      createSubscription();

      await openDashboard(tester);

      expect(
        find.byKey(const Key('dashboard_annual_projection')),
        findsOneWidget,
      );

      expect(find.text('L 68200.00'), findsOneWidget);

      expect(find.textContaining('L 5600.00'), findsWidgets);
    });

    testWidgets('Reacciona a nuevos registros sin reiniciar', (tester) async {
      await openDashboard(tester);

      MasterCustomerRegistry.register(legalName: 'Empresa A');

      MasterCustomerRegistry.register(legalName: 'Empresa B');

      await tester.pumpAndSettle();

      expect(find.text('2 registrados'), findsOneWidget);
    });

    testWidgets('Actualiza los cargos y abonos simulados', (tester) async {
      final subscriptionId = createSubscription();

      await openDashboard(tester);

      final result = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      expect(result.success, isTrue);

      BillingPreviewRegistry.simulateAbono(
        chargeId: result.charge!.id,
        amountCents: 200000,
      );

      await tester.pumpAndSettle();

      expect(find.text('L 3600.00'), findsOneWidget);
    });

    testWidgets('Los accesos rapidos envian al modulo correcto', (
      tester,
    ) async {
      final selected = <int>[];

      await openDashboard(tester, onNavigate: selected.add);

      final button = find.byKey(const Key('dashboard_go_2'));

      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(selected, [2]);
    });

    testWidgets('Se adapta a una pantalla de telefono', (tester) async {
      await openDashboard(tester, size: const Size(390, 844));

      expect(find.byType(MasterDashboardScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
