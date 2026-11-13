import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_identity.dart';
import '../../core/master_api_client.dart';
import 'master_api_products_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// CATALOGO CENTRAL DE PRODUCTOS
// ============================================================

class SoftwareProduct {
  final String code;
  final String name;
  final String category;
  final String description;
  final String status;

  const SoftwareProduct({
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
  });
}

const softwareCatalog = <SoftwareProduct>[
  SoftwareProduct(
    code: 'adn-carwash',
    name: MasterIdentity.firstProduct,
    category: 'Gestión de autolavados',
    description:
        'Sistema de administración para negocios '
        'dedicados al lavado y cuidado de vehículos.',
    status: 'En desarrollo',
  ),
];

// ============================================================
// PANTALLA PRINCIPAL
// ============================================================

class SoftwareProductsScreen extends StatelessWidget {
  final MasterApiClient? apiClient;

  const SoftwareProductsScreen({super.key, this.apiClient});

  Future<void> _openForm(BuildContext context) async {
    final validated = await showDialog<bool>(
      context: context,
      builder: (_) => SoftwareProductFormDialog(apiClient: apiClient),
    );

    if (!context.mounted || validated != true) {
      return;
    }

    if (apiClient != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El producto se guardó en Software Master.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Datos del producto validados. '
          'No se ha registrado otro software: '
          'el catálogo todavía no está conectado '
          'a la base de datos central.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = apiClient;
    if (client != null) {
      return MasterApiProductsScreen(apiClient: client);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;
        final padding = mobile ? 18.0 : 29.0;
        final width = constraints.maxWidth - padding * 2;

        final columns = width >= 960
            ? 3
            : width >= 560
            ? 2
            : 1;

        final cardWidth = (width - 14 * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PageHeading(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: _NewProductButton(
                        onPressed: () => _openForm(context),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Expanded(child: _PageHeading()),
                    const SizedBox(width: 16),
                    _NewProductButton(onPressed: () => _openForm(context)),
                  ],
                ),

              const SizedBox(height: 25),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.apps_rounded,
                    title: 'Productos definidos',
                    value: '${softwareCatalog.length}',
                    accent: AdnColors.turquoise,
                  ),
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.code_rounded,
                    title: 'En desarrollo',
                    value:
                        '${softwareCatalog.where((product) => product.status == 'En desarrollo').length}',
                    accent: const Color(0xFFF5C000),
                  ),
                  _MetricCard(
                    width: cardWidth,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Instancias contratadas',
                    value: 'Sin conectar',
                    accent: const Color(0xFF22C55E),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const _DevelopmentNotice(),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdnColors.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AdnColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'Catálogo de productos',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AdnColors.border),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          for (final product in softwareCatalog)
                            _ProductCard(product: product),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const _CatalogInformation(),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ENCABEZADO
// ============================================================

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos de software',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Sistemas desarrollados y administrados '
          'por ADN Publicidad.',
          style: TextStyle(color: AdnColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

// ============================================================
// BOTON NUEVO PRODUCTO
// ============================================================

class _NewProductButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewProductButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_box_outlined, size: 19),
      label: const Text('Nuevo producto'),
      style: FilledButton.styleFrom(
        backgroundColor: AdnColors.turquoise,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ============================================================
// INDICADORES
// ============================================================

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
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
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 23),
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
                Text(
                  value,
                  style: const TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AVISO DE DESARROLLO
// ============================================================

class _DevelopmentNotice extends StatelessWidget {
  const _DevelopmentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdnColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.2)),
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
              'ADN CarWash es el primer producto '
              'de la plataforma. '
              'Los nuevos sistemas se incorporarán '
              'a este catálogo sin crear otro Master. '
              'El registro y la administración real '
              'de productos se habilitarán '
              'cuando conectemos el servidor.',
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

// ============================================================
// TARJETA DE PRODUCTO
// ============================================================

class _ProductCard extends StatelessWidget {
  final SoftwareProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('software_product_${product.code}'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AdnColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 540;

          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdnColors.turquoise.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_car_wash_rounded,
                  color: AdnColors.turquoiseLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: AdnColors.turquoiseLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AdnColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Identificador: ${product.code}',
                      style: const TextStyle(
                        color: AdnColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final status = Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5C000).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF5C000).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              product.status,
              style: const TextStyle(
                color: Color(0xFFF5C000),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 17), status],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: information),
              const SizedBox(width: 20),
              status,
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// INFORMACION DE LA ARQUITECTURA
// ============================================================

class _CatalogInformation extends StatelessWidget {
  const _CatalogInformation();

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
            'Organización de la plataforma',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Cada producto tendrá sus propios planes '
            'y podrá contratarse por distintos clientes. '
            'Las instalaciones o instancias contratadas '
            'se administrarán de forma independiente, '
            'con sus propias suscripciones y datos.',
            style: TextStyle(color: AdnColors.muted, fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORMULARIO PRELIMINAR DE NUEVO PRODUCTO
// ============================================================

class SoftwareProductFormDialog extends StatefulWidget {
  final MasterApiClient? apiClient;

  const SoftwareProductFormDialog({super.key, this.apiClient});

  @override
  State<SoftwareProductFormDialog> createState() =>
      _SoftwareProductFormDialogState();
}

class _SoftwareProductFormDialogState extends State<SoftwareProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _code = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  String? _saveError;
  bool _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
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
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 12),
      filled: true,
      fillColor: AdnColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
    );
  }

