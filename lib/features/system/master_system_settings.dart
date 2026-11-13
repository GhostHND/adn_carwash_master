import 'package:flutter/foundation.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// CONFIGURACION LOCAL PRELIMINAR
// ============================================================

class MasterSystemSettings {
  final String supportPhone;
  final String supportEmail;
  final int defaultGraceDays;
  final int backupRetentionDays;

  const MasterSystemSettings({
    required this.supportPhone,
    required this.supportEmail,
    required this.defaultGraceDays,
    required this.backupRetentionDays,
  });

  // Valores iniciales de desarrollo.
  // No constituyen políticas comerciales definitivas.
  static const initial = MasterSystemSettings(
    supportPhone: '',
    supportEmail: '',
    defaultGraceDays: 7,
    backupRetentionDays: 30,
  );
}

class MasterSystemSettingsStore {
  const MasterSystemSettingsStore._();

  static final ValueNotifier<MasterSystemSettings> current =
      ValueNotifier<MasterSystemSettings>(MasterSystemSettings.initial);

  static String? validate({
    required String supportPhone,
    required String supportEmail,
    required int defaultGraceDays,
    required int backupRetentionDays,
  }) {
    if (defaultGraceDays < 0 || defaultGraceDays > 30) {
      return 'El plazo de gracia debe estar '
          'entre 0 y 30 días.';
    }

    if (backupRetentionDays < 1 || backupRetentionDays > 365) {
      return 'La retención debe estar '
          'entre 1 y 365 días.';
    }

    final email = supportEmail.trim();

    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'El correo de soporte no es válido.';
    }

    if (supportPhone.trim().length > 40) {
      return 'El teléfono de soporte es demasiado largo.';
    }

    return null;
  }

  static String? save({
    required String supportPhone,
    required String supportEmail,
    required int defaultGraceDays,
    required int backupRetentionDays,
  }) {
    final error = validate(
      supportPhone: supportPhone,
      supportEmail: supportEmail,
      defaultGraceDays: defaultGraceDays,
      backupRetentionDays: backupRetentionDays,
    );

    if (error != null) return error;

    current.value = MasterSystemSettings(
      supportPhone: supportPhone.trim(),
      supportEmail: supportEmail.trim().toLowerCase(),
      defaultGraceDays: defaultGraceDays,
      backupRetentionDays: backupRetentionDays,
    );

    return null;
  }

  static void resetForTesting() {
    current.value = MasterSystemSettings.initial;
  }
}
