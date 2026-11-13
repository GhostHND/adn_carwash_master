import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'instance_pricing.dart';

class MasterApiInstancesScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiInstancesScreen({super.key, required this.apiClient});

  @override
  State<MasterApiInstancesScreen> createState() =>
      _MasterApiInstancesScreenState();
}

class _MasterApiInstancesScreenState extends State<MasterApiInstancesScreen> {
  late Future<_InstanceData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_InstanceData> _load() async {
    final results = await Future.wait([
      widget.apiClient.getCollection('customers'),
      widget.apiClient.getCollection('products'),
      widget.apiClient.getCollection('plans'),
      widget.apiClient.getCollection('instances'),
    ]);
    return _InstanceData(
      customers: results[0],
      products: results[1],
      plans: results[2],
      instances: results[3],
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _editInstance(
    _InstanceData data, {
    Map<String, dynamic>? instance,
  }) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _InstanceEditorDialog(data: data, instance: instance),
    );
    if (!mounted || payload == null) {
      return;
    }

    try {
      if (instance == null) {
        await widget.apiClient.post('instances', body: payload);
      } else {
        await widget.apiClient.patch(
          'instances/${instance['id']}',
          body: payload,
        );
      }
      if (!mounted) {
        return;
      }
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            instance == null
                ? 'Instancia guardada en Software Master.'
                : 'Instancia actualizada.',
          ),
        ),
      );
    } on MasterApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_formatError(error))));
    }
  }

  String _formatError(MasterApiException error) {
    final fieldErrors = error.errors.values
        .whereType<List>()
        .expand((messages) => messages.whereType<String>())
        .toList();
    return fieldErrors.isEmpty
        ? error.message
        : '${error.message} ${fieldErrors.join(' ')}';
  }

  Future<void> _linkFidelidad(Map<String, dynamic> instance) async {
    final linked = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _FidelidadLinkDialog(apiClient: widget.apiClient, instance: instance),
    );
    if (!mounted || linked != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Negocio vinculado. Su acceso actual no se ha modificado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return FutureBuilder<_InstanceData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 18 : 29),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 14,
                children: [
                  const Column(
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
                        'Registro persistido de clientes, productos e infraestructura.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: data == null ? null : () => _editInstance(data),
                    icon: const Icon(Icons.add_to_queue_rounded),
                    label: const Text('Nueva instancia'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.hasError)
                _InstanceMessage(
                  message: snapshot.error.toString(),
                  actionLabel: 'Reintentar',
                  onPressed: _reload,
                  isError: true,
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (data!.instances.isEmpty)
                const _InstanceMessage(
                  message:
                      'No hay instancias registradas en la base de datos. '
                      'El alta crea un registro en estado borrador; no '
                      'contrata servicios ni provisiona servidores.',
                )
              else
                ...data.instances.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InstanceTile(
                      instance: instance,
                      onEdit: () => _editInstance(data, instance: instance),
                      onLinkFidelidad: () => _linkFidelidad(instance),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InstanceData {
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> instances;

  const _InstanceData({
    required this.customers,
    required this.products,
    required this.plans,
    required this.instances,
  });
}

class _InstanceTile extends StatelessWidget {
  final Map<String, dynamic> instance;
  final VoidCallback onEdit;
  final VoidCallback onLinkFidelidad;

  const _InstanceTile({
    required this.instance,
    required this.onEdit,
    required this.onLinkFidelidad,
  });

  @override
  Widget build(BuildContext context) {
    final customer = instance['customer'] is Map
        ? (instance['customer'] as Map)['name'] as String? ?? ''
        : '';
    final product = instance['product'] is Map
        ? (instance['product'] as Map)['name'] as String? ?? ''
        : '';
    final plan = instance['plan'] is Map
        ? (instance['plan'] as Map)['name'] as String? ?? ''
        : '';
    final domain = instance['domain'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        border: Border.all(color: AdnColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dns_outlined, color: AdnColors.turquoiseLight),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance['name'] as String? ?? '',
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      customer,
                      product,
                      plan,
                      domain,
                    ].where((value) => value.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Chip(
            label: Text(switch (instance['provisioning_status']) {
              'ready' => 'Lista',
              'failed' => 'Fallida',
              _ => 'Borrador',
            }),
          ),
          if (instance['product'] is Map &&
              (instance['product'] as Map)['code'] == 'adn-fidelidad')
            OutlinedButton(
              onPressed: onLinkFidelidad,
              child: const Text('Vincular Fidelidad'),
            ),
          IconButton(
            tooltip: 'Editar instancia',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _FidelidadLinkDialog extends StatefulWidget {
  final MasterApiClient apiClient;
  final Map<String, dynamic> instance;

  const _FidelidadLinkDialog({required this.apiClient, required this.instance});

  @override
  State<_FidelidadLinkDialog> createState() => _FidelidadLinkDialogState();
}

class _FidelidadLinkDialogState extends State<_FidelidadLinkDialog> {
  final _query = TextEditingController();
  List<Map<String, dynamic>>? _businesses;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) {
      setState(() => _error = 'Escribe al menos dos caracteres.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _businesses = null;
    });
    try {
      final response = await widget.apiClient.post(
        'instances/${widget.instance['id']}/fidelidad/search',
        body: {'query': _query.text.trim()},
      );
      final data = response['data'];
      if (data is! List || data.any((item) => item is! Map)) {
        throw const MasterApiException(
          'La respuesta de Fidelidad no es válida.',
        );
      }
      if (!mounted) return;
      setState(() {
        _businesses = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } on MasterApiException catch (error) {
      if (mounted) setState(() => _error = _formatLinkError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _link(Map<String, dynamic> business) async {
    final uuid = business['uuid'];
    final name = business['name'];
    if (uuid is! String || name is! String) {
      setState(() => _error = 'Fidelidad devolvió un negocio inválido.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar vinculación'),
        content: Text(
          'Vincular "$name" con "${widget.instance['name']}". '
          'Esta acción no modifica sus usuarios, datos ni acceso, y no '
          'confirma pagos ni activa una suscripción. Los eventos pendientes '
          'de Master podrían cambiar el acceso después: revísalos antes '
          'de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.apiClient.post(
        'instances/${widget.instance['id']}/fidelidad/link',
        body: {'business_uuid': uuid},
      );
      if (mounted) Navigator.pop(context, true);
    } on MasterApiException catch (error) {
      if (mounted) setState(() => _error = _formatLinkError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatLinkError(MasterApiException error) {
    final details = error.errors.values
        .whereType<List>()
        .expand((messages) => messages.whereType<String>())
        .join(' ');
    return details.isEmpty ? error.message : '${error.message} $details';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vincular negocio de Fidelidad'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Busca el negocio existente y confirma que sea el correcto. '
                'Su acceso actual se conservará.',
              ),
              TextField(
                controller: _query,
                decoration: const InputDecoration(
                  labelText: 'Nombre del negocio',
                ),
                onSubmitted: (_) {
                  if (!_busy) _search();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _search,
                child: const Text('Buscar'),
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AdnColors.coral)),
              if (_businesses != null && _businesses!.isEmpty)
                const Text('No se encontraron negocios.'),
              for (final business in _businesses ?? <Map<String, dynamic>>[])
                ListTile(
                  title: Text('${business['name']}'),
                  subtitle: Text(
                    business['master_business_id'] == null
                        ? 'Disponible'
                        : business['master_business_id'] ==
                              widget.instance['id']
                        ? 'Ya vinculado a esta instancia'
                        : 'Vinculado a otra instancia',
                  ),
                  trailing: TextButton(
                    onPressed:
                        _busy ||
                            (business['master_business_id'] != null &&
                                business['master_business_id'] !=
                                    widget.instance['id'])
                        ? null
                        : () => _link(business),
                    child: const Text('Seleccionar'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _InstanceEditorDialog extends StatefulWidget {
  final _InstanceData data;
  final Map<String, dynamic>? instance;

  const _InstanceEditorDialog({required this.data, this.instance});

  @override
  State<_InstanceEditorDialog> createState() => _InstanceEditorDialogState();
}

class _InstanceEditorDialogState extends State<_InstanceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _domain = TextEditingController();
  final _hostingProvider = TextEditingController();
  final _hostingCost = TextEditingController(text: '0');
  final _hostingCharge = TextEditingController(text: '0');
  final _domainCost = TextEditingController(text: '0');
  final _domainCharge = TextEditingController(text: '0');
  final _currency = TextEditingController(text: 'HNL');
  String? _customerId;
  String? _productCode;
  String? _planId;

  @override
  void initState() {
    super.initState();
    final customers = widget.data.customers.where(
      (customer) => customer['status'] == 'active',
    );
    _customerId = customers.isEmpty ? null : customers.first['id'] as String?;
    _productCode = widget.data.products.isEmpty
        ? null
        : widget.data.products.first['code'] as String?;
    _selectFirstPlan();
    final instance = widget.instance;
    final infrastructure = instance?['infrastructure'];
    if (instance != null) {
      _name.text = instance['name'] as String? ?? '';
      _domain.text = instance['domain'] as String? ?? '';
    }
    if (infrastructure is Map) {
      _currency.text = infrastructure['currency'] as String? ?? 'HNL';
      _hostingProvider.text =
          infrastructure['hosting_provider'] as String? ?? '';
      _hostingCost.text = _amountText(infrastructure['hosting_cost_cents']);
      _hostingCharge.text = _amountText(infrastructure['hosting_charge_cents']);
      _domainCost.text = _amountText(infrastructure['domain_cost_cents']);
      _domainCharge.text = _amountText(infrastructure['domain_charge_cents']);
    }
  }

  void _selectFirstPlan() {
    final plans = _plansForProduct;
    _planId = plans.isEmpty ? null : plans.first['id'] as String?;
  }

  List<Map<String, dynamic>> get _activeCustomers => widget.data.customers
      .where((customer) => customer['status'] == 'active')
      .toList();

  List<Map<String, dynamic>> get _plansForProduct => widget.data.plans
      .where((plan) => plan['product_code'] == _productCode)
      .toList();

  @override
  void dispose() {
    _name.dispose();
    _domain.dispose();
    _hostingProvider.dispose();
    _hostingCost.dispose();
    _hostingCharge.dispose();
    _domainCost.dispose();
    _domainCharge.dispose();
    _currency.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Este campo es obligatorio.'
        : null;
  }

  String? _validateDomain(String? value) {
    final domain = (value ?? '').trim().toLowerCase();
    if (domain.isEmpty) {
      return null;
    }
    return RegExp(r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$')
            .hasMatch(domain)
        ? null
        : 'Ingresa un dominio válido, sin https:// ni rutas.';
  }

  String? _validateMoney(String? value) {
    return value != null && InstanceMoney.parse(value) != null
        ? null
        : 'Escribe un importe válido, o 0 si no aplica.';
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (widget.instance == null &&
        (_customerId == null || _productCode == null || _planId == null)) {
      return;
    }

    final infrastructure = {
      'currency': _currency.text.trim().toUpperCase(),
      'hosting_provider': _hostingProvider.text.trim().isEmpty
          ? null
          : _hostingProvider.text.trim(),
      'hosting_cost_cents': InstanceMoney.parse(_hostingCost.text),
      'hosting_charge_cents': InstanceMoney.parse(_hostingCharge.text),
      'domain_cost_cents': InstanceMoney.parse(_domainCost.text),
      'domain_charge_cents': InstanceMoney.parse(_domainCharge.text),
    };

    if (widget.instance != null) {
      Navigator.of(context).pop({
        'name': _name.text.trim(),
        'domain': _domain.text.trim().isEmpty ? null : _domain.text.trim(),
        'infrastructure': infrastructure,
      });
      return;
    }

    Navigator.of(context).pop({
      'customer_id': _customerId,
      'product_code': _productCode,
      'plan_id': _planId,
      'name': _name.text.trim(),
      'domain': _domain.text.trim().isEmpty ? null : _domain.text.trim(),
      'environment': 'production',
      'infrastructure': infrastructure,
    });
  }

  String _amountText(Object? cents) {
    return cents is num ? (cents / 100).toStringAsFixed(2) : '0';
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.data.products;
    final customers = _activeCustomers;
    final plans = _plansForProduct;
    final isEditing = widget.instance != null;
    return AlertDialog(
      backgroundColor: AdnColors.panel,
      title: Text(
        isEditing ? 'Editar instancia' : 'Nueva instancia',
        style: const TextStyle(color: AdnColors.white),
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditing) ...[
                  _linkedDirectorySummary(widget.instance!),
                ] else ...[
                  DropdownButtonFormField<String>(
                    key: const Key('api_instance_customer'),
                    initialValue: _customerId,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer['id'] as String,
                            child: Text(
                              customer['trade_name'] as String? ??
                                  customer['legal_name'] as String? ??
                                  '',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _customerId = value),
                    validator: (value) => value == null
                        ? 'Registra y selecciona un cliente activo.'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    key: const Key('api_instance_product'),
                    initialValue: _productCode,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product['code'] as String,
                            child: Text(product['name'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _productCode = value;
                        _selectFirstPlan();
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Registra un producto.' : null,
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'api_instance_plan_${_productCode ?? 'none'}',
                    ),
                    initialValue: _planId,
                    decoration: InputDecoration(
                      labelText: 'Plan',
                      helperText: plans.isEmpty
                          ? 'Crea primero un plan para este producto.'
                          : null,
                    ),
                    items: plans
                        .map(
                          (plan) => DropdownMenuItem(
                            value: plan['id'] as String,
                            child: Text(plan['name'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _planId = value),
                    validator: (value) => value == null
                        ? 'Selecciona un plan del producto.'
                        : null,
                  ),
                ],
                TextFormField(
                  key: const Key('api_instance_name'),
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la instancia',
                    hintText: 'Sede principal',
                  ),
                  validator: _required,
                ),
                TextFormField(
                  key: const Key('api_instance_domain'),
                  controller: _domain,
                  decoration: const InputDecoration(
                    labelText: 'Dominio (opcional)',
                    hintText: 'ejemplo.hn',
                  ),
                  validator: _validateDomain,
                ),
                TextFormField(
                  controller: _hostingProvider,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor de hosting (opcional)',
                  ),
                ),
                TextFormField(
                  controller: _currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  validator: (value) =>
                      value != null && RegExp(r'^[A-Za-z]{3}$').hasMatch(value)
                      ? null
                      : 'Indica la moneda con tres letras.',
                ),
                _moneyField(
                  key: const Key('api_instance_host_cost'),
                  label: 'Costo de hosting mensual',
                  controller: _hostingCost,
                ),
                _moneyField(
                  key: const Key('api_instance_host_charge'),
                  label: 'Cargo de hosting mensual',
                  controller: _hostingCharge,
                ),
                _moneyField(
                  key: const Key('api_instance_domain_cost'),
                  label: 'Costo de dominio anual',
                  controller: _domainCost,
                ),
                _moneyField(
                  key: const Key('api_instance_domain_charge'),
                  label: 'Cargo de dominio anual',
                  controller: _domainCharge,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Se guardará como borrador. El precio del software '
                    'pertenece al plan; aquí se registran costos y cargos '
                    'de infraestructura. No se contrata ni provisiona nada.',
                    style: TextStyle(
                      color: AdnColors.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('api_instance_save'),
          onPressed: _submit,
          child: Text(isEditing ? 'Guardar cambios' : 'Guardar borrador'),
        ),
      ],
    );
  }

  Widget _linkedDirectorySummary(Map<String, dynamic> instance) {
    final customer = instance['customer'] is Map
        ? (instance['customer'] as Map)['name'] as String? ?? ''
        : '';
    final product = instance['product'] is Map
        ? (instance['product'] as Map)['name'] as String? ?? ''
        : '';
    final plan = instance['plan'] is Map
        ? (instance['plan'] as Map)['name'] as String? ?? ''
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$customer · $product · $plan',
          style: const TextStyle(color: AdnColors.muted, fontSize: 12),
        ),
      ),
    );
  }

  Widget _moneyField({
    required Key key,
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: _validateMoney,
    );
  }
}

class _InstanceMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isError;

  const _InstanceMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        border: Border.all(color: isError ? AdnColors.coral : AdnColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: AdnColors.white, height: 1.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
