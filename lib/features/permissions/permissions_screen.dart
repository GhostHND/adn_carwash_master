import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../master_users/master_api_admin_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// MATRIZ PRELIMINAR DE PERMISOS
// ============================================================

enum MasterRole { administrator, operator, viewer }

enum PermissionAction { view, create, edit, manage }

class PermissionModule {
  final String id;
  final String name;
  final String group;
  final IconData icon;
  final List<PermissionAction> actions;

  const PermissionModule({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    required this.actions,
  });
}

const permissionModules = <PermissionModule>[
  PermissionModule(
    id: 'dashboard',
    name: 'Dashboard',
    group: 'GENERAL',
    icon: Icons.dashboard_rounded,
    actions: [PermissionAction.view],
  ),
  PermissionModule(
    id: 'empresas',
    name: 'Empresas',
    group: 'GESTION EMPRESARIAL',
    icon: Icons.business_rounded,
    actions: PermissionAction.values,
  ),
  PermissionModule(
    id: 'planes',
    name: 'Planes',
    group: 'GESTION EMPRESARIAL',
    icon: Icons.workspace_premium_rounded,
    actions: [
      PermissionAction.view,
      PermissionAction.edit,
      PermissionAction.manage,
    ],
  ),
  PermissionModule(
    id: 'suscripciones',
    name: 'Suscripciones',
    group: 'GESTION EMPRESARIAL',
    icon: Icons.credit_card_rounded,
    actions: PermissionAction.values,
  ),
  PermissionModule(
    id: 'pagos',
    name: 'Pagos',
    group: 'GESTION EMPRESARIAL',
    icon: Icons.receipt_long_rounded,
    actions: [
      PermissionAction.view,
      PermissionAction.create,
      PermissionAction.edit,
    ],
  ),
  PermissionModule(
    id: 'usuarios_master',
    name: 'Usuarios Master',
    group: 'ADMINISTRACION',
    icon: Icons.supervisor_account_rounded,
    actions: PermissionAction.values,
  ),
  PermissionModule(
    id: 'administradores',
    name: 'Administradores',
    group: 'ADMINISTRACION',
    icon: Icons.manage_accounts_rounded,
    actions: PermissionAction.values,
  ),
  PermissionModule(
    id: 'permisos',
    name: 'Permisos',
    group: 'ADMINISTRACION',
    icon: Icons.admin_panel_settings_rounded,
    actions: [PermissionAction.view, PermissionAction.manage],
  ),
  PermissionModule(
    id: 'estado_empresas',
    name: 'Estado de empresas',
    group: 'SISTEMA',
    icon: Icons.monitor_heart_rounded,
    actions: [
      PermissionAction.view,
      PermissionAction.edit,
      PermissionAction.manage,
    ],
  ),
  PermissionModule(
    id: 'monitoreo',
    name: 'Monitoreo',
    group: 'SISTEMA',
    icon: Icons.analytics_rounded,
    actions: [PermissionAction.view],
  ),
  PermissionModule(
    id: 'respaldos',
    name: 'Respaldos',
    group: 'SISTEMA',
    icon: Icons.backup_rounded,
    actions: [PermissionAction.view, PermissionAction.manage],
  ),
  PermissionModule(
    id: 'auditoria',
    name: 'Auditor\u00eda',
    group: 'SISTEMA',
    icon: Icons.fact_check_rounded,
    actions: [PermissionAction.view],
  ),
  PermissionModule(
    id: 'ajustes',
    name: 'Ajustes generales',
    group: 'CONFIGURACION',
    icon: Icons.settings_rounded,
    actions: [PermissionAction.view, PermissionAction.manage],
  ),
];

// ============================================================
// PANTALLA PRINCIPAL
// ============================================================

class PermissionsScreen extends StatefulWidget {
  final MasterApiClient? apiClient;

  const PermissionsScreen({super.key, this.apiClient});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  MasterRole _selectedRole = MasterRole.operator;

