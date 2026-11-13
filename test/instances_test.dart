import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/instances/instance_pricing.dart';
import 'package:adn_carwash_master/features/instances/instances_screen.dart';

void main() {
  group('Software Master - Precios por instancia', () {
    test('Convierte importes a centavos', () {
      expect(InstanceMoney.parse('1500.50'), 150050);
      expect(InstanceMoney.parse('1500,50'), 150050);
      expect(InstanceMoney.parse('0'), 0);
      expect(InstanceMoney.parse('15.999'), isNull);
      expect(InstanceMoney.parse('abc'), isNull);
    });

    test('Calcula cargos y costos independientes', () {
      const pricing = InstancePricing(
        softwareMonthlyChargeCents: 50000,
        hostingMonthlyCostCents: 18000,
        hostingMonthlyChargeCents: 25000,
        domainAnnualCostCents: 70000,
        domainAnnualChargeCents: 100000,
      );

      expect(pricing.customerAnnualChargeCents, 1000000);

      expect(pricing.infrastructureAnnualCostCents, 286000);

      expect(pricing.customerMonthlyEquivalentCents, 83333);

      expect(pricing.preliminaryContributionCents, 714000);
    });

    test('Admite infraestructura incluida sin cargo adicional', () {
      const pricing = InstancePricing(
        softwareMonthlyChargeCents: 50000,
        hostingMonthlyCostCents: 18000,
        hostingMonthlyChargeCents: 0,
        domainAnnualCostCents: 70000,
        domainAnnualChargeCents: 0,
      );

      expect(pricing.customerAnnualChargeCents, 600000);

      expect(pricing.infrastructureAnnualCostCents, 286000);
    });
  });

  group('Software Master - Pantalla Instancias', () {
    Future<void> openInstances(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(MasterSidebar),
          matching: find.widgetWithText(InkWell, 'Instancias'),
        ),
      );

      await tester.pumpAndSettle();
    }

    Future<void> openForm(WidgetTester tester) async {
      await openInstances(tester);

      await tester.tap(find.text('Nueva instancia'));

      await tester.pumpAndSettle();
    }

    testWidgets('Abre el directorio de instancias', (
      WidgetTester tester,
    ) async {
      await openInstances(tester);

      expect(find.byType(InstancesScreen), findsOneWidget);

      expect(find.byKey(const Key('instances_directory')), findsOneWidget);

      expect(find.text('Sin instancias registradas'), findsOneWidget);
    });

    testWidgets('Abre el formulario con cliente pendiente', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      expect(find.byType(InstanceFormDialog), findsOneWidget);

      expect(find.text('Sin clientes registrados'), findsOneWidget);

      expect(find.byKey(const Key('instance_name')), findsOneWidget);

      expect(find.byKey(const Key('instance_domain')), findsOneWidget);

      expect(find.byKey(const Key('instance_plan')), findsOneWidget);
    });

    testWidgets('Exige un nombre de instancia', (WidgetTester tester) async {
      await openForm(tester);

      await tester.tap(find.byKey(const Key('instance_validate')));

      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio.'), findsOneWidget);

      expect(find.byType(InstanceFormDialog), findsOneWidget);
    });

    testWidgets('Calcula una proyeccion comercial anual', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      final amounts = <Key, String>{
        const Key('instance_software_fee'): '500',
        const Key('instance_host_cost'): '180',
        const Key('instance_host_charge'): '250',
        const Key('instance_domain_cost'): '700',
        const Key('instance_domain_charge'): '1000',
      };

      for (final entry in amounts.entries) {
        final field = find.byKey(entry.key);

        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }

      expect(
        find.textContaining('Cargos al cliente por 12 meses: L 10000.00'),
        findsOneWidget,
      );

      expect(find.byKey(const Key('instance_total_yearly')), findsOneWidget);
    });

    testWidgets('Validar un borrador no crea instancias', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(
        find.byKey(const Key('instance_name')),
        'Instancia de prueba',
      );

      await tester.tap(find.byKey(const Key('instance_validate')));

      await tester.pumpAndSettle();

      expect(find.byType(InstanceFormDialog), findsNothing);

      expect(find.text('Sin instancias registradas'), findsOneWidget);
    });

    testWidgets('La pantalla se adapta a telefonos', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstancesScreen())),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Nueva instancia'));

      await tester.pumpAndSettle();

      expect(find.byType(InstanceFormDialog), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
