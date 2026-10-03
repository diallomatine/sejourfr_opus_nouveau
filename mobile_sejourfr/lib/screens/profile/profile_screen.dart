import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/client_context.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/billing_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../../core/widgets/stat_value_card.dart';
import '../favoris/favoris_labels.dart';
import 'account_labels.dart';
import 'profile_labels.dart';
import '../../core/router/shell_navigation.dart';

/// Statut d'abonnement pour la carte « Mon pass » du profil.
///
/// L'onglet Profil vit dans le ShellRoute : pousser l'écran de gestion par
/// dessus ne dispose PAS ce provider autoDispose (le widget reste monté sous
/// la pile), donc un simple autoDispose ne refetch pas au retour d'un achat.
/// Il observe donc [accesRevisionProvider], **l'autorité unique** de la
/// fraîcheur d'un accès, émise par `AuthController.refreshSubscriptionStatus`
/// — donc après chaque vérification de reçu et chaque restauration. La carte
/// « Mon pass » reflète l'achat sans invalidation manuelle.
///
/// ⚠️ Il portait sa propre signature Premium, recopiée à la main : c'est
/// exactement cette copie que le signal généralise, pour que les quinze autres
/// lectures d'accès en bénéficient au lieu de celle-ci seule.
final _subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusResponse>((ref) {
  ref.watch(accesRevisionProvider);
  return ref.watch(billingRepositoryProvider).getSubscriptionStatus();
});

