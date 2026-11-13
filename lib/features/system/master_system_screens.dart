import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'master_api_audit_screen.dart';
import '../console/master_commercial_console.dart';
import 'master_system_settings.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// PANTALLAS DE ADMINISTRACION CENTRAL
// ============================================================

class _SystemHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SystemHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AdnColors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AdnColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SystemSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _SystemSection({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MasterConsoleCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AdnColors.turquoise.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AdnColors.turquoiseLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AdnColors.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sin conectar',
                  style: const TextStyle(
                    color: AdnColors.turquoiseLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODULO DE RESPALDOS
// ============================================================

class MasterBackupsScreen extends StatelessWidget {
  const MasterBackupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return ValueListenableBuilder<MasterSystemSettings>(
      valueListenable: MasterSystemSettingsStore.current,
      builder: (context, settings, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SystemHeading(
                title: 'Respaldos',
                subtitle:
                    'Copias de seguridad y recuperación '
                    'de los datos administrados.',
              ),
              const SizedBox(height: 23),
              const MasterConsoleNotice(
                message:
                    'Todavía no existe un servicio de respaldos '
                    'conectado. No se ha verificado ni generado '
                    'ninguna copia de seguridad desde Master. '
                    'Los respaldos reales requerirán acceso '
                    'seguro al servidor correspondiente.',
              ),
              const SizedBox(height: 23),
              const _SystemSection(
                title: 'Base de datos central',
                description:
                    'Respaldo de productos, clientes, '
                    'instancias, contratos, cobros y '
                    'configuración administrativa.',
                icon: Icons.storage_rounded,
              ),
              const SizedBox(height: 14),
              const _SystemSection(
                title: 'Bases de datos de las instancias',
                description:
                    'Cada instancia conservará una base de '
                    'datos independiente. Sus respaldos '
                    'necesitarán autorización y un destino '
                    'seguro adecuado al hosting contratado.',
                icon: Icons.dns_rounded,
              ),
              const SizedBox(height: 14),
              const _SystemSection(
                title: 'Archivos de las instalaciones',
                description:
                    'Documentos y recursos de cada producto '
                    'que deban incluirse en la recuperación.',
                icon: Icons.folder_copy_outlined,
              ),
              const SizedBox(height: 23),
              MasterConsoleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Política de respaldo preliminar',
                      style: TextStyle(
                        color: AdnColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Retención propuesta: '
                      '${settings.backupRetentionDays} días',
                      key: const Key('backup_retention'),
                      style: const TextStyle(
                        color: AdnColors.turquoiseLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Esta cifra es una configuración '
                      'local de referencia. No está '
                      'activando ninguna programación '
                      'ni eliminando respaldos antiguos.',
                      style: TextStyle(
                        color: AdnColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.backup_outlined, size: 19),
                      label: Text('Ejecutar respaldo (sin conectar)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              const MasterConsoleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de respaldos',
                      style: TextStyle(
                        color: AdnColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 22),
                    Center(
                      child: Text(
                        'Sin ejecuciones verificadas',
                        key: Key('backups_empty'),
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 13),
                    Text(
                      'El historial real mostrará fecha, '
                      'instancia o servicio, resultado, '
                      'ubicación protegida y verificación '
                      'de integridad. También deberá '
                      'permitir comprobar la restauración.',
                      style: TextStyle(
                        color: AdnColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// MODULO DE AUDITORIA
// ============================================================

class MasterAuditScreen extends StatelessWidget {
  final MasterApiClient? apiClient;

  const MasterAuditScreen({super.key, this.apiClient});

  @override
  Widget build(BuildContext context) {
    final client = apiClient;
    if (client != null) {
      return MasterApiAuditScreen(apiClient: client);
    }

    final compact = MediaQuery.sizeOf(context).width < 720;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 28),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SystemHeading(
            title: 'Auditoría',
            subtitle:
                'Trazabilidad de las acciones '
                'administrativas de Software Master.',
          ),
          SizedBox(height: 23),
          MasterConsoleNotice(
            message:
                'La auditoría real deberá generarse desde '
                'el backend autenticado. Esta pantalla '
                'todavía no recibe eventos del servidor. '
                'Las acciones locales de desarrollo '
                'no se presentan como registros confiables.',
          ),
          SizedBox(height: 23),
          _SystemSection(
            title: 'Acceso y autenticación',
            description:
                'Inicio y cierre de sesión, intentos '
                'fallidos, recuperación de acceso '
                'y cambios de credenciales.',
            icon: Icons.security_rounded,
          ),
          SizedBox(height: 14),
          _SystemSection(
            title: 'Operaciones comerciales',
            description:
                'Cambios en clientes, productos, '
                'instancias, contratos, cargos '
                'y pagos confirmados.',
            icon: Icons.receipt_long_rounded,
          ),
          SizedBox(height: 14),
          _SystemSection(
            title: 'Licencias y restricciones',
            description:
                'Suspensiones, reactivaciones, '
                'cambios de permisos y decisiones '
                'administrativas por instancia.',
            icon: Icons.vpn_key_rounded,
          ),
          SizedBox(height: 14),
          _SystemSection(
            title: 'Respaldo y recuperación',
            description:
                'Solicitudes, ejecuciones, '
                'restauraciones y fallas '
                'de las tareas de respaldo.',
            icon: Icons.backup_rounded,
          ),
          SizedBox(height: 23),
          MasterConsoleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro de eventos',
                  style: TextStyle(
                    color: AdnColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 19),
                Center(
                  child: Text(
                    'Sin eventos recibidos del servidor',
                    key: Key('audit_empty'),
                    style: TextStyle(color: AdnColors.muted, fontSize: 13),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Cada evento verificable deberá '
                  'identificar el usuario, acción, '
                  'recurso, fecha del servidor, '
                  'resultado y contexto autorizado. '
                  'La auditoría no se podrá editar '
                  'desde esta interfaz.',
                  style: TextStyle(
                    color: AdnColors.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODULO DE AJUSTES GENERALES
// ============================================================

class MasterSettingsScreen extends StatefulWidget {
  const MasterSettingsScreen({super.key});

  @override
  State<MasterSettingsScreen> createState() => _MasterSettingsScreenState();
}

class _MasterSettingsScreenState extends State<MasterSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _grace;
  late final TextEditingController _retention;

  @override
  void initState() {
    super.initState();

    final settings = MasterSystemSettingsStore.current.value;

    _phone = TextEditingController(text: settings.supportPhone);

    _email = TextEditingController(text: settings.supportEmail);

    _grace = TextEditingController(text: '${settings.defaultGraceDays}');

    _retention = TextEditingController(text: '${settings.backupRetentionDays}');
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _grace.dispose();
    _retention.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return null;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Correo electrónico inválido.';
    }

    return null;
  }

  String? _validateInteger(
    String? value, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < min || parsed > max) {
      return 'Ingresa un número entre $min y $max.';
    }

    return null;
  }

  Widget _field({
    required String title,
    required TextEditingController controller,
    required Key key,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            key: key,
            controller: controller,
            keyboardType: keyboard,
            validator: validator,
            style: const TextStyle(color: AdnColors.white, fontSize: 13),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final error = MasterSystemSettingsStore.save(
      supportPhone: _phone.text,
      supportEmail: _email.text,
      defaultGraceDays: int.parse(_grace.text.trim()),
      backupRetentionDays: int.parse(_retention.text.trim()),
    );

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Configuración guardada en memoria. '
          'No se han modificado ajustes del servidor.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SystemHeading(
            title: 'Ajustes generales',
            subtitle:
                'Configuración administrativa '
                'de ADN Publicidad Software Master.',
          ),
          const SizedBox(height: 23),
          const MasterConsoleNotice(
            message:
                'Los ajustes se conservarán únicamente '
                'durante esta sesión de desarrollo. '
                'No modifican contratos existentes, '
                'servidores, tareas programadas '
                'ni autorizaciones de licencias.',
          ),
          const SizedBox(height: 23),
          MasterConsoleCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atención al cliente',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    key: const Key('settings_phone'),
                    title: 'Teléfono de soporte',
                    controller: _phone,
                    keyboard: TextInputType.phone,
                    validator: (value) {
                      if ((value ?? '').trim().length > 40) {
                        return 'Máximo 40 caracteres.';
                      }
                      return null;
                    },
                  ),
                  _field(
                    key: const Key('settings_email'),
                    title: 'Correo de soporte',
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const Divider(color: AdnColors.border),
                  const SizedBox(height: 18),
                  const Text(
                    'Políticas preliminares',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    key: const Key('settings_grace'),
                    title: 'Días de gracia predeterminados (0-30)',
                    controller: _grace,
                    keyboard: TextInputType.number,
                    validator: (value) =>
                        _validateInteger(value, min: 0, max: 30),
                  ),
                  _field(
                    key: const Key('settings_retention'),
                    title: 'Retención propuesta de respaldos (1-365)',
                    controller: _retention,
                    keyboard: TextInputType.number,
                    validator: (value) =>
                        _validateInteger(value, min: 1, max: 365),
                  ),
                  const Text(
                    'Estos parámetros todavía no '
                    'se aplican automáticamente '
                    'al motor de licencias ni '
                    'a tareas de respaldo.',
                    style: TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('settings_save'),
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, size: 19),
                    label: const Text('Guardar configuración local'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdnColors.turquoise,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 23),
          const _SystemSection(
            title: 'Configuración técnica del servidor',
            description:
                'URL de API, autenticación, correo '
                'transaccional, almacenamiento de '
                'respaldos y conexiones protegidas. '
                'Se configurarán en el backend '
                'mediante variables de entorno.',
            icon: Icons.settings_ethernet_rounded,
          ),
        ],
      ),
    );
  }
}
