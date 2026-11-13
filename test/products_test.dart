import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/main.dart';
import 'package:adn_carwash_master/features/products/software_products_screen.dart';

void main() {
  group('ADN Software Master - Productos', () {
    Future<void> openProducts(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(const AdnCarWashMaster());

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'Productos de software'));

      await tester.pumpAndSettle();
    }

    testWidgets('Muestra ADN CarWash como primer producto', (
      WidgetTester tester,
    ) async {
      await openProducts(tester);

      expect(find.byType(SoftwareProductsScreen), findsOneWidget);

      expect(
        find.byKey(const Key('software_product_adn-carwash')),
        findsOneWidget,
      );

      expect(find.text('ADN CarWash'), findsOneWidget);

      expect(find.text('En desarrollo'), findsWidgets);
    });

    testWidgets('Permite abrir el formulario de producto', (
      WidgetTester tester,
    ) async {
      await openProducts(tester);

      await tester.tap(find.text('Nuevo producto'));

      await tester.pumpAndSettle();

      expect(find.byType(SoftwareProductFormDialog), findsOneWidget);

      expect(find.byKey(const Key('product_name')), findsOneWidget);

      expect(find.byKey(const Key('product_code')), findsOneWidget);

      expect(find.byKey(const Key('product_category')), findsOneWidget);
    });

    testWidgets('Rechaza campos vacios', (WidgetTester tester) async {
      await openProducts(tester);

      await tester.tap(find.text('Nuevo producto'));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('product_validate')));

      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));

      expect(find.text('Ingresa un identificador interno.'), findsOneWidget);

      expect(find.byType(SoftwareProductFormDialog), findsOneWidget);
    });

    testWidgets('No permite un identificador duplicado', (
      WidgetTester tester,
    ) async {
      await openProducts(tester);

      await tester.tap(find.text('Nuevo producto'));

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('product_name')),
        'Otro software',
      );

      await tester.enterText(
        find.byKey(const Key('product_code')),
        'adn-carwash',
      );

      await tester.enterText(
        find.byKey(const Key('product_category')),
        'Servicios',
      );

      await tester.tap(find.byKey(const Key('product_validate')));

      await tester.pumpAndSettle();

      expect(find.text('Este identificador ya está definido.'), findsOneWidget);

      expect(find.byType(SoftwareProductFormDialog), findsOneWidget);
    });

    testWidgets('Validar datos no crea productos nuevos', (
      WidgetTester tester,
    ) async {
      await openProducts(tester);

      await tester.tap(find.text('Nuevo producto'));

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('product_name')),
        'Software de Barberías',
      );

      await tester.enterText(
        find.byKey(const Key('product_code')),
        'adn-barberias',
      );

      await tester.enterText(
        find.byKey(const Key('product_category')),
        'Barberías',
      );

      await tester.tap(find.byKey(const Key('product_validate')));

      await tester.pumpAndSettle();

      expect(find.byType(SoftwareProductFormDialog), findsNothing);

      expect(softwareCatalog.length, 1);

      expect(
        find.byKey(const Key('software_product_adn-carwash')),
        findsOneWidget,
      );
    });
  });
}
