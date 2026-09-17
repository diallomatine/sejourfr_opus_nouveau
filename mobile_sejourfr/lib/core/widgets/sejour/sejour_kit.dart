import 'dart:math' as math;

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
/// L'état d'une étape de parcours ou d'une compétence.
///
/// 🛑 **[verify] n'est pas [done].** Une série de petits sujets terminée n'est
/// pas une compétence acquise — c'est une preuve qui reste à faire, et elle se
/// lit au premier coup d'œil (accent ambre, icône de validation) plutôt que
/// comme une coche de plus. [doing] est la série commencée, distincte de [now]
/// qui repère la compétence que le Plan travaille **maintenant**.
///
/// ⚠️ Miroir de `StepState` (`web .../app/_components/sejour/SejourKit.tsx`).
enum SfStepState { done, verify, doing, now, todo }

/// La couleur d'un état d'étape, déclarée **une fois** pour les trois widgets
/// qui l'affichent.
Color _sfStepColor(SfStepState state) => switch (state) {
      SfStepState.done => AppColors.greenDark,
      SfStepState.verify => AppColors.amberDark,
      SfStepState.doing || SfStepState.now => AppColors.blueDark,
      SfStepState.todo => AppColors.muted,
    };

IconData _sfStepIcon(SfStepState state) => switch (state) {
      SfStepState.done => LucideIcons.check,
      SfStepState.verify => LucideIcons.badgeCheck,
      SfStepState.doing => LucideIcons.circleDot,
      SfStepState.now => LucideIcons.arrowRight,
      SfStepState.todo => LucideIcons.circle,
    };

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
  const SfSection(
      {super.key, this.title, required this.child, this.flush = false});

  final String? title;
  final Widget child;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: sfSectionGap, left: flush ? 16 : 0, right: flush ? 16 : 0),
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
    this.rule = false,
  });

  final Widget child;
  final SfCardVariant variant;
  final EdgeInsets? padding;

  /// La **cocarde** de 3 px posée en tête de carte (maquette du propriétaire,
  /// 2026-09-16) : bleu · blanc · rouge.
  ///
  /// 🛑 **Décorative et rien d'autre** : elle ne code aucun état et ne change
  /// jamais selon une donnée. Miroir web : `Card rule="flag"`.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final hero = variant == SfCardVariant.hero;
    final (background, border) = switch (variant) {
      SfCardVariant.soft => (AppColors.blueSoft, AppColors.blueLight),
      SfCardVariant.ok => (AppColors.greenLight, AppColors.greenBorder),
      SfCardVariant.warn => (AppColors.amberLight, AppColors.amberBorder),
      _ => (AppColors.white, null),
    };
    final radius = BorderRadius.circular(hero ? 28 : AppRadii.xl);
    final body = Container(
      padding: padding ??
          (hero
              ? const EdgeInsets.fromLTRB(18, 22, 18, 18)
              : const EdgeInsets.fromLTRB(16, 18, 16, 18)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border == null ? null : Border.all(color: border),
        boxShadow:
            border == null ? (hero ? AppShadows.md : AppShadows.card) : null,
      ),
      child: child,
    );
    if (!rule) return body;
    return Stack(
      children: [
        body,
        // 🛑 **Pleine largeur** (maquette v2) : trois bandes égales de 5 px en
        // tête de carte, pas un filet en retrait. Il est posé PAR-DESSUS — il ne
        // mange aucune hauteur de contenu —, découpé au rayon de la carte, et
        // `Positioned.fill` laisse l'ombre du corps intacte (un `ClipRRect`
        // autour du corps la rognerait).
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: radius,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue,
                        AppColors.blue,
                        AppColors.white,
                        AppColors.white,
                        AppColors.red,
                        AppColors.red,
                      ],
                      stops: [0, 1 / 3, 1 / 3, 2 / 3, 2 / 3, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      style: AppFonts.ui(
          size: 12.5, color: color ?? AppColors.muted, height: 1.45),
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
      style: AppFonts.display(
          size: 72,
          weight: FontWeight.w600,
          color: AppColors.blue,
          height: 0.9),
    );
  }
}

/// Le score brut « 18 / 40 » de la carte de tête civique.
class SfScore extends StatelessWidget {
  const SfScore(
      {super.key,
      required this.score,
      required this.total,
      this.compact = false});

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
                ? (currentIndex.clamp(0, levels.length - 1)) /
                    (levels.length - 1)
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
                border:
                    isGoal ? Border.all(color: AppColors.blue, width: 2) : null,
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
            color: isNow
                ? AppColors.blue
                : (isGoal ? AppColors.ink : AppColors.muted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: AppFonts.ui(
              size: 11, weight: FontWeight.w600, color: AppColors.muted),
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
            decoration: const BoxDecoration(
                color: AppColors.blueLight, shape: BoxShape.circle),
            child: const Icon(LucideIcons.arrowRight,
                size: 20, color: AppColors.blue),
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
            style: AppFonts.display(
                size: 32, weight: FontWeight.w600, color: AppColors.blue),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                  style: AppFonts.ui(
                      size: 14, weight: FontWeight.w700, height: 1.3),
                ),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    text!,
                    style: AppFonts.ui(
                        size: 13, color: AppColors.muted, height: 1.4),
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
            child: Icon(icon,
                size: 20, color: ok ? AppColors.green : AppColors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.display(
                      size: titleSize, weight: FontWeight.w700, height: 1.3),
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
                Text(title,
                    style: AppFonts.ui(size: 14, weight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppFonts.ui(size: 12, color: AppColors.muted)),
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
                    style: AppFonts.display(
                        size: 22,
                        weight: FontWeight.w600,
                        color: AppColors.blue),
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

/// **Anneau de couverture** — la part parcourue d'un ensemble, entre 0 et 1.
///
/// 🛑 **Ce n'est pas une note et ce n'est pas un état pédagogique** : un seul
/// accent de marque, jamais une rampe de seuils. Un anneau vide veut dire « pas
/// encore commencé », jamais « mauvais ». Miroir web : `Ring`.
///
/// ⚠️ Distinct de `ProgressRing` (`core/widgets/progress_ring.dart`), qui écrit
/// un pourcentage en son centre : ici il n'y a **aucun chiffre** dans l'anneau,
/// le compteur vit sur la ligne.
class SfRing extends StatelessWidget {
  const SfRing(
      {super.key, required this.ratio, this.size = 40, this.stroke = 4});

  final double ratio;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final part =
        ratio.isNaN || ratio.isInfinite ? 0.0 : ratio.clamp(0, 1).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SfRingPainter(
          part: part,
          stroke: stroke,
          color: part >= 1 ? AppColors.green : AppColors.blue,
        ),
      ),
    );
  }
}

