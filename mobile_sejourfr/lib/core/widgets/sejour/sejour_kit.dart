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
              ? AppFonts.ui(size: 20, weight: FontWeight.w800, height: 1.15)
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

/// [tcf] / [civique] : le CTA **d'un module**, peint de sa couleur de module
/// (Navigation v2, X1 — TCF bleu, civique rouge). À préférer à [blue] ou
/// [primary] dès que la couleur dit « ce module » plutôt que « critique ».
/// Miroir web : `Cta` variantes `tcf` / `civique`.
enum SfButtonVariant { primary, blue, line, tcf, civique }

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
      SfButtonVariant.tcf => AppColors.moduleTcf,
      SfButtonVariant.civique => AppColors.moduleCivique,
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
///
/// **Navigation v2 (phase 4a)** : [civique] peint l'anneau à la couleur du
/// module (`.ring.red` de la maquette) — accent, piste et chiffre. `false` ⇒ le
/// rendu bleu d'avant, inchangé pour les lecteurs existants. Miroir web :
/// `Ring module`.
class SfRing extends StatelessWidget {
  const SfRing({
    super.key,
    required this.ratio,
    this.size = 40,
    this.stroke = 4,
    this.label,
    this.reached,
    this.civique = false,
  });

  final double ratio;
  final double size;
  final double stroke;

  /// Le texte du centre, composé par l'appelant. `null` = anneau muet.
  final String? label;

  /// Le seuil est-il atteint ? **Servi**, jamais déduit de [ratio].
  final bool? reached;

