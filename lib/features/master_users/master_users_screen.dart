import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'master_api_admin_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// ADMINISTRACION DE USUARIOS MASTER
// ============================================================

class MasterUsersScreen extends StatelessWidget {
  final MasterApiClient? apiClient;

  const MasterUsersScreen({super.key, this.apiClient});

  Future<void> _openUserForm(BuildContext context) async {
    final validated = await showDialog<bool>(
      context: context,
      builder: (_) => const MasterUserFormDialog(),
    );

    if (!context.mounted || validated != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdnColors.panel,
        content: Text(
          'Datos validados correctamente. '
          'El usuario no ha sido registrado '
          'porque el servidor todav\u00eda '
          'no est\u00e1 conectado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = apiClient;
    if (client != null) {
      return MasterApiAdminScreen(
        apiClient: client,
        mode: MasterAdminMode.users,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;
        final padding = mobile ? 18.0 : 29.0;
        final available = constraints.maxWidth - padding * 2;

        final columns = available >= 900
            ? 3
            : available >= 530
            ? 2
            : 1;

        final cardWidth = (available - 16 * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _UsersHeading(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: _NewUserButton(
                        onPressed: () => _openUserForm(context),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Expanded(child: _UsersHeading()),
                    const SizedBox(width: 16),
                    _NewUserButton(onPressed: () => _openUserForm(context)),
                  ],
                ),

              const SizedBox(height: 26),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _UserMetric(
                    width: cardWidth,
                    label: 'Usuarios registrados',
                    icon: Icons.groups_rounded,
                    color: AdnColors.turquoise,
                  ),
                  _UserMetric(
                    width: cardWidth,
                    label: 'Usuarios activos',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                  _UserMetric(
                    width: cardWidth,
                    label: 'Usuarios suspendidos',
                    icon: Icons.person_off_rounded,
                    color: AdnColors.coral,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdnColors.turquoise.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AdnColors.turquoise.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AdnColors.turquoiseLight,
                      size: 21,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La administraci\u00f3n de usuarios '
                        'est\u00e1 en desarrollo. '
                        'Todav\u00eda no se crean cuentas, '
                        'no se asignan permisos reales '
                        'ni se env\u00edan correos.',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdnColors.panel,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AdnColors.border),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Directorio de usuarios Master',
                              style: TextStyle(
                                color: AdnColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.manage_accounts_outlined,
                            color: AdnColors.muted,
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AdnColors.border),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 55,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: AdnColors.turquoise.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: const Icon(
                              Icons.group_add_rounded,
                              color: AdnColors.turquoise,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 19),
                          const Text(
                            'No hay usuarios para mostrar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AdnColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 11),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: const Text(
                              'Cuando conectemos el servidor, '
                              'aqu\u00ed aparecer\u00e1n las cuentas '
                              'autorizadas para administrar '
                              'ADN Publicidad Software Master.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AdnColors.muted,
                                fontSize: 12,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
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
// ENCABEZADO
// ============================================================

class _UsersHeading extends StatelessWidget {
  const _UsersHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usuarios Master',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Administraci\u00f3n de cuentas '
          'de acceso a la plataforma.',
          style: TextStyle(color: AdnColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

// ============================================================
// BOTON DE NUEVO USUARIO
// ============================================================

class _NewUserButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewUserButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text('Nuevo usuario'),
      style: FilledButton.styleFrom(
        backgroundColor: AdnColors.turquoise,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ============================================================
// INDICADORES
// ============================================================

class _UserMetric extends StatelessWidget {
  final double width;
  final String label;
  final IconData icon;
  final Color color;

  const _UserMetric({
    required this.width,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AdnColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sin conectar',
                  style: TextStyle(color: AdnColors.muted, fontSize: 12),
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
// FORMULARIO DE REGISTRO PRELIMINAR
// ============================================================

class MasterUserFormDialog extends StatefulWidget {
  const MasterUserFormDialog({super.key});

  @override
  State<MasterUserFormDialog> createState() => _MasterUserFormDialogState();
}

class _MasterUserFormDialogState extends State<MasterUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  String _role = 'Administrador Master';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa un correo electr\u00f3nico.';
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingresa un correo electr\u00f3nico v\u00e1lido.';
    }

    return null;
  }

  InputDecoration _decoration(String hint, IconData icon) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 12),
      prefixIcon: Icon(icon, size: 20, color: AdnColors.muted),
      filled: true,
      fillColor: AdnColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          color: AdnColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _validate() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // No se crea ninguna cuenta hasta conectar
    // la API y el servicio de correo.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    final availableHeight = size.height - keyboardHeight - 36;

    final height = math.min(580.0, math.max(250.0, availableHeight));

    final mobile = size.width < 620;

    return Dialog(
      backgroundColor: AdnColors.panel,
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 24,
        vertical: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdnColors.border),
      ),
      child: SizedBox(
        width: 610,
        height: height,
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AdnColors.turquoiseLight,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo usuario Master',
                          style: TextStyle(
                            color: AdnColors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Datos iniciales de la cuenta',
                          style: TextStyle(
                            color: AdnColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AdnColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Divider(height: 1, color: AdnColors.border),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 19),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Nombre completo *'),
                        TextFormField(
                          key: const Key('master_user_name'),
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                          style: const TextStyle(color: AdnColors.white),
                          decoration: _decoration(
                            'Nombre y apellido',
                            Icons.person_outline_rounded,
                          ),
                        ),

                        const SizedBox(height: 19),

                        _label('Correo electr\u00f3nico *'),
                        TextFormField(
                          key: const Key('master_user_email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          validator: _validateEmail,
                          style: const TextStyle(color: AdnColors.white),
                          decoration: _decoration(
                            'usuario@empresa.com',
                            Icons.alternate_email_rounded,
                          ),
                        ),

                        const SizedBox(height: 19),

                        _label('Rol preliminar *'),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          dropdownColor: AdnColors.panel,
                          style: const TextStyle(
                            color: AdnColors.white,
                            fontSize: 13,
                          ),
                          decoration: _decoration(
                            'Selecciona un rol',
                            Icons.admin_panel_settings_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Administrador Master',
                              child: Text('Administrador Master'),
                            ),
                            DropdownMenuItem(
                              value: 'Operador Master',
                              child: Text('Operador Master'),
                            ),
                            DropdownMenuItem(
                              value: 'Consulta Master',
                              child: Text('Consulta Master'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _role = value);
                            }
                          },
                        ),

                        const SizedBox(height: 22),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AdnColors.turquoise.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AdnColors.turquoise.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Los roles son preliminares: '
                            'sus permisos se definir\u00e1n '
                            'en el m\u00f3dulo Permisos. '
                            'Cuando implementemos el servidor, '
                            'cada usuario podr\u00e1 establecer '
                            'su propia contrase\u00f1a '
                            'mediante un enlace seguro.',
                            style: TextStyle(
                              color: AdnColors.white,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AdnColors.border),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdnColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AdnColors.border),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _validate,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdnColors.turquoise,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Validar datos',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
