import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// En-tête plat de la home des hubs Civique / TCF :
/// menu (icône) à gauche, titre + sous-titre au centre, slot trailing
/// (typiquement une cloche notifications) à droite.
///
/// Calqué sur le pattern de `ModuleScreenHeader` mais sans bouton back —
/// on est dans la bottom-nav, pas dans une route empilée.
class HubHomeHeader extends StatelessWidget {
  const HubHomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRightTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppFonts.jakarta(
                  size: 17,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ).copyWith(letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _IconBtn(
          icon: Icons.notifications_outlined,
          color: AppColors.muted,
          onTap: onRightTap,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

/// Hero plein large « Examen blanc complet » — carte avec **dégradé** plein
/// (style readiness hero du menu Progression), texte blanc, CTA pill blanche
/// qui ressort sur le fond coloré. Réutilisé par les 2 hubs : Civique
/// (rouge, défaut) et TCF (bleu via accent override).
///
/// `accent` = bout foncé du dégradé (= couleur du shadow, foreground texte
/// du CTA). `accentStart` = bout clair du dégradé.
class ExamBlancHero extends StatelessWidget {
  const ExamBlancHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onTap,
    this.accent = AppColors.redDark,
    this.accentLight = AppColors.redLight,
    this.accentStart = AppColors.red,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onTap;
  final Color accent;

  /// Conservé pour compat — non utilisé depuis le passage au dégradé plein.
  final Color accentLight;
  final Color accentStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentStart, accent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    size: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: AppFonts.mono(
                        size: 10,
                        color: AppColors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.4,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppFonts.jakarta(
                  size: 19,
                  weight: FontWeight.w800,
                  color: AppColors.white,
                ).copyWith(letterSpacing: -0.3),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              _HeroCta(
                label: ctaLabel,
                onTap: onTap,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w800,
                    color: accent,
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

/// Étiquette de section (« S'entraîner par épreuve », « Ma progression »)
/// avec compteur ou lien optionnel à droite.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 13.5,
              weight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Compteur droite des sections, ex. « 5 modules ».
class SectionCounter extends StatelessWidget {
  const SectionCounter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.jakarta(size: 11.5, color: AppColors.muted2),
    );
  }
}

/// Lien droite des sections, ex. « Détails ».
class SectionLink extends StatelessWidget {
  const SectionLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: AppFonts.jakarta(
            size: 12,
            weight: FontWeight.w700,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}

/// Carte module verticale (CO / CE / Structure / EE / EO ou thème civique) :
/// icône colorée 44×44 + radius 12, titre + pill niveau optionnelle, sous-titre,
/// barre de progression 3 px + % à droite, chevron.
///
/// Pattern aligné sur la maquette `tcf_modules_home_screen.html` :
/// densité serrée, ombres légères. Sert à la fois aux épreuves TCF et
/// aux thèmes civique.
class EpreuveCard extends StatelessWidget {
  const EpreuveCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pillLabel,
    this.progress,
    this.locked = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Label pill à droite du titre (ex. "B1", "CSP", "BONUS"). Couleur tirée
  /// de [iconColor] pour rester cohérent avec l'icône.
  final String? pillLabel;

  /// Progression en 0..1. Null = pas de barre rendue. 0.0 = barre rendue
  /// mais vide (utile pour signaler "rien commencé").
  final double? progress;

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null ? null : (progress! * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppFonts.jakarta(
                                  size: 14.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ).copyWith(letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pillLabel != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                pillLabel!,
                                style: AppFonts.jakarta(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (progress != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 3,
                                        color: AppColors.line2,
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress!.clamp(0.0, 1.0),
                                        child: Container(
                                          height: 3,
                                          color: iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percent%',
                                style: AppFonts.jakarta(
                                  size: 10,
                                  color: AppColors.muted2,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.chevron_right_rounded,
                    size: locked ? 16 : 20,
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
