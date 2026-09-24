import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'help_center_labels.dart';

/// Hub "Centre d'aide" accessible depuis le profil. Regroupe :
///   - **FAQ**                       → WebView sur `${webBaseUrl}/faq`
///   - **Nous contacter**            → écran natif `ContactScreen`
///   - **Conditions d'utilisation**  → WebView sur `${webBaseUrl}/cgu`
///   - **Politique de confidentialité** → WebView sur `${webBaseUrl}/confidentialite`
///
/// FAQ / CGU / Privacy passent par WebView pour éviter de dupliquer 1200+
/// lignes de contenu en Dart natif. Le contact reste natif (UX bien meilleure
/// + on contrôle la validation + retour direct via snackbar).
///
/// Textes : `help_center_labels.dart`, miroir mot pour mot de la page web
/// `/aide` (`web_sejoufr/lib/aide.ts`).
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final webBase = ApiConfig.webBaseUrl;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          kAideTitle,
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _HelpHero(),
            const SizedBox(height: 22),
            const _SectionLabel(kAideSectionRessources),
            const SizedBox(height: 10),
            _HelpTile(
              icon: LucideIcons.circleHelp,
              accent: AppColors.blue,
              title: kAideFaqTitle,
              subtitle: kAideFaqSub,
              onTap: () => context.push(
                '${AppRoutes.helpWebview}?url=$webBase/faq&title=Aide+%26+FAQ',
              ),
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: LucideIcons.mail,
              accent: AppColors.red,
              title: kAideContactTitle,
              subtitle: kAideContactSub,
              onTap: () => context.push(AppRoutes.contact),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(kAideSectionLegal),
            const SizedBox(height: 10),
            _HelpTile(
              icon: LucideIcons.scale,
              accent: AppColors.muted,
              title: kAideCguTitle,
              subtitle: kAideCguSub,
              onTap: () => context.push(
                '${AppRoutes.helpWebview}?url=$webBase/cgu&title=Conditions+d%27utilisation',
              ),
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: LucideIcons.shield,
              accent: AppColors.muted,
              title: kAideConfidentialiteTitle,
              subtitle: kAideConfidentialiteSub,
              onTap: () => context.push(
                '${AppRoutes.helpWebview}?url=$webBase/confidentialite&title=Confidentialit%C3%A9',
              ),
            ),
            const SizedBox(height: 10),
            _HelpTile(
              icon: LucideIcons.info,
              accent: AppColors.blue,
              title: kAideAboutTitle,
              subtitle: kAideAboutSub,
              onTap: () => context.push(AppRoutes.about),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blueSoft, AppColors.blueLight],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.headset,
              color: AppColors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kAideHeroTitle,
                  style: AppFonts.display(
                    size: 17,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kAideHeroText,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.muted,
                    height: 1.4,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        '§ ${text.toUpperCase()}',
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 2.0,
          weight: FontWeight.w600,
        ).copyWith(height: 1.0),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.ui(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
