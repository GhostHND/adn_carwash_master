import 'package:flutter/foundation.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// REGISTRO CENTRAL TEMPORAL DE CLIENTES
// ============================================================

class MasterCustomer {
  final String id;
  final String legalName;
  final String tradeName;
  final String email;
  final String phone;

  const MasterCustomer({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.email,
    required this.phone,
  });

  String get displayName {
    if (tradeName.trim().isNotEmpty) {
      return tradeName;
    }

    return legalName;
  }
}

// ============================================================
// RESULTADOS DEL REGISTRO
// ============================================================

enum CustomerRegistrationStatus {
  registered,
  duplicate,
  invalidName,
  invalidEmail,
}

class CustomerRegistrationResult {
  final CustomerRegistrationStatus status;
  final MasterCustomer? customer;

  const CustomerRegistrationResult({required this.status, this.customer});

  bool get success => status == CustomerRegistrationStatus.registered;
}

// ============================================================
// REPOSITORIO EN MEMORIA
// ============================================================

class MasterCustomerRegistry {
  const MasterCustomerRegistry._();

  static final ValueNotifier<List<MasterCustomer>> customers =
      ValueNotifier<List<MasterCustomer>>(const <MasterCustomer>[]);

  static int _nextId = 1;

  static List<MasterCustomer> get all =>
      List<MasterCustomer>.unmodifiable(customers.value);

  static MasterCustomer? findById(String id) {
    for (final customer in customers.value) {
      if (customer.id == id) {
        return customer;
      }
    }

    return null;
  }

  static bool _validEmail(String email) {
    if (email.isEmpty) {
      return true;
    }

    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  static CustomerRegistrationResult register({
    required String legalName,
    String tradeName = '',
    String email = '',
    String phone = '',
  }) {
    final cleanLegalName = legalName.trim();
    final cleanTradeName = tradeName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    if (cleanLegalName.isEmpty) {
      return const CustomerRegistrationResult(
        status: CustomerRegistrationStatus.invalidName,
      );
    }

    if (!_validEmail(cleanEmail)) {
      return const CustomerRegistrationResult(
        status: CustomerRegistrationStatus.invalidEmail,
      );
    }

    final normalizedName = cleanLegalName.toLowerCase();

    final duplicate = customers.value.any(
      (customer) => customer.legalName.trim().toLowerCase() == normalizedName,
    );

    if (duplicate) {
      return const CustomerRegistrationResult(
        status: CustomerRegistrationStatus.duplicate,
      );
    }

    final customer = MasterCustomer(
      id: 'CLI-${_nextId.toString().padLeft(4, '0')}',
      legalName: cleanLegalName,
      tradeName: cleanTradeName,
      email: cleanEmail,
      phone: cleanPhone,
    );

    _nextId++;

    customers.value = List<MasterCustomer>.unmodifiable([
      ...customers.value,
      customer,
    ]);

    return CustomerRegistrationResult(
      status: CustomerRegistrationStatus.registered,
      customer: customer,
    );
  }

  // Exclusivo para aislar las pruebas automatizadas.
  // No elimina datos de ninguna base de datos.
  static void resetForTesting() {
    customers.value = const <MasterCustomer>[];
    _nextId = 1;
  }
}