  final bool civique;

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
          color: vert ? AppColors.green : AppColors.module(civique: civique),
          track:
              civique ? AppColors.moduleLight(civique: true) : AppColors.line,
        ),
        child: texte == null
            ? null
            : Center(
                child: Text(
                  texte,
                  style: AppFonts.display(
                    size: size * 0.2,
                    weight: FontWeight.w800,
                    color: AppColors.moduleDark(civique: civique),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SfRingPainter extends CustomPainter {
  _SfRingPainter({
    required this.part,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double part;
  final double stroke;
  final Color color;
  final Color track;

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
        ..color = track,
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
      old.part != part ||
      old.color != color ||
      old.stroke != stroke ||
      old.track != track;
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
   **même traité segmenté que l'échelle TCF** (`SfLevelLadder`, supprimée à
   son tour le 2026-10-03). Refonte = suppression de l'ancien. [SfBarTone]
   reste — il teinte les pastilles de statut du kit. Miroir web :
   `ProgressMini`, supprimée dans la même passe. */

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
    this.civique = false,
  });

  /// 🛑 [SfNowCardVariant.verify] change **la carte**, pas seulement son
  /// bouton : quand la série de petits sujets se termine, le nom de la
  /// compétence reste le même, et sans accent propre le candidat lit « rien n'a
  /// bougé » alors que l'action a changé de nature. Miroir du `variant` du
  /// `NowCard` web.
  final SfNowCardVariant variant;

  /// Couleur du module de la pastille d'icône (TCF bleu, civique rouge).
  final bool civique;

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
                  color: verify
                      ? AppColors.amberDark
                      : AppColors.module(civique: civique),
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
          if (child != null) ...[const SizedBox(height: 16), child!],
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
    return Padding(
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
                    children: [for (final b in badges) _SfTopBadge(b)],
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
/// compte : [SfTop] annonce une **page** (retour en fleche, titre) ;
/// celui-ci coiffe un ecran **qu'on ferme** —
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

/// Le badge bleu de l'en-tête [SfTop] (`.sf-badge`). Privé depuis la phase
/// 4a de Navigation v2 : le nom public [SfBadge] est le miroir du `Badge` web
/// (`.badge` de la maquette) ; côté web, cette pastille d'en-tête est elle
/// aussi interne à `Top`.
class _SfTopBadge extends StatelessWidget {
  const _SfTopBadge(this.label);

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

  /// Les compteurs sont posés **sur un fond de marque** ([SfHero]) :
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

   🛑 Miroirs de `MicroNote`, `PanelHead` et `InfoNote` côté web. Un motif qui
   bouge d'un côté bouge de l'autre dans la même passe.

   ⚠️ « Où vous en êtes » a quitté l'Accueil (Navigation v2, phase 3,
   2026-10-03) : `SfLevelLadder` (+ `SfLadderStep`, `SfLadderState`),
   `SfLevelCard`, `SfLevelCardGrid` et `SfGoalBanner` sont **supprimées**
   avec lui, des deux côtés — refonte = suppression de l'ancien.
   ========================================================================== */

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
          const Positioned(
              left: 0, right: 0, bottom: 0, child: _SfDashedLine()),
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
/// [exam] est **la derniere etape de la file** — le [SfExamStepAction] du bloc.
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
    this.title,
    this.civique = false,
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

  /// **La carte « Cycle » de Navigation v2** (`.card.card-pad` de « Mon
  /// plan », maquette `sejourfr-navigation-mobile.html`) : [badge] (ou [label]
  /// sur un cycle clos) en intitulé, [title] (« Votre parcours vers le B2 ») en
  /// titre, le compteur `done/total` servi à droite, la barre à la couleur du
  /// module ([civique]), [hint] dessous. `null` ⇒ la forme historique.
  ///
  /// Miroir web : `CycleProgress title`.
  final String? title;

  /// La couleur de la barre de la variante [title].
  final bool civique;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final titre = title;
    if (titre != null) return _carte(titre, ratio);
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

  Widget _carte(String titre, double ratio) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
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
                      (badge ?? label).toUpperCase(),
                      style: AppFonts.label(size: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      titre,
                      style: AppFonts.display(
                          size: 16, weight: FontWeight.w700, height: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$done/$total',
                style: AppFonts.display(
                    size: 18, weight: FontWeight.w800, height: 1),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _SfBar(
            part: complete ? 1 : ratio,
            fill:
                complete ? AppColors.green : AppColors.module(civique: civique),
            track: AppColors.line,
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(
              hint!,
              style:
                  AppFonts.ui(size: 13, color: AppColors.muted, height: 1.35),
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
/// avec leur rail), puis un [SfExamStepAction]. Le corps ne porte donc aucun
/// retrait de rail — c'est la liste qui a le sien.
///
/// 🛑 **Le nom de l'epreuve ne se tronque jamais** et tient sur UNE ligne
/// (D-21). C'est la maquette qui le garantit : sous 360 px logiques elle
/// **masque l'etat** et l'en-tete passe a deux colonnes, plutot que de
/// retrecir le titre. Miroir exact du `@media(max-width:360px)` web.
///
/// **Variante LIEN** ([SfBlocAccordion.lien], « Mes cycles », 2026-09-27) : le
/// même en-tête, sans corps, qui **ouvre un écran** au lieu de se déplier — le
/// chevron pointe alors à droite. C'est ainsi que la liste des cycles terminés
/// mène à la consultation d'un cycle : un seul motif d'en-tête, pas une carte
/// de plus. Miroir de la prop `href` de `BlocAccordion`.
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
    required VoidCallback this.onToggle,
    required Widget this.child,
    this.current = false,
    this.icon,
    this.civique = false,
  }) : onOpen = null;

  /// La variante lien : l'en-tête ouvre un écran ([onOpen]), il n'a pas de corps.
  const SfBlocAccordion.lien({
    super.key,
    required this.mark,
    required this.title,
    required this.meta,
    required this.status,
    required VoidCallback this.onOpen,
    this.current = false,
  })  : open = false,
        onToggle = null,
        child = null,
        icon = null,
        civique = false;

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
  final VoidCallback? onToggle;

  /// La variante lien : ouvre un écran. `null` ⇒ l'en-tête déplie son corps.
  final VoidCallback? onOpen;

  /// Le bloc courant : filet et repere accentues. **Servi**, jamais deduit.
  final bool current;

  final Widget? child;

  /// **L'en-tête en `.info-card`** (Navigation v2, « Priorités actuelles ») :
  /// pastille d'icône douce du module, [mark] en badge au-dessus du titre,
  /// titre à l'encre, [meta] en clair, état en [SfBadge]. `null` ⇒ l'en-tête
  /// historique de `plan_cycle.html`.
  final IconData? icon;

  /// La teinte de la pastille et du badge de la variante [icon].
  final bool civique;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    final pictogramme = icon;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        // `.examGroup` de la maquette : filet fin au repos, filet plus marque
        // et relief plus porte sur `.current`.
        border:
            Border.all(color: current ? AppColors.lineStrong : AppColors.line),
        boxShadow: current ? AppShadows.md : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: onOpen == null ? open : null,
            child: InkWell(
              onTap: onOpen ?? onToggle,
              child: Padding(
                // Les valeurs de `.groupHead` dans
                // `docs/progression/plan_cycle.html` : `42px 1fr auto`,
                // `gap: 11px`, `padding: 15px`.
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    if (pictogramme != null) ...[
                      // Tailles de l'en-tête d'avant (repère 42, gap 11) —
                      // 2026-10-04, demande du propriétaire.
                      _SfSoftIconBox(
                          icon: pictogramme, civique: civique, size: 42),
                      const SizedBox(width: 11),
                    ] else if (mark.isNotEmpty) ...[
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: current ? AppColors.blue : AppColors.blueSoft,
                          // La maquette dit 13 ; le token le plus proche vaut 12.
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                              color: current ? AppColors.blue : AppColors.line),
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
                      child: pictogramme != null
                          ? _enTeteInfoCard()
                          : Column(
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
                    //
                    // ⚠️ **Sur la timeline du cycle, 388** (366 + les 22 px du
                    // rail, [SfCycleRail.retraitDe]) : miroir du
                    // `@media (max-width: 388px)` de `.railStep` cote web.
                    if (MediaQuery.sizeOf(context).width -
                            SfCycleRail.retraitDe(context) >
                        366) ...[
                      // L'état reste discret et colle au chevron (pastille
                      // dense, 2026-10-04, demande du propriétaire).
                      const SizedBox(width: 8),
                      SfPill(
                          label: status.label,
                          tone: status.tone.asBarTone,
                          dense: true),
                    ],
                    const SizedBox(width: 4),
                    // La seule affordance visible qu'un bloc se deplie. Le
                    // chevron PIVOTE, il ne se remplace pas — aucun saut de
                    // largeur a l'ouverture. La variante lien pointe a droite.
                    if (onOpen != null)
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.muted,
                      )
                    else
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
          if (onOpen == null && open && child != null)
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

  Widget _enTeteInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mark.isNotEmpty) ...[
          SfBadge(mark, civique: civique),
          const SizedBox(height: 4),
        ],
        Text(
          title,
          style:
              AppFonts.display(size: 14, weight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 3),
        Text(
          meta,
          style: AppFonts.ui(size: 10.5, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

/// Ce que l'étape d'examen porte **à droite** : un bouton de lancement
/// ([SfExamStepStart]), ou le constat qu'elle est passée ([SfExamStepDone]).
///
/// Miroir de `ExamStepTrailing` (`web .../sejour/SejourKit.tsx`).
sealed class SfExamStepTrailing {
  const SfExamStepTrailing();
}

/// Le bouton. **Inactif sans [onTap]** ; [locked] ajoute le cadenas. Le kit ne
/// décide ni de l'un ni de l'autre.
class SfExamStepStart extends SfExamStepTrailing {
  const SfExamStepStart({
    required this.label,
    required this.locked,
    this.onTap,
  });

  final String label;
  final bool locked;
  final VoidCallback? onTap;
}

/// Une pastille cochée, sans geste.
class SfExamStepDone extends SfExamStepTrailing {
  const SfExamStepDone({required this.label});

  final String label;
}

/// **L'étape d'examen d'un bloc de cycle** : titre et sous-titre à gauche, le
/// bouton à droite (demande du propriétaire, 2026-09-26).
///
/// 🛑 **Aucune phrase n'est écrite ici**, et aucun état n'est classé : le titre,
/// le sous-titre, le libellé du bouton, la phrase de pied et son lien arrivent
/// tous en paramètres. Un bouton inactif se lit avec son cadenas **et** sa
/// phrase de pied — jamais un bouton muet sans raison.
///
/// Miroir web : `ExamStepAction`. Elle sert aussi la consultation d'un cycle
/// clos (« Mes cycles ») : sans [trailing] de lancement, elle y est inerte.
class SfExamStepAction extends StatelessWidget {
  const SfExamStepAction({
    super.key,
    this.civique = false,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.note,
    this.noteAction,
  });

  /// La couleur du bouton : celle du module (civique rouge). Miroir web :
  /// `ExamStepAction.module`.
  final bool civique;
  final String title;
  final String subtitle;
  final SfExamStepTrailing? trailing;

  /// Pourquoi le bouton est inactif, en une phrase courte.
  final String? note;

  /// Le geste qui lève le verrou, sous la phrase de pied.
  final ({String label, VoidCallback onTap})? noteAction;

  @override
  Widget build(BuildContext context) {
    final droite = switch (trailing) {
      SfExamStepDone(:final label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.check, size: 13, color: AppColors.green),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: AppFonts.label(size: 10, color: AppColors.green)
                  .copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      final SfExamStepStart start => _SfExamStepButton(start, civique: civique),
      null => null,
    };
    final pied = note != null || noteAction != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
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
                        size: 12.5,
                        weight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppFonts.ui(
                          size: 11, color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (droite != null) ...[
                const SizedBox(width: 10),
                droite,
              ],
            ],
          ),
          if (pied) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (note != null)
                  Text(
                    note!,
                    style: AppFonts.ui(
                        size: 10.5, color: AppColors.muted, height: 1.4),
                  ),
                if (noteAction != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: noteAction!.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        noteAction!.label,
                        style: AppFonts.ui(size: 10.5, color: AppColors.blue)
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Le bouton « Commencer » de [SfExamStepAction] : bleu et actif, ou grisé et
/// inactif, avec son cadenas quand l'étape est verrouillée.
class _SfExamStepButton extends StatelessWidget {
  const _SfExamStepButton(this.start, {required this.civique});

  final SfExamStepStart start;
  final bool civique;

  @override
  Widget build(BuildContext context) {
    final actif = start.onTap != null;
    final encre = actif ? AppColors.white : AppColors.muted;
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      enabled: actif,
      child: Material(
        color: actif ? AppColors.module(civique: civique) : AppColors.line,
        borderRadius: radius,
        child: InkWell(
          onTap: start.onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (start.locked) ...[
                    Icon(LucideIcons.lock, size: 12, color: encre),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    start.label,
                    style: AppFonts.ui(size: 11.5, color: encre)
                        .copyWith(fontWeight: FontWeight.w800),
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

/// Un fait de la carte de fin de cycle : une valeur et ce qu'elle nomme.
typedef SfNextStepFact = ({String value, String label});

/// **La carte de fin de cycle** — le `.finalCard` de `cycle_termine.html`.
///
/// ⚠️ **Une seule action depuis le 2026-09-27** (D-66) : « Actualiser mon
/// plan ». Le second terme « Passer l'examen blanc complet » a quitte la fin de
/// cycle — il est devenu un jalon au-dessus du Plan — et l'emplacement
/// secondaire est supprime avec lui (plus aucun appelant).
///
/// 🛑 **Aucune phrase n'est ecrite ici** : [eyebrow], [title], [text], les
/// [facts] et le libelle d'action arrivent tous en parametres.
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
  });

  final String eyebrow;
  final String title;
  final String text;

  /// Les reperes de la carte. Vide ⇒ aucune grille.
  final List<SfNextStepFact> facts;

  final ({String label, VoidCallback onPressed}) primary;

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  style: AppFonts.ui(size: 13, color: doux, height: 1.5),
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  // 🛑 `IntrinsicHeight` est OBLIGATOIRE : la carte vit dans une liste
                  // qui défile (hauteur non bornée), et une `Row` `stretch` y lève
                  // « BoxConstraints forces an infinite height ». En release, la carte
                  // entière disparaissait, bouton « Actualiser mon plan » compris
                  // (prod, 2026-10-03). Même garde que les autres rangées du kit.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < facts.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.10),
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
                  ),
                ],
                const SizedBox(height: 15),
                // Le CTA rouge est celui du kit : une seule definition de
                // bouton principal, ici comme partout.
                SfButton(
                  label: primary.label,
                  onPressed: primary.onPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================================
   La timeline du cycle (demande du proprietaire, 2026-09-27)

   Un rail vertical ETROIT a gauche des blocs : un rond par bloc, relie par un
   trait, et une derniere etape « Fin du cycle » en bas. 🛑 Miroirs de
   `CycleRail`, `CycleRailStep` et `CycleRailEnd` cote web, brique pour brique
   et au pixel pres : rond 14, trait 2, gouttiere 8 — soit 22 px pris aux
   cartes, pas un de plus. Les memes chiffres vivent dans `sejour.module.css`
   (`.rail`) ; l'un ne bouge pas sans l'autre.
   ========================================================================= */

const double _kRailDot = 14;
const double _kRailGap = 8;
const double _kRailLine = 2;

/// Le rond est centre sur l'en-tete d'un [SfBlocAccordion] : 15 de marge + la
/// moitie du repere de 42 = 36, moins la moitie du rond.
const double _kRailDotTop = 29;

/// La derniere etape : le rond s'aligne sur la premiere ligne de l'encart.
const double _kRailEndDotTop = 16;

/// L'etat d'un rond de la timeline. **Passe**, jamais deduit ici : l'ecran le
/// traduit du statut servi du bloc. Miroir web : `RailState`.
enum SfRailState { done, current, upcoming }

/// **La timeline du cycle** — le conteneur du rail.
///
/// Le trait est dessine **par etape** (du haut de l'etape jusqu'a la suivante,
/// en franchissant l'ecart [sfGap]), et coupe au rond de la premiere et de la
/// derniere : aucune hauteur n'est mesuree, la timeline suit ce que les cartes
/// deviennent en se depliant.
///
/// ⚠️ **22 px de moins pour les cartes** : [retraitDe] les rend a
/// [SfBlocAccordion], dont le palier « pastille d'etat masquee » passe ainsi de
/// 366 a 388 px sur la timeline — le rond dit alors l'etat, et le nom
/// d'epreuve reste sur une ligne (D-21). Miroir du `@media (max-width: 388px)`
/// de `.railStep`.
///
/// Miroir web : `CycleRail`.
class SfCycleRail extends StatelessWidget {
  const SfCycleRail({super.key, required this.children});

  /// Des [SfCycleRailStep], puis un [SfCycleRailEnd].
  final List<Widget> children;

  /// La largeur que la timeline prend aux cartes posees dessus, `0` hors
  /// timeline.
  static double retraitDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SfRailSlot>() == null
          ? 0
          : _kRailDot + _kRailGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: sfGap),
          _SfRailSlot(
            first: i == 0,
            last: i == children.length - 1,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

/// La position d'une etape dans la timeline — premiere, derniere — que le trait
/// lit pour se couper au rond (`:first-child` / `:last-child` cote web).
class _SfRailSlot extends InheritedWidget {
  const _SfRailSlot({
    required this.first,
    required this.last,
    required super.child,
  });

  final bool first;
  final bool last;

  @override
  bool updateShouldNotify(_SfRailSlot oldWidget) =>
      first != oldWidget.first || last != oldWidget.last;
}

/// Le squelette commun d'une etape : le trait, le rond, la carte a droite.
class _SfRailItem extends StatelessWidget {
  const _SfRailItem({
    required this.dot,
    required this.dotTop,
    required this.child,
  });

  final Widget dot;
  final double dotTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slot = context.dependOnInheritedWidgetOfExactType<_SfRailSlot>();
    final first = slot?.first ?? true;
    final last = slot?.last ?? true;
    final centre = dotTop + _kRailDot / 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!(first && last))
          Positioned(
            left: (_kRailDot - _kRailLine) / 2,
            width: _kRailLine,
            top: first ? centre : 0,
            // Le trait franchit l'ecart jusqu'a l'etape suivante.
            bottom: last ? null : -sfGap,
            height: last ? centre : null,
            child: const ColoredBox(color: AppColors.lineStrong),
          ),
        Padding(
          padding: const EdgeInsets.only(left: _kRailDot + _kRailGap),
          child: child,
        ),
        Positioned(left: 0, top: dotTop, child: dot),
      ],
    );
  }
}

/// **Une etape de la timeline** : un rond a gauche, la carte a droite, recue
/// **telle quelle** ([SfBlocAccordion] sur le Plan).
///
/// - [SfRailState.done] — rond plein bleu, coche ;
/// - [SfRailState.current] — rond epais bleu, le bloc en cours ;
/// - [SfRailState.upcoming] — rond gris au trait fin.
///
/// Miroir web : `CycleRailStep`.
class SfCycleRailStep extends StatelessWidget {
  const SfCycleRailStep({super.key, required this.state, required this.child});

  final SfRailState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: _kRailDot,
      height: _kRailDot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == SfRailState.done ? AppColors.blue : AppColors.white,
        border: Border.all(
          color: state == SfRailState.upcoming
              ? AppColors.lineStrong
              : AppColors.blue,
          width: state == SfRailState.current ? 4 : 2,
        ),
      ),
      child: state == SfRailState.done
          ? const Icon(LucideIcons.check, size: 9, color: AppColors.white)
          : null,
    );
    return _SfRailItem(dot: dot, dotTop: _kRailDotTop, child: child);
  }
}

/// **La derniere etape de la timeline** — « Fin du cycle », rond etoile.
///
/// - **Non atteinte** : un encart en pointilles, attenue — [eyebrow], [title]
///   et, s'il reste des etapes, la pastille [remaining] (« Encore 4 etapes »).
/// - **Atteinte** ([reached] + [child]) : l'encart disparait et **l'action
///   prend sa place** — la carte de fin de cycle existante, jamais un second
///   bouton qui la dupliquerait.
/// - **Franchie** ([done], consultation d'un cycle clos, 2026-09-27) : l'encart
///   devient **plein** — ni pointilles, ni attenuation — et porte [note]
///   (« Le 27 sept. 2026 »). Aucun geste : un cycle clos ne se rejoue pas.
///
/// 🛑 **Aucune phrase n'est ecrite ici**, et rien n'est compte : les libelles
/// arrivent en parametres.
///
/// Miroir web : `CycleRailEnd`.
class SfCycleRailEnd extends StatelessWidget {
  const SfCycleRailEnd({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.reached,
    this.remaining,
    this.done = false,
    this.note,
    this.child,
  });

  /// La fin a ete franchie : l'encart est plein, et lu tel quel.
  final bool done;

  /// La ligne sous le titre, **servie** : la date d'une fin franchie, ou
  /// « 3 priorités identifiées » sur une fin à venir (D-67, 2026-09-27).
  final String? note;

  final String eyebrow;
  final String title;

  /// « Encore N etapes ». `null` ⇒ aucune pastille.
  final String? remaining;
  final bool reached;

  /// L'action de fin de cycle, rendue **a la place** de l'encart une fois
  /// atteinte.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final action = child;
    final dot = Container(
      width: _kRailDot,
      height: _kRailDot,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blueDark,
      ),
      child: const Icon(Icons.star_rounded, size: 10, color: AppColors.white),
    );
    final contenu = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.ui(
              size: 15,
              weight: FontWeight.w800,
              color: AppColors.ink2,
              height: 1.3,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.4),
            ),
          ],
          if (remaining != null) ...[
            const SizedBox(height: 8),
            SfPill(label: remaining!, tone: SfBarTone.warn),
          ],
        ],
      ),
    );
    final Widget body;
    if (reached && action != null) {
      body = action;
    } else if (done) {
      // Franchie : un encart plein, lu tel quel (`.railEndDone` cote web).
      body = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: contenu,
      );
    } else {
      body = CustomPaint(painter: const _SfDashedBoxPainter(), child: contenu);
    }
    return _SfRailItem(dot: dot, dotTop: _kRailEndDotTop, child: body);
  }
}

