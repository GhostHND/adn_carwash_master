// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// CATALOGO COMERCIAL DE PLANES POR PRODUCTO
// ============================================================

// Definicion de un plan asociado a un producto.
class SoftwarePlanDefinition {
  final String code;
  final String productCode;
  final String name;

  const SoftwarePlanDefinition({
    required this.code,
    required this.productCode,
    required this.name,
  });
}

// ============================================================
// CATALOGO DE PLANES
// ============================================================

class ProductPlanCatalog {
  const ProductPlanCatalog._();

  // Los planes pertenecen a productos concretos.
  //
  // Los precios se administraran por separado.
  // No se establecen precios ficticios.
  //
  // El dominio y hosting pueden variar por instancia.

  static const plans = <SoftwarePlanDefinition>[
    SoftwarePlanDefinition(
      code: 'basico',
      productCode: 'adn-carwash',
      name: 'Básico',
    ),

    SoftwarePlanDefinition(
      code: 'intermedio',
      productCode: 'adn-carwash',
      name: 'Intermedio',
    ),

    SoftwarePlanDefinition(
      code: 'pro',
      productCode: 'adn-carwash',
      name: 'Pro',
    ),
  ];

  // ==========================================================
  // OBTENER PLANES DE UN PRODUCTO
  // ==========================================================

  static List<SoftwarePlanDefinition> forProduct(String productCode) {
    return List<SoftwarePlanDefinition>.unmodifiable(
      plans.where((plan) => plan.productCode == productCode),
    );
  }

  // ==========================================================
  // VALIDAR RELACION PRODUCTO - PLAN
  // ==========================================================

  static bool belongsToProduct({
    required String productCode,
    required String planCode,
  }) {
    return plans.any(
      (plan) => plan.productCode == productCode && plan.code == planCode,
    );
  }
}

// ============================================================
// POSIBLES PROBLEMAS DE ASOCIACION COMERCIAL
// ============================================================

enum CommercialAssociationProblem {
  missingCustomer,
  unknownCustomer,
  unknownProduct,
  planDoesNotBelongToProduct,
}

// ============================================================
// VALIDADOR DE RELACIONES COMERCIALES
// ============================================================

class CommercialAssociationValidator {
  const CommercialAssociationValidator._();

  // Esta evaluacion no crea clientes ni instancias.
  //
  // El servidor central debera repetir las validaciones
  // antes de registrar una contratacion definitiva.

  static List<CommercialAssociationProblem> validate({
    required String? customerId,
    required String productCode,
    required String planCode,
    required Set<String> registeredCustomerIds,
    required Set<String> registeredProductCodes,
  }) {
    final problems = <CommercialAssociationProblem>[];

    final cleanCustomerId = customerId?.trim() ?? '';

    // --------------------------------------------------------
    // VERIFICAR CLIENTE
    // --------------------------------------------------------

    if (cleanCustomerId.isEmpty) {
      problems.add(CommercialAssociationProblem.missingCustomer);
    } else if (!registeredCustomerIds.contains(cleanCustomerId)) {
      problems.add(CommercialAssociationProblem.unknownCustomer);
    }

    // --------------------------------------------------------
    // VERIFICAR PRODUCTO
    // --------------------------------------------------------

    if (!registeredProductCodes.contains(productCode)) {
      problems.add(CommercialAssociationProblem.unknownProduct);
    }

    // --------------------------------------------------------
    // VERIFICAR PLAN DEL PRODUCTO
    // --------------------------------------------------------

    if (!ProductPlanCatalog.belongsToProduct(
      productCode: productCode,
      planCode: planCode,
    )) {
      problems.add(CommercialAssociationProblem.planDoesNotBelongToProduct);
    }

    return List<CommercialAssociationProblem>.unmodifiable(problems);
  }
}
