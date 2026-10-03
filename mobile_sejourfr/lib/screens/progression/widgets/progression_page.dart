import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../progression_labels.dart';

/// **Le squelette commun des quatre écrans de progression** : la barre du haut
/// (retour + « Progression » + le parcours), puis le contenu d'une lecture
/// servie, avec tiré-pour-rafraîchir.
///
/// 🛑 **Le retour vit dans la barre du haut** (demande du propriétaire,
/// 2026-09-28) : plus de rangée « retour + examen blanc » dans la page. La
/// barre reste dans tous les états — chargement et erreur compris : c'est la
/// porte de sortie. [onBack] remonte l'historique (`retourOuRepli`). Miroir
/// web : la flèche d'`AppTopBar`, posée par `ProgressionFrame`.
///
/// 🛑 **Un échec n'est pas « aucun examen »** : on ne range pas une panne dans
/// l'état vide.
class ProgressionPage<T> extends StatelessWidget {
  const ProgressionPage({
    super.key,
    required this.async,
    required this.barSub,
    required this.onBack,
    required this.onRefresh,
    required this.children,
    this.notFound,
    this.entete = const [],
    this.lienRetour,
  });

  final AsyncValue<T> async;
  /// Le parcours sous le titre de la barre (« TCF IRN », « Examen civique »).
  final String barSub;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final List<Widget> Function(T data) children;

  /// Le message d'un **404** servi (thème inconnu) — une absence, pas une
  /// panne. `null` = le message d'échec générique.
  final String? notFound;

  /// Ce qui ouvre la page **dans tous les états** (chargement et erreur
  /// compris) : l'intro des deux écrans globaux. Vide ailleurs.
  final List<Widget> entete;

  /// **Le lien retour de la maquette** (« ‹ TCF IRN », « ‹ Examen civique »),
  /// à la couleur du module, à la place de la barre du haut — sur les deux
  /// écrans GLOBAUX, ouverts depuis l'écran de module (Navigation v2). Son
  /// geste est [onBack]. `null` ⇒ la barre du haut habituelle.
  final ({String label, bool civique})? lienRetour;

  @override
  Widget build(BuildContext context) {
    final data = async.valueOrNull;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lienRetour case final lien?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SfBackLink(
                  civique: lien.civique,
                  label: lien.label,
                  onTap: onBack,
                ),
              )
            else
              ScreenHeader(
                title: kProgressionBarTitle,
                sub: barSub,
                onBack: onBack,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 42),
                  children: [
                    ...entete,
                    ...corps,
                  ],
                ),
              ),
            ),
          ],
        ),
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
