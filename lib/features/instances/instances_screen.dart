import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../commercial/product_plan_catalog.dart';
import '../customers/master_customer_selector.dart';
import '../customers/master_customer_registry.dart';
import 'master_instance_registry.dart';
import '../products/software_products_screen.dart';
import 'instance_pricing.dart';
import 'master_api_instances_screen.dart';

class InstancesScreen extends StatelessWidget {
  final MasterApiClient? apiClient;

  const InstancesScreen({super.key, this.apiClient});

  Future<void> _openForm(BuildContext context) async {
    final validated = await showDialog<bool>(
      context: context,
      builder: (_) => const InstanceFormDialog(),
    );

    if (!context.mounted || validated != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Borrador validado. No se creó ninguna instancia '
          'ni se contrató dominio o hosting. '
          'La vinculación con clientes y el registro real '
          'requieren el servidor central.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (apiClient != null) {
      return MasterApiInstancesScreen(apiClient: apiClient!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;
        final padding = mobile ? 18.0 : 29.0;
        final available = constraints.maxWidth - padding * 2;

        final columns = available >= 960
            ? 3
            : available >= 560
            ? 2
            : 1;

        final cardWidth = (available - 14 * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InstanceHeading(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: _NewInstanceButton(
                        onPressed: () => _openForm(context),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Expanded(child: _InstanceHeading()),
                    const SizedBox(width: 16),
                    _NewInstanceButton(onPressed: () => _openForm(context)),
                  ],
                ),

              const SizedBox(height: 25),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _InstanceMetric(
                    width: cardWidth,
                    title: 'Instancias contratadas',
                    icon: Icons.dns_rounded,
                    color: AdnColors.turquoise,
                  ),
                  _InstanceMetric(
                    width: cardWidth,
                    title: 'Instancias activas',
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                  _InstanceMetric(
                    width: cardWidth,
                    title: 'Licencias suspendidas',
                    icon: Icons.lock_clock_rounded,
                    color: AdnColors.coral,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const _InstanceNotice(),

              const SizedBox(height: 24),

              const _InstanceDirectory(),

              const SizedBox(height: 24),

              const _InstanceArchitecture(),
            ],
          ),
        );
      },
    );
  }
}

class _InstanceHeading extends StatelessWidget {
  const _InstanceHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instancias de software',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Implementaciones, dominios, hosting '
          'y licencias por cliente.',
          style: TextStyle(color: AdnColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _NewInstanceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewInstanceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_to_queue_rounded, size: 19),
      label: const Text('Nueva instancia'),
      style: FilledButton.styleFrom(
        backgroundColor: AdnColors.turquoise,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InstanceMetric extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Color color;

  const _InstanceMetric({
    required this.width,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdnColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
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

class _InstanceNotice extends StatelessWidget {
  const _InstanceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdnColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.20)),
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
              'Cada cliente podrá tener varias instancias '
              'de diferentes productos. Cada instancia '
              'tendrá sus propios recursos, suscripción '
              'y control de licencia. '
              'Los borradores locales no representan instalaciones activas.',
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
}

class _InstanceDirectory extends StatelessWidget {
  const _InstanceDirectory();

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

  Widget _emptyDirectory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 53),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AdnColors.turquoise.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: AdnColors.turquoise,
              size: 35,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sin instancias registradas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const Text(
              'Aquí aparecerán los sistemas contratados, '
              'su producto, cliente, dominio, hosting, '
              'plan y estado de licencia.',
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
    );
  }

