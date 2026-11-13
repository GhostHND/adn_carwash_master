import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';

const masterOnboardingCompletedKey = 'master_first_use_guide_completed_v1';

class MasterOnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final List<String> instructions;
  final String? note;

  const MasterOnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.instructions,
    this.note,
  });
}

const masterOnboardingSteps = [
  MasterOnboardingStep(
    title: 'Conoce tus accesos',
    description: 'Cada subdominio tiene una función. Usa el enlace correcto según lo que necesitas administrar.',
    icon: Icons.language_rounded,
    instructions: [
      'Sitio público: adnpublicidad.site',
      'Aplicación pública: app.adnpublicidad.site',
      'Editor: editor.adnpublicidad.site',
      'Administración central: master.adnpublicidad.site',
      'Programa de fidelidad: fidelidad.adnpublicidad.site',
    ],
    note: 'Master administra el catálogo y las relaciones comerciales; Fidelidad es un producto distinto.',
  ),
  MasterOnboardingStep(
    title: 'Empieza por el catálogo',
    description: 'Define primero qué productos ofrece ADN Publicidad y qué planes comerciales pertenecen a cada producto.',
    icon: Icons.apps_rounded,
    instructions: [
      'Abre «Productos de software» y registra el producto, por ejemplo ADN CarWash o ADN Fidelidad.',
      'Revisa «Planes» y define el nombre, precio, moneda, periodo y funcionalidades que realmente ofrece cada plan.',
      'No publiques precios ni límites que no estén confirmados en el acuerdo comercial.',
    ],
    note: 'Las pantallas de catálogo y planes pueden ser vistas previas; verifica que el guardado esté conectado antes de cargar información real.',
  ),
  MasterOnboardingStep(
    title: 'Registra la empresa cliente',
    description: 'El módulo «Empresas» organiza los datos de las organizaciones que contratan tus productos.',
    icon: Icons.business_rounded,
    instructions: [
      'Abre «Empresas» desde el menú lateral para ver «Empresas y clientes».',
      'Pulsa «Registrar cliente» y completa el nombre legal, nombre comercial y los datos de contacto solicitados.',
      'Revisa los datos antes de validar el formulario.',
      'Comprueba que aparezca en «Directorio de clientes» antes de continuar.',
    ],
    note: 'Los registros de este directorio actualmente viven en memoria y se pierden al cerrar la aplicación. No ingreses datos reales hasta habilitar el guardado en servidor.',
  ),
  MasterOnboardingStep(
    title: 'Crea la instancia contratada',
    description: 'Una instancia representa la instalación de un producto asignada a un cliente.',
    icon: Icons.dns_rounded,
    instructions: [
      'Abre «Instancias» y selecciona el cliente y el producto correctos.',
      'Asigna un plan del mismo producto; no selecciones un plan de otra aplicación.',
      'Registra el dominio y el entorno de la instalación cuando estén confirmados.',
      'Revisa el estado de aprovisionamiento y el estado administrativo por separado.',
    ],
    note: 'Crear una ficha de instancia no configura automáticamente DNS, hosting, bases de datos ni instala el producto.',
  ),
  MasterOnboardingStep(
    title: 'Define la suscripción y los cargos',
    description: 'La suscripción documenta las condiciones vigentes; los cargos representan importes que se deben cobrar.',
    icon: Icons.credit_card_rounded,
    instructions: [
      'Abre «Suscripciones» y vincula el contrato con la instancia correcta.',
      'Define fechas de inicio y vencimiento, moneda, estado y periodo de gracia según el acuerdo firmado.',
      'Revisa los cargos y sus fechas de vencimiento antes de emitirlos.',
      'Actualiza el estado de la suscripción solo cuando corresponda al contrato.',
    ],
    note: 'No se procesan cobros automáticos por registrar una suscripción o un cargo.',
  ),
  MasterOnboardingStep(
    title: 'Registra y aplica los pagos',
    description: 'El registro de pagos ayuda a conciliar lo recibido con los cargos del cliente.',
    icon: Icons.payments_rounded,
    instructions: [
      'Abre «Pagos» e identifica al cliente y el método de pago.',
      'Confirma el pago únicamente después de verificarlo en el canal financiero real.',
      'Distribuye el importe entre los cargos que cubre y revisa que no exceda los saldos.',
      'Conserva la referencia externa para facilitar conciliaciones posteriores.',
    ],
    note: 'Master no se conecta a un banco o pasarela de pago en esta versión.',
  ),
  MasterOnboardingStep(
    title: 'Administra accesos y licencias',
    description: 'Limita el acceso administrativo y revisa el estado de servicio de cada instancia.',
    icon: Icons.admin_panel_settings_rounded,
    instructions: [
      'En «Usuarios Master» y «Administradores», crea cuentas solo para personas autorizadas.',
      'En «Permisos», concede únicamente las acciones necesarias para cada función.',
      'Usa «Estado de empresas» y «Licencias» para revisar decisiones administrativas antes de aplicarlas.',
      'Registra el motivo de cualquier suspensión o cambio relevante.',
    ],
    note: 'Los cambios de acceso y licencias requieren que las pantallas estén conectadas a la API para surtir efecto fuera de esta sesión.',
  ),
  MasterOnboardingStep(
    title: 'Revisa operación y auditoría',
    description: 'Los módulos del sistema ayudan a supervisar servicios, respaldos y actividad administrativa.',
    icon: Icons.monitor_heart_rounded,
    instructions: [
      'Consulta el Dashboard para orientarte y navegar a los módulos principales.',
      'Revisa «Monitoreo» para identificar verificaciones pendientes o incidentes.',
      'Consulta «Respaldos» y confirma la ubicación y la integridad del respaldo en el almacenamiento real.',
      'Usa «Auditoría» para rastrear cambios y «Ajustes generales» para revisar la configuración.',
    ],
    note: 'Una pantalla de respaldo o monitoreo no confirma por sí sola que se haya ejecutado una tarea real.',
  ),
];