class _SfRingPainter extends CustomPainter {
  _SfRingPainter(
      {required this.part, required this.stroke, required this.color});

  final double part;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.line,
    );
    if (part <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * part,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SfRingPainter old) =>
      old.part != part || old.color != color || old.stroke != stroke;
}

/// **Ligne d'une épreuve ou d'un thème** sur l'écran Réviser : pictogramme,
/// titre, ligne d'état **servie**, compteur, et à droite soit un anneau de
/// couverture, soit un chevron.
///
/// 🛑 [status] et [meta] arrivent **composés** (`reviser_labels.dart` ⇄
/// `lib/reviser.ts`) : cette brique ne classe rien et ne compte rien.
///
/// Miroir web : `EpreuveRow`.
class SfEpreuveRow extends StatelessWidget {
  const SfEpreuveRow({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
    this.meta,
    this.ratio,
  });

  final IconData icon;
  final String title;
  final String status;
  final String? meta;

  /// Part parcourue (0-1). `null` ⇒ un chevron prend la place de l'anneau.
  final double? ratio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = this.ratio;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                      if (meta != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            meta!,
                            style: AppFonts.ui(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: AppColors.ink2,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (ratio != null)
                  SfRing(ratio: ratio)
                else
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: AppColors.muted2,
                  ),
              ],
            ),
          ),
        ),
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
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
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
              style:
                  AppFonts.ui(size: 13.5, weight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: AppFonts.ui(
                size: 11, weight: FontWeight.w700, color: tone.text),
          ),
        ],
      ),
    );
  }
}

/// Carte de priorité, avec son liseré de rang (1 rouge, 2 ambre, 3 jaune).
///
/// **Rétractable dès qu'on en empile plusieurs.** [details] est le contenu que
/// l'encart FERMÉ ne montre pas ; [child] reste toujours lisible. Sans
/// [details], la carte est exactement celle d'avant — c'est le cas d'une
/// priorité seule, qu'il n'y a aucune raison de replier.
///
/// 🛑 **Les deux libellés du bouton sont SERVIS** ([moreLabel] / [lessLabel]) :
/// le kit ne compose aucune phrase et ne compte rien. Sans eux, pas de bouton —
/// on n'affiche pas une bascule anonyme.
///
/// Miroir de `Prio` dans `web_sejoufr/app/_components/sejour/SejourKit.tsx`.
class SfPrio extends StatefulWidget {
  const SfPrio({
    super.key,
    required this.rank,
    required this.tag,
    required this.title,
    this.text,
    this.child,
    this.details,
    this.moreLabel,
    this.lessLabel,
    this.defaultOpen = false,
  });

  final int rank;
  final String tag;
  final String title;
  final String? text;

  /// Ce qui reste lisible encart fermé.
  final Widget? child;

  /// Ce que l'ouverture révèle. `null` ⇒ carte non rétractable.
  final Widget? details;

  /// Le libellé du bouton fermé, **servi** (« + 6 autres compétences »).
  final String? moreLabel;

  /// Le libellé du bouton ouvert, **servi** (« Réduire »).
  final String? lessLabel;

  final bool defaultOpen;

  @override
  State<SfPrio> createState() => _SfPrioState();
}

class _SfPrioState extends State<SfPrio> {
  late bool _open = widget.defaultOpen;

  Color get _accent => switch (widget.rank) {
        1 => AppColors.red,
        2 => AppColors.amber,
        _ => AppColors.yellow,
      };

