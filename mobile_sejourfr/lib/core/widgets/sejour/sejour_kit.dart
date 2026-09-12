import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';

/// Kit « parcours » — primitives partagées par les écrans de diagnostic et de
/// plan (TCF et civique).
///
/// **Miroir Flutter de `web_sejoufr/app/_components/sejour/SejourKit.tsx`.**
/// Les deux fichiers décrivent les mêmes briques, avec les mêmes noms : un
/// motif ajouté d'un côté s'ajoute de l'autre dans la même passe, sinon les
/// deux fronts divergent — c'est l'invariant de parité du dépôt.
///
/// 🛑 Aucune couleur ni taille de police en dur : tout passe par [AppColors],
/// [AppRadii], [AppShadows] et [AppFonts].
///
/// 🛑 Aucune de ces briques ne **classe** : elle affiche un libellé et un ton
/// servis par le backend. Pas de seuil, pas de `cefr(v)`, pas de `masteryLabel`.

/// Ton d'état servi : [ok] acquis, [warn] à renforcer, [hot] prioritaire.
///
/// 🛑 [muted] = **non mesuré**, et ce n'est pas un quatrième degré de gravité :
/// c'est l'absence de mesure. Sans lui, un thème `NON_EVALUE` retombait sur
/// [warn] et s'affichait en ambre — le front désignait comme fragile quelque
/// chose que le serveur n'a jamais évalué. `null = inconnu, jamais mauvais`.
enum SfTone { ok, warn, hot, muted }

/// État d'une étape de parcours ou d'une compétence.
enum SfStepState { done, now, todo }

extension SfToneColors on SfTone {
  /// Couleur du libellé d'état. Chacune est un ton **de texte** : lisible sur
  /// blanc comme sur son fond clair.
  Color get text => switch (this) {
        SfTone.ok => AppColors.greenDark,
        SfTone.warn => AppColors.amberDark,
        SfTone.hot => AppColors.redDark,
        SfTone.muted => AppColors.muted,
      };

  /// Fond clair de la pastille correspondante.
  Color get soft => switch (this) {
        SfTone.ok => AppColors.greenLight,
        SfTone.warn => AppColors.amberLight,
        SfTone.hot => AppColors.redLight,
        SfTone.muted => AppColors.surface3,
      };

  /// Teinte pleine de l'icône posée sur [soft].
  Color get mark => switch (this) {
        SfTone.ok => AppColors.green,
        SfTone.warn => AppColors.amberDark,
        SfTone.hot => AppColors.red,
        SfTone.muted => AppColors.muted,
      };

  /// [muted] et [warn] partagent le tiret : ce qui les distingue, c'est la
  /// couleur (neutre / ambre) et le libellé servi, jamais une icône d'alerte.
  IconData get icon => switch (this) {
        SfTone.ok => LucideIcons.check,
        SfTone.warn => LucideIcons.minus,
        SfTone.hot => LucideIcons.circleAlert,
        SfTone.muted => LucideIcons.minus,
      };
}

/* ----------------------------------------------------------------- Rythme */

/// Marge latérale d'écran de la maquette.
const sfGutter = EdgeInsets.symmetric(horizontal: 16);

/// Écart entre deux cartes d'une même pile.
const sfGap = 10.0;

/// Espace au-dessus d'une section.
const sfSectionGap = 22.0;

/// Titre de section, aligné sur les marges d'écran.
class SfSectionTitle extends StatelessWidget {
  const SfSectionTitle(this.text, {super.key, this.flush = false});

  final String text;

  /// `true` quand le titre est déjà dans un bloc en gouttière : il ne reprend
  /// pas la marge latérale.
  final bool flush;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(flush ? 0 : 16, 0, flush ? 0 : 16, 10),
      child: Text(
        text,
        style: AppFonts.display(size: 16, weight: FontWeight.w700),
      ),
    );
  }
}

