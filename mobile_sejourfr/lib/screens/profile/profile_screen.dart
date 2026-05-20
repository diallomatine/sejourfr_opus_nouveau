import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/auth_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
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

    final fromHere = Uri.encodeComponent(AppRoutes.profile);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Text(
              '§ PROFIL',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 2.0,
              ).copyWith(height: 1.0),
            ),
            const SizedBox(height: 10),
            Text(
              'Mon compte',
              style: AppFonts.fraunces(size: 26, weight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            _ProfileHero(user: user),
            const SizedBox(height: 14),
            _TargetCard(
              user: user,
              onTap: () => context.push('${AppRoutes.targetPath}?from=$fromHere'),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Préparation'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.flag_outlined,
              title: 'Ma démarche',
              subtitle: user.targetProcedure?.fullLabel ?? 'Non définie',
              accent: AppColors.blue,
              onTap: () => context.push(
                '${AppRoutes.targetPath}?from=$fromHere',
              ),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.history_rounded,
              title: 'Mes historiques',
              subtitle: 'Examens QCM + TCF Expression orale et écrite',
              accent: AppColors.blue,
              onTap: () => context.push(AppRoutes.historiques),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.bookmark_outline,
              title: 'Mes questions',
              subtitle: 'Favoris et erreurs récentes',
              accent: AppColors.red,
              onTap: () => context.push(AppRoutes.review),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Compte'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Passer Premium',
              subtitle: 'Accès illimité à toutes les questions',
              accent: AppColors.amber,
              trailing: const AppTag(label: 'Bientôt', tone: TagTone.amber),
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Gérer les rappels d\'entraînement',
              accent: AppColors.blue,
              onTap: () => _showSoon(context),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Aide'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.help_outline_rounded,
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
            const SizedBox(height: 26),
            _LogoutButton(onTap: () => _confirmLogout(context, ref)),
            const SizedBox(height: 26),
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

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
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

// ---------------------------------------------------------------------------
// Hero compte
// ---------------------------------------------------------------------------

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.08),
                    width: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 22,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(user.displayName),
                      style: AppFonts.jakarta(
                        size: 22,
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
                          'MEMBRE SEJOURFR',
                          style: AppFonts.mono(
                            size: 9,
                            color: AppColors.white.withValues(alpha: 0.65),
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.displayName,
                          style: AppFonts.fraunces(
                            size: 22,
                            weight: FontWeight.w600,
                            color: AppColors.white,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Carte "Mon parcours"
// ---------------------------------------------------------------------------

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.user, required this.onTap});

  final AuthUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = user.targetProcedure;
    if (target == null) {
      return AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flag_outlined,
                color: AppColors.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Définir mon objectif',
                    style: AppFonts.jakarta(size: 14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Adaptez les questions à votre démarche',
                    style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.muted2,
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MON PARCOURS',
                style: AppFonts.mono(
                  size: 9,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppColors.muted2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.fullLabel,
                      style: AppFonts.jakarta(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppTag(label: 'Civique ${target.wire}', tone: TagTone.blue),
                        AppTag(label: 'TCF ${target.tcfLevel}', tone: TagTone.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label + tile
// ---------------------------------------------------------------------------

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
        ).copyWith(height: 1.0, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final Widget? trailing;

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
              color: accent.withValues(alpha: 0.12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.muted2,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout
// ---------------------------------------------------------------------------

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                'Se déconnecter',
                style: AppFonts.jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
