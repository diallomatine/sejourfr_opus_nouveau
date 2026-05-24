import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Topbar pour les hubs Civique/TCF : icône notifications à gauche,
/// pastille de niveau/parcours à droite (ex: "B1", "CSP").
class HubTopBar extends StatelessWidget {
  const HubTopBar({
    super.key,
    required this.badgeText,
    required this.badgeColor,
    this.onLeftTap,
  });

  final String badgeText;
  final Color badgeColor;
  final VoidCallback? onLeftTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onLeftTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeText,
            style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero gradient identique sur les 2 hubs (couleurs variables).
class HubHero extends StatelessWidget {
  const HubHero({
    super.key,
    required this.eyebrow,
    required this.titleTop,
    required this.titleBottom,
    required this.description,
    required this.colors,
  });

  final String eyebrow;
  final String titleTop;
  final String titleBottom;
  final String description;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -35,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: AppFonts.mono(
                      size: 10,
                      color: AppColors.white.withValues(alpha: 0.85),
                      letterSpacing: 1.8,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titleTop,
                    style: AppFonts.jakarta(
                      size: 26,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.1,
                    ).copyWith(letterSpacing: -0.5),
                  ),
                  Text(
                    titleBottom,
                    style: AppFonts.jakarta(
                      size: 26,
                      weight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.1,
                    ).copyWith(letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: AppFonts.jakarta(
                      size: 13.5,
                      color: AppColors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de progression : objectif (parcours / niveau) + % de maîtrise.
class HubProgressCard extends StatelessWidget {
  const HubProgressCard({
    super.key,
    required this.objectiveLabel,
    required this.objectiveValue,
    required this.percent,
    required this.accent,
    required this.hint,
  });

  final String objectiveLabel;
  final String objectiveValue;
  final int percent;
  final Color accent;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
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
                      objectiveLabel.toUpperCase(),
                      style: AppFonts.mono(
                        size: 9.5,
                        color: AppColors.muted,
                        letterSpacing: 1.8,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objectiveValue,
                      style: AppFonts.jakarta(
                        size: 17,
                        weight: FontWeight.w800,
                        color: AppColors.ink,
                      ).copyWith(letterSpacing: -0.2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$clamped%',
                  style: AppFonts.jakarta(
                    size: 12,
                    weight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: AppColors.line2,
                ),
                FractionallySizedBox(
                  widthFactor: clamped / 100,
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
          Text(
            hint,
            style: AppFonts.jakarta(
              size: 12.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre de section (équivalent du h2.section-title du design).
class HubSectionTitle extends StatelessWidget {
  const HubSectionTitle(this.label, {super.key, this.trailing});

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
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ).copyWith(letterSpacing: -0.3),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Carte module : icône couleur + titre (+ tag IA) + description + meta + chevron.
class HubModuleCard extends StatelessWidget {
  const HubModuleCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.meta,
    required this.onTap,
    this.aiTag = false,
    this.locked = false,
    this.coverageRatio,
    this.coverageLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String meta;
  final bool aiTag;
  final bool locked;
  final VoidCallback onTap;

  /// Taux de couverture du pool de questions du module (0..1). Quand
  /// non null, une fine barre s'affiche sous le meta avec [coverageLabel].
  /// Cohérent avec la logique "barre = couverture" des hubs et de
  /// l'écran Progression : on n'affiche pas la mastery agrégée (correct/total)
  /// qui démotive au démarrage, mais la part du pool déjà touchée.
  final double? coverageRatio;

  /// Texte court rendu à côté de la barre — typiquement "X/Y vues · Z% justes".
  /// Null si seule la barre suffit. Ignoré quand [coverageRatio] est null.
  final String? coverageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 23, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: AppFonts.jakarta(
                                  size: 14.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.ink,
                                ).copyWith(letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (aiTag) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'IA',
                                  style: AppFonts.mono(
                                    size: 9,
                                    color: AppColors.blue,
                                    letterSpacing: 1.1,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: AppFonts.mono(
                            size: 10,
                            color: AppColors.ink2,
                            letterSpacing: 1.4,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (coverageRatio != null) ...[
                          const SizedBox(height: 8),
                          _ModuleCardCoverage(
                            ratio: coverageRatio!.clamp(0.0, 1.0),
                            label: coverageLabel,
                            accent: iconColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    size: locked ? 18 : 22,
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

/// Mini barre de progression + label, rendue sous le meta d'une [HubModuleCard]
/// quand `coverageRatio` est fourni. Représente la couverture du pool du
/// module (% du programme touché), en miroir de la barre par thème de
/// l'écran Progression. Pas de marqueur de seuil — la couverture vise 100%.
class _ModuleCardCoverage extends StatelessWidget {
  const _ModuleCardCoverage({
    required this.ratio,
    required this.accent,
    this.label,
  });

  final double ratio;
  final Color accent;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.02, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 5),
          Text(
            label!,
            style: AppFonts.jakarta(size: 11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Les deux onglets en haut des hubs Civique / TCF.
enum HubTab { entrainement, examens }

/// Switch Entraînement / Examens stylé en segmented control sur fond blanc,
/// calqué sur le switch module de l'écran Progression. La couleur active
/// suit l'accent du hub (bleu sur Civique, rouge sur TCF).
class HubTabsBar extends StatelessWidget {
  const HubTabsBar({
    super.key,
    required this.current,
    required this.onChanged,
    required this.activeColor,
  });

  final HubTab current;
  final ValueChanged<HubTab> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _HubTabBtn(
              label: 'Entraînement',
              active: current == HubTab.entrainement,
              activeColor: activeColor,
              onTap: () => onChanged(HubTab.entrainement),
            ),
          ),
          Expanded(
            child: _HubTabBtn(
              label: 'Examens',
              active: current == HubTab.examens,
              activeColor: activeColor,
              onTap: () => onChanged(HubTab.examens),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTabBtn extends StatelessWidget {
  const _HubTabBtn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 13,
              weight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? AppColors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
