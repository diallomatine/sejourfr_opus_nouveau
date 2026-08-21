import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Briques de mise en page reprises du prototype « Compétences ».
///
/// Elles ne portent **aucune** couleur en dur : tout vient de [AppColors], et
/// l'accent du module (bleu EE / rouge EO) descend en paramètre.

/// Intertitre de section (`.section-head`) : un `h3` 18, une phrase 12, et un
/// lien discret facultatif à droite (le « Continuer » du prototype est un
/// lien, pas un bouton pleine largeur).
class ProductionSectionHead extends StatelessWidget {
  const ProductionSectionHead({
    super.key,
    required this.title,
    this.description,
    this.linkLabel,
    this.onLinkTap,
    this.trailing,
    this.accent = AppColors.blue,
  });

  final String title;
  final String? description;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  /// Élément libre aligné à droite du titre (lien vers une ressource
  /// d'appoint). Prioritaire sur [linkLabel] — les deux ne coexistent jamais.
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.display(size: 18)),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: AppFonts.ui(
                      size: 12,
                      height: 1.35,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ] else if (linkLabel != null && onLinkTap != null) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onLinkTap,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  linkLabel!,
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w900,
                    color: accent,
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

/// Encart d'information (`.notice`) : pastille 34×34 `radius 12`, `padding 14`,
/// `radius 20`, texte 12. Porte le « Principe pédagogique » de l'accueil.
class ProductionNotice extends StatelessWidget {
  const ProductionNotice({
    super.key,
    required this.title,
    required this.body,
    this.icon = LucideIcons.info,
    this.tone = AppColors.amber,
    this.toneSoft = AppColors.amberLight,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tone;
  final Color toneSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: toneSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 17, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.ui(size: 12.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppFonts.ui(
                    size: 12,
                    height: 1.45,
                    color: AppColors.inkSoft,
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

/// Tipline ambre (`.tipline`) posée en pied de la carte d'exercice : c'est
/// elle qui explique pourquoi les références restent masquées avant la
/// production. Sans elle, la règle centrale de la spec (§13.2) n'est écrite
/// nulle part côté candidat.
class ProductionTipline extends StatelessWidget {
  const ProductionTipline({
    super.key,
    required this.lead,
    required this.body,
  });

  final String lead;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$lead ',
              style: AppFonts.ui(
                size: 11,
                height: 1.4,
                weight: FontWeight.w900,
                color: AppColors.amberDark,
              ),
            ),
            TextSpan(
              text: body,
              style: AppFonts.ui(
                size: 11,
                height: 1.4,
                color: AppColors.amberDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de numéro **unique** du prototype : 48×48, `radius 16`, graisse
/// très élevée. Une seule forme aux quatre emplacements (carte de compétence,
/// carte de petit sujet) — avant, chaque carte avait la sienne.
class ProductionIndexChip extends StatelessWidget {
  const ProductionIndexChip({
    super.key,
    required this.order,
    required this.foreground,
    required this.background,
    this.done = false,
    this.pad = false,
  });

  final int order;
  final Color foreground;
  final Color background;
  final bool done;

  /// Numéro sur deux chiffres (`01`, `02`) — la forme de la maquette pour les
  /// listes de sujets, où l'alignement des rangs se lit d'un coup d'œil.
  final bool pad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: done
          ? Icon(LucideIcons.check, size: 22, color: foreground)
          : Text(
              pad ? order.toString().padLeft(2, '0') : '$order',
              style: AppFonts.display(size: 18, color: foreground)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
    );
  }
}

/// Encadré à **bordure pointillée** (`border: 1px dashed` du prototype).
/// Flutter n'a pas de bordure pointillée native ; on la peint.
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.color = AppColors.line,
    this.radius = 16,
    this.background = AppColors.surface2,
    this.padding = const EdgeInsets.all(11),
  });

  final Widget child;
  final Color color;
  final double radius;
  final Color background;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Pied chiffré d'une carte : 2 à 4 colonnes séparées par des filets, chacune
/// portant un nombre et son libellé.
///
/// Le libellé **s'accorde** : un seul élément affiche « 1 compétence », jamais
/// « 1 compétences ». Extrait à la 2ᵉ occurrence — la carte de synthèse d'une
/// épreuve et celle d'une tâche portent le même pied.
///
/// Un `value` **nul** signifie « pas encore chargé » et s'écrit « — » : un
/// « 0 compétences » le temps d'un appel se lirait comme un catalogue vide.
class ProductionCountersRow extends StatelessWidget {
  const ProductionCountersRow({
    super.key,
    required this.counters,
    this.background,
    this.valueSize = 17,
  });

  final List<({int? value, String label, String singular})> counters;

  /// Fond du pied. `null` = transparent (la carte donne le sien).
  final Color? background;

  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: const Border(top: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < counters.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(
                          left: BorderSide(color: AppColors.lineSoft),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counters[i].value?.toString() ?? '—',
                      style: AppFonts.display(size: valueSize),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      counters[i].value == 1
                          ? counters[i].singular
                          : counters[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lien discret vers une ressource d'appoint (les modèles corrigés), posé
/// au-dessus d'une liste. Il ne doit jamais concurrencer l'action principale de
/// l'écran — produire.
class ProductionSideLink extends StatelessWidget {
  const ProductionSideLink({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de palier de l'en-tête : « NIVEAU VISÉ » + le palier.
///
/// C'est le **palier visé** par la démarche du candidat, pas un niveau obtenu.
/// L'eyebrow le dit en toutes lettres : le repo interdit d'afficher un niveau
/// estimé sans le qualifier.
class ProductionLevelBadge extends StatelessWidget {
  const ProductionLevelBadge({
    super.key,
    required this.level,
    this.onDark = false,
  });

  final String level;

  /// Sur un bandeau bleu plein, un fond bleu disparaitrait : la pastille passe
  /// alors en voile blanc translucide. Ajoute le 2026-08-21 avec l'en-tete
  /// plein de l'ecran de tache ; les autres appelants gardent le fond bleu.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.white.withValues(alpha: 0.18)
            : AppColors.blue,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NIVEAU VISÉ',
            style: AppFonts.ui(
              size: 8,
              weight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            level,
            style: AppFonts.display(size: 16, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