class MasterOnboardingDialog extends StatefulWidget {
  final bool firstUse;
  final Future<void> Function() onFinish;

  const MasterOnboardingDialog({
    super.key,
    required this.firstUse,
    required this.onFinish,
  });

  @override
  State<MasterOnboardingDialog> createState() => _MasterOnboardingDialogState();
}

class _MasterOnboardingDialogState extends State<MasterOnboardingDialog> {
  int _currentStep = 0;
  bool _isFinishing = false;

  Future<void> _finish() async {
    if (_isFinishing) {
      return;
    }

    setState(() => _isFinishing = true);
    await widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = masterOnboardingSteps[_currentStep];
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: AdnColors.panel,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.all(screenSize.width < 500 ? 18 : 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AdnColors.turquoiseLight,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      widget.firstUse
                          ? 'Guía de primer uso'
                          : 'Guía de Software Master',
                      style: const TextStyle(
                        color: AdnColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar guía',
                    onPressed: _isFinishing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Paso ${_currentStep + 1} de ${masterOnboardingSteps.length}',
                style: const TextStyle(
                  color: AdnColors.turquoiseLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / masterOnboardingSteps.length,
                  minHeight: 5,
                  backgroundColor: AdnColors.border,
                  color: AdnColors.turquoise,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AdnColors.turquoise.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              step.icon,
                              color: AdnColors.turquoiseLight,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: const TextStyle(
                                    color: AdnColors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.description,
                                  style: const TextStyle(
                                    color: AdnColors.muted,
                                    fontSize: 12,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      ...step.instructions.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 23,
                                height: 23,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AdnColors.turquoise.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${entry.$1 + 1}',
                                  style: const TextStyle(
                                    color: AdnColors.turquoiseLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.$2,
                                  style: const TextStyle(
                                    color: AdnColors.white,
                                    fontSize: 12,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (step.note case final note?) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AdnColors.coral.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AdnColors.coral.withValues(alpha: 0.24),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AdnColors.coral,
                                size: 18,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  note,
                                  style: const TextStyle(
                                    color: AdnColors.white,
                                    fontSize: 11,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 10,
                children: [
                  if (_currentStep == 0)
                    TextButton(
                      onPressed: _isFinishing ? null : _finish,
                      child: const Text('Saltar guía'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _isFinishing
                          ? null
                          : () => setState(() => _currentStep--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Anterior'),
                    ),
                  FilledButton.icon(
                    onPressed: _isFinishing
                        ? null
                        : _currentStep == masterOnboardingSteps.length - 1
                        ? _finish
                        : () => setState(() => _currentStep++),
                    icon: Icon(
                      _currentStep == masterOnboardingSteps.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _currentStep == masterOnboardingSteps.length - 1
                          ? 'Terminar'
                          : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