  bool get _foldable =>
      widget.details != null &&
      widget.moreLabel != null &&
      widget.lessLabel != null;

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
                        '${widget.rank}',
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
                          Text(widget.tag.toUpperCase(),
                              style: AppFonts.label(size: 11)),
                          const SizedBox(height: 3),
                          Text(
                            widget.title,
                            style: AppFonts.display(
                                size: 14.5,
                                weight: FontWeight.w700,
                                height: 1.25),
                          ),
                          if (widget.text != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              widget.text!,
                              style: AppFonts.ui(
                                  size: 13,
                                  color: AppColors.muted,
                                  height: 1.4),
                            ),
                          ],
                          if (widget.child != null) widget.child!,
                          // Le contenu replié est RETIRÉ de l'arbre, pas juste
                          // masqué : un lecteur d'écran ne doit pas traverser un
                          // encart fermé.
                          if (_foldable && _open) widget.details!,
                          if (_foldable) _toggle(),
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

  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        button: true,
        expanded: _open,
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (_open ? widget.lessLabel : widget.moreLabel)!,
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                // Le chevron PIVOTE, il ne se remplace pas : une seule icône,
                // donc aucun saut de largeur à l'ouverture.
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(
                    LucideIcons.chevronDown,
                    size: 15,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le ton du remplissage d'une jauge.
///
/// 🛑 Il se **passe**, il ne se dérive d'aucun nombre : l'appelant le tient
/// d'un état servi. Même palette que les segments de parcours — vert = tenu,
/// bleu = en cours, ambre = à vérifier, rouge = prioritaire, neutre = non
/// mesuré. Miroir web : `BarTone` (`SejourKit.tsx`).
enum SfBarTone { ok, now, warn, hot, muted }

Color _sfBarColor(SfBarTone tone) => switch (tone) {
      SfBarTone.ok => AppColors.green,
      SfBarTone.now => AppColors.blue,
      SfBarTone.warn => AppColors.amberDark,
      SfBarTone.hot => AppColors.red,
      SfBarTone.muted => AppColors.muted2,
    };

/// Barre fine de progression d'une priorité (compétences validées).
///
/// 🛑 **Aucun chiffre n'est rendu** : c'est une part parcourue, jamais une
/// note ni un pourcentage annoncé au candidat.
class SfProgressMini extends StatelessWidget {
  const SfProgressMini({
    super.key,
    required this.ratio,
    this.semanticsLabel,
    this.tone = SfBarTone.now,
  });

  final double ratio;
  final String? semanticsLabel;

  /// Défaut [SfBarTone.now] : c'est le bleu que la brique rendait avant, donc
  /// aucun appelant existant ne change d'aspect.
  final SfBarTone tone;

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
            valueColor: AlwaysStoppedAnimation(_sfBarColor(tone)),
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
    final color = _sfStepColor(state);
    final icon = _sfStepIcon(state);
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
                weight: state == SfStepState.now
                    ? FontWeight.w700
                    : FontWeight.w500,
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
  const SfPathStep({required this.label, required this.state, this.pill});

  final String label;
  final SfStepState state;

  /// Le libellé de la pastille, **servi** par l'appelant (« Série terminée ·
  /// 5/5 »…). Le kit ne compose aucune phrase et n'en déduit aucune d'un
  /// compteur. `null` ⇒ pas de pastille.
  final String? pill;
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
                style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.muted,
                    weight: FontWeight.w600),
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
                        // Série finie, preuve encore à faire : ni la ligne
                        // d'arrivée (vert), ni le travail en cours (bleu).
                        SfStepState.verify => AppColors.amber,
                        SfStepState.doing || SfStepState.now => AppColors.blue,
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
          for (final step in steps)
            SfPathRow(label: step.label, state: step.state, pill: step.pill),
        ],
      ),
    );
  }
}

/// Une ligne d'étape. L'étape en cours prend un fond bleu clair, la série
/// terminée à vérifier un fond ambre, et chacune porte sa **pastille servie**.
///
/// 🛑 **Le libellé de la pastille vient de l'appelant**, jamais d'ici : il porte
/// un état **servi**, pas une phrase du kit.
class SfPathRow extends StatelessWidget {
  const SfPathRow(
      {super.key, required this.label, required this.state, this.pill});

  final String label;
  final SfStepState state;
  final String? pill;

