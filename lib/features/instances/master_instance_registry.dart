import 'package:flutter/foundation.dart';

import '../commercial/product_plan_catalog.dart';
import '../customers/master_customer_registry.dart';
import '../products/software_products_screen.dart';
import 'instance_pricing.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// REGISTRO TEMPORAL DE INSTANCIAS
// ============================================================

class MasterInstance {
  final String id;
  final String name;
  final String customerId;
  final String productCode;
  final String planCode;
  final String domain;
  final String hostingProvider;
  final InstancePricing pricing;

  const MasterInstance({
    required this.id,
    required this.name,
    required this.customerId,
    required this.productCode,
    required this.planCode,
    required this.domain,
    required this.hostingProvider,
    required this.pricing,
  });

  String get statusLabel => 'Borrador local · Sin licencia';
}

// ============================================================
// RESULTADOS DEL REGISTRO
// ============================================================

enum InstanceRegistrationStatus {
  registered,
  missingName,
  unknownCustomer,
  unknownProduct,
  invalidPlan,
  invalidDomain,
  duplicateName,
  duplicateDomain,
}

class InstanceRegistrationResult {
  final InstanceRegistrationStatus status;
  final MasterInstance? instance;

  const InstanceRegistrationResult({required this.status, this.instance});

  bool get success => status == InstanceRegistrationStatus.registered;

  String get message {
    switch (status) {
      case InstanceRegistrationStatus.registered:
        return 'Instancia guardada en esta sesión. '
            'No se ha activado ninguna licencia.';

      case InstanceRegistrationStatus.missingName:
        return 'Ingresa el nombre de la instancia.';

      case InstanceRegistrationStatus.unknownCustomer:
        return 'Selecciona un cliente registrado en Master.';

      case InstanceRegistrationStatus.unknownProduct:
        return 'El producto seleccionado no existe.';

      case InstanceRegistrationStatus.invalidPlan:
        return 'El plan no corresponde al producto seleccionado.';

      case InstanceRegistrationStatus.invalidDomain:
        return 'El dominio ingresado no es válido.';

      case InstanceRegistrationStatus.duplicateName:
        return 'Este cliente ya tiene una instancia '
            'con ese nombre para el mismo producto.';

      case InstanceRegistrationStatus.duplicateDomain:
        return 'El dominio ya está asociado a otra instancia.';
    }
  }
}

// ============================================================
// REPOSITORIO EN MEMORIA
// ============================================================

class MasterInstanceRegistry {
  const MasterInstanceRegistry._();

  static final ValueNotifier<List<MasterInstance>> instances =
      ValueNotifier<List<MasterInstance>>(const <MasterInstance>[]);

  static int _nextId = 1;

  static List<MasterInstance> get all =>
      List<MasterInstance>.unmodifiable(instances.value);

  static MasterInstance? findById(String id) {
    for (final instance in instances.value) {
      if (instance.id == id) {
        return instance;
      }
    }
    return null;
  }

  static InstanceRegistrationResult register({
    required String name,
    required String customerId,
    required String productCode,
    required String planCode,
    required String domain,
    required String hostingProvider,
    required InstancePricing pricing,
  }) {
    final cleanName = name.trim();
    final cleanCustomerId = customerId.trim();
    final cleanProductCode = productCode.trim();
    final cleanPlanCode = planCode.trim();

    final cleanDomain = domain.trim().toLowerCase();
    final cleanHostingProvider = hostingProvider.trim();

    if (cleanName.isEmpty) {
      return const InstanceRegistrationResult(
        status: InstanceRegistrationStatus.missingName,
      );
    }

    if (MasterCustomerRegistry.findById(cleanCustomerId) == null) {
      return const InstanceRegistrationResult(
        status: InstanceRegistrationStatus.unknownCustomer,
      );
    }

    final productExists = softwareCatalog.any(
      (product) => product.code == cleanProductCode,
    );

    if (!productExists) {
      return const InstanceRegistrationResult(
        status: InstanceRegistrationStatus.unknownProduct,
      );
    }

    if (!ProductPlanCatalog.belongsToProduct(
      productCode: cleanProductCode,
      planCode: cleanPlanCode,
    )) {
      return const InstanceRegistrationResult(
        status: InstanceRegistrationStatus.invalidPlan,
      );
    }

    if (cleanDomain.isNotEmpty) {
      final validDomain = RegExp(
        r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
      ).hasMatch(cleanDomain);

      if (!validDomain) {
        return const InstanceRegistrationResult(
          status: InstanceRegistrationStatus.invalidDomain,
        );
      }
    }

    final duplicateName = instances.value.any(
      (instance) =>
          instance.customerId == cleanCustomerId &&
          instance.productCode == cleanProductCode &&
          instance.name.toLowerCase() == cleanName.toLowerCase(),
    );

    if (duplicateName) {
      return const InstanceRegistrationResult(
        status: InstanceRegistrationStatus.duplicateName,
      );
    }

    if (cleanDomain.isNotEmpty) {
      final duplicateDomain = instances.value.any(
        (instance) => instance.domain == cleanDomain,
      );

      if (duplicateDomain) {
        return const InstanceRegistrationResult(
          status: InstanceRegistrationStatus.duplicateDomain,
        );
      }
    }

    final instance = MasterInstance(
      id: 'INS-${_nextId.toString().padLeft(4, '0')}',
      name: cleanName,
      customerId: cleanCustomerId,
      productCode: cleanProductCode,
      planCode: cleanPlanCode,
      domain: cleanDomain,
      hostingProvider: cleanHostingProvider,
      pricing: pricing,
    );

    _nextId++;

    instances.value = List<MasterInstance>.unmodifiable([
      ...instances.value,
      instance,
    ]);

    return InstanceRegistrationResult(
      status: InstanceRegistrationStatus.registered,
      instance: instance,
    );
  }

  // Exclusivo para aislar pruebas automatizadas.
  // No elimina registros de ninguna base de datos.
  static void resetForTesting() {
    instances.value = const <MasterInstance>[];
    _nextId = 1;
  }
}
