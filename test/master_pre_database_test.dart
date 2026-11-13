import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/console/master_commercial_console.dart';
import 'package:adn_carwash_master/features/customers/master_customer_registry.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/master_instance_registry.dart';
import 'package:adn_carwash_master/features/payments/billing_preview_registry.dart';
import 'package:adn_carwash_master/features/payments/master_billing_screen.dart';
import 'package:adn_carwash_master/features/subscriptions/linked_subscription_registry.dart';
import 'package:adn_carwash_master/features/system/master_system_screens.dart';
import 'package:adn_carwash_master/features/system/master_system_settings.dart';

void main() {
  setUp(() {
    BillingPreviewRegistry.resetForTesting();
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
    MasterSystemSettingsStore.resetForTesting();
  });

  tearDown(() {
    BillingPreviewRegistry.resetForTesting();
    LinkedSubscriptionRegistry.resetForTesting();
    MasterInstanceRegistry.resetForTesting();
    MasterCustomerRegistry.resetForTesting();
    MasterSystemSettingsStore.resetForTesting();
  });

  String createSubscription() {
    final customer = MasterCustomerRegistry.register(
      legalName: 'Cliente de prueba',
    );

    final instance = MasterInstanceRegistry.register(
      name: 'Sede principal',
      customerId: customer.customer!.id,
      productCode: 'adn-carwash',
      planCode: 'basico',
      domain: 'prueba.hn',
      hostingProvider: 'Proveedor de prueba',
      pricing: const InstancePricing(
        softwareMonthlyChargeCents: 500000,
        hostingMonthlyCostCents: 2000,
        hostingMonthlyChargeCents: 60000,
        domainAnnualCostCents: 20000,
        domainAnnualChargeCents: 100000,
      ),
    );

    final subscription = LinkedSubscriptionRegistry.register(
      instanceId: instance.instance!.id,
      firstMonthlyDueDate: DateTime(2026, 11, 15),
      firstDomainDueDate: DateTime(2027, 1, 10),
    );

    return subscription.draft!.id;
  }

  group('Software Master - Cargos preliminares', () {
    test('No crea cargos sin suscripción', () {
      final result = BillingPreviewRegistry.create(
        subscriptionId: 'SUS-INEXISTENTE',
        concept: BillingConcept.monthly,
      );

      expect(result.success, isFalse);
      expect(BillingPreviewRegistry.all, isEmpty);
    });

    test('Prepara el cargo mensual correcto', () {
      final subscriptionId = createSubscription();

      final result = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      expect(result.success, isTrue);
      expect(result.charge?.id, 'CAR-0001');
      expect(result.charge?.amountCents, 560000);
      expect(result.charge?.simulatedPaidCents, 0);

      expect(result.charge?.dueDate, DateTime.utc(2026, 11, 15));
    });

    test('Prepara el cargo anual de dominio', () {
      final subscriptionId = createSubscription();

      final result = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.annualDomain,
      );

      expect(result.success, isTrue);
      expect(result.charge?.amountCents, 100000);

      expect(result.charge?.dueDate, DateTime.utc(2027, 1, 10));
    });

    test('Impide duplicar el mismo concepto', () {
      final subscriptionId = createSubscription();

      final first = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      final duplicate = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      );

      expect(first.success, isTrue);
      expect(duplicate.success, isFalse);
      expect(BillingPreviewRegistry.all.length, 1);
    });

    test('Calcula correctamente el abono parcial', () {
      final subscriptionId = createSubscription();

      final charge = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      ).charge!;

      final error = BillingPreviewRegistry.simulateAbono(
        chargeId: charge.id,
        amountCents: 200000,
      );

      expect(error, isNull);

      final updated = BillingPreviewRegistry.findById(charge.id)!;

      expect(updated.simulatedPaidCents, 200000);
      expect(updated.simulatedBalanceCents, 360000);
      expect(updated.status, 'Abono parcial simulado');
    });

    test('No permite abonos mayores al saldo', () {
      final subscriptionId = createSubscription();

      final charge = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      ).charge!;

      final error = BillingPreviewRegistry.simulateAbono(
        chargeId: charge.id,
        amountCents: 600000,
      );

      expect(error, isNotNull);
      expect(BillingPreviewRegistry.findById(charge.id)!.simulatedPaidCents, 0);
    });

    test('No permite abonos negativos ni de cero', () {
      final subscriptionId = createSubscription();

      final charge = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      ).charge!;

      expect(
        BillingPreviewRegistry.simulateAbono(
          chargeId: charge.id,
          amountCents: 0,
        ),
        isNotNull,
      );

      expect(
        BillingPreviewRegistry.simulateAbono(
          chargeId: charge.id,
          amountCents: -100,
        ),
        isNotNull,
      );
    });

    test('Permite completar exactamente el importe', () {
      final subscriptionId = createSubscription();

      final charge = BillingPreviewRegistry.create(
        subscriptionId: subscriptionId,
        concept: BillingConcept.monthly,
      ).charge!;

      final error = BillingPreviewRegistry.simulateAbono(
        chargeId: charge.id,
        amountCents: 560000,
      );

      expect(error, isNull);

      final updated = BillingPreviewRegistry.findById(charge.id)!;

      expect(updated.simulatedBalanceCents, 0);
      expect(updated.status, 'Cubierto en simulación');
    });
  });

  group('Software Master - Ajustes', () {
    test('Guarda configuración local válida', () {
      final result = MasterSystemSettingsStore.save(
        supportPhone: '+504 9999-9999',
        supportEmail: 'soporte@ejemplo.com',
        defaultGraceDays: 5,
        backupRetentionDays: 60,
      );

      expect(result, isNull);

      expect(MasterSystemSettingsStore.current.value.defaultGraceDays, 5);

      expect(MasterSystemSettingsStore.current.value.backupRetentionDays, 60);
    });

    test('Rechaza plazos fuera de rango', () {
      final error = MasterSystemSettingsStore.save(
        supportPhone: '',
        supportEmail: '',
        defaultGraceDays: -1,
        backupRetentionDays: 30,
      );

      expect(error, isNotNull);

      expect(MasterSystemSettingsStore.current.value.defaultGraceDays, 7);
    });

    test('Rechaza correos inválidos', () {
      final error = MasterSystemSettingsStore.save(
        supportPhone: '',
        supportEmail: 'correo-invalido',
        defaultGraceDays: 7,
        backupRetentionDays: 30,
      );

      expect(error, isNotNull);
    });
  });

  group('Software Master - Pantallas centrales', () {
    Future<void> openScreen(WidgetTester tester, Widget screen) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));

      await tester.pumpAndSettle();
    }

    testWidgets('Clientes usa el registro compartido', (tester) async {
      MasterCustomerRegistry.register(legalName: 'Empresa de prueba');

      await openScreen(tester, const MasterCustomersScreen());

      expect(
        find.byKey(const Key('unified_customer_CLI-0001')),
        findsOneWidget,
      );

      expect(find.text('Directorio de clientes'), findsOneWidget);
    });

    testWidgets('Suscripciones usa borradores vinculados', (tester) async {
      createSubscription();

      await openScreen(tester, const MasterSubscriptionsScreen());

      expect(
        find.byKey(const Key('unified_subscription_SUS-0001')),
        findsOneWidget,
      );
    });

    testWidgets('Pagos inicia sin cargos ficticios', (tester) async {
      await openScreen(tester, const MasterBillingScreen());

      expect(find.text('Sin cargos de prueba'), findsOneWidget);

      expect(find.text('Cargos de prueba: 0'), findsOneWidget);
    });

    testWidgets('Respaldos no presenta ejecuciones falsas', (tester) async {
      await openScreen(tester, const MasterBackupsScreen());

      expect(find.byKey(const Key('backups_empty')), findsOneWidget);
    });

    testWidgets('Auditoría no presenta eventos falsos', (tester) async {
      await openScreen(tester, const MasterAuditScreen());

      expect(find.byKey(const Key('audit_empty')), findsOneWidget);
    });

    testWidgets('Ajustes muestra los campos previstos', (tester) async {
      await openScreen(tester, const MasterSettingsScreen());

      expect(find.byKey(const Key('settings_phone')), findsOneWidget);

      expect(find.byKey(const Key('settings_grace')), findsOneWidget);

      expect(find.byKey(const Key('settings_retention')), findsOneWidget);
    });
  });
}
