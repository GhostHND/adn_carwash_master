import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../console/master_commercial_console.dart';

enum MasterAdminMode { users, roles }

class MasterApiAdminScreen extends StatefulWidget {
  final MasterApiClient apiClient;
  final MasterAdminMode mode;

  const MasterApiAdminScreen({
    super.key,
    required this.apiClient,
    required this.mode,
  });

  @override
  State<MasterApiAdminScreen> createState() => _MasterApiAdminScreenState();
}

class _MasterApiAdminScreenState extends State<MasterApiAdminScreen> {
  late Future<_AdminData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_AdminData> _load() async {
    if (widget.mode == MasterAdminMode.users) {
      final result = await Future.wait([
        widget.apiClient.getCollection('users'),
        widget.apiClient.getCollection('roles'),
      ]);
      return _AdminData(users: result[0], roles: result[1]);
    }

    final result = await Future.wait([
      widget.apiClient.getCollection('roles'),
      widget.apiClient.getCollection('permissions'),
    ]);
    return _AdminData(roles: result[0], permissions: result[1]);
  }

  void _reload() => setState(() => _data = _load());

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatError(MasterApiException error) {
    final details = error.errors.values
        .whereType<List>()
        .expand((messages) => messages.whereType<String>())
        .toList();
    return details.isEmpty
        ? error.message
        : '${error.message} ${details.join(' ')}';
  }

  Future<void> _openUserForm(
    _AdminData data, {
    Map<String, dynamic>? user,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _UserFormDialog(roles: data.roles, user: user),
    );
    if (!mounted || payload == null) return;

    try {
      if (user == null) {
        await widget.apiClient.post('users', body: payload);
      } else {
        await widget.apiClient.patch('users/${user['id']}', body: payload);
      }
      _reload();
      _showMessage(user == null ? 'Usuario creado.' : 'Usuario actualizado.');
    } on MasterApiException catch (error) {
      _showMessage(_formatError(error));
    }
  }

  Future<void> _setUserActive(Map<String, dynamic> user, bool isActive) async {
    try {
      await widget.apiClient.patch(
        'users/${user['id']}',
        body: {'is_active': isActive},
      );
      _reload();
      _showMessage(isActive ? 'Usuario activado.' : 'Usuario desactivado.');
    } on MasterApiException catch (error) {
      _showMessage(_formatError(error));
    }
  }

  Future<void> _openRoleForm(
    _AdminData data, {
    Map<String, dynamic>? role,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _RoleFormDialog(permissions: data.permissions, role: role),
    );
    if (!mounted || payload == null) return;

    try {
      if (role == null) {
        await widget.apiClient.post('roles', body: payload);
      } else {
        await widget.apiClient.patch('roles/${role['id']}', body: payload);
      }
      _reload();
      _showMessage(role == null ? 'Rol creado.' : 'Rol actualizado.');
    } on MasterApiException catch (error) {
      _showMessage(_formatError(error));
    }
  }

