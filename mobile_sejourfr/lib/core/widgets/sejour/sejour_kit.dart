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
  const SfSectionTitle(
    this.text, {
    super.key,
    this.flush = false,
    this.mono = false,
    this.lead = false,
    this.action,
  });

  final String text;

  /// `true` quand le titre est déjà dans un bloc en gouttière : il ne reprend
  /// pas la marge latérale.
  final bool flush;

  /// L'intertitre en **petites capitales** (« À FAIRE »).
  ///
  /// 🛑 **Une variante, pas une primitive de plus** : c'est le même titre de
  /// section, dans le registre technique que le kit emploie déjà pour ses
  /// œils-de-bœuf. Miroir web : `Section mono`.
  final bool mono;

  /// L'intertitre **de tête d'écran** (« Où vous en êtes ») : plus grand, pour
  /// une section qui ouvre un tableau de bord. Miroir web : `Section lead`.
  final bool lead;

  /// Un lien discret aligné à droite du titre (« Mon plan »). 🛑 Une variante
  /// du titre, pas une seconde en-tête. Miroir web : `Section action`.
  final SfSectionAction? action;

  @override
  Widget build(BuildContext context) {
    final titre = Text(
      text,
      style: mono
          ? AppFonts.label(size: 11, color: AppColors.muted)
          : lead
              ? AppFonts.ui(size: 24, weight: FontWeight.w800, height: 1.15)
              : AppFonts.display(size: 16, weight: FontWeight.w700),
    );
    final lien = action;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          flush ? 0 : 16, 0, flush ? 0 : 16, lien != null || lead ? 12 : 10),
      child: lien == null
          ? titre
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: titre),
                const SizedBox(width: 12),
                InkWell(
                  onTap: lien.onTap,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Text(
                    lien.label,
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Le lien de tête d'une section ([SfSectionTitle.action]).
class SfSectionAction {
  const SfSectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

/// Une section : un titre optionnel puis son contenu, avec l'espace au-dessus.
class SfSection extends StatelessWidget {
  const SfSection({
    super.key,
    this.title,
    required this.child,
    this.flush = false,
    this.mono = false,
    this.lead = false,
    this.action,
  });

  final String? title;
  final Widget child;
  final bool flush;

  /// Le titre en petites capitales. Voir [SfSectionTitle.mono].
  final bool mono;

  /// Le titre de tête d'écran. Voir [SfSectionTitle.lead].
  final bool lead;

  /// Le lien à droite du titre. Voir [SfSectionTitle.action].
  final SfSectionAction? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: sfSectionGap, left: flush ? 16 : 0, right: flush ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            SfSectionTitle(
              title!,
              flush: flush,
              mono: mono,
              lead: lead,
              action: action,
            ),
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
      padding: padding ??
          (hero
              ? const EdgeInsets.fromLTRB(18, 22, 18, 18)
              : const EdgeInsets.fromLTRB(16, 18, 16, 18)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(hero ? 28 : AppRadii.xl),
        border: border == null ? null : Border.all(color: border),
        boxShadow:
            border == null ? (hero ? AppShadows.md : AppShadows.card) : null,
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
          _SfGoalValue(value),
        ],
      );
}

/// La valeur d'une cellule de [SfGoalStrip] — un palier (« B2 ») ou une
/// démarche (« Naturalisation », « Carte de résident »).
///
/// 🛑 **Jamais coupée au milieu d'un mot.** Flutter casse un mot plus large
/// que sa colonne : à grande taille d'affichage, « Naturalisation » se lisait
/// « Naturalis / ation » à côté de la flèche. La taille se réduit donc jusqu'à
/// ce que le **mot le plus long** tienne, et le retour à la ligne ne se fait
/// plus qu'entre deux mots. Miroir web : `GoalStrip` (`--goal-word`).
class _SfGoalValue extends StatelessWidget {
  const _SfGoalValue(this.value);

  final String value;

  static const double _size = 32;

  /// Marge d'arrondi : un mot mesuré « juste à la largeur » peut encore casser.
  static const double _safety = 0.97;

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.display(
        size: _size, weight: FontWeight.w600, color: AppColors.blue);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var size = _size;
        if (width.isFinite && width > 0) {
          final longest = _longestWordWidth(context, style);
          if (longest > width * _safety) {
            size = _size * width * _safety / longest;
          }
        }
        return Text(
          value,
          textAlign: TextAlign.center,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }

  double _longestWordWidth(BuildContext context, TextStyle style) {
    var longest = 0.0;
    for (final word in value.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > longest) longest = painter.width;
      painter.dispose();
    }
    return longest;
  }
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
    this.lead,
    this.caption,
    this.icon = LucideIcons.arrowRight,
  });

  final String label;
  final VoidCallback? onPressed;
  final SfButtonVariant variant;

  /// La ligne **au-dessus** du bouton — ce que l'action va coûter (« À partir
  /// de 9,99 € achat unique »).
  ///
  /// 🛑 **Une variante de [caption], pas une primitive de plus** : le même
  /// bouton, avec de quoi décider juste avant de le presser. [caption] reste ce
  /// qui se lit **après**. `null` ⇒ rien à sa place — c'est le rendu exact d'un
  /// catalogue injoignable. Miroir web : `Cta.lead`.
  final String? lead;

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
        if (lead != null) ...[
          Text(
            lead!,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
        ],
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
/// Par défaut il n'y a **aucun chiffre** dans l'anneau, le compteur vit sur la
/// ligne. (`ProgressRing`, l'ancien anneau à pourcentage central, est supprimé
/// avec l'écran Progrès, son dernier lecteur, le 2026-09-24.)
///
/// **Variante « écran de progression » (2026-09-24)** : [label] écrit au centre
/// un chiffre **déjà composé** (« 85 % », le taux servi d'un examen civique), et
/// [reached] porte le fait **servi** « seuil atteint » — vert s'il l'est, bleu
/// sinon. 🛑 Le kit ne compare le ratio à aucun seuil : sans [reached], seul un
/// anneau plein passe au vert, comme avant. Miroir web : `Ring label reached`.
class SfRing extends StatelessWidget {
  const SfRing({
    super.key,
    required this.ratio,
    this.size = 40,
    this.stroke = 4,
    this.label,
    this.reached,
  });

  final double ratio;
  final double size;
  final double stroke;

  /// Le texte du centre, composé par l'appelant. `null` = anneau muet.
  final String? label;

  /// Le seuil est-il atteint ? **Servi**, jamais déduit de [ratio].
  final bool? reached;

  @override
  Widget build(BuildContext context) {
    final part =
        ratio.isNaN || ratio.isInfinite ? 0.0 : ratio.clamp(0, 1).toDouble();
    final vert = reached ?? part >= 1;
    final texte = label;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SfRingPainter(
          part: part,
          stroke: stroke,
          color: vert ? AppColors.green : AppColors.blue,
        ),
        child: texte == null
            ? null
            : Center(
                child: Text(
                  texte,
                  style: AppFonts.display(
                    size: size * 0.2,
                    weight: FontWeight.w800,
                    color: AppColors.blueDark,
                  ),
                ),
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

/* ⚠️ **`SfProgressMini` est supprimée** (2026-09-19), avec sa table de
   couleurs `_sfBarColor` : la jauge continue ne servait plus qu'à la ligne
   civique de « Où vous en êtes », qui rend désormais son état servi avec le
   **même traité segmenté que l'échelle TCF** ([SfLevelLadder]). Refonte =
   suppression de l'ancien. [SfBarTone] reste — il teinte encore la pastille de
   statut de [SfLevelCard]. Miroir web : `ProgressMini`, supprimée dans la même
   passe. */

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

/* ⚠️ **`SfLockRow` et `SfLockItem` sont SUPPRIMÉES** (2026-09-20), avec leur
   miroir web (`LockRow`, `LockItem`, `LockList` et leurs classes CSS).

   Elles ne servaient qu'à l'**anatomie gratuite** des deux Plans : les trois
   bénéfices verrouillés du TCF (partis avec A114) puis les cinq du civique. Les
   deux écrans gratuits portent désormais l'anatomie de l'abonné, où le verrou se
   dit par un **cadenas servi** et un **geste** (`SfJourneyRow locked` +
   `kJourneyStepUnlockLink`) — jamais par une liste de choses qu'on n'a pas.
   Ne pas les réintroduire. */

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
                      label: rows[i].pill!,
                      tone: (rows[i].tone ?? SfTone.warn).asBarTone),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Pilule d'état, fond clair + texte du même ton.
///
/// ⚠️ **Brique partagée** : plusieurs écrans l'appellent, et sa taille par
/// défaut est celle de la maquette. [dense] est la seule variante — une
/// pastille plus petite pour une ligne d'en-tête serrée, où c'est le **nom de
/// l'épreuve** qui doit garder la largeur ([SfBlocAccordion], D-21). Aucun
/// autre appelant n'est concerné : le défaut reste `false`.
///
/// Miroir web : `Pill` (`.pill` / `.pill.dense`).
/// Le même ton, lu sur l'échelle qui porte aussi le bleu.
///
/// ⚠️ [SfTone] est un **sous-ensemble** de [SfBarTone] : la conversion ne perd
/// rien, elle évite seulement de recopier un `switch` à chaque appel.
extension SfToneAsBar on SfTone {
  SfBarTone get asBarTone => switch (this) {
        SfTone.ok => SfBarTone.ok,
        SfTone.warn => SfBarTone.warn,
        SfTone.hot => SfBarTone.hot,
        SfTone.muted => SfBarTone.muted,
      };
}

/// Les fonds clairs de la pastille : l'aplat et le texte sont les tokens exacts
/// du kit, miroir des règles `.pill.ok` … `.pill.pillNow` du web.
Color _sfPillSoft(SfBarTone tone) => switch (tone) {
      SfBarTone.ok => AppColors.greenLight,
      SfBarTone.now => AppColors.blueLight,
      SfBarTone.warn => AppColors.amberLight,
      SfBarTone.hot => AppColors.redLight,
      SfBarTone.muted => AppColors.surface3,
    };

Color _sfPillText(SfBarTone tone) => switch (tone) {
      SfBarTone.ok => AppColors.greenDark,
      SfBarTone.now => AppColors.blueDark,
      SfBarTone.warn => AppColors.amberDark,
      SfBarTone.hot => AppColors.redDark,
      SfBarTone.muted => AppColors.muted,
    };

class SfPill extends StatelessWidget {
  const SfPill({
    super.key,
    required this.label,
    required this.tone,
    this.dense = false,
  });

  final String label;

  /// ⚠️ **[SfBarTone], pas [SfTone]** (2026-09-20) : la pastille a besoin du
  /// bleu ([SfBarTone.now]) pour le repère de domaine d'une étape
  /// (« CO · B2 »). Les appelants existants passent un ton qui existe dans les
  /// deux échelles.
  final SfBarTone tone;

  /// Variante resserrée (`.status` de `docs/progression/plan_cycle.html` :
  /// 9,5 px, poids 900, `padding: 5px 8px`), réservée aux lignes d'en-tête où
  /// la largeur va au titre. **Ne change pas** la pastille par défaut.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: dense ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: _sfPillSoft(tone),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppFonts.ui(
          size: dense ? 9.5 : 11,
          weight: dense ? FontWeight.w900 : FontWeight.w700,
          color: _sfPillText(tone),
        ),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
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
                  child: Text(
                    label,
                    style: AppFonts.ui(
                      size: 14.5,
                      weight: FontWeight.w600,
                      color: selected ? AppColors.blueDark : AppColors.ink,
                    ),
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
    this.lead,
    this.badges = const <String>[],
  });

  final VoidCallback? onBack;
  final String? kicker;
  final String title;

  /// La phrase de cadrage sous le titre (`.hero-copy` de la maquette).
  ///
  /// 🛑 Une **variante** de l'en-tete, pas une primitive de plus : un ecran qui
  /// s'annonce en trois lignes — oeil-de-boeuf, titre, phrase — est le meme
  /// motif que celui qui s'annonce en deux. `null` ⇒ rien a sa place.
  final String? lead;

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
                if (lead != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    lead!,
                    textAlign: TextAlign.start,
                    style: AppFonts.ui(
                      size: 13.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
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

/// **La tete d'un ecran de transition** : une croix de fermeture a gauche, un
/// oeil-de-boeuf a droite.
///
/// 🛑 **Ce n'est pas une variante de [SfTop]**, et c'est la difference qui
/// compte : [SfTop] annonce une **page** (retour en fleche, titre, bascule de
/// module dans son [SfTopSlot]) ; celui-ci coiffe un ecran **qu'on ferme** —
/// une etape posee par-dessus, sans titre, dont le contenu commence par son
/// heros. Les deux maquettes de l'ecran de deblocage du Plan le montrent ainsi.
///
/// Miroir web : `SheetHead`.
class SfSheetHead extends StatelessWidget {
  const SfSheetHead({
    super.key,
    required this.eyebrow,
    required this.onClose,
    this.closeLabel = 'Fermer',
  });

  final String eyebrow;
  final VoidCallback onClose;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: closeLabel,
            child: Transform.translate(
              offset: const Offset(-6, 0),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(LucideIcons.x, size: 22, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            eyebrow.toUpperCase(),
            textAlign: TextAlign.end,
            style: AppFonts.mono(size: 11, color: AppColors.muted),
          ),
        ],
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

/// La carte de statistiques en colonnes (`.sf-stat-grid`), et le `.stats` de
/// `histo_cycle.html` quand elle est posée sur un fond de marque.
///
/// Le nombre de colonnes suit la liste : une statistique que le serveur ne sert
/// pas ne s'affiche pas plutôt que de s'inventer.
///
/// 🛑 **Rien n'est compté ici.** [SfStat.value] arrive déjà en texte : cette
/// brique ne somme rien et ne classe rien.
///
/// Miroir web : `StatGrid`.
class SfStatGrid extends StatelessWidget {
  const SfStatGrid({
    super.key,
    required this.stats,
    this.onHero = false,
    this.accentIndex,
  });

  final List<SfStat> stats;

  /// Les compteurs sont posés **sur un fond de marque** ([SfHeroBanner]) :
  /// tuiles translucides, valeur blanche, libellé adouci, tout calé à gauche.
  /// Sans lui, la rangée est nue sur fond clair, valeur bleue et texte centré.
  final bool onHero;

  /// Le compteur **accentué** de la maquette (celui du milieu). 🛑 **Passé, et
  /// c'est une décision d'ÉCRAN** : le kit n'élit pas le chiffre important.
  final int? accentIndex;

  @override
  Widget build(BuildContext context) {
    final rangee = Row(
      crossAxisAlignment:
          onHero ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: onHero
                ? _SfHeroStat(stat: stats[i], accent: i == accentIndex)
                : Column(
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
    // 🛑 **`stretch` exige une hauteur BORNÉE.** Les tuiles de marque doivent
    // toutes faire la hauteur de la plus haute — c'est ce que la maquette
    // montre —, mais dans une `ListView` la rangée reçoit
    // `0.0 <= h <= Infinity` : `stretch` transmet alors l'infini aux tuiles,
    // les contraintes deviennent invalides et **l'écran entier tombe** (blanc
    // en release). `IntrinsicHeight` mesure d'abord la plus haute et borne la
    // rangée. Coût négligeable ici : trois tuiles de texte court.
    return onHero ? IntrinsicHeight(child: rangee) : rangee;
  }
}

/// Une tuile de compteur posée sur un fond de marque (`.hero .stat`).
class _SfHeroStat extends StatelessWidget {
  const _SfHeroStat({required this.stat, required this.accent});

  final SfStat stat;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: AppFonts.ui(
              size: 19,
              weight: FontWeight.w700,
              // 🛑 Le rouge clair n'est pas un signal d'urgence : c'est
              // l'accent de marque posé sur le chiffre que l'ÉCRAN met en
              // avant.
              color: accent ? AppColors.redBright : AppColors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.label,
            style: AppFonts.ui(
              size: 10.5,
              weight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.70),
              height: 1.25,
            ),
          ),
        ],
      ),
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

/* ==========================================================================
   Maquette « Où vous en êtes » + « Vos résultats » (propriétaire, 2026-09-16)

   🛑 Miroirs de `LevelLadder`, `LevelCard`, `LevelCardGrid`, `GoalBanner`,
   `MicroNote`, `PanelHead`, `ResultHero`, `LevelChart`, `FilterChips`,
   `HistoryRow` et `InfoNote` côté web. Un motif qui bouge d'un côté bouge de
   l'autre dans la même passe.

   ⚠️ « Où vous en êtes » a été refait deux fois : liste verticale dans une
   seule carte (v2, 2026-09-16), puis GRILLE de cartes séparées, une par
   épreuve (v3, 2026-09-24). `SfLevelRow`, `SfLevelList` et `SfLadderLegend`
   sont **supprimées** — refonte = suppression de l'ancien.
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
/// ⚠️ **Elle sert aussi la ligne CIVIQUE** depuis le 2026-09-19 (« afficher le
/// cran de la même manière que le TCF ») : trois crans au lieu de quatre, les
/// états **mesurés** de `CivicThemeState` (`accueilEchelonsCivique`), et
/// **aucun cran d'objectif** — le civique n'en sert pas. La rangée s'adapte au
/// nombre de crans reçus.
///
/// Miroir web : `LevelLadder`.
class SfLevelLadder extends StatelessWidget {
  const SfLevelLadder({
    super.key,
    required this.steps,
    required this.label,
    this.dim = false,
    this.labels = true,
  });

  final List<SfLadderStep> steps;

  /// Ce que l'échelle DIT. Jamais dérivé ici.
  final String label;

  /// Épreuve jamais mesurée : les crans passent en contour, sans remplissage.
  ///
  /// 🛑 **Passé, jamais deviné** d'un cran vide — une épreuve « &lt;A1 » n'a
  /// elle non plus aucun cran rempli, et ce n'est pas la même chose.
  final bool dim;

  /// Les libellés sous les crans (maquette v3 : chaque carte porte les
  /// siens). `false` quand ils ne tiennent pas : les trois états civiques
  /// (« À renforcer ») débordent d'une demi-carte, et la pastille de statut de
  /// la carte dit déjà l'état servi. Miroir web : `LevelLadder labels`.
  final bool labels;

  static const double gap = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: _SfLadderBar(step: steps[i], dim: dim)),
              ],
            ],
          ),
          if (labels) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(child: _ladderLabel(steps[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Le palier ACTUEL en bleu, le palier VISÉ (s'il n'est pas l'actuel) en
  /// rouge, le reste en gris — la règle de `.ladderLabels` côté web.
  Widget _ladderLabel(SfLadderStep step) {
    final vise = !step.current && step.goal;
    final couleur = step.current
        ? AppColors.blue
        : vise
            ? AppColors.red
            : AppColors.muted2;
    return Text(
      step.label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: AppFonts.label(size: 10, color: couleur).copyWith(
        fontWeight:
            step.current || vise ? FontWeight.w700 : FontWeight.w500,
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
          border: Border.all(color: AppColors.redMuted, width: 1.5),
        ),
      );
    }
    final rempli = step.state == SfLadderState.done;
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: rempli
            ? AppColors.blueMuted
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

/// **La carte d'une épreuve** — maquette « niveau par épreuve » v3 du
/// propriétaire (2026-09-24) : repère court en pastille mono et pictogramme en
/// tête, intitulé discret, palier en très gros, statut à pastille colorée,
/// l'échelle et ses libellés, puis un filet et l'action, **épinglée en bas**.
///
/// 🛑 **Cette brique ne classe rien.** Tout lui arrive **composé** par
/// `accueilEpreuve*` (`screens/progres/progres_labels.dart`) — palier, statut,
/// ton, crans, CTA.
///
/// ⚠️ **Deux jeux de données pour une seule anatomie** : en TCF, [level] porte
/// le palier CECRL servi ; en civique, aucun palier n'est servi, [level] est
/// `null` et la carte n'en montre pas — on n'en fabrique aucun.
///
/// ⚠️ **Remplace `SfLevelRow`, `SfLevelList` et `SfLadderLegend`** (liste
/// verticale dans une seule carte, maquette v2) — refonte = suppression de
/// l'ancien. Miroir web : `LevelCard`.
class SfLevelCard extends StatelessWidget {
  const SfLevelCard({
    super.key,
    required this.mark,
    required this.icon,
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

  /// Repère court (« CO », ou le rang servi d'un thème).
  final String mark;

  /// Le pictogramme de l'épreuve ou du thème, choisi par l'appelant.
  final IconData icon;

  final String title;

  /// L'état en un mot. `null` = rien à dire, jamais « rien à faire ».
  final String? status;

  /// Le ton de la pastille de statut.
  final SfBarTone tone;

  /// Le palier servi, ou le mot d'une absence de mesure. `null` retire la
  /// ligne : le civique n'a aucun palier CECRL servi.
  final String? level;

  /// Y a-t-il une mesure derrière [level] ?
  ///
  /// 🛑 **Passé, jamais deviné du texte** : comparer un libellé pour décider
  /// d'une couleur ferait dépendre l'apparence d'une chaîne reformulable.
  final bool measured;

  /// L'échelle ([SfLevelLadder]). `null` quand rien ne la sert.
  final Widget? scale;

  final String cta;

  /// Le CTA devient un bouton plein — l'action qui manque, pas celle qui relit.
  final bool ctaPrimary;

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    final statut = status;
    final palier = level;
    return Material(
      // Une épreuve **jamais mesurée** se détache : c'est la seule carte qui
      // demande un geste pour exister. 🛑 Le fait est passé (`measured`), et il
      // ne se confond pas avec « <A1 », qui est une mesure.
      color: measured ? AppColors.white : AppColors.surface2,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      // Un repère d'épreuve est une étiquette technique.
                      child: Text(
                        mark,
                        style: AppFonts.label(size: 12.5, color: AppColors.blue),
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, size: 24, color: AppColors.blue),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                    height: 1.25,
                  ),
                ),
                if (palier != null)
                  // 🛑 Non mesuré : le mot de l'absence, en neutre et en petit.
                  // Le très gros noir est réservé à un palier réel — une absence
                  // de mesure en gros se lirait comme un résultat.
                  Padding(
                    padding: EdgeInsets.only(top: measured ? 4 : 10),
                    child: measured
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              palier,
                              maxLines: 1,
                              style: AppFonts.ui(
                                size: 44,
                                weight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -1.6,
                              ),
                            ),
                          )
                        : Text(
                            palier,
                            style: AppFonts.ui(
                              size: 15,
                              weight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                  ),
                if (statut != null) ...[
                  const SizedBox(height: 8),
                  _SfStatusDot(label: statut, tone: tone),
                ],
                if (scale != null) ...[
                  const SizedBox(height: 12),
                  scale!,
                ],
                // 🛑 **L'action épinglée en bas** : l'espace libre passe au-dessus
                // du filet, donc les barres et les CTA d'une même rangée restent
                // alignés quelle que soit la longueur des noms.
                const Spacer(),
                const SizedBox(height: 12),
                _SfLevelCardCta(cta: cta, primary: ctaPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La pastille de statut d'une carte : le ton **servi**, et le mot le redit —
/// la couleur n'est jamais le seul porteur de l'information.
class _SfStatusDot extends StatelessWidget {
  const _SfStatusDot({required this.label, required this.tone});

  final String label;
  final SfBarTone tone;

  @override
  Widget build(BuildContext context) {
    final couleur = _sfStatusColor(tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w600,
              color: couleur,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SfLevelCardCta extends StatelessWidget {
  const _SfLevelCardCta({required this.cta, required this.primary});

  final String cta;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    // 🛑 Le rouge n'apparaît que sur l'action qui MANQUE (évaluer une épreuve
    // jamais mesurée) — c'est la règle d'usage du Rouge France, pas un accent.
    if (primary) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          cta,
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.white,
            height: 1.25,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cta,
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.blue,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.arrowRight, size: 18, color: AppColors.blue),
        ],
      ),
    );
  }
}

/// La grille des cartes d'épreuve — **deux colonnes**, les cartes d'une même
/// rangée à la même hauteur ; une dernière carte impaire (les 5 thèmes
/// civiques) prend toute la rangée.
///
/// ⚠️ Le web passe à quatre cartes sur une rangée (cinq en 3 + 2) quand la
/// grille est large ; **rien à porter ici**, l'app est en portrait téléphone.
/// Une requête de conteneur n'est pas une primitive. Miroir web :
/// `LevelCardGrid`.
class SfLevelCardGrid extends StatelessWidget {
  const SfLevelCardGrid({super.key, required this.children});

  final List<Widget> children;

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final rangees = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final seule = i + 1 >= children.length;
      rangees.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: seule
                ? [Expanded(child: children[i])]
                : [
                    Expanded(child: children[i]),
                    const SizedBox(width: _gap),
                    Expanded(child: children[i + 1]),
                  ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rangees.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          rangees[i],
        ],
      ],
    );
  }
}

/// **Le bandeau d'objectif** — la bande bleue pleine de la maquette : cocarde,
/// intitulé + valeur, puis le compteur « 3 / 4 » en gros et le mot qu'il
/// compte.
///
/// 🛑 [count] et [total] sont **passés**, jamais comptés ici.
///
/// ⚠️ **Plus de pastilles sous le compteur** (maquette v3, 2026-09-24) : les
/// cartes juste en dessous montrent déjà, une par une, ce qui est évalué.
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
    final compte = faites != null && sur != null && sur > 0;
    final doux = AppColors.white.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          // La cocarde : trois cercles concentriques, en pur dégradé radial.
          Container(
            width: 40,
            height: 40,
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
                stops: [0, 0.36, 0.37, 0.70, 0.71, 1],
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
                    size: 13,
                    weight: FontWeight.w500,
                    color: doux,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppFonts.ui(
                    size: 18,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (compte) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$faites / $sur',
                  style: AppFonts.ui(
                    size: 22,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.1,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: AppFonts.ui(size: 12, color: doux),
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

/// L'encart ambre de pied de liste (`.footer-info`) : ce que la liste au-dessus
/// compte, et ce qu'elle ne compte pas.
///
/// Miroir web : `InfoNote`.
/// La nature d'un [SfInfoNote].
///
/// 🛑 **[check] n'est pas une couleur de plus** : c'est l'encart de
/// **validation** — il énonce la condition à remplir, pas une réserve, et
/// l'ambre du défaut se lirait comme un avertissement. Miroir web :
/// `InfoNote variant="check"`.
enum SfInfoNoteVariant { info, check }

class SfInfoNote extends StatelessWidget {
  const SfInfoNote({
    super.key,
    required this.child,
    this.variant = SfInfoNoteVariant.info,
  });

  final Widget child;
  final SfInfoNoteVariant variant;

  @override
  Widget build(BuildContext context) {
    final check = variant == SfInfoNoteVariant.check;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: check ? AppColors.blueLight : AppColors.amberLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: check ? AppColors.blueLight : AppColors.amberBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              check ? LucideIcons.check : LucideIcons.info,
              size: 14,
              color: check ? AppColors.blue : AppColors.amberDark,
            ),
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

/// **La variante de rendu d'une file d'etapes.**
///
/// - [standard] : la file de l'**ACCUEIL** et son rail continu — le rendu
///   historique, intouche (D-22 : « l'Accueil ne bouge pas d'un pixel »).
/// - [cycle] : le **corps deplie d'un bloc d'epreuve** du Plan, a la lettre de
///   `docs/progression/plan_cycle.html` — retrait de 65 px, pastilles 16 px sur
///   un rail segmente, separateurs pointilles, ligne d'action separee.
///
/// 🛑 **Elle se pose sur la LISTE, pas sur chaque ligne** : le rail, les
/// separateurs et la position des pastilles doivent s'accorder, et deux
/// appelants qui repondraient differemment produiraient une file bancale.
/// [SfJourneyRow] la lit par heritage (`_SfJourneySlot`) — une ligne rendue
/// hors d'une [SfJourneyList] (c'est le cas de l'Accueil, `home_screen.dart`)
/// retombe donc sur [standard] par construction.
///
/// ⚠️ Miroir de `JourneyVariant` (`web .../sejour/SejourKit.tsx`).
enum SfJourneyVariant { standard, cycle }

/// Ce que [SfJourneyList] pose sur chacun de ses enfants dans la variante
/// [SfJourneyVariant.cycle] : la variante, et **« est-ce la derniere ligne ? »**
/// — le pendant Dart du `:last-child` du CSS, qui decide du separateur
/// pointille et de la fin du rail.
class _SfJourneySlot extends InheritedWidget {
  const _SfJourneySlot({
    required this.variant,
    required this.last,
    required super.child,
  });

  final SfJourneyVariant variant;
  final bool last;

  static _SfJourneySlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SfJourneySlot>();

  @override
  bool updateShouldNotify(_SfJourneySlot oldWidget) =>
      oldWidget.variant != variant || oldWidget.last != last;
}

/// La pastille de rail de la maquette : 16×16, bordure 2 px.
///
/// 🛑 **Declaree une seule fois** : la ligne d'etape et l'encart d'examen la
/// dessinent tous les deux, et deux copies auraient fini par ne pas s'aligner
/// sur le meme rail.
///
/// Teintes : ce sont NOS tokens, choisis au plus pres de la maquette —
/// `#cfd5e5` (bordure au repos) ⇒ [AppColors.lineStrong] (#D4DAE6),
/// `#fff3f1` (halo de l'etape courante) ⇒ [AppColors.redLight].
Widget _sfCycleBullet({
  required bool done,
  required bool current,
  required bool exam,
}) {
  return Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done
          ? AppColors.green
          : current
              ? AppColors.red
              : AppColors.white,
      border: Border.all(
        color: done
            ? AppColors.green
            : current
                ? AppColors.white
                : exam
                    ? AppColors.blue
                    : AppColors.lineStrong,
        width: 2,
      ),
      boxShadow: current
          ? const [BoxShadow(color: AppColors.redLight, spreadRadius: 4)]
          : null,
    ),
    // La coche de la maquette, et rien d'autre : un pictogramme de 15 px dans
    // un rond de 16 ne serait qu'une tache. Le « ◎ » de l'examen est un point
    // dans un anneau, le rouge de l'etape courante un disque plein.
    child: done
        ? const Center(
            child: Icon(LucideIcons.check, size: 9, color: AppColors.white),
          )
        : exam
            ? const Center(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              )
            : null,
  );
}

/// Le separateur pointille entre deux etapes (`1px dashed` de la maquette).
/// Flutter n'a pas de bordure pointillee : on la peint.
class _SfDashedLine extends StatelessWidget {
  const _SfDashedLine();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _SfDashedLinePainter()),
      );
}

class _SfDashedLinePainter extends CustomPainter {
  const _SfDashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset(math.min(x + dash, size.width), 0.5),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_SfDashedLinePainter oldDelegate) => false;
}

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
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final SfJourneyState state;
  final SfJourneyKind kind;

  /// **Servi par l'appelant** — « MAINTENANT », « EXAMEN », « Deja maitrisee ».
  /// Le kit ne compose aucune phrase.
  final String? badge;

  /// Le libelle du lien d'action, **servi** (« Faire cette etape → »). Il n'a
  /// d'effet que dans la variante [SfJourneyVariant.cycle], ou la maquette met
  /// l'action sur sa propre ligne : la c'est **le lien** qui porte le geste,
  /// jamais la ligne entiere.
  final String? actionLabel;

  /// L'etape ne peut pas etre menee a son terme avec l'acces du candidat.
  /// 🛑 **Elle reste a sa place** : on ajoute un cadenas, on ne deplace ni ne
  /// masque rien (R16).
  final bool locked;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final slot = _SfJourneySlot.maybeOf(context);
    final done =
        state == SfJourneyState.done || state == SfJourneyState.skipped;
    final current = state == SfJourneyState.current;
    final exam = kind == SfJourneyKind.exam && !done;
    if (slot?.variant == SfJourneyVariant.cycle) {
      return _buildCycle(
        done: done,
        current: current,
        exam: exam,
        last: slot!.last,
      );
    }
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

  /// La ligne de la maquette : pastille sur le rail, titre 13 px, sous-titre,
  /// puis une **ligne d'action separee** a 9 px — le tag a gauche, le lien a
  /// droite.
  Widget _buildCycle({
    required bool done,
    required bool current,
    required bool exam,
    required bool last,
  }) {
    final corps = <Widget>[
      Text(
        title,
        style: AppFonts.ui(
          size: 13,
          height: 1.35,
          color: AppColors.ink,
          weight: current
              ? FontWeight.w800
              : done
                  ? FontWeight.w700
                  : FontWeight.w600,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: AppFonts.ui(size: 10.5, color: AppColors.muted, height: 1.4),
        ),
      ],
    ];

    final gauche = <Widget>[
      if (locked)
        const Icon(LucideIcons.lock, size: 13, color: AppColors.muted),
      if (locked && badge != null) const SizedBox(width: 6),
      if (badge != null)
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              // Le ton suit l'etat : un « Deja travaillee » en rouge dirait une
              // urgence qui n'existe pas.
              color: done
                  ? AppColors.greenLight
                  : current
                      ? AppColors.redLight
                      // La maquette n'a pas de tag sur une etape a venir ;
                      // « Examen » en porte un. `AppColors.line2` ⇄
                      // `--color-line-2` sont la meme valeur des deux cotes.
                      : AppColors.line2,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              badge!.toUpperCase(),
              style: AppFonts.label(
                size: 9,
                color: done
                    ? AppColors.greenDark
                    : current
                        ? AppColors.red
                        : AppColors.muted,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
    ];

    final lien = onTap != null && actionLabel != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionLabel!,
                style: AppFonts.ui(size: 10.5, color: AppColors.blue)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          )
        : null;

    if (gauche.isNotEmpty || lien != null) {
      corps
        ..add(const SizedBox(height: 9))
        ..add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(mainAxisSize: MainAxisSize.min, children: gauche),
              ),
              if (lien != null) ...[const SizedBox(width: 10), lien],
            ],
          ),
        );
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        // `.step:not(:last-child):after` — de 2 px sous la pastille jusqu'au
        // haut de la suivante (`top:35`, `height:calc(100% - 18px)`), donc il
        // traverse le pointille, comme dans la maquette. Recentre a -21 : la
        // maquette ecrit -20 et laisse le rail 1 px a droite du centre.
        if (!last)
          const Positioned(
            left: -21,
            top: 35,
            bottom: -17,
            child: SizedBox(width: 2, child: ColoredBox(color: AppColors.line)),
          ),
        Positioned(
          left: -28,
          top: 17,
          child: _sfCycleBullet(done: done, current: current, exam: exam),
        ),
        if (!last)
          const Positioned(left: 0, right: 0, bottom: 0, child: _SfDashedLine()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: corps,
          ),
        ),
      ],
    );
  }
}

/// L'encart d'examen **sur le rail** : la derniere « etape » d'un bloc, avec sa
/// pastille « ◎ ». Pose seul sous la liste, il perdrait son repere de
/// checkpoint.
class _SfJourneyExamRow extends StatelessWidget {
  const _SfJourneyExamRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Positioned(
          left: -28,
          top: 17,
          child: _sfCycleBullet(done: false, current: false, exam: true),
        ),
        // `.step` 14 px + `.examBox { margin-top: 2px }`.
        Padding(padding: const EdgeInsets.only(top: 16), child: child),
      ],
    );
  }
}

/// La file d'etapes, avec son **rail vertical**.
///
/// 🛑 **L'ordre est celui du serveur**, jamais retrie : la position d'une etape
/// *est* la decision d'ordonnancement que le parcours a prise, et elle ne se
/// recalcule pas.
///
/// [exam] est **la derniere etape de la file** — le [SfExamStepBox] du bloc.
/// Dans la variante [SfJourneyVariant.cycle], la maquette le range SUR le rail ;
/// il reste servi a part par le serveur (`bloc.exam`), et le kit ne decide ni
/// de sa presence ni de son contenu.
class SfJourneyList extends StatelessWidget {
  const SfJourneyList({
    super.key,
    this.children = const <Widget>[],
    this.variant = SfJourneyVariant.standard,
    this.exam,
  });

  final List<Widget> children;
  final SfJourneyVariant variant;
  final Widget? exam;

  @override
  Widget build(BuildContext context) {
    final examen = exam;
    if (variant == SfJourneyVariant.cycle) {
      final lignes = <Widget>[
        ...children,
        if (examen != null) _SfJourneyExamRow(child: examen),
      ];
      if (lignes.isEmpty) return const SizedBox.shrink();
      return Padding(
        // `.groupBody` de la maquette retire a 65 px. `SfBlocAccordion` en pose
        // deja 15 : la file complete les 50 qui manquent, et l'encart d'examen
        // s'aligne dessus.
        padding: const EdgeInsets.only(left: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lignes.length; i++)
              _SfJourneySlot(
                variant: SfJourneyVariant.cycle,
                last: i == lignes.length - 1,
                child: lignes[i],
              ),
          ],
        ),
      );
    }
    if (children.isEmpty && examen == null) return const SizedBox.shrink();
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
          children: [...children, if (examen != null) examen],
        ),
      ],
    );
  }
}

// =============================================================================
// PLAN — CYCLE ET FIN DE CYCLE (maquettes du proprietaire, 2026-09-18)
// `docs/progression/plan_cycle.html` ⇄ `docs/progression/cycle_termine.html`
//
// 🛑 Miroirs de `CycleProgress`, `BlocAccordion`, `ExamStepBox` et
// `NextStepCard` cote web (`app/_components/sejour/SejourKit.tsx` +
// `sejour.module.css`). Un motif qui bouge d'un cote bouge de l'autre dans la
// meme passe.
//
// Perimetre : la zone du Plan qui commence a « Votre parcours vers le B2 »
// (D-22). Tout ce qui est au-dessus — en-tete, bascule de module, bloc
// objectif, « A faire maintenant » — reste l'existant.
// =============================================================================

/// **L'avancement du cycle** — le `.cycleIntro` de `plan_cycle.html`, et le
/// `.progressBox` de `cycle_termine.html` quand il est termine.
///
/// 🛑 **Barre CONTINUE, et elle porte un chiffre.** C'est ce qui la distingue
/// des deux briques voisines, qu'il ne faut surtout pas remplacer par elle :
/// - [SfProgressMini] a un contrat qui **interdit tout chiffre** (« c'est une
///   part parcourue, jamais une note ni un pourcentage annonce au candidat ») ;
/// - [SfPathCard] a une barre **segmentee**, un segment par etape — elle decrit
///   un parcours de tache, pas l'avancement d'un cycle entier.
///
/// Le pourcentage est **derive de [done] / [total]**, deux faits servis : ce
/// n'est pas un etat pedagogique, seulement la lecture arithmetique du compteur
/// que [label] ecrit deja en mots.
///
/// Miroir web : `CycleProgress`.
class SfCycleProgress extends StatelessWidget {
  const SfCycleProgress({
    super.key,
    required this.label,
    required this.done,
    required this.total,
    this.badge,
    this.hint,
    this.complete = false,
  });

  /// Le compteur en mots (« 3 etapes sur 8 terminees »), **servi**.
  final String label;

  final int done;
  final int total;

  /// Le repere de cycle (« Cycle 2 »), **servi**. `null` ⇒ rien a droite.
  final String? badge;

  /// La phrase sous la barre, **servie**.
  final String? hint;

  /// L'etat 100 % : la barre se termine en vert et le pourcentage prend la
  /// place du badge, comme dans `cycle_termine.html`.
  ///
  /// 🛑 **Passe, jamais deduit de `done == total`** : un cycle peut afficher
  /// « 8 sur 8 » sans etre clos cote serveur (un examen reste a passer), et le
  /// kit n'a pas a en decider.
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final pct = complete && total <= 0 ? 100 : (ratio * 100).round();
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.ui(size: 13.5, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              if (complete)
                // Le cycle est clos : le chiffre prend la place du repere.
                Text(
                  '$pct %',
                  style: AppFonts.label(size: 12, color: AppColors.greenDark),
                )
              else if (badge != null)
                Text(
                  badge!,
                  style: AppFonts.ui(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              height: 7,
              color: AppColors.line,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: complete ? 1.0 : ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // ⚠️ Degrade bleu → rouge : c'est la teinte de la maquette
                    // validee. Le rouge n'y signale rien d'urgent, il ferme
                    // l'accent tricolore de la marque — la regle « rouge = CTA
                    // critique » porte sur les actions, pas sur cet aplat.
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: complete
                          ? const [AppColors.blue, AppColors.green]
                          : const [AppColors.blue, AppColors.red],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style:
                  AppFonts.ui(size: 12, color: AppColors.muted, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

/// **L'en-tete d'un bloc d'epreuve, depliable** — le `.examGroup` de
/// `plan_cycle.html` : repere d'epreuve, nom en clair, meta, pastille d'etat,
/// et un corps qui s'ouvre.
///
/// 🛑 **L'etat d'ouverture est EXTERNE** ([open] + [onToggle]), jamais
/// interne : l'ecran doit pouvoir n'en deplier **qu'un** — le bloc courant.
/// C'est exactement ce que [SfPrio] ne sait pas faire (son `State` est prive),
/// et c'est pourquoi cette brique existe au lieu d'une variante de [SfPrio].
///
/// 🛑 **Le nom de l'epreuve est EN CLAIR** (D-21) : « Comprehension orale »,
/// pas « CO » seul, pas « lot », pas « step ». Le vocabulaire interne reste
/// interne.
///
/// Composition attendue : une [SfJourneyList] de [SfJourneyRow] (les etapes,
/// avec leur rail), puis un [SfExamStepBox]. Le corps ne porte donc aucun
/// retrait de rail — c'est la liste qui a le sien.
///
/// 🛑 **Le nom de l'epreuve ne se tronque jamais** et tient sur UNE ligne
/// (D-21). C'est la maquette qui le garantit : sous 360 px logiques elle
/// **masque l'etat** et l'en-tete passe a deux colonnes, plutot que de
/// retrecir le titre. Miroir exact du `@media(max-width:360px)` web.
///
/// Miroir web : `BlocAccordion`.
class SfBlocAccordion extends StatelessWidget {
  const SfBlocAccordion({
    super.key,
    required this.mark,
    required this.title,
    required this.meta,
    required this.status,
    required this.open,
    required this.onToggle,
    required this.child,
    this.current = false,
  });

  /// Le repere court de l'epreuve (« CO »), en etiquette technique.
  ///
  /// 🛑 **Vide pour une THEMATIQUE civique** : l'initiale a deux lettres
  /// n'existe que pour une epreuve. « Principes et valeurs de la Republique »
  /// ne se reduit pas a deux lettres, et en inventer une serait un libelle
  /// **fabrique par le front** (A49). La pastille DISPARAIT alors, et **rien ne
  /// la remplace** — un carre vide, un numero de rang ou une icone choisie ici
  /// seraient toutes des inventions. Le titre prend la largeur, ce dont un nom
  /// de thematique a justement besoin.
  ///
  /// ⚠️ Miroir de `BlocAccordion` (`mark` vide ⇒ `.blocHeadSansMarque`).
  final String mark;

  /// Le nom de l'epreuve **en clair**, servi.
  final String title;

  /// « 1 competence restante · puis examen », **servi**.
  final String meta;

  /// Le libelle d'etat et son ton, tous deux **servis**.
  final ({String label, SfTone tone}) status;

  final bool open;
  final VoidCallback onToggle;

  /// Le bloc courant : filet et repere accentues. **Servi**, jamais deduit.
  final bool current;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        // `.examGroup` de la maquette : filet fin au repos, filet plus marque
        // et relief plus porte sur `.current`.
        border: Border.all(
            color: current ? AppColors.lineStrong : AppColors.line),
        boxShadow: current ? AppShadows.md : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                // Les valeurs de `.groupHead` dans
                // `docs/progression/plan_cycle.html` : `42px 1fr auto`,
                // `gap: 11px`, `padding: 15px`.
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    if (mark.isNotEmpty) ...[
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: current ? AppColors.blue : AppColors.blueSoft,
                          // La maquette dit 13 ; le token le plus proche vaut 12.
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                              color:
                                  current ? AppColors.blue : AppColors.line),
                        ),
                        child: Text(
                          mark,
                          style: AppFonts.label(
                            size: 12,
                            color: current ? AppColors.white : AppColors.blue,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 11),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            // `.groupTitle` : 14 px, poids 850 (w800 ici).
                            //
                            // 🛑 **Le titre d'une epreuve est BLEU** (arbitrage
                            // du proprietaire, 2026-09-19). La capture montre
                            // un bleu de navigateur ; c'est **notre** bleu de
                            // marque qui est ecrit ici. Le bloc courant n'est
                            // pas concerne : sa pastille d'initiale est bleue
                            // PLEINE avec un texte blanc, le titre reste a cote
                            // sur le fond blanc de la carte.
                            //
                            // ⚠️ [SfBlocAccordion] sert aussi « Ma
                            // progression », ou le titre est « Cycle 2 » : il y
                            // passe au bleu lui aussi, et c'est voulu.
                            style: AppFonts.ui(
                              size: 14,
                              weight: FontWeight.w800,
                              height: 1.25,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            meta,
                            style: AppFonts.ui(
                              size: 10.5,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 🛑 **Sous 360 px, la maquette MASQUE l'etat** et
                    // l'en-tete passe a deux colonnes
                    // (`@media(max-width:360px)`) : c'est ainsi qu'elle
                    // garantit le nom de l'epreuve sur UNE ligne sur les
                    // telephones les plus etroits. Miroir exact ici — 360 px
                    // est un vrai telephone, pas un palier desktop.
                    //
                    // La pastille prend sa largeur INTRINSEQUE (`auto` dans la
                    // grille web) : en `Flexible` elle prenait la MOITIE de
                    // l'espace libre, ce qui coupait « Comprehension orale »
                    // en deux lignes.
                    // 366 et non 360 : **mesure** faite sur les vraies
                    // metriques Hanken Grotesk, pire cas « Comprehension
                    // ecrite » + « A EVALUER » — la colonne du titre manque
                    // encore 0,1 px a 361 px. On elargit le palier de 6 px,
                    // ce qu'aucune largeur de telephone reelle n'occupe.
                    if (MediaQuery.sizeOf(context).width > 366) ...[
                      const SizedBox(width: 11),
                      SfPill(
                          label: status.label,
                          tone: status.tone.asBarTone,
                          dense: true),
                    ],
                    const SizedBox(width: 6),
                    // La seule affordance visible qu'un bloc se deplie. Le
                    // chevron PIVOTE, il ne se remplace pas — aucun saut de
                    // largeur a l'ouverture.
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Le corps est RETIRE de l'arbre quand il est replie : un lecteur
          // d'ecran ne doit pas traverser un bloc ferme.
          if (open)
            Container(
              // `.groupBody` : `4px 15px 15px`. Son 4e terme (`65px` a gauche)
              // est le retrait du rail — ici c'est `SfJourneyList` qui porte le
              // sien, l'ajouter le doublerait.
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 15),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// **L'encart d'examen imbrique en fin de bloc** — le `.examBox` de
/// `plan_cycle.html`.
///
/// 🛑 **[locked] rend l'encart inerte** : ni `onTap`, ni retour au toucher. Le
/// contenu reste **entierement lisible** — on ajoute un verrou, on ne masque
/// rien (R16, contradiction #1 tranchee le 2026-08-21).
///
/// [state] porte le libelle **servi** (« Verrouille », « Disponible ») et son
/// ton : [SfBarTone.muted] quand il n'y a rien a faire, [SfBarTone.now] quand
/// l'examen s'ouvre.
///
/// Miroir web : `ExamStepBox`.
class SfExamStepBox extends StatelessWidget {
  const SfExamStepBox({
    super.key,
    required this.title,
    required this.state,
    required this.note,
    required this.locked,
    this.onTap,
  });

  /// « Examen blanc · Comprehension orale », ou la mesure d'un niveau. Servi.
  final String title;

  final ({String label, SfBarTone tone}) state;

  /// La phrase de condition, **servie**.
  final String note;

  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    final corps = Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.ui(
                    size: 11.5,
                    weight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.label.toUpperCase(),
                style: AppFonts.label(
                  size: 9,
                  color: _sfStatusColor(state.tone),
                ).copyWith(fontWeight: FontWeight.w900),
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                const Icon(LucideIcons.lock, size: 13, color: AppColors.muted),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            note,
            style: AppFonts.ui(
                size: 10, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
    final decore = Container(
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
      ),
      child: corps,
    );
    if (locked || onTap == null) return decore;
    return Material(
      color: AppColors.blueSoft,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.line),
          ),
          child: corps,
        ),
      ),
    );
  }
}

/// Un fait de la carte de fin de cycle : une valeur et ce qu'elle nomme.
typedef SfNextStepFact = ({String value, String label});

/// **La carte de fin de cycle** — le `.finalCard` de `cycle_termine.html`, et
/// 🛑 **la seule primitive du kit a DEUX actions**.
///
/// C'est la raison de son existence : aucune brique n'a deux emplacements
/// d'action ([SfNowCard] en a un, [SfStickyBar] en porte une, [SfButton] est un
/// bouton). Le choix « passer l'examen complet » / « actualiser mon plan sans
/// examen » est un vrai choix, et le second terme ne doit pas se lire comme un
/// renoncement — d'ou une action **discrete mais entiere** sous le CTA, pas un
/// lien de pied.
///
/// 🛑 **Aucune phrase n'est ecrite ici** : [eyebrow], [title], [text], les
/// [facts] et les deux libelles d'action arrivent tous en parametres.
///
/// Miroir web : `NextStepCard`.
class SfNextStepCard extends StatelessWidget {
  const SfNextStepCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.text,
    required this.facts,
    required this.primary,
    this.secondary,
  });

  final String eyebrow;
  final String title;
  final String text;

  /// Les reperes de l'examen (3 dans la maquette). Vide ⇒ aucune grille.
  final List<SfNextStepFact> facts;

  final ({String label, VoidCallback onPressed}) primary;

  /// 🛑 **Facultative, et c'est une vraie issue du produit** : a la fin d'un
  /// cycle de mesure, « passer l'examen blanc complet » n'a plus de sens — il ne
  /// reste qu'une action. Absente, la carte n'affiche **rien** a sa place : on
  /// ne fabrique pas un second terme pour tenir la forme.
  final ({String label, VoidCallback onPressed})? secondary;

  @override
  Widget build(BuildContext context) {
    final doux = AppColors.white.withValues(alpha: 0.86);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue, AppColors.blueMid],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // L'anneau decoratif du coin, comme `.finalCard:after`.
          Positioned(
            right: -55,
            top: -62,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.06),
                  width: 28,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: AppFonts.label(size: 10.5, color: doux),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppFonts.display(
                    size: 21,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style:
                      AppFonts.ui(size: 13, color: doux, height: 1.5),
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < facts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color:
                                    AppColors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facts[i].value,
                                  style: AppFonts.ui(
                                    size: 12.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  facts[i].label,
                                  style: AppFonts.ui(
                                    size: 10.5,
                                    color: AppColors.white
                                        .withValues(alpha: 0.78),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 15),
                // Le CTA rouge est celui du kit : une seule definition de
                // bouton principal, ici comme partout.
                SfButton(
                  label: primary.label,
                  onPressed: primary.onPressed,
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 9),
                  // L'action discrete : entiere, pas un lien de pied — le
                  // second terme d'un vrai choix ne doit pas se lire comme un
                  // renoncement.
                  _SfNextStepSecondary(
                    label: secondary!.label,
                    onPressed: secondary!.onPressed,
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

class _SfNextStepSecondary extends StatelessWidget {
  const _SfNextStepSecondary({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Material(
      color: AppColors.white.withValues(alpha: 0.10),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MA PROGRESSION — HISTORIQUE DES CYCLES (maquette du proprietaire,
// 2026-09-18) — `docs/progression/histo_cycle.html`
//
// 🛑 Miroir de `HeroBanner` cote web (`app/_components/sejour/SejourKit.tsx` +
// `sejour.module.css`). Les compteurs de la maquette passent par [SfStatGrid]
// avec `onHero: true`.
// =============================================================================

/// **Le bandeau de tete d'un ecran d'archive** — le `.hero` de
/// `histo_cycle.html` : fond de marque, oeil-de-boeuf, titre editorial, phrase
/// de cadrage, puis ce que l'ecran y pose (les compteurs, dans la maquette).
///
/// 🛑 **Distinct de [SfNextStepCard]**, qu'il ne faut pas remplacer par lui :
/// celle-ci porte **deux actions** — c'est une decision a prendre. Ce bandeau,
/// lui, n'a **aucune action** : il presente.
///
/// 🛑 **Aucune phrase n'est ecrite ici** : [eyebrow], [title] et [text]
/// arrivent tous en parametres.
///
/// Miroir web : `HeroBanner`.
class SfHeroBanner extends StatelessWidget {
  const SfHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    this.text,
    this.child,
  });

  final String eyebrow;
  final String title;

  /// La phrase de cadrage. `null` ⇒ rien a sa place.
  final String? text;

  /// Ce que l'ecran pose sous la phrase. `null` ⇒ le bandeau s'arrete la.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final doux = AppColors.white.withValues(alpha: 0.80);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // L'oeil-de-boeuf du coin, comme `.hero` dans la maquette.
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.06),
                  width: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: AppFonts.label(
                          size: 11,
                          color: AppColors.white.withValues(alpha: 0.74),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppFonts.display(
                    size: 25,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                    height: 1.15,
                  ),
                ),
                if (text != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    text!,
                    style: AppFonts.ui(size: 14, color: doux, height: 1.5),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: 18),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LE BANDEAU D'OBJECTIF (template `docs/progression/ecran_progression_normal.html`,
// 2026-09-19). ⚠️ L'écran « Votre progression » qui le portait est supprimé
// (2026-09-24) ; le bandeau reste pour l'écran de déblocage du Plan. Ses
// voisines de l'époque (`SfLevelStrip`, `SfChartTitle`, `SfChartNote`,
// `SfEpreuveStatRow` / `SfEpreuveStatList`, `SfTrendTone`) sont supprimées avec
// leur dernier lecteur. Miroir web : `GoalHero`.
// =============================================================================

/// **Le bandeau d'objectif d'un ecran de progression** — le `.hero` du
/// template : oeil-de-boeuf, intitule + valeur en gros, pastille d'objectif a
/// droite, rail, ligne de mesure, puis ce que l'ecran y pose (la bande des
/// paliers).
///
/// 🛑 **Distinct des deux heros voisins**, qu'il ne faut pas remplacer par
/// lui :
/// - [SfHeroBanner] **presente** un ecran d'archive, sans aucun chiffre ;
/// - [SfGoalBanner] est une bande **compacte**, posee DANS une carte.
///
/// Celui-ci porte un **avancement** : un compteur, un rail et sa lecture en
/// pourcentage. C'est ce qui lui evite d'etre une variante de l'un des deux.
///
/// 🛑 [ratio] est une **part passee**, jamais derivee ici, et le pourcentage
/// est **ecrit par l'appelant** ([metaValue]) : le kit ne convertit aucun
/// nombre. `null` des deux cotes ⇒ ni rail ni chiffre, ce qui est le rendu
/// exact d'une donnee non servie.
///
/// Miroir web : `GoalHero`.
class SfGoalHero extends StatelessWidget {
  const SfGoalHero({
    super.key,
    required this.label,
    this.value,
    this.pill,
    this.ratio,
    this.metaLabel,
    this.metaValue,
    this.child,
  });

  /// « Vers votre objectif ».
  final String label;

  /// « 2 epreuves sur 4 ». **Compose par l'appelant.** `null` quand le serveur
  /// ne sert pas de quoi l'ecrire : le bandeau garde son intitule et sa bande
  /// de paliers, mais **n'annonce aucun chiffre**.
  final String? value;

  /// « Objectif B1 ». `null` sans demarche declaree — on ne devine pas
  /// l'objectif d'un candidat qui n'en a pas donne.
  final String? pill;

  /// Part parcourue (0-1). `null` ⇒ pas de rail.
  final double? ratio;

  final String? metaLabel;

  /// Le pourcentage, **deja ecrit**. `null` ⇒ la ligne n'annonce aucun chiffre.
  final String? metaValue;

  /// La bande des paliers. `null` ⇒ le bandeau s'arrete la.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final doux = AppColors.white.withValues(alpha: 0.82);
    final rail = ratio;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueDark, AppColors.blue, AppColors.blueMid],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // L'oeil-de-boeuf du coin (`.hero:after`).
          Positioned(
            right: -68,
            top: -86,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.05),
                  width: 34,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppFonts.ui(
                              size: 12,
                              weight: FontWeight.w700,
                              color: doux,
                            ),
                          ),
                          if (value != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              value!,
                              style: AppFonts.display(
                                size: 27,
                                weight: FontWeight.w700,
                                color: AppColors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (pill != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          pill!,
                          style: AppFonts.ui(
                            size: 11,
                            weight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (rail != null) ...[
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: Container(
                      height: 7,
                      color: AppColors.white.withValues(alpha: 0.18),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: rail.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.white),
                        ),
                      ),
                    ),
                  ),
                ],
                if (metaLabel != null || metaValue != null) ...[
                  SizedBox(height: rail == null ? 16 : 14),
                  Row(
                    children: [
                      if (metaLabel != null)
                        Expanded(
                          child: Text(
                            metaLabel!,
                            style: AppFonts.ui(size: 12, color: doux),
                          ),
                        )
                      else
                        const Spacer(),
                      if (metaValue != null)
                        Text(
                          metaValue!,
                          style: AppFonts.label(
                              size: 12.5, color: AppColors.white),
                        ),
                    ],
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: 12),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Maquette « Détail d'une étape de séries » (propriétaire, 2026-09-20)
//
// L'écran intermédiaire qui s'ouvre depuis le cycle du Plan sur une étape
// d'entraînement de compréhension (CO/CE) ou une étape civique : le domaine et
// la priorité en pastilles, la compétence en titre, l'avancement, puis une
// carte par série.
//
// 🛑 Miroirs de `SerieProgress` et `SerieCard` côté web. Un motif qui bouge
// d'un côté bouge de l'autre dans la même passe.
// =============================================================================

/// **L'avancement d'une étape de séries** — le gros compteur à gauche, le seuil
/// à droite, et la barre en dessous.
///
/// 🛑 **Elle n'est pas [SfCycleProgress]**, et il ne faut pas les confondre :
/// celle-là compte les **étapes d'un cycle** (un compteur en mots, un repère de
/// cycle) ; celle-ci compte les **séries d'une étape**, met son chiffre en
/// évidence et porte, en face, le seuil à tenir sur chacune. Deux échelles,
/// deux lectures.
///
/// 🛑 **Aucune phrase n'est composée ici** : [count], [note] et [noteSub]
/// arrivent en props, tous trois posés sur des faits servis (`quota`,
/// `seuilReussite`, `questionsParSerie`).
///
/// Miroir web : `SerieProgress`.
class SfSerieProgress extends StatelessWidget {
  const SfSerieProgress({
    super.key,
    required this.count,
    required this.note,
    required this.noteSub,
    required this.done,
    required this.total,
  });

  /// « 0/2 séries », composé par l'appelant.
  final String count;

  /// « 16/20 minimum ».
  final String note;

  /// « sur chacune ».
  final String noteSub;

  /// Les séries **validées** — un décompte de booléens servis.
  final int done;

  /// Le quota **servi**.
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    return SfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  count,
                  style: AppFonts.ui(
                    size: 24,
                    weight: FontWeight.w800,
                    color: AppColors.blue,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    note,
                    style:
                        AppFonts.ui(size: 13, weight: FontWeight.w700),
                  ),
                  Text(
                    noteSub,
                    style: AppFonts.ui(size: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              height: 7,
              color: AppColors.line,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **La carte d'une série** — repère carré, titre, méta, badge d'état, puis le
/// bouton pleine largeur et, si la série a déjà été jouée, l'accès à son
/// corrigé.
///
/// 🛑 **Le kit ne décide d'aucun état.** [state], l'inertie du bouton et la
/// présence de [linkLabel] sont posés par l'appelant à partir de `locked` et
/// `validee`, **servis** — jamais d'une comparaison entre un score et un seuil.
///
/// 🛑 **[locked] grise la carte, il ne la masque pas** : le repère, le titre, la
/// méta et le bouton restent lisibles (R16 — on floute l'action, jamais le
/// résultat). Le bouton porte alors la condition (« Après la série 1 ») et ne
/// répond pas.
///
/// Miroir web : `SerieCard`.
class SfSerieCard extends StatelessWidget {
  const SfSerieCard({
    super.key,
    required this.mark,
    required this.title,
    required this.questions,
    required this.state,
    required this.locked,
    required this.actionLabel,
    this.duree,
    this.score,
    this.onAction,
    this.linkLabel,
    this.onLink,
  });

  /// Le chiffre du carré — l'`index` **servi**, mis en texte par l'appelant.
  final String mark;

  /// « Série 1 ».
  final String title;

  /// « 16 min ». `null` quand la durée n'est pas servie : rien à sa place.
  final String? duree;

  /// « 20 questions ».
  final String questions;

  /// Le badge d'état et son ton, **composés** par l'appelant.
  final ({String label, SfBarTone tone}) state;

  /// « Dernier score : 17/20 ». `null` tant que la série n'a pas été jouée.
  final String? score;

  final bool locked;

  /// Le bouton pleine largeur. Sans [onAction], il est inerte.
  final String actionLabel;
  final VoidCallback? onAction;

  /// Le second accès d'une série jouée : son corrigé.
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final inerte = onAction == null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: locked ? AppColors.surface3 : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: locked ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: locked ? AppColors.line : AppColors.blueLight,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  mark,
                  style: AppFonts.label(
                    size: 13,
                    color: locked ? AppColors.muted : AppColors.blueDark,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.ui(size: 15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (duree != null) ...[
                          const Icon(LucideIcons.clock,
                              size: 13, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Text(
                            duree!,
                            style: AppFonts.ui(
                                size: 12, color: AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(LucideIcons.listChecks,
                            size: 13, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            questions,
                            style: AppFonts.ui(
                                size: 12, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.label.toUpperCase(),
                    style: AppFonts.ui(
                      size: 10,
                      weight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: _sfStatusColor(state.tone),
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 5),
                    const Icon(LucideIcons.lock,
                        size: 12, color: AppColors.muted),
                  ],
                ],
              ),
            ],
          ),
          if (score != null) ...[
            const SizedBox(height: 10),
            Text(
              score!,
              style: AppFonts.ui(
                  size: 12.5, weight: FontWeight.w600, color: AppColors.ink2),
            ),
          ],
          const SizedBox(height: 12),
          // 🛑 Un bouton fermé est GRIS, pas un bouton d'action pâli : il porte
          // la condition qui l'ouvrira, et rien ne doit inviter à le presser.
          Material(
            color: inerte ? AppColors.line : AppColors.blue,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        actionLabel,
                        textAlign: TextAlign.center,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          color: inerte ? AppColors.muted : AppColors.white,
                        ),
                      ),
                    ),
                    if (!inerte) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight,
                          size: 18, color: AppColors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (linkLabel != null && onLink != null) ...[
            const SizedBox(height: 9),
            InkWell(
              onTap: onLink,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      linkLabel!,
                      style: AppFonts.ui(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight,
                        size: 15, color: AppColors.blue),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// ÉCRANS DE PROGRESSION (2026-09-24) — maquettes
// `docs/progression/maquettes-progression/*.html`, état téléphone (≤ 470 /
// 620 px). Contrat : `docs/regles/progression.md` § « Écrans de progression ».
//
// 🛑 **Aucune de ces briques ne classe, ne compte ni ne compare** : score,
// palier, état, écart, sens, bandes, repères, seuil, ordinal, durée et verrou
// arrivent SERVIS, et l'appelant les compose en texte. La courbe et la
// sparkline **placent** des valeurs sur un axe dont les bornes sont servies —
// placer n'est pas classer.
//
// 🛑 **Rouge = CTA critiques seulement** : le dernier point de la courbe,
// l'anneau et le badge « B2 », rouges sur les maquettes, sont ici dans la
// famille bleue (l'anneau passe au vert quand le seuil servi est atteint,
// sémantique de [SfRing]). Seule la pastille de l'œil-de-bœuf reste rouge : la
// convention du kit (`.heroDot`), comme le web.
//
// Miroirs web (mêmes noms, sans `Sf`) : `ProgressTopbar`, `ProgressIntro`,
// `ProgressHero`, `ProgressStatTile`, `ProgressStatGrid`, `ProgressDomainCard`,
// `ProgressChart`, `ProgressScaleLegend`, `ProgressExamRow`,
// `ProgressGlobalExamRow`.
// =============================================================================

/// Le rayon des cartes de ces écrans (`.card` des maquettes, 18 px).
const double _sfProgressRadius = AppRadii.lg;

BoxDecoration _sfProgressCardDecoration() => BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(_sfProgressRadius),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadows.card,
    );

/// La carte blanche des écrans de progression, avec son effet de toucher.
class _SfProgressCard extends StatelessWidget {
  const _SfProgressCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_sfProgressRadius);
    final contenu = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(
        decoration: _sfProgressCardDecoration(),
        child: contenu,
      );
    }
    return Material(
      color: AppColors.white,
      borderRadius: radius,
      child: Ink(
        decoration: _sfProgressCardDecoration(),
        child: InkWell(onTap: onTap, borderRadius: radius, child: contenu),
      ),
    );
  }
}

/// **La barre haute** : le retour (flèche en tuile + intitulé) à gauche, le
/// CTA « Nouvel examen blanc » à droite.
///
/// 🛑 [ctaLocked] est le `cta.locked` **servi** (D20) : le bouton garde sa
/// place et son libellé, il gagne un cadenas, et c'est l'appelant qui ouvre le
/// paywall au toucher. Aucun verrou n'est déduit ici. Bouton **bleu** : ce
/// n'est pas un CTA critique.
///
/// Miroir web : `ProgressTopbar`.
class SfProgressTopbar extends StatelessWidget {
  const SfProgressTopbar({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.ctaLabel,
    this.onCta,
    this.ctaLocked = false,
  });

  final String backLabel;
  final VoidCallback onBack;

  /// `null` = aucun bouton (chargement, erreur) : on ne propose pas une porte
  /// dont le verrou n'est pas encore connu.
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool ctaLocked;

  @override
  Widget build(BuildContext context) {
    final libelle = ctaLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(LucideIcons.arrowLeft,
                              size: 17, color: AppColors.blueDark),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            backLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.ui(
                              size: 14,
                              weight: FontWeight.w800,
                              color: AppColors.blueDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (libelle != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Material(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: onCta,
                  borderRadius: BorderRadius.circular(13),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (ctaLocked) ...[
                          const Icon(LucideIcons.lock,
                              size: 14, color: AppColors.white),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            libelle,
                            textAlign: TextAlign.center,
                            style: AppFonts.ui(
                              size: 13.5,
                              weight: FontWeight.w800,
                              color: AppColors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// **L'intro** : l'œil-de-bœuf à pastille (« Votre progression »), le titre de
/// l'écran, sa phrase. Miroir web : `ProgressIntro`.
class SfProgressIntro extends StatelessWidget {
  const SfProgressIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    this.lead,
  });

  final String eyebrow;
  final String title;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final phrase = lead;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // La pastille rouge à halo est la convention du kit pour un
              // œil-de-bœuf (`.heroDot` côté web) — un repère, pas un CTA.
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.16),
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  eyebrow,
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppFonts.display(
              size: 28,
              weight: FontWeight.w800,
              color: AppColors.blueDark,
              height: 1.08,
            ),
          ),
          if (phrase != null) ...[
            const SizedBox(height: 9),
            Text(
              phrase,
              style: AppFonts.ui(size: 15, color: AppColors.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une pastille des écrans de progression (`.level` / `.trend`) : le ton est
/// **passé** (état servi, sens servi), jamais déduit du texte.
class _SfProgressChip extends StatelessWidget {
  const _SfProgressChip({required this.label, required this.tone});

  final String label;
  final SfBarTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _sfPillSoft(tone),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppFonts.ui(
          size: 13,
          weight: FontWeight.w800,
          color: _sfPillText(tone),
        ),
      ),
    );
  }
}

/// Un anneau de carte de tête : ratio **servi**, texte du centre **composé**,
/// seuil atteint **servi**. Civique seulement (D5).
typedef SfProgressRing = ({double ratio, String label, bool reached});

/// **La carte de tête** — « Dernier résultat » : le gros score (ou le palier)
/// et son unité, les pastilles (palier ou état, puis tendance), des lignes
/// secondaires, et l'anneau en civique.
///
/// 🛑 **D5 : pas d'anneau en TCF.** [ring] est `null` pour le TCF — un disque
/// rempli à côté d'un palier se lirait comme « x % vers le B2 ».
///
/// Miroir web : `ProgressHero`.
class SfProgressHero extends StatelessWidget {
  const SfProgressHero({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.level,
    this.levelTone = SfBarTone.now,
    this.trend,
    this.trendTone = SfBarTone.muted,
    this.notes = const <String>[],
    this.ring,
  });

  final String label;

  /// Le score (« 422 ») ou le palier (« B1 ») ; « — » quand rien n'est mesuré.
  final String value;

  /// « / 499 ». `null` pour un palier.
  final String? unit;

  /// La pastille de palier ou d'état. `null` = aucune.
  final String? level;
  final SfBarTone levelTone;

  /// La pastille de tendance. `null` quand l'écart est inconnu — jamais « +0 ».
  final String? trend;
  final SfBarTone trendTone;

  /// Les lignes secondaires (niveau actuel estimé, provenance de l'état…).
  final List<String> notes;

  final SfProgressRing? ring;

  @override
  Widget build(BuildContext context) {
    final unite = unit;
    final palier = level;
    final tendance = trend;
    final anneau = ring;
    return _SfProgressCard(
      padding: const EdgeInsets.all(21),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: AppFonts.display(
                          size: 38,
                          weight: FontWeight.w800,
                          color: AppColors.blueDark,
                          height: 1,
                        ),
                      ),
                    ),
                    if (unite != null) ...[
                      const SizedBox(width: 7),
                      Text(
                        unite,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (palier != null || tendance != null) ...[
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (palier != null)
                        _SfProgressChip(label: palier, tone: levelTone),
                      if (tendance != null)
                        _SfProgressChip(label: tendance, tone: trendTone),
                    ],
                  ),
                ],
                for (final note in notes) ...[
                  const SizedBox(height: 10),
                  Text(
                    note,
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (anneau != null) ...[
            const SizedBox(width: 14),
            SfRing(
              ratio: anneau.ratio,
              size: 84,
              stroke: 10,
              label: anneau.label,
              reached: anneau.reached,
            ),
          ],
        ],
      ),
    );
  }
}

/// **Un encart de synthèse** : un intitulé, une valeur, une légende.
///
/// [inset] = l'encart posé **dans** une carte (`.summary-box` de l'écran
/// global) ; sinon c'est une carte à part entière (`.mini` de l'écran d'une
/// épreuve ou d'un thème). 🛑 La valeur arrive en texte : rien n'est compté.
///
/// Miroir web : `ProgressStatTile`.
class SfProgressStatTile extends StatelessWidget {
  const SfProgressStatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.inset = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final legende = caption;
    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.ui(
            size: inset ? 12 : 13,
            weight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        SizedBox(height: inset ? 7 : 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppFonts.display(
                size: inset ? 21 : 23,
                weight: FontWeight.w800,
                color: AppColors.blueDark,
                height: 1.1,
              ),
            ),
            if (legende != null) ...[
              const SizedBox(height: 4),
              Text(
                legende,
                style: AppFonts.ui(
                  size: inset ? 11 : 12,
                  color: AppColors.muted,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ],
    );
    if (inset) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: contenu,
      );
    }
    return _SfProgressCard(
      padding: const EdgeInsets.all(17),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 91),
        child: contenu,
      ),
    );
  }
}

/// **La grille des encarts**, deux colonnes, les encarts d'une rangée à la
/// même hauteur. [framed] pose la grille **dans** une carte blanche (écran
/// global : les encarts sont alors `inset`). Miroir web : `ProgressStatGrid`.
class SfProgressStatGrid extends StatelessWidget {
  const SfProgressStatGrid({
    super.key,
    required this.tiles,
    this.framed = false,
  });

  final List<SfProgressStatTile> tiles;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final gap = framed ? 10.0 : 14.0;
    final rangees = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final seule = i + 1 >= tiles.length;
      rangees.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              SizedBox(width: gap),
              Expanded(child: seule ? const SizedBox() : tiles[i + 1]),
            ],
          ),
        ),
      );
    }
    final grille = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rangees.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          rangees[i],
        ],
      ],
    );
    if (!framed) return grille;
    return _SfProgressCard(padding: const EdgeInsets.all(16), child: grille);
  }
}

/// Une sparkline à l'échelle **servie** ([min] → [max]) : la série du plus
/// ancien au plus récent, le dernier point marqué.
typedef SfProgressSpark = ({List<double> serie, double min, double max});

/// **La carte d'une épreuve ou d'un thème** : pictogramme, nom, sous-titre,
/// chevron ; puis le dernier score et son unité, la pastille de palier ou
/// d'état, l'écart, et la sparkline. Toute la carte ouvre l'écran détaillé.
///
/// 🛑 [empty] remplace le bloc de score quand rien n'est servi (« Pas encore
/// d'examen ») : ni sparkline, ni écart — une absence n'a pas de tendance.
///
/// Miroir web : `ProgressDomainCard`.
class SfProgressDomainCard extends StatelessWidget {
  const SfProgressDomainCard({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.value,
    this.unit,
    this.pill,
    this.pillTone = SfBarTone.now,
    this.delta,
    this.deltaTone = SfBarTone.muted,
    this.spark,
    this.empty,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  final String? value;
  final String? unit;
  final String? pill;
  final SfBarTone pillTone;
  final String? delta;
  final SfBarTone deltaTone;
  final SfProgressSpark? spark;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final vide = empty;
    final score = value;
    final unite = unit;
    final pastille = pill;
    final ecart = delta;
    final serie = spark;
    return _SfProgressCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
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
                    Text(
                      title,
                      style: AppFonts.display(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.blueDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: AppFonts.ui(size: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight,
                  size: 20, color: AppColors.muted2),
            ],
          ),
          const SizedBox(height: 18),
          if (vide != null)
            Text(
              vide,
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.muted,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            score ?? '—',
                            style: AppFonts.display(
                              size: 32,
                              weight: FontWeight.w800,
                              color: AppColors.blueDark,
                              height: 1,
                            ),
                          ),
                          if (unite != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              unite,
                              style: AppFonts.ui(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (pastille != null) ...[
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: _sfPillSoft(pillTone),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            pastille,
                            style: AppFonts.ui(
                              size: 12,
                              weight: FontWeight.w900,
                              color: _sfPillText(pillTone),
                            ),
                          ),
                        ),
                      ],
                      if (ecart != null) ...[
                        const SizedBox(height: 9),
                        Text(
                          ecart,
                          style: AppFonts.ui(
                            size: 12,
                            weight: FontWeight.w800,
                            color: _sfPillText(deltaTone),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (serie != null && serie.serie.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 115,
                    height: 58,
                    child: CustomPaint(
                      painter: _SfSparkPainter(
                        serie: serie.serie,
                        min: serie.min,
                        max: serie.max,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// La hauteur relative (0 = en haut) d'une valeur sur un axe servi.
double _sfAxisAt(double v, double min, double max) {
  final span = max - min;
  if (span <= 0) return 0.5;
  return 1 - ((v - min) / span).clamp(0.0, 1.0);
}

class _SfSparkPainter extends CustomPainter {
  const _SfSparkPainter({
    required this.serie,
    required this.min,
    required this.max,
  });

  final List<double> serie;
  final double min;
  final double max;

  static const double _pad = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - 2 * _pad;
    final h = size.height - 2 * _pad;
    Offset at(int i) => Offset(
          _pad + (serie.length > 1 ? i / (serie.length - 1) * w : w),
          _pad + _sfAxisAt(serie[i], min, max) * h,
        );
    if (serie.length > 1) {
      final path = Path()..moveTo(at(0).dx, at(0).dy);
      for (var i = 1; i < serie.length; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.blue
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final dernier = at(serie.length - 1);
    canvas.drawCircle(dernier, 4, Paint()..color = AppColors.white);
    canvas.drawCircle(
      dernier,
      4,
      Paint()
        ..color = AppColors.blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SfSparkPainter old) =>
      old.serie != serie || old.min != min || old.max != max;
}

/// Une bande de l'axe, bornes **servies** et libellé composé (« B2 · 10–20 »).
///
/// [tone] teinte la bande d'un état **servi** (civique) ; `null` = rampe
/// neutre de la famille bleue, du bas vers le haut (paliers EE/EO).
class SfProgressBand {
  const SfProgressBand({
    required this.from,
    required this.to,
    required this.label,
    this.tone,
  });

  final double from;
  final double to;
  final String label;
  final SfBarTone? tone;
}

/// Un point de la courbe : sa valeur (pour la placer), son texte (pour la
/// dire) et sa date.
class SfProgressChartPoint {
  const SfProgressChartPoint({
    required this.value,
    required this.valueLabel,
    required this.date,
  });

  final double value;
  final String valueLabel;
  final String date;
}

/// **La courbe d'évolution** : aire + ligne + points, le dernier point mis en
/// avant, les dates en abscisse, et — **seulement quand elles sont servies** —
/// les bandes de l'échelle et le trait de seuil.
///
/// 🛑 **D2 : aucune bande en CO/CE.** [bands] vide ⇒ des repères neutres
/// ([reperes]) et rien d'autre. Un point se **place** entre [min] et [max]
/// servis ; aucune interpolation, aucune moyenne. Au-delà de ce que la largeur
/// tient, la courbe défile horizontalement, calée sur le plus récent.
///
/// Miroir web : `ProgressChart`.
class SfProgressChart extends StatelessWidget {
  const SfProgressChart({
    super.key,
    required this.min,
    required this.max,
    required this.points,
    this.bands = const <SfProgressBand>[],
    this.reperes = const <double>[],
    this.seuil,
    this.note,
  });

  final double min;
  final double max;

  /// Du plus ancien au plus récent.
  final List<SfProgressChartPoint> points;
  final List<SfProgressBand> bands;
  final List<double> reperes;
  final double? seuil;

  /// Ce que mesure l'axe, servi (« Score de progression · /499 »). `null` = rien.
  final String? note;

  static const double _axis = 34;
  static const double _plot = 210;
  static const double _top = 22;
  static const double _dates = 26;
  static const double _pas = 64;

  String _repere(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final echelle = note;
    final courbe = LayoutBuilder(
      builder: (context, constraints) {
        final dispo = math.max(constraints.maxWidth - _axis, 1.0);
        final largeur = math.max(dispo, points.length * _pas);
        double y(double v) => _top + _sfAxisAt(v, min, max) * _plot;
        final trace = SizedBox(
          width: largeur,
          height: _top + _plot + _dates,
          child: CustomPaint(
            painter: _SfProgressChartPainter(
              min: min,
              max: max,
              top: _top,
              plot: _plot,
              points: [for (final p in points) p.value],
              bands: bands,
              reperes: reperes,
              seuil: seuil,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final b in bands)
                  if ((y(b.from) - y(b.to)) >= 16)
                    Positioned(
                      left: 12,
                      top: y(b.to) + 4,
                      child: Text(
                        b.label,
                        style: AppFonts.ui(
                          size: 11,
                          weight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                for (var i = 0; i < points.length; i++)
                  if (_montreValeur(i))
                    Positioned(
                      left: _x(i, largeur) - 30,
                      top: y(points[i].value) -
                          (i == points.length - 1 ? 26 : 22),
                      width: 60,
                      child: Text(
                        points[i].valueLabel,
                        textAlign: TextAlign.center,
                        style: AppFonts.ui(
                          size: i == points.length - 1 ? 12 : 11,
                          weight: i == points.length - 1
                              ? FontWeight.w900
                              : FontWeight.w800,
                          color: i == points.length - 1
                              ? AppColors.blueDark
                              : AppColors.blue,
                        ),
                      ),
                    ),
                for (var i = 0; i < points.length; i++)
                  if (_montreDate(i))
                    Positioned(
                      left: (_x(i, largeur) - 32)
                          .clamp(0.0, math.max(largeur - 64, 0.0)),
                      top: _top + _plot + 8,
                      width: 64,
                      child: Text(
                        points[i].date,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(size: 11, color: AppColors.muted),
                      ),
                    ),
              ],
            ),
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _axis,
              height: _top + _plot + _dates,
              child: Stack(
                children: [
                  for (final r in reperes)
                    Positioned(
                      left: 0,
                      right: 6,
                      top: y(r) - 7,
                      child: Text(
                        _repere(r),
                        textAlign: TextAlign.right,
                        style: AppFonts.ui(size: 11, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: largeur > dispo
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: trace,
                    )
                  : trace,
            ),
          ],
        );
      },
    );
    if (echelle == null) return courbe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          echelle,
          textAlign: TextAlign.right,
          style: AppFonts.ui(
            size: 12,
            weight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        courbe,
      ],
    );
  }

  double _x(int i, double largeur) =>
      _SfProgressChartPainter.xOf(i, points.length, largeur);

  /// Quelques valeurs seulement, pour ne pas surcharger (maquette) : toutes
  /// jusqu'à quatre points, puis la première et la dernière.
  bool _montreValeur(int i) =>
      points.length <= 4 || i == 0 || i == points.length - 1;

  /// Les dates : toutes jusqu'à quatre points, puis une sur deux en gardant
  /// toujours la plus récente.
  bool _montreDate(int i) =>
      points.length <= 4 || (points.length - 1 - i).isEven;
}

class _SfProgressChartPainter extends CustomPainter {
  const _SfProgressChartPainter({
    required this.min,
    required this.max,
    required this.top,
    required this.plot,
    required this.points,
    required this.bands,
    required this.reperes,
    required this.seuil,
  });

  final double min;
  final double max;
  final double top;
  final double plot;
  final List<double> points;
  final List<SfProgressBand> bands;
  final List<double> reperes;
  final double? seuil;

  static const double _marge = 26;

  static double xOf(int i, int n, double largeur) {
    if (n <= 1) return largeur / 2;
    return _marge + i / (n - 1) * (largeur - 2 * _marge);
  }

  double _y(double v) => top + _sfAxisAt(v, min, max) * plot;

  Color _bandFill(SfProgressBand b, int rang, int total) {
    final ton = b.tone;
    if (ton != null) return _sfPillSoft(ton).withValues(alpha: 0.55);
    final t = total <= 1 ? 1.0 : rang / (total - 1);
    return Color.lerp(AppColors.blueSoft, AppColors.blueLight, t)!
        .withValues(alpha: 0.4 + 0.5 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ordonnees = [...bands]..sort((a, b) => a.from.compareTo(b.from));
    for (var i = 0; i < ordonnees.length; i++) {
      final b = ordonnees[i];
      canvas.drawRect(
        Rect.fromLTRB(0, _y(b.to), size.width, _y(b.from)),
        Paint()..color = _bandFill(b, i, ordonnees.length),
      );
    }
    final grille = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final r in reperes) {
      canvas.drawLine(Offset(0, _y(r)), Offset(size.width, _y(r)), grille);
    }
    final palier = seuil;
    if (palier != null) {
      final trait = Paint()
        ..color = AppColors.lineStrong
        ..strokeWidth = 1.5;
      final y = _y(palier);
      for (var x = 0.0; x < size.width; x += 9) {
        canvas.drawLine(
            Offset(x, y), Offset(math.min(x + 4, size.width), y), trait);
      }
    }
    if (points.isEmpty) return;
    final pts = [
      for (var i = 0; i < points.length; i++)
        Offset(xOf(i, points.length, size.width), _y(points[i])),
    ];
    if (pts.length > 1) {
      final ligne = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        ligne.lineTo(p.dx, p.dy);
      }
      final bas = top + plot;
      final aire = Path.from(ligne)
        ..lineTo(pts.last.dx, bas)
        ..lineTo(pts.first.dx, bas)
        ..close();
      canvas.drawPath(
        aire,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.blue.withValues(alpha: 0.13),
              AppColors.blue.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(0, top, size.width, bas)),
      );
      canvas.drawPath(
        ligne,
        Paint()
          ..color = AppColors.blue
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final fond = Paint()..color = AppColors.white;
    for (var i = 0; i < pts.length; i++) {
      final dernier = i == pts.length - 1;
      if (dernier) {
        canvas.drawCircle(
            pts[i], 11, Paint()..color = AppColors.blue.withValues(alpha: 0.14));
      }
      canvas.drawCircle(pts[i], dernier ? 6 : 5, fond);
      canvas.drawCircle(
        pts[i],
        dernier ? 6 : 5,
        Paint()
          ..color = dernier ? AppColors.blueDark : AppColors.blue
          ..strokeWidth = dernier ? 4 : 3
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SfProgressChartPainter old) =>
      old.points != points ||
      old.bands != bands ||
      old.reperes != reperes ||
      old.seuil != seuil ||
      old.min != min ||
      old.max != max;
}

/// Une entrée de légende : le nom de la bande et son intervalle, **servis**.
typedef SfProgressScaleItem = ({String label, String range});

/// **La légende de l'échelle** (`.scale`) : les bandes servies, deux par
/// rangée. 🛑 Rien ici en CO/CE — il n'y a pas de bande (D2).
///
/// Miroir web : `ProgressScaleLegend`.
class SfProgressScaleLegend extends StatelessWidget {
  const SfProgressScaleLegend({super.key, required this.items});

  final List<SfProgressScaleItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeur = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                width: largeur,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppFonts.ui(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.range,
                      style: AppFonts.ui(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Le badge de fin de ligne d'examen (`.level-badge`).
class _SfProgressBadge extends StatelessWidget {
  const _SfProgressBadge({required this.label, required this.tone});

  final String label;
  final SfBarTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 45),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _sfPillSoft(tone),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppFonts.ui(
          size: 12,
          weight: FontWeight.w900,
          color: _sfPillText(tone),
        ),
      ),
    );
  }
}

/// Le cadre d'une ligne d'examen (`.exam` / `.attempt`), touchable.
class _SfProgressRowFrame extends StatelessWidget {
  const _SfProgressRowFrame({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: AppColors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// **Une ligne d'examen** d'un écran d'épreuve ou de thème : l'ordinal servi
/// (« Examen blanc n°7 »), la date, la provenance, la durée fiable (ou « — »),
/// le score et le badge de palier ou d'état. Le toucher ouvre le rapport — sa
/// route est choisie par l'appelant sur `rapport.kind` **servi**.
///
/// Miroir web : `ProgressExamRow`.
class SfProgressExamRow extends StatelessWidget {
  const SfProgressExamRow({
    super.key,
    required this.title,
    required this.score,
    required this.scoreLabel,
    required this.duration,
    required this.durationLabel,
    required this.onTap,
    this.badge,
    this.date,
    this.meta,
    this.badgeTone = SfBarTone.now,
  });

  final String title;
  final String? date;

  /// La provenance (« Épreuve passée seule »). `null` = rien à dire.
  final String? meta;
  final String score;
  final String scoreLabel;

  /// La durée, ou « — » quand elle n'est pas fiable (D9).
  final String duration;
  final String durationLabel;

  /// Le palier ou l'état de l'examen. `null` = aucun badge (jamais « A1 »).
  final String? badge;
  final SfBarTone badgeTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lignes = [
      if (date != null) date!,
      if (meta != null) meta!,
      '$durationLabel $duration',
    ];
    return _SfProgressRowFrame(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.blueDark,
                  ),
                ),
                for (final l in lignes) ...[
                  const SizedBox(height: 3),
                  Text(
                    l,
                    style: AppFonts.ui(size: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scoreLabel,
                style: AppFonts.ui(size: 10, color: AppColors.muted),
              ),
              const SizedBox(height: 3),
              Text(
                score,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            _SfProgressBadge(label: badge!, tone: badgeTone),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.muted2),
          ],
        ],
      ),
    );
  }
}

/// Une part d'un examen global : l'épreuve ou le thème, et sa valeur composée
/// (« 392 / 499 », « 7 / 11 posées », « — »).
typedef SfProgressPart = ({String label, String value});

/// **Une ligne d'examen global** : l'ordinal et la date, le badge global
/// (palier TCF ou « Global : 29 / 40 »), puis le détail **par épreuve** (TCF,
/// quatre colonnes) ou **par thème** (civique, une ligne par thème : D11,
/// « x / n posées », jamais « / 20 »).
///
/// Miroir web : `ProgressGlobalExamRow`.
class SfProgressGlobalExamRow extends StatelessWidget {
  const SfProgressGlobalExamRow({
    super.key,
    required this.title,
    required this.badge,
    required this.parts,
    required this.onTap,
    this.date,
    this.meta,
    this.badgeTone = SfBarTone.now,
    this.stacked = false,
  });

  final String title;
  final String? date;

  /// Une précision servie (« Partiel : 3 épreuves sur 4 »). `null` = rien.
  final String? meta;
  final String badge;
  final SfBarTone badgeTone;
  final List<SfProgressPart> parts;

  /// `true` = une part par ligne (noms longs des thèmes civiques).
  final bool stacked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final precision = meta;
    return _SfProgressRowFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.blueDark,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        date!,
                        style: AppFonts.ui(size: 11, color: AppColors.muted),
                      ),
                    ],
                    if (precision != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        precision,
                        style: AppFonts.ui(size: 11, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SfProgressBadge(label: badge, tone: badgeTone),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight,
                    size: 18, color: AppColors.muted2),
              ],
            ],
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (stacked)
              Column(
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            parts[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppFonts.ui(size: 12, color: AppColors.muted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          parts[i].value,
                          style: AppFonts.ui(
                            size: 12.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parts[i].label,
                            style:
                                AppFonts.ui(size: 10, color: AppColors.muted),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              parts[i].value,
                              maxLines: 1,
                              style: AppFonts.ui(
                                size: 13,
                                weight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
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
