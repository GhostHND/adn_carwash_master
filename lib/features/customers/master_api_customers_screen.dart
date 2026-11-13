import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'companies_customer_hub.dart' show MasterCustomerFormDialog;
import 'master_customer_registry.dart';

class MasterApiCustomersScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiCustomersScreen({super.key, required this.apiClient});

  @override
  State<MasterApiCustomersScreen> createState() =>
      _MasterApiCustomersScreenState();
}

class _MasterApiCustomersScreenState extends State<MasterApiCustomersScreen> {
  late Future<List<Map<String, dynamic>>> _customers;

  @override
  void initState() {
    super.initState();
    _customers = widget.apiClient.getCollection('customers');
  }

  void _reload() {
    setState(() {
      _customers = widget.apiClient.getCollection('customers');
    });
  }

  Future<void> _createCustomer() async {
    final customer = await showDialog<MasterCustomer>(
      context: context,
      builder: (_) => MasterCustomerFormDialog(apiClient: widget.apiClient),
    );
    if (!mounted || customer == null) {
      return;
    }

    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customer.displayName} se guardó en la base de datos.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _customers,
      builder: (context, snapshot) {
        final customers = snapshot.data ?? const <Map<String, dynamic>>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 18 : 28),
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
                        'Empresas y clientes',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Directorio comercial persistido en Software Master.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    key: const Key('unified_customer_add'),
                    onPressed: _createCustomer,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Registrar cliente'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (snapshot.hasError)
                _CustomersMessage(
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
              else ...[
                _CustomersMessage(
                  message:
                      'Clientes registrados en base de datos: ${customers.length}',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AdnColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdnColors.border),
                  ),
                  child: customers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(35),
                          child: Center(
                            child: Text(
                              'Sin clientes registrados.',
                              style: TextStyle(color: AdnColors.muted),
                            ),
                          ),
                        )
                      : Column(
                          children: customers.map((customer) {
                            final name = customer['trade_name'] as String?;
                            final legalName =
                                customer['legal_name'] as String? ?? '';
                            return ListTile(
                              leading: const Icon(
                                Icons.business_outlined,
                                color: AdnColors.turquoiseLight,
                              ),
                              title: Text(
                                name?.isNotEmpty == true ? name! : legalName,
                                style: const TextStyle(color: AdnColors.white),
                              ),
                              subtitle: Text(
                                [
                                      legalName,
                                      customer['email'] as String? ?? '',
                                      customer['phone'] as String? ?? '',
                                    ]
                                    .where((value) => value.isNotEmpty)
                                    .join(' · '),
                                style: const TextStyle(
                                  color: AdnColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Text(
                                customer['status'] as String? ?? '',
                                style: const TextStyle(
                                  color: AdnColors.turquoiseLight,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CustomersMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isError;

  const _CustomersMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isError
              ? AdnColors.coral.withValues(alpha: 0.35)
              : AdnColors.border,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
