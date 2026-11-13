import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../console/master_commercial_console.dart';

class MasterApiBillingScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiBillingScreen({super.key, required this.apiClient});

  @override
  State<MasterApiBillingScreen> createState() => _MasterApiBillingScreenState();
}

class _MasterApiBillingScreenState extends State<MasterApiBillingScreen> {
  late Future<_BillingData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_BillingData> _load() async {
    final result = await Future.wait([
      widget.apiClient.getCollection('subscriptions'),
      widget.apiClient.getCollection('charges'),
      widget.apiClient.getCollection('payments'),
      widget.apiClient.getCollection('instances'),
    ]);

    return _BillingData(
      subscriptions: result[0],
      charges: result[1],
      payments: result[2],
      instances: result[3],
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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

  Future<void> _createSubscription(_BillingData data) async {
    final result = await showDialog<_SubscriptionFormResult>(
      context: context,
      builder: (_) => _SubscriptionFormDialog(instances: data.instances),
    );
    if (!mounted || result == null) return;

    try {
      final response = await widget.apiClient.post(
        'subscriptions',
        body: {
          'instance_id': result.instanceId,
          'currency': result.currency,
          'starts_on': result.item['effective_from'],
        },
      );
      final subscription = _map(response['data'], 'subscription');
      final id = subscription['id'] as String;
      await widget.apiClient.put(
        'subscriptions/$id/items',
        body: {
          'items': [result.item],
        },
      );
      _reload();
      _message('Suscripción borrador y partida guardadas.');
    } on MasterApiException catch (error) {
      _reload();
      _message(_formatError(error));
    }
  }

  Future<void> _editItems(Map<String, dynamic> subscription) async {
    final existingItems = _maps(subscription['items']);
    final result = await showDialog<_SubscriptionFormResult>(
      context: context,
      builder: (_) => _SubscriptionFormDialog(
        instances: const [],
        subscription: subscription,
        existingItem: existingItems.isEmpty ? null : existingItems.first,
      ),
    );
    if (!mounted || result == null) return;

    try {
      await widget.apiClient.put(
        'subscriptions/${subscription['id']}/items',
        body: {
          'starts_on': result.item['effective_from'],
          'items': [result.item],
        },
      );
      _reload();
      _message('Partidas de suscripción actualizadas.');
    } on MasterApiException catch (error) {
      _message(_formatError(error));
    }
  }

  Future<void> _createInitialCharge(Map<String, dynamic> subscription) async {
    final items = _maps(subscription['items']);
    if (items.isEmpty) {
      _message('Agrega una partida con importe antes de emitir el cargo.');
      return;
    }

    final dueDate =
        (items.map((item) => item['effective_from'] as String).toList()..sort())
            .first;
    final amount = items
        .where((item) => item['effective_from'] == dueDate)
        .fold<int>(0, (total, item) => total + _int(item['amount_cents']));
    if (amount <= 0) {
      _message('Agrega una partida con importe antes de emitir el cargo.');
      return;
    }
    final confirmed = await _confirm(
      'Emitir cargo inicial',
      'Se emitirá un cargo por ${_money(amount, subscription['currency'] as String)} '
          'con vencimiento $dueDate. Confirma que el importe y la fecha sean correctos.',
      confirmLabel: 'Emitir cargo',
    );
    if (!mounted || !confirmed) return;

    try {
      await widget.apiClient.post(
        'subscriptions/${subscription['id']}/initial-charge',
        body: {'expected_due_date': dueDate, 'expected_amount_cents': amount},
      );
      _reload();
      _message('Cargo inicial emitido. Registra el pago al recibirlo.');
    } on MasterApiException catch (error) {
      _reload();
      _message(_formatError(error));
    }
  }

  Future<void> _voidCharge(Map<String, dynamic> charge) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _VoidChargeDialog(),
    );
    if (!mounted || reason == null) return;
    await _runApiAction(
      () => widget.apiClient.post(
        'charges/${charge['id']}/void',
        body: {'reason': reason},
      ),
      'Cargo anulado. Se conservó su historial.',
    );
  }

