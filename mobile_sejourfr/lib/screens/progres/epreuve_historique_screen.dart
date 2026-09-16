import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/epreuve_historique_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../home/widgets/home_blocks.dart';

/// Les dernières évaluations qualifiantes d'une épreuve.
///
/// 🛑 **`autoDispose` et non gardé en vie** : c'est un détail qu'on ouvre, pas
/// une source d'écran d'accueil. Le garder en cache retiendrait un historique
/// périmé après un examen blanc passé entre-temps.
final epreuveHistoriqueProvider = FutureProvider.autoDispose
    .family<EpreuveHistorique, EpreuveType>((ref, epreuve) {
  return ref.watch(progressRepositoryProvider).historique(epreuve);
});

const String kHistoriqueTitle = 'Vos résultats';

/// 🛑 Une absence de mesure n'est pas une erreur, et se dit comme telle.
const String kHistoriqueVide = 'Aucune évaluation qualifiante pour l\'instant.';
const String kHistoriqueVideAide =
    'Un examen blanc, une épreuve passée seule ou un diagnostic apparaîtront '
    'ici dès qu\'ils auront été corrigés.';

/// Ce que la liste contient, dit au candidat plutôt que deviné par lui.
///
/// ⚠️ **Formulée pour rester vraie même quand la liste est vide.** « Les
/// évaluations qui déterminent votre niveau » était faux en EE/EO : le profil y
/// compte aussi l'entraînement libre, que cette page ne montre pas (arbitrage
/// ouvert, cf. `EpreuveHistoriqueService`). On dit donc ce que la liste
/// **contient**, pas ce qu'elle prétend expliquer.
const String kHistoriqueLead =
    'Vos épreuves complètes et vos diagnostics sur cette épreuve. '
    'Vos entraînements libres et vos petits sujets n\'y figurent pas.';

const String kHistoriqueErreur =
    'Vos résultats n\'ont pas pu être chargés. Réessayez dans un instant.';

/// Le lien vers le hub des historiques. 🛑 **Miroir du web**, où la même carte
/// porte la même sortie : cet écran ne montre qu'UNE épreuve, et il faut
/// pouvoir rejoindre le reste sans repasser par l'Accueil.
const String kHistoriqueTousLabel = 'Tous mes résultats';

/// **« D'où sort mon niveau ? »** — l'écran ouvert depuis une carte d'épreuve
/// de l'Accueil.
///
/// 🛑 **Ce n'est pas une seconde liste d'historique.** `/historiques` liste
/// **toutes** les sessions, entraînements compris ; celui-ci ne montre que les
/// **évaluations qualifiantes** de UNE épreuve — exactement celles qui ont
/// produit le palier affiché sur la carte. C'est la seule page qui répond à
/// « pourquoi ce niveau ? », et elle n'a pas d'équivalent.
///
/// 🛑 **Rien n'est dérivé ici** : date, provenance et palier sont **servis**
/// (`GET /api/me/progress/tcf/{epreuve}/historique`).
class EpreuveHistoriqueScreen extends ConsumerWidget {
  const EpreuveHistoriqueScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(epreuveHistoriqueProvider(epreuve));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              onBack: () => retourOuRepli(context, repli: '/'),
              kicker: epreuve.displayLabel,
              title: kHistoriqueTitle,
            ),
            SfSection(
              flush: true,
              child: SfCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SfTiny(kHistoriqueLead),
                    const SizedBox(height: 12),
                    async.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      ),
                      // 🛑 Un échec de chargement n'est pas « aucune
                      // évaluation » : on ne range pas une panne dans le
                      // verdict le plus bas.
                      error: (_, __) => const SfTiny(kHistoriqueErreur),
                      data: (historique) => historique.evaluations.isEmpty
                          ? const _Vide()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final e in historique.evaluations)
                                  _Ligne(evaluation: e),
                              ],
                            ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: HomeLink(
                        label: kHistoriqueTousLabel,
                        onTap: () => context.push(AppRoutes.historiques),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kHistoriqueVide,
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const SfTiny(kHistoriqueVideAide),
      ],
    );
  }
}

/// Une évaluation : sa provenance, sa date, son palier.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.evaluation});

  final EvaluationQualifiante evaluation;

  /// « 14 sept. 2026 ». `null` quand le serveur n'a pas de date — on n'en
  /// invente pas.
  String? get _date {
    final quand = evaluation.mesureA;
    if (quand == null) return null;
    final local = quand.toLocal();
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${local.day} ${mois[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evaluation.source.label,
                  style: AppFonts.ui(size: 14, weight: FontWeight.w700),
                ),
                if (date != null) ...[
                  const SizedBox(height: 1),
                  SfTiny(date),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            evaluation.niveau.shortName,
            style: AppFonts.label(size: 13, color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}
