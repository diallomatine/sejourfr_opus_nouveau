import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
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
  final _email = TextEditingController(text: 'user@sejourfr.fr');
  final _password = TextEditingController(text: 'User123!');
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

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
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      // Le router redirigera automatiquement vers /home
    } catch (e) {
      final err = ApiClient.toApiException(e);
      setState(() {
        _error = err.statusCode == 401 ? 'Email ou mot de passe incorrect.' : err.message;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    style: AppFonts.fraunces(
                      size: 30,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reprenez votre préparation là où vous l\'avez laissée.',
                    style: AppFonts.jakarta(
                      size: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SocialAuthButtons(
                    onError: (msg) => setState(() => _error = msg),
                  ),
                  _Field(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
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
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Mot de passe requis' : null,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: AppFonts.jakarta(
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
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nouveau ici ? ',
                        style: AppFonts.jakarta(
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: Text(
                          'Créer un compte',
                          style: AppFonts.jakarta(
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
    this.suffixIcon,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
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
          style: AppFonts.jakarta(size: 14),
          decoration: InputDecoration(
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
          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.jakarta(size: 13, color: AppColors.red),
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
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) =>
      _Field(
        label: label,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
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
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) =>
      _Field(
        label: label,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        suffixIcon: suffixIcon,
        autofillHints: autofillHints,
      );

  static Widget errorBox(String message) => _ErrorBox(message: message);
}
