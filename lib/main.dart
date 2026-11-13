import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/adn_colors.dart';
import 'core/master_identity.dart';
import 'core/master_api_client.dart';
import 'features/dashboard/master_dashboard_screen.dart';
import 'features/system/master_system_screens.dart';
import 'features/payments/master_billing_screen.dart';
import 'features/console/master_commercial_console.dart';
import 'features/administrators/administrators_screen.dart';
import 'features/auth/master_access_app.dart';
import 'features/company_status/company_status_screen.dart';
import 'features/instances/instances_screen.dart';
import 'features/licensing/license_control_screen.dart';
import 'features/master_users/master_users_screen.dart';
import 'features/monitoring/monitoring_screen.dart';
import 'features/onboarding/master_onboarding.dart';
import 'features/permissions/permissions_screen.dart';
import 'features/plans/plans_screen.dart';
import 'features/products/software_products_screen.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// ============================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MasterAccessApp(
      previewApp: AdnCarWashMaster(showFirstUseGuide: true),
      authenticatedAppBuilder: (apiClient, user, onLogout) => AdnCarWashMaster(
        showFirstUseGuide: true,
        apiClient: apiClient,
        currentUser: user,
        onLogout: onLogout,
      ),
    ),
  );
}

// Nombre interno conservado por compatibilidad con
// main_dev.dart y las pruebas existentes.
class AdnCarWashMaster extends StatelessWidget {
  final bool showFirstUseGuide;
  final MasterApiClient? apiClient;
  final MasterUser? currentUser;
  final Future<void> Function()? onLogout;

  const AdnCarWashMaster({
    super.key,
    this.showFirstUseGuide = false,
    this.apiClient,
    this.currentUser,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MasterIdentity.fullName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AdnColors.background,
        dividerColor: AdnColors.border,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdnColors.turquoise,
          brightness: Brightness.dark,
          surface: AdnColors.background,
        ),
        inputDecorationTheme: const InputDecorationThemeData(errorMaxLines: 3),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AdnColors.panel,
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(
            color: AdnColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: AdnColors.turquoise),
          ),
        ),
      ),
      home: MasterScreen(
        showFirstUseGuide: showFirstUseGuide,
        apiClient: apiClient,
        currentUser: currentUser,
        onLogout: onLogout,
      ),
    );
  }
}

// ============================================================
// MENU
// ============================================================

class MasterMenuItem {
  final String title;
  final String group;
  final IconData icon;

  const MasterMenuItem({
    required this.title,
    required this.group,
    required this.icon,
  });
}

const List<MasterMenuItem> masterMenu = [
  MasterMenuItem(
    title: 'Dashboard',
    group: 'GENERAL',
    icon: Icons.dashboard_rounded,
  ),
  MasterMenuItem(
    title: 'Productos de software',
    group: 'CATÁLOGO',
    icon: Icons.apps_rounded,
  ),
  MasterMenuItem(
    title: 'Instancias',
    group: 'CATÁLOGO',
    icon: Icons.dns_rounded,
  ),
  MasterMenuItem(
    title: 'Empresas',
    group: 'GESTIÓN EMPRESARIAL',
    icon: Icons.business_rounded,
  ),
  MasterMenuItem(
    title: 'Planes',
    group: 'GESTIÓN EMPRESARIAL',
    icon: Icons.workspace_premium_rounded,
  ),
  MasterMenuItem(
    title: 'Suscripciones',
    group: 'GESTIÓN EMPRESARIAL',
    icon: Icons.credit_card_rounded,
  ),
  MasterMenuItem(
    title: 'Pagos',
    group: 'GESTIÓN EMPRESARIAL',
    icon: Icons.receipt_long_rounded,
  ),
  MasterMenuItem(
    title: 'Usuarios Master',
    group: 'ADMINISTRACIÓN',
    icon: Icons.supervisor_account_rounded,
  ),
  MasterMenuItem(
    title: 'Administradores',
    group: 'ADMINISTRACIÓN',
    icon: Icons.manage_accounts_rounded,
  ),
  MasterMenuItem(
    title: 'Permisos',
    group: 'ADMINISTRACIÓN',
    icon: Icons.admin_panel_settings_rounded,
  ),
  MasterMenuItem(
    title: 'Estado de empresas',
    group: 'SISTEMA',
    icon: Icons.monitor_heart_rounded,
  ),
  MasterMenuItem(
    title: 'Monitoreo',
    group: 'SISTEMA',
    icon: Icons.analytics_rounded,
  ),
  MasterMenuItem(
    title: 'Licencias',
    group: 'SISTEMA',
    icon: Icons.vpn_key_rounded,
  ),
  MasterMenuItem(
    title: 'Respaldos',
    group: 'SISTEMA',
    icon: Icons.backup_rounded,
  ),
  MasterMenuItem(
    title: 'Auditoría',
    group: 'SISTEMA',
    icon: Icons.fact_check_rounded,
  ),
  MasterMenuItem(
    title: 'Ajustes generales',
    group: 'CONFIGURACIÓN',
    icon: Icons.settings_rounded,
  ),
];

