import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/attempt_summary.dart';
import '../../core/models/civic_diagnostic_models.dart';
import '../../core/models/preparation_labels.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../home/widgets/home_blocks.dart';
import '../module_detail/civique_hub_data.dart';
import 'progres_labels.dart';

/// **« Où j'en suis sur ce thème ? »** — l'écran ouvert par « Voir mes
/// résultats » d'une ligne de thème civique de l'Accueil.
///
/// 🛑 **Ce n'est pas la grille des examens blancs.** `CiviqueThemeExamsScreen`
/// est là où l'on **passe** un examen ; celui-ci est là où l'on **lit** ses
/// résultats — d'où le lien de pied qui mène à l'autre, et pas l'inverse.
///
/// 🛑 **Rien n'est classé ici, et le civique n'a AUCUN palier CECRL.** L'état du
/// thème arrive **servi** (`CivicThemeState`, via `progressProvider` — le même
/// que l'Accueil, donc **aucun appel de plus**), et chaque examen porte son
/// score, son total et son seuil **servis** avec lui
/// (`GET /api/me/attempts?type=MOCK_EXAM&module=CIVIQUE&themeId=…`). Une absence
/// de mesure se **dit** : jamais un `0 / 20`, jamais un palier inventé.
///
/// 🛑 **Miroir de `ThemeHistoriqueView` côté web**, bloc pour bloc.
class ThemeHistoriqueScreen extends ConsumerStatefulWidget {
  const ThemeHistoriqueScreen({super.key, required this.themeId});

  final String themeId;

  @override
  ConsumerState<ThemeHistoriqueScreen> createState() =>
      _ThemeHistoriqueScreenState();
}

class _ThemeHistoriqueScreenState extends ConsumerState<ThemeHistoriqueScreen> {
  /// L'index **dans la liste servie** (la plus récente d'abord).
  int? _choisi;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(civiqueThemeExamsHistoryProvider(widget.themeId));
    // 🛑 **L'état du thème est un CONFORT** : son absence laisse la liste
    // entière, elle ne doit jamais empêcher de lire ses résultats.
    final progres = ref.watch(progressProvider).valueOrNull;
    final theme = progres?.civique.themes
        .where((t) => t.themeId == widget.themeId)
        .firstOrNull;

