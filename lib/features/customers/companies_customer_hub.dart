import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../companies/companies_screen.dart';
import 'master_customer_registry.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// INTEGRACION DE EMPRESAS CON CLIENTES MASTER
// ============================================================

class CompaniesCustomerHub extends StatelessWidget {
  const CompaniesCustomerHub({super.key});

  Future<void> _registerCustomer(BuildContext context) async {
    final customer = await showDialog<MasterCustomer>(
      context: context,
      builder: (_) => const MasterCustomerFormDialog(),
    );

    if (!context.mounted || customer == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cliente ${customer.displayName} registrado '
          'en esta sesión. Ya puedes seleccionarlo '
          'desde Instancias.',
        ),
      ),
    );
  }

  void _showCustomers(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CustomerDirectoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<List<MasterCustomer>>(
          valueListenable: MasterCustomerRegistry.customers,
          builder: (context, customers, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                color: AdnColors.sidebar,
                border: Border(bottom: BorderSide(color: AdnColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 740;

                  final information = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clientes de Software Master',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Clientes en esta sesión: '
                        '${customers.length}',
                        key: const Key('master_customer_count'),
                        style: const TextStyle(
                          color: AdnColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );

                  final actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('master_customer_view'),
                        onPressed: () => _showCustomers(context),
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text('Ver clientes'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdnColors.white,
                          side: const BorderSide(color: AdnColors.border),
                        ),
                      ),
                      FilledButton.icon(
                        key: const Key('master_customer_add'),
                        onPressed: () => _registerCustomer(context),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        label: const Text('Registrar cliente en Master'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AdnColors.turquoise,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        information,
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: information),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  );
                },
              ),
            );
          },
        ),

        // Se conserva el modulo existente.
        // Sus formularios actuales no se eliminan.
        const Expanded(child: CompaniesScreen()),
      ],
    );
  }
}

// ============================================================
// FORMULARIO DE CLIENTES
// ============================================================

class MasterCustomerFormDialog extends StatefulWidget {
  final MasterApiClient? apiClient;

  const MasterCustomerFormDialog({super.key, this.apiClient});

  @override
  State<MasterCustomerFormDialog> createState() =>
      _MasterCustomerFormDialogState();
}