/// Le cadre en pointilles de [SfCycleRailEnd] (`1.5px dashed` cote web).
class _SfDashedBoxPainter extends CustomPainter {
  const _SfDashedBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.5;
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = AppColors.lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadii.lg),
    ).deflate(stroke / 2);
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
              distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SfDashedBoxPainter oldDelegate) => false;
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
/// 🛑 **Distinct du hero voisin**, qu'il ne faut pas remplacer par lui :
/// - [SfHero] **presente** un ecran ou un geste de module (Navigation v2) ;
///
/// Celui-ci porte un **avancement** : un compteur, un rail et sa lecture en
/// pourcentage. C'est ce qui lui evite d'en etre une variante.
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
                    style: AppFonts.ui(size: 13, weight: FontWeight.w700),
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
/// **Carte JOUÉE = carte COMPACTE** (demande du propriétaire, 2026-09-27) :
/// quand [verdict] et [onOpen] sont posés, la carte se réduit à une ligne
/// touchable — repère à **coche verte** ([SfSerieVerdict.ok]) ou **croix
/// rouge** ([SfSerieVerdict.fail]), le motif des cartes de séries et d'examens
/// blancs du web (`serieCheck` / `examCheckFail`) —, titre, score et état. Ni
/// gros bouton ni lien : « Refaire » et le corrigé passent par la feuille que
/// l'appelant ouvre (`showAppSheet`, la même que les sujets déjà traités).
/// 🛑 **Une variante, pas une primitive de plus.**
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
    this.verdict,
    this.onOpen,
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

  /// Le verdict d'une série **jouée**, composé par l'appelant sur des faits
  /// servis. Avec [onOpen], il rend la carte compacte ; `null` = carte à faire.
  final SfSerieVerdict? verdict;

  /// Le toucher d'une carte compacte : la feuille « corrigé / refaire ».
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final verdict = this.verdict;
    final onOpen = this.onOpen;
    if (verdict != null && onOpen != null) {
      return _compacte(verdict, onOpen);
    }
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
                            style:
                                AppFonts.ui(size: 12, color: AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(LucideIcons.listChecks,
                            size: 13, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            questions,
                            style:
                                AppFonts.ui(size: 12, color: AppColors.muted),
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

  Widget _compacte(SfSerieVerdict verdict, VoidCallback onOpen) {
    final ok = verdict == SfSerieVerdict.ok;
    final teinte = ok ? AppColors.green : AppColors.red;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Le repère teinté + la pastille cochée (verte) ou barrée
                // (rouge) en coin : le motif des cartes de séries.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ok ? AppColors.greenLight : AppColors.redLight,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Text(
                        mark,
                        style: AppFonts.label(size: 13, color: teinte),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: teinte,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Icon(
                          ok ? LucideIcons.check : LucideIcons.x,
                          size: 10,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
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
                      if (score != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          score!,
                          style: AppFonts.ui(size: 12, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.label.toUpperCase(),
                  style: AppFonts.ui(
                    size: 10,
                    weight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: _sfStatusColor(state.tone),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight,
                    size: 16, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le verdict d'une série **jouée** — composé par l'appelant sur `validee` et
/// la présence d'un score, **jamais** en comparant ce score à un seuil.
enum SfSerieVerdict { ok, fail }

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
// Miroirs web (mêmes noms, sans `Sf`) : `ProgressIntro`, `ProgressHero`,
// `ProgressStatTile`, `ProgressStatGrid`, `ProgressDomainCard`,
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
        canvas.drawCircle(pts[i], 11,
            Paint()..color = AppColors.blue.withValues(alpha: 0.14));
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

/// **Une ligne d'examen global** : l'ordinal et la date, le badge global
/// (palier TCF ou « Global : 29 / 40 »). Le détail par épreuve / par thème
/// n'est pas repris en portrait téléphone (2026-10-03, demande du
/// propriétaire) : il se lit dans le rapport que la ligne ouvre. Le web le
/// garde au palier large (`ProgressGlobalExamRow`, `.pRowParts`).
///
/// Miroir web : `ProgressGlobalExamRow`.
class SfProgressGlobalExamRow extends StatelessWidget {
  const SfProgressGlobalExamRow({
    super.key,
    required this.title,
    required this.badge,
    required this.onTap,
    this.date,
    this.meta,
    this.badgeTone = SfBarTone.now,
  });

  final String title;
  final String? date;

  /// Une précision servie (« Partiel : 3 épreuves sur 4 »). `null` = rien.
  final String? meta;
  final String badge;
  final SfBarTone badgeTone;
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
        ],
      ),
    );
  }
}

/* ==========================================================================
   NAVIGATION V2 (2026-10-03) — en-tête de module, carte « Ma progression »,
   lien retour. Maquette : `docs/redesign/sejourfr-navigation-mobile.html`
   (`.kicker`, `h1`, `.subtitle`, `.progress-summary`, `.back-link`).
   Miroirs web, mêmes noms sans `Sf` : `ModuleHeader`, `ProgressSummary`,
   `BackLink`. Le segment « Plan | Entraînement | Examens » est
   `SegmentedTabs(shape: SegmentedTabsShape.module)` (`core/widgets/`).
   ========================================================================== */

/// **L'en-tête d'un écran de module** (onglet TCF ou Civique) : la pastille
/// kicker teintée du module, le grand titre, la phrase de cadrage.
///
/// 🛑 Textes **statiques** fournis par l'écran ; la couleur vient du module
/// ([AppColors.moduleLight] / [AppColors.moduleDark]), jamais d'un hex.
class SfModuleHeader extends StatelessWidget {
  const SfModuleHeader({
    super.key,
    required this.civique,
    this.kicker,
    required this.title,
    this.lead,
  });

  final bool civique;

  /// `null` ⇒ pas de pastille (l'Accueil d'un compte sans démarche déclarée).
  final String? kicker;
  final String title;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final pastille = kicker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pastille != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.moduleLight(civique: civique),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              pastille.toUpperCase(),
              style: AppFonts.ui(
                size: 11,
                weight: FontWeight.w800,
                color: AppColors.moduleDark(civique: civique),
                letterSpacing: 0.7,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          title,
          style:
              AppFonts.display(size: 28, weight: FontWeight.w800, height: 1.05),
        ),
        if (lead != null) ...[
          const SizedBox(height: 8),
          Text(
            lead!,
            style: AppFonts.ui(size: 16, color: AppColors.muted, height: 1.45),
          ),
        ],
      ],
    );
  }
}