    final examens = _mesurables(async.valueOrNull ?? const []);
    // 🛑 **L'échelle et les points viennent de `civiqueThemeCourbe`**, l'unique
    // autorité : le maximum et le seuil sont ceux des examens SERVIS, jamais
    // les 20 / 16 du format recopiés dans un écran.
    final courbe = civiqueThemeCourbe([
      for (final a in examens)
        ThemeMesure(
          date: a.finishedAt,
          score: a.score!,
          total: a.totalQuestions,
          seuil: a.passThreshold,
        ),
    ]);
    final points = courbe.points;
    final dernier = examens.isEmpty ? null : examens.first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            SfTop(
              onBack: () => retourOuRepli(context, repli: '/'),
              kicker: theme?.label ?? kCiviqueLabel,
              title: kThemeResultatsTitle,
            ),
            SfSection(
              flush: true,
              child: SfStack(
                pad: false,
                children: [
                  // 🛑 **Le dernier score et le seuil sont SERVIS**, et « — »
                  // est le rendu d'une absence de mesure : jamais un « 0 ».
                  SfResultHero(
                    label: kThemeResultatsHeroLabel,
                    level: dernier == null
                        ? '—'
                        : themeResultatsScore(
                            dernier.score!, dernier.totalQuestions),
                    goalLabel: kThemeResultatsSeuilLabel,
                    goal: dernier?.passThreshold == null
                        ? null
                        : themeResultatsScore(
                            dernier!.passThreshold!, dernier.totalQuestions),
                    // 🛑 **L'état arrive servi**, avec son libellé gelé :
                    // `NON_EVALUE` se dit « À évaluer », jamais « faible ».
                    trend: theme == null
                        ? null
                        : theme.etat == CivicThemeState.nonEvalue
                            ? kNonMesureLabel
                            : theme.etat.label,
                    note: kThemeResultatsLead,
                  ),
                  // 🛑 **Pas de courbe sans point** : un panneau vide
                  // raconterait une absence comme un incident. Un seul examen
                  // rend un seul point — la courbe reste honnête.
                  if (points.isNotEmpty)
                    SfCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SfPanelHead(
                            title: kThemeResultatsCourbeTitle,
                            sub: points.length > 1
                                ? kThemeResultatsCourbeSub
                                : kThemeResultatsCourbeUnPoint,
                          ),
                          const SizedBox(height: 12),
                          SfLevelChart(
                            rungs: courbe.rungs,
                            points: points,
                            activeIndex: _choisi == null
                                ? points.length - 1
                                : examens.length - 1 - _choisi!,
                            onSelect: (i) => setState(
                                () => _choisi = examens.length - 1 - i),
                          ),
                        ],
                      ),
                    ),
                  SfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SfPanelHead(
                          title: kThemeResultatsListeTitle,
                          sub: examens.isEmpty
                              ? null
                              : themeResultatsCountLabel(examens.length),
                        ),
                        const SizedBox(height: 12),
                        async.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          ),
                          // 🛑 Un échec de chargement n'est pas « aucun
                          // examen » : on ne range pas une panne dans le
                          // verdict le plus bas.
                          error: (_, __) => const SfTiny(kThemeResultatsErreur),
                          data: (_) => examens.isEmpty
                              ? const _Vide()
                              : _Liste(
                                  examens: examens,
                                  choisi: _choisi,
                                  onToggle: (i) => setState(
                                      () => _choisi = _choisi == i ? null : i),
                                ),
                        ),
                        const SizedBox(height: 12),
                        SfInfoNote(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: kThemeResultatsPorteeTitle,
                                  style: AppFonts.ui(
                                    size: 11.5,
                                    weight: FontWeight.w800,
                                    color: AppColors.amberDark,
                                    height: 1.45,
                                  ),
                                ),
                                TextSpan(
                                  text: kThemeResultatsPorteeText,
                                  style: AppFonts.ui(
                                    size: 11.5,
                                    color: AppColors.amberDark,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          // 🛑 **La grille des examens blancs**, adresse
                          // déclarée une seule fois
                          // (`AppRoutes.civiqueThemeExamsPath`) : c'est là qu'on
                          // PASSE un examen, pas là qu'on lit ses résultats.
                          child: HomeLink(
                            label: kThemeResultatsExamensLabel,
                            onTap: () => context.push(
                              AppRoutes.civiqueThemeExamsPath(widget.themeId),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Les examens qui portent réellement une mesure, dans l'**ordre servi**.
  ///
  /// 🛑 Un examen non terminé, sans score ou sans total n'est pas un résultat :
  /// il ne compte ni sur la courbe, ni dans « N examens blancs ».
  List<AttemptSummary> _mesurables(List<AttemptSummary> servis) => [
        for (final a in servis)
          if (a.isFinished && a.score != null && a.totalQuestions > 0) a,
      ];
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kThemeResultatsVide,
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const SfTiny(kThemeResultatsVideAide),
      ],
    );
  }
}

/// La liste des examens blancs du thème.
///
/// 🛑 **Aucun filtre** : les lignes sont toutes de la même nature. Une rangée
/// d'onglets au-dessus d'une liste homogène ne filtre rien.
class _Liste extends StatelessWidget {
  const _Liste({
    required this.examens,
    required this.choisi,
    required this.onToggle,
  });

  final List<AttemptSummary> examens;
  final int? choisi;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < examens.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Ligne(
            examen: examens[i],
            open: choisi == i,
            onToggle: () => onToggle(i),
          ),
        ],
      ],
    );
  }
}

/// Un examen : son rang de créneau, sa date, son score, et son détail.
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.examen,
    required this.open,
    required this.onToggle,
  });

  final AttemptSummary examen;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final seuil = examen.passThreshold;
    final verdict = themeResultatsVerdict(examen.score!, seuil);
    return SfHistoryRow(
      icon: LucideIcons.fileText,
      title: themeResultatsExamenTitle(examen.slotNumber),
      date: jourLong(examen.finishedAt),
      level: themeResultatsScore(examen.score!, examen.totalQuestions),
      open: open,
      onToggle: onToggle,
      // 🛑 **Deux nombres servis et leur comparaison**, jamais un état
      // pédagogique : « au-dessus du seuil » n'est pas un palier. Sans seuil
      // servi, on dit l'absence plutôt que d'inventer la barre.
      detail: seuil == null
          ? const SfTiny(kThemeResultatsSansSeuil)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: verdict,
                    style: AppFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),
                  TextSpan(
                    text: ' '
                        '${themeResultatsSeuilDetail(seuil, examen.totalQuestions)}',
                    style: AppFonts.ui(
                      size: 11.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
