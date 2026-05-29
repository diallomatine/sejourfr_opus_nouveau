import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/billing_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';

/// Écran « Mon abonnement » : statut actuel, date de renouvellement, et CTA
/// de résiliation. Routing décidé côté backend selon la source :
/// - Stripe : annulation serveur, on affiche un succès et on refresh le user.
/// - Apple / Google : redirection vers la page de gestion du store
///   (`https://apps.apple.com/account/subscriptions` ou Play). Le statut
///   bascule ensuite via le webhook quand l'user confirme côté store.
final _subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusResponse>((ref) {
  return ref.watch(billingRepositoryProvider).getSubscriptionStatus();
});

class ManageSubscriptionScreen extends ConsumerStatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  ConsumerState<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState
    extends ConsumerState<ManageSubscriptionScreen> {
  bool _cancelInProgress = false;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(_subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mon abonnement',
          style: AppFonts.jakarta(
            size: 16,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(_subscriptionStatusProvider),
          ),
          data: (status) => _Body(
            status: status,
            cancelInProgress: _cancelInProgress,
            onCancel: () => _onCancelPressed(status),
          ),
        ),
      ),
    );
  }

  Future<void> _onCancelPressed(SubscriptionStatusResponse status) async {
    final confirmed = await _showConfirmDialog(status);
    if (confirmed != true) return;

    setState(() => _cancelInProgress = true);
    try {
      final res = await ref.read(billingRepositoryProvider).cancel();
      if (!mounted) return;
      if (res.isRedirect && res.redirectUrl != null) {
        await _openExternal(res.redirectUrl!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message)),
          );
        }
      } else {
        // DONE — Stripe a enregistré l'annulation. Refresh le user pour
        // que la PlanCard du profil affiche le nouvel état (autoRenew=false).
        await ref
            .read(authControllerProvider.notifier)
            .refreshSubscriptionStatus();
        ref.invalidate(_subscriptionStatusProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final api = ApiClient.toApiException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(api.message),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelInProgress = false);
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir $url'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog(SubscriptionStatusResponse status) {
    final source = status.source;
    final isRedirect = source == SubscriptionSource.apple ||
        source == SubscriptionSource.google;
    final body = isRedirect
        ? 'Vous serez redirigé vers ${_storeLabel(source)} pour résilier votre '
            'abonnement. L\'accès Premium restera ouvert jusqu\'à la date '
            'd\'expiration en cours.'
        : 'Votre accès Premium restera ouvert jusqu\'au '
            '${_formatDate(status.expiresAt)}, puis ne sera pas renouvelé. '
            'Vous pourrez réactiver l\'abonnement plus tard.';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Résilier l\'abonnement ?',
          style: AppFonts.fraunces(size: 20, weight: FontWeight.w600),
        ),
        content: Text(
          body,
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
              isRedirect ? 'Ouvrir le store' : 'Résilier',
              style: AppFonts.jakarta(
                color: AppColors.red,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _storeLabel(SubscriptionSource? source) {
    return switch (source) {
      SubscriptionSource.apple => 'l\'App Store',
      SubscriptionSource.google => 'Google Play',
      _ => 'le store',
    };
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return 'la fin de la période';
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ============================================================================
// Body
// ============================================================================

class _Body extends StatelessWidget {
  const _Body({
    required this.status,
    required this.cancelInProgress,
    required this.onCancel,
  });

  final SubscriptionStatusResponse status;
  final bool cancelInProgress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!status.isPremium) {
      return const _NotPremiumView();
    }
    // Résilié = status CANCELED côté backend. C'est posé soit par notre
    // endpoint /cancel (action explicite de l'user), soit par un webhook
    // store (DID_CHANGE_RENEWAL_STATUS Apple, RTDN Google,
    // customer.subscription.updated Stripe avec cancel_at_period_end).
    // `autoRenew=false` SEUL ne suffit PAS : les anciens abos Stripe
    // one-shot (avant lot 4 récurrent) sont ACTIVE + autoRenew=false sans
    // que l'user n'ait rien annulé.
    final isCanceled = status.status == SubscriptionStatus.canceled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _PlanHero(status: status, isCanceled: isCanceled),
        const SizedBox(height: 16),
        _InfoCard(status: status, isCanceled: isCanceled),
        const SizedBox(height: 20),
        if (!isCanceled)
          _CancelButton(
            inProgress: cancelInProgress,
            onTap: cancelInProgress ? null : onCancel,
          )
        else
          _CanceledFootnote(expiresAt: status.expiresAt),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _PlanHero extends StatelessWidget {
  const _PlanHero({required this.status, required this.isCanceled});

  final SubscriptionStatusResponse status;
  final bool isCanceled;

  @override
  Widget build(BuildContext context) {
    final planLabel = _planLabel(status);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCanceled
              ? const [AppColors.muted, AppColors.ink]
              : const [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isCanceled ? AppColors.muted : AppColors.blue)
                .withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCanceled
                    ? Icons.event_busy_rounded
                    : Icons.workspace_premium_rounded,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'PLAN ACTUEL',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.white.withValues(alpha: 0.78),
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AppTag(
                label: isCanceled ? 'Résilié' : 'Actif',
                tone: isCanceled ? TagTone.amber : TagTone.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planLabel,
            style: AppFonts.fraunces(
              size: 26,
              weight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCanceled
                ? 'Renouvellement automatique désactivé.'
                : 'Renouvellement automatique activé.',
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  String _planLabel(SubscriptionStatusResponse s) {
    if (s.moduleAccess == ModuleAccess.integral) return 'Plan Intégral';
    if (s.moduleAccess == ModuleAccess.civique) return 'Plan Civique';
    return 'Plan TCF';
  }
}

// ---------------------------------------------------------------------------
// Info card — détails (source, dates, identifiant)
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.status, required this.isCanceled});

  final SubscriptionStatusResponse status;
  final bool isCanceled;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '§ DÉTAILS',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'Géré par',
            value: _sourceLabel(status.source),
            icon: _sourceIcon(status.source),
          ),
          const _Divider(),
          _Row(
            label: isCanceled ? 'Accès jusqu\'au' : 'Prochain renouvellement',
            value: _formatDate(status.expiresAt) ?? '—',
            icon: Icons.event_rounded,
          ),
          if (status.productId != null) ...[
            const _Divider(),
            _Row(
              label: 'Référence',
              value: status.productId!,
              icon: Icons.tag_rounded,
              monospace: true,
            ),
          ],
        ],
      ),
    );
  }

  static String _sourceLabel(SubscriptionSource? s) => switch (s) {
        SubscriptionSource.stripe => 'Carte bancaire (Stripe)',
        SubscriptionSource.apple => 'App Store (Apple)',
        SubscriptionSource.google => 'Google Play',
        _ => '—',
      };

  static IconData _sourceIcon(SubscriptionSource? s) => switch (s) {
        SubscriptionSource.stripe => Icons.credit_card_rounded,
        SubscriptionSource.apple => Icons.apple_rounded,
        SubscriptionSource.google => Icons.shop_rounded,
        _ => Icons.help_outline_rounded,
      };

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: monospace
                  ? AppFonts.mono(
                      size: 11.5,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    )
                  : AppFonts.jakarta(
                      size: 13.5,
                      color: AppColors.ink,
                      weight: FontWeight.w700,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: AppColors.line,
      );
}

