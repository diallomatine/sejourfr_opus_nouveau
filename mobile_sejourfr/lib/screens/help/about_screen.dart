import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejourfr_logo.dart';

/// Écran « À propos » natif (conformité stores — Misleading Claims policy) :
/// disclaimer de non-affiliation bien visible + liens vers les sources
/// officielles `.gouv.fr`. Tout le texte est statique pour rester consultable
/// hors connexion ; les liens s'ouvrent en navigateur externe et échouent
/// gracieusement sans réseau.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _officialLinks = [
    _OfficialLink(
      icon: LucideIcons.landmark,
      title: 'Démarches séjour / naturalisation',
      subtitle: 'service-public.fr',
      url: 'https://www.service-public.fr',
    ),
    _OfficialLink(
      icon: LucideIcons.scale,
      title: 'Examen civique — ministère de l\'Intérieur',
      subtitle: 'immigration.interieur.gouv.fr',
      url: 'https://www.immigration.interieur.gouv.fr',
    ),
    _OfficialLink(
      icon: LucideIcons.languages,
      title: 'TCF — France Éducation International',
      subtitle: 'france-education-international.fr',
      url: 'https://www.france-education-international.fr',
    ),
    _OfficialLink(
      icon: LucideIcons.idCard,
      title: 'OFII',
      subtitle: 'ofii.fr',
      url: 'https://www.ofii.fr',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          'À propos',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Center(child: SejourFrLogoLockup()),
            const SizedBox(height: 18),
            Text(
              'SejourFR est une application d\'entraînement aux examens '
              'civique (CSP, carte de résident, naturalisation) et au TCF IRN '
              '(A2/B1/B2) : QCM corrigés, examens blancs en conditions '
              'réelles et productions évaluées.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.muted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            const _DisclaimerCard(),
            const SizedBox(height: 26),
            const _SectionLabel('Sources officielles'),
            const SizedBox(height: 6),
            Text(
              'Pour toute démarche administrative et pour l\'inscription aux '
              'épreuves, référez-vous uniquement aux sites officiels :',
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            for (final link in _officialLinks) ...[
              _OfficialLinkTile(link: link),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Encart disclaimer — non-affiliation. Surfaces neutres/bleues uniquement
// (jamais de rouge ici : ce n'est ni un CTA critique ni un signal d'urgence).
// ---------------------------------------------------------------------------

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.info,
                size: 16,
                color: AppColors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'OUTIL INDÉPENDANT',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blue,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'SejourFR est un outil d\'entraînement indépendant. Cette '
            'application n\'est affiliée ni au gouvernement français, ni à '
            'l\'OFII, ni au ministère de l\'Intérieur, ni à France Éducation '
            'International. Elle ne garantit pas la réussite aux examens.',
            style: AppFonts.ui(
              size: 13.5,
              color: AppColors.ink,
              height: 1.55,
              weight: FontWeight.w600,
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

class _OfficialLink {
  const _OfficialLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
}

class _OfficialLinkTile extends StatelessWidget {
  const _OfficialLinkTile({required this.link});

  final _OfficialLink link;

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Impossible d\'ouvrir le lien. Vérifiez votre connexion.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
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
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(link.icon, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      link.subtitle,
                      style: AppFonts.mono(
                        size: 10.5,
                        color: AppColors.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.externalLink,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
