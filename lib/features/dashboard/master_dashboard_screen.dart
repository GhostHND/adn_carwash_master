import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../customers/master_customer_registry.dart';
import '../instances/instance_pricing.dart';
import '../instances/master_instance_registry.dart';
import '../payments/billing_preview_registry.dart';
import '../products/software_products_screen.dart';
import '../subscriptions/linked_subscription_registry.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// DASHBOARD ADMINISTRATIVO
// ============================================================

class MasterDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const MasterDashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        MasterCustomerRegistry.customers,
        MasterInstanceRegistry.instances,
        LinkedSubscriptionRegistry.subscriptions,
        BillingPreviewRegistry.charges,
      ]),
      builder: (context, _) {
        final customers = MasterCustomerRegistry.all;
        final instances = MasterInstanceRegistry.all;
        final subscriptions = LinkedSubscriptionRegistry.all;
        final charges = BillingPreviewRegistry.all;

        final projectedMonthly = subscriptions.fold<int>(
          0,
          (sum, item) => sum + item.monthlyChargeCents,
        );

        final projectedAnnual = subscriptions.fold<int>(
          0,
          (sum, item) => sum + item.annualProjectionCents,
        );

        final charged = charges.fold<int>(
          0,
          (sum, item) => sum + item.amountCents,
        );

        final simulatedPaid = charges.fold<int>(
          0,
          (sum, item) => sum + item.simulatedPaidCents,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 620;
            final padding = mobile ? 16.0 : 27.0;
            final available = constraints.maxWidth - padding * 2;

            final columns = available >= 1180
                ? 4
                : available >= 580
                ? 2
                : 1;

            final cardWidth = (available - (columns - 1) * 15) / columns;

            final metrics = <Widget>[
              _MetricCard(
                width: cardWidth,
                title: 'Productos de software',
                value: '${softwareCatalog.length}',
                detail: 'Catálogo de ADN Publicidad',
                icon: Icons.apps_rounded,
                accent: AdnColors.turquoiseLight,
              ),
              _MetricCard(
                width: cardWidth,
                title: 'Clientes registrados',
                value: '${customers.length}',
                detail: 'Registros de esta sesión',
                icon: Icons.business_rounded,
                accent: const Color(0xFF60A5FA),
              ),
              _MetricCard(
                width: cardWidth,
                title: 'Instancias',
                value: '${instances.length}',
                detail: 'Borradores sin activar',
                icon: Icons.dns_rounded,
                accent: const Color(0xFFA78BFA),
              ),
              _MetricCard(
                width: cardWidth,
                title: 'Suscripciones',
                value: '${subscriptions.length}',
                detail: 'Borradores sin facturar',
                icon: Icons.credit_card_rounded,
                accent: const Color(0xFFF5C000),
              ),
            ];

            final financial = _FinancialPanel(
              monthly: projectedMonthly,
              annual: projectedAnnual,
              charged: charged,
              paid: simulatedPaid,
              chargeCount: charges.length,
            );

            final recent = _RecentInstancesPanel(
              instances: instances,
              onOpen: () => onNavigate?.call(2),
            );

            final flow = _CommercialFlowPanel(
              customerCount: customers.length,
              instanceCount: instances.length,
              subscriptionCount: subscriptions.length,
              chargeCount: charges.length,
            );

            final shortcuts = _ShortcutsPanel(onNavigate: onNavigate);

            final mainSections = available >= 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            financial,
                            const SizedBox(height: 17),
                            recent,
                          ],
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            flow,
                            const SizedBox(height: 17),
                            shortcuts,
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      financial,
                      const SizedBox(height: 17),
                      flow,
                      const SizedBox(height: 17),
                      recent,
                      const SizedBox(height: 17),
                      shortcuts,
                    ],
                  );

            return SingleChildScrollView(
              key: const Key('master_dashboard_scroll'),
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel general',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Centro administrativo de '
                        'ADN Publicidad Software Master.',
                        style: TextStyle(color: AdnColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      _WelcomeBanner(onNavigate: onNavigate),

                      const SizedBox(height: 19),

                      Wrap(spacing: 15, runSpacing: 15, children: metrics),

                      const SizedBox(height: 19),
                      mainSections,
                      const SizedBox(height: 19),

                      const _SystemConnectionPanel(),

                      const SizedBox(height: 19),

                      const Text(
                        'Los registros, importes y estadísticas '
                        'mostrados son locales o simulados. '
                        'Los indicadores reales de facturación, '
                        'licencias y disponibilidad aparecerán '
                        'al conectar el servidor.',
                        style: TextStyle(
                          color: AdnColors.muted,
                          fontSize: 11,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// COMPONENTES VISUALES
// ============================================================

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AdnColors.turquoiseLight, size: 22),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdnColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdnColors.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ENCABEZADO PRINCIPAL
// ============================================================

class _WelcomeBanner extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const _WelcomeBanner({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A3940), Color(0xFF092329), Color(0xFF091115)],
          ),
          border: Border.all(
            color: AdnColors.turquoise.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              top: -48,
              child: Icon(
                Icons.hub_rounded,
                size: 225,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AdnColors.turquoise.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'CENTRO DE OPERACIONES · VISTA LOCAL',
                      style: TextStyle(
                        color: AdnColors.turquoiseLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'Todos tus productos.\nUn solo Master.',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 13),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 650),
                    child: Text(
                      'Administra clientes, instancias, '
                      'suscripciones y licencias de '
                      'los productos desarrollados '
                      'por ADN Publicidad.',
                      style: TextStyle(
                        color: Color(0xFFC7D8DD),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 19),
                  OutlinedButton.icon(
                    key: const Key('dashboard_go_products'),
                    onPressed: onNavigate == null ? null : () => onNavigate!(1),
                    icon: const Icon(Icons.apps_rounded, size: 18),
                    label: const Text('Explorar productos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdnColors.white,
                      side: const BorderSide(color: AdnColors.turquoise),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INDICADORES
// ============================================================

class _MetricCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 23),
                ),
                const Spacer(),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: AdnColors.muted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(color: AdnColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FINANZAS SIMULADAS
// ============================================================

class _FinancialPanel extends StatelessWidget {
  final int monthly;
  final int annual;
  final int charged;
  final int paid;
  final int chargeCount;

  const _FinancialPanel({
    required this.monthly,
    required this.annual,
    required this.charged,
    required this.paid,
    required this.chargeCount,
  });

  @override
  Widget build(BuildContext context) {
    final balance = charged - paid;
    final progress = charged == 0 ? 0.0 : (paid / charged).clamp(0.0, 1.0);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Resumen financiero',
            subtitle: 'Proyecciones y movimientos simulados.',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 22),
          const Text(
            'Proyección anual de suscripciones',
            style: TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            InstanceMoney.format(annual),
            key: const Key('dashboard_annual_projection'),
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Proyección mensual recurrente: '
            '${InstanceMoney.format(monthly)}',
            style: const TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 21),
          const Divider(color: AdnColors.border),
          const SizedBox(height: 16),
          _FinancialLine(label: 'Cargos de prueba', amount: charged),
          const SizedBox(height: 13),
          _FinancialLine(label: 'Abonos simulados', amount: paid),
          const SizedBox(height: 13),
          _FinancialLine(
            label: 'Saldo hipotético',
            amount: balance,
            emphasized: true,
          ),
          const SizedBox(height: 19),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: AdnColors.turquoiseLight,
              backgroundColor: AdnColors.border,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$chargeCount cargos de prueba · '
            'Proporción abonada en simulación',
            style: const TextStyle(
              color: AdnColors.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialLine extends StatelessWidget {
  final String label;
  final int amount;
  final bool emphasized;

  const _FinancialLine({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          InstanceMoney.format(amount),
          style: TextStyle(
            color: emphasized ? AdnColors.turquoiseLight : AdnColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ULTIMAS INSTANCIAS
// ============================================================

class _RecentInstancesPanel extends StatelessWidget {
  final List<MasterInstance> instances;
  final VoidCallback onOpen;

  const _RecentInstancesPanel({required this.instances, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final latest = instances.reversed.take(4).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Instancias recientes',
            subtitle: 'Últimos borradores de la sesión.',
            icon: Icons.dns_outlined,
          ),
          const SizedBox(height: 18),
          if (latest.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Todavía no hay instancias registradas.',
                key: Key('dashboard_empty_instances'),
                style: TextStyle(color: AdnColors.muted, fontSize: 12),
              ),
            )
          else
            for (final instance in latest) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdnColors.border)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      color: AdnColors.turquoiseLight,
                      size: 23,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instance.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdnColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            MasterCustomerRegistry.findById(instance.customerId)
                                    ?.displayName ??
                                'Cliente no disponible',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdnColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BORRADOR',
                      style: TextStyle(
                        color: AdnColors.turquoiseLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Ver instancias'),
            style: TextButton.styleFrom(
              foregroundColor: AdnColors.turquoiseLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FLUJO COMERCIAL
// ============================================================

class _CommercialFlowPanel extends StatelessWidget {
  final int customerCount;
  final int instanceCount;
  final int subscriptionCount;
  final int chargeCount;

  const _CommercialFlowPanel({
    required this.customerCount,
    required this.instanceCount,
    required this.subscriptionCount,
    required this.chargeCount,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Flujo comercial',
            subtitle: 'Registros disponibles por etapa.',
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: 18),
          _FlowStep(
            number: '01',
            title: 'Clientes',
            detail: '$customerCount registrados',
          ),
          _FlowStep(
            number: '02',
            title: 'Instancias',
            detail: '$instanceCount borradores',
          ),
          _FlowStep(
            number: '03',
            title: 'Suscripciones',
            detail: '$subscriptionCount borradores',
          ),
          _FlowStep(
            number: '04',
            title: 'Cobros',
            detail: '$chargeCount cargos de prueba',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String number;
  final String title;
  final String detail;
  final bool last;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.detail,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 17),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdnColors.turquoise.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdnColors.border),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AdnColors.turquoiseLight,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AdnColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NAVEGACION RAPIDA
// ============================================================

class _ShortcutsPanel extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const _ShortcutsPanel({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    const shortcuts = <(String, IconData, int)>[
      ('Clientes', Icons.business_outlined, 3),
      ('Instancias', Icons.dns_outlined, 2),
      ('Suscripciones', Icons.credit_card_outlined, 5),
      ('Pagos', Icons.receipt_long_outlined, 6),
      ('Licencias', Icons.vpn_key_outlined, 12),
      ('Respaldos', Icons.backup_outlined, 13),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Accesos rápidos',
            subtitle: 'Abrir módulos del Master.',
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final shortcut in shortcuts)
                OutlinedButton.icon(
                  key: Key('dashboard_go_${shortcut.$3}'),
                  onPressed: onNavigate == null
                      ? null
                      : () => onNavigate!(shortcut.$3),
                  icon: Icon(shortcut.$2, size: 17),
                  label: Text(
                    shortcut.$1,
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdnColors.white,
                    side: const BorderSide(color: AdnColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ESTADO REAL DE CONEXION
// ============================================================

class _SystemConnectionPanel extends StatelessWidget {
  const _SystemConnectionPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Estado de la infraestructura',
            subtitle: 'La telemetría se habilitará con la API.',
            icon: Icons.monitor_heart_outlined,
          ),
          SizedBox(height: 19),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ConnectionStatus(
                name: 'API central',
                status: 'Sin conectar',
                icon: Icons.api_rounded,
              ),
              _ConnectionStatus(
                name: 'Base de datos',
                status: 'Sin verificar',
                icon: Icons.storage_rounded,
              ),
              _ConnectionStatus(
                name: 'Licencias',
                status: 'Sin verificar',
                icon: Icons.vpn_key_outlined,
              ),
              _ConnectionStatus(
                name: 'Respaldos',
                status: 'Sin verificar',
                icon: Icons.backup_outlined,
              ),
              _ConnectionStatus(
                name: 'Auditoría',
                status: 'Sin eventos recibidos',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final String name;
  final String status;
  final IconData icon;

  const _ConnectionStatus({
    required this.name,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdnColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AdnColors.muted, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  style: const TextStyle(color: AdnColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
