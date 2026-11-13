class InstanceMoney {
  const InstanceMoney._();

  static int? parse(String input) {
    final value = input.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d{1,9}(?:\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final units = int.parse(parts.first);

    final decimals = parts.length == 2
        ? int.parse(parts.last.padRight(2, '0'))
        : 0;

    return units * 100 + decimals;
  }

  static String format(int cents) {
    final negative = cents < 0;
    final absolute = cents.abs();

    final units = absolute ~/ 100;
    final decimals = (absolute % 100).toString().padLeft(2, '0');

    return '${negative ? '-' : ''}L $units.$decimals';
  }
}

class InstancePricing {
  // Precio mensual del software contratado.
  final int softwareMonthlyChargeCents;

  // Hosting: costo interno y cargo al cliente.
  final int hostingMonthlyCostCents;
  final int hostingMonthlyChargeCents;

  // Dominio: costo interno y cargo al cliente.
  final int domainAnnualCostCents;
  final int domainAnnualChargeCents;

  const InstancePricing({
    required this.softwareMonthlyChargeCents,
    required this.hostingMonthlyCostCents,
    required this.hostingMonthlyChargeCents,
    required this.domainAnnualCostCents,
    required this.domainAnnualChargeCents,
  }) : assert(softwareMonthlyChargeCents >= 0),
       assert(hostingMonthlyCostCents >= 0),
       assert(hostingMonthlyChargeCents >= 0),
       assert(domainAnnualCostCents >= 0),
       assert(domainAnnualChargeCents >= 0);

  // Proyeccion de cargos recurrentes durante 12 meses.
  int get customerAnnualChargeCents {
    return softwareMonthlyChargeCents * 12 +
        hostingMonthlyChargeCents * 12 +
        domainAnnualChargeCents;
  }

  // Costo interno anual de dominio y hosting.
  int get infrastructureAnnualCostCents {
    return hostingMonthlyCostCents * 12 + domainAnnualCostCents;
  }

  // Equivalente mensual redondeado al centavo.
  // Es una referencia, no necesariamente una cuota mensual.
  int get customerMonthlyEquivalentCents {
    return (customerAnnualChargeCents / 12).round();
  }

  // Diferencia antes de costos operativos del software,
  // impuestos, soporte y otros gastos.
  int get preliminaryContributionCents {
    return customerAnnualChargeCents - infrastructureAnnualCostCents;
  }
}
