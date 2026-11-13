import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adn_carwash_master/features/commercial/product_plan_catalog.dart';
import 'package:adn_carwash_master/features/instances/instances_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// PRUEBAS DE RELACIONES COMERCIALES
// ============================================================

void main() {
  // ==========================================================
  // PRUEBAS DE PLANES POR PRODUCTO
  // ==========================================================

  group('Software Master - planes por producto', () {
    test('CarWash tiene exactamente los tres planes actuales', () {
      final plans = ProductPlanCatalog.forProduct('adn-carwash');

      expect(plans.map((plan) => plan.name).toList(), [
        'Básico',
        'Intermedio',
        'Pro',
      ]);
    });

    test('Un producto nuevo no hereda planes de CarWash', () {
      expect(ProductPlanCatalog.forProduct('adn-restaurante'), isEmpty);

      expect(ProductPlanCatalog.forProduct('adn-barberia'), isEmpty);
    });

    test('Rechaza planes que no corresponden al producto', () {
      expect(
        ProductPlanCatalog.belongsToProduct(
          productCode: 'adn-barberia',
          planCode: 'pro',
        ),
        isFalse,
      );
    });

    test('Reconoce un plan asignado correctamente', () {
      expect(
        ProductPlanCatalog.belongsToProduct(
          productCode: 'adn-carwash',
          planCode: 'intermedio',
        ),
        isTrue,
      );
    });
  });

  // ==========================================================
  // PRUEBAS DE VINCULACION COMERCIAL
  // ==========================================================

  group('Software Master - vinculación comercial', () {
    // Datos ficticios exclusivos de las pruebas.
    // No se registran en la aplicacion.

    const customerIds = {'cliente-001'};

    const productCodes = {'adn-carwash'};

    List<CommercialAssociationProblem> check({
      String? customerId = 'cliente-001',
      String productCode = 'adn-carwash',
      String planCode = 'basico',
    }) {
      return CommercialAssociationValidator.validate(
        customerId: customerId,
        productCode: productCode,
        planCode: planCode,
        registeredCustomerIds: customerIds,
        registeredProductCodes: productCodes,
      );
    }

    test('Acepta una relación completa y coherente', () {
      expect(check(), isEmpty);
    });

    test('Impide vincular sin cliente', () {
      expect(
        check(customerId: null),
        contains(CommercialAssociationProblem.missingCustomer),
      );
    });

    test('Impide vincular un cliente no registrado', () {
      expect(
        check(customerId: 'cliente-inexistente'),
        contains(CommercialAssociationProblem.unknownCustomer),
      );
    });

    test('Impide vincular un producto inexistente', () {
      final result = check(productCode: 'adn-restaurante');

      expect(result, contains(CommercialAssociationProblem.unknownProduct));

      expect(
        result,
        contains(CommercialAssociationProblem.planDoesNotBelongToProduct),
      );
    });

    test('Impide vincular un plan inexistente', () {
      expect(
        check(planCode: 'premium-externo'),
        contains(CommercialAssociationProblem.planDoesNotBelongToProduct),
      );
    });
  });

  // ==========================================================
  // PRUEBA DE INTEGRACION CON INSTANCIAS
  // ==========================================================

  testWidgets('Instancias utiliza planes vinculados al producto', (
    WidgetTester tester,
  ) async {
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

    expect(find.byKey(const Key('instance_product')), findsOneWidget);

    expect(find.byKey(const Key('instance_plan')), findsOneWidget);

    final planDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('instance_plan')),
    );

    expect(planDropdown.initialValue, 'basico');
  });
}
