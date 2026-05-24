import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import 'login_screen.dart';
import 'widgets/social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;
  Map<String, String>? _fieldErrors;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = null;
    });
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _passwordConfirm.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
          );
    } catch (e) {
      final err = ApiClient.toApiException(e);
      setState(() {
        _fieldErrors = err.fieldErrors;
        _error = err.statusCode == 409 ? 'Un compte existe déjà avec cet email.' : err.message;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _fieldError(String name) => _fieldErrors?[name];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Eyebrow('§ Création de compte'),
                  const SizedBox(height: 8),
                  Text(
                    'Inscrivez-vous',
                    style: AppFonts.fraunces(
                      size: 30,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quelques infos suffisent pour démarrer.',
                    style: AppFonts.jakarta(
                      size: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthFormField.field(
                    label: 'Prénom',
                    controller: _firstName,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthFormField.field(
                    label: 'Nom',
                    controller: _lastName,
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthFormField.field(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: Icons.mail_outline,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Email requis';
                      if (!s.contains('@')) return 'Format invalide';
                      return _fieldError('email');
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthFormField.field(
                    label: 'Mot de passe',
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                    validator: (v) {
                      if ((v?.length ?? 0) < 8) return 'Au moins 8 caractères';
                      return _fieldError('password');
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthFormField.field(
                    label: 'Confirmer le mot de passe',
                    controller: _passwordConfirm,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Confirmation requise' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    AuthFormField.errorBox(_error!),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Créer mon compte',
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                  ),
                  SocialAuthButtons(
                    onError: (msg) => setState(() => _error = msg),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: AppFonts.jakarta(
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Se connecter',
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
      ),
    );
  }
}
