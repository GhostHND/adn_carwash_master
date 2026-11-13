import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../commercial/product_plan_catalog.dart';
import '../customers/master_customer_registry.dart';
import '../instances/instance_pricing.dart';
import '../instances/master_instance_registry.dart';
import '../products/software_products_screen.dart';
import 'linked_subscription_registry.dart';
import 'subscriptions_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// SUSCRIPCIONES VINCULADAS A INSTANCIAS
// ============================================================

class LinkedSubscriptionsHub extends StatelessWidget {
  const LinkedSubscriptionsHub({super.key});

  Future<void> _openForm(BuildContext context) async {
    final result = await showDialog<LinkedSubscriptionDraft>(
      context: context,
      builder: (_) => const LinkedSubscriptionFormDialog(),
    );

    if (!context.mounted || result == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Suscripción guardada como borrador local. '
          'No se generaron pagos ni se activó una licencia.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<List<LinkedSubscriptionDraft>>(
          valueListenable: LinkedSubscriptionRegistry.subscriptions,
          builder: (context, drafts, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: const BoxDecoration(
                color: AdnColors.sidebar,
                border: Border(bottom: BorderSide(color: AdnColors.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 740;

                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suscripciones vinculadas',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Borradores locales: ${drafts.length}',
                        key: const Key('linked_subscription_count'),
                        style: const TextStyle(
                          color: AdnColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );

                  final button = FilledButton.icon(
                    key: const Key('linked_subscription_add'),
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add_card_rounded, size: 18),
                    label: const Text('Nueva suscripción vinculada'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdnColors.turquoise,
                      foregroundColor: Colors.white,
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact) ...[
                        heading,
                        const SizedBox(height: 12),
                        button,
                      ] else
                        Row(
                          children: [
                            Expanded(child: heading),
                            const SizedBox(width: 12),
                            button,
                          ],
                        ),

                      if (drafts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: (drafts.length > 2
                              ? 240.0
                              : drafts.length * 112.0),
                          child: ListView.separated(
                            itemCount: drafts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) {
                              return _LinkedDraftCard(draft: drafts[index]);
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),

        // Conservamos la pantalla existente y sus pruebas.
        // Sus formularios anteriores siguen siendo preliminares.
        const Expanded(child: SubscriptionsScreen()),
      ],
    );
  }
}

// ============================================================
// TARJETA DEL BORRADOR
// ============================================================

class _LinkedDraftCard extends StatelessWidget {
  final LinkedSubscriptionDraft draft;

  const _LinkedDraftCard({required this.draft});

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final instance = MasterInstanceRegistry.findById(draft.instanceId);

    final customer = MasterCustomerRegistry.findById(draft.customerId);

    return Container(
      key: Key('linked_subscription_record_${draft.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${draft.id} · ${instance?.name ?? draft.instanceId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${customer?.displayName ?? draft.customerId}'
            ' · ${draft.statusLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${InstanceMoney.format(draft.monthlyChargeCents)}'
            '/mes · Dominio: '
            '${InstanceMoney.format(draft.domainAnnualChargeCents)}'
            '/año · Primer cobro: '
            '${_date(draft.firstMonthlyDueDate)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdnColors.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORMULARIO DE SUSCRIPCION VINCULADA
// ============================================================

class LinkedSubscriptionFormDialog extends StatefulWidget {
  const LinkedSubscriptionFormDialog({super.key});

  @override
  State<LinkedSubscriptionFormDialog> createState() =>
      _LinkedSubscriptionFormDialogState();
}

class _LinkedSubscriptionFormDialogState
    extends State<LinkedSubscriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _monthlyDateController = TextEditingController();
  final _domainDateController = TextEditingController();

  String? _instanceId;
  String? _registrationError;

  @override
  void dispose() {
    _monthlyDateController.dispose();
    _domainDateController.dispose();
    super.dispose();
  }

  MasterInstance? get _selectedInstance {
    if (_instanceId == null) {
      return null;
    }

    return MasterInstanceRegistry.findById(_instanceId!);
  }

  DateTime? _parseDate(String input) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(input.trim());

    if (match == null) {
      return null;
    }

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    if (year < 2000 || year > 2100) {
      return null;
    }

    final date = DateTime.utc(year, month, day);

    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    return date;
  }

  String? _validateDate(String? input, {required bool requiredField}) {
    final value = input?.trim() ?? '';

    if (value.isEmpty) {
      return requiredField ? 'La fecha es obligatoria.' : null;
    }

    if (_parseDate(value) == null) {
      return 'Usa una fecha válida en formato DD/MM/AAAA.';
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
      prefixIcon: Icon(icon, size: 20, color: AdnColors.muted),
      filled: true,
      fillColor: AdnColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      errorMaxLines: 3,
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 12),
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _dateField({
    required Key key,
    required String label,
    required TextEditingController controller,
    required bool requiredField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: TextInputType.datetime,
          style: const TextStyle(color: AdnColors.white, fontSize: 13),
          decoration: _decoration('DD/MM/AAAA', Icons.calendar_month_outlined),
          validator: (value) =>
              _validateDate(value, requiredField: requiredField),
        ),
      ],
    );
  }

  String _productName(String code) {
    for (final product in softwareCatalog) {
      if (product.code == code) {
        return product.name;
      }
    }
    return code;
  }

  String _planName(String productCode, String planCode) {
    for (final plan in ProductPlanCatalog.forProduct(productCode)) {
      if (plan.code == planCode) {
        return plan.name;
      }
    }
    return planCode;
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AdnColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instanceSelector() {
    final instances = MasterInstanceRegistry.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Instancia contratada *'),
        DropdownButtonFormField<String>(
          key: const Key('linked_subscription_instance'),
          initialValue: null,
          isExpanded: true,
          dropdownColor: AdnColors.panel,
          decoration: _decoration(
            instances.isEmpty
                ? 'No hay instancias guardadas'
                : 'Seleccionar instancia',
            Icons.dns_outlined,
          ),
          items: instances.map((instance) {
            final customer = MasterCustomerRegistry.findById(
              instance.customerId,
            );

            return DropdownMenuItem<String>(
              value: instance.id,
              child: Text(
                '${instance.name} · '
                '${customer?.displayName ?? instance.customerId}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdnColors.white, fontSize: 12),
              ),
            );
          }).toList(),
          validator: (value) {
            if (value == null) {
              return 'Selecciona una instancia registrada.';
            }
            return null;
          },
          onChanged: instances.isEmpty
              ? null
              : (id) {
                  setState(() {
                    _instanceId = id;
                    _registrationError = null;
                  });
                },
        ),
        if (instances.isEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Primero registra un cliente y guarda '
            'una instancia desde Catálogo → Instancias.',
            style: TextStyle(color: AdnColors.muted, fontSize: 11, height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _pricingSummary(MasterInstance instance) {
    final pricing = instance.pricing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AdnColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Condiciones económicas de la instancia',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _detail(
            'Software mensual',
            InstanceMoney.format(pricing.softwareMonthlyChargeCents),
          ),
          _detail(
            'Hosting mensual',
            InstanceMoney.format(pricing.hostingMonthlyChargeCents),
          ),
          const Divider(color: AdnColors.border),
          const SizedBox(height: 7),
          _detail(
            'Total mensual previsto',
            InstanceMoney.format(
              pricing.softwareMonthlyChargeCents +
                  pricing.hostingMonthlyChargeCents,
            ),
          ),
          _detail(
            'Dominio anual',
            InstanceMoney.format(pricing.domainAnnualChargeCents),
          ),
          const SizedBox(height: 5),
          Text(
            'Proyección comercial de 12 meses: '
            '${InstanceMoney.format(pricing.customerAnnualChargeCents)}',
            style: const TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'La cuota mensual y el dominio anual '
            'tienen fechas de cobro diferentes. '
            'No se ha generado una factura.',
            style: TextStyle(color: AdnColors.muted, fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _save() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final selected = _selectedInstance;

    if (selected == null) {
      return;
    }

    final result = LinkedSubscriptionRegistry.register(
      instanceId: selected.id,
      firstMonthlyDueDate: _parseDate(_monthlyDateController.text),
      firstDomainDueDate: _parseDate(_domainDateController.text),
    );

    if (result.success && result.draft != null) {
      Navigator.of(context).pop(result.draft);
      return;
    }

    setState(() {
      _registrationError = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 620;
    final instance = _selectedInstance;
    final requiresDomainDate =
        (instance?.pricing.domainAnnualChargeCents ?? 0) > 0;

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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 670,
          maxHeight: size.height * 0.86,
        ),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 17 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    color: AdnColors.turquoiseLight,
                    size: 29,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Vincular suscripción',
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
              const SizedBox(height: 16),
              const Divider(height: 1, color: AdnColors.border),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 19),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecciona una instancia existente',
                          style: TextStyle(
                            color: AdnColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 17),

                        _instanceSelector(),

                        if (instance != null) ...[
                          const SizedBox(height: 19),
                          _detail(
                            'Cliente',
                            MasterCustomerRegistry.findById(instance.customerId)
                                    ?.displayName ??
                                'Cliente no disponible',
                          ),
                          _detail(
                            'Producto',
                            _productName(instance.productCode),
                          ),
                          _detail(
                            'Plan',
                            _planName(instance.productCode, instance.planCode),
                          ),
                          const SizedBox(height: 17),
                          _pricingSummary(instance),
                        ],

                        const SizedBox(height: 23),
                        const Divider(color: AdnColors.border),
                        const SizedBox(height: 17),

                        const Text(
                          'Fechas comerciales preliminares',
                          style: TextStyle(
                            color: AdnColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 17),

                        _dateField(
                          key: const Key('linked_subscription_monthly_due'),
                          label: 'Primera fecha de cobro mensual *',
                          controller: _monthlyDateController,
                          requiredField: true,
                        ),

                        const SizedBox(height: 17),

                        if (requiresDomainDate)
                          _dateField(
                            key: const Key('linked_subscription_domain_due'),
                            label:
                                'Primera fecha del cargo anual del dominio *',
                            controller: _domainDateController,
                            requiredField: true,
                          )
                        else
                          const Text(
                            'Esta instancia no tiene un cargo '
                            'anual de dominio definido.',
                            style: TextStyle(
                              color: AdnColors.muted,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),

                        if (_registrationError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _registrationError!,
                            key: const Key('linked_subscription_error'),
                            style: const TextStyle(
                              color: AdnColors.coral,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        const Text(
                          'Estas fechas son referencias '
                          'para preparar un contrato. '
                          'No crean obligaciones de pago, '
                          'facturas ni licencias activas.',
                          style: TextStyle(
                            color: AdnColors.muted,
                            fontSize: 11,
                            height: 1.6,
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
                        side: const BorderSide(color: AdnColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('linked_subscription_save'),
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdnColors.turquoise,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar borrador'),
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