/// Une section : un titre optionnel puis son contenu, avec l'espace au-dessus.
class SfSection extends StatelessWidget {
  const SfSection({super.key, this.title, required this.child, this.flush = false});

  final String? title;
  final Widget child;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: sfSectionGap, left: flush ? 16 : 0, right: flush ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) SfSectionTitle(title!, flush: flush),
          child,
        ],
      ),
    );
  }
}

/// Empile des enfants avec l'écart standard, en gouttière.
class SfStack extends StatelessWidget {
  const SfStack({super.key, required this.children, this.pad = true});

  final List<Widget> children;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: sfGap),
          children[i],
        ],
      ],
    );
    return pad ? Padding(padding: sfGutter, child: column) : column;
  }
}

/* ------------------------------------------------------------------ Cartes */

enum SfCardVariant { plain, soft, ok, warn, hero }

/// La carte blanche du kit. [hero] est la carte de tête d'un écran : plus
/// ronde, ombre marquée.
class SfCard extends StatelessWidget {
  const SfCard({
    super.key,
    required this.child,
    this.variant = SfCardVariant.plain,
    this.padding,
  });

  final Widget child;
  final SfCardVariant variant;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final hero = variant == SfCardVariant.hero;
    final (background, border) = switch (variant) {
      SfCardVariant.soft => (AppColors.blueSoft, AppColors.blueLight),
      SfCardVariant.ok => (AppColors.greenLight, AppColors.greenBorder),
      SfCardVariant.warn => (AppColors.amberLight, AppColors.amberBorder),
      _ => (AppColors.white, null),
    };
    return Container(
      padding: padding ?? (hero ? const EdgeInsets.fromLTRB(18, 22, 18, 18) : const EdgeInsets.fromLTRB(16, 18, 16, 18)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(hero ? 28 : AppRadii.xl),
        border: border == null ? null : Border.all(color: border),
        boxShadow: border == null ? (hero ? AppShadows.md : AppShadows.card) : null,
      ),
      child: child,
    );
  }
}

/// Petit label gris au-dessus d'une valeur.
class SfLabel extends StatelessWidget {
  const SfLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.ui(
        size: 12,
        weight: FontWeight.w700,
        color: color ?? AppColors.muted,
      ),
    );
  }
}

/// Paragraphe d'analyse sous une valeur de tête.
class SfInsight extends StatelessWidget {
  const SfInsight(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.ui(size: 14, color: AppColors.ink2, height: 1.5),
    );
  }
}

/// Texte secondaire fin.
class SfTiny extends StatelessWidget {
  const SfTiny(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.ui(size: 12.5, color: color ?? AppColors.muted, height: 1.45),
    );
  }
}

/* ------------------------------------------------------------------ Niveau */

/// Le grand niveau CECRL de la carte de tête.
class SfLevel extends StatelessWidget {
  const SfLevel(this.level, {super.key});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Text(
      level,
      style: AppFonts.display(size: 72, weight: FontWeight.w600, color: AppColors.blue, height: 0.9),
    );
  }
}

/// Le score brut « 18 / 40 » de la carte de tête civique.
class SfScore extends StatelessWidget {
  const SfScore({super.key, required this.score, required this.total, this.compact = false});

