import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/licensing/license_policy.dart';
import 'package:adn_carwash_master/features/licensing/license_control_screen.dart';

void main() {
  group('Software Master - Politica de pagos', () {
    final dueDate = DateTime(2026, 11, 10);

    PaymentControlDecision evaluate({
      required DateTime today,
      int? balance = 85000,
      int graceDays = 7,
      bool verified = true,
      bool administrativeHold = false,
    }) {
      return LicensePaymentPolicy.evaluate(
        today: today,
        paymentDueDate: dueDate,
        outstandingCents: balance,
        graceDays: graceDays,
        verified: verified,
        administrativelySuspended: administrativeHold,
      );
    }

    test('No inventa estados sin verificacion', () {
      final result = evaluate(today: DateTime(2026, 11, 10), verified: false);

      expect(result.state, PaymentControlState.unverified);

      expect(result.requiresVerification, isTrue);
      expect(result.isRestricted, isFalse);
    });

    test('Sin deuda no aplica bloqueo por pago', () {
      final result = evaluate(today: DateTime(2026, 11, 18), balance: 0);

      expect(result.state, PaymentControlState.noOutstandingBalance);

      expect(result.isRestricted, isFalse);
      expect(result.shouldShowPaymentNotice, isFalse);
    });

    test('Antes del vencimiento muestra aviso', () {
      final result = evaluate(today: DateTime(2026, 11, 5));

      expect(result.state, PaymentControlState.paymentPending);

      expect(result.daysUntilSuspension, 12);
      expect(result.shouldShowPaymentNotice, isTrue);
    });

    test('El dia del vencimiento no suspende', () {
      final result = evaluate(today: DateTime(2026, 11, 10));

      expect(result.state, PaymentControlState.paymentPending);

      expect(result.isRestricted, isFalse);
      expect(result.daysUntilSuspension, 7);
    });

    test('Despues del vencimiento inicia gracia', () {
      final result = evaluate(today: DateTime(2026, 11, 11));

      expect(result.state, PaymentControlState.gracePeriod);

      expect(result.daysUntilSuspension, 6);
      expect(result.isRestricted, isFalse);
    });

    test('El ultimo dia de gracia conserva acceso', () {
      final result = evaluate(today: DateTime(2026, 11, 17));

      expect(result.state, PaymentControlState.gracePeriod);

      expect(result.daysUntilSuspension, 0);
      expect(result.isRestricted, isFalse);
    });

    test('Suspende al terminar la gracia', () {
      final result = evaluate(today: DateTime(2026, 11, 18));

      expect(result.state, PaymentControlState.suspendedForPayment);

      expect(result.isRestricted, isTrue);
      expect(result.shouldShowPaymentNotice, isFalse);
    });

    test('Sin gracia suspende al dia siguiente', () {
      final result = evaluate(today: DateTime(2026, 11, 11), graceDays: 0);

      expect(result.state, PaymentControlState.suspendedForPayment);
    });

    test('La suspension administrativa tiene prioridad', () {
      final result = evaluate(
        today: DateTime(2026, 11, 5),
        balance: 0,
        administrativeHold: true,
      );

      expect(result.state, PaymentControlState.administrativelySuspended);

      expect(result.isRestricted, isTrue);
    });

    test('Dos instancias pueden tener estados diferentes', () {
      final activeInstance = evaluate(
        today: DateTime(2026, 11, 18),
        balance: 0,
      );

      final suspendedInstance = evaluate(
        today: DateTime(2026, 11, 18),
        balance: 85000,
      );

      expect(activeInstance.state, PaymentControlState.noOutstandingBalance);

      expect(suspendedInstance.state, PaymentControlState.suspendedForPayment);
    });

    test('Rechaza saldos negativos', () {
      expect(
        () => evaluate(today: DateTime(2026, 11, 10), balance: -100),
        throwsArgumentError,
      );
    });

    test('Rechaza plazos negativos', () {
      expect(
        () => evaluate(today: DateTime(2026, 11, 10), graceDays: -1),
        throwsArgumentError,
      );
    });
  });

  group('Software Master - Pantalla Licencias', () {
    testWidgets('Abre Licencias desde el menu lateral', (
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

      final option = find.widgetWithText(InkWell, 'Licencias');

      await tester.scrollUntilVisible(
        option,
        170.0,
        scrollable: scrollable,
        maxScrolls: 30,
      );

      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(find.byType(LicenseControlScreen), findsOneWidget);

      expect(find.byKey(const Key('license_simulator')), findsOneWidget);
    });

    testWidgets('El simulador inicia sin resultados ficticios', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LicenseControlScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('license_no_simulation')), findsOneWidget);

      expect(find.byKey(const Key('license_simulation_result')), findsNothing);
    });

    testWidgets('La pantalla funciona en telefonos', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LicenseControlScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LicenseControlScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
