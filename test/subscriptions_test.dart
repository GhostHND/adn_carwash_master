import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/console/master_commercial_console.dart';
import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscription_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscriptions_hub.dart';

void main() {
  setUp(() {
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  tearDown(() {
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
  });

  void createInstance() {
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
  }

  Future<void> openSubscriptions(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 950));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MasterSubscriptionsScreen())),
    );

    await tester.pumpAndSettle();
  }

  group('Software Master - Suscripciones', () {
    testWidgets('Abre la pantalla unificada desde el menu', (
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
        matching: find.widgetWithText(InkWell, 'Suscripciones'),
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

      expect(find.byType(MasterSubscriptionsScreen), findsOneWidget);

      expect(find.text('Directorio de suscripciones'), findsOneWidget);
    });

    testWidgets('No registra una suscripcion sin instancia', (
      WidgetTester tester,
    ) async {
      await openSubscriptions(tester);

      await tester.tap(find.byKey(const Key('unified_subscription_add')));

      await tester.pumpAndSettle();

      expect(find.byType(LinkedSubscriptionFormDialog), findsOneWidget);

      expect(
        find.textContaining('Primero registra un cliente'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('linked_subscription_save')));

      await tester.pumpAndSettle();

      expect(LinkedSubscriptionRegistry.all, isEmpty);
    });

    testWidgets('Cancelar no crea suscripciones', (WidgetTester tester) async {
      await openSubscriptions(tester);

      await tester.tap(find.byKey(const Key('unified_subscription_add')));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(LinkedSubscriptionFormDialog), findsNothing);

      expect(find.text('Sin suscripciones vinculadas'), findsOneWidget);

      expect(LinkedSubscriptionRegistry.all, isEmpty);
    });

    testWidgets('Guarda la suscripcion vinculada a una instancia', (
      WidgetTester tester,
    ) async {
      createInstance();

      await openSubscriptions(tester);

      await tester.tap(find.byKey(const Key('unified_subscription_add')));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('linked_subscription_instance')));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Sede principal · Empresa A').last);

      await tester.pumpAndSettle();

      final monthly = find.byKey(const Key('linked_subscription_monthly_due'));

      await tester.ensureVisible(monthly);
      await tester.pumpAndSettle();

      await tester.enterText(monthly, '15/11/2026');

      final domain = find.byKey(const Key('linked_subscription_domain_due'));

      await tester.ensureVisible(domain);
      await tester.pumpAndSettle();

      await tester.enterText(domain, '10/01/2027');

      final save = find.byKey(const Key('linked_subscription_save'));

      await tester.ensureVisible(save);
      await tester.pumpAndSettle();

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.byType(LinkedSubscriptionFormDialog), findsNothing);

      expect(LinkedSubscriptionRegistry.all.length, 1);

      expect(
        find.byKey(const Key('unified_subscription_SUS-0001')),
        findsOneWidget,
      );

      expect(LinkedSubscriptionRegistry.all.first.monthlyChargeCents, 560000);
    });
  });
}
