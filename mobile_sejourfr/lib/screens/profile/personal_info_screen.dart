import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';

/// Édition des informations personnelles (compte LOCAL uniquement) :
///   - Identité (firstName/lastName) — édition inline + bouton "Enregistrer"
///   - Email — édition via bottom sheet déclenchant une vérif par mail
///   - Mot de passe — bottom sheet avec ancien + nouveau
///
/// Pour les comptes social (Google/Apple), email + password sont rendus en
/// lecture seule avec un message expliquant que ça se gère côté provider
/// (l'API backend refuse aussi, mais on prévient l'utilisateur en amont).
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  bool _savingIdentity = false;
  String? _identityError;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIdentity() async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (fn.isEmpty || ln.isEmpty) {
      setState(() => _identityError = 'Prénom et nom requis');
      return;
    }
    setState(() {
      _savingIdentity = true;
      _identityError = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(firstName: fn, lastName: ln);
      // Rafraîchit le user en mémoire pour que le profil reflète le changement.
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      _showSnack('Identité mise à jour', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _identityError = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _savingIdentity = false);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.green : AppColors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: AppFonts.ui(color: AppColors.white, size: 13.5),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = auth.user;
    final isLocal = user.authProvider == AuthProvider.local;

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
          'Mes informations',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // ── Identité (toujours éditable) ──────────────────────────────
            _SectionLabel('Identité'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _FieldLabel('Prénom'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _input('Prénom'),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Nom'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _input('Nom'),
                  ),
                  if (_identityError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _identityError!,
                      style: AppFonts.ui(size: 12, color: AppColors.red),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _PrimaryButton(
                    label: 'Enregistrer',
                    loading: _savingIdentity,
                    onPressed: _savingIdentity ? null : _saveIdentity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Email (lecture + bouton "Changer") ────────────────────────
            _SectionLabel('Adresse email'),
            const SizedBox(height: 10),
            _ReadOnlyTile(
              icon: LucideIcons.mail,
              accent: AppColors.blue,
              title: user.email,
              subtitle: isLocal
                  ? 'On enverra un mail de vérification au nouvel email avant de l\'activer.'
                  : 'Connexion via ${_providerLabel(user.authProvider)} — l\'email se gère côté provider.',
              action: isLocal
                  ? _GhostButton(
                      label: 'Changer',
                      onPressed: () =>
                          _showChangeEmailSheet(context, ref, user.email),
                    )
                  : null,
            ),

            const SizedBox(height: 22),

            // ── Mot de passe ─────────────────────────────────────────────
            _SectionLabel('Mot de passe'),
            const SizedBox(height: 10),
            _ReadOnlyTile(
              icon: LucideIcons.lock,
              accent: AppColors.red,
              title: '••••••••••',
              subtitle: isLocal
                  ? 'Tape l\'ancien et le nouveau pour modifier.'
                  : 'Connexion via ${_providerLabel(user.authProvider)} — pas de mot de passe SejourFR.',
              action: isLocal
                  ? _GhostButton(
                      label: 'Modifier',
                      onPressed: () => _showChangePasswordSheet(context, ref),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.ui(size: 13.5, color: AppColors.muted2),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  String _providerLabel(AuthProvider p) => switch (p) {
        AuthProvider.local => 'email',
        AuthProvider.google => 'Google',
        AuthProvider.apple => 'Apple',
      };
}

// ---------------------------------------------------------------------------
// Bottom sheets : change email + change password
// ---------------------------------------------------------------------------

void _showChangeEmailSheet(
    BuildContext context, WidgetRef ref, String currentEmail) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ChangeEmailSheet(currentEmail: currentEmail),
    ),
  );
}

void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _ChangePasswordSheet(),
    ),
  );
}

class _ChangeEmailSheet extends ConsumerStatefulWidget {
  const _ChangeEmailSheet({required this.currentEmail});

  final String currentEmail;

  @override
  ConsumerState<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<_ChangeEmailSheet> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newEmail = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      setState(() => _error = 'Email invalide');
      return;
    }
    if (pwd.isEmpty) {
      setState(() => _error = 'Ton mot de passe actuel est requis');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).requestEmailChange(
            newEmail: newEmail,
            currentPassword: pwd,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Mail de vérification envoyé à $newEmail. Clique sur le lien pour confirmer.',
            style: AppFonts.ui(color: AppColors.white, size: 13),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: 'Changer mon email',
      subtitle:
          'On envoie un lien de vérification au nouvel email. Tant que tu n\'as pas cliqué dessus, ton compte reste accessible avec ${widget.currentEmail}.',
      children: [
        _FieldLabel('Nouvel email'),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _input('nouvel@email.fr'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Ton mot de passe actuel'),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: _input('••••••••'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppFonts.ui(size: 12, color: AppColors.red)),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Envoyer le lien',
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (current.isEmpty) {
      setState(() => _error = 'Mot de passe actuel requis');
      return;
    }
    if (newPwd.length < 8) {
      setState(() => _error = 'Le nouveau mot de passe doit faire au moins 8 caractères');
      return;
    }
    if (newPwd != confirm) {
      setState(() => _error = 'La confirmation ne correspond pas');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: current,
            newPassword: newPwd,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Mot de passe modifié.',
            style: AppFonts.ui(color: AppColors.white, size: 13.5),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: 'Modifier mon mot de passe',
      subtitle:
          'Il te faut connaître ton mot de passe actuel pour faire la modification.',
      children: [
        _FieldLabel('Mot de passe actuel'),
        const SizedBox(height: 6),
        TextField(
          controller: _currentCtrl,
          obscureText: true,
          decoration: _input('••••••••'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Nouveau mot de passe'),
        const SizedBox(height: 6),
        TextField(
          controller: _newCtrl,
          obscureText: true,
          decoration: _input('Au moins 8 caractères'),
        ),
        const SizedBox(height: 14),
        _FieldLabel('Confirmer le nouveau'),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmCtrl,
          obscureText: true,
          decoration: _input('Re-tape le nouveau'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppFonts.ui(size: 12, color: AppColors.red)),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Mettre à jour',
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets utilitaires partagés
// ---------------------------------------------------------------------------

InputDecoration _input(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppFonts.ui(size: 13.5, color: AppColors.muted2),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        '§ ${text.toUpperCase()}',
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 2.0,
          weight: FontWeight.w600,
        ).copyWith(height: 1.0),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Text(
                label,
                style: AppFonts.ui(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppFonts.display(
                  size: 22,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