// ============================================================
// PANTALLA PRINCIPAL
// ============================================================

class MasterScreen extends StatefulWidget {
  final bool showFirstUseGuide;
  final MasterApiClient? apiClient;
  final MasterUser? currentUser;
  final Future<void> Function()? onLogout;

  const MasterScreen({
    super.key,
    this.showFirstUseGuide = false,
    this.apiClient,
    this.currentUser,
    this.onLogout,
  });

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.showFirstUseGuide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGuideOnFirstUse();
      });
    }
  }

  Future<void> _showGuideOnFirstUse() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted || preferences.getBool(masterOnboardingCompletedKey) == true) {
      return;
    }

    await _showGuide(firstUse: true, preferences: preferences);
  }

  Future<void> _openGuide() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    await _showGuide(firstUse: false, preferences: preferences);
  }

  Future<void> _showGuide({
    required bool firstUse,
    required SharedPreferences preferences,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !firstUse,
      builder: (dialogContext) => MasterOnboardingDialog(
        firstUse: firstUse,
        onFinish: () async {
          final saved = await preferences.setBool(
            masterOnboardingCompletedKey,
            true,
          );
          if (!dialogContext.mounted) {
            return;
          }
          if (!saved) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo guardar que completaste la guía. '
                  'Podría volver a aparecer al iniciar la aplicación.',
                ),
              ),
            );
          }
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget buildSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return MasterDashboard(onNavigate: selectPage);

      case 1:
        return SoftwareProductsScreen(apiClient: widget.apiClient);

      case 2:
        return InstancesScreen(apiClient: widget.apiClient);

      case 3:
        return MasterCustomersScreen(apiClient: widget.apiClient);

      case 4:
        return PlansScreen(apiClient: widget.apiClient);

      case 5:
        return widget.apiClient == null
            ? const MasterSubscriptionsScreen()
            : MasterBillingScreen(apiClient: widget.apiClient);

      case 6:
        return MasterBillingScreen(apiClient: widget.apiClient);

      case 7:
        return MasterUsersScreen(apiClient: widget.apiClient);

      case 8:
        return const AdministratorsScreen();

      case 9:
        return PermissionsScreen(apiClient: widget.apiClient);

      case 10:
        return const CompanyStatusScreen();

      case 11:
        return const MonitoringScreen();

      case 12:
        return const LicenseControlScreen();

      case 13:
        return const MasterBackupsScreen();

      case 14:
        return MasterAuditScreen(apiClient: widget.apiClient);

      case 15:
        return const MasterSettingsScreen();

      default:
        return MasterModulePlaceholder(
          title: masterMenu[selectedIndex].title,
          icon: masterMenu[selectedIndex].icon,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final mobile = width < 620;
        final tablet = width >= 620 && width < 850;
        final desktop = width >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AdnColors.background,
          drawer: mobile
              ? Drawer(
                  width: 285,
                  backgroundColor: AdnColors.sidebar,
                  child: MasterSidebar(
                    selectedIndex: selectedIndex,
                    onSelected: (index) {
                      selectPage(index);
                      Navigator.of(context).pop();
                    },
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 260,
                    child: MasterSidebar(
                      selectedIndex: selectedIndex,
                      onSelected: selectPage,
                    ),
                  ),
                if (tablet)
                  MasterNavigationRail(
                    selectedIndex: selectedIndex,
                    onSelected: selectPage,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      MasterTopBar(
                        isMobile: mobile,
                        onOpenMenu: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        onOpenGuide: _openGuide,
                        currentUser: widget.currentUser,
                        onLogout: widget.onLogout,
                      ),
                      Expanded(child: buildSelectedPage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// IDENTIDAD VISUAL
// ============================================================

class AdnBrand extends StatelessWidget {
  const AdnBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 76,
          height: 51,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AdnColors.turquoise.withValues(alpha: 0.30),
            ),
          ),
          child: SvgPicture.asset(
            'assets/branding/logo_adn.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MasterIdentity.owner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AdnColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 5),
              Text(
                MasterIdentity.sidebarSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AdnColors.turquoiseLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
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
// BARRA LATERAL
// ============================================================

class MasterSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MasterSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdnColors.sidebar,
        border: Border(right: BorderSide(color: AdnColors.border)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(17, 20, 13, 20),
            child: AdnBrand(),
          ),
          const Divider(height: 1, color: AdnColors.border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 15, 12, 15),
              itemCount: masterMenu.length,
              itemBuilder: (context, index) {
                final item = masterMenu[index];
                final selected = selectedIndex == index;

                final newGroup =
                    index == 0 || masterMenu[index - 1].group != item.group;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (newGroup)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 20, 8, 11),
                        child: Text(
                          item.group,
                          style: const TextStyle(
                            color: AdnColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Material(
                        color: selected
                            ? AdnColors.turquoise
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: selected
                                      ? Colors.white
                                      : AdnColors.muted,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AdnColors.muted,
                                      fontSize: 12.5,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AdnColors.border),
          const Padding(
            padding: EdgeInsets.all(17),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: AdnColors.turquoise),
                SizedBox(width: 9),
                Text(
                  'ENTORNO DE DESARROLLO',
                  style: TextStyle(
                    color: AdnColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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
// NAVEGACION DE TABLETAS
// ============================================================

class MasterNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MasterNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AdnColors.border)),
      ),
      child: NavigationRail(
        backgroundColor: AdnColors.sidebar,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        extended: false,
        minWidth: 75,
        scrollable: true,
        labelType: NavigationRailLabelType.none,
        indicatorColor: AdnColors.turquoise,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: AdnColors.muted),
        destinations: masterMenu.map((item) {
          return NavigationRailDestination(
            icon: Tooltip(message: item.title, child: Icon(item.icon)),
            label: Text(item.title),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// BARRA SUPERIOR
// ============================================================

class MasterTopBar extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenGuide;
  final MasterUser? currentUser;
  final Future<void> Function()? onLogout;

  const MasterTopBar({
    super.key,
    required this.isMobile,
    required this.onOpenMenu,
    required this.onOpenGuide,
    this.currentUser,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 25),
      decoration: const BoxDecoration(
        color: AdnColors.background,
        border: Border(bottom: BorderSide(color: AdnColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: onOpenMenu,
              tooltip: 'Abrir menú',
              icon: const Icon(Icons.menu_rounded, color: AdnColors.white),
            ),
            const SizedBox(width: 5),
          ],
          const Expanded(
            child: Text(
              MasterIdentity.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AdnColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isMobile) ...[
            const Icon(Icons.circle, size: 8, color: AdnColors.muted),
            const SizedBox(width: 9),
            Text(
              currentUser == null ? 'VISTA LOCAL' : 'SESIÓN API',
              style: const TextStyle(
                color: AdnColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
          if (currentUser != null) ...[
            const SizedBox(width: 8),
            if (!isMobile)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  currentUser!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdnColors.muted, fontSize: 11),
                ),
              ),
            IconButton(
              onPressed: onLogout == null
                  ? null
                  : () async {
                      try {
                        await onLogout!();
                      } on MasterApiException catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'La sesión se cerró en este navegador, '
                              'pero el servidor no confirmó la revocación: '
                              '${error.message}',
                            ),
                          ),
                        );
                      }
                    },
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded, color: AdnColors.muted),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: onOpenGuide,
            tooltip: 'Guía de uso',
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AdnColors.turquoiseLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class MasterDashboard extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const MasterDashboard({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return MasterDashboardScreen(onNavigate: onNavigate);
  }
}

class MasterInfoCard extends StatelessWidget {
  final double width;
  final String title;
  final String description;
  final IconData icon;

  const MasterInfoCard({
    super.key,
    required this.width,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 158),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C171B), Color(0xFF070E11)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AdnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdnColors.turquoise.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AdnColors.turquoiseLight, size: 22),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              color: AdnColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: AdnColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin datos operativos',
            style: TextStyle(
              color: AdnColors.turquoiseLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PANTALLAS PENDIENTES
// ============================================================

class MasterModulePlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const MasterModulePlaceholder({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AdnColors.turquoise.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AdnColors.turquoise.withValues(alpha: 0.17),
                ),
              ),
              child: Icon(icon, size: 37, color: AdnColors.turquoise),
            ),
            const SizedBox(height: 19),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AdnColors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Este módulo todavía no está implementado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AdnColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