  final int score;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$score ',
            style: AppFonts.display(
              size: compact ? 40 : 56,
              weight: FontWeight.w600,
              color: AppColors.blue,
              height: 0.95,
            ),
          ),
          TextSpan(
            text: '/ $total',
            style: AppFonts.display(
              size: compact ? 18 : 22,
              weight: FontWeight.w500,
              color: AppColors.muted,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}

/// Piste de niveau CECRL. Les paliers, le palier courant et l'objectif sont
/// **servis** : ce widget ne devine ni l'ordre ni la position.
class SfLevelTrack extends StatelessWidget {
  const SfLevelTrack({
    super.key,
    required this.levels,
    required this.currentIndex,
    required this.goalIndex,
    this.youLabel = 'Vous',
    this.goalLabel = 'Objectif',
  });

  final List<String> levels;
  final int currentIndex;
  final int goalIndex;
  final String youLabel;
  final String goalLabel;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: 'Vous êtes à ${levels[currentIndex.clamp(0, levels.length - 1)]}, '
          'objectif ${levels[goalIndex.clamp(0, levels.length - 1)]}',
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = constraints.maxWidth / levels.length;
            final railStart = columnWidth / 2;
            final railEnd = constraints.maxWidth - columnWidth / 2;
            final ratio = levels.length > 1
                ? (currentIndex.clamp(0, levels.length - 1)) / (levels.length - 1)
                : 0.0;
            return Stack(
              children: [
                Positioned(
                  left: railStart,
                  top: 8,
                  child: Container(
                    width: railEnd - railStart,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.lineStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Positioned(
                  left: railStart,
                  top: 8,
                  child: Container(
                    width: (railEnd - railStart) * ratio,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < levels.length; i++)
                      Expanded(
                        child: _SfTrackColumn(
                          level: levels[i],
                          caption: i == currentIndex
                              ? youLabel
                              : i == goalIndex
                                  ? goalLabel
                                  : '',
                          isNow: i == currentIndex,
                          isGoal: i == goalIndex && i != currentIndex,
                          isDone: i < currentIndex,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SfTrackColumn extends StatelessWidget {
  const _SfTrackColumn({
    required this.level,
    required this.caption,
    required this.isNow,
    required this.isGoal,
    required this.isDone,
  });

  final String level;
  final String caption;
  final bool isNow;
  final bool isGoal;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final size = isNow ? 18.0 : (isGoal ? 14.0 : 12.0);
    return Column(
      children: [
        SizedBox(
          height: 20,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNow
                    ? AppColors.blue
                    : isGoal
                        ? AppColors.white
                        : (isDone ? AppColors.muted2 : AppColors.lineStrong),
                border: isGoal ? Border.all(color: AppColors.blue, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: isNow ? AppColors.blueLight : AppColors.white,
                    spreadRadius: isNow ? 5 : 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          level,
          style: AppFonts.ui(
            size: 12,
            weight: FontWeight.w800,
            color: isNow ? AppColors.blue : (isGoal ? AppColors.ink : AppColors.muted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: AppFonts.ui(size: 11, weight: FontWeight.w600, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Bandeau compact « niveau actuel → objectif ».
class SfGoalStrip extends StatelessWidget {
  const SfGoalStrip({
    super.key,
    required this.current,
    required this.goal,
    this.currentLabel = 'Niveau actuel',
    this.goalLabel = 'Objectif',
  });

  final String current;
  final String goal;
  final String currentLabel;
  final String goalLabel;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Row(
        children: [
          Expanded(child: _cell(currentLabel, current)),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
            child: const Icon(LucideIcons.arrowRight, size: 20, color: AppColors.blue),
          ),
          Expanded(child: _cell(goalLabel, goal)),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) => Column(
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppFonts.label(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.display(size: 32, weight: FontWeight.w600, color: AppColors.blue),
          ),
        ],
      );
}

/* ----------------------------------------------------------------- Boutons */

enum SfButtonVariant { primary, blue, line }

/// Le bouton pleine largeur du kit, flèche comprise.
class SfButton extends StatelessWidget {
  const SfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SfButtonVariant.primary,
    this.caption,
    this.icon = LucideIcons.arrowRight,
  });

  final String label;
  final VoidCallback? onPressed;
  final SfButtonVariant variant;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final line = variant == SfButtonVariant.line;
    final background = switch (variant) {
      SfButtonVariant.primary => AppColors.red,
      SfButtonVariant.blue => AppColors.blue,
      SfButtonVariant.line => AppColors.white,
    };
    final foreground = line ? AppColors.blue : AppColors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.md),
            elevation: 0,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: line ? Border.all(color: AppColors.line) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppFonts.ui(
                          size: line ? 14.5 : 16,
                          weight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12.5, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/* ------------------------------------------------------------- Observations */

/// Une observation du diagnostic rapide : positive (vert) ou à améliorer
/// (ambre). Le ton, le titre et le texte sont **servis**.
class SfObservation extends StatelessWidget {
  const SfObservation({
    super.key,
    required this.positive,
    required this.kicker,
    required this.title,
    this.text,
  });

  final bool positive;
  final String kicker;
  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positive ? AppColors.greenLight : AppColors.amberLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              positive ? LucideIcons.check : LucideIcons.arrowUp,
              size: 20,
              color: positive ? AppColors.green : AppColors.amberDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: AppFonts.label(
                    size: 11,
                    color: positive ? AppColors.greenDark : AppColors.amberDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppFonts.ui(size: 14, weight: FontWeight.w700, height: 1.3),
                ),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    text!,
                    style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Encart d'explication ou de réassurance : pastille d'icône + titre + corps.
class SfNoteCard extends StatelessWidget {
  const SfNoteCard({
    super.key,
    required this.icon,
    required this.title,
    this.child,
    this.variant = SfCardVariant.soft,
    this.titleSize = 15,
  });

  final IconData icon;
  final String title;
  final Widget? child;
  final SfCardVariant variant;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final ok = variant == SfCardVariant.ok;
    return SfCard(
      variant: variant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ok ? AppColors.white : AppColors.blueLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: ok ? AppColors.green : AppColors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.display(size: titleSize, weight: FontWeight.w700, height: 1.3),
                ),
                if (child != null) ...[const SizedBox(height: 6), child!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ Lignes */

/// Ligne d'épreuve : icône + libellé, et à droite le niveau et son état servi.
class SfExamRow extends StatelessWidget {
  const SfExamRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.level,
    this.status,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? level;
  final String? status;
  final SfTone? tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.ui(size: 14, weight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!, style: AppFonts.ui(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (level != null || status != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (level != null)
                  Text(
                    level!,
                    style: AppFonts.display(size: 22, weight: FontWeight.w600, color: AppColors.blue),
                  ),
                if (status != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    status!,
                    style: AppFonts.ui(
                      size: 11,
                      weight: FontWeight.w700,
                      color: (tone ?? SfTone.warn).text,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne de thème civique : pastille d'état + nom + libellé d'état servi.
class SfThemeLine extends StatelessWidget {
  const SfThemeLine({
    super.key,
    required this.tone,
    required this.name,
    required this.status,
    this.last = false,
  });

  final SfTone tone;
  final String name;
  final String status;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: tone.soft, shape: BoxShape.circle),
            child: Icon(tone.icon, size: 14, color: tone.mark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: AppFonts.ui(size: 13.5, weight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: AppFonts.ui(size: 11, weight: FontWeight.w700, color: tone.text),
          ),
        ],
      ),
    );
  }
}

/// Carte de priorité, avec son liseré de rang (1 rouge, 2 ambre, 3 jaune).
class SfPrio extends StatelessWidget {
  const SfPrio({
    super.key,
    required this.rank,
    required this.tag,
    required this.title,
    this.text,
    this.child,
  });

  final int rank;
  final String tag;
  final String title;
  final String? text;
  final Widget? child;

  Color get _accent => switch (rank) {
        1 => AppColors.red,
        2 => AppColors.amber,
        _ => AppColors.yellow,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        '$rank',
                        style: AppFonts.ui(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tag.toUpperCase(), style: AppFonts.label(size: 11)),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: AppFonts.display(size: 14.5, weight: FontWeight.w700, height: 1.25),
                          ),
                          if (text != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              text!,
                              style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.4),
                            ),
                          ],
                          if (child != null) child!,
                        ],
                      ),
                    ),
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

/// Barre fine de progression d'une priorité (compétences validées).
class SfProgressMini extends StatelessWidget {
  const SfProgressMini({super.key, required this.ratio, this.semanticsLabel});

  final double ratio;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation(AppColors.blue),
          ),
        ),
      ),
    );
  }
}

/// Sous-ligne d'une priorité : une compétence et son état.
class SfSkillRow extends StatelessWidget {
  const SfSkillRow({super.key, required this.label, required this.state});

  final String label;
  final SfStepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      SfStepState.done => AppColors.greenDark,
      SfStepState.now => AppColors.blueDark,
      SfStepState.todo => AppColors.muted,
    };
    final icon = switch (state) {
      SfStepState.done => LucideIcons.check,
      SfStepState.now => LucideIcons.arrowRight,
      SfStepState.todo => LucideIcons.circle,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(
                size: 13,
                color: color,
                height: 1.3,
                weight: state == SfStepState.now ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------------------------------------------- Parcours */

/// Une étape d'un parcours de tâche ou de notion.
class SfPathStep {
  const SfPathStep({required this.label, required this.state});

  final String label;
  final SfStepState state;
}

/// Le parcours d'une tâche / d'une notion : barre segmentée, compteur
/// « Étape X / Y » et étapes. Les états sont **servis**.
class SfPathCard extends StatelessWidget {
  const SfPathCard({
    super.key,
    required this.currentLabel,
    required this.counterLabel,
    required this.steps,
  });

  final String currentLabel;
  final String counterLabel;
  final List<SfPathStep> steps;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  currentLabel,
                  style: AppFonts.ui(size: 13, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                counterLabel,
                style: AppFonts.ui(size: 12.5, color: AppColors.muted, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: switch (steps[i].state) {
                        SfStepState.done => AppColors.green,
                        SfStepState.now => AppColors.blue,
                        SfStepState.todo => AppColors.line,
                      },
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          for (final step in steps) SfPathRow(label: step.label, state: step.state),
        ],
      ),
    );
  }
}

/// Une ligne d'étape. L'étape courante prend un fond bleu clair et la
/// pastille « Maintenant ».
class SfPathRow extends StatelessWidget {
  const SfPathRow({super.key, required this.label, required this.state});

  final String label;
  final SfStepState state;

  @override
  Widget build(BuildContext context) {
    final done = state == SfStepState.done;
    final now = state == SfStepState.now;
    // 🛑 **Aucune marge négative.** `Container` l'interdit par assertion
    // (`margin.isNonNegative`) : la ligne en cours plantait l'écran en debug dès
    // qu'un parcours servait une étape `now` — Accueil comme Plan. Le débord de
    // 10 px du CSS web (`.isNext`, qui sort de la gouttière de sa carte) n'a pas
    // d'équivalent légal ici ; la surbrillance reste donc **dans** la carte, et
    // c'est le seul écart avec la feuille du web sur cette ligne.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: now ? 10 : 0, vertical: 8),
      decoration: now
          ? BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.greenLight
                  : now
                      ? AppColors.blueLight
                      : AppColors.line,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done
                  ? LucideIcons.check
                  : now
                      ? LucideIcons.arrowRight
                      : LucideIcons.circle,
              size: 14,
              color: done
                  ? AppColors.green
                  : now
                      ? AppColors.blue
                      : AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(
                size: 14,
                color: done ? AppColors.muted : AppColors.ink,
                weight: now ? FontWeight.w700 : (done ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
          ),
          if (now)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.blueLight),
              ),
              child: Text(
                'MAINTENANT',
                style: AppFonts.label(size: 10, color: AppColors.blue),
              ),
            ),
        ],
      ),
    );
  }
}

/// Étape verrouillée (plan gratuit) : rang + libellé + cadenas.
class SfLockRow extends StatelessWidget {
  const SfLockRow({super.key, required this.rank, required this.label, this.last = false});

  final int rank;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$rank',
              style: AppFonts.ui(size: 12, weight: FontWeight.w800, color: AppColors.blue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppFonts.ui(size: 14))),
          const SizedBox(width: 10),
          const Icon(LucideIcons.lock, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Bénéfice verrouillé, dans la carte « votre première étape est prête ».
class SfLockItem extends StatelessWidget {
  const SfLockItem({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          const Icon(LucideIcons.lock, size: 16, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppFonts.ui(size: 13.5, color: AppColors.ink2)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------- « À faire maintenant » */

/// Une métadonnée de la carte d'action : une icône et son libellé.
class SfMeta {
  const SfMeta(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// La carte « À faire maintenant » du Plan : ce que le moteur a choisi, son
/// objectif de séance, ses métadonnées et son bouton.
class SfNowCard extends StatelessWidget {
  const SfNowCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.objectiveLabel,
    this.objective,
    this.meta = const [],
    this.child,
    this.action,
    this.caption,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final String? objectiveLabel;
  final String? objective;
  final List<SfMeta> meta;

  /// Contenu libre entre les métadonnées et le bouton — la liste de bénéfices
  /// verrouillés du plan gratuit vit ICI, dans la carte, comme dans la
  /// maquette. Pendant de `children` sur le `NowCard` web.
  final Widget? child;

  final Widget? action;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface2, AppColors.white],
          stops: [0, 0.42],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, size: 24, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.display(size: 16, weight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppFonts.ui(size: 13, color: AppColors.muted)),
                    ],
                    if (badge != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          badge!.toUpperCase(),
                          style: AppFonts.label(size: 10, color: AppColors.redDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (objective != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (objectiveLabel != null) ...[
                    Text(
                      objectiveLabel!.toUpperCase(),
                      style: AppFonts.label(size: 11, color: AppColors.blue),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    objective!,
                    style: AppFonts.ui(size: 14, weight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final m in meta)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 16, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        m.label,
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (child != null) ...[const SizedBox(height: 12), child!],
          if (action != null) ...[const SizedBox(height: 14), action!],
          if (caption != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                caption!,
                style: AppFonts.ui(size: 12.5, color: AppColors.blueDark, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------ Petites vues */

/// Une ligne de l'aperçu de plan servi en fin de diagnostic.
class SfMiniRow {
  const SfMiniRow({required this.label, this.pill, this.tone});

  final String label;
  final String? pill;
  final SfTone? tone;
}

/// L'aperçu numéroté « votre plan est prêt ».
class SfMiniPlan extends StatelessWidget {
  const SfMiniPlan({super.key, required this.rows});

  final List<SfMiniRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${i + 1}',
                    style: AppFonts.ui(size: 13, weight: FontWeight.w800, color: AppColors.blue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(rows[i].label, style: AppFonts.ui(size: 13.5))),
                if (rows[i].pill != null) ...[
                  const SizedBox(width: 10),
                  SfPill(label: rows[i].pill!, tone: rows[i].tone ?? SfTone.warn),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Pilule d'état, fond clair + texte du même ton.
class SfPill extends StatelessWidget {
  const SfPill({super.key, required this.label, required this.tone});

  final String label;
  final SfTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppFonts.ui(size: 11, weight: FontWeight.w700, color: tone.text),
      ),
    );
  }
}

/// Pastille de contexte du Plan (« 3 thèmes à renforcer »).
class SfPillMeta extends StatelessWidget {
  const SfPillMeta({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.blue),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppFonts.ui(size: 12.5, weight: FontWeight.w600, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

/// Ligne à coche verte d'une liste de bénéfices.
class SfCheckRow extends StatelessWidget {
  const SfCheckRow({super.key, required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 22.0 : 18.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: large ? 8 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, size: 14, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(size: large ? 14 : 13.5, color: AppColors.ink2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de choix à cocher (démarche visée, durée de pass…).
class SfChoiceCard extends StatelessWidget {
  const SfChoiceCard({
    super.key,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.blueSoft : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: selected ? AppColors.blue : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppFonts.ui(
                          size: subtitle == null ? 14.5 : 15,
                          weight: subtitle == null ? FontWeight.w600 : FontWeight.w700,
                          color: selected ? AppColors.blueDark : AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppFonts.ui(size: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.blue : AppColors.white,
                    border: Border.all(
                      color: selected ? AppColors.blue : AppColors.lineStrong,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(LucideIcons.check, size: 12, color: AppColors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------- En-tête d'écran */

/// L'en-tête d'écran de la maquette (`<Top>` / `.sf-top`) : flèche de retour
/// optionnelle, kicker, titre, et pastilles sous le titre.
///
/// Il vit **dans le scroll**, contrairement à `ScreenHeader` : c'est ce que
/// décrit la maquette, et le titre y a la place de tenir sur deux lignes.
///
/// 🛑 Il a vécu en **trois copies** (`CivicTop`, `PlanTop`, plus les écrans TCF
/// restés sur `ScreenHeader`), et elles avaient déjà divergé — 22 px d'un côté,
/// 28 de l'autre. La taille du kit est celle de `.sf-title`, donc 22, comme le
/// web : c'est la maquette qui tranche, pas la dernière passe.
/// Ce qui se glisse SOUS l'en-tête de page, dans TOUS les états d'un écran.
///
/// 🛑 **L'ordre « eyebrow → titre → bascule de module » est posé ICI**, une
/// seule fois : l'écran parent fournit le widget, [SfTop] le pose. Sans ce
/// relais, le parent devrait rendre la bascule lui-même — donc AU-DESSUS de
/// l'en-tête, l'ordre qu'on corrige — ou la faire descendre jusqu'aux sept
/// variantes du Plan (chargement, sans diagnostic, gratuit, abonné, TCF,
/// civique…), chacune portant son propre [SfTop]. Une bascule recopiée sept
/// fois finit toujours par diverger d'un état à l'autre.
///
/// Miroir web : `TopSlot` (`app/_components/sejour/SejourKit.tsx`).
class SfTopSlot extends InheritedWidget {
  const SfTopSlot({super.key, required this.below, required super.child});

  final Widget below;

  static Widget? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SfTopSlot>()?.below;

  @override
  bool updateShouldNotify(SfTopSlot oldWidget) => below != oldWidget.below;
}

class SfTop extends StatelessWidget {
  const SfTop({
    super.key,
    this.onBack,
    this.kicker,
    required this.title,
    this.badges = const <String>[],
  });

  final VoidCallback? onBack;
  final String? kicker;
  final String title;

  /// Les pastilles sous le titre, dans l'ordre donné. Vide = aucune.
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final below = SfTopSlot.maybeOf(context);
    // 🛑 **L'en-tête est TOUJOURS aligné à gauche** (arbitrage du propriétaire,
    // 2026-09-12, sur capture de l'Accueil et du Plan). Il **révoque** la règle
    // « un en-tête sans flèche de retour se centre », posée le même jour : un
    // titre centré au-dessus d'un contenu entièrement calé à gauche se lisait
    // comme un bandeau, pas comme le titre de la page — et il ne s'alignait ni
    // sur la bascule de parcours, ni sur les cartes en dessous.
    //
    // C'est aussi ce que fait la maquette, et ce que le web a toujours fait sur
    // l'Accueil (`.home-hello`). `.topPlain` a été retiré côté web dans la même
    // passe : les deux fronts s'alignent à gauche à toutes les largeurs.
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            _SfBackButton(onTap: onBack!),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(
                    kicker!,
                    textAlign: TextAlign.start,
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppFonts.display(size: 22, weight: FontWeight.w700, height: 1.15),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final b in badges) SfBadge(b)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (below == null) return header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, below],
    );
  }
}

class _SfBackButton extends StatelessWidget {
  const _SfBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(LucideIcons.arrowLeft, size: 22, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Le badge bleu de l'en-tête (`.sf-badge`).
class SfBadge extends StatelessWidget {
  const SfBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.label(size: 11, color: AppColors.blueDark),
      ),
    );
  }
}

/// « Votre objectif : **B2** » (`.sf-goal-line`), sous le niveau d'une carte
/// hero.
///
/// 🛑 Le palier est **servi** : cette ligne n'est pas rendue quand la démarche
/// du candidat n'est pas déclarée.
class SfGoalLine extends StatelessWidget {
  const SfGoalLine({super.key, required this.prefix, required this.goal});

  /// « Votre objectif : » ou « Objectif : » selon l'écran — la maquette ne dit
  /// pas la même chose sur l'estimation rapide et sur le bilan complet.
  final String prefix;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: prefix,
        style: AppFonts.ui(size: 15, color: AppColors.ink),
        children: [
          TextSpan(
            text: goal,
            style: AppFonts.ui(size: 15, weight: FontWeight.w800, color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}

/// La phrase en emphase d'un encart (`.sf-emphasis`) : « Votre niveau peut donc
/// être différent selon les épreuves. »
class SfEmphasis extends StatelessWidget {
  const SfEmphasis(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.ui(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.blueDark,
        height: 1.45,
      ),
    );
  }
}

/* ------------------------------------------------------------- Chiffres */

/// Une colonne de la carte de statistiques : une valeur et son libellé.
typedef SfStat = ({String value, String label});

/// La carte de statistiques en colonnes (`.sf-stat-grid`).
///
/// Le nombre de colonnes suit la liste : une statistique que le serveur ne sert
/// pas ne s'affiche pas plutôt que de s'inventer.
class SfStatGrid extends StatelessWidget {
  const SfStatGrid({super.key, required this.stats});

  final List<SfStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  stats[i].value,
                  textAlign: TextAlign.center,
                  style: AppFonts.display(
                    size: 22,
                    weight: FontWeight.w600,
                    color: AppColors.blue,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats[i].label,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// La liste à puces d'une carte (`.sf-theme-list`).
class SfBulletList extends StatelessWidget {
  const SfBulletList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: EdgeInsets.fromLTRB(0, 8, 0, i == items.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              border: i == items.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: AppColors.ink2,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// L'encart de seuil sous un score (`.sf-threshold`).
class SfThreshold extends StatelessWidget {
  const SfThreshold(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        text,
        style: AppFonts.ui(size: 13, color: AppColors.ink2, height: 1.45),
      ),
    );
  }
}

/// La valeur en toutes lettres d'une carte (`.sf-sit-score`) : « 8 réponses
/// correctes sur 12 ».
class SfHeadline extends StatelessWidget {
  const SfHeadline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.display(size: 18, weight: FontWeight.w700, height: 1.25),
    );
  }
}

/* --------------------------------------------------- Bas d'écran bloqué */

/// La barre d'action basse (`.sf-sticky`) : elle porte le seul geste d'un écran
/// verrouillé, et reste visible quel que soit le défilement.
class SfStickyBar extends StatelessWidget {
  const SfStickyBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.md,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

/// La carte d'offre bleue (« Passez du diagnostic à la progression ») : ce que
/// l'accès ouvre, en langage de bénéfices.
///
/// 🛑 **Aucun prix.** Les tarifs viennent du store et ne se lisent que sur
/// l'écran d'offre, qui reste la seule porte d'achat de l'app.
class SfUnlockHero extends StatelessWidget {
  const SfUnlockHero({
    super.key,
    required this.title,
    required this.text,
    this.checks = const <String>[],
  });

  final String title;
  final String text;
  final List<String> checks;

  @override
  Widget build(BuildContext context) {
    return SfCard(
      variant: SfCardVariant.soft,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.display(size: 20, weight: FontWeight.w700, height: 1.2),
          ),
          const SizedBox(height: 8),
          SfInsight(text),
          if (checks.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final check in checks) SfCheckRow(label: check),
          ],
        ],
      ),
    );
  }
}