  @override
  Widget build(BuildContext context) {
    final done = state == SfStepState.done;
    final verify = state == SfStepState.verify;
    final now = state == SfStepState.now || state == SfStepState.doing;
    final accent = now || verify;
    // 🛑 **Aucune marge négative.** `Container` l'interdit par assertion
    // (`margin.isNonNegative`) : la ligne en cours plantait l'écran en debug dès
    // qu'un parcours servait une étape `now` — Accueil comme Plan. Le débord de
    // 10 px du CSS web (`.isNext`, qui sort de la gouttière de sa carte) n'a pas
    // d'équivalent légal ici ; la surbrillance reste donc **dans** la carte, et
    // c'est le seul écart avec la feuille du web sur cette ligne.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: accent ? 10 : 0, vertical: 8),
      decoration: accent
          ? BoxDecoration(
              color: verify ? AppColors.amberLight : AppColors.blueSoft,
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
                  : verify
                      ? AppColors.white
                      : now
                          ? AppColors.blueLight
                          : AppColors.line,
              shape: BoxShape.circle,
              border: verify ? Border.all(color: AppColors.amberBorder) : null,
            ),
            child: Icon(
              _sfStepIcon(state),
              size: 14,
              color: done
                  ? AppColors.green
                  : verify
                      ? AppColors.amberDark
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
                weight: accent
                    ? FontWeight.w700
                    : (done ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
          ),
          if (pill != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: verify ? AppColors.amberBorder : AppColors.blueLight,
                  ),
                ),
                child: Text(
                  pill!.toUpperCase(),
                  // La pastille porte un état SERVI : elle se replie sur deux
                  // lignes plutot que d'etre tronquee — un etat a moitie lu ne
                  // dit plus rien. Miroir du `white-space: normal` du web.
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.label(
                    size: 10,
                    color: verify ? AppColors.amberDark : AppColors.blue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Étape verrouillée (plan gratuit) : rang + libellé + cadenas.
class SfLockRow extends StatelessWidget {
  const SfLockRow(
      {super.key, required this.rank, required this.label, this.last = false});

  final int rank;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
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
              style: AppFonts.ui(
                  size: 12, weight: FontWeight.w800, color: AppColors.blue),
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
            child: Text(label,
                style: AppFonts.ui(size: 13.5, color: AppColors.ink2)),
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

/// Les deux visages de la carte d'action : l'entraînement de l'étape, et la
/// **vérification** qui la clôt.
enum SfNowCardVariant { standard, verify }

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
    this.variant = SfNowCardVariant.standard,
  });

  /// 🛑 [SfNowCardVariant.verify] change **la carte**, pas seulement son
  /// bouton : quand la série de petits sujets se termine, le nom de la
  /// compétence reste le même, et sans accent propre le candidat lit « rien n'a
  /// bougé » alors que l'action a changé de nature. Miroir du `variant` du
  /// `NowCard` web.
  final SfNowCardVariant variant;

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
    final verify = variant == SfNowCardVariant.verify;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            verify ? AppColors.amberLight : AppColors.surface2,
            AppColors.white,
          ],
          stops: const [0, 0.46],
        ),
        borderRadius: BorderRadius.circular(28),
        border: verify ? Border.all(color: AppColors.amberBorder) : null,
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
                  color: verify ? AppColors.amberDark : AppColors.blue,
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
                      style:
                          AppFonts.display(size: 16, weight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: AppFonts.ui(size: 13, color: AppColors.muted)),
                    ],
                    if (badge != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: verify ? AppColors.white : AppColors.redLight,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: verify
                              ? Border.all(color: AppColors.amberBorder)
                              : null,
                        ),
                        child: Text(
                          badge!.toUpperCase(),
                          style: AppFonts.label(
                            size: 10,
                            color: verify
                                ? AppColors.amberDark
                                : AppColors.redDark,
                          ),
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
                color: verify ? AppColors.white : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(14),
                border:
                    verify ? Border.all(color: AppColors.amberBorder) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (objectiveLabel != null) ...[
                    Text(
                      objectiveLabel!.toUpperCase(),
                      style: AppFonts.label(
                        size: 11,
                        color: verify ? AppColors.amberDark : AppColors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    objective!,
                    style: AppFonts.ui(
                        size: 14, weight: FontWeight.w600, height: 1.4),
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
                color: verify ? AppColors.white : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border:
                    verify ? Border.all(color: AppColors.amberBorder) : null,
              ),
              child: Text(
                caption!,
                style: AppFonts.ui(
                  size: 12.5,
                  color: verify ? AppColors.inkSoft : AppColors.blueDark,
                  height: 1.45,
                ),
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
                    style: AppFonts.ui(
                        size: 13,
                        weight: FontWeight.w800,
                        color: AppColors.blue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(rows[i].label, style: AppFonts.ui(size: 13.5))),
                if (rows[i].pill != null) ...[
                  const SizedBox(width: 10),
                  SfPill(
                      label: rows[i].pill!, tone: rows[i].tone ?? SfTone.warn),
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
            style: AppFonts.ui(
                size: 12.5, weight: FontWeight.w600, color: AppColors.ink2),
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
            decoration: const BoxDecoration(
                color: AppColors.greenLight, shape: BoxShape.circle),
            child:
                const Icon(LucideIcons.check, size: 14, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(
                  size: large ? 14 : 13.5, color: AppColors.ink2, height: 1.4),
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
                          weight: subtitle == null
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: selected ? AppColors.blueDark : AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style:
                              AppFonts.ui(size: 12.5, color: AppColors.muted),
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
                      ? const Icon(LucideIcons.check,
                          size: 12, color: AppColors.white)
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
                  style: AppFonts.display(
                      size: 22, weight: FontWeight.w700, height: 1.15),
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
            style: AppFonts.ui(
                size: 15, weight: FontWeight.w800, color: AppColors.blue),
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
            padding:
                EdgeInsets.fromLTRB(0, 8, 0, i == items.length - 1 ? 0 : 8),
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
            style: AppFonts.display(
                size: 20, weight: FontWeight.w700, height: 1.2),
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

/* ==========================================================================
   Maquette « Où vous en êtes » + « Vos résultats » (propriétaire, 2026-09-16)

   🛑 Miroirs de `LevelLadder`, `LevelRow`, `LevelList`, `GoalBanner`,
   `MicroNote`, `PanelHead`, `ResultHero`, `LevelChart`, `FilterChips`,
   `HistoryRow` et `InfoNote` côté web. Un motif qui bouge d'un côté bouge de
   l'autre dans la même passe.

   ⚠️ « Où vous en êtes » a été REFAIT le même jour sur une seconde maquette
   (`ou_en_vous_v2.html`) : la grille de cartes compactes est devenue une LISTE
   verticale dans une seule carte, chaque ligne portant une échelle CECRL.
   `SfLevelCard`, `SfLevelGrid` et `SfGoalRibbon` sont **supprimées** — refonte
   = suppression de l'ancien.
   ========================================================================== */

/// Un cran de l'échelle CECRL, **composé par l'appelant** (`accueilEchelons`,
/// `screens/progres/progres_labels.dart`).
///
/// 🛑 Le kit ne sait ni ce qu'est un palier, ni lequel est atteint : il reçoit
/// des crans déjà situés, et il en rend autant qu'on lui en donne — c'est
/// l'appelant qui décide que l'échelle s'arrête à B2. Miroir web :
/// `LadderStep`.
class SfLadderStep {
  const SfLadderStep({
    required this.label,
    required this.state,
    required this.current,
    required this.goal,
  });

  /// Ce qui s'écrit sous le cran (« A1 »…). Décoratif : l'échelle est une image.
  final String label;

  /// `done` = palier acquis · `target` = le cran visé · `empty` = le reste.
  final SfLadderState state;

  /// Le palier ACTUEL du candidat — au plus un cran, aucun sans mesure.
  final bool current;

  /// Le palier VISÉ — au plus un cran, aucun sans démarche déclarée.
  final bool goal;
}

enum SfLadderState { done, target, empty }

/// **L'échelle CECRL** — l'élément signature de la maquette v2 : les crans du
/// parcours et leurs libellés, sous la ligne d'une épreuve.
///
/// 🛑 **Ce n'est pas une jauge et elle n'affiche aucun chiffre** : elle situe
/// un **palier servi** face à un **objectif servi**. Aucun pourcentage de
/// progression vers un palier n'est calculé ni montré — la règle qui l'interdit
/// tient toujours.
///
/// 🛑 **Une seule annonce** : le `Semantics` porte l'échelle entière (« Niveau
/// B1, objectif B2 ») et ses libellés sont exclus — un lecteur d'écran n'a pas
/// à épeler quatre crans. Pendant du `role="img"` + `aria-hidden` du web.
///
/// Miroir web : `LevelLadder`.
class SfLevelLadder extends StatelessWidget {
  const SfLevelLadder({
    super.key,
    required this.steps,
    required this.label,
    this.dim = false,
  });

  final List<SfLadderStep> steps;

  /// Ce que l'échelle DIT. Jamais dérivé ici.
  final String label;

  /// Épreuve jamais mesurée : les crans passent en contour, sans remplissage.
  ///
  /// 🛑 **Passé, jamais deviné** d'un cran vide — une épreuve « &lt;A1 » n'a
  /// elle non plus aucun cran rempli, et ce n'est pas la même chose.
  final bool dim;

  static const double gap = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Expanded(child: _SfLadderBar(step: steps[i], dim: dim)),
          ],
        ],
      ),
    );
  }
}

/// **La légende de l'échelle CECRL** — les quatre paliers, écrits **une seule
/// fois** pour toute la liste.
///
/// 🛑 **Elle remplace quatre répétitions** (2026-09-17) : chaque ligne
/// d'épreuve écrivait « A1 A2 B1 B2 » sous son échelle, soit la même échelle
/// quatre fois et une ligne de texte par épreuve. Le palier atteint se lit déjà
/// en gros à droite de la ligne, et l'objectif est annoncé par le bandeau
/// au-dessus : les libellés par ligne n'ajoutaient rien et coûtaient une
/// hauteur d'écran.
///
/// 🛑 **Le cran d'objectif reste marqué en rouge** : c'est le seul repère des
/// libellés qui portait une information, et il est **global** — le même pour
/// les quatre épreuves.
///
/// ⚠️ **Alignée sur les échelles des lignes** ([SfLevelRow.legendIndent]) : elle
/// n'a de sens qu'au-dessus d'une liste dont les lignes portent un repère
/// court. Miroir web : `LadderLegend` (que le palier desktop masque, où la
/// hauteur n'est pas une contrainte et où la liste passe à deux colonnes).
class SfLadderLegend extends StatelessWidget {
  const SfLadderLegend({super.key, required this.labels, this.goalIndex});

  /// Les paliers de l'échelle, dans l'ordre. **Passés**, jamais dérivés ici.
  final List<String> labels;

  /// Le rang du palier visé. `null` sans démarche déclarée.
  final int? goalIndex;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(left: SfLevelRow.legendIndent),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: SfLevelLadder.gap),
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: AppFonts.label(
                    size: 10,
                    color: i == goalIndex ? AppColors.red : AppColors.muted2,
                  ).copyWith(
                    fontWeight:
                        i == goalIndex ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SfLadderBar extends StatelessWidget {
  const _SfLadderBar({required this.step, required this.dim});

  final SfLadderStep step;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    // Le cran d'objectif reste marqué même sur une épreuve non mesurée : c'est
    // la seule chose qu'on sache d'elle.
    if (step.state == SfLadderState.target) {
      return Container(
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.red, width: 1.5),
        ),
      );
    }
    final rempli = step.state == SfLadderState.done;
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: rempli
            ? AppColors.blue
            : (dim ? Colors.transparent : AppColors.line),
        borderRadius: BorderRadius.circular(4),
        border: dim && !rempli ? Border.all(color: AppColors.line) : null,
      ),
    );
  }
}

