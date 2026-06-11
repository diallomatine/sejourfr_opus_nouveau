import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

/// Formulaire de contact natif. POST `/api/contact` (endpoint public).
///
/// Pré-remplit nom + email depuis l'utilisateur connecté si dispo (le
/// formulaire reste utilisable déconnecté). Validation côté front + remontée
/// des erreurs serveur via snackbar.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    String prefilledName = '';
    String prefilledEmail = '';
    if (auth is AuthAuthenticated) {
      prefilledName = auth.user.displayName;
      prefilledEmail = auth.user.email;
    }
    _nameCtrl = TextEditingController(text: prefilledName);
    _emailCtrl = TextEditingController(text: prefilledEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(contactRepositoryProvider).submit(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            subject: _subjectCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Message envoyé. Réponse sous 24 h ouvrées.',
            style: AppFonts.ui(color: AppColors.white, size: 13.5),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = ApiClient.toApiException(e).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          content: Text(
            msg,
            style: AppFonts.ui(color: AppColors.white, size: 13.5),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nous contacter',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _Pitch(),
              const SizedBox(height: 22),
              _FieldLabel('Votre nom'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(hint: 'Prénom et nom'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ton nom est requis' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Email'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(hint: 'tu@exemple.fr'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Sujet'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectCtrl,
                decoration: _inputDecoration(hint: 'Ex. Problème de paiement'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Sujet trop court'
                    : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Votre message'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageCtrl,
                minLines: 5,
                maxLines: 10,
                maxLength: 4000,
                decoration: _inputDecoration(
                  hint: 'Décris ton problème ou ta question...',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Message trop court (10 caractères min.)'
                    : null,
              ),
              const SizedBox(height: 14),
              _SubmitButton(
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.ui(size: 13.5, color: AppColors.muted2),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }
}

String? _validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email requis';
  final trimmed = v.trim();
  // Validation simple : on s'appuie sur le @ pour ne pas faire un regex
  // complexe — la vérification réelle se fait côté serveur.
  if (!trimmed.contains('@') || !trimmed.contains('.')) return 'Email invalide';
  return null;
}

class _Pitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.messageCircle,
              color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Décris ton problème en quelques lignes',
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Nous te répondons par email sous 24 h ouvrées.',
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                    height: 1.4,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.mono(
        size: 10,
        color: AppColors.muted,
        letterSpacing: 1.8,
        weight: FontWeight.w700,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Text(
                'Envoyer le message',
                style: AppFonts.ui(
                  size: 14.5,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
