import 'package:flutter/foundation.dart';

import '../subscriptions/linked_subscription_registry.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// SIMULACION DE CARGOS Y ABONOS
// ============================================================

enum BillingConcept { monthly, annualDomain }

extension BillingConceptDescription on BillingConcept {
  String get label {
    switch (this) {
      case BillingConcept.monthly:
        return 'Software y hosting mensual';
      case BillingConcept.annualDomain:
        return 'Dominio anual';
    }
  }
}

class BillingPreviewCharge {
  final String id;
  final String subscriptionId;
  final String instanceId;
  final BillingConcept concept;
  final DateTime dueDate;
  final int amountCents;
  final int simulatedPaidCents;

  const BillingPreviewCharge({
    required this.id,
    required this.subscriptionId,
    required this.instanceId,
    required this.concept,
    required this.dueDate,
    required this.amountCents,
    required this.simulatedPaidCents,
  });

  int get simulatedBalanceCents => amountCents - simulatedPaidCents;

  String get status {
    if (simulatedPaidCents == 0) {
      return 'Sin abonos simulados';
    }
    if (simulatedBalanceCents == 0) {
      return 'Cubierto en simulación';
    }
    return 'Abono parcial simulado';
  }

  BillingPreviewCharge withPayment(int cents) {
    return BillingPreviewCharge(
      id: id,
      subscriptionId: subscriptionId,
      instanceId: instanceId,
      concept: concept,
      dueDate: dueDate,
      amountCents: amountCents,
      simulatedPaidCents: simulatedPaidCents + cents,
    );
  }
}

class BillingPreviewResult {
  final BillingPreviewCharge? charge;
  final String? error;

  const BillingPreviewResult({this.charge, this.error});

  bool get success => charge != null;
}

class BillingPreviewRegistry {
  const BillingPreviewRegistry._();

  static final ValueNotifier<List<BillingPreviewCharge>> charges =
      ValueNotifier<List<BillingPreviewCharge>>(const <BillingPreviewCharge>[]);

  static int _nextId = 1;

  static List<BillingPreviewCharge> get all =>
      List<BillingPreviewCharge>.unmodifiable(charges.value);

  static BillingPreviewCharge? findById(String id) {
    for (final charge in charges.value) {
      if (charge.id == id) return charge;
    }
    return null;
  }

  static LinkedSubscriptionDraft? _subscription(String id) {
    for (final subscription in LinkedSubscriptionRegistry.all) {
      if (subscription.id == id) return subscription;
    }
    return null;
  }

  static BillingPreviewResult create({
    required String subscriptionId,
    required BillingConcept concept,
  }) {
    final subscription = _subscription(subscriptionId);

    if (subscription == null) {
      return const BillingPreviewResult(
        error: 'Selecciona una suscripción vinculada.',
      );
    }

    final duplicated = charges.value.any(
      (charge) =>
          charge.subscriptionId == subscriptionId && charge.concept == concept,
    );

    if (duplicated) {
      return const BillingPreviewResult(
        error:
            'Ya existe un cargo preliminar de este concepto '
            'para la suscripción.',
      );
    }

    final amount = concept == BillingConcept.monthly
        ? subscription.monthlyChargeCents
        : subscription.domainAnnualChargeCents;

    final dueDate = concept == BillingConcept.monthly
        ? subscription.firstMonthlyDueDate
        : subscription.firstDomainDueDate;

    if (amount <= 0 || dueDate == null) {
      return const BillingPreviewResult(
        error:
            'Esta suscripción no tiene un importe '
            'y una fecha para ese concepto.',
      );
    }

    final charge = BillingPreviewCharge(
      id: 'CAR-${_nextId.toString().padLeft(4, '0')}',
      subscriptionId: subscription.id,
      instanceId: subscription.instanceId,
      concept: concept,
      dueDate: dueDate,
      amountCents: amount,
      simulatedPaidCents: 0,
    );

    _nextId++;

    charges.value = List<BillingPreviewCharge>.unmodifiable([
      ...charges.value,
      charge,
    ]);

    return BillingPreviewResult(charge: charge);
  }

  // null significa simulacion aceptada.
  // Un mensaje indica el motivo del rechazo.
  static String? simulateAbono({
    required String chargeId,
    required int amountCents,
  }) {
    final current = findById(chargeId);

    if (current == null) {
      return 'No se encontró el cargo de prueba.';
    }

    if (amountCents <= 0) {
      return 'El abono debe ser mayor que cero.';
    }

    if (amountCents > current.simulatedBalanceCents) {
      return 'El abono supera el saldo simulado.';
    }

    charges.value = List<BillingPreviewCharge>.unmodifiable([
      for (final charge in charges.value)
        if (charge.id == chargeId) charge.withPayment(amountCents) else charge,
    ]);

    return null;
  }

  static void resetForTesting() {
    charges.value = const <BillingPreviewCharge>[];
    _nextId = 1;
  }
}