/// La couleur d'une **pastille de statut**. Même contrat que [_sfBarColor],
/// mais posée sur du texte : le rouge plein y est trop clair et le gris de
/// `muted2` trop pâle. Miroir web : `.toneOk` … `.toneMuted`.
Color _sfStatusColor(SfBarTone tone) => switch (tone) {
      SfBarTone.ok => AppColors.green,
      SfBarTone.now => AppColors.blue,
      SfBarTone.warn => AppColors.amberDark,
      SfBarTone.hot => AppColors.redDark,
      SfBarTone.muted => AppColors.muted,
    };

/// **La ligne d'une épreuve** — le `.test` de la maquette v2 : repère court en
/// pastille mono, intitulé, statut à pastille colorée, palier à droite, puis
/// l'échelle et une ligne de pied « action · objectif ».
///
/// 🛑 **Cette brique ne classe rien.** Tout lui arrive **composé** par
/// `accueilEpreuve*` (`screens/progres/progres_labels.dart`).
///
/// ⚠️ **Remplace `SfLevelCard`**, la carte compacte de la maquette v1.
/// Miroir web : `LevelRow`.
class SfLevelRow extends StatelessWidget {
  const SfLevelRow({
    super.key,
    required this.mark,
    required this.title,
    required this.status,
    required this.tone,
    required this.level,
    required this.measured,
    required this.cta,
    required this.onTap,
    this.scale,
    this.ctaPrimary = false,
    this.busy = false,
  });

  /// Repère court (« CO »). `null` quand rien n'en sert — on n'en invente pas.
  final String? mark;

  final String title;

  /// L'état en un mot. `null` = rien à dire, jamais « rien à faire ».
  final String? status;

  /// Le ton de la pastille de statut.
  final SfBarTone tone;

  /// Le palier servi, ou le mot d'une absence de mesure. `null` retire la
  /// pastille : le civique n'a aucun palier CECRL servi.
  final String? level;

  /// Y a-t-il une mesure derrière [level] ?
  ///
  /// 🛑 **Passé, jamais deviné du texte** : comparer un libellé pour décider
  /// d'une couleur ferait dépendre l'apparence d'une chaîne reformulable.
  final bool measured;

  /// L'échelle, ou la jauge du civique. `null` quand rien ne la sert.
  final Widget? scale;

  final String cta;

  /// Le CTA devient un bouton plein — l'action qui manque, pas celle qui relit.
  final bool ctaPrimary;

  final VoidCallback onTap;
  final bool busy;

  /// 38 px de pastille + 12 px de gouttière : l'échelle et la ligne de pied
  /// s'alignent sous l'intitulé, pas sous le repère.
  static const double _indent = 50;

  /// Le retrait d'une échelle **depuis le bord de la carte** : le padding de la
  /// ligne plus [_indent]. C'est ce dont [SfLadderLegend] a besoin pour tomber
  /// exactement sous les crans.
  static const double legendIndent = _padding + _indent;