  late Map<MasterRole, Map<String, Set<PermissionAction>>> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _defaultPermissions();
  }

  // ==========================================================
  // PERMISOS INICIALES DE DEMOSTRACION
  // ==========================================================

  Map<MasterRole, Map<String, Set<PermissionAction>>> _defaultPermissions() {
    final administrator = <String, Set<PermissionAction>>{};

    final operator = <String, Set<PermissionAction>>{};

    final viewer = <String, Set<PermissionAction>>{};

    for (final module in permissionModules) {
      administrator[module.id] = {...module.actions};

      operator[module.id] = <PermissionAction>{};
      viewer[module.id] = <PermissionAction>{};
    }

    operator['dashboard'] = {PermissionAction.view};

    operator['empresas'] = {
      PermissionAction.view,
      PermissionAction.create,
      PermissionAction.edit,
    };

    operator['planes'] = {PermissionAction.view};

    operator['suscripciones'] = {
      PermissionAction.view,
      PermissionAction.create,
      PermissionAction.edit,
    };

    operator['pagos'] = {PermissionAction.view, PermissionAction.create};

    operator['estado_empresas'] = {PermissionAction.view};

    operator['monitoreo'] = {PermissionAction.view};

    viewer['dashboard'] = {PermissionAction.view};

    viewer['empresas'] = {PermissionAction.view};

    viewer['planes'] = {PermissionAction.view};

    viewer['suscripciones'] = {PermissionAction.view};

    viewer['pagos'] = {PermissionAction.view};

    viewer['monitoreo'] = {PermissionAction.view};

    return {
      MasterRole.administrator: administrator,
      MasterRole.operator: operator,
      MasterRole.viewer: viewer,
    };
  }

  // ==========================================================
  // CONFIGURACION DE ROLES
  // ==========================================================

  String _roleLabel(MasterRole role) {
    switch (role) {
      case MasterRole.administrator:
        return 'Administrador Master';
      case MasterRole.operator:
        return 'Operador Master';
      case MasterRole.viewer:
        return 'Consulta Master';
    }
  }

  String _roleDescription(MasterRole role) {
    switch (role) {
      case MasterRole.administrator:
        return 'Acceso completo a las operaciones '
            'disponibles. Este rol no se puede '
            'modificar desde la matriz.';

      case MasterRole.operator:
        return 'Permisos operativos configurables '
            'por m\u00f3dulo. Los cambios son '
            'temporales durante esta etapa.';

      case MasterRole.viewer:
        return 'Acceso exclusivo de lectura. '
            'No puede crear, editar ni '
            'administrar registros.';
    }
  }

  bool _isLocked(PermissionAction action) {
    if (_selectedRole == MasterRole.administrator) {
      return true;
    }

    if (_selectedRole == MasterRole.viewer && action != PermissionAction.view) {
      return true;
    }

    return false;
  }

  // ==========================================================
  // ACTIVAR O DESACTIVAR UN PERMISO
  // ==========================================================

  void _setPermission(
    PermissionModule module,
    PermissionAction action,
    bool enabled,
  ) {
    if (_isLocked(action)) {
      return;
    }

    if (!module.actions.contains(action)) {
      return;
    }

    setState(() {
      final permissions = _permissions[_selectedRole]![module.id]!;

      if (action == PermissionAction.view && !enabled) {
        // Sin consulta no hay otras acciones.
        permissions.clear();
        return;
      }

      if (enabled) {
        permissions.add(action);

        // Las acciones superiores necesitan consulta.
        permissions.add(PermissionAction.view);
      } else {
        permissions.remove(action);
      }
    });
  }

  // ==========================================================
  // RESTABLECER LA CONFIGURACION LOCAL
  // ==========================================================

  void _resetCurrentRole() {
    if (_selectedRole == MasterRole.administrator) {
      return;
    }

    final defaults = _defaultPermissions();

    setState(() {
      _permissions[_selectedRole] = defaults[_selectedRole]!;
    });
  }

  int _enabledCount() {
    final modules = _permissions[_selectedRole]!;

    return modules.values.fold<int>(
      0,
      (total, actions) => total + actions.length,
    );
  }

  int _visibleModulesCount() {
    final modules = _permissions[_selectedRole]!;

    return modules.values
        .where((actions) => actions.contains(PermissionAction.view))
        .length;
  }

  // ==========================================================
  // CABECERA
  // ==========================================================

  Widget _pageHeading(bool mobile) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permisos',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Configuraci\u00f3n de acceso '
          'para los usuarios Master.',
          style: TextStyle(color: AdnColors.muted, fontSize: 13),
        ),
      ],
    );

    final status = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AdnColors.turquoise.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_outlined,
            color: AdnColors.turquoiseLight,
            size: 17,
          ),
          SizedBox(width: 8),
          Text(
            'Configuraci\u00f3n de prueba',
            style: TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [heading, const SizedBox(height: 18), status],
      );
    }

    return Row(
      children: [
        Expanded(child: heading),
        const SizedBox(width: 16),
        status,
      ],
    );
  }

  // ==========================================================
  // SELECTOR DE ROLES
  // ==========================================================

  Widget _roleSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar rol',
            style: TextStyle(
              color: AdnColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final role in MasterRole.values)
                ChoiceChip(
                  key: Key('role_${role.name}'),
                  label: Text(_roleLabel(role)),
                  selected: _selectedRole == role,
                  selectedColor: AdnColors.turquoise,
                  backgroundColor: AdnColors.background,
                  side: BorderSide(
                    color: _selectedRole == role
                        ? AdnColors.turquoise
                        : AdnColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: _selectedRole == role
                        ? Colors.white
                        : AdnColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            _roleDescription(_selectedRole),
            style: const TextStyle(
              color: AdnColors.muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _smallMetric(
                Icons.apps_rounded,
                '${_visibleModulesCount()} m\u00f3dulos visibles',
              ),

              _smallMetric(
                Icons.check_circle_outline_rounded,
                '${_enabledCount()} permisos habilitados',
              ),

              if (_selectedRole != MasterRole.administrator)
                OutlinedButton.icon(
                  key: const Key('reset_role_permissions'),
                  onPressed: _resetCurrentRole,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Restablecer cambios'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdnColors.turquoiseLight,
                    side: const BorderSide(color: AdnColors.border),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdnColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AdnColors.turquoiseLight),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABLA DE PERMISOS
  // ==========================================================

  Widget _tableHeader() {
    return Container(
      color: AdnColors.background,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      child: const Row(
        children: [
          SizedBox(
            width: 282,
            child: Text(
              'M\u00d3DULO',
              style: TextStyle(
                color: AdnColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          _PermissionColumnTitle('CONSULTAR'),
          _PermissionColumnTitle('CREAR'),
          _PermissionColumnTitle('EDITAR'),
          _PermissionColumnTitle('ADMINISTRAR'),
        ],
      ),
    );
  }

  Widget _groupHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
      color: AdnColors.sidebar,
      child: Text(
        title,
        style: const TextStyle(
          color: AdnColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _permissionCell(PermissionModule module, PermissionAction action) {
    if (!module.actions.contains(action)) {
      return const SizedBox(
        width: 132,
        child: Center(
          child: Text(
            '\u2014',
            style: TextStyle(color: AdnColors.muted, fontSize: 16),
          ),
        ),
      );
    }

    final granted = _permissions[_selectedRole]![module.id]!.contains(action);

    return SizedBox(
      width: 132,
      child: Center(
        child: Checkbox(
          key: Key(
            'permission_${_selectedRole.name}_'
            '${module.id}_${action.name}',
          ),
          value: granted,
          onChanged: _isLocked(action)
              ? null
              : (enabled) {
                  _setPermission(module, action, enabled ?? false);
                },
          activeColor: AdnColors.turquoise,
          checkColor: Colors.white,
          side: const BorderSide(color: AdnColors.muted, width: 1.4),
        ),
      ),
    );
  }

  Widget _moduleRow(PermissionModule module) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdnColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 282,
            child: Row(
              children: [
                Icon(module.icon, color: AdnColors.muted, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.name,
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          for (final action in PermissionAction.values)
            _permissionCell(module, action),
        ],
      ),
    );
  }

  Widget _permissionMatrix() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Matriz de permisos',
              style: TextStyle(
                color: AdnColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 17),
            child: Text(
              'Cada casilla controla una acci\u00f3n '
              'del rol seleccionado.',
              style: TextStyle(color: AdnColors.muted, fontSize: 12),
            ),
          ),

          const Divider(height: 1, color: AdnColors.border),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 834,
              child: Column(
                children: [
                  _tableHeader(),

                  for (
                    int index = 0;
                    index < permissionModules.length;
                    index++
                  ) ...[
                    if (index == 0 ||
                        permissionModules[index - 1].group !=
                            permissionModules[index].group)
                      _groupHeader(permissionModules[index].group),

                    _moduleRow(permissionModules[index]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVISO SOBRE SEGURIDAD Y PERSISTENCIA
  // ==========================================================

  Widget _developmentNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AdnColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.18)),
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
              'Esta matriz es una vista de desarrollo. '
              'Los cambios se aplican solamente en '
              'esta pantalla y no se guardan. '
              'Tampoco modifican el acceso real '
              'a ning\u00fan m\u00f3dulo. '
              'La verificaci\u00f3n de permisos '
              'se implementar\u00e1 en el servidor.',
              style: TextStyle(
                color: AdnColors.white,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INTERFAZ RESPONSIVE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final client = widget.apiClient;
    if (client != null) {
      return MasterApiAdminScreen(
        apiClient: client,
        mode: MasterAdminMode.roles,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;

        return SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 18 : 29),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeading(mobile),

              const SizedBox(height: 24),

              _developmentNotice(),

              const SizedBox(height: 24),

              _roleSelector(),

              const SizedBox(height: 24),

              _permissionMatrix(),

              const SizedBox(height: 18),

              const Text(
                'En pantallas peque\u00f1as puedes '
                'desplazar horizontalmente la matriz '
                'para consultar todas las acciones.',
                style: TextStyle(
                  color: AdnColors.muted,
                  fontSize: 11,
                  height: 1.6,
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
// TITULOS DE COLUMNAS
// ============================================================

class _PermissionColumnTitle extends StatelessWidget {
  final String title;

  const _PermissionColumnTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AdnColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