  Future<void> _setRoleActive(Map<String, dynamic> role, bool isActive) async {
    try {
      await widget.apiClient.patch(
        'roles/${role['id']}',
        body: {'is_active': isActive},
      );
      _reload();
      _showMessage(isActive ? 'Rol activado.' : 'Rol desactivado.');
    } on MasterApiException catch (error) {
      _showMessage(_formatError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersMode = widget.mode == MasterAdminMode.users;
    return FutureBuilder<_AdminData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      usersMode ? 'Usuarios Master' : 'Roles y permisos',
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: data == null
                        ? null
                        : () => usersMode
                              ? _openUserForm(data)
                              : _openRoleForm(data),
                    icon: const Icon(Icons.add),
                    label: Text(usersMode ? 'Nuevo usuario' : 'Nuevo rol'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                usersMode
                    ? 'Las cuentas y roles se guardan en la base de datos.'
                    : 'Asigna únicamente los permisos necesarios para cada rol.',
                style: const TextStyle(color: AdnColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                _AdminMessage(
                  message: snapshot.error.toString(),
                  action: _reload,
                  actionLabel: 'Reintentar',
                  isError: true,
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(45),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (usersMode)
                if (data!.users.isEmpty)
                  const _AdminMessage(message: 'No hay usuarios registrados.')
                else
                  for (final user in data.users)
                    _UserCard(
                      user: user,
                      onEdit: () => _openUserForm(data, user: user),
                      onActiveChanged: (value) => _setUserActive(user, value),
                    )
              else if (data!.roles.isEmpty)
                const _AdminMessage(message: 'No hay roles registrados.')
              else
                for (final role in data.roles)
                  _RoleCard(
                    role: role,
                    onEdit: role['code'] == 'owner'
                        ? null
                        : () => _openRoleForm(data, role: role),
                    onActiveChanged: role['code'] == 'owner'
                        ? null
                        : (value) => _setRoleActive(role, value),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminData {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> permissions;

  const _AdminData({
    this.users = const [],
    this.roles = const [],
    this.permissions = const [],
  });
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = _maps(user['roles'])
        .map((role) => role['name'] as String? ?? role['code'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
    final isOwner = _maps(user['roles']).any((role) => role['code'] == 'owner');
    final isActive = user['is_active'] == true;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: MasterConsoleCard(
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AdnColors.turquoiseLight),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] as String? ?? '',
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user['email']} · ${roles.isEmpty ? 'Sin rol' : roles}',
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isOwner) Switch(value: isActive, onChanged: onActiveChanged),
            IconButton(
              tooltip: 'Editar usuario',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onActiveChanged;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final permissions = _maps(role['permissions'])
        .map((permission) => permission['code'] as String? ?? '')
        .where((code) => code.isNotEmpty)
        .join(', ');
    final owner = role['code'] == 'owner';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: MasterConsoleCard(
        child: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              color: AdnColors.turquoiseLight,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${role['name']} · ${role['code']}',
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    permissions.isEmpty
                        ? 'Sin permisos asignados'
                        : permissions,
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!owner)
              Switch(
                value: role['is_active'] == true,
                onChanged: onActiveChanged,
              ),
            IconButton(
              tooltip: owner ? 'El rol owner es inmutable' : 'Editar permisos',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> roles;
  final Map<String, dynamic>? user;

  const _UserFormDialog({required this.roles, this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final Set<int> _selectedRoles;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?['name'] as String? ?? '');
    _email = TextEditingController(text: user?['email'] as String? ?? '');
    _password = TextEditingController();
    _selectedRoles = _maps(user?['roles'])
        .map((role) => role['id'])
        .whereType<int>()
        .toSet();
    _isActive = user?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'is_active': _isActive,
      'role_ids': _selectedRoles.toList(),
    };
    if (_password.text.isNotEmpty) payload['password'] = _password.text;
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.user != null;
    final existingOwner = _selectedRoles.any(
      (id) => widget.roles.any(
        (role) => role['id'] == id && role['code'] == 'owner',
      ),
    );
    final roleOptions = widget.roles.where(
      (role) => role['code'] != 'owner' || existingOwner,
    );

    return AlertDialog(
      title: Text(editing ? 'Editar usuario' : 'Crear usuario'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Indica el nombre.'
                      : null,
                ),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())
                      ? 'Indica un correo válido.'
                      : null,
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: editing
                        ? 'Nueva contraseña (opcional)'
                        : 'Contraseña (mínimo 12 caracteres)',
                  ),
                  validator: (value) {
                    if (!editing && (value == null || value.isEmpty)) {
                      return 'La contraseña es obligatoria.';
                    }
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length < 12) {
                      return 'Usa al menos 12 caracteres.';
                    }
                    return null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cuenta activa'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Roles'),
                  ),
                ),
                for (final role in roleOptions)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(role['name'] as String? ?? ''),
                    subtitle: Text(role['code'] as String? ?? ''),
                    value: _selectedRoles.contains(role['id']),
                    onChanged: role['code'] == 'owner'
                        ? null
                        : (enabled) => setState(() {
                            final id = role['id'] as int;
                            if (enabled == true) {
                              _selectedRoles.add(id);
                            } else {
                              _selectedRoles.remove(id);
                            }
                          }),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _RoleFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> permissions;
  final Map<String, dynamic>? role;

  const _RoleFormDialog({required this.permissions, this.role});

  @override
  State<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<_RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final Set<int> _selectedPermissions;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    _code = TextEditingController(text: role?['code'] as String? ?? '');
    _name = TextEditingController(text: role?['name'] as String? ?? '');
    _description = TextEditingController(
      text: role?['description'] as String? ?? '',
    );
    _selectedPermissions = _maps(role?['permissions'])
        .map((permission) => permission['id'])
        .whereType<int>()
        .toSet();
    _isActive = role?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'code': _code.text.trim().toLowerCase(),
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'is_active': _isActive,
      'permission_ids': _selectedPermissions.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.role != null;
    return AlertDialog(
      title: Text(editing ? 'Editar rol' : 'Crear rol'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _code,
                  enabled: !editing,
                  decoration: const InputDecoration(
                    labelText: 'Código del rol',
                    hintText: 'billing_operator',
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]*$')
                              .hasMatch(value.trim())
                      ? 'Usa letras, números, guion o guion bajo.'
                      : null,
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Indica el nombre.'
                      : null,
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rol activo'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Permisos'),
                  ),
                ),
                for (final permission in widget.permissions)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(permission['code'] as String? ?? ''),
                    subtitle: Text(permission['description'] as String? ?? ''),
                    value: _selectedPermissions.contains(permission['id']),
                    onChanged: (enabled) => setState(() {
                      final id = permission['id'] as int;
                      if (enabled == true) {
                        _selectedPermissions.add(id);
                      } else {
                        _selectedPermissions.remove(id);
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar rol')),
      ],
    );
  }
}

class _AdminMessage extends StatelessWidget {
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final bool isError;

  const _AdminMessage({
    required this.message,
    this.action,
    this.actionLabel,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return MasterConsoleCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AdnColors.coral : AdnColors.muted,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: action, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Respuesta administrativa inválida.');
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('La respuesta no contiene una lista válida.');
  }
  return value.map(_map).toList();
}