  Widget _instanceCard(MasterInstance instance) {
    final customer = MasterCustomerRegistry.findById(instance.customerId);

    final customerName = customer?.displayName ?? 'Cliente no disponible';

    final productName = _productName(instance.productCode);

    final planName = _planName(instance.productCode, instance.planCode);

    return Container(
      key: Key('instance_record_${instance.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance.name,
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    instance.id,
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AdnColors.turquoise.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AdnColors.turquoise.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  instance.statusLabel,
                  style: const TextStyle(
                    color: AdnColors.turquoiseLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),
          const Divider(color: AdnColors.border),
          const SizedBox(height: 12),

          Wrap(
            spacing: 25,
            runSpacing: 12,
            children: [
              _detail('Cliente', customerName),
              _detail('Software', productName),
              _detail('Plan', planName),
              _detail(
                'Dominio',
                instance.domain.isEmpty ? 'No asignado' : instance.domain,
              ),
              _detail(
                'Hosting',
                instance.hostingProvider.isEmpty
                    ? 'No asignado'
                    : instance.hostingProvider,
              ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            'Proyección de cargos por 12 meses: '
            '${InstanceMoney.format(instance.pricing.customerAnnualChargeCents)}',
            style: const TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Borrador temporal. No representa '
            'una suscripción facturada ni una licencia activa.',
            style: TextStyle(color: AdnColors.muted, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _detail(String title, String value) {
    return SizedBox(
      width: 195,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AdnColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('instances_directory'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      child: ValueListenableBuilder<List<MasterInstance>>(
        valueListenable: MasterInstanceRegistry.instances,
        builder: (context, instances, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(21),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Directorio de instancias',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Borradores: ${instances.length}',
                      style: const TextStyle(
                        color: AdnColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AdnColors.border),

              if (instances.isEmpty)
                Center(child: _emptyDirectory())
              else
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < instances.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 13),
                        _instanceCard(instances[index]),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InstanceArchitecture extends StatelessWidget {
  const _InstanceArchitecture();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recursos independientes por instancia',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'El dominio, el hosting y la base de datos '
            'se asociarán a cada instalación. '
            'La base de datos operativa permanecerá '
            'separada de Software Master. '
            'Las credenciales y llaves de licencia '
            'no se almacenarán en estos formularios. '
            'Master administrará las autorizaciones '
            'a través de un servicio central seguro.',
            style: TextStyle(color: AdnColors.muted, fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORMULARIO PRELIMINAR
// ============================================================

class InstanceFormDialog extends StatefulWidget {
  const InstanceFormDialog({super.key});

  @override
  State<InstanceFormDialog> createState() => _InstanceFormDialogState();
}

class _InstanceFormDialogState extends State<InstanceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _domain = TextEditingController();
  final _hostingProvider = TextEditingController();

  final _softwareCharge = TextEditingController();
  final _hostingCost = TextEditingController();
  final _hostingCharge = TextEditingController();
  final _domainCost = TextEditingController();
  final _domainCharge = TextEditingController();

  String? _customerId;

  String _productCode = softwareCatalog.first.code;

  String? _planCode = ProductPlanCatalog.forProduct(softwareCatalog.first.code)
      .first
      .code;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _domain,
      _hostingProvider,
      _softwareCharge,
      _hostingCost,
      _hostingCharge,
      _domainCost,
      _domainCharge,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _validateDomain(String? value) {
    final domain = (value ?? '').trim().toLowerCase();

    if (domain.isEmpty) {
      return null;
    }

    final valid = RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
    ).hasMatch(domain);

    if (!valid) {
      return 'Ingresa un dominio válido, sin https:// ni rutas.';
    }

    return null;
  }

  String? _validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (InstanceMoney.parse(value) == null) {
      return 'Usa un importe válido con hasta dos decimales.';
    }

    return null;
  }

  InputDecoration _decoration({required IconData icon, required String hint}) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 12),
      prefixIcon: Icon(icon, color: AdnColors.muted, size: 20),
      filled: true,
      fillColor: AdnColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AdnColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _textField({
    required Key key,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          key: key,
          controller: controller,
          validator: validator,
          style: const TextStyle(color: AdnColors.white, fontSize: 13),
          decoration: _decoration(icon: icon, hint: hint),
        ),
      ],
    );
  }

  Widget _moneyField({
    required Key key,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateMoney,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AdnColors.white, fontSize: 13),
          decoration: _decoration(
            icon: Icons.attach_money_rounded,
            hint: 'L 0.00',
          ),
        ),
      ],
    );
  }

  Widget _pair(Widget first, Widget second, bool twoColumns) {
    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [first, const SizedBox(height: 17), second],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _unavailableClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MasterCustomerSelector(
          onChanged: (customerId) {
            setState(() {
              _customerId = customerId;
            });
          },
        ),

        if (_customerId != null) ...[
          const SizedBox(height: 8),

          const Text(
            'Cliente seleccionado para este borrador. '
            'La vinculación definitiva se realizará '
            'cuando exista el registro central.',
            style: TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _productAndPlan(bool twoColumns) {
    final availablePlans = ProductPlanCatalog.forProduct(_productCode);

    final product = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Producto de software'),

        DropdownButtonFormField<String>(
          key: const Key('instance_product'),
          initialValue: _productCode,
          isExpanded: true,
          dropdownColor: AdnColors.panel,

          decoration: _decoration(
            icon: Icons.apps_rounded,
            hint: 'Seleccionar producto',
          ),

          items: softwareCatalog.map((product) {
            return DropdownMenuItem<String>(
              value: product.code,
              child: Text(
                product.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdnColors.white, fontSize: 12),
              ),
            );
          }).toList(),

          onChanged: (code) {
            if (code == null || code == _productCode) {
              return;
            }

            final plans = ProductPlanCatalog.forProduct(code);

            setState(() {
              _productCode = code;

              _planCode = plans.isEmpty ? null : plans.first.code;
            });
          },
        ),
      ],
    );

    final plan = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Plan del producto'),

        KeyedSubtree(
          key: ValueKey('plan_for_$_productCode'),

          child: DropdownButtonFormField<String>(
            key: const Key('instance_plan'),
            initialValue: _planCode,
            isExpanded: true,
            dropdownColor: AdnColors.panel,

            decoration: _decoration(
              icon: Icons.workspace_premium_rounded,
              hint: availablePlans.isEmpty
                  ? 'Producto sin planes definidos'
                  : 'Seleccionar plan',
            ),

            items: availablePlans.map((item) {
              return DropdownMenuItem<String>(
                value: item.code,
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdnColors.white, fontSize: 12),
                ),
              );
            }).toList(),

            onChanged: availablePlans.isEmpty
                ? null
                : (code) {
                    setState(() {
                      _planCode = code;
                    });
                  },
          ),
        ),

        if (availablePlans.isEmpty) ...[
          const SizedBox(height: 8),

          const Text(
            'Este producto necesita planes propios '
            'antes de poder contratarse.',
            style: TextStyle(color: AdnColors.coral, fontSize: 11),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pair(product, plan, twoColumns),

        const SizedBox(height: 12),

        const Text(
          'Asociación preliminar: los planes '
          'se filtran por producto. '
          'El cliente deberá existir en Master '
          'antes de que esta instancia pueda '
          'contratarse o activarse.',
          style: TextStyle(color: AdnColors.muted, fontSize: 11, height: 1.6),
        ),
      ],
    );
  }

  InstancePricing? get _preview {
    final controllers = [
      _softwareCharge,
      _hostingCost,
      _hostingCharge,
      _domainCost,
      _domainCharge,
    ];

    if (controllers.any((controller) => controller.text.trim().isEmpty)) {
      return null;
    }

    final amounts = controllers
        .map((controller) => InstanceMoney.parse(controller.text))
        .toList();

    if (amounts.any((amount) => amount == null)) {
      return null;
    }

    return InstancePricing(
      softwareMonthlyChargeCents: amounts[0]!,
      hostingMonthlyCostCents: amounts[1]!,
      hostingMonthlyChargeCents: amounts[2]!,
      domainAnnualCostCents: amounts[3]!,
      domainAnnualChargeCents: amounts[4]!,
    );
  }

  Widget _pricingSummary() {
    final preview = _preview;

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
            'Proyección económica',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (preview == null)
            const Text(
              'Completa los cinco importes para revisar '
              'la proyección. Puedes escribir 0 cuando '
              'un concepto no tenga cargo.',
              style: TextStyle(
                color: AdnColors.muted,
                fontSize: 12,
                height: 1.6,
              ),
            )
          else ...[
            Text(
              'Cargos al cliente por 12 meses: '
              '${InstanceMoney.format(preview.customerAnnualChargeCents)}',
              key: const Key('instance_total_yearly'),
              style: const TextStyle(
                color: AdnColors.turquoiseLight,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Equivalente mensual aproximado: '
              '${InstanceMoney.format(preview.customerMonthlyEquivalentCents)}',
              style: const TextStyle(color: AdnColors.white, fontSize: 12),
            ),
            const SizedBox(height: 9),
            Text(
              'Costo anual de infraestructura: '
              '${InstanceMoney.format(preview.infrastructureAnnualCostCents)}',
              style: const TextStyle(color: AdnColors.white, fontSize: 12),
            ),
            const SizedBox(height: 9),
            Text(
              'Diferencia antes de otros gastos: '
              '${InstanceMoney.format(preview.preliminaryContributionCents)}',
              style: const TextStyle(color: AdnColors.white, fontSize: 12),
            ),
          ],
          const SizedBox(height: 13),
          const Text(
            'Proyección ilustrativa, no factura ni utilidad '
            'neta. No incluye impuestos, cambios de precio, '
            'soporte, operación o cargos de instalación.',
            style: TextStyle(color: AdnColors.muted, fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _saveInSession() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_customerId == null || _customerId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un cliente registrado '
            'antes de guardar la instancia.',
          ),
        ),
      );
      return;
    }

    if (_planCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un plan válido '
            'para el producto.',
          ),
        ),
      );
      return;
    }

