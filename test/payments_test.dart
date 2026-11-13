import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscription_registry.dart';
import 'package:adn_carwash_master/features/payments/billing_preview_registry.dart';
import 'package:adn_carwash_master/features/payments/master_billing_screen.dart';

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

  String createSubscription() {
    final customer = MasterCustomerRegistry.register(legalName: 'Empresa A');

    expect(customer.success, isTrue);

    final instance = MasterInstanceRegistry.register(
      name: 'Sede principal',
      customerId: customer.customer!.id,
      productCode: 'adn-carwash',
      planCode: 'basico',
      domain: 'sede.hn',
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

  Future<void> openBilling(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 950));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MasterBillingScreen())),
    );

    await tester.pumpAndSettle();
  }

  Future<void> selectSubscription(WidgetTester tester) async {
    final field = find.byKey(const Key('billing_subscription'));

    await tester.ensureVisible(field);
    await tester.pumpAndSettle();

    await tester.tap(field);
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUS-0001 · Sede principal').last);

    await tester.pumpAndSettle();
  }

  Future<void> createMonthlyCharge(WidgetTester tester) async {
    await selectSubscription(tester);

    final button = find.byKey(const Key('billing_create_charge'));

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('Software Master - Pagos y cobros', () {
    testWidgets('Abre la pantalla actual desde el menu', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      final sidebar = find.byType(MasterSidebar);

      final scrollable = find
          .descendant(of: sidebar, matching: find.byType(Scrollable))
          .first;

      final option = find.descendant(
        of: sidebar,
        matching: find.widgetWithText(InkWell, 'Pagos'),
      );

      await tester.scrollUntilVisible(
        option,
        150.0,
        scrollable: scrollable,
        maxScrolls: 20,
      );

      await tester.pumpAndSettle();

      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(find.byType(MasterBillingScreen), findsOneWidget);

      expect(find.text('Pagos y cobros'), findsOneWidget);
    });

    testWidgets('No permite crear cargos sin suscripciones', (
      WidgetTester tester,
    ) async {
      await openBilling(tester);

      expect(find.text('Sin cargos de prueba'), findsOneWidget);

      expect(find.text('Cargos de prueba: 0'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('billing_create_charge')),
      );

      expect(button.onPressed, isNull);

      expect(BillingPreviewRegistry.all, isEmpty);
    });

    testWidgets('Prepara un cargo mensual desde una suscripcion', (
      WidgetTester tester,
    ) async {
      createSubscription();

      await openBilling(tester);
      await createMonthlyCharge(tester);

      expect(BillingPreviewRegistry.all.length, 1);

      expect(BillingPreviewRegistry.all.first.amountCents, 560000);

      expect(find.byKey(const Key('billing_charge_CAR-0001')), findsOneWidget);

      expect(find.text('Cargos de prueba: 1'), findsOneWidget);
    });

    testWidgets('Impide duplicar el primer cargo mensual', (
      WidgetTester tester,
    ) async {
      createSubscription();

      await openBilling(tester);
      await createMonthlyCharge(tester);

      final button = find.byKey(const Key('billing_create_charge'));

      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(BillingPreviewRegistry.all.length, 1);
    });

    testWidgets('Calcula el saldo después de un abono parcial', (
      WidgetTester tester,
    ) async {
      final subscriptionId = createSubscription();

      final result = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      expect(result.success, isTrue);

      await openBilling(tester);

      final amount = find.byKey(const Key('billing_payment_CAR-0001'));

      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();

      await tester.enterText(amount, '2000');

      final apply = find.byKey(const Key('billing_apply_CAR-0001'));

      await tester.ensureVisible(apply);
      await tester.pumpAndSettle();

      await tester.tap(apply);
      await tester.pumpAndSettle();

      final charge = BillingPreviewRegistry.findById('CAR-0001')!;

      expect(charge.simulatedPaidCents, 200000);

      expect(charge.simulatedBalanceCents, 360000);

      expect(find.text('Abono parcial simulado'), findsOneWidget);
    });

    testWidgets('Rechaza un abono mayor que el saldo', (
      WidgetTester tester,
    ) async {
      final subscriptionId = createSubscription();

      BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      await openBilling(tester);

      final amount = find.byKey(const Key('billing_payment_CAR-0001'));

      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();

      await tester.enterText(amount, '6000');

      final apply = find.byKey(const Key('billing_apply_CAR-0001'));

      await tester.ensureVisible(apply);
      await tester.pumpAndSettle();

      await tester.tap(apply);
      await tester.pumpAndSettle();

      final charge = BillingPreviewRegistry.findById('CAR-0001')!;

      expect(charge.simulatedPaidCents, 0);

      expect(charge.simulatedBalanceCents, 560000);
    });

    testWidgets('Permite completar el cargo sin excederlo', (
      WidgetTester tester,
    ) async {
      final subscriptionId = createSubscription();

      BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      await openBilling(tester);

      final amount = find.byKey(const Key('billing_payment_CAR-0001'));

      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();

      await tester.enterText(amount, '5600');

      final apply = find.byKey(const Key('billing_apply_CAR-0001'));

      await tester.ensureVisible(apply);
      await tester.pumpAndSettle();

      await tester.tap(apply);
      await tester.pumpAndSettle();

      final charge = BillingPreviewRegistry.findById('CAR-0001')!;

      expect(charge.simulatedBalanceCents, 0);

      expect(charge.status, 'Cubierto en simulación');

      expect(find.text('Cubierto en simulación'), findsOneWidget);
    });
  });
}