/// **Onglet « Profil »** — Navigation v2, phase 4b (maquette
/// `docs/redesign/sejourfr-navigation-mobile.html`, `#profil`) : titre et
/// phrase, carte profil, puis « Mon compte » en [SfInfoCard] — **Mon pass**
/// (jamais « abonnement »), Mes informations et Notifications **gardées
/// séparées** (pas d'écran « Paramètres »), Aide.
///
/// Gardés, hors maquette : e-mail et pastille de démarche (dans la carte),
/// les 3 tuiles, « Mon objectif », Ma progression, Mes favoris, À propos,
/// Supprimer mon compte / Se déconnecter (+ leurs feuilles) et la version.
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

    final dash = dashboard.valueOrNull;
    final sub = subscription.valueOrNull;
    final procedure = user.targetProcedure;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            const SfModuleHeader(
              civique: false,
              title: kProfileTitle,
              lead: kProfileLead,
            ),
            const SizedBox(height: 20),
            _ProfileCard(
              user: user,
              passName: _passName(user, sub),
              onTap: () => context.push(AppRoutes.personalInfo),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatValueCard(
                    value: dash?.estimatedTcfLevel?.shortName ?? '—',
                    label: 'Niveau estimé',
                    color: AppColors.blue,
                    valueSize: 22,
                    // Un niveau qui ne porte pas sur les 4 épreuves le dit ici
                    // (parité web /profil).
                    hint: estimatedTcfLevelScopeLabel(dash),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SfSectionTitle(kProfileObjectifSection,
                flush: true, lead: true),
            SfInfoCard(
              icon: LucideIcons.target,
              title: procedure?.fullLabel ?? kProfileObjectifNone,
              meta: procedure != null
                  ? kProfileObjectifEdit
                  : kProfileObjectifNoneMeta,
              trailing: const SfChevron(),
              onTap: () =>
                  context.push(AppRoutes.targetPathFrom(AppRoutes.profile)),
            ),
            const SizedBox(height: 22),
            const SfSectionTitle(kProfileAccountSection,
                flush: true, lead: true),
            SfStack(
              pad: false,
              children: [
                _PassRow(
                  user: user,
                  subscription: sub,
                  onTap: () async {
                    await context.push(AppRoutes.manageSubscription);
                    // Filet de sécurité : achat ou résiliation qui n'aurait
                    // pas muté la signature d'accès (échéance prolongée).
                    ref.invalidate(_subscriptionStatusProvider);
                  },
                ),
                SfInfoCard(
                  icon: LucideIcons.penLine,
                  title: kProfileInfosTitle,
                  meta: user.email,
                  trailing: const SfChevron(),
                  onTap: () => context.push(AppRoutes.personalInfo),
                ),
                SfInfoCard(
                  icon: LucideIcons.bell,
                  title: kCompteNotifRowTitle,
                  meta: kCompteNotifRowSub,
                  trailing: const SfChevron(),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                // « Ma progression » ouvre l'écran de progression GLOBAL TCF
                // (D16, 2026-09-24) ; le global civique s'atteint par la carte
                // « Ma progression » du module Civique.
                SfInfoCard(
                  icon: LucideIcons.chartColumn,
                  title: kProfileProgressionTitle,
                  meta: kProfileProgressionMeta,
                  trailing: const SfChevron(),
                  onTap: () =>
                      pousserOuAller(context, AppRoutes.progressionTcf),
                ),
                SfInfoCard(
                  icon: LucideIcons.bookmark,
                  title: kFavorisTitle,
                  meta: kFavorisRowSub,
                  trailing: const SfChevron(),
                  onTap: () => context.push(AppRoutes.mesFavoris),
                ),
                SfInfoCard(
                  icon: LucideIcons.circleHelp,
                  title: kProfileHelpTitle,
                  meta: kProfileHelpMeta,
                  trailing: const SfChevron(),
                  onTap: () => context.push(AppRoutes.helpCenter),
                ),
                SfInfoCard(
                  icon: LucideIcons.info,
                  title: kProfileAboutTitle,
                  meta: kProfileAboutMeta,
                  trailing: const SfChevron(),
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
            const SizedBox(height: 22),
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
              // La version vient de l'app installée (pubspec), jamais d'une
              // chaîne recopiée : « 0.1.3+19 » ⇒ « v0.1.3 (19) ».
              child: FutureBuilder<String?>(
                future: ClientContext.appVersion(),
                builder: (context, snapshot) => Text(
                  profileVersionLabel(snapshot.data),
                  style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Le nom du pass (X12) : lu sur le statut servi, sinon sur l'accès du
  /// compte — jamais un nom deviné.
  static String _passName(AuthUser user, SubscriptionStatusResponse? sub) =>
      passAccessName(
        premium: sub?.isPremium ?? user.isPremium,
        integral: sub != null
            ? sub.moduleAccess == ModuleAccess.integral ||
                sub.moduleAccess == ModuleAccess.tcf
            : user.hasTcf,
      );

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

/// **La carte profil** (`.card.profile` de la maquette mobile) : avatar aux
/// initiales sur le dégradé du module (token), nom, « Objectif : {démarche} »,
/// puis — gardés de l'ancienne carte d'identité — l'e-mail, la pastille de
/// démarche et le nom du pass (X12). « Membre depuis » : absent, la date
/// d'inscription n'est pas servie (X11). Toute la carte et « Modifier » mènent
/// à « Mes informations ».
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.passName,
    required this.onTap,
  });

  final AuthUser user;
  final String passName;
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
    final procedure = user.targetProcedure;
    final rayon = BorderRadius.circular(AppRadii.xl);
    return Material(
      color: AppColors.white,
      borderRadius: rayon,
      child: InkWell(
        onTap: onTap,
        borderRadius: rayon,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
          decoration: BoxDecoration(
            borderRadius: rayon,
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.module(civique: false),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Text(
                  _initials,
                  style: AppFonts.display(
                    size: 26,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppFonts.display(size: 18, weight: FontWeight.w700),
              ),
              if (procedure != null) ...[
                const SizedBox(height: 4),
                Text(
                  profileObjectif(procedure.fullLabel),
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 14, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  SfBadge(passName),
                  if (procedure != null)
                    AppTag(
                      label: procedure.shortLabel,
                      icon: LucideIcons.mapPin,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kProfileEdit,
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

/// **« Mon pass »** (« Mon abonnement » de la maquette, R6) : nom du pass
/// (X12), son état et son échéance servis, puis la gestion de l'accès.
class _PassRow extends StatelessWidget {
  const _PassRow({
    required this.user,
    required this.subscription,
    required this.onTap,
  });

  final AuthUser user;
  final SubscriptionStatusResponse? subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final premium = sub?.isPremium ?? user.isPremium;
    final nom = ProfileScreen._passName(user, sub);
    final expiresAt = sub?.expiresAt ?? user.premiumEndsAt;
    final String detail;
    if (!premium) {
      detail = kProfilePassFreeMeta;
    } else if (expiresAt != null) {
      detail = profilePassUntil(_formatDate(expiresAt));
    } else {
      detail = kProfilePassActiveMeta;
    }
    return SfInfoCard(
      icon: LucideIcons.creditCard,
      title: kProfilePassTitle,
      meta: profilePassMeta(nom, detail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          premium
              ? const SfBadge(kProfilePassActive, tone: SfTone.ok, check: true)
              : const SfBadge(kProfilePassFree, tone: SfTone.muted),
          const SizedBox(width: 6),
          const SfChevron(),
        ],
      ),
      onTap: onTap,
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

/// « SejourFR · v0.1.3 (19) » depuis `0.1.3+19` ; « SejourFR » seul si la
/// plateforme ne dit rien.
String profileVersionLabel(String? raw) {
  if (raw == null || raw.isEmpty) return 'SejourFR';
  final parts = raw.split('+');
  final build = parts.length > 1 && parts[1].isNotEmpty ? ' (${parts[1]})' : '';
  return 'SejourFR · v${parts.first}$build';
}
