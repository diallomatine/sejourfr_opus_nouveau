import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mastery_status.dart';

/// Topbar du détail module : bouton retour à gauche, icône décorative du
/// module à droite. Diffère de `HubTopBar` (notif + badge) — on garde les
/// deux distincts pour ne pas paramétrer trop.
class ModuleDetailTopBar extends StatelessWidget {
  const ModuleDetailTopBar({
    super.key,
    required this.onBack,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final VoidCallback onBack;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 22,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ],
    );
  }
}

/// Titre de page (eyebrow "Module TCF" / "Module civique" + grand titre).
class ModuleDetailTitle extends StatelessWidget {
  const ModuleDetailTitle({
    super.key,
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppFonts.mono(
            size: 10,
            color: AppColors.muted,
            letterSpacing: 1.8,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppFonts.ui(
            size: 30,
            weight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.05,
          ).copyWith(letterSpacing: -0.6),
        ),
      ],
    );
  }
}

/// Bandeau "hero" en gradient sous le titre. Reprend le pattern audio-hero
/// du design (gros emoji + intitulé + description) en typographie SejourFR.
class ModuleDetailHero extends StatelessWidget {
  const ModuleDetailHero({
    super.key,
    required this.icon,
    required this.headline,
    required this.description,
    required this.gradient,
  });

