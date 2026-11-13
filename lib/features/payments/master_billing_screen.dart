import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import '../console/master_commercial_console.dart';
import '../instances/instance_pricing.dart';
import '../instances/master_instance_registry.dart';
import '../subscriptions/linked_subscription_registry.dart';
import 'billing_preview_registry.dart';
import 'master_api_billing_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// PAGOS: PREPARACION COMERCIAL
// ============================================================

class MasterBillingScreen extends StatefulWidget {
  final MasterApiClient? apiClient;

  const MasterBillingScreen({super.key, this.apiClient});

  @override
  State<MasterBillingScreen> createState() => _MasterBillingScreenState();
}

class _MasterBillingScreenState extends State<MasterBillingScreen> {
  String? _selectedSubscriptionId;
  BillingConcept _concept = BillingConcept.monthly;

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _createCharge() {
    final subscriptionId = _selectedSubscriptionId;

    if (subscriptionId == null) {
      _message('Selecciona una suscripción.');
      return;
    }

    final result = BillingPreviewRegistry.create(
      subscriptionId: subscriptionId,
      concept: _concept,
    );

    if (result.success) {
      _message(
        'Cargo de prueba preparado. '
        'No se emitió una factura.',
      );
    } else {
      _message(result.error ?? 'No se pudo preparar el cargo.');
    }
  }

  Widget _newChargeForm(List<LinkedSubscriptionDraft> subscriptions) {
    return MasterConsoleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preparar cargo preliminar',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Cada concepto corresponde a la primera '
            'fecha definida en el borrador de suscripción. '
            'Todavía no se generan cargos periódicos.',
            style: TextStyle(color: AdnColors.muted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 19),
          DropdownButtonFormField<String>(
            key: const Key('billing_subscription'),
            initialValue: _selectedSubscriptionId,
            isExpanded: true,
            dropdownColor: AdnColors.panel,
            decoration: const InputDecoration(
              labelText: 'Suscripción vinculada',
              border: OutlineInputBorder(),
            ),
            items: subscriptions.map((subscription) {
              final instance = MasterInstanceRegistry.findById(
                subscription.instanceId,
              );

              return DropdownMenuItem<String>(
                value: subscription.id,
                child: Text(
                  '${subscription.id} · '
                  '${instance?.name ?? subscription.instanceId}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: subscriptions.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedSubscriptionId = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BillingConcept>(
            key: const Key('billing_concept'),
            initialValue: _concept,
            isExpanded: true,
            dropdownColor: AdnColors.panel,
            decoration: const InputDecoration(
              labelText: 'Concepto del cargo',
              border: OutlineInputBorder(),
            ),
            items: BillingConcept.values.map((concept) {
              return DropdownMenuItem<BillingConcept>(
                value: concept,
                child: Text(concept.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _concept = value);
              }
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('billing_create_charge'),
            onPressed: subscriptions.isEmpty ? null : _createCharge,
            icon: const Icon(Icons.add_card_rounded, size: 19),
            label: const Text('Preparar cargo de prueba'),
            style: FilledButton.styleFrom(
              backgroundColor: AdnColors.turquoise,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = widget.apiClient;
    if (apiClient != null) {
      return MasterApiBillingScreen(apiClient: apiClient);
    }

    final compact = MediaQuery.sizeOf(context).width < 720;

    return ValueListenableBuilder<List<LinkedSubscriptionDraft>>(
      valueListenable: LinkedSubscriptionRegistry.subscriptions,
      builder: (context, subscriptions, _) {
        return ValueListenableBuilder<List<BillingPreviewCharge>>(
          valueListenable: BillingPreviewRegistry.charges,
          builder: (context, charges, _) {
            final simulatedTotal = charges.fold<int>(
              0,
              (sum, charge) => sum + charge.amountCents,
            );

            final simulatedPaid = charges.fold<int>(
              0,
              (sum, charge) => sum + charge.simulatedPaidCents,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 18 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pagos y cobros',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cargos, abonos y saldos por suscripción.',
                    style: TextStyle(color: AdnColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 23),
                  MasterConsoleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cargos de prueba: ${charges.length}',
                          key: const Key('billing_charge_count'),
                          style: const TextStyle(
                            color: AdnColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          'Importe simulado: '
                          '${InstanceMoney.format(simulatedTotal)}',
                          style: const TextStyle(
                            color: AdnColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saldo hipotético: '
                          '${InstanceMoney.format(simulatedTotal - simulatedPaid)}',
                          style: const TextStyle(
                            color: AdnColors.turquoiseLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  const MasterConsoleNotice(
                    message:
                        'Los cargos y abonos de esta pantalla '
                        'son simulaciones locales. No representan '
                        'cuentas por cobrar, pagos recibidos ni '
                        'obligaciones del cliente. Tampoco afectan '
                        'la suspensión o activación de licencias.',
                  ),
                  const SizedBox(height: 23),
                  _newChargeForm(subscriptions),
                  const SizedBox(height: 23),
                  MasterConsoleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle de cargos preliminares',
                          style: TextStyle(
                            color: AdnColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AdnColors.border),
                        if (charges.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 35),
                            child: Center(
                              child: Text(
                                'Sin cargos de prueba',
                                style: TextStyle(color: AdnColors.muted),
                              ),
                            ),
                          )
                        else
                          for (final charge in charges) ...[
                            _ChargeCard(
                              key: ValueKey(charge.id),
                              charge: charge,
                              formattedDate: _date(charge.dueDate),
                            ),
                            const SizedBox(height: 13),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// CARGO Y ABONO SIMULADO
// ============================================================

class _ChargeCard extends StatefulWidget {
  final BillingPreviewCharge charge;
  final String formattedDate;

  const _ChargeCard({
    super.key,
    required this.charge,
    required this.formattedDate,
  });

  @override
  State<_ChargeCard> createState() => _ChargeCardState();
}

class _ChargeCardState extends State<_ChargeCard> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _simulate() {
    final cents = InstanceMoney.parse(_amountController.text);

    if (cents == null) {
      _message('Ingresa un importe válido.');
      return;
    }

    final error = BillingPreviewRegistry.simulateAbono(
      chargeId: widget.charge.id,
      amountCents: cents,
    );

    if (error != null) {
      _message(error);
      return;
    }

    _amountController.clear();

    _message(
      'Abono simulado registrado. '
      'No se recibió dinero real.',
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final charge = widget.charge;

    return Container(
      key: Key('billing_charge_${charge.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${charge.id} · ${charge.concept.label}',
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suscripción: ${charge.subscriptionId}'
            ' · Fecha prevista: ${widget.formattedDate}',
            style: const TextStyle(color: AdnColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 13),
          Text(
            'Cargo: ${InstanceMoney.format(charge.amountCents)}',
            style: const TextStyle(color: AdnColors.white, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Abonos simulados: '
            '${InstanceMoney.format(charge.simulatedPaidCents)}',
            style: const TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo hipotético: '
            '${InstanceMoney.format(charge.simulatedBalanceCents)}',
            style: const TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            charge.status,
            style: const TextStyle(color: AdnColors.muted, fontSize: 11),
          ),
          if (charge.simulatedBalanceCents > 0) ...[
            const SizedBox(height: 17),
            TextField(
              key: Key('billing_payment_${charge.id}'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Importe de abono simulado (L)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: Key('billing_apply_${charge.id}'),
              onPressed: _simulate,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Simular abono'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdnColors.turquoiseLight,
                side: const BorderSide(color: AdnColors.turquoise),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