class _MasterCustomerFormDialogState extends State<MasterCustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _legalNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _registrationError;
  bool _isSaving = false;

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateLegalName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el nombre del cliente.';
    }

    if (value.trim().length < 3) {
      return 'Ingresa al menos tres caracteres.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingresa un correo válido.';
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
      prefixIcon: Icon(icon, color: AdnColors.muted, size: 20),
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 12),
      filled: true,
      fillColor: AdnColors.background,
      errorMaxLines: 3,
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _field({
    required Key key,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          validator: validator,
          style: const TextStyle(color: AdnColors.white, fontSize: 13),
          decoration: _decoration(hint, icon),
        ),
      ],
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }

    final apiClient = widget.apiClient;
    if (apiClient != null) {
      setState(() {
        _isSaving = true;
        _registrationError = null;
      });
      try {
        final response = await apiClient.post(
          'customers',
          body: {
            'legal_name': _legalNameController.text.trim(),
            'trade_name': _tradeNameController.text.trim().isEmpty
                ? null
                : _tradeNameController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          },
        );
        final data = response['data'];
        if (data is! Map) {
          throw const MasterApiException(
            'El servidor no devolvió el cliente guardado.',
          );
        }
        final record = Map<String, dynamic>.from(data);
        final customer = MasterCustomer(
          id: record['id'] as String,
          legalName: record['legal_name'] as String,
          tradeName: record['trade_name'] as String? ?? '',
          email: record['email'] as String? ?? '',
          phone: record['phone'] as String? ?? '',
        );
        if (mounted) {
          Navigator.of(context).pop(customer);
        }
      } on MasterApiException catch (error) {
        if (mounted) {
          setState(() => _registrationError = error.message);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }

      return;
    }

    final result = MasterCustomerRegistry.register(
      legalName: _legalNameController.text,
      tradeName: _tradeNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    if (result.success && result.customer != null) {
      Navigator.of(context).pop(result.customer);
      return;
    }

    setState(() {
      switch (result.status) {
        case CustomerRegistrationStatus.duplicate:
          _registrationError =
              'Ya existe un cliente con ese nombre legal '
              'en esta sesión.';
          break;

        case CustomerRegistrationStatus.invalidName:
          _registrationError = 'El nombre del cliente no es válido.';
          break;

        case CustomerRegistrationStatus.invalidEmail:
          _registrationError = 'El correo electrónico no es válido.';
          break;

        case CustomerRegistrationStatus.registered:
          _registrationError = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 620;
    final apiClient = widget.apiClient;

    return Dialog(
      backgroundColor: AdnColors.panel,
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 24,
        vertical: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AdnColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 17 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AdnColors.turquoiseLight,
                      size: 27,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Registrar cliente Master',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
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

                const SizedBox(height: 13),

                Text(
                  apiClient == null
                      ? 'Registro preliminar compartido '
                            'entre Empresas e Instancias.'
                      : 'El cliente se guardará en la base de datos central.',
                  style: TextStyle(color: AdnColors.muted, fontSize: 12),
                ),

                const SizedBox(height: 19),
                const Divider(color: AdnColors.border),
                const SizedBox(height: 17),

                _field(
                  key: const Key('customer_legal_name'),
                  label: 'Razón social o nombre del cliente *',
                  hint: 'Nombre del cliente',
                  icon: Icons.business_outlined,
                  controller: _legalNameController,
                  validator: _validateLegalName,
                ),

                const SizedBox(height: 18),

                _field(
                  key: const Key('customer_trade_name'),
                  label: 'Nombre comercial',
                  hint: 'Nombre comercial del negocio',
                  icon: Icons.storefront_outlined,
                  controller: _tradeNameController,
                ),

                const SizedBox(height: 18),

                _field(
                  key: const Key('customer_email'),
                  label: 'Correo electrónico',
                  hint: 'correo@empresa.com',
                  icon: Icons.alternate_email_rounded,
                  controller: _emailController,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 18),

                _field(
                  key: const Key('customer_phone'),
                  label: 'Teléfono',
                  hint: 'Número de contacto',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                ),

                if (_registrationError != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _registrationError!,
                    key: const Key('customer_error'),
                    style: const TextStyle(
                      color: AdnColors.coral,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AdnColors.turquoise.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AdnColors.turquoise.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Text(
                    'Los datos se conservarán únicamente '
                    'mientras esta aplicación permanezca '
                    'en ejecución. No se ha conectado '
                    'ninguna base de datos.',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdnColors.white,
                          side: const BorderSide(color: AdnColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton(
                        key: const Key('master_customer_save'),
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AdnColors.turquoise,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isSaving
                              ? 'Guardando…'
                              : widget.apiClient == null
                              ? 'Guardar en sesión'
                              : 'Guardar cliente',
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
      ),
    );
  }
}

// ============================================================
// CONSULTA DE CLIENTES REGISTRADOS
// ============================================================

class _CustomerDirectoryDialog extends StatelessWidget {
  const _CustomerDirectoryDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AdnColors.panel,
      title: const Text(
        'Clientes registrados en Master',
        style: TextStyle(
          color: AdnColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SizedBox(
        width: 540,
        child: ValueListenableBuilder<List<MasterCustomer>>(
          valueListenable: MasterCustomerRegistry.customers,
          builder: (context, customers, _) {
            if (customers.isEmpty) {
              return const Text(
                'Todavía no hay clientes registrados '
                'en esta sesión.',
                style: TextStyle(color: AdnColors.muted, fontSize: 12),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: customers.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AdnColors.border),
              itemBuilder: (context, index) {
                final customer = customers[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.business_outlined,
                    color: AdnColors.turquoiseLight,
                  ),
                  title: Text(
                    customer.displayName,
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${customer.id} · '
                    '${customer.legalName}',
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AdnColors.turquoiseLight),
          ),
        ),
      ],
    );
  }
}
