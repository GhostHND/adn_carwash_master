enum PaymentControlState {
  unverified,
  noOutstandingBalance,
  paymentPending,
  gracePeriod,
  suspendedForPayment,
  administrativelySuspended,
}

class PaymentControlDecision {
  final PaymentControlState state;
  final int outstandingCents;
  final DateTime? paymentDueDate;
  final DateTime? graceDeadline;
  final int? daysUntilSuspension;

  const PaymentControlDecision({
    required this.state,
    required this.outstandingCents,
    required this.paymentDueDate,
    required this.graceDeadline,
    required this.daysUntilSuspension,
  });

  bool get isRestricted =>
      state == PaymentControlState.suspendedForPayment ||
      state == PaymentControlState.administrativelySuspended;

  bool get shouldShowPaymentNotice =>
      state == PaymentControlState.paymentPending ||
      state == PaymentControlState.gracePeriod;

  bool get requiresVerification => state == PaymentControlState.unverified;

  String get label {
    switch (state) {
      case PaymentControlState.unverified:
        return 'Sin verificar';

      case PaymentControlState.noOutstandingBalance:
        return 'Sin deuda pendiente';

      case PaymentControlState.paymentPending:
        return 'Pago pendiente';

      case PaymentControlState.gracePeriod:
        return 'En plazo de gracia';

      case PaymentControlState.suspendedForPayment:
        return 'Suspendida por falta de pago';

      case PaymentControlState.administrativelySuspended:
        return 'Suspendida administrativamente';
    }
  }
}

class LicensePaymentPolicy {
  const LicensePaymentPolicy._();

  static DateTime _dateOnlyUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static PaymentControlDecision evaluate({
    required DateTime today,
    required DateTime? paymentDueDate,
    required int? outstandingCents,
    required int graceDays,
    bool administrativelySuspended = false,
    bool verified = false,
  }) {
    if (graceDays < 0) {
      throw ArgumentError.value(
        graceDays,
        'graceDays',
        'El plazo no puede ser negativo.',
      );
    }

    if (outstandingCents != null && outstandingCents < 0) {
      throw ArgumentError.value(
        outstandingCents,
        'outstandingCents',
        'El saldo no puede ser negativo.',
      );
    }

    if (!verified || paymentDueDate == null || outstandingCents == null) {
      return const PaymentControlDecision(
        state: PaymentControlState.unverified,
        outstandingCents: 0,
        paymentDueDate: null,
        graceDeadline: null,
        daysUntilSuspension: null,
      );
    }

    final currentDate = _dateOnlyUtc(today);
    final dueDate = _dateOnlyUtc(paymentDueDate);

    final deadline = dueDate.add(Duration(days: graceDays));

    final remaining = deadline.difference(currentDate).inDays;

    if (administrativelySuspended) {
      return PaymentControlDecision(
        state: PaymentControlState.administrativelySuspended,
        outstandingCents: outstandingCents,
        paymentDueDate: dueDate,
        graceDeadline: deadline,
        daysUntilSuspension: null,
      );
    }

    if (outstandingCents == 0) {
      return PaymentControlDecision(
        state: PaymentControlState.noOutstandingBalance,
        outstandingCents: 0,
        paymentDueDate: dueDate,
        graceDeadline: deadline,
        daysUntilSuspension: null,
      );
    }

    if (!currentDate.isAfter(dueDate)) {
      return PaymentControlDecision(
        state: PaymentControlState.paymentPending,
        outstandingCents: outstandingCents,
        paymentDueDate: dueDate,
        graceDeadline: deadline,
        daysUntilSuspension: remaining,
      );
    }

    if (!currentDate.isAfter(deadline)) {
      return PaymentControlDecision(
        state: PaymentControlState.gracePeriod,
        outstandingCents: outstandingCents,
        paymentDueDate: dueDate,
        graceDeadline: deadline,
        daysUntilSuspension: remaining,
      );
    }

    return PaymentControlDecision(
      state: PaymentControlState.suspendedForPayment,
      outstandingCents: outstandingCents,
      paymentDueDate: dueDate,
      graceDeadline: deadline,
      daysUntilSuspension: 0,
    );
  }
}
