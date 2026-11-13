import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/adn_colors.dart';
import '../../core/master_identity.dart';
import '../../core/master_api_client.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// ACCESO CENTRAL
// ============================================================

class MasterAccessApp extends StatefulWidget {
  final Widget previewApp;
  final Widget Function(
    MasterApiClient apiClient,
    MasterUser user,
    Future<void> Function() onLogout,
  )?
  authenticatedAppBuilder;

  const MasterAccessApp({
    super.key,
    required this.previewApp,
    this.authenticatedAppBuilder,
  });

  @override
  State<MasterAccessApp> createState() => _MasterAccessAppState();
}

class _MasterAccessAppState extends State<MasterAccessApp> {
  bool _previewEnabled = false;
  late final MasterApiClient _apiClient = MasterApiClient();
  MasterUser? _user;

  void _openPreview() {
    if (!kDebugMode) {
      return;
    }

    setState(() {
      _previewEnabled = true;
    });
  }

  void _authenticated(MasterUser user) {
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    try {
      await _apiClient.logout();
    } finally {
      if (mounted) {
        setState(() => _user = null);
      }
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && _previewEnabled) {
      return widget.previewApp;
    }

    final user = _user;
    final authenticatedAppBuilder = widget.authenticatedAppBuilder;
    if (user != null && authenticatedAppBuilder != null) {
      return authenticatedAppBuilder(_apiClient, user, _logout);
    }

    return MaterialApp(
      title: MasterIdentity.fullName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AdnColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdnColors.turquoise,
          brightness: Brightness.dark,
          surface: AdnColors.background,
        ),
        inputDecorationTheme: const InputDecorationThemeData(errorMaxLines: 3),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AdnColors.panel,
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(color: AdnColors.white, fontSize: 13),
        ),
      ),
      home: MasterAccessScreen(
        apiClient: _apiClient,
        onAuthenticated: _authenticated,
        onPreviewRequested: _openPreview,
      ),
    );
  }
}

// ============================================================
// FORMULARIO DE ACCESO
// ============================================================

class MasterAccessScreen extends StatefulWidget {
  final VoidCallback onPreviewRequested;
  final ValueChanged<MasterUser> onAuthenticated;
  final MasterApiClient apiClient;

  const MasterAccessScreen({
    super.key,
    required this.apiClient,
    required this.onAuthenticated,
    required this.onPreviewRequested,
  });

  @override
  State<MasterAccessScreen> createState() => _MasterAccessScreenState();
}