  Future<void> _activateSubscription(Map<String, dynamic> subscription) async {
    final confirmed = await _confirm(
      'Activar suscripción',
      'Sólo se activará si existe un cargo emitido totalmente cubierto por pagos confirmados.',
      confirmLabel: 'Activar',
    );
    if (!mounted || !confirmed) return;

    await _runApiAction(
      () => widget.apiClient.post(
        'subscriptions/${subscription['id']}/activate',
        body: const {},
      ),
      'Suscripción activada.',
    );
  }

  Future<void> _cancelSubscription(Map<String, dynamic> subscription) async {
    final confirmed = await _confirm(
      'Cancelar suscripción',
      'La cancelación es inmediata: detiene cargos futuros, pero no revierte cargos ya emitidos ni genera reembolsos.',
      confirmLabel: 'Cancelar suscripción',
    );
    if (!mounted || !confirmed) return;

    await _runApiAction(
      () => widget.apiClient.post(
        'subscriptions/${subscription['id']}/cancel',
        body: const {},
      ),
      'Suscripción cancelada.',
    );
  }

  Future<void> _recordPayment(
    Map<String, dynamic> subscription,
    _BillingData data,
  ) async {
    final customerId = _customerIdForSubscription(subscription, data);
    if (customerId == null) {
      _message('No se encontró el cliente de esta suscripción.');
      return;
    }

    final result = await showDialog<_PaymentFormResult>(
      context: context,
      builder: (_) =>
          _PaymentFormDialog(currency: subscription['currency'] as String),
    );
    if (!mounted || result == null) return;

    await _runApiAction(
      () => widget.apiClient.post(
        'payments',
        body: {
          'customer_id': customerId,
          'amount_cents': result.amountCents,
          'currency': subscription['currency'],
          'payment_method': 'manual',
          if (result.reference.isNotEmpty)
            'external_reference': result.reference,
          'idempotency_key': _uuidV4(),
        },
      ),
      'Pago registrado como pendiente de verificación.',
    );
  }

  Future<void> _confirmPayment(Map<String, dynamic> payment) async {
    final confirmed = await _confirm(
      'Confirmar pago recibido',
      'Usa esta acción sólo después de verificar que el dinero fue recibido.',
      confirmLabel: 'Confirmar pago',
    );
    if (!mounted || !confirmed) return;

    await _runApiAction(
      () => widget.apiClient.post(
        'payments/${payment['id']}/confirm',
        body: const {},
      ),
      'Pago confirmado.',
    );
  }

  Future<void> _allocatePayment(
    Map<String, dynamic> payment,
    _BillingData data,
  ) async {
    final customerId = payment['customer_id'];
    final eligibleCharges = data.charges.where((charge) {
      if (charge['status'] != 'issued' ||
          _int(charge['allocated_cents']) >= _int(charge['amount_cents'])) {
        return false;
      }
      final subscription = _findById(
        data.subscriptions,
        charge['subscription_id'],
      );
      return subscription != null &&
          _customerIdForSubscription(subscription, data) == customerId;
    }).toList();
    if (eligibleCharges.isEmpty) {
      _message('No hay cargos emitidos para este cliente.');
      return;
    }

    final result = await showDialog<_AllocationFormResult>(
      context: context,
      builder: (_) =>
          _AllocationFormDialog(payment: payment, charges: eligibleCharges),
    );
    if (!mounted || result == null) return;

    await _runApiAction(
      () => widget.apiClient.post(
        'payments/${payment['id']}/allocations',
        body: {
          'charge_id': result.chargeId,
          'amount_cents': result.amountCents,
        },
      ),
      'Pago asignado al cargo.',
    );
  }

