import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      final err = ApiClient.toApiException(e);
      setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Eyebrow('§ Mot de passe oublié'),
                const SizedBox(height: 8),
                Text(
                  'Réinitialiser',
                  style: AppFonts.display(size: 30, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Indiquez votre email, nous vous enverrons un lien de réinitialisation.',
                  style: AppFonts.ui(size: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                if (_sent)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Si un compte est associé à cet email, vous recevrez un message dans quelques instants.',
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.green,
                      ),
                    ),
                  )
                else ...[
                  AuthFormField.field(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: LucideIcons.mail,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Email requis';
                      if (!s.contains('@')) return 'Format invalide';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    AuthFormField.errorBox(_error!),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Envoyer le lien',
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