class _MasterAccessScreenState extends State<MasterAccessScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _recoveryMode = false;
  bool _showPassword = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    if (!valid) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }

    return null;
  }

  void _setRecoveryMode(bool enabled) {
    FocusScope.of(context).unfocus();

    setState(() {
      _recoveryMode = enabled;
      _showPassword = false;
      _passwordController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formKey.currentState?.reset();
      }
    });
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    final formIsValid = _formKey.currentState?.validate() == true;
    if (!formIsValid || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_recoveryMode) {
        await widget.apiClient.requestPasswordReset(_emailController.text);
        if (!mounted) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 5),
              content: Text(
                'Si la cuenta existe, se enviarán instrucciones para restablecer la contraseña.',
              ),
            ),
          );
      } else {
        final user = await widget.apiClient.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        widget.onAuthenticated(user);
      }
    } on MasterApiException catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(error.message),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdnColors.muted, fontSize: 13),
      prefixIcon: Icon(icon, color: AdnColors.muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AdnColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      enabledBorder: border(AdnColors.border),
      focusedBorder: border(AdnColors.turquoise),
      errorBorder: border(AdnColors.coral),
      focusedErrorBorder: border(AdnColors.coral),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AdnColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Correo electrónico'),
        TextFormField(
          key: const Key('master_login_email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: _recoveryMode
              ? TextInputAction.done
              : TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          autocorrect: false,
          validator: _validateEmail,
          onFieldSubmitted: (_) {
            if (_recoveryMode) {
              _submitForm();
            }
          },
          style: const TextStyle(color: AdnColors.white, fontSize: 14),
          decoration: _decoration(
            hint: 'correo@empresa.com',
            icon: Icons.alternate_email_rounded,
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Contraseña'),
        TextFormField(
          key: const Key('master_login_password'),
          controller: _passwordController,
          obscureText: !_showPassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enableSuggestions: false,
          autocorrect: false,
          validator: _validatePassword,
          onFieldSubmitted: (_) => _submitForm(),
          style: const TextStyle(color: AdnColors.white, fontSize: 14),
          decoration: _decoration(
            hint: 'Ingresa tu contraseña',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              key: const Key('master_toggle_password'),
              tooltip: _showPassword
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AdnColors.muted,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandSymbol({double size = 85}) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: AdnColors.turquoise.withValues(alpha: 0.28)),
      ),
      child: SvgPicture.asset(
        'assets/branding/logo_adn.svg',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _brandPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _brandSymbol(size: 100),
        const SizedBox(height: 28),
        const Text(
          MasterIdentity.owner,
          style: TextStyle(
            color: AdnColors.turquoiseLight,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Software\nMaster',
          style: TextStyle(
            color: AdnColors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420),
          child: Text(
            'Administración central de productos '
            'de software, clientes, instancias, '
            'suscripciones y operaciones '
            'de ADN Publicidad.',
            style: TextStyle(color: AdnColors.muted, fontSize: 15, height: 1.7),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          height: 4,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AdnColors.turquoise, AdnColors.coral, Color(0xFFF5C000)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _accessCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 465),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C171B), Color(0xFF070E11)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdnColors.border),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _recoveryMode
                    ? Icons.mark_email_read_outlined
                    : Icons.shield_outlined,
                color: AdnColors.turquoiseLight,
                size: 33,
              ),

              const SizedBox(height: 18),

              Text(
                _recoveryMode ? 'Recuperar acceso' : 'Iniciar sesión',
                style: const TextStyle(
                  color: AdnColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _recoveryMode
                    ? 'Ingresa el correo registrado '
                          'en ADN Publicidad Software Master.'
                    : 'Acceso exclusivo al personal '
                          'autorizado de ADN Publicidad.',
                style: const TextStyle(
                  color: AdnColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 28),

              _emailField(),

              if (!_recoveryMode) ...[
                const SizedBox(height: 21),
                _passwordField(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('master_forgot_password'),
                    onPressed: () => _setRecoveryMode(true),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AdnColors.turquoiseLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('master_submit'),
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: Icon(
                    _isSubmitting
                        ? Icons.hourglass_top_rounded
                        : _recoveryMode
                        ? Icons.mail_outline_rounded
                        : Icons.login_rounded,
                    size: 19,
                  ),
                  label: Text(
                    _recoveryMode ? 'Solicitar recuperación' : 'Iniciar sesión',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdnColors.turquoise,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              if (_recoveryMode) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    key: const Key('master_back_to_login'),
                    onPressed: () => _setRecoveryMode(false),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('Volver al inicio de sesión'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdnColors.turquoiseLight,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(color: AdnColors.border),
              const SizedBox(height: 14),

              const Text(
                'El acceso y la recuperación se verifican '
                'contra el servidor de Software Master.',
                style: TextStyle(
                  color: AdnColors.muted,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),

              if (kDebugMode) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('master_preview_access'),
                    onPressed: widget.onPreviewRequested,
                    icon: const Icon(Icons.developer_mode_rounded, size: 19),
                    label: const Text('Entrar en vista previa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdnColors.turquoiseLight,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: AdnColors.turquoise),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Solo para desarrollo. '
                    'Sin autenticación.',
                    style: TextStyle(color: AdnColors.muted, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISEÑO RESPONSIVE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 950;

        return Scaffold(
          backgroundColor: AdnColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: desktop ? 45 : 20,
                        vertical: desktop ? 45 : 32,
                      ),
                      child: desktop
                          ? Row(
                              children: [
                                Expanded(child: _brandPanel()),
                                const SizedBox(width: 55),
                                Expanded(child: Center(child: _accessCard())),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _brandSymbol(size: 78),
                                const SizedBox(height: 15),
                                const Text(
                                  MasterIdentity.fullName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AdnColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _accessCard(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
