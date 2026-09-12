import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/retour.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cecrl_track.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import 'tcf_diagnostic_labels.dart';

/// T12 — le résultat du diagnostic TCF 4 épreuves.
///
/// Ordre des blocs, imposé par la maquette :
/// 1. la carte hero — niveau global, objectif, rail, phrase d'analyse ;
/// 2. « Votre niveau par épreuve » — les quatre, dans l'ordre servi ;
/// 3. la progression, quand il y a un diagnostic précédent à comparer ;
/// 4. « Ce qui vous empêche aujourd'hui d'atteindre {cible} » — trois priorités ;
/// 5. « Vous n'avez pas besoin de tout retravailler » ;
/// 6. « Votre plan {cible} est prêt » — l'aperçu, puis l'ouverture du plan.
///
/// 🛑 **Aucun résultat n'est masqué derrière le paywall.** Le paywall porte sur
/// le plan, pas sur le constat : le DTO ne porte aucun `locked`, et cet écran
/// n'en invente pas.
///
/// 🛑 **Une épreuve non évaluée est NOMMÉE, pas escamotée.** `niveau == null`
/// signifie « on n'a pas mesuré », jamais « A1 » : la ligne perd son palier et
/// son état, elle ne gagne pas un verdict que personne n'a rendu.
class TcfDiagnosticResultScreen extends ConsumerStatefulWidget {
  const TcfDiagnosticResultScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TcfDiagnosticResultScreen> createState() =>
      _TcfDiagnosticResultScreenState();
}

class _TcfDiagnosticResultScreenState
    extends ConsumerState<TcfDiagnosticResultScreen> {
  TcfDiagnosticResultDto? _resultat;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(tcfDiagnosticRepositoryProvider)
          .readResult(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.toApiException(e).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: kTcfDiagnosticResultTitle,
              sub: kTcfDiagnosticResultKicker,
              onBack: () => retourOuRepli(context, repli: AppRoutes.plan),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfInsight(error),
            const SizedBox(height: 16),
            SfButton(
              label: 'Réessayer',
              variant: SfButtonVariant.line,
              icon: null,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final r = _resultat!;
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 32),
      children: [
        Padding(
          padding: sfGutter,
          child: Align(
            alignment: Alignment.centerLeft,
            child: const AppTag(
              label: kTcfDiagnosticResultBadge,
              tone: TagTone.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(padding: sfGutter, child: _HeroCard(resultat: r)),
        SfSection(
          title: kTcfDiagnosticEpreuvesTitle,
          child: SfStack(
            children: [
              // 🛑 **Ordre servi**, jamais retrié : le serveur envoie les quatre
              // épreuves, l'écran les rend dans cet ordre.
              for (final e in r.epreuves) _EpreuveRow(niveau: e, resultat: r),
            ],
          ),
        ),
        // La réévaluation : absent au premier diagnostic (`progression` null).
        if (r.progression case final progression?)
          SfSection(
            child: SfStack(
              children: [_ProgressionCard(progression: progression)],
            ),
          ),
        if (r.priorites.isNotEmpty)
          SfSection(
            title: blocageTitle(r.cible),
            child: SfStack(
              children: [
                for (final p in r.priorites)
                  SfPrio(
                    rank: p.rang,
                    tag: prioriteTag(p.rang),
                    title: prioriteIntitule(
                      epreuvePresentation(p.epreuve).label,
                      p.taskCode,
                    ),
                    // 🛑 Phrase gelée côté front, indexée par la tâche. Un
                    // couple inconnu ⇒ pas de phrase, jamais une phrase
                    // générique.
                    text: prioritePhrase(p.epreuve, p.taskCode),
                  ),
              ],
            ),
          ),
        SfSection(
          child: SfStack(
            children: [
              SfNoteCard(
                icon: LucideIcons.check,
                variant: SfCardVariant.ok,
                title: kTcfDiagnosticRassuranceTitle,
                child: SfTiny(rassuranceText(r.cible)),
              ),
            ],
          ),
        ),
        // On ne promet pas un plan vide : sans priorité servie, pas d'aperçu.
        if (r.priorites.isNotEmpty)
          SfSection(
            title: planPretTitle(r.cible),
            child: SfStack(
              children: [
                SfCard(child: _MiniPlan(resultat: r)),
                SfButton(
                  label: r.cible == null
                      ? kTcfDiagnosticPlanCta
                      : '$kTcfDiagnosticPlanCta ${r.cible!.wire}',
                  onPressed: () => context.go(AppRoutes.plan),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: sfGutter,
          child: Center(child: SfTiny(kTcfDiagnosticEstimationNote)),
        ),
      ],
    );
  }
}

/// La carte de tête : le niveau global et ce qu'il reste à franchir.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.resultat});

  final TcfDiagnosticResultDto resultat;

  @override
  Widget build(BuildContext context) {
    final niveau = resultat.niveauGlobal;
    final track = cecrlTrack(niveau, resultat.cible);
    final analyse = analyseGlobale(
      niveau,
      resultat.cible,
      resultat.dejaAuNiveau,
      resultat.priorites,
    );

    return SfCard(
      variant: SfCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SfLabel(kTcfDiagnosticNiveauLabel),
          const SizedBox(height: 8),
          if (niveau != null)
            SfLevel(niveau.shortName)
          else
            const AppTag(label: kNiveauNonEvalue, tone: TagTone.neutral),
          if (resultat.cible case final cible?) ...[
            const SizedBox(height: 12),
            SfGoalLine(prefix: kTcfDiagnosticGoalPrefix, goal: cible.wire),
          ],
          if (track != null)
            SfLevelTrack(
              levels: track.levels,
              currentIndex: track.currentIndex,
              goalIndex: track.goalIndex,
              youLabel: 'Actuel',
            ),
          if (analyse != null) ...[
            const SizedBox(height: 16),
            SfInsight(analyse),
          ],
        ],
      ),
    );
  }
}

/// Une ligne du tableau des niveaux.
class _EpreuveRow extends StatelessWidget {
  const _EpreuveRow({required this.niveau, required this.resultat});

  final TcfDiagnosticEpreuveNiveau niveau;
  final TcfDiagnosticResultDto resultat;

  @override
  Widget build(BuildContext context) {
    final presentation = epreuvePresentation(niveau.epreuve);
    // 🛑 L'état se **lit** sur `dejaAuNiveau` et sur le rang 1 des priorités,
    // servis par le serveur. Aucun palier n'est comparé ici, et l'épreuve non
    // mesurée n'en reçoit aucun.
    final mention = epreuveMention(
      niveau.epreuve,
      niveau.niveau,
      resultat.dejaAuNiveau,
      resultat.priorites,
    );
    return SfExamRow(
      icon: presentation.icon,
      title: presentation.label,
      subtitle: niveau.niveau == null ? kTcfDiagnosticNonEvalueeSub : null,
      level: niveau.niveau?.shortName,
      status: mention?.label,
      tone: mention == null ? null : _sfTone(mention.tone),
    );
  }
}

/// L'aperçu numéroté du plan à venir, et ce que les réponses ont fait remonter.
class _MiniPlan extends StatelessWidget {
  const _MiniPlan({required this.resultat});

  final TcfDiagnosticResultDto resultat;

  @override
  Widget build(BuildContext context) {
    final ligne = competencesCibleesLine(resultat.tachesSousLaCible);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SfMiniPlan(
          rows: [
            for (final p in resultat.priorites)
              SfMiniRow(
                label: prioriteCourte(epreuveCourte(p.epreuve), p.taskCode),
                pill: prioritePastille(p.rang).label,
                tone: _sfTone(prioritePastille(p.rang).tone),
              ),
          ],
        ),
        if (ligne != null) ...[
          const SizedBox(height: 10),
          SfTiny(ligne),
        ],
      ],
    );
  }
}