/// **La carte « Ma progression »** d'un écran de module : un libellé, une
/// valeur (« B1 → B2 » ou « 39 % »), une méta, et « Voir le détail ».
///
/// [from] est la valeur de départ (niveau actuel), affichée à l'encre et suivie
/// d'une flèche ; [value] est la valeur mise en avant, à la couleur du module.
/// `from == null` ⇒ une seule valeur (le % civique). 🛑 Aucune valeur n'est
/// calculée ici : l'écran passe des faits servis ou leur agrégat documenté.
class SfProgressSummary extends StatelessWidget {
  const SfProgressSummary({
    super.key,
    required this.civique,
    required this.label,
    required this.value,
    required this.action,
    required this.onTap,
    this.from,
    this.meta,
  });

  final bool civique;
  final String label;
  final String? from;
  final String value;
  final String? meta;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.module(civique: civique);
    final big = AppFonts.display(size: 22, weight: FontWeight.w800, height: 1);
    // Fond blanc PORTÉ par la décoration : une ombre posée sur un conteneur
    // sans couleur se voit au travers et grise la carte.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.md,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: AppFonts.label(size: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (from != null) ...[
                            Text(from!, style: big),
                            const SizedBox(width: 8),
                            Text(
                              '→',
                              style: AppFonts.display(
                                size: 19,
                                weight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: big.copyWith(color: accent),
                            ),
                          ),
                        ],
                      ),
                      if (meta != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          meta!,
                          style: AppFonts.ui(
                            size: 14,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action,
                      style: AppFonts.ui(
                        size: 12,
                        weight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 17, color: accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// **Le lien retour** d'un écran poussé depuis un module (« ‹ TCF IRN »,
/// « ‹ Examen civique »), à la couleur du module.
class SfBackLink extends StatelessWidget {
  const SfBackLink({
    super.key,
    required this.civique,
    required this.label,
    required this.onTap,
  });

  final bool civique;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.module(civique: civique);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.chevronLeft, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppFonts.ui(
                  size: 14,
                  weight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==========================================================================
   NAVIGATION V2 — ACCUEIL (phase 3, 2026-10-03). Maquette :
   `docs/redesign/sejourfr-navigation-mobile.html` (`.objectives-card`,
   `.objective-row`, `.objective-divider`, `.action-card`, `.iconbox`, `.cta`).
   Miroirs web, mêmes noms sans `Sf` : `ObjectivesCard`, `ObjectiveRow`,
   `ActionCard`, `BlockSkeleton`, `BlockError`. (`SfObjCard` / `SfObjMetric`,
   créés en phase 3 sans lecteur mobile, sont supprimés en phase 4a.)
   🛑 Aucune de ces briques ne calcule : l'écran passe des faits servis, ou
   leur agrégat documenté, déjà mis en mots.
   ========================================================================== */

/// **Une ligne d'objectif** (`.objective-row`) : pictogramme doux du module,
/// libellé du module, objectif, méta, et la valeur à la couleur du module
/// suivie d'un chevron. Se range dans [SfObjectivesCard].
class SfObjectiveRow extends StatelessWidget {
  const SfObjectiveRow({
    super.key,
    required this.civique,
    required this.icon,
    required this.label,
    required this.title,
    this.meta,
    required this.value,
    this.onTap,
  });

  final bool civique;
  final IconData icon;

  /// Le nom du module (« TCF IRN », « Examen civique »), en petites capitales.
  final String label;
  final String title;
  final String? meta;

  /// « B1 → B2 », « 39 % ». Déjà composée par l'écran.
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.module(civique: civique);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.moduleLight(civique: civique),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, size: 24, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppFonts.label(size: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppFonts.display(
                        size: 16, weight: FontWeight.w700, height: 1.2),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta!,
                      style: AppFonts.ui(
                          size: 13, color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: AppFonts.display(
                  size: 16, weight: FontWeight.w800, color: accent, height: 1),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 17, color: accent),
          ],
        ),
      ),
    );
  }
}

/// **La carte groupée « Mes objectifs »** (`.objectives-card`) : des
/// [SfObjectiveRow] séparées par un filet aligné sur le texte
/// (`.objective-divider`).
class SfObjectivesCard extends StatelessWidget {
  const SfObjectivesCard({super.key, required this.rows});

  final List<SfObjectiveRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Material(
          color: AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Padding(
                    // 16 (marge) + 48 (pictogramme) + 12 (écart) = 76.
                    padding: EdgeInsets.only(left: 76, right: 16),
                    child:
                        Divider(height: 1, thickness: 1, color: AppColors.line),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// **La carte d'action** de « À faire maintenant » (`.action-card`) : pastille
/// pleine du module, libellé du module, titre, méta, badge optionnel, puis le
/// CTA plein à la couleur du module, sur toute la largeur.
///
/// 🛑 **Sans geste, pas de bouton** : [onPressed] `null` ⇒ la carte passe en
/// état neutre (pastille douce, aucun CTA) — jamais un bouton mort.
class SfActionCard extends StatelessWidget {
  const SfActionCard({
    super.key,
    required this.civique,
    required this.icon,
    required this.label,
    required this.title,
    this.meta,
    this.badge,
    this.note,
    this.cta,
    this.onPressed,
  });

  final bool civique;
  final IconData icon;

  /// Une ligne discrète sous l'en-tête, avant le bouton — le pendant du
  /// `children` de `ActionCard` web (`.actionNote`). `null` ⇒ rien.
  final String? note;

  /// Le nom du module (« TCF IRN », « Examen civique »).
  final String label;
  final String title;
  final String? meta;

  /// Un repère court et factuel à droite (code d'épreuve). `null` ⇒ rien.
  final String? badge;
  final String? cta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final actif = cta != null && onPressed != null;
    final accent = AppColors.module(civique: civique);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      actif ? accent : AppColors.moduleLight(civique: civique),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: actif ? AppColors.white : accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppFonts.label(size: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppFonts.display(
                          size: 17, weight: FontWeight.w700, height: 1.2),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta!,
                        style: AppFonts.ui(
                            size: 13, color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.moduleLight(civique: civique),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    badge!,
                    style: AppFonts.label(
                        size: 11,
                        color: AppColors.moduleDark(civique: civique)),
                  ),
                ),
              ],
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(
              note!,
              style:
                  AppFonts.ui(size: 13, color: AppColors.muted, height: 1.45),
            ),
          ],
          if (actif) ...[
            const SizedBox(height: 16),
            SfButton(
              label: cta!,
              variant: civique ? SfButtonVariant.civique : SfButtonVariant.tcf,
              onPressed: onPressed,
            ),
          ],
        ],
      ),
    );
  }
}

