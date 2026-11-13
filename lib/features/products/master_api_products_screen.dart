import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'software_products_screen.dart' show SoftwareProductFormDialog;

class MasterApiProductsScreen extends StatefulWidget {
  final MasterApiClient apiClient;

  const MasterApiProductsScreen({super.key, required this.apiClient});

  @override
  State<MasterApiProductsScreen> createState() =>
      _MasterApiProductsScreenState();
}

class _MasterApiProductsScreenState extends State<MasterApiProductsScreen> {
  late Future<List<Map<String, dynamic>>> _products;
  final Set<String> _activating = {};

  @override
  void initState() {
    super.initState();
    _products = widget.apiClient.getCollection('products');
  }

  void _reload() {
    setState(() {
      _products = widget.apiClient.getCollection('products');
    });
  }

  Future<void> _createProduct() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => SoftwareProductFormDialog(apiClient: widget.apiClient),
    );
    if (!mounted || created != true) {
      return;
    }

    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El producto se guardó en Software Master.'),
      ),
    );
  }

  Future<void> _activateProduct(Map<String, dynamic> product) async {
    final id = product['id'];
    if (id is! String || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El producto no tiene un identificador válido.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activar producto'),
        content: Text(
          '¿Activar ${product['name']}? Podrás activar sus planes cuando '
          'tengan precio, moneda, período y funcionalidades configurados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _activating.contains(id)) return;

    setState(() => _activating.add(id));
    try {
      await widget.apiClient.patch('products/$id', body: {'status': 'active'});
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Producto activado.')));
    } on MasterApiException catch (error) {
      if (!mounted) return;
      final details = error.errors.values
          .whereType<List>()
          .expand((messages) => messages.whereType<String>())
          .join(' ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            details.isEmpty ? error.message : '${error.message} $details',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _activating.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _products,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Map<String, dynamic>>[];
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
                        'Productos de software',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Catálogo persistido de ADN Publicidad.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _createProduct,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Nuevo producto'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snapshot.hasError)
                _ApiStateMessage(
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
              else if (products.isEmpty)
                const _ApiStateMessage(
                  message:
                      'El catálogo está vacío. Crea un producto o ejecuta '
                      'master:catalog:seed-products para añadir los productos '
                      'base ADN CarWash y ADN Fidelidad.',
                )
              else
                ...products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductTile(
                      product: product,
                      isActivating: _activating.contains(product['id']),
                      onActivate: () => _activateProduct(product),
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

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isActivating;
  final VoidCallback onActivate;

  const _ProductTile({
    required this.product,
    required this.isActivating,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final code = product['code'] as String? ?? '';
    final category = product['category'] as String? ?? '';
    final description = product['description'] as String? ?? '';
    final status = product['status'] as String? ?? 'draft';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        border: Border.all(color: AdnColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.apps_rounded, color: AdnColors.turquoiseLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String? ?? code,
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    code,
                    category,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: const TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AdnColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Chip(label: Text(_statusLabel(status))),
              if (status == 'draft')
                TextButton(
                  onPressed: isActivating ? null : onActivate,
                  child: Text(isActivating ? 'Activando…' : 'Activar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => 'Activo',
      'retired' => 'Retirado',
      _ => 'Borrador',
    };
  }
}

class _ApiStateMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final bool isError;

  const _ApiStateMessage({
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
        border: Border.all(
          color: isError
              ? AdnColors.coral.withValues(alpha: 0.35)
              : AdnColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 12,
              height: 1.6,
            ),
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