/// Ce qui a bougé depuis le diagnostic précédent.
///
/// 🛑 **Sobre.** C'est une mesure, pas une célébration, et elle doit rester
/// lisible quand elle baisse. `inconnue` n'affiche **rien** de comparatif :
/// « = » se lirait « vous avez tenu votre niveau » alors que rien n'a été
/// comparé.
class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({required this.progression});

  final TcfDiagnosticProgressionDto progression;

  @override
  Widget build(BuildContext context) {
    final quand = progression.previousCompletedAt;
    final avant = progression.previousNiveauGlobal;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progressionTitle(progression.niveauGlobal),
            style: AppFonts.display(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SfTiny(
            'Diagnostic du ${quand == null ? 'précédent' : formatJourCourt(quand)}'
            '${avant == null ? '' : ' — niveau estimé ${avant.wire}'}',
          ),
          const SizedBox(height: 10),
          for (final e in progression.epreuves)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    epreuvePresentation(e.epreuve).icon,
                    size: 18,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      epreuvePresentation(e.epreuve).label,
                      style: AppFonts.ui(size: 13.5),
                    ),
                  ),
                  Text(
                    evolutionLabel(e.evolution, e.avant) ?? kNiveauNonEvalue,
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: e.evolution == NiveauEvolution.hausse
                          ? AppColors.blue
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Le ton du kit pour une mention servie. Les deux échelles disent la même
/// chose ; l'enum du fichier de libellés reste le miroir mot pour mot du web,
/// et la traduction vers le kit vit ici, une seule fois.
SfTone _sfTone(EpreuveMentionTone tone) => switch (tone) {
      EpreuveMentionTone.ok => SfTone.ok,
      EpreuveMentionTone.warn => SfTone.warn,
      EpreuveMentionTone.hot => SfTone.hot,
    };
