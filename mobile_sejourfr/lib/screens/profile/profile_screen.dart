import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejourfr_logo.dart';

/// Stats agrégées pour la carte "Mes stats" du profil. On lit les 2 stats
/// + le résumé de progression TCF (pour le niveau CECRL plancher) + l'historique
/// des examens TCF complets (pour compter combien ont été passés).
///
/// On garde tout en `FutureProvider.autoDispose` : la card respecte les états
/// loading/error sans casser le rendu du profil — si une seule des 4 requêtes
/// échoue, on dégrade en "—" sur la cellule concernée plutôt que de bloquer.
final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

final _tcfProgressionProvider = FutureProvider.autoDispose<ProgressionSummary>((ref) {
  return ref.watch(userContentRepositoryProvider).progression(module: AppModule.tcf);
});

final _tcfExamsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(fullTcfExamRepositoryProvider).listMine(limit: 100);
  return list.where((e) => e.status == FullTcfExamStatus.completed).length;
});

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
      backgroundColor: AppColors.bg,
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
            const _StatsRow(),
            const SizedBox(height: 14),
            _PlanCard(user: user),
            const SizedBox(height: 14),
            _TargetCard(
              user: user,
              onTap: () => context.push('${AppRoutes.targetPath}?from=$fromHere'),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Préparation'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.history_rounded,
              title: 'Mes historiques',
              subtitle: 'Examens civique, TCF + sessions IA EE/EO',
              accent: AppColors.blue,
              onTap: () => context.push(AppRoutes.historiques),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Compte'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.person_outline_rounded,
              title: 'Mes informations',
              subtitle: 'Identité, email et mot de passe',
              accent: AppColors.blue,
              onTap: () => context.push(AppRoutes.personalInfo),
            ),
            // TODO à remettre en place après.
            /*const SizedBox(height: 8),
            _SettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Gérer les rappels d\'entraînement',
              accent: AppColors.blue,
              onTap: () => _showSoon(context),
            ),*/
            const SizedBox(height: 22),
            const _SectionLabel('Aide & informations légales'),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.help_outline_rounded,
              title: 'Centre d\'aide',
              subtitle: 'FAQ, contact, CGU et politique de confidentialité',
              accent: AppColors.muted,
              onTap: () => context.push(AppRoutes.helpCenter),
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
// Hero compte — gradient bleu, avatar, nom, badge auth provider
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
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
              right: -20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red.withValues(alpha: 0.22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
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
                                weight: FontWeight.w600,
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
                            const SizedBox(height: 3),
                            Text(
                              user.email,
                              style: AppFonts.jakarta(
                                size: 12,
                                color: AppColors.white.withValues(alpha: 0.78),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _HeroChip(
                        icon: _providerIcon(user.authProvider),
                        label: _providerLabel(user.authProvider),
                      ),
                      if (user.targetProcedure != null)
                        _HeroChip(
                          icon: Icons.flag_rounded,
                          label: user.targetProcedure!.shortLabel,
                        ),
                      if (user.targetProcedure?.tcfLevel != null)
                        _HeroChip(
                          icon: Icons.translate_rounded,
                          label: 'TCF ${user.targetProcedure!.tcfLevel}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _providerIcon(AuthProvider p) => switch (p) {
        AuthProvider.local => Icons.mail_outline_rounded,
        AuthProvider.google => Icons.g_mobiledata_rounded,
        AuthProvider.apple => Icons.apple_rounded,
      };

  String _providerLabel(AuthProvider p) => switch (p) {
        AuthProvider.local => 'Email',
        AuthProvider.google => 'Google',
        AuthProvider.apple => 'Apple',
      };

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.jakarta(
              size: 11.5,
              weight: FontWeight.w700,
              color: AppColors.white,
            ).copyWith(letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte "Mes stats" — 3 cellules : questions vues, examens passés, niveau TCF
// ---------------------------------------------------------------------------

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final civique = ref.watch(_civiqueStatsProvider);
    final tcf = ref.watch(_tcfStatsProvider);
    final tcfProg = ref.watch(_tcfProgressionProvider);
    final tcfExams = ref.watch(_tcfExamsCountProvider);

    // Questions vues : somme byTheme.answered des 2 modules. "—" tant que
    // l'une des requêtes n'est pas dispo (loading ou error) plutôt qu'un
    // sous-total trompeur.
    final viewedLabel = (civique.valueOrNull != null && tcf.valueOrNull != null)
        ? _formatLargeCount(
            civique.value!.byTheme.fold<int>(0, (s, t) => s + t.answered) +
                tcf.value!.byTheme.fold<int>(0, (s, t) => s + t.answered),
          )
        : '—';

    // Examens passés = examens TCF complets terminés. Le compteur civique
    // viendra plus tard quand on aura un endpoint dédié (pour l'instant les
    // examens civique sont mélangés avec les thématiques dans /api/me/attempts
    // — déjà filtré dans l'écran d'historique mais pas exposé en KPI).
    final examsLabel = tcfExams.maybeWhen(
      data: (n) => n.toString(),
      orElse: () => '—',
    );

    // Niveau CECRL : on lit `lastFullExam.finalLevel` (plancher des 4
    // épreuves CO/CE/EE/EO, la règle officielle TCF IRN). "—" si pas
    // d'examen passé. C'est un snapshot rapide — pas le best historique.
    final levelLabel = tcfProg.maybeWhen(
      data: (p) => _shortLevel(p.tcf?.lastFullExam?.finalLevel),
      orElse: () => '—',
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '§ MES STATS',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCell(value: viewedLabel, label: 'Questions vues')),
              _StatDivider(),
              Expanded(child: _StatCell(value: examsLabel, label: 'Examens TCF')),
              _StatDivider(),
              Expanded(child: _StatCell(value: levelLabel, label: 'Dernier niveau')),
            ],
          ),
        ],
      ),
    );
  }

  /// Forme courte pour la pastille niveau (la version "A1 non atteint" est
  /// trop longue pour la cellule).
  String _shortLevel(NiveauCecrl? lvl) {
    if (lvl == null) return '—';
    if (lvl == NiveauCecrl.a1NonAtteint) return '<A1';
    return lvl.wire;
  }

  /// Formate un compteur : 1 234 plutôt que 1234 (groupage français à
  /// l'espace fine, lisible sur petite cellule).
  String _formatLargeCount(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppFonts.fraunces(
            size: 22,
            weight: FontWeight.w700,
            color: AppColors.ink,
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.mono(
            size: 9,
            color: AppColors.muted,
            letterSpacing: 1.0,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.line,
    );
  }
}

