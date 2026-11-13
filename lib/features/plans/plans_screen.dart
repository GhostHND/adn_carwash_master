import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import '../../core/master_api_client.dart';
import 'master_api_plans_screen.dart';

// ============================================================
// DEFINICIÓN VISUAL DE PLANES
// ============================================================

/// Modelo temporal usado únicamente por la vista previa local.
class PlanPreview {
  final String name;
  final String description;
  final String audience;
  final IconData icon;
  final Color accent;
  final List<String> features;
  final bool isRecommended;

  const PlanPreview({
    required this.name,
    required this.description,
    required this.audience,
    required this.icon,
    required this.accent,
    required this.features,
    this.isRecommended = false,
  });
}

const List<PlanPreview> previewPlans = [
  PlanPreview(
    name: 'Básico',
    description: 'Administración esencial del autolavado.',
    audience: 'Negocios pequeños',
    icon: Icons.local_car_wash_rounded,
    accent: AdnColors.turquoise,
    features: [
      'Dashboard administrativo',
      'Registro de clientes y vehículos',
      'Gestión y asignación de lavados',
      'Fotografías de vehículos',
      'Servicios y precios',
      'Recibos y control de caja',
      'Ingresos y gastos',
      'Sitio web público básico',
      'Reservaciones básicas',
      'Seguimiento público de lavados',
    ],
  ),
  PlanPreview(
    name: 'Intermedio',
    description: 'Mayor control operativo y administrativo.',
    audience: 'Negocios en crecimiento',
    icon: Icons.workspace_premium_rounded,
    accent: AdnColors.turquoiseLight,
    features: [
      'Todas las funciones del plan Básico',
      'Editor web ampliado',
      'Selección de lavador en reservaciones',
      'Pantalla operativa de lavados',
      'Control de inventario',
      'Cuentas por cobrar y pagar',
      'Salarios y comisiones',
      'Reportes avanzados',
      'Administración de sucursales',
      'Mayor capacidad de usuarios',
    ],
    isRecommended: true,
  ),
  PlanPreview(
    name: 'Pro',
    description: 'Acceso integral a la plataforma.',
    audience: 'Administración empresarial completa',
    icon: Icons.diamond_rounded,
    accent: AdnColors.coral,
    features: [
      'Todas las funciones del plan Intermedio',
      'Control avanzado de mora',
      'Reportes financieros completos',
      'Editor web completo',
      'Automatizaciones avanzadas',
      'Promociones y descuentos avanzados',
      'Configuraciones empresariales ampliadas',
      'Herramientas avanzadas de análisis',
      'Mayor capacidad de almacenamiento',
      'Acceso a todas las funciones disponibles',
    ],
  ),
];

// ============================================================
// PANTALLA PRINCIPAL DE PLANES
// ============================================================

class PlansScreen extends StatelessWidget {
  final MasterApiClient? apiClient;

  const PlansScreen({super.key, this.apiClient});

  @override
  Widget build(BuildContext context) {
    if (apiClient != null) {
      return MasterApiPlansScreen(apiClient: apiClient!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 620;
        final double padding = isMobile ? 18 : 29;

        final double availableWidth = constraints.maxWidth - (padding * 2);

        final int columns = availableWidth >= 1050
            ? 3
            : availableWidth >= 650
            ? 2
            : 1;

        final double cardWidth =
            (availableWidth - (16 * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              const Text(
                'Planes de suscripción',
                style: TextStyle(
                  color: AdnColors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Estructura comercial de ADN CarWash.',
                style: TextStyle(color: AdnColors.muted, fontSize: 13),
              ),

              const SizedBox(height: 22),

              // AVISO DE DESARROLLO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdnColors.turquoise.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AdnColors.turquoise.withValues(alpha: 0.22),
                  ),
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
                        'Vista preliminar. Los precios, límites y '
                        'funciones definitivas se configurarán '
                        'desde Master cuando implementemos '
                        'el módulo administrativo y su API.',
                        style: TextStyle(
                          color: AdnColors.white,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // TARJETAS DE PLANES
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: previewPlans.map((plan) {
                  return PlanCard(plan: plan, width: cardWidth);
                }).toList(),
              ),

              const SizedBox(height: 25),

              // CONFIGURACIÓN PENDIENTE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AdnColors.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AdnColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración comercial',
                      style: TextStyle(
                        color: AdnColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Desde este módulo podremos establecer '
                      'precios, períodos de facturación, '
                      'funcionalidades, límites de usuarios, '
                      'sucursales y almacenamiento. '
                      'Los cambios serán administrados '
                      'exclusivamente desde ADN Publicidad Software Master.',
                      style: TextStyle(
                        color: AdnColors.muted,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// TARJETA INDIVIDUAL DE PLAN
// ============================================================

class PlanCard extends StatelessWidget {
  final PlanPreview plan;
  final double width;

  const PlanCard({super.key, required this.plan, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C171B), Color(0xFF070E11)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.isRecommended ? AdnColors.turquoise : AdnColors.border,
          width: plan.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: plan.accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(plan.icon, color: plan.accent, size: 25),
              ),

              const Spacer(),

              if (plan.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AdnColors.turquoise.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    style: TextStyle(
                      color: AdnColors.turquoiseLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            plan.name,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            plan.description,
            style: const TextStyle(
              color: AdnColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 17),

          Text(
            plan.audience.toUpperCase(),
            style: TextStyle(
              color: plan.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdnColors.background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AdnColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRECIO DEL PLAN',
                  style: TextStyle(
                    color: AdnColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Por definir',
                  style: TextStyle(
                    color: AdnColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 23),

          const Text(
            'Funciones propuestas',
            style: TextStyle(
              color: AdnColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          // FUNCIONES
          ...plan.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: plan.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: AdnColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdnColors.border),
            ),
            child: const Text(
              'Pendiente de configuración',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdnColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