  Future<void> _runApiAction(
    Future<Map<String, dynamic>> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _reload();
      _message(successMessage);
    } on MasterApiException catch (error) {
      _message(_formatError(error));
    }
  }

  Future<bool> _confirm(
    String title,
    String message, {
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  String? _customerIdForSubscription(
    Map<String, dynamic> subscription,
    _BillingData data,
  ) {
    final instance = _findById(data.instances, subscription['instance_id']);
    final customer = instance?['customer'];
    return customer is Map ? customer['id'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return FutureBuilder<_BillingData>(
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
                        'Suscripciones y facturación',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Pagos manuales verificados por un owner.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: data == null || data.instances.isEmpty
                        ? null
                        : () => _createSubscription(data),
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Nueva suscripción'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const MasterConsoleNotice(
                message:
                    'Registrar un pago no confirma que se recibió dinero. '
                    'Confirma sólo después de verificarlo. La activación exige '
                    'un cargo emitido totalmente pagado. No hay pasarela ni '
                    'reembolsos automáticos.',
              ),
              const SizedBox(height: 20),
              if (snapshot.hasError)
                _BillingMessage(
                  message: snapshot.error.toString(),
                  actionLabel: 'Reintentar',
                  onPressed: _reload,
                  isError: true,
                )
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (data!.instances.isEmpty && data.subscriptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _BillingMessage(
                      message: 'Registra una instancia antes de crear suscripciones.',
                    ),
                  ),
                _sectionTitle('Suscripciones'),
                if (data.subscriptions.isEmpty)
                  const _BillingMessage(message: 'No hay suscripciones.')
                else
                  for (final subscription in data.subscriptions)
                    _SubscriptionCard(
                      subscription: subscription,
                      data: data,
                      onEditItems: () => _editItems(subscription),
                      onCreateCharge: () => _createInitialCharge(subscription),
                      onRecordPayment: () => _recordPayment(subscription, data),
                      onActivate: () => _activateSubscription(subscription),
                      onCancel: () => _cancelSubscription(subscription),
                    ),
                const SizedBox(height: 24),
                _sectionTitle('Cargos'),
                if (data.charges.isEmpty)
                  const _BillingMessage(message: 'No hay cargos.')
                else
                  for (final charge in data.charges)
                    _ChargeTile(
                      charge: charge,
                      onVoid:
                          (charge['status'] == 'issued' ||
                                  charge['status'] == 'draft') &&
                              _int(charge['allocated_cents']) == 0
                          ? () => _voidCharge(charge)
                          : null,
                      onIssue: charge['status'] == 'draft'
                          ? () => _runApiAction(
                              () => widget.apiClient.post(
                                'charges/${charge['id']}/issue',
                                body: const {},
                              ),
                              'Cargo emitido.',
                            )
                          : null,
                    ),
                const SizedBox(height: 24),
                _sectionTitle('Pagos'),
                if (data.payments.isEmpty)
                  const _BillingMessage(message: 'No hay pagos registrados.')
                else
                  for (final payment in data.payments)
                    _PaymentTile(
                      payment: payment,
                      onConfirm: payment['confirmation_status'] == 'pending'
                          ? () => _confirmPayment(payment)
                          : null,
                      onAllocate: payment['confirmation_status'] == 'confirmed'
                          ? () => _allocatePayment(payment, data)
                          : null,
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BillingData {
  final List<Map<String, dynamic>> subscriptions;
  final List<Map<String, dynamic>> charges;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> instances;

  const _BillingData({
    required this.subscriptions,
    required this.charges,
    required this.payments,
    required this.instances,
  });
}

class _VoidChargeDialog extends StatefulWidget {
  const _VoidChargeDialog();

  @override
  State<_VoidChargeDialog> createState() => _VoidChargeDialogState();
}

class _VoidChargeDialogState extends State<_VoidChargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anular cargo'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reason,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Motivo de anulación'),
          validator: (value) => (value?.trim().length ?? 0) < 5
              ? 'Indica un motivo de al menos cinco caracteres.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reason.text.trim());
            }
          },
          child: const Text('Anular cargo'),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final _BillingData data;
  final VoidCallback onEditItems;
  final VoidCallback onCreateCharge;
  final VoidCallback onRecordPayment;
  final VoidCallback onActivate;
  final VoidCallback onCancel;

  const _SubscriptionCard({
    required this.subscription,
    required this.data,
    required this.onEditItems,
    required this.onCreateCharge,
    required this.onRecordPayment,
    required this.onActivate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final id = subscription['id'];
    final instance = _findById(data.instances, subscription['instance_id']);
    final items = _maps(subscription['items']);
    final charges = data.charges
        .where((charge) => charge['subscription_id'] == id)
        .toList();
    final hasInitialCharge = charges.any(
      (charge) => charge['status'] != 'void',
    );
    final hasPayableCharge = charges.any(
      (charge) =>
          charge['status'] == 'issued' &&
          _int(charge['allocated_cents']) < _int(charge['amount_cents']),
    );
    final status = subscription['status'] as String? ?? 'unknown';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: MasterConsoleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${instance?['name'] ?? id} · $status',
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inicio: ${subscription['starts_on'] ?? 'sin fecha'} · '
              'Moneda: ${subscription['currency']} · '
              'Partidas: ${items.length}',
              style: const TextStyle(color: AdnColors.muted, fontSize: 12),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final item in items)
                Text(
                  '${item['concept']} · ${_money(_int(item['amount_cents']), subscription['currency'] as String)} '
                  '· ${item['billing_frequency']}',
                  style: const TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'draft' && !hasInitialCharge)
                  OutlinedButton(
                    onPressed: onEditItems,
                    child: const Text('Configurar partida'),
                  ),
                if (status == 'draft' && items.isNotEmpty && !hasInitialCharge)
                  FilledButton.tonal(
                    onPressed: onCreateCharge,
                    child: const Text('Crear cargo inicial'),
                  ),
                if (hasPayableCharge)
                  OutlinedButton(
                    onPressed: onRecordPayment,
                    child: const Text('Registrar pago'),
                  ),
                if (status == 'draft')
                  OutlinedButton(
                    onPressed: onActivate,
                    child: const Text('Activar'),
                  ),
                if (status == 'active' || status == 'draft')
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar suscripción'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  final Map<String, dynamic> charge;
  final VoidCallback? onIssue;
  final VoidCallback? onVoid;

  const _ChargeTile({
    required this.charge,
    required this.onIssue,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: MasterConsoleCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${charge['concept']} · ${charge['status'] == 'void' ? 'Anulado' : charge['status']}',
                    style: const TextStyle(
                      color: AdnColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_money(_int(charge['amount_cents']), charge['currency'] as String)} · '
                    'Vence ${charge['due_date']} · '
                    'Abonado ${_money(_int(charge['allocated_cents']), charge['currency'] as String)}',
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onIssue != null)
              TextButton(onPressed: onIssue, child: const Text('Emitir')),
            if (onVoid != null)
              TextButton(onPressed: onVoid, child: const Text('Anular')),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback? onConfirm;
  final VoidCallback? onAllocate;

  const _PaymentTile({
    required this.payment,
    required this.onConfirm,
    required this.onAllocate,
  });

  @override
  Widget build(BuildContext context) {
    final allocations = _maps(payment['allocations']);
    final available =
        _int(payment['amount_cents']) -
        allocations.fold<int>(
          0,
          (total, allocation) => total + _int(allocation['amount_cents']),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: MasterConsoleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_money(_int(payment['amount_cents']), payment['currency'] as String)} · '
              '${payment['confirmation_status']}',
              style: const TextStyle(
                color: AdnColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Referencia: ${payment['external_reference'] ?? 'No indicada'} · '
              'Asignaciones: ${allocations.length}',
              style: const TextStyle(color: AdnColors.muted, fontSize: 12),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (onConfirm != null)
                  TextButton(
                    onPressed: onConfirm,
                    child: const Text('Confirmar recibido'),
                  ),
                if (onAllocate != null && available > 0)
                  TextButton(
                    onPressed: onAllocate,
                    child: const Text('Asignar a cargo'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionFormResult {
  final String instanceId;
  final String currency;
  final Map<String, dynamic> item;

  const _SubscriptionFormResult({
    required this.instanceId,
    required this.currency,
    required this.item,
  });
}

class _SubscriptionFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> instances;
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? existingItem;

  const _SubscriptionFormDialog({
    required this.instances,
    this.subscription,
    this.existingItem,
  });

  @override
  State<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends State<_SubscriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late String? _instanceId;
  late DateTime _effectiveFrom;
  String _frequency = 'monthly';

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    final subscription = widget.subscription;
    _conceptController = TextEditingController(
      text: item?['concept'] as String? ?? '',
    );
    _amountController = TextEditingController(
      text: item == null
          ? ''
          : (_int(item['amount_cents']) / 100).toStringAsFixed(2),
    );
    _currencyController = TextEditingController(
      text: subscription?['currency'] as String? ?? 'HNL',
    );
    _instanceId =
        subscription?['instance_id'] as String? ??
        (widget.instances.isEmpty
            ? null
            : widget.instances.first['id'] as String);
    _effectiveFrom =
        DateTime.tryParse(
          item?['effective_from'] as String? ??
              subscription?['starts_on'] as String? ??
              '',
        ) ??
        DateTime.now();
    _frequency = item?['billing_frequency'] as String? ?? 'monthly';
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _effectiveFrom = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _instanceId == null) return;
    final cents = _parseCents(_amountController.text);
    if (cents == null) return;
    final date = _dateString(_effectiveFrom);
    Navigator.pop(
      context,
      _SubscriptionFormResult(
        instanceId: _instanceId!,
        currency: _currencyController.text.trim().toUpperCase(),
        item: {
          'concept': _conceptController.text.trim(),
          'amount_cents': cents,
          'billing_frequency': _frequency,
          'effective_from': date,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.subscription != null;
    return AlertDialog(
      title: Text(editing ? 'Configurar partida' : 'Nueva suscripción'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!editing)
                  DropdownButtonFormField<String>(
                    initialValue: _instanceId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Instancia'),
                    items: widget.instances.map((instance) {
                      final customer = instance['customer'] is Map
                          ? (instance['customer'] as Map)['name']
                          : '';
                      return DropdownMenuItem<String>(
                        value: instance['id'] as String,
                        child: Text(
                          '${instance['name']} · $customer',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _instanceId = value),
                    validator: (value) =>
                        value == null ? 'Selecciona una instancia.' : null,
                  )
                else
                  Text(
                    'Instancia: ${widget.subscription!['instance_id']}',
                    style: const TextStyle(color: AdnColors.muted),
                  ),
                TextFormField(
                  controller: _currencyController,
                  enabled: !editing,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Moneda (ISO 4217)',
                  ),
                  validator: (value) =>
                      value != null &&
                          RegExp(r'^[A-Za-z]{3}$').hasMatch(value.trim())
                      ? null
                      : 'Usa un código de 3 letras, por ejemplo HNL.',
                ),
                TextFormField(
                  controller: _conceptController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Indica el concepto.'
                      : null,
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Importe'),
                  validator: (value) => _parseCents(value ?? '') == null
                      ? 'Indica un importe válido mayor que cero.'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                    DropdownMenuItem(
                      value: 'quarterly',
                      child: Text('Trimestral'),
                    ),
                    DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    DropdownMenuItem(
                      value: 'one_time',
                      child: Text('Única vez'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _frequency = value);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Primera fecha efectiva'),
                  subtitle: Text(_dateString(_effectiveFrom)),
                  trailing: IconButton(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_month),
                  ),
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

class _PaymentFormResult {
  final int amountCents;
  final String reference;

  const _PaymentFormResult(this.amountCents, this.reference);
}

class _PaymentFormDialog extends StatefulWidget {
  final String currency;

  const _PaymentFormDialog({required this.currency});

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final cents = _parseCents(_amountController.text);
    if (cents == null) return;
    Navigator.pop(
      context,
      _PaymentFormResult(cents, _referenceController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago pendiente'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Importe (${widget.currency})',
              ),
              validator: (value) => _parseCents(value ?? '') == null
                  ? 'Indica un importe válido.'
                  : null,
            ),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Referencia externa (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _save, child: const Text('Registrar')),
      ],
    );
  }
}

class _AllocationFormResult {
  final String chargeId;
  final int amountCents;

  const _AllocationFormResult(this.chargeId, this.amountCents);
}

class _AllocationFormDialog extends StatefulWidget {
  final Map<String, dynamic> payment;
  final List<Map<String, dynamic>> charges;

  const _AllocationFormDialog({required this.payment, required this.charges});

  @override
  State<_AllocationFormDialog> createState() => _AllocationFormDialogState();
}

class _AllocationFormDialogState extends State<_AllocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String? _chargeId;

  int _availableForPayment() {
    final allocations = _maps(widget.payment['allocations']);
    final allocated = allocations.fold<int>(
      0,
      (total, item) => total + _int(item['amount_cents']),
    );
    return _int(widget.payment['amount_cents']) - allocated;
  }

  int _remaining(Map<String, dynamic> charge) =>
      _int(charge['amount_cents']) - _int(charge['allocated_cents']);

  @override
  void initState() {
    super.initState();
    _chargeId = widget.charges.first['id'] as String;
    final remaining = _remaining(widget.charges.first);
    _amountController = TextEditingController(
      text:
          (_availableForPayment() < remaining
                  ? _availableForPayment()
                  : remaining)
              .toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _chargeId == null) return;
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) return;
    Navigator.pop(context, _AllocationFormResult(_chargeId!, amount));
  }

  @override
  Widget build(BuildContext context) {
    final paymentAvailable = _availableForPayment();
    return AlertDialog(
      title: const Text('Asignar pago a cargo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _chargeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cargo emitido'),
              items: widget.charges.map((charge) {
                final remaining = _remaining(charge);
                return DropdownMenuItem<String>(
                  value: charge['id'] as String,
                  child: Text(
                    '${charge['concept']} · ${_money(remaining, charge['currency'] as String)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _chargeId = value;
                  final charge = _findById(widget.charges, value);
                  final remaining = charge == null ? 0 : _remaining(charge);
                  _amountController.text =
                      (paymentAvailable < remaining
                              ? paymentAvailable
                              : remaining)
                          .toString();
                });
              },
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Importe en centavos',
              ),
              validator: (value) {
                final amount = int.tryParse(value?.trim() ?? '');
                final charge = _findById(widget.charges, _chargeId);
                if (amount == null ||
                    amount < 1 ||
                    amount > paymentAvailable ||
                    charge == null ||
                    amount > _remaining(charge)) {
                  return 'El importe supera el saldo disponible.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(onPressed: _save, child: const Text('Asignar')),
      ],
    );
  }
}

class _BillingMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isError;

  const _BillingMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
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
          if (onPressed != null)
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String title) => Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Text(
    title,
    style: const TextStyle(
      color: AdnColors.white,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    ),
  ),
);

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw MasterApiException('La respuesta del servidor no contiene $field.');
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => _map(item, 'una lista válida')).toList();
}

Map<String, dynamic>? _findById(List<Map<String, dynamic>> values, Object? id) {
  for (final value in values) {
    if (value['id'] == id) return value;
  }
  return null;
}

int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _parseCents(String input) {
  final value = input.trim().replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(value);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  final fraction = int.tryParse((match.group(2) ?? '').padRight(2, '0'));
  if (whole == null || fraction == null) return null;
  final cents = whole * 100 + fraction;
  return cents > 0 && cents <= 1000000000000 ? cents : null;
}

String _money(int cents, String currency) =>
    '$currency ${(cents ~/ 100).toString()}.${(cents % 100).toString().padLeft(2, '0')}';

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