  static const double _padding = 12;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    final retrait = mark == null ? 0.0 : _indent;
    return Material(
      // Une épreuve **jamais mesurée** se détache : c'est la seule ligne qui
      // demande un geste pour exister. 🛑 Le fait est passé (`measured`), et il
      // ne se confond pas avec « <A1 », qui est une mesure.
      color: measured ? Colors.transparent : AppColors.surface2,
      borderRadius: radius,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _padding,
            vertical: 11,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SfLevelRowTop(
                mark: mark,
                title: title,
                status: status,
                tone: tone,
                level: level,
                measured: measured,
              ),
              if (scale != null)
                Padding(
                  padding: EdgeInsets.only(left: retrait, top: 9),
                  child: scale!,
                ),
              Padding(
                padding: EdgeInsets.only(left: retrait, top: 7),
                child: _SfLevelRowCta(cta: cta, primary: ctaPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SfLevelRowTop extends StatelessWidget {
  const _SfLevelRowTop({
    required this.mark,
    required this.title,
    required this.status,
    required this.tone,
    required this.level,
    required this.measured,
  });

  final String? mark;
  final String title;
  final String? status;
  final SfBarTone tone;
  final String? level;
  final bool measured;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (mark != null) ...[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: measured ? AppColors.blue : AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: measured
                  ? null
                  : Border.all(color: AppColors.blue, width: 1.5),
            ),
            // Un repère d'épreuve est une étiquette technique.
            child: Text(
              mark!,
              style: AppFonts.label(
                size: 13.5,
                color: measured ? AppColors.white : AppColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.ui(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    // La pastille prend le ton **servi**, et le mot le redit :
                    // la couleur n'est jamais le seul porteur du sens.
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _sfStatusColor(tone),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: _sfStatusColor(tone),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (level != null) ...[
          const SizedBox(width: 10),
          // 🛑 Non mesuré : pastille neutre et petite. Le bleu est réservé à un
          // palier réel — une pastille de marque sur une absence de mesure se
          // lirait comme un résultat.
          if (measured)
            Text(
              level!,
              style: AppFonts.label(size: 18, color: AppColors.blue),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                level!,
                style: AppFonts.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SfLevelRowCta extends StatelessWidget {
  const _SfLevelRowCta({required this.cta, required this.primary});

  final String cta;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    // 🛑 Le rouge n'apparaît que sur l'action qui MANQUE (évaluer une épreuve
    // jamais mesurée) — c'est la règle d'usage du Rouge France, pas un accent.
    if (primary) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            cta,
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            cta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.blue),
      ],
    );
  }
}

/// La liste des épreuves — **une seule colonne**, comme la maquette v2.
///
/// ⚠️ Le web la passe à deux colonnes au-dessus de 960 px ; **rien à porter
/// ici**, l'app est en portrait téléphone. Une media query n'est pas une
/// primitive.
///
/// ⚠️ **Remplace `SfLevelGrid`**, la grille à deux colonnes de la maquette v1.
/// Miroir web : `LevelList`.
class SfLevelList extends StatelessWidget {
  const SfLevelList({super.key, required this.children});

  final List<Widget> children;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          children[i],
        ],
      ],
    );
  }
}

/// **Le bandeau d'objectif** — la bande bleue pleine de la maquette v2 :
/// cocarde, intitulé + valeur, puis le compteur « 3 / 4 », ses pastilles et le
/// mot qu'elles comptent.
///
/// 🛑 [count] et [total] sont **passés**, jamais comptés ici — et [total] pose
/// le nombre de pastilles, donc l'écran ne peut pas en dessiner quatre quand le
/// serveur en publie trois.
///
/// ⚠️ **Remplace `SfGoalRibbon`** (bande claire à filet, maquette v1).
/// Miroir web : `GoalBanner`.
class SfGoalBanner extends StatelessWidget {
  const SfGoalBanner({
    super.key,
    required this.label,
    required this.value,
    this.count,
    this.total,
    this.caption,
  });

  final String label;
  final String value;

  /// Le nombre de mesures faites. `null` retire le compteur entier.
  final int? count;
  final int? total;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final faites = count;
    final sur = total;
    final pastilles = faites != null && sur != null && sur > 0;
    final doux = AppColors.white.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          // La cocarde : trois cercles concentriques, en pur dégradé radial.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 2,
              ),
              gradient: const RadialGradient(
                colors: [
                  AppColors.red,
                  AppColors.red,
                  AppColors.white,
                  AppColors.white,
                  AppColors.blueDark,
                  AppColors.blueDark,
                ],
                stops: [0, 0.30, 0.31, 0.58, 0.59, 1],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: doux,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppFonts.ui(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          if (pastilles) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$faites / $sur',
                  style: AppFonts.label(size: 15, color: AppColors.white),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < sur; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Container(
                        width: 14,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i < faites
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    caption!,
                    style: AppFonts.ui(size: 11, color: doux),
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

/// La note discrète de bas de carte (`.micro-note`) : une pastille « i » et une
/// phrase fine. Miroir web : `MicroNote`.
class SfMicroNote extends StatelessWidget {
  const SfMicroNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface3,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.info, size: 11, color: AppColors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppFonts.ui(
              size: 11.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// L'en-tête d'un panneau : son titre, et ce qu'il contient en sous-titre.
/// Miroir web : `PanelHead`.
class SfPanelHead extends StatelessWidget {
  const SfPanelHead({
    super.key,
    required this.title,
    this.sub,
    this.lead = false,
  });

  final String title;
  final String? sub;

  /// Variante **de tête de carte** (maquette « Où vous en êtes » v2) : titre
  /// éditorial plus grand et sous-titre en phrase de cadrage, là où la variante
  /// par défaut coiffe un bloc dans une page de résultats.
  ///
  /// 🛑 Une **variante**, pas une seconde primitive. Miroir web :
  /// `PanelHead lead`.
  final bool lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.display(
            size: lead ? 22 : 19,
            weight: FontWeight.w700,
            height: lead ? 1.1 : 1.2,
          ),
        ),
        if (sub != null) ...[
          SizedBox(height: lead ? 6 : 3),
          Text(
            sub!,
            style: AppFonts.ui(
              size: lead ? 13 : 11.5,
              weight: lead ? FontWeight.w400 : FontWeight.w700,
              color: AppColors.muted,
              height: lead ? 1.35 : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// **Le héros d'une page de résultats** — le `.result-hero` de la maquette :
/// fond sombre de marque, le palier en très gros, l'objectif à droite, une
/// pastille d'évolution et une note de portée.
///
/// 🛑 **Aucune valeur n'est dérivée ici** : palier, objectif et pastille
/// arrivent composés d'un fait servi. Miroir web : `ResultHero`.
class SfResultHero extends StatelessWidget {
  const SfResultHero({
    super.key,
    required this.label,
    required this.level,
    required this.goalLabel,
    required this.goal,
    this.trend,
    this.note,
  });

  final String label;
  final String level;
  final String goalLabel;

  /// `null` quand aucune démarche n'est déclarée : rien vers quoi situer.
  final String? goal;

  /// `null` quand l'évolution est inconnue — surtout pas un « = » consolant.
  final String? trend;

  final String? note;

  @override
  Widget build(BuildContext context) {
    final pale = AppColors.white.withValues(alpha: 0.78);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.premium,
          boxShadow: AppShadows.md,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -46,
              top: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.ui(
                      size: 12,
                      weight: FontWeight.w800,
                      color: pale,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          level,
                          style: AppFonts.display(
                            size: 46,
                            weight: FontWeight.w700,
                            color: AppColors.white,
                            height: 0.95,
                          ),
                        ),
                      ),
                      if (goal != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              goalLabel,
                              style: AppFonts.ui(size: 12, color: pale),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              goal!,
                              style: AppFonts.ui(
                                size: 17,
                                weight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (trend != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        trend!,
                        style: AppFonts.ui(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      note!,
                      style: AppFonts.ui(size: 11.5, color: pale, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un point de la courbe : sa date, son palier, et sa ligne dans l'échelle.
class SfChartPoint {
  const SfChartPoint({
    required this.date,
    required this.level,
    required this.row,
  });

  /// Abscisse lisible (« 11 sept. »).
  final String date;

  /// Le palier, tel qu'il s'écrit sur la pastille.
  final String level;

  /// Index dans l'échelle, 0 = le palier le plus haut. **Passé, jamais deviné.**
  final int row;
}

/// **La courbe d'évolution** d'une épreuve.
///
/// 🛑 **Aucune interpolation, aucune moyenne** : un point par évaluation
/// **servie**, posé sur l'échelle de paliers que l'appelant lui donne. L'axe ne
/// porte aucun chiffre — seulement des paliers.
///
/// Miroir web : `LevelChart`.
class SfLevelChart extends StatelessWidget {
  const SfLevelChart({
    super.key,
    required this.ladder,
    required this.points,
    required this.activeIndex,
    required this.onSelect,
  });

  /// Du plus haut au plus bas (« B2 », « B1 », « A2 »).
  final List<String> ladder;

  /// Du plus ancien au plus récent.
  final List<SfChartPoint> points;

  final int activeIndex;
  final ValueChanged<int> onSelect;

  static const double _axis = 34;
  static const double _plotHeight = 132;
  static const double _datesHeight = 20;

  @override
  Widget build(BuildContext context) {
    final rows = math.max(ladder.length - 1, 1);
    final cols = math.max(points.length - 1, 1);
    double yOf(int row) => ladder.length > 1 ? row / rows : 0.5;
    double xOf(int i) => points.length > 1 ? i / cols : 0.5;

    return SizedBox(
      height: _plotHeight + _datesHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = math.max(constraints.maxWidth - _axis, 1.0);
          return Stack(
            children: [
              for (var i = 0; i < ladder.length; i++)
                Positioned(
                  left: 0,
                  top: yOf(i) * _plotHeight - 6,
                  child: SizedBox(
                    width: _axis - 6,
                    child: Text(
                      ladder[i],
                      style: AppFonts.label(size: 10, color: AppColors.muted),
                    ),
                  ),
                ),
              Positioned(
                left: _axis,
                top: 0,
                width: plotWidth,
                height: _plotHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(plotWidth, _plotHeight),
                      painter: _SfChartPainter(
                        rows: [for (var i = 0; i < ladder.length; i++) yOf(i)],
                        line: [
                          for (var i = 0; i < points.length; i++)
                            Offset(xOf(i), yOf(points[i].row)),
                        ],
                      ),
                    ),
                    for (var i = 0; i < points.length; i++)
                      Positioned(
                        left: xOf(i) * plotWidth - 14,
                        top: yOf(points[i].row) * _plotHeight - 14,
                        child: Semantics(
                          label:
                              '${points[i].date} : niveau ${points[i].level}',
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(i),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.blue,
                                      width: 4,
                                    ),
                                    boxShadow: i == activeIndex
                                        ? [
                                            BoxShadow(
                                              color: AppColors.blue
                                                  .withValues(alpha: 0.14),
                                              spreadRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < points.length; i++)
                Positioned(
                  // 🛑 **Bornée** : sans clamp, la date du dernier point sort du
                  // cadre et le `Stack` la rogne — c'est justement la mesure la
                  // plus récente, celle qu'on vient lire.
                  left: (_axis + xOf(i) * plotWidth - 30)
                      .clamp(0.0, math.max(constraints.maxWidth - 60, 0.0)),
                  top: _plotHeight + 4,
                  width: 60,
                  child: Text(
                    points[i].date,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SfChartPainter extends CustomPainter {
  const _SfChartPainter({required this.rows, required this.line});

  /// Ordonnées relatives (0-1) des lignes de repère.
  final List<double> rows;

  /// Les points, en coordonnées relatives (0-1).
  final List<Offset> line;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line2
      ..strokeWidth = 1;
    for (final r in rows) {
      final y = r * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (line.length < 2) return;
    final stroke = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < line.length; i++) {
      final p = Offset(line[i].dx * size.width, line[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_SfChartPainter old) =>
      old.rows != rows || old.line != line;
}

/// La rangée de filtres d'une liste. 🛑 **Les options sont servies par
/// l'appelant** : le kit ne sait pas ce qu'il filtre.
///
/// Miroir web : `FilterChips`.
class SfFilterChips<T> extends StatelessWidget {
  const SfFilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({T id, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _SfFilterChip(
              label: options[i].label,
              selected: options[i].id == value,
              onTap: () => onChanged(options[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SfFilterChip extends StatelessWidget {
  const _SfFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.surface3,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: AppFonts.ui(
              size: 11.5,
              weight: FontWeight.w800,
              color: selected ? AppColors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// **Une ligne d'historique dépliable** : pictogramme, intitulé + date, palier,
/// et un détail qui s'ouvre au toucher.
///
/// Miroir web : `HistoryRow`.
class SfHistoryRow extends StatelessWidget {
  const SfHistoryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.date,
    required this.level,
    required this.detail,
    required this.open,
    required this.onToggle,
  });

  final IconData icon;
  final String title;

  /// `null` quand le serveur n'a pas de date — on n'en invente pas.
  final String? date;

  final String level;
  final Widget detail;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Material(
      color: open ? AppColors.blueLight : AppColors.blueSoft,
      borderRadius: radius,
      child: InkWell(
        onTap: onToggle,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.ui(
                            size: 13,
                            weight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            date!,
                            style: AppFonts.ui(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    level,
                    style: AppFonts.label(size: 15, color: AppColors.blue),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: detail,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// L'encart ambre de pied de liste (`.footer-info`) : ce que la liste au-dessus
/// compte, et ce qu'elle ne compte pas.
///
/// Miroir web : `InfoNote`.
class SfInfoNote extends StatelessWidget {
  const SfInfoNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 14, color: AppColors.amberDark),
          ),
          const SizedBox(width: 9),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// =============================================================================
// PARCOURS TCF — la file d'etapes (spec §12-13)
// =============================================================================

/// L'etat d'une etape du **parcours TCF**, tel que le serveur le sert
/// (`JourneyStepDto.status`).
///
/// 🛑 **Rien n'est deduit ici** : ni d'un compteur, ni d'une position dans la
/// liste. [skipped] — « Deja maitrisee » / « Deja travaillee » — est une nuance
/// de rendu de [done] que le **serveur** derive de l'ordre de cloture, et
/// [current] depend du verrou du candidat. Un front qui les recalculerait
/// finirait par designer une autre etape que le serveur.
///
/// ⚠️ **Distinct de [SfStepState]**, qui decrit une etape de *tache* (les
/// 5 petits sujets d'une competence). Deux objets, deux vocabulaires : les
/// confondre ferait cocher en vert une serie finie qui n'a rien prouve.
///
/// ⚠️ Miroir de `JourneyState` (`web .../sejour/SejourKit.tsx`).
enum SfJourneyState { done, skipped, current, upcoming }

/// La nature d'une etape, pour son marqueur.
///
/// 🛑 Un **examen** porte un double cercle et non un rond plein : c'est un
/// *checkpoint*, pas une tache de plus — le candidat doit le reperer de loin
/// dans la file.
enum SfJourneyKind { step, exam }

/// Une ligne du parcours.
class SfJourneyRow extends StatelessWidget {
  const SfJourneyRow({
    super.key,
    required this.title,
    required this.state,
    this.subtitle,
    this.kind = SfJourneyKind.step,
    this.badge,
    this.locked = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final SfJourneyState state;
  final SfJourneyKind kind;

  /// **Servi par l'appelant** — « MAINTENANT », « EXAMEN », « Deja maitrisee ».
  /// Le kit ne compose aucune phrase.
  final String? badge;

  /// L'etape ne peut pas etre menee a son terme avec l'acces du candidat.
  /// 🛑 **Elle reste a sa place** : on ajoute un cadenas, on ne deplace ni ne
  /// masque rien (R16).
  final bool locked;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done =
        state == SfJourneyState.done || state == SfJourneyState.skipped;
    final current = state == SfJourneyState.current;
    final exam = kind == SfJourneyKind.exam && !done;
    final ligne = Container(
      padding: const EdgeInsets.fromLTRB(0, 9, 10, 9),
      decoration: current
          ? BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.greenLight
                  : current
                      ? AppColors.blue
                      : exam
                          ? AppColors.blueSoft
                          : AppColors.white,
              shape: BoxShape.circle,
              border: current
                  ? null
                  : Border.all(
                      color: done
                          ? AppColors.greenBorder
                          : exam
                              ? AppColors.blue
                              : AppColors.line,
                      width: exam ? 1.5 : 1,
                    ),
            ),
            child: Icon(
              done
                  ? LucideIcons.check
                  : exam
                      ? LucideIcons.target
                      : current
                          ? LucideIcons.arrowRight
                          : LucideIcons.circle,
              size: 15,
              color: done
                  ? AppColors.green
                  : current
                      ? AppColors.white
                      : exam
                          ? AppColors.blue
                          : AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(
                    size: 14,
                    color: done ? AppColors.muted : AppColors.ink,
                    weight: current
                        ? FontWeight.w800
                        : done
                            ? FontWeight.w600
                            : FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppFonts.ui(size: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (locked) ...[
            const SizedBox(width: 8),
            const Icon(LucideIcons.lock, size: 14, color: AppColors.muted),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: done ? AppColors.greenBorder : AppColors.line,
                  ),
                ),
                child: Text(
                  badge!.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: AppFonts.label(
                    size: 10,
                    color: done ? AppColors.green : AppColors.blue,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return ligne;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ligne,
    );
  }
}

/// La file d'etapes, avec son **rail vertical**.
///
/// 🛑 **L'ordre est celui du serveur**, jamais retrie : la position d'une etape
/// *est* la decision d'ordonnancement que le parcours a prise, et elle ne se
/// recalcule pas.
class SfJourneyList extends StatelessWidget {
  const SfJourneyList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        // Le rail s'arrete AVANT la premiere pastille et APRES la derniere,
        // sinon il deborde en haut et en bas de la liste.
        Positioned(
          left: 13,
          top: 23,
          bottom: 23,
          child: Container(width: 2, color: AppColors.line),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ],
    );
  }
}