    final pricing = _preview;

    if (pricing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa los cinco importes. '
            'Escribe 0 cuando no exista un cargo o costo.',
          ),
        ),
      );
      return;
    }

    final result = MasterInstanceRegistry.register(
      name: _name.text,
      customerId: _customerId!,
      productCode: _productCode,
      planCode: _planCode!,
      domain: _domain.text,
      hostingProvider: _hostingProvider.text,
      pricing: pricing,
    );

    if (!result.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    // Devuelve false porque no es solo una validacion.
    // Evita mostrar el mensaje antiguo de borrador validado.
    Navigator.of(context).pop(false);

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _validate() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Solo se revisan datos.
    // No se registra una instancia, licencia o contrato.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 740,
          maxHeight: size.height * 0.82,
        ),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.add_to_queue_rounded,
                    color: AdnColors.turquoiseLight,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva instancia',
                          style: TextStyle(
                            color: AdnColors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Configuración preliminar',
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

              const SizedBox(height: 16),
              const Divider(height: 1, color: AdnColors.border),

              Flexible(
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 610;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormHeading(
                              'Identificación de la instancia',
                            ),
                            const SizedBox(height: 17),

                            _textField(
                              key: const Key('instance_name'),
                              label: 'Nombre de la instancia *',
                              controller: _name,
                              icon: Icons.dns_outlined,
                              hint: 'Ej. Sede principal',
                              validator: _required,
                            ),

                            const SizedBox(height: 17),
                            _unavailableClient(),

                            const SizedBox(height: 17),
                            _productAndPlan(twoColumns),

                            const SizedBox(height: 23),
                            const Divider(color: AdnColors.border),
                            const SizedBox(height: 17),

                            const _FormHeading('Infraestructura independiente'),
                            const SizedBox(height: 17),

                            _pair(
                              _textField(
                                key: const Key('instance_domain'),
                                label: 'Dominio',
                                controller: _domain,
                                icon: Icons.language_rounded,
                                hint: 'ejemplo.hn',
                                validator: _validateDomain,
                              ),
                              _textField(
                                key: const Key('instance_host'),
                                label: 'Proveedor de hosting',
                                controller: _hostingProvider,
                                icon: Icons.cloud_outlined,
                                hint: 'Proveedor asignado',
                              ),
                              twoColumns,
                            ),

                            const SizedBox(height: 12),
                            const Text(
                              'La base de datos independiente '
                              'se configurará desde el servidor. '
                              'No ingreses contraseñas aquí.',
                              style: TextStyle(
                                color: AdnColors.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 23),
                            const Divider(color: AdnColors.border),
                            const SizedBox(height: 17),

                            const _FormHeading('Costos y cargos en lempiras'),
                            const SizedBox(height: 10),
                            const Text(
                              'Costo: lo pagamos al proveedor. '
                              'Cargo: lo facturamos al cliente.',
                              style: TextStyle(
                                color: AdnColors.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 17),

                            _moneyField(
                              key: const Key('instance_software_fee'),
                              label: 'Precio del software (mensual)',
                              controller: _softwareCharge,
                            ),

                            const SizedBox(height: 17),

                            _pair(
                              _moneyField(
                                key: const Key('instance_host_cost'),
                                label: 'Costo del hosting (mensual)',
                                controller: _hostingCost,
                              ),
                              _moneyField(
                                key: const Key('instance_host_charge'),
                                label: 'Cargo por hosting (mensual)',
                                controller: _hostingCharge,
                              ),
                              twoColumns,
                            ),

                            const SizedBox(height: 17),

                            _pair(
                              _moneyField(
                                key: const Key('instance_domain_cost'),
                                label: 'Costo del dominio (anual)',
                                controller: _domainCost,
                              ),
                              _moneyField(
                                key: const Key('instance_domain_charge'),
                                label: 'Cargo por dominio (anual)',
                                controller: _domainCharge,
                              ),
                              twoColumns,
                            ),

                            const SizedBox(height: 23),
                            _pricingSummary(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Divider(height: 1, color: AdnColors.border),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('instance_save_session'),
                  onPressed: _saveInSession,
                  icon: const Icon(Icons.save_outlined, size: 19),
                  label: const Text('Guardar en sesión'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdnColors.turquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      key: const Key('instance_validate'),
                      onPressed: _validate,
                      style: FilledButton.styleFrom(
                        backgroundColor: AdnColors.turquoise,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Validar borrador'),
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

class _FormHeading extends StatelessWidget {
  final String text;

  const _FormHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AdnColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
