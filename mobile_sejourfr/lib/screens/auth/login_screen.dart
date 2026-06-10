import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_checkbox.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/sejourfr_logo.dart';
import 'widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _remember = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await ref.read(tokenStorageProvider).readCredentials();
    if (creds != null && mounted) {
      setState(() {
        _email.text = creds.email;
        _password.text = creds.password;
        _remember = true;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    // Capturé avant l'await : après un login réussi, le router redirige et ce
    // widget peut être démonté — on n'utilise donc plus `ref` ensuite.
    final storage = ref.read(tokenStorageProvider);
    final email = _email.text.trim();
    final password = _password.text;
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: email,
            password: password,
          );
      // Succès : on enregistre (ou efface) les identifiants selon la case.
      if (_remember) {
        await storage.saveCredentials(email, password);
      } else {
        await storage.clearCredentials();
      }
      // Le router redirigera automatiquement vers /home
    } catch (e) {
      final err = ApiClient.toApiException(e);
      setState(() {
        _error = err.statusCode == 401
            ? 'Email ou mot de passe incorrect.'
            : err.message;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Center(
                      child: SejourFrLogoLockup(
                        cocardeSize: 72,
                        wordmarkSize: 32,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Eyebrow('§ Bienvenue'),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous',
                      style: AppFonts.display(
                        size: 30,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reprenez votre préparation là où vous l\'avez laissée.',
                      style: AppFonts.ui(
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Field(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      prefixIcon: LucideIcons.mail,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Email requis';
                        if (!s.contains('@')) return 'Format invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Mot de passe',
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      prefixIcon: LucideIcons.lock,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          color: AppColors.muted,
                        ),
                      ),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Mot de passe requis' : null,
                    ),
                    const SizedBox(height: 14),
                    AppCheckbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v),
                      label: Text(
                        'Enregistrer mes identifiants',
                        style: AppFonts.ui(size: 13.5, color: AppColors.ink),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: AppFonts.ui(
                            size: 13,
                            color: AppColors.blue,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      _ErrorBox(message: _error!),
                    ],
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Se connecter',
                      onPressed: _submitting ? null : _submit,
                      isLoading: _submitting,
                    ),
                    SocialAuthButtons(
                      onError: (msg) => setState(() => _error = msg),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nouveau ici ? ',
                          style: AppFonts.ui(
                            size: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.register),
                          child: Text(
                            'Créer un compte',
                            style: AppFonts.ui(
                              size: 14,
                              color: AppColors.blue,
                              weight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Champs réutilisables (Login + Register)
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, color: AppColors.muted),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          validator: validator,
          style: AppFonts.ui(size: 14),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.muted)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.ui(size: 13, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Re-export pour register/forgot
class FormField {
  static Widget field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) =>
      _Field(
        label: label,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        autofillHints: autofillHints,
      );

  static Widget errorBox(String message) => _ErrorBox(message: message);
}

// Re-export pour register/forgot
class AuthFormField {
  static Widget field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) =>
      _Field(
        label: label,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        autofillHints: autofillHints,
      );

  static Widget errorBox(String message) => _ErrorBox(message: message);
}
