import 'package:flutter/foundation.dart';

import '../customers/master_customer_registry.dart';
import '../instances/master_instance_registry.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// SUSCRIPCIONES VINCULADAS - ALMACENAMIENTO TEMPORAL
// ============================================================

class LinkedSubscriptionDraft {
  final String id;
  final String instanceId;
  final String customerId;
  final String productCode;
  final String planCode;

  final DateTime firstMonthlyDueDate;
  final DateTime? firstDomainDueDate;

  // Importes capturados cuando se prepara el borrador.
  // No dependen de que el precio de la instancia
  // cambie posteriormente.

  final int softwareMonthlyChargeCents;
  final int hostingMonthlyChargeCents;
  final int domainAnnualChargeCents;

  const LinkedSubscriptionDraft({
    required this.id,
    required this.instanceId,
    required this.customerId,
    required this.productCode,
    required this.planCode,
    required this.firstMonthlyDueDate,
    required this.firstDomainDueDate,
    required this.softwareMonthlyChargeCents,
    required this.hostingMonthlyChargeCents,
    required this.domainAnnualChargeCents,
  });

  int get monthlyChargeCents {
    return softwareMonthlyChargeCents + hostingMonthlyChargeCents;
  }

  int get annualProjectionCents {
    return monthlyChargeCents * 12 + domainAnnualChargeCents;
  }

  String get statusLabel => 'Borrador · Sin facturar';
}

// ============================================================
// RESULTADOS DE REGISTRO
// ============================================================

enum LinkedSubscriptionResultStatus {
  saved,
  unknownInstance,
  unknownCustomer,
  duplicateSubscription,
  missingMonthlyDueDate,
  missingDomainDueDate,
}

class LinkedSubscriptionResult {
  final LinkedSubscriptionResultStatus status;
  final LinkedSubscriptionDraft? draft;

  const LinkedSubscriptionResult({required this.status, this.draft});

  bool get success => status == LinkedSubscriptionResultStatus.saved;

  String get message {
    switch (status) {
      case LinkedSubscriptionResultStatus.saved:
        return 'Borrador de suscripción guardado. '
            'No se generaron cobros ni licencias.';

      case LinkedSubscriptionResultStatus.unknownInstance:
        return 'Selecciona una instancia registrada en Master.';

      case LinkedSubscriptionResultStatus.unknownCustomer:
        return 'El cliente asociado ya no está disponible.';

      case LinkedSubscriptionResultStatus.duplicateSubscription:
        return 'Esta instancia ya tiene un borrador '
            'de suscripción asociado.';

      case LinkedSubscriptionResultStatus.missingMonthlyDueDate:
        return 'Indica la primera fecha de cobro mensual.';

      case LinkedSubscriptionResultStatus.missingDomainDueDate:
        return 'Indica la fecha del cargo anual '
            'del dominio.';
    }
  }
}

// ============================================================
// REPOSITORIO EN MEMORIA
// ============================================================

class LinkedSubscriptionRegistry {
  const LinkedSubscriptionRegistry._();

  static final ValueNotifier<List<LinkedSubscriptionDraft>> subscriptions =
      ValueNotifier<List<LinkedSubscriptionDraft>>(
        const <LinkedSubscriptionDraft>[],
      );

  static int _nextId = 1;

  static List<LinkedSubscriptionDraft> get all =>
      List<LinkedSubscriptionDraft>.unmodifiable(subscriptions.value);

  static LinkedSubscriptionDraft? findByInstance(String instanceId) {
    for (final draft in subscriptions.value) {
      if (draft.instanceId == instanceId) {
        return draft;
      }
    }

    return null;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  static LinkedSubscriptionResult register({
    required String instanceId,
    required DateTime? firstMonthlyDueDate,
    DateTime? firstDomainDueDate,
  }) {
    final instance = MasterInstanceRegistry.findById(instanceId.trim());

    if (instance == null) {
      return const LinkedSubscriptionResult(
        status: LinkedSubscriptionResultStatus.unknownInstance,
      );
    }

    if (MasterCustomerRegistry.findById(instance.customerId) == null) {
      return const LinkedSubscriptionResult(
        status: LinkedSubscriptionResultStatus.unknownCustomer,
      );
    }

    if (findByInstance(instance.id) != null) {
      return const LinkedSubscriptionResult(
        status: LinkedSubscriptionResultStatus.duplicateSubscription,
      );
    }

    if (firstMonthlyDueDate == null) {
      return const LinkedSubscriptionResult(
        status: LinkedSubscriptionResultStatus.missingMonthlyDueDate,
      );
    }

    final domainCharge = instance.pricing.domainAnnualChargeCents;

    if (domainCharge > 0 && firstDomainDueDate == null) {
      return const LinkedSubscriptionResult(
        status: LinkedSubscriptionResultStatus.missingDomainDueDate,
      );
    }

    final draft = LinkedSubscriptionDraft(
      id: 'SUS-${_nextId.toString().padLeft(4, '0')}',
      instanceId: instance.id,
      customerId: instance.customerId,
      productCode: instance.productCode,
      planCode: instance.planCode,
      firstMonthlyDueDate: _normalizeDate(firstMonthlyDueDate),
      firstDomainDueDate: firstDomainDueDate == null
          ? null
          : _normalizeDate(firstDomainDueDate),
      softwareMonthlyChargeCents: instance.pricing.softwareMonthlyChargeCents,
      hostingMonthlyChargeCents: instance.pricing.hostingMonthlyChargeCents,
      domainAnnualChargeCents: domainCharge,
    );

    _nextId++;

    subscriptions.value = List<LinkedSubscriptionDraft>.unmodifiable([
      ...subscriptions.value,
      draft,
    ]);

    return LinkedSubscriptionResult(
      status: LinkedSubscriptionResultStatus.saved,
      draft: draft,
    );
  }

  // Solamente para pruebas automatizadas.
  // No elimina suscripciones reales.
  static void resetForTesting() {
    subscriptions.value = const <LinkedSubscriptionDraft>[];
    _nextId = 1;
  }
}
