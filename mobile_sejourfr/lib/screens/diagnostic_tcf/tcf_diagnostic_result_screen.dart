import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/tcf_diagnostic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import 'tcf_diagnostic_labels.dart';

/// T12 — le résultat du diagnostic TCF 4 épreuves (`10_` §4.5).
///
/// Ordre des blocs, imposé par la spec : niveau global → niveau par épreuve →
/// ce qui bloque → rassurance → déjà au niveau → plan.
///
/// 🛑 **Aucun résultat n'est masqué derrière le paywall.** « Le paywall porte
/// sur le plan, pas sur le constat » : le DTO ne porte aucun `locked`, et cet
/// écran n'en invente pas.
///
/// 🛑 **Une épreuve non évaluée est NOMMÉE, pas escamotée.** `niveau == null`
/// signifie « on n'a pas mesuré », jamais « A1 ».
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
              title: 'Mon diagnostic',
              sub: kTcfDiagnosticTitle,
              onBack: () => context.pop(),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 14, color: AppColors.ink)),
            const SizedBox(height: 16),
            AppButton(
              label: 'Réessayer',
              onPressed: _load,
              variant: AppButtonVariant.outline,
              fullWidth: false,
            ),
          ],
        ),
      );
    }

    final r = _resultat!;
    final nonEvaluees =
        r.epreuves.where((e) => e.niveau == null).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 1 — le niveau. L'élément dominant.
        AppCard(
          color: AppColors.blueLight,
          child: Column(
            children: [
              Text('VOTRE NIVEAU ESTIMÉ',
                  style: AppFonts.label(size: 11, color: AppColors.blueDark)),
              const SizedBox(height: 6),
              Text(
                r.niveauGlobal?.shortName ?? '—',
                style: AppFonts.display(size: 48, color: AppColors.blue),
              ),
              if (r.cible != null) ...[
                const SizedBox(height: 4),
                Text('Objectif : ${r.cible!.wire}',
                    style: AppFonts.ui(size: 14, color: AppColors.ink)),
              ],
              // Une épreuve manquante se dit, elle ne se devine pas.
              if (nonEvaluees.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${nonEvaluees.map((e) => epreuvePresentation(e.epreuve).label).join(', ')} : '
                  '${kNiveauNonEvalue.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 12, color: AppColors.blueDark),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1 bis — ce qui a bougé depuis le diagnostic précédent (L7).
        // 🛑 Absent au premier diagnostic : `progression` vaut alors `null`, et
        // on n'affiche pas un bloc vide.
        if (r.progression != null) ...[
          _ProgressionCard(progression: r.progression!),
          const SizedBox(height: 16),
        ],

        // 2 — le niveau par épreuve.
        Text('Votre niveau par épreuve',
            style: AppFonts.display(size: 18, color: AppColors.ink)),
        const SizedBox(height: 8),
        for (final e in r.epreuves) ...[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(epreuvePresentation(e.epreuve).icon,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(epreuvePresentation(e.epreuve).label,
                      style: AppFonts.ui(size: 14, color: AppColors.ink)),
                ),
                Text(
                  e.niveau == null ? kNiveauNonEvalue : e.niveau!.shortName,
                  style: AppFonts.ui(
                    size: e.niveau == null ? 12 : 14,
                    weight: FontWeight.w700,
                    // Non évaluée : atténué, jamais alarmant — ce n'est pas un échec.
                    color: e.niveau == null ? AppColors.inkFaint : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 3 — ce qui bloque. Le bloc de conversion.
        if (r.priorites.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(blocageTitle(r.cible),
              style: AppFonts.display(size: 18, color: AppColors.ink)),
          const SizedBox(height: 8),
          for (final p in r.priorites) ...[
            _PrioriteCard(priorite: p, cible: r.cible),
            const SizedBox(height: 8),
          ],
        ],

        // 4 — rassurance.
        const SizedBox(height: 8),
        AppCard(
          color: AppColors.surface2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kTcfDiagnosticRassuranceTitle,
                  style: AppFonts.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(rassuranceText(r.cible),
                  style: AppFonts.ui(size: 13, color: AppColors.inkSoft)),
            ],
          ),
        ),

        // 5 — déjà au niveau. Visuellement secondaire.
        if (r.dejaAuNiveau.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(kTcfDiagnosticDejaTitle.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 6),
          for (final e in r.dejaAuNiveau)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '✓ ${epreuvePresentation(e.epreuve).label}'
                '${e.niveau != null ? ' — ${e.niveau!.shortName}' : ''}',
                style: AppFonts.ui(size: 13, color: AppColors.green),
              ),
            ),
        ],

        // 6 — le plan.
        const SizedBox(height: 20),
        AppButton(
          label: r.cible == null
              ? kTcfDiagnosticPlanCta
              : '$kTcfDiagnosticPlanCta ${r.cible!.wire}',
          onPressed: () => context.go('/plan'),
        ),
        const SizedBox(height: 14),
        Text(kTcfDiagnosticEstimationNote,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
      ],
    );
  }
}

/// Le bloc de progression (L7) : d'où à où, épreuve par épreuve.
///
/// 🛑 **Sobre.** C'est une mesure, pas une célébration, et il doit rester
/// lisible quand elle baisse.
class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({required this.progression});

  final TcfDiagnosticProgressionDto progression;

  @override
  Widget build(BuildContext context) {
    final quand = progression.previousCompletedAt;
    final avant = progression.previousNiveauGlobal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(progressionTitle(progression.niveauGlobal),
              style: AppFonts.display(size: 17, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            'Diagnostic du ${quand == null ? 'précédent' : formatJourCourt(quand)}'
            '${avant == null ? '' : ' — niveau estimé ${avant.wire}'}',
            style: AppFonts.label(size: 11, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 10),
          for (final e in progression.epreuves)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(epreuvePresentation(e.epreuve).icon,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(epreuvePresentation(e.epreuve).label,
                        style: AppFonts.ui(size: 14, color: AppColors.ink)),
                  ),
                  // 🛑 `inconnue` n'affiche RIEN de comparatif : « = » se
                  // lirait « vous avez tenu votre niveau » alors que rien n'a
                  // été comparé.
                  Text(
                    evolutionLabel(e.evolution, e.avant) ?? kNiveauNonEvalue,
                    style: AppFonts.label(
                      size: 12,
                      color: e.evolution == NiveauEvolution.hausse
                          ? AppColors.blueDark
                          : AppColors.inkFaint,
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

class _PrioriteCard extends StatelessWidget {
  const _PrioriteCard({required this.priorite, required this.cible});

  final TcfDiagnosticPriorityDto priorite;
  final NiveauCecrl? cible;

  @override
  Widget build(BuildContext context) {
    // Le rang 1 est le plus urgent : il porte le rouge, les suivants l'ambre.
    final accent = priorite.rang == 1 ? AppColors.red : AppColors.amber;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prioriteTitle(
              priorite.rang,
              epreuvePresentation(priorite.epreuve).label,
              priorite.taskCode,
            ),
            style: AppFonts.ui(
                size: 14, weight: FontWeight.w700, color: AppColors.ink),
          ),
          if (priorite.niveauTache != null) ...[
            const SizedBox(height: 2),
            Text(
              '${priorite.niveauTache!.shortName}'
              '${cible != null ? ' → ${cible!.wire}' : ''}',
              style: AppFonts.ui(size: 12, color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}