// ---------------------------------------------------------------------------
// Carte plan / abonnement
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final isPremium = user.isPremium;
    final hasIntegral = user.hasCivique && user.hasTcf;
    final planLabel = !isPremium
        ? 'Plan gratuit'
        : hasIntegral
            ? 'Plan Intégral'
            : user.hasCivique
                ? 'Plan Civique'
                : 'Plan TCF';

    final endLabel =
        user.premiumEndsAt == null ? null : 'Renouvellement le ${_formatDate(user.premiumEndsAt!)}';

    // Plan gratuit / démo → on rend la carte tappable et on ouvre la
    // PaywallSheet partagée (CTA "Gérer mon accès sur le site" qui pousse
    // vers le site web — paiement Stripe hors stores pour éviter la
    // commission Apple/Google, cf. CLAUDE.md racine).
    return AppCard(
      onTap: isPremium ? null : () => showPaywallSheet(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPremium ? AppColors.amber.withValues(alpha: 0.14) : AppColors.line2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
              size: 22,
              color: isPremium ? AppColors.amber : AppColors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      planLabel,
                      style: AppFonts.jakarta(
                        size: 14.5,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isPremium)
                      const AppTag(label: 'Actif', tone: TagTone.success)
                    else
                      const AppTag(label: 'Démo', tone: TagTone.amber),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  endLabel ??
                      (isPremium ? 'Accès complet aux modules.' : 'Appuie pour débloquer tous les modules.'),
                  style: AppFonts.jakarta(
                    size: 12,
                    color: AppColors.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isPremium) const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.muted2),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Carte "Mon parcours" — seule entrée pour modifier la cible (la tile
// dupliquée "Ma démarche" a été retirée, c'était redondant).
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
