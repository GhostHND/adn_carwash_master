import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/payments/payments_screen.dart';

void main() {
  group('ADN Publicidad Software Master - Pagos', () {
    Future<void> openPayments(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Pagos'));

      await tester.pumpAndSettle();
    }

    Future<void> openForm(WidgetTester tester) async {
      await openPayments(tester);

      await tester.tap(find.text('Nuevo pago'));

      await tester.pumpAndSettle();
    }

    testWidgets('Abre el historial de pagos', (WidgetTester tester) async {
      await openPayments(tester);

      expect(find.byType(PaymentsScreen), findsOneWidget);

      expect(find.text('Historial de pagos'), findsOneWidget);

      expect(find.text('A\u00fan no hay pagos registrados'), findsOneWidget);
    });

    testWidgets('Abre el formulario sin suscripciones ficticias', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      expect(find.byType(PaymentFormDialog), findsOneWidget);

      expect(find.text('Sin suscripciones registradas'), findsOneWidget);

      expect(find.byKey(const Key('payment_total')), findsOneWidget);

      expect(find.byKey(const Key('payment_paid')), findsOneWidget);

      expect(find.byKey(const Key('payment_method')), findsOneWidget);
    });

    testWidgets('Rechaza importes y abonos vacios', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.byKey(const Key('payment_validate')));

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ingresa un importe mayor que cero '
          'con hasta dos decimales.',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Ingresa un abono mayor que cero '
          'con hasta dos decimales.',
        ),
        findsOneWidget,
      );

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('Calcula el saldo de un abono parcial', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('payment_total')), '1000.00');

      await tester.enterText(find.byKey(const Key('payment_paid')), '400.00');

      await tester.pumpAndSettle();

      expect(find.text('Saldo estimado: L 600.00'), findsOneWidget);

      expect(find.byKey(const Key('payment_balance')), findsOneWidget);
    });

    testWidgets('No acepta un abono mayor que el importe', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('payment_total')), '100.00');

      await tester.enterText(find.byKey(const Key('payment_paid')), '150.00');

      await tester.tap(find.byKey(const Key('payment_validate')));

      await tester.pumpAndSettle();

      expect(
        find.text('El abono no puede superar el importe.'),
        findsOneWidget,
      );

      expect(find.byType(PaymentFormDialog), findsOneWidget);
    });

    testWidgets('Validar un borrador no registra un pago', (
      WidgetTester tester,
    ) async {
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('payment_total')), '1000');

      await tester.enterText(find.byKey(const Key('payment_paid')), '500');

      await tester.tap(find.byKey(const Key('payment_validate')));

      await tester.pumpAndSettle();

      expect(find.byType(PaymentFormDialog), findsNothing);

      expect(find.text('A\u00fan no hay pagos registrados'), findsOneWidget);
    });

    testWidgets('La pantalla se adapta a un telefono', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentsScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PaymentsScreen), findsOneWidget);

      await tester.tap(find.text('Nuevo pago'));

      await tester.pumpAndSettle();

      expect(find.byType(PaymentFormDialog), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
