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

/// Chevron encerclé du prototype (`.chev`, 30×30) : même forme sur la carte de
/// compétence et sur celle d'un petit sujet.
class ProductionChevron extends StatelessWidget {
  const ProductionChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: AppColors.inkFaint,
      ),
    );
  }
}

/// Carte cliquable du prototype : ombre douce au repos, **retour au toucher**
/// (le survol `translateY(-2px)` + ombre n'a pas d'équivalent tactile — on le
/// transpose en enfoncement). Le bord se teinte quand la carte est « traitée ».
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 23,
    this.borderColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final Color? borderColor;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: widget.borderColor ?? AppColors.line),
            boxShadow: _down ? AppShadows.md : AppShadows.card,
          ),
          child: widget.child,
        ),
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