  Widget _field({
    required Key key,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    int maxLines = 1,
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
          maxLines: maxLines,
          style: const TextStyle(color: AdnColors.white, fontSize: 13),
          decoration: _decoration(hint, icon),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Ingresa un identificador interno.';
    }

    if (!RegExp(r'^[a-z][a-z0-9-]{2,40}$').hasMatch(code)) {
      return 'Usa letras minúsculas, números '
          'y guiones. Inicia con una letra.';
    }

    if (widget.apiClient == null &&
        softwareCatalog.any((product) => product.code == code)) {
      return 'Este identificador ya está definido.';
    }

    return null;
  }

  Future<void> _validate() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final apiClient = widget.apiClient;
    if (apiClient == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await apiClient.post(
        'products',
        body: {
          'name': _name.text.trim(),
          'code': _code.text.trim(),
          'category': _category.text.trim().isEmpty
              ? null
              : _category.text.trim(),
          'description': _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          'status': 'draft',
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on MasterApiException catch (error) {
      if (mounted) {
        setState(() => _saveError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 620;

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
      child: SizedBox(
        width: 620,
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
                      Icons.add_box_outlined,
                      size: 29,
                      color: AdnColors.turquoiseLight,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Nuevo producto de software',
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
                const Divider(color: AdnColors.border),
                const SizedBox(height: 18),

                _field(
                  key: const Key('product_name'),
                  label: 'Nombre del software *',
                  controller: _name,
                  icon: Icons.apps_outlined,
                  hint: 'Nombre comercial',
                  validator: _required,
                ),
                const SizedBox(height: 18),

                _field(
                  key: const Key('product_code'),
                  label: 'Identificador interno *',
                  controller: _code,
                  icon: Icons.code_rounded,
                  hint: 'ejemplo-software',
                  validator: _validateCode,
                ),
                const SizedBox(height: 18),

                _field(
                  key: const Key('product_category'),
                  label: 'Sector o categoría *',
                  controller: _category,
                  icon: Icons.category_outlined,
                  hint: 'Sector del negocio',
                  validator: _required,
                ),
                const SizedBox(height: 18),

                _field(
                  key: const Key('product_description'),
                  label: 'Descripción',
                  controller: _description,
                  icon: Icons.description_outlined,
                  hint: 'Descripción general del sistema',
                  validator: (_) => null,
                  maxLines: 2,
                ),
                const SizedBox(height: 21),

                if (_saveError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdnColors.coral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AdnColors.coral.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _saveError!,
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdnColors.turquoise.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AdnColors.turquoise.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    widget.apiClient == null
                        ? 'Este formulario únicamente valida '
                              'la información. Todavía no agrega '
                              'productos al catálogo ni crea '
                              'bases de datos o instancias.'
                        : 'El producto se guardará en el catálogo central '
                              'con estado Borrador. No se crean planes, '
                              'instancias ni bases de datos automáticamente.',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 19),

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
                        key: const Key('product_validate'),
                        onPressed: _isSaving ? null : _validate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AdnColors.turquoise,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isSaving
                              ? 'Guardando…'
                              : widget.apiClient == null
                              ? 'Validar datos'
                              : 'Guardar producto',
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
