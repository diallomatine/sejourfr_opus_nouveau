import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/stat_value_card.dart';

/// Statut d'abonnement pour la carte « Mon pass » du profil.
///
/// L'onglet Profil vit dans le ShellRoute : pousser l'écran de gestion par
/// dessus ne dispose PAS ce provider autoDispose (le widget reste monté sous
/// la pile), donc un simple autoDispose ne refetch pas au retour d'un achat.
/// On le fait donc dépendre de la signature Premium portée par
/// `authControllerProvider` — `BillingController` la rafraîchit après chaque
/// verify-receipt (et `AuthController` après une résiliation Stripe). Quand
/// elle change, ce provider se réexécute et refetch le statut détaillé →
/// la carte « Mon pass » reflète l'achat sans invalidation manuelle.
final _subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusResponse>((ref) {
  ref.watch(authControllerProvider.select((s) => switch (s) {
        AuthAuthenticated(:final user) => (
            user.isPremium,
            user.hasCivique,
            user.hasTcf,
            user.premiumEndsAt
          ),
        _ => null,
      }));
  return ref.watch(billingRepositoryProvider).getSubscriptionStatus();
});

/// Onglet « Profil » de la refonte 2026 (cf. `MProfil` maquette) : carte
/// identité, 3 stats, carte « Mon pass », objectif, groupes Compte / Aide
/// et actions (déconnexion, suppression).
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
    final dashboard = ref.watch(dashboardProvider);
    final subscription = ref.watch(_subscriptionStatusProvider);
    final fromHere = Uri.encodeComponent(AppRoutes.profile);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'Profil', large: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _IdentityCard(
                    user: user,
                    onTap: () => context.push(AppRoutes.personalInfo),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatValueCard(
                          value: dashboard.valueOrNull?.globalSuccessPercent !=
                                  null
                              ? '${dashboard.valueOrNull!.globalSuccessPercent} %'
                              : '—',
                          label: 'Maîtrise',
                          color: AppColors.blue,
                          valueSize: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatValueCard(
                          value: dashboard.valueOrNull != null
                              ? '${dashboard.valueOrNull!.currentStreakDays} j'
                              : '—',
                          label: 'Série',
                          color: AppColors.red,
                          valueSize: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatValueCard(
                          value: dashboard
                                  .valueOrNull?.estimatedTcfLevel?.shortName ??
                              '—',
                          label: 'Niveau estimé',
                          color: AppColors.blue,
                          valueSize: 22,
                          // Un niveau qui ne porte pas sur les 4 épreuves le
                          // dit ici (parité web /profil).
                          hint: estimatedTcfLevelScopeLabel(
                              dashboard.valueOrNull),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Mon pass'),
                  const SizedBox(height: 12),
                  _PassCard(
                    user: user,
                    subscription: subscription,
                    onTap: () async {
                      await context.push(AppRoutes.manageSubscription);
                      // Filet de sécurité : si l'achat/la résiliation n'a pas
                      // muté la signature Premium de l'auth (ex. statut
                      // détaillé inchangé mais date d'échéance prolongée), on
                      // refetch quand même au retour de l'écran de gestion.
                      ref.invalidate(_subscriptionStatusProvider);
                    },
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Mon objectif'),
                  const SizedBox(height: 12),
                  _ObjectifCard(
                    user: user,
                    onTap: () =>
                        context.push('${AppRoutes.targetPath}?from=$fromHere'),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Mon compte'),
                  const SizedBox(height: 12),
                  ListGroup(
                    children: [
                      ListRow(
                        icon: LucideIcons.penLine,
                        title: 'Mes informations',
                        sub: user.email,
                        onTap: () => context.push(AppRoutes.personalInfo),
                      ),
                      // « Ma progression » a quitté l'écran Plan : le Plan dit
                      // quoi travailler maintenant, la progression se consulte.
                      // Elle n'est plus dans la barre du bas (remplacée par
                      // Plan), donc c'est ici qu'on la retrouve.
                      ListRow(
                        icon: LucideIcons.chartColumn,
                        title: 'Ma progression',
                        sub: 'Maîtrise par parcours et niveau estimé',
                        onTap: () => context.push(AppRoutes.progress),
                      ),
                      ListRow(
                        icon: LucideIcons.dumbbell,
                        title: 'Mon entraînement',
                        sub: 'Historique, mes questions et favoris',
                        onTap: () => context.push(AppRoutes.monEntrainement),
                      ),
                      ListRow(
                        icon: LucideIcons.bookOpen,
                        title: "Centre d'aide",
                        sub: 'FAQ, CGU, confidentialité, contact',
                        onTap: () => context.push(AppRoutes.helpCenter),
                      ),
                      ListRow(
                        icon: LucideIcons.info,
                        title: 'À propos de SejourFR',
                        sub: 'Outil indépendant · sources officielles',
                        onTap: () => context.push(AppRoutes.about),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListGroup(
                    children: [
                      ListRow(
                        icon: LucideIcons.x,
                        iconBg: AppColors.redLight,
                        iconColor: AppColors.red,
                        title: 'Supprimer mon compte',
                        onTap: () => _confirmDeleteAccount(context, ref),
                        right: const SizedBox.shrink(),
                      ),
                      ListRow(
                        icon: LucideIcons.arrowLeft,
                        iconBg: AppColors.surface2,
                        iconColor: AppColors.inkSoft,
                        title: 'Se déconnecter',
                        onTap: () => _confirmLogout(context, ref),
                        right: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'SejourFR · v0.1.0',
                      style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
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

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppSheet<bool>(
      context,
      icon: LucideIcons.arrowLeft,
      title: 'Se déconnecter ?',
      sub: 'Vous devrez vous reconnecter pour reprendre votre préparation.',
      children: [
        AppButton(
          label: 'Se déconnecter',
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AppButton(
          label: 'Annuler',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authControllerProvider);
    final hasPaidAccess = auth is AuthAuthenticated && auth.user.isPremium;
    final message = 'Cette action est irréversible. Vos progrès, examens, '
        'favoris et informations personnelles seront définitivement supprimés.'
        '${hasPaidAccess ? "\n\nVotre accès payant en cours sera perdu et ne "
            "fait l'objet d'aucun remboursement." : ''}';

    final confirmed = await showAppSheet<bool>(
      context,
      icon: LucideIcons.x,
      iconBg: AppColors.redLight,
      iconColor: AppColors.red,
      title: 'Supprimer votre compte ?',
      sub: 'Cette action est définitive',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Text(
            message,
            style:
                AppFonts.ui(size: 13, color: AppColors.inkSoft, height: 1.55),
          ),
        ),
        AppButton(
          label: 'Supprimer définitivement',
          variant: AppButtonVariant.danger,
          icon: LucideIcons.x,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AppButton(
          label: 'Annuler',
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final controller = ref.read(authControllerProvider.notifier);
    try {
      final result = await controller.deleteAccount();

      // Message d'action manuelle si un abonnement Apple/Google reste à
      // résilier côté store, tant que l'écran est monté.
      if (context.mounted &&
          result.hasActiveSubscription &&
          result.manualActionMessage != null) {
        await showAppSheet<void>(
          context,
          icon: LucideIcons.check,
          title: 'Compte supprimé',
          sub: result.manualActionMessage,
          children: [
            AppButton(
              label: 'Compris',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
      // Vide la session locale → le router redirige vers /login.
      await controller.logout();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la suppression. Réessayez.'),
          ),
        );
      }
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user, required this.onTap});

  final AuthUser user;
  final VoidCallback onTap;

  String get _initials {
    final f = user.firstName?.trim();
    final l = user.lastName?.trim();
    if (f != null && f.isNotEmpty) {
      final second = l != null && l.isNotEmpty ? l[0] : '';
      return '${f[0]}$second'.toUpperCase();
    }
    return user.email.isNotEmpty ? user.email[0].toUpperCase() : '·';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppFonts.display(size: 26, color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(size: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
                ),
                if (user.targetProcedure != null) ...[
                  const SizedBox(height: 6),
                  AppTag(
                    label: user.targetProcedure!.shortLabel,
                    icon: LucideIcons.mapPin,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                'Modifier',
                style: AppFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronRight,
                  size: 14, color: AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte « Mon pass » : nom du pass + statut + échéance, tap → gestion.
/// Compte gratuit : carte Découverte avec CTA vers la page d'abonnement.
class _PassCard extends StatelessWidget {
  const _PassCard({
    required this.user,
    required this.subscription,
    required this.onTap,
  });

  final AuthUser user;
  final AsyncValue<SubscriptionStatusResponse> subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sub = subscription.valueOrNull;
    final premium = sub?.isPremium ?? user.isPremium;

    final String name;
    final Color accent;
    if (!premium) {
      name = 'Découverte';
      accent = AppColors.inkSoft;
    } else if (sub?.moduleAccess == ModuleAccess.integral ||
        (sub == null && user.hasTcf && user.hasCivique)) {
      name = 'Pass Intégral';
      accent = AppColors.red;
    } else if (sub?.moduleAccess == ModuleAccess.tcf ||
        (sub == null && user.hasTcf)) {
      name = 'Pass TCF';
      accent = AppColors.blue;
    } else if (sub?.moduleAccess == ModuleAccess.civique || user.hasCivique) {
      name = 'Pass Civique';
      accent = AppColors.blue;
    } else {
      // Premium annoncé sans périmètre connu (statut pas encore chargé) : on
      // ne nomme pas un pass au hasard, ce serait mentir sur ce qui est ouvert.
      name = 'Pass actif';
      accent = AppColors.blue;
    }

    final expiresAt = sub?.expiresAt ?? user.premiumEndsAt;
    final String subLabel;
    if (!premium) {
      subLabel = 'Accès limité — débloquez tout SejourFR';
    } else if (expiresAt != null) {
      subLabel = "Valable jusqu'au ${_formatDate(expiresAt)}";
    } else {
      subLabel = 'Accès actif';
    }

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: premium ? accent : AppColors.surface3,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              LucideIcons.graduationCap,
              size: 23,
              color: premium ? AppColors.white : AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(size: 16, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (premium)
                      const AppTag(
                        label: 'Actif',
                        tone: TagTone.success,
                        icon: LucideIcons.check,
                      )
                    else
                      const AppTag(label: 'Gratuit', tone: TagTone.neutral),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(size: 12.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 16, color: AppColors.inkFaint),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ObjectifCard extends StatelessWidget {
  const _ObjectifCard({required this.user, required this.onTap});

  final AuthUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final procedure = user.targetProcedure;
    return AppCard(
      color: AppColors.surface2,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child:
                const Icon(LucideIcons.target, size: 23, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  procedure?.fullLabel ?? 'Choisir mon parcours',
                  style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                ),
                Text(
                  procedure != null
                      ? 'Parcours visé — toucher pour modifier'
                      : 'Définissez votre objectif administratif',
                  style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
