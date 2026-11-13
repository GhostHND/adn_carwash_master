import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// MODULO DE MONITOREO
// ============================================================

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;
        final padding = mobile ? 18.0 : 29.0;
        final availableWidth = constraints.maxWidth - padding * 2;

        final columns = availableWidth >= 1080
            ? 4
            : availableWidth >= 560
            ? 2
            : 1;

        final cardWidth = (availableWidth - 14 * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeading(),

              const SizedBox(height: 25),

              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MonitoringMetric(
                    width: cardWidth,
                    title: 'API central',
                    icon: Icons.cloud_outlined,
                    accent: AdnColors.turquoise,
                  ),
                  _MonitoringMetric(
                    width: cardWidth,
                    title: 'Base de datos',
                    icon: Icons.storage_rounded,
                    accent: const Color(0xFF22C55E),
                  ),
                  _MonitoringMetric(
                    width: cardWidth,
                    title: 'Empresas conectadas',
                    icon: Icons.business_rounded,
                    accent: const Color(0xFFF5C000),
                  ),
                  _MonitoringMetric(
                    width: cardWidth,
                    title: 'Servicio de correo',
                    icon: Icons.mark_email_unread_outlined,
                    accent: AdnColors.coral,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const _DevelopmentNotice(),

              const SizedBox(height: 24),

              const _ServiceChecks(),

              const SizedBox(height: 24),

              const _IncidentPanel(),

              const SizedBox(height: 24),

              const _MonitoringInformation(),
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
          'Monitoreo',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Supervisi\u00f3n de servicios, '
          'conexiones e incidencias.',
          style: TextStyle(color: AdnColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

// ============================================================
// INDICADORES
// ============================================================

class _MonitoringMetric extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Color accent;

  const _MonitoringMetric({
    required this.width,
    required this.title,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdnColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdnColors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sin verificar',
                  style: TextStyle(color: AdnColors.muted, fontSize: 11),
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
              'El monitoreo autom\u00e1tico '
              'todav\u00eda no est\u00e1 conectado. '
              'Los estados mostrados no representan '
              'resultados de verificaciones reales. '
              'Las comprobaciones se habilitar\u00e1n '
              'cuando implementemos el servidor.',
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
// COMPROBACIONES DE SERVICIOS
// ============================================================

class _ServiceChecks extends StatelessWidget {
  const _ServiceChecks();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de los servicios',
                  style: TextStyle(
                    color: AdnColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Comprobaciones previstas '
                  'para la infraestructura central.',
                  style: TextStyle(color: AdnColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AdnColors.border),

          const _ServiceRow(
            icon: Icons.cloud_outlined,
            title: 'API central',
            description:
                'Disponibilidad del servidor '
                'y respuesta de sus servicios.',
          ),

          const _ServiceRow(
            icon: Icons.storage_rounded,
            title: 'Base de datos central',
            description:
                'Disponibilidad de la conexi\u00f3n '
                'utilizada por Software Master.',
          ),

          const _ServiceRow(
            icon: Icons.business_outlined,
            title: 'Conexiones de instancias',
            description:
                'Estado de comunicaci\u00f3n '
                'con las instancias contratadas.',
          ),

          const _ServiceRow(
            icon: Icons.alternate_email_rounded,
            title: 'Correo transaccional',
            description:
                'Verificaci\u00f3n del servicio '
                'utilizado para notificaciones '
                'y recuperaci\u00f3n de acceso.',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILA DE SERVICIO
// ============================================================

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AdnColors.border, width: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 21, color: AdnColors.turquoiseLight),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AdnColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          const status = _PendingBadge();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [information, const SizedBox(height: 12), status],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 16),
              status,
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// ESTADO NO VERIFICADO
// ============================================================

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdnColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 16, color: AdnColors.muted),
          SizedBox(width: 8),
          Text(
            'Sin verificar',
            style: TextStyle(
              color: AdnColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REGISTRO DE INCIDENCIAS
// ============================================================

class _IncidentPanel extends StatelessWidget {
  const _IncidentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('monitoring_incidents'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdnColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(21),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Registro de incidencias',
                    style: TextStyle(
                      color: AdnColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.report_problem_outlined,
                  color: AdnColors.muted,
                  size: 22,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AdnColors.border),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 47),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AdnColors.turquoise.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: AdnColors.turquoise,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sin verificaciones registradas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AdnColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: const Text(
                    'Todav\u00eda no podemos determinar '
                    'si existen incidencias. '
                    'Cuando el monitoreo est\u00e9 '
                    'conectado, aqu\u00ed aparecer\u00e1n '
                    'los eventos detectados.',
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
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFORMACION DE ULTIMA COMPROBACION
// ============================================================

class _MonitoringInformation extends StatelessWidget {
  const _MonitoringInformation();

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
            'Informaci\u00f3n del monitoreo',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),

          _InformationRow(
            title: '\u00daltima verificaci\u00f3n',
            value: 'No disponible',
          ),

          SizedBox(height: 14),

          _InformationRow(
            title: 'Frecuencia de comprobaci\u00f3n',
            value: 'Pendiente de configurar',
          ),

          SizedBox(height: 14),

          _InformationRow(
            title: 'Historial de disponibilidad',
            value: 'Sin datos',
          ),

          SizedBox(height: 20),

          Text(
            'Los resultados deber\u00e1n proceder '
            'del servidor. La aplicaci\u00f3n '
            'no considerar\u00e1 un servicio '
            'operativo solamente porque '
            'la pantalla pueda abrirse.',
            style: TextStyle(color: AdnColors.muted, fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILA INFORMATIVA
// ============================================================

class _InformationRow extends StatelessWidget {
  final String title;
  final String value;

  const _InformationRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
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
    );
  }
}
