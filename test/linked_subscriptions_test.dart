import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscription_registry.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscriptions_hub.dart';
import 'package:adn_carwash_master/features/subscriptions/subscriptions_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// PRUEBAS DE SUSCRIPCIONES VINCULADAS
// ============================================================

void main() {
  const pricing = InstancePricing(
    softwareMonthlyChargeCents: 500000,
    hostingMonthlyCostCents: 2000,
    hostingMonthlyChargeCents: 60000,
    domainAnnualCostCents: 20000,
    domainAnnualChargeCents: 100000,
  );

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

  String createInstance({
    String name = 'Sede principal',
    String domain = 'sede.hn',
    InstancePricing instancePricing = pricing,
  }) {
    final customer = MasterCustomerRegistry.register(legalName: 'Empresa A');

    final customerId = customer.success
        ? customer.customer!.id
        : MasterCustomerRegistry.all.first.id;

    final instance = MasterInstanceRegistry.register(
      name: name,
      customerId: customerId,
      productCode: 'adn-carwash',
      planCode: 'basico',
      domain: domain,
      hostingProvider: 'Hosting de prueba',
      pricing: instancePricing,
    );

    expect(instance.success, isTrue);

    return instance.instance!.id;
  }

  LinkedSubscriptionResult saveDraft(
    String instanceId, {
    DateTime? monthlyDue,
    DateTime? domainDue,
  }) {
    return LinkedSubscriptionRegistry.register(
      instanceId: instanceId,
      firstMonthlyDueDate: monthlyDue ?? DateTime(2026, 11, 15),
      firstDomainDueDate: domainDue ?? DateTime(2027, 1, 10),
    );
  }

  group('Software Master - Suscripciones vinculadas', () {
    test('Registra una suscripcion sin activar licencia', () {
      final instanceId = createInstance();

      final result = saveDraft(instanceId);

      expect(result.success, isTrue);
      expect(result.draft?.id, 'SUS-0001');
      expect(result.draft?.instanceId, instanceId);

      expect(result.draft?.statusLabel, 'Borrador · Sin facturar');

      expect(LinkedSubscriptionRegistry.all.length, 1);
    });

    test('Mantiene separados los cargos mensuales y anuales', () {
      final instanceId = createInstance();
      final draft = saveDraft(instanceId).draft!;

      expect(draft.softwareMonthlyChargeCents, 500000);

      expect(draft.hostingMonthlyChargeCents, 60000);

      expect(draft.monthlyChargeCents, 560000);

      expect(draft.domainAnnualChargeCents, 100000);

      expect(draft.annualProjectionCents, 6820000);
    });

    test('Rechaza una instancia inexistente', () {
      final result = saveDraft('INS-INEXISTENTE');

      expect(result.status, LinkedSubscriptionResultStatus.unknownInstance);

      expect(LinkedSubscriptionRegistry.all, isEmpty);
    });

    test('Exige la primera fecha de cobro mensual', () {
      final instanceId = createInstance();

      final result = LinkedSubscriptionRegistry.register(
        instanceId: instanceId,
        firstMonthlyDueDate: null,
        firstDomainDueDate: DateTime(2027, 1, 10),
      );

      expect(
        result.status,
        LinkedSubscriptionResultStatus.missingMonthlyDueDate,
      );
    });

    test('Exige fecha anual si el dominio tiene cargo', () {
      final instanceId = createInstance();

      final result = LinkedSubscriptionRegistry.register(
        instanceId: instanceId,
        firstMonthlyDueDate: DateTime(2026, 11, 15),
        firstDomainDueDate: null,
      );

      expect(
        result.status,
        LinkedSubscriptionResultStatus.missingDomainDueDate,
      );
    });

    test('Permite no cobrar dominio cuando su cargo es cero', () {
      const noDomainCharge = InstancePricing(
        softwareMonthlyChargeCents: 500000,
        hostingMonthlyCostCents: 2000,
        hostingMonthlyChargeCents: 60000,
        domainAnnualCostCents: 0,
        domainAnnualChargeCents: 0,
      );

      final instanceId = createInstance(instancePricing: noDomainCharge);

      final result = LinkedSubscriptionRegistry.register(
        instanceId: instanceId,
        firstMonthlyDueDate: DateTime(2026, 11, 15),
        firstDomainDueDate: null,
      );

      expect(result.success, isTrue);
      expect(result.draft?.firstDomainDueDate, isNull);
      expect(result.draft?.annualProjectionCents, 6720000);
    });

    test('Impide duplicar suscripcion para una instancia', () {
      final instanceId = createInstance();

      final first = saveDraft(instanceId);
      final second = saveDraft(instanceId);

      expect(first.success, isTrue);

      expect(
        second.status,
        LinkedSubscriptionResultStatus.duplicateSubscription,
      );

      expect(LinkedSubscriptionRegistry.all.length, 1);
    });

    test('Permite diferentes instancias del mismo cliente', () {
      final firstId = createInstance();

      final secondId = createInstance(
        name: 'Segunda sede',
        domain: 'segunda.hn',
      );

      expect(saveDraft(firstId).success, isTrue);
      expect(saveDraft(secondId).success, isTrue);

      expect(LinkedSubscriptionRegistry.all.length, 2);
    });

    test('Conserva fechas normalizadas sin horas', () {
      final instanceId = createInstance();

      final result = LinkedSubscriptionRegistry.register(
        instanceId: instanceId,
        firstMonthlyDueDate: DateTime(2026, 11, 15, 22, 30),
        firstDomainDueDate: DateTime(2027, 1, 10, 15, 45),
      );

      expect(result.success, isTrue);

      expect(result.draft?.firstMonthlyDueDate, DateTime.utc(2026, 11, 15));

      expect(result.draft?.firstDomainDueDate, DateTime.utc(2027, 1, 10));
    });
  });

  group('Software Master - Interfaz de Suscripciones', () {
    Future<void> openHub(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LinkedSubscriptionsHub())),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('Conserva el modulo anterior de Suscripciones', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      expect(find.byType(SubscriptionsScreen), findsOneWidget);

      expect(find.text('Suscripciones vinculadas'), findsOneWidget);

      expect(find.text('Borradores locales: 0'), findsOneWidget);
    });

    testWidgets('Sin instancias no permite crear suscripcion', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      await tester.tap(find.byKey(const Key('linked_subscription_add')));

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

    testWidgets('Guarda un borrador vinculado desde el formulario', (
      WidgetTester tester,
    ) async {
      createInstance();

      await openHub(tester);

      await tester.tap(find.byKey(const Key('linked_subscription_add')));

      await tester.pumpAndSettle();

      final instanceField = find.byKey(
        const Key('linked_subscription_instance'),
      );

      await tester.tap(instanceField);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sede principal · Empresa A').last);

      await tester.pumpAndSettle();

      final monthlyDate = find.byKey(
        const Key('linked_subscription_monthly_due'),
      );

      await tester.ensureVisible(monthlyDate);
      await tester.pumpAndSettle();

      await tester.enterText(monthlyDate, '15/11/2026');

      final domainDate = find.byKey(
        const Key('linked_subscription_domain_due'),
      );

      await tester.ensureVisible(domainDate);
      await tester.pumpAndSettle();

      await tester.enterText(domainDate, '10/01/2027');

      await tester.tap(find.byKey(const Key('linked_subscription_save')));

      await tester.pumpAndSettle();

      expect(find.byType(LinkedSubscriptionFormDialog), findsNothing);

      expect(LinkedSubscriptionRegistry.all.length, 1);

      expect(
        find.byKey(const Key('linked_subscription_record_SUS-0001')),
        findsOneWidget,
      );
    });
  });
}
