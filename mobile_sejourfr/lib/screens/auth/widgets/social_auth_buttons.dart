import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/social_auth_config.dart';
import '../../../core/auth/social_sign_in_service.dart';
import '../../../core/theme/app_theme.dart';

/// Boutons "Continuer avec Google" (toutes plateformes) et "Continuer avec
/// Apple" (iOS uniquement). Affiche un divider "ou" en dessous quand au
/// moins un bouton est rendu.
///
/// Si la config est absente (cf. [SocialAuthConfig]), rien n'est rendu —
/// pas de bouton mort.
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    super.key,
    required this.onError,
    this.onSuccess,
  });

  /// Affichage de l'erreur dans le formulaire parent (sauf annulation user).
  final void Function(String message) onError;

  /// Callback optionnel apres login reussi (avant que le router redirige).
  final VoidCallback? onSuccess;

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _busy = false;

  bool get _showGoogle => SocialAuthConfig.isGoogleConfigured;
  bool get _showApple =>
      Platform.isIOS && SocialAuthConfig.isAppleConfigured;

  Future<void> _runGoogle() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
      widget.onSuccess?.call();
    } on SocialSignInException catch (e) {
      if (!e.cancelled) widget.onError(e.message);
    } catch (e) {
      final err = ApiClient.toApiException(e);
      widget.onError(err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runApple() async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithApple();
      widget.onSuccess?.call();
    } on SocialSignInException catch (e) {
      if (!e.cancelled) widget.onError(e.message);
    } catch (e) {
      final err = ApiClient.toApiException(e);
      widget.onError(err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGoogle && !_showApple) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showGoogle)
          _SocialButton(
            icon: const _GoogleGlyph(),
            label: 'Continuer avec Google',
            background: AppColors.white,
            foreground: AppColors.ink,
            borderColor: AppColors.line,
            onPressed: _busy ? null : _runGoogle,
          ),
        if (_showGoogle && _showApple) const SizedBox(height: 10),
        if (_showApple)
          _SocialButton(
            icon: const Icon(Icons.apple, size: 22, color: AppColors.white),
            label: 'Continuer avec Apple',
            background: AppColors.ink,
            foreground: AppColors.white,
            onPressed: _busy ? null : _runApple,
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.line, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OU',
                style: AppFonts.mono(
                  size: 11,
                  color: AppColors.muted2,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.line, height: 1)),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
  });

  final Widget icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
          child: Opacity(
            opacity: disabled ? 0.6 : 1,
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppFonts.jakarta(
                        size: 15,
                        color: foreground,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  // Logo Google officiel ("G" multicolore) inline en SVG — pas besoin d'asset
  // externe. Source : https://developers.google.com/identity/branding-guidelines
  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3c-1.6 4.7-6 8-11.3 8-6.6 0-12-5.4-12-12s5.4-12 12-12c3 0 5.8 1.1 7.9 3l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z"/>
<path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.7 16 19 13 24 13c3 0 5.8 1.1 7.9 3l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z"/>
<path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.1 35.1 26.7 36 24 36c-5.3 0-9.7-3.3-11.3-8l-6.5 5C9.6 39.6 16.2 44 24 44z"/>
<path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.3 4.3-4.1 5.6l6.2 5.2C41.5 35.5 44 30.1 44 24c0-1.3-.1-2.4-.4-3.5z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: SvgPicture.string(_svg, fit: BoxFit.contain),
    );
  }
}