  final IconData icon;
  final String headline;
  final String description;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            style: AppFonts.ui(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppFonts.ui(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de stats (3 cellules) sous le hero. Chaque cellule : valeur en
/// gras + label en JetBrains Mono.
class ModuleDetailStats extends StatelessWidget {
  const ModuleDetailStats({super.key, required this.items});

  /// Triplet (value, label) — le widget assume 3 entrées (1 par cellule).
  final List<({String value, String label})> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _StatCell(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final ({String value, String label}) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            item.value,
            style: AppFonts.ui(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label.toUpperCase(),
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte "Dernier score" : pourcentage de maîtrise + badge + barre.
/// Pour la version simple on affiche un score de maîtrise dérivé de
/// `/api/me/stats` plutôt qu'un score de session précis (qui demanderait
/// `listMine` filtré finement).
class ModuleDetailScoreCard extends StatelessWidget {
  const ModuleDetailScoreCard({
    super.key,
    required this.answered,
    required this.correct,
    required this.total,
    required this.accent,
  });

  /// Nombre de questions distinctes que le user a vues sur ce module
  /// (= ce qui alimente la barre couverture).
  final int answered;

  /// Nombre de questions distinctes que le user a réussies au moins une
  /// fois sur ce module.
  final int correct;

  /// Taille du pool actif du module (depuis `Theme.questionCount`).
  final int total;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final neverPlayed = answered == 0;
    // Progression = maîtrise : bonnes réponses / total de questions du module.
    final mastery = total == 0 ? 0.0 : (correct / total).clamp(0.0, 1.0);
    final masteryPct = (mastery * 100).round();

    // Badge de statut piloté par la maîtrise (source unique partagée avec
    // l'écran Progression — cohérence sur toutes les surfaces).
    final status = MasteryStatus.of(hasAnswered: !neverPlayed, mastery: mastery);
    final badgeLabel = status.label;
    final badgeColor = status.color;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAÎTRISE DU MODULE',
                      style: AppFonts.mono(
                        size: 9.5,
                        color: AppColors.muted,
                        letterSpacing: 1.8,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: neverPlayed ? '0' : '$correct',
                            style: AppFonts.ui(
                              size: 22,
                              weight: FontWeight.w800,
                              color: AppColors.ink,
                            ).copyWith(letterSpacing: -0.4),
                          ),
                          TextSpan(
                            text: ' / $total',
                            style: AppFonts.ui(
                              size: 18,
                              weight: FontWeight.w600,
                              color: AppColors.muted2,
                            ),
                          ),
                          TextSpan(
                            text: ' réussies',
                            style: AppFonts.ui(
                              size: 13,
                              weight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: AppFonts.ui(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de maîtrise (% de bonnes réponses sur le pool complet).
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: AppColors.line2,
                ),
                FractionallySizedBox(
                  widthFactor: neverPlayed ? 0 : mastery.clamp(0.02, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!neverPlayed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$masteryPct % de maîtrise',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.ink2,
                      letterSpacing: 1.2,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!neverPlayed) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  neverPlayed
                      ? 'Lance ta première session pour voir ta progression.'
                      : '$answered questions vues — continue pour gagner en maîtrise.',
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// Barre d'onglets segmentés (Séries / Examens / Erreurs).
class ModuleDetailTabs extends StatelessWidget {
  const ModuleDetailTabs({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
    required this.accent,
    this.lockedIndices = const <int>{},
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  /// Indices d'onglets réservés aux abonnés : un petit cadenas est rendu à
  /// côté du label, et le tap reste fonctionnel (au caller d'afficher le
  /// paywall en regardant si l'onglet sélectionné est dans cet ensemble).
  final Set<int> lockedIndices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == activeIndex ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == activeIndex
                        ? [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: i == activeIndex ? accent : AppColors.muted,
                        ),
                      ),
                      if (lockedIndices.contains(i)) ...[
                        const SizedBox(width: 5),
                        Icon(
                          LucideIcons.lock,
                          size: 12,
                          color: i == activeIndex ? accent : AppColors.muted,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte d'une série d'entraînement : numéro + titre + description + chevron
/// (ou icône lock si réservé premium). `scoreBadge` est un texte facultatif
/// (ex: "8/15") affiché à droite à la place du chevron quand le lot a déjà
/// été fait — sert à signaler visuellement les lots terminés. `scoreColor`
/// override `accent` pour le tint de la card + le badge (sert à coder le
/// niveau de réussite : rouge / ambre / vert). Le chip du numéro reste en
/// `accent` (couleur du niveau du lot).
class ModuleDetailSeriesCard extends StatelessWidget {
  const ModuleDetailSeriesCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
    this.locked = false,
    this.scoreBadge,
    this.scoreColor,
  });

  final int index;
  final String title;
  final String description;
  final Color accent;
  final bool locked;
  final String? scoreBadge;
  final Color? scoreColor;
  final VoidCallback onTap;

  /// Couleur utilisée pour teinter la card et le badge quand un score est
  /// présent. Fallback sur l'accent du niveau quand aucun score-color
  /// override n'a été fourni.
  Color get _doneAccent => scoreColor ?? accent;

  @override
  Widget build(BuildContext context) {
    final isDone = scoreBadge != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        // Lot déjà fait : fond très légèrement teinté avec la couleur du
        // score (rouge / ambre / vert) pour signaler la maîtrise d'un coup
        // d'œil. Sans score override, on retombe sur la couleur du niveau.
        color: isDone
            ? _doneAccent.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? _doneAccent.withValues(alpha: 0.4) : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '$index',
                      style: AppFonts.ui(
                        size: 16,
                        weight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppFonts.ui(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ).copyWith(letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: AppFonts.ui(
                            size: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (locked)
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.line2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        size: 15,
                        color: AppColors.muted,
                      ),
                    )
                  else if (scoreBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _doneAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        scoreBadge!,
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 22,
                      color: AppColors.muted2,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder "Bientôt" pour les onglets pas encore branchés (Examens, Erreurs).
class ModuleDetailTabPlaceholder extends StatelessWidget {
  const ModuleDetailTabPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 26, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 12.5,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'BIENTÔT',
              style: AppFonts.mono(
                size: 9.5,
                color: AppColors.amber,
                letterSpacing: 1.6,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay loader affiché pendant le POST /api/attempts.
class ModuleDetailStartingOverlay extends StatelessWidget {
  const ModuleDetailStartingOverlay({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink.withValues(alpha: 0.32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: accent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Préparation de la session…',
                style: AppFonts.ui(size: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
