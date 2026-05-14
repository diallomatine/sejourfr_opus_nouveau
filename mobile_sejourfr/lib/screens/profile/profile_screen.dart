import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/sejourfr_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Eyebrow('§ Profil'),
            const SizedBox(height: 8),
            Text(
              'Mon compte',
              style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(user.displayName),
                      style: AppFonts.jakarta(
                        size: 18,
                        weight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: AppFonts.jakarta(size: 15, weight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: AppFonts.jakarta(
                            size: 12.5,
                            color: AppColors.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppTag(label: 'Gratuit', tone: TagTone.neutral),
                ],
              ),
            ),
            const Eyebrow('§ Paramètres'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.flag_outlined,
              title: 'Ma démarche',
              subtitle: _pathSubtitle(user.targetProcedure),
              accent: AppColors.blue,
              onTap: () => context.push(
                '${AppRoutes.targetPath}?from=${Uri.encodeComponent(AppRoutes.profile)}',
              ),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.history,
              title: 'Mes examens',
              subtitle: 'Historique et progression',
              accent: AppColors.blue,
              onTap: () => context.push(AppRoutes.history),
            ),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Passer Premium',
              subtitle: 'Accès illimité à toutes les questions',
              accent: AppColors.amber,
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'Gérer les rappels d\'entraînement',
              accent: AppColors.blue,
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.help_outline,
              title: 'Centre d\'aide',
              subtitle: 'Questions fréquentes et contact',
              accent: AppColors.muted,
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.shield_outlined,
              title: 'Confidentialité',
              subtitle: 'Politique et données',
              accent: AppColors.muted,
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Se déconnecter',
              variant: AppButtonVariant.ghost,
              icon: Icons.logout,
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 28),
            const Center(child: SejourFrTagline()),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version 0.1.0',
                style: AppFonts.mono(
                  size: 9,
                  color: AppColors.muted2,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pathSubtitle(TargetProcedure? path) {
    if (path == null) return 'Non définie';
    return path.fullLabel;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
          'Bientôt disponible',
          style: AppFonts.jakarta(color: AppColors.white, size: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Se déconnecter ?',
          style: AppFonts.fraunces(size: 20, weight: FontWeight.w600),
        ),
        content: Text(
          'Vous devrez vous reconnecter pour reprendre votre préparation.',
          style: AppFonts.jakarta(size: 13.5, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Se déconnecter',
              style: AppFonts.jakarta(
                color: AppColors.red,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (result == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.jakarta(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.muted2),
        ],
      ),
    );
  }
}
