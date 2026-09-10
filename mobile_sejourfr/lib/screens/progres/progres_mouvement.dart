import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/models/progress_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/premium_lock.dart';
import 'progres_labels.dart';

/// **Progrès** (T28, `30_` §7) — « montrer le MOUVEMENT, pas un tableau de
/// bord ».
///
/// ⚠️ **Ce n'est pas un écran de plus.** `ProgresScreen` répond déjà à « où j'en
/// suis » (maîtrise par catégorie) ; ce bloc s'y greffe et répond à « qu'est-ce
/// qui a bougé ». Créer un troisième écran de progression aurait été la
/// troisième réponse à la même question.
///
/// 🛑 **Rien n'est calculé ici.** Les paliers, les sens d'évolution, les états
/// de maîtrise et les compteurs arrivent **servis** (`/api/me/progress`), et les
/// phrases vivent dans `progres_labels.dart`.
///
/// 🛑 **Deux règles de la spec, plus faciles à violer qu'à tenir** : aucun
/// pourcentage de progression vers un palier, aucune gamification.
///
/// 🛑 **Le bloc 5 est un LIEN**, pas une seconde liste : les écrans
/// d'historique existent.
class ProgresMouvement extends ConsumerStatefulWidget {
  const ProgresMouvement({super.key});

  @override
  ConsumerState<ProgresMouvement> createState() => _ProgresMouvementState();
}

class _ProgresMouvementState extends ConsumerState<ProgresMouvement> {
  Progress? _progres;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final progres = await ref.read(progressRepositoryProvider).progres();
      if (mounted) setState(() => _progres = progres);
    } catch (_) {
      // Best-effort : le reste de l'écran (maîtrise par catégorie) n'a pas à
      // disparaître parce qu'un bloc de mouvement manque.
    }
  }

  @override
  Widget build(BuildContext context) {
    final progres = _progres;
    if (progres == null) return const SizedBox.shrink();

    final tcf = progres.tcf;
    final civique = progres.civique;
    final niveau = progresNiveauLabel(tcf);
    final competences = progresCompetencesLabel(tcf.competences);
    final civiqueLabel = progresCiviqueLabel(civique);
    final civiqueScore = progresCiviqueScore(civique);
    final regularite = progresRegulariteLabel(progres.activite);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kProgresTitle, style: AppFonts.display(size: 20, color: AppColors.ink)),
        const SizedBox(height: 4),
        Text(kProgresLead,
            style: AppFonts.ui(size: 13, color: AppColors.inkFaint, height: 1.45)),
        const SizedBox(height: 12),

        if (!tcf.disponible && !civique.disponible) ...[
          Text(kProgresVideText,
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
        ],

        // 1 — le niveau. 🛑 Deux paliers nommés, jamais une barre entre eux.
        if (tcf.disponible && niveau != null) ...[
          _Bloc(
            eyebrow: kProgresNiveauTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(niveau, style: AppFonts.display(size: 22)),
                // 🛑 Une courbe demande DEUX points : avec un seul, on liste
                // les mesures, on n'annonce pas une trajectoire.
                if (tcf.historique.length > 1) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      for (final point in tcf.historique)
                        _Point(
                          valeur: point.niveau?.displayName ?? '—',
                          quand: point.mesureA,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 2 — par épreuve. Les 4 sont là, évaluées ou non.
        if (tcf.epreuves.isNotEmpty) ...[
          _Bloc(
            eyebrow: kProgresEpreuvesTitle,
            child: Column(
              children: [
                for (final e in tcf.epreuves) _EpreuveRow(epreuve: e),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 3 — les compétences. 🛑 Le compteur reste, le DÉTAIL est premium.
        if (competences != null) ...[
          _Bloc(
            eyebrow: kProgresCompetencesTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(competences, style: AppFonts.ui(size: 15, color: AppColors.ink)),
                const SizedBox(height: 8),
                if (tcf.competences.locked)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PremiumLockPill(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(kProgresCompetencesLocked,
                            style: AppFonts.ui(
                                size: 12, color: AppColors.inkFaint, height: 1.5)),
                      ),
                    ],
                  )
                else
                  for (final c in tcf.competences.dernieres)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(c.titre,
                                style: AppFonts.ui(size: 14, color: AppColors.ink)),
                          ),
                          Text(_jourCourt(c.preuveA) ?? '',
                              style: AppFonts.ui(
                                  size: 12, color: AppColors.inkFaint)),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Civique — 🛑 aucun palier CECRL de ce côté (`20_` §12).
        if (civique.disponible) ...[
          _Bloc(
            eyebrow: kProgresCiviqueTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (civiqueScore != null)
                  Text(civiqueScore, style: AppFonts.display(size: 20)),
                if (civiqueLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(civiqueLabel,
                      style: AppFonts.ui(size: 14, color: AppColors.inkSoft)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 4 — l'activité. 🛑 Ni flamme, ni record, ni objectif.
        _Bloc(
          eyebrow: kProgresActiviteTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(progresActiviteLabel(progres.activite),
                  style: AppFonts.ui(size: 15, color: AppColors.ink)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final semaine in progres.activite.semaines)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: i < semaine.jours
                                    ? AppColors.blue
                                    : AppColors.line,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (regularite != null) ...[
                const SizedBox(height: 8),
                Text(regularite,
                    style: AppFonts.ui(size: 12, color: AppColors.inkFaint)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 5 — l'historique. 🛑 Un LIEN vers l'existant, pas une liste.
        AppCard(
          onTap: () => context.push(AppRoutes.historiques),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kProgresHistoriqueTitle,
                        style: AppFonts.ui(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(kProgresHistoriqueText,
                        style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
      ],
    );
  }
}

String? _jourCourt(DateTime? date) {
  if (date == null) return null;
  return '${date.day}/${date.month.toString().padLeft(2, '0')}';
}

class _Bloc extends StatelessWidget {
  const _Bloc({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.valeur, this.quand});

  final String valeur;
  final DateTime? quand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valeur, style: AppFonts.ui(size: 14, color: AppColors.ink)),
        Text(_jourCourt(quand) ?? '',
            style: AppFonts.ui(size: 11, color: AppColors.inkFaint)),
      ],
    );
  }
}

class _EpreuveRow extends StatelessWidget {
  const _EpreuveRow({required this.epreuve});

  final ProgressEpreuve epreuve;

  static Color _tone(ProgresEvolutionTone tone) => switch (tone) {
        ProgresEvolutionTone.up => AppColors.green,
        ProgresEvolutionTone.down => AppColors.red,
        ProgresEvolutionTone.flat => AppColors.inkFaint,
      };

  @override
  Widget build(BuildContext context) {
    final marqueur = progresEvolutionLabel(epreuve);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(epreuve.epreuve.displayLabel,
                style: AppFonts.ui(size: 14, color: AppColors.ink)),
          ),
          Text(progresEpreuveNiveau(epreuve),
              style: AppFonts.label(size: 12, color: AppColors.inkSoft)),
          // 🛑 `inconnue` ne rend RIEN — surtout pas « = » : une épreuve non
          // comparable n'a ni progressé ni tenu.
          if (marqueur != null) ...[
            const SizedBox(width: 10),
            Text(marqueur,
                style: AppFonts.ui(
                    size: 12.5,
                    color: _tone(progresEvolutionTone(epreuve.evolution)))),
          ],
        ],
      ),
    );
  }
}