// ---------------------------------------------------------------------------
// CTA résilier
// ---------------------------------------------------------------------------

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.inProgress, required this.onTap});

  final bool inProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (inProgress)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(AppColors.red),
                  ),
                )
              else
                const Icon(Icons.cancel_outlined,
                    size: 18, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                inProgress ? 'Résiliation…' : 'Résilier mon abonnement',
                style: AppFonts.jakarta(
                  size: 14.5,
                  weight: FontWeight.w800,
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

class _CanceledFootnote extends StatelessWidget {
  const _CanceledFootnote({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.amber.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              expiresAt == null
                  ? 'Votre abonnement est résilié. Vous conservez l\'accès Premium '
                      'jusqu\'à la fin de la période en cours.'
                  : 'Votre abonnement est résilié. Vous conservez l\'accès Premium '
                      'jusqu\'au ${_formatLong(expiresAt!)}.',
              style: AppFonts.jakarta(
                size: 12.5,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatLong(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// États dégradés
// ---------------------------------------------------------------------------

class _NotPremiumView extends StatelessWidget {
  const _NotPremiumView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 36, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Aucun abonnement actif',
            style: AppFonts.fraunces(size: 20, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous êtes sur le plan gratuit. Souscrivez depuis un module pour '
            'débloquer l\'accès complet.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 32, color: AppColors.red),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 13.5, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
