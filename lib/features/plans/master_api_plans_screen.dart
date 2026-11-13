import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';

class MasterApiPlansScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiPlansScreen({super.key, required this.apiClient});

  @override
  State<MasterApiPlansScreen> createState() => _MasterApiPlansScreenState();
}

class _MasterApiPlansScreenState extends State<MasterApiPlansScreen> {
  late Future<_PlanData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_PlanData> _load() async {
    final results = await Future.wait([
      widget.apiClient.getCollection('products'),
      widget.apiClient.getCollection('plans'),
    ]);
    return _PlanData(products: results[0], plans: results[1]);
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _editPlan({
    required List<Map<String, dynamic>> products,
    Map<String, dynamic>? plan,
  }) async {
    if (products.isEmpty) {
      _showMessage('Registra primero un producto de software.');
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PlanEditorDialog(products: products, plan: plan),
    );
    if (!mounted || payload == null) {
      return;
    }

    try {
      if (plan == null) {
        await widget.apiClient.post('plans', body: payload);
      } else {
        await widget.apiClient.patch('plans/${plan['id']}', body: payload);
      }

      if (!mounted) {
        return;
      }
      _reload();
      _showMessage(
        plan == null
            ? 'Plan guardado en Software Master.'
            : 'Plan actualizado.',
      );
    } on MasterApiException catch (error) {
      if (mounted) {
        _showMessage(_formatError(error));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;

    return FutureBuilder<_PlanData>(
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
                        'Planes de suscripción',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Planes persistidos en Software Master.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: data == null
                        ? null
                        : () => _editPlan(products: data.products),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo plan'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.hasError)
                _PlanMessage(
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
              else if (data!.products.isEmpty)
                const _PlanMessage(
                  message:
                      'No hay productos registrados. Crea primero un producto.',
                )
              else if (data.plans.isEmpty)
                const _PlanMessage(
                  message:
                      'Aún no hay planes en la base de datos. Los planes se '
                      'guardan como borradores hasta definir precio, período '
                      'y funcionalidades.',
                )
              else
                ...data.plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanTile(
                      plan: plan,
                      onEdit: () =>
                          _editPlan(products: data.products, plan: plan),
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

class _PlanData {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> plans;

  const _PlanData({required this.products, required this.plans});
}

class _PlanTile extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onEdit;

  const _PlanTile({required this.plan, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final price = plan['price_cents'];
    final currency = plan['currency'] as String?;
    final period = plan['billing_period'] as String?;
    final features = plan['features'] is List
        ? (plan['features'] as List)
        : const [];
    final amount = price is num && currency != null
        ? '$currency ${(price / 100).toStringAsFixed(2)} / ${_periodLabel(period)}'
        : 'Precio por definir';
    final status = plan['status'] as String? ?? 'draft';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        border: Border.all(color: AdnColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, color: AdnColors.turquoiseLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] as String? ?? '',
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${plan['product_code'] ?? ''} · ${plan['code'] ?? ''} · $amount',
                  style: const TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '${features.length} funcionalidades configuradas',
                  style: const TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(label: Text(_statusLabel(status))),
          IconButton(
            tooltip: 'Editar plan',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  String _periodLabel(String? period) {
    return switch (period) {
      'monthly' => 'mes',
      'quarterly' => 'trimestre',
      'yearly' => 'año',
      'one_time' => 'único',
      _ => 'período por definir',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => 'Activo',
      'retired' => 'Retirado',
      _ => 'Borrador',
    };
  }
}

class _PlanEditorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? plan;

  const _PlanEditorDialog({required this.products, this.plan});

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _features;
  late String? _productCode;
  late String _billingPeriod;
  late String _status;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _code = TextEditingController(text: plan?['code'] as String? ?? '');
    _name = TextEditingController(text: plan?['name'] as String? ?? '');
    _price = TextEditingController(text: _priceText(plan?['price_cents']));
    _currency = TextEditingController(
      text: plan?['currency'] as String? ?? 'HNL',
    );
    final features = plan?['features'];
    _features = TextEditingController(
      text: features is List
          ? features
                .whereType<Map>()
                .map((item) => item['feature_code'])
                .whereType<String>()
                .join('\n')
          : '',
    );
    _productCode =
        plan?['product_code'] as String? ??
        (widget.products.isEmpty
            ? null
            : widget.products.first['code'] as String?);
    _billingPeriod = plan?['billing_period'] as String? ?? 'monthly';
    _status = plan?['status'] as String? ?? 'draft';
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _price.dispose();
    _currency.dispose();
    _features.dispose();
    super.dispose();
  }

  String _priceText(Object? cents) {
    if (cents is! num) {
      return '';
    }
    return (cents / 100).toStringAsFixed(2);
  }

  int? _parseCents(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(normalized)) {
      return null;
    }
    final parts = normalized.split('.');
    final whole = int.tryParse(parts[0]);
    final fraction = parts.length == 1
        ? 0
        : int.tryParse(parts[1].padRight(2, '0'));
    if (whole == null || fraction == null) {
      return null;
    }
    return whole * 100 + fraction;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final existingFeatures = widget.plan?['features'];
    final existingByCode = <String, Map<String, dynamic>>{};
    if (existingFeatures is List) {
      for (final feature in existingFeatures.whereType<Map>()) {
        final code = feature['feature_code'];
        if (code is String) {
          existingByCode[code] = Map<String, dynamic>.from(feature);
        }
      }
    }

    final features = _features.text
        .split(RegExp(r'[\n,;]'))
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .map((feature) {
          return existingByCode[feature] ??
              {'feature_code': feature, 'enabled': true, 'limit_value': null};
        })
        .toList();
    final cents = _price.text.trim().isEmpty ? null : _parseCents(_price.text);
    Navigator.of(context).pop({
      if (widget.plan == null) 'product_code': _productCode,
      'code': _code.text.trim(),
      'name': _name.text.trim(),
      'price_cents': cents,
      'currency': cents == null ? null : _currency.text.trim().toUpperCase(),
      'billing_period': cents == null ? null : _billingPeriod,
      'status': _status,
      'features': features,
    });
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Este campo es obligatorio.'
        : null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return _parseCents(value) == null
        ? 'Usa un importe válido con máximo dos decimales.'
        : null;
  }

  String? _validateFeatures(String? value) {
    final entries = (value ?? '')
        .split(RegExp(r'[\n,;]'))
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty);
    for (final feature in entries) {
      if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(feature)) {
        return 'Usa códigos en minúsculas, por ejemplo wallet.google.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;

    return AlertDialog(
      backgroundColor: AdnColors.panel,
      title: Text(
        isEditing ? 'Editar plan' : 'Nuevo plan',
        style: const TextStyle(color: AdnColors.white),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEditing)
                  DropdownButtonFormField<String>(
                    key: const Key('plan_product'),
                    initialValue: _productCode,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: widget.products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product['code'] as String,
                            child: Text(product['name'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _productCode = value),
                    validator: (value) =>
                        value == null ? 'Selecciona un producto.' : null,
                  ),
                TextFormField(
                  key: const Key('plan_code'),
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Código del plan',
                    hintText: 'basico',
                  ),
                  validator: _required,
                ),
                TextFormField(
                  key: const Key('plan_name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: _required,
                ),
                TextFormField(
                  key: const Key('plan_price'),
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio (opcional)',
                    hintText: 'Por definir',
                  ),
                  validator: _validatePrice,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _billingPeriod,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                    DropdownMenuItem(
                      value: 'quarterly',
                      child: Text('Trimestral'),
                    ),
                    DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    DropdownMenuItem(value: 'one_time', child: Text('Único')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _billingPeriod = value);
                    }
                  },
                ),
                TextFormField(
                  controller: _currency,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Moneda',
                    hintText: 'HNL',
                  ),
                  validator: (value) {
                    if (_price.text.trim().isEmpty) {
                      return null;
                    }
                    return value != null &&
                            RegExp(r'^[A-Za-z]{3}$').hasMatch(value)
                        ? null
                        : 'Indica la moneda con tres letras.';
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Borrador')),
                    DropdownMenuItem(value: 'active', child: Text('Activo')),
                    DropdownMenuItem(value: 'retired', child: Text('Retirado')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                TextFormField(
                  controller: _features,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Códigos de funcionalidades',
                    hintText: 'Una por línea, ej. wallet.google',
                  ),
                  validator: _validateFeatures,
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
          key: const Key('plan_save'),
          onPressed: _submit,
          child: const Text('Guardar plan'),
        ),
      ],
    );
  }
}

class _PlanMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isError;

  const _PlanMessage({
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