/// **Le squelette d'un bloc qui charge** : un aplat aux dimensions du
/// composant attendu, jamais une roue plein écran (brief §7).
class SfBlockSkeleton extends StatelessWidget {
  const SfBlockSkeleton({
    super.key,
    required this.height,
    this.radius = AppRadii.xl,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// **L'erreur d'un bloc** : un message et « Réessayer », dans le bloc
/// concerné — le reste de l'écran reste utilisable (brief §7).
class SfBlockError extends StatelessWidget {
  const SfBlockError({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.cloudOff, size: 20, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppFonts.ui(size: 14, color: AppColors.ink2, height: 1.35),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              retryLabel,
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ==========================================================================
   NAVIGATION V2 — PRIMITIVES DES ÉCRANS DE MODULE (phase 4a, 2026-10-03).
   Maquette : `docs/redesign/sejourfr-navigation-mobile.html` (`.hero`,
   `.info-card`, `.metric`, `.timeline` / `.step`, `.ring`,
   `.exam-row`, `.progression-head` / `.target`) et, pour [SfThemeCard] et
   [SfTipCard] absents de la maquette mobile, `sejourfr-navigation-web.html`
   (`.theme-card`, `.tip-card`) ramenés au portrait.
   Miroirs web, mêmes noms sans `Sf` : `Hero`, `InfoCard`, `Metric`,
   `Timeline`, `ThemeCard`, `TipCard`,
   `ProgressionHead`, `ExamRow`. Le `module: "tcf" | "civique"` du web est ici
   `civique: bool`, comme [SfActionCard].
   Rayons de la maquette (16 → 30 px) arrondis aux [AppRadii] (DEC-10).
   🛑 Aucune de ces briques ne classe ni ne calcule : états, tons, niveaux,
   compteurs et pourcentages arrivent servis (ou agrégés par la fonction
   documentée de l'écran), déjà mis en mots.
   ========================================================================== */

/// Un état **servi** et son ton : « Objectif atteint » / [SfTone.ok],
/// « À renforcer » / [SfTone.warn]… Le `tone` du web (`success | warning |
/// danger | neutral`) se lit [SfTone.ok] / [SfTone.warn] / [SfTone.hot] /
/// [SfTone.muted].
typedef SfState = ({String label, SfTone tone});

/// **La pastille de la maquette** (`.badge`, `.badge.red`, `.badge.green`,
/// `.badge.amber`) : code court (« CO »), compteur (« {terminées}/{total} séries ») ou état
/// servi.
///
/// - [tone] posé ⇒ couleurs de l'état servi ;
/// - sinon ⇒ teinte douce du module ([civique]).
/// - [check] ⇒ une coche avant le texte ; [label] `null` ⇒ la coche seule
///   (nommée par [semanticLabel]).
///
/// Miroir web : `Badge` (`module`, `tone?`, `check`, `label`).
class SfBadge extends StatelessWidget {
  const SfBadge(
    this.label, {
    super.key,
    this.civique = false,
    this.tone,
    this.check = false,
    this.semanticLabel,
  });

  final String? label;
  final bool civique;
  final SfTone? tone;
  final bool check;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ton = tone;
    final fond = ton?.soft ?? AppColors.moduleLight(civique: civique);
    final encre = ton?.text ?? AppColors.module(civique: civique);
    final texte = label;
    return Semantics(
      label: texte == null ? semanticLabel : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 26, minWidth: 26),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (check) Icon(LucideIcons.check, size: 13, color: encre),
            if (check && texte != null) const SizedBox(width: 5),
            if (texte != null)
              Text(
                texte,
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: encre,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La pastille d'icône douce du module (`.iconbox.soft` / `.iconbox.soft-red`).
class _SfSoftIconBox extends StatelessWidget {
  const _SfSoftIconBox({
    required this.icon,
    required this.civique,
    this.size = 54,
  });

  final IconData icon;
  final bool civique;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.moduleLight(civique: civique),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: AppColors.module(civique: civique),
      ),
    );
  }
}

/// L'emphase d'un CTA de carte (`.cta` de la maquette) : [solid] = plein à la
/// couleur du module (le geste que le serveur désigne), [soft] = gris doux,
/// texte encre (`.cta.soft`, les autres tuiles d'épreuve), [ghost] = fond doux
/// du module, texte du module (`.cta.ghost-*`, cartes de thème). Miroir web :
/// `CtaEmphasis` (`"solid" | "soft" | "ghost"`).
enum SfCtaEmphasis { solid, soft, ghost }

/// Le CTA pleine largeur d'une carte de grille (`.cta` de `.metric` et de
/// `.theme-card`) : plus compact que [SfButton] — il doit tenir dans une
/// demi-largeur de téléphone ; flèche sur l'emphase pleine seulement.
class _SfCardCta extends StatelessWidget {
  const _SfCardCta({
    required this.label,
    required this.civique,
    required this.emphasis,
    required this.onPressed,
  });

  final String label;
  final bool civique;
  final SfCtaEmphasis emphasis;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final solid = emphasis == SfCtaEmphasis.solid;
    final encre = switch (emphasis) {
      SfCtaEmphasis.solid => AppColors.white,
      SfCtaEmphasis.soft => AppColors.ink,
      SfCtaEmphasis.ghost => AppColors.module(civique: civique),
    };
    return Material(
      color: switch (emphasis) {
        SfCtaEmphasis.solid => AppColors.module(civique: civique),
        SfCtaEmphasis.soft => AppColors.surface3,
        SfCtaEmphasis.ghost => AppColors.moduleLight(civique: civique),
      },
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 15,
                    weight: FontWeight.w800,
                    color: encre,
                  ),
                ),
              ),
              if (solid) ...[
                const SizedBox(width: 6),
                const Icon(LucideIcons.arrowRight,
                    size: 16, color: AppColors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// La barre d'avancement d'une carte (`.progress`, `.progress.red`,
/// `.progress.white`). 🛑 [part] est une part (0 → 1) **déjà calculée** par
/// l'écran.
class _SfBar extends StatelessWidget {
  const _SfBar({required this.part, required this.fill, required this.track});

  final double part;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final p = part.isNaN || part.isInfinite ? 0.0 : part.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: LinearProgressIndicator(
        value: p,
        minHeight: 8,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}

/// **Le bandeau dégradé d'un module** (`.hero`, `.hero.red`) : intitulé,
/// titre, phrase, chiffre clé à droite, barre blanche, CTA translucide.
///
/// Évolution de l'ancien `SfHeroBanner` (bandeau de l'historique des cycles),
/// renommé en phase 4a pour ne pas doubler le motif : [child] reste le slot
/// où cet écran pose ses compteurs ([SfStatGrid] `onHero`).
///
/// 🛑 Rien n'est composé ici : [stat], [progress] et les textes arrivent
/// prêts. [progress] `null` ⇒ pas de barre ; [cta] ou [onPressed] `null` ⇒
/// pas de bouton (jamais un bouton mort).
///
/// Miroir web : `Hero`.
class SfHero extends StatelessWidget {
  const SfHero({
    super.key,
    required this.civique,
    required this.label,
    required this.title,
    this.sub,
    this.stat,
    this.progress,
    this.cta,
    this.onPressed,
    this.icon,
    this.child,
  });

  final bool civique;

  /// L'intitulé en petites capitales (« Progression globale »).
  final String label;
  final String title;
  final String? sub;

  /// Le chiffre clé à droite (« {pct} % » / « du parcours »).
  final SfStat? stat;

  /// Part (0 → 1) de la barre blanche.
  final double? progress;
  final String? cta;
  final VoidCallback? onPressed;

  /// Le pictogramme posé devant l'intitulé. `null` ⇒ intitulé seul.
  final IconData? icon;

  /// Ce que l'écran pose sous le bandeau (compteurs de l'historique).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final doux = AppColors.white.withValues(alpha: 0.84);
    final chiffre = stat;
    final part = progress;
    final geste = cta;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.module(civique: civique),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          children: [
            // Les deux halos de `.hero::before` / `.hero::after`.
            Positioned(
              right: -70,
              top: -90,
              child: _SfHalo(size: 300, alpha: 0.16),
            ),
            Positioned(
              right: 60,
              bottom: -130,
              child: _SfHalo(size: 240, alpha: 0.10),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
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
                            Row(
                              children: [
                                if (icon != null) ...[
                                  Icon(icon, size: 14, color: doux),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    label.toUpperCase(),
                                    style:
                                        AppFonts.label(size: 11, color: doux),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: AppFonts.display(
                                size: 24,
                                weight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1.05,
                              ),
                            ),
                            if (sub != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                sub!,
                                style: AppFonts.ui(
                                    size: 13, color: doux, height: 1.45),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (chiffre != null) ...[
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              chiffre.value,
                              style: AppFonts.display(
                                size: 24,
                                weight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chiffre.label,
                              style: AppFonts.ui(size: 11, color: doux),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (part != null) ...[
                    const SizedBox(height: 14),
                    _SfBar(
                      part: part,
                      fill: AppColors.white,
                      track: AppColors.white.withValues(alpha: 0.24),
                    ),
                  ],
                  if (geste != null && onPressed != null) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SfHeroCta(label: geste, onPressed: onPressed!),
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
      ),
    );
  }
}

/// Un halo radial blanc décoratif d'un bandeau dégradé.
class _SfHalo extends StatelessWidget {
  const _SfHalo({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.white.withValues(alpha: alpha),
              AppColors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le bouton translucide d'un [SfHero] (`.hero-cta`).
class _SfHeroCta extends StatelessWidget {
  const _SfHeroCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight,
                  size: 16, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le chevron d'une ligne cliquable (`.chev`) — le `trailing="chevron"` du
/// web.
class SfChevron extends StatelessWidget {
  const SfChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(LucideIcons.chevronRight,
        size: 18, color: AppColors.muted2);
  }
}

/// Le cadre commun des lignes blanches cliquables (`.info-card`,
/// `.exam-row`).
class _SfRowFrame extends StatelessWidget {
  const _SfRowFrame({
    required this.padding,
    required this.child,
    this.onTap,
  });

  final EdgeInsets padding;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(AppRadii.lg);
    return Material(
      color: AppColors.white,
      borderRadius: rayon,
      child: InkWell(
        onTap: onTap,
        borderRadius: rayon,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: rayon,
            border: Border.all(color: AppColors.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// **La ligne d'information** (`.info-card`) : pastille d'icône douce, badge
/// court optionnel, titre, méta, et en bout [trailing] — [SfChevron],
/// [SfBadge] ou tout bloc court.
///
/// Miroir web : `InfoCard`.
class SfInfoCard extends StatelessWidget {
  const SfInfoCard({
    super.key,
    this.civique = false,
    required this.icon,
    this.code,
    required this.title,
    this.meta,
    this.trailing,
    this.onTap,
  });

  final bool civique;
  final IconData icon;

  /// Badge court au-dessus du titre (code d'épreuve). `null` ⇒ rien.
  final String? code;
  final String title;
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bout = trailing;
    return _SfRowFrame(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SfSoftIconBox(icon: icon, civique: civique),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (code != null) ...[
                  SfBadge(code!, civique: civique),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: AppFonts.display(
                      size: 16, weight: FontWeight.w700, height: 1.2),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta!,
                    style: AppFonts.ui(
                        size: 13, color: AppColors.muted, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (bout != null) ...[
            const SizedBox(width: 12),
            bout,
          ],
        ],
      ),
    );
  }
}

/// **La tuile d'épreuve** (`.metric`) : code, valeur en gros (niveau servi,
/// « — » s'il manque), état servi au ton servi, méta, CTA.
///
/// 🛑 [ctaEmphasis] est une décision d'ÉCRAN lue sur un fait servi (l'épreuve
/// que le serveur désigne prioritaire) — le kit n'élit rien. Dans une grille,
/// la tuile s'étire à la hauteur reçue et pousse le CTA en bas.
///
/// Miroir web : `Metric`.
class SfMetric extends StatelessWidget {
  const SfMetric({
    super.key,
    required this.civique,
    required this.code,
    required this.value,
    this.title,
    this.state,
    this.meta,
    this.cta,
    this.onPressed,
    this.ctaEmphasis = SfCtaEmphasis.soft,
    this.fill = false,
  });

  /// Le nom de l'épreuve, lisible d'un coup d'œil sous la pastille.
  /// Miroir web : `Metric.title`.
  final String? title;

  final bool civique;
  final String code;
  final String value;
  final SfState? state;
  final String? meta;
  final String? cta;
  final VoidCallback? onPressed;
  final SfCtaEmphasis ctaEmphasis;

  /// La tuile reçoit une hauteur bornée par sa rangée (`IntrinsicHeight` +
  /// `CrossAxisAlignment.stretch`, la `.grid-2` portrait) : elle s'étire sans
  /// `LayoutBuilder`, qui ne sait pas répondre à une mesure intrinsèque.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    if (fill) return _tuile(etiree: true);
    return LayoutBuilder(
      builder: (context, box) => _tuile(etiree: box.hasBoundedHeight),
    );
  }

  Widget _tuile({required bool etiree}) {
    final etat = state;
    final geste = cta;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: etiree ? MainAxisSize.max : MainAxisSize.min,
        children: [
          SfBadge(code, civique: civique),
          if (title case final nom?) ...[
            const SizedBox(height: 10),
            Text(
              nom,
              style: AppFonts.display(
                  size: 16, weight: FontWeight.w700, height: 1.25),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            value,
            style:
                AppFonts.display(size: 24, weight: FontWeight.w800, height: 1),
          ),
          if (etat != null) ...[
            const SizedBox(height: 8),
            Text(
              etat.label,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w700,
                color: etat.tone.text,
              ),
            ),
          ],
          if (meta != null) ...[
            const SizedBox(height: 4),
            Text(
              meta!,
              style:
                  AppFonts.ui(size: 12, color: AppColors.muted, height: 1.35),
            ),
          ],
          if (geste != null && onPressed != null) ...[
            const SizedBox(height: 14),
            if (etiree) const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _SfCardCta(
                label: geste,
                civique: civique,
                emphasis: ctaEmphasis,
                onPressed: onPressed!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// **La frise des derniers repères** (`.card` + `.timeline` / `.step`) : un
/// intitulé, des pastilles reliées par des flèches — la dernière active, à la
/// couleur du module —, puis [caption] (« Meilleur niveau observé : B1 »).
///
/// 🛑 Les étapes sont des valeurs **servies**, déjà écrites (un palier, un taux),
/// dans l'ordre servi ; liste vide ⇒ pas de frise (l'écran pose son état vide).
///
/// Miroir web : `Timeline`.
class SfTimeline extends StatelessWidget {
  const SfTimeline({
    super.key,
    this.civique = false,
    required this.steps,
    this.label,
    this.caption,
  });

  final bool civique;
  final List<String> steps;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Text(
              label!.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.muted),
            ),
          if (label != null && steps.isNotEmpty) const SizedBox(height: 14),
          if (steps.isNotEmpty)
            Wrap(
              spacing: 7,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    Text(
                      '→',
                      style: AppFonts.ui(size: 13, color: AppColors.muted2),
                    ),
                  _SfTimelineStep(
                    label: steps[i],
                    active: i == steps.length - 1,
                    civique: civique,
                  ),
                ],
              ],
            ),
          if (caption != null) ...[
            const SizedBox(height: 12),
            Text(
              caption!,
              style:
                  AppFonts.ui(size: 13, color: AppColors.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _SfTimelineStep extends StatelessWidget {
  const _SfTimelineStep({
    required this.label,
    required this.active,
    required this.civique,
  });

  final String label;
  final bool active;
  final bool civique;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.module(civique: civique) : AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppFonts.ui(
          size: 12,
          weight: FontWeight.w800,
          color: active ? AppColors.white : AppColors.muted,
          height: 1,
        ),
      ),
    );
  }
}

/// **La carte d'un thème civique** (`.theme-card`, maquette web ramenée au
/// portrait) : pastille d'icône, nom, description, anneau d'avancement, puis
/// le compteur de séries, l'état servi et le CTA doux.
///
/// 🛑 [ring] est le pourcentage **déjà calculé** par la fonction unique de
/// l'écran (`avancementSeriesCivique([stat]).pourcentage`) ; l'anneau n'en
/// tire aucun état et garde la teinte du module jusqu'au bout (jamais de
/// vert). [description] `null` ⇒ rien à sa place.
///
/// [onPressed] sans [cta] ⇒ toute la carte agit ; avec [cta], seul le bouton.
///
/// Miroir web : `ThemeCard`.
class SfThemeCard extends StatelessWidget {
  const SfThemeCard({
    super.key,
    this.civique = true,
    required this.icon,
    required this.title,
    this.description,
    required this.ring,
    required this.count,
    this.state,
    this.cta,
    this.onPressed,
  });

  final bool civique;
  final IconData icon;
  final String title;
  final String? description;

  /// Pourcentage d'avancement, 0 → 100.
  final int ring;

  /// « {terminées}/{total} séries ».
  final String count;
  final SfState? state;
  final String? cta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final etat = state;
    final geste = cta;
    final rayon = BorderRadius.circular(AppRadii.xl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: rayon,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: rayon,
        child: InkWell(
          onTap: geste == null ? onPressed : null,
          borderRadius: rayon,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: rayon,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _SfSoftIconBox(icon: icon, civique: civique, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppFonts.display(
                                size: 16, weight: FontWeight.w700, height: 1.2),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              style: AppFonts.ui(
                                  size: 13,
                                  color: AppColors.muted,
                                  height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SfRing(
                      ratio: ring / 100,
                      size: 52,
                      stroke: 6,
                      label: '$ring %',
                      reached: false,
                      civique: civique,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SfBadge(count, civique: civique),
                    const Spacer(),
                    if (etat != null)
                      Text(
                        etat.label,
                        style: AppFonts.ui(
                          size: 12,
                          weight: FontWeight.w700,
                          color: etat.tone.text,
                        ),
                      ),
                  ],
                ),
                if (geste != null && onPressed != null) ...[
                  const SizedBox(height: 14),
                  _SfCardCta(
                    label: geste,
                    civique: civique,
                    emphasis: SfCtaEmphasis.ghost,
                    onPressed: onPressed!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// **La carte conseil** (`.tip-card`, maquette web) : fond ambre doux,
/// intitulé ambre, texte éditorial, CTA plein du module optionnel.
///
/// 🛑 Le texte est **éditorial ou servi** : la carte ne compose aucune phrase
/// à partir d'un chiffre.
///
/// Miroir web : `TipCard`.
class SfTipCard extends StatelessWidget {
  const SfTipCard({
    super.key,
    this.civique = false,
    this.icon,
    required this.label,
    required this.text,
    this.cta,
    this.onPressed,
  });

  /// La couleur du CTA.
  final bool civique;
  final IconData? icon;
  final String label;
  final String text;
  final String? cta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final geste = cta;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.amberDark),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: AppFonts.label(size: 11, color: AppColors.amberDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.ui(size: 14, color: AppColors.ink2, height: 1.55),
          ),
          if (geste != null && onPressed != null) ...[
            const SizedBox(height: 14),
            SfButton(
              label: geste,
              variant: civique ? SfButtonVariant.civique : SfButtonVariant.tcf,
              onPressed: onPressed,
            ),
          ],
        ],
      ),
    );
  }
}

/// **La tête d'un écran de progression** (`.progression-head` / `.target`).
/// Deux formes :
/// - [from] → [to] : niveau actuel, flèche, objectif (TCF) ;
/// - [primary] + [secondary] : « {pct} % du parcours réalisé » / « {n} séries
///   terminées » (civique), avec sa barre [progress].
///
/// 🛑 Valeurs **servies** ou agrégées par la fonction documentée de l'écran ;
/// [progress] `null` ⇒ pas de barre (le TCF n'en pose pas à côté des
/// niveaux).
///
/// Miroir web : `ProgressionHead`.
class SfProgressionHead extends StatelessWidget {
  const SfProgressionHead({
    super.key,
    this.civique = false,
    required this.label,
    this.from,
    this.to,
    this.primary,
    this.secondary,
    this.progress,
  }) : assert((from != null && to != null) || primary != null,
            'from + to, ou primary');

  final bool civique;
  final String label;

  /// Niveau actuel (« B1 » / « Niveau actuel »), affiché au-dessus du libellé.
  final SfStat? from;

  /// Objectif (« B2 » / « Objectif »), à la couleur du module.
  final SfStat? to;

  /// Valeur mise en avant, à la couleur du module, libellé dessous.
  final SfStat? primary;
  final SfStat? secondary;

  /// Part (0 → 1) de la barre du module.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.module(civique: civique);
    final depart = from;
    final cible = to;
    final tete = primary;
    final second = secondary;
    final part = progress;
    final grand =
        AppFonts.display(size: 26, weight: FontWeight.w800, height: 1);
    final micro = AppFonts.ui(size: 12, color: AppColors.muted, height: 1.35);

    final Widget corps;
    if (depart != null && cible != null) {
      corps = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(depart.label, style: micro),
                const SizedBox(height: 2),
                Text(depart.value, style: grand),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.moduleLight(civique: civique),
            ),
            child: Icon(LucideIcons.arrowRight, size: 20, color: accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(cible.label, style: micro, textAlign: TextAlign.right),
                const SizedBox(height: 2),
                Text(cible.value, style: grand.copyWith(color: accent)),
              ],
            ),
          ),
        ],
      );
    } else {
      corps = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tete!.value, style: grand.copyWith(color: accent)),
                const SizedBox(height: 2),
                Text(tete.label, style: micro),
              ],
            ),
          ),
          if (second != null) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(second.value, style: grand),
                  const SizedBox(height: 2),
                  Text(second.label, style: micro, textAlign: TextAlign.right),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.label(size: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          corps,
          if (part != null) ...[
            const SizedBox(height: 14),
            _SfBar(part: part, fill: accent, track: AppColors.surface3),
          ],
        ],
      ),
    );
  }
}

/// Le statut d'un créneau d'examen, **lu sur l'état servi et le `locked`
/// servi** par l'écran : [done] fait, [go] disponible (geste mis en avant),
/// [locked] verrouillé, [neutral] tout le reste.
enum SfExamStatus { done, go, locked, neutral }

/// **La ligne d'un examen blanc** (`.exam-row`) : numéro dans sa pastille,
/// titre, méta servie, statut en pastille.
///
/// Refaite en phase 4a sur la maquette ; l'ancienne ligne d'épreuve (icône +
/// niveau) a cédé sa place à [SfInfoCard] chez son seul lecteur.
///
/// Miroir web : `ExamRow`.
class SfExamRow extends StatelessWidget {
  const SfExamRow({
    super.key,
    this.civique = false,
    required this.number,
    required this.title,
    this.meta,
    required this.status,
    required this.statusLabel,
    this.onTap,
  });

  final bool civique;
  final int number;
  final String title;
  final String? meta;
  final SfExamStatus status;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.module(civique: civique);
    final plein = status == SfExamStatus.done || status == SfExamStatus.go;
    final go = status == SfExamStatus.go;
    return Opacity(
      opacity: status == SfExamStatus.locked ? 0.55 : 1,
      child: _SfRowFrame(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: plein ? accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                '$number',
                style: AppFonts.display(
                  size: 20,
                  weight: FontWeight.w800,
                  color: plein ? AppColors.white : accent,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.display(
                        size: 16, weight: FontWeight.w700, height: 1.2),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta!,
                      style: AppFonts.ui(
                          size: 13, color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: go ? accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                statusLabel,
                style: AppFonts.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: go ? AppColors.white : AppColors.muted,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
