import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/api/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paywall_sheet.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../progression_labels.dart';

/// **Le geste du CTA** « Nouvel examen blanc » : la GRILLE d'examens, jamais un
/// démarrage direct (la grille sert ses propres verrous de créneau).
///
/// 🛑 **D20 : seul `cta.locked` servi ferme la porte**, et elle s'ouvre sur le
/// paywall — le parcours d'abonnement unique, compté comme un vrai clic sur un
/// appel à l'examen blanc. Aucun verrou n'est déduit ici.
void ouvrirProgressionCta(
  BuildContext context,
  WidgetRef ref, {
  required bool locked,
  required String grille,
}) {
  if (locked) {
    showPaywallSheet(
      context,
      ref: ref,
      ctaLocation: AnalyticsCtaLocation.mockExam,
    );
    return;
  }
  context.push(grille);
}

/// **Le retour d'un écran d'épreuve ou de thème** — « Progression globale » /
/// « Examen civique » : l'écran global du module. Venu de lui, on dépile ;
/// venu d'ailleurs (l'Accueil), on l'ouvre à la place de celui-ci — le retour
/// suivant ramène alors là d'où l'on venait. Miroir du lien de retour du web.
void retourVersGlobal(
  BuildContext context, {
  required bool depuisGlobal,
  required String global,
}) {
  if (depuisGlobal && context.canPop()) {
    context.pop();
    return;
  }
  context.pushReplacement(global);
}

/// Le CTA de la barre haute, **servi** : son libellé, son verrou (`cta.locked`,
/// D20) et son geste.
typedef ProgressionCta = ({String label, bool locked, VoidCallback onTap});

/// **Le squelette commun des quatre écrans de progression** : la barre haute,
/// puis le contenu d'une lecture servie, avec tiré-pour-rafraîchir.
///
/// 🛑 **La barre haute reste dans tous les états** — chargement et erreur
/// compris : c'est la porte de sortie. Son CTA, lui, n'apparaît qu'une fois la
/// lecture arrivée, parce que son verrou vient d'elle.
///
/// 🛑 **Un échec n'est pas « aucun examen »** : on ne range pas une panne dans
/// l'état vide.
class ProgressionPage<T> extends StatelessWidget {
  const ProgressionPage({
    super.key,
    required this.async,
    required this.backLabel,
    required this.onBack,
    required this.onRefresh,
    required this.children,
    this.cta,
    this.notFound,
    this.entete = const [],
  });

  final AsyncValue<T> async;
  final String backLabel;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final List<Widget> Function(T data) children;
  final ProgressionCta Function(T data)? cta;

  /// Le message d'un **404** servi (thème inconnu) — une absence, pas une
  /// panne. `null` = le message d'échec générique.
  final String? notFound;

  /// Ce qui suit la barre haute **dans tous les états** (chargement et erreur
  /// compris) : l'intro et la bascule des deux écrans globaux — la bascule est
  /// une navigation, pas un résultat. Vide ailleurs.
  final List<Widget> entete;

  @override
  Widget build(BuildContext context) {
    final data = async.valueOrNull;
    final bouton = data == null ? null : cta?.call(data);
    final List<Widget> corps;
    if (data != null) {
      corps = children(data);
    } else if (async.hasError) {
      final introuvable =
          notFound != null && ApiClient.toApiException(async.error!).isNotFound;
      corps = [
        _Erreur(
          message: introuvable ? notFound! : kProgressionError,
          onRetry: introuvable ? null : onRefresh,
        ),
      ];
    } else {
      corps = const [_Chargement()];
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 42),
            children: [
              SfProgressTopbar(
                backLabel: backLabel,
                onBack: onBack,
                ctaLabel: bouton?.label,
                ctaLocked: bouton?.locked ?? false,
                onCta: bouton?.onTap,
              ),
              ...entete,
              ...corps,
            ],
          ),
        ),
      ),
    );
  }
}

/// **La bascule TCF IRN / Examen civique** des deux écrans globaux, posée sous
/// l'intro comme sur le Plan et l'Accueil — le MÊME toggle (`SegmentedTabs` +
/// `parcoursSegments`), pas une copie. Miroir web : `ModuleToggle` du kit dans
/// `ProgressionFrame`.
///
/// 🛑 **La route reste l'unique autorité du choix** : basculer remplace l'écran
/// global par celui de l'autre module (`/progression/tcf` ⇄
/// `/progression/civique`), sans `?tous=true` — le retour mène toujours là
/// d'où l'on venait. Les écrans d'épreuve et de thème ne la portent pas.
class ProgressionBascule extends StatelessWidget {
  const ProgressionBascule({super.key, required this.civique});

  final bool civique;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: SegmentedTabs<bool>(
        tabs: parcoursSegments(tcf: false, civique: true),
        value: civique,
        onChanged: (v) {
          if (v == civique) return;
          context.pushReplacement(
            v ? AppRoutes.progressionCivique : AppRoutes.progressionTcf,
          );
        },
      ),
    );
  }
}

class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
      child: SfStack(
        pad: false,
        children: [
          SfInfoNote(child: Text(message)),
          if (onRetry != null)
            SfButton(
              label: kProgressionRetry,
              variant: SfButtonVariant.line,
              icon: null,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

/// Les blocs d'un écran, en gouttière, séparés par l'écart des maquettes.
class ProgressionBlocs extends StatelessWidget {
  const ProgressionBlocs({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: sfGutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// **Un panneau** (la courbe, la liste des examens) : la carte du kit, sa tête,
/// puis son contenu — la même composition que le web (`Card` + `PanelHead`).
class ProgressionPanneau extends StatelessWidget {
  const ProgressionPanneau({
    super.key,
    required this.title,
    required this.children,
    this.sub,
  });

  final String title;
  final String? sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfPanelHead(title: title, sub: sub),
          for (final enfant in children) ...[
            const SizedBox(height: 14),
            enfant,
          ],
        ],
      ),
    );
  }
}

/// Le lien d'un panneau (« Tous mes examens blancs → »), centré.
class ProgressionLien extends StatelessWidget {
  const ProgressionLien({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 13.5,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
