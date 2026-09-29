import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_update/min_version.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

const String kUpdateRequiredTitle = 'Une mise à jour est nécessaire';
const String kUpdateRequiredBody =
    'Cette version de SejourFR n\'est plus prise en charge. Installez la '
    'dernière version pour continuer à vous entraîner : votre compte et votre '
    'progression vous attendent.';

/// L'écran bloquant de la **version minimale** (contrôle G-a) : rien d'autre
/// qu'un lien vers la fiche du store. Affiché à la place de toute l'app quand
/// `updateRequiredProvider` le dit — jamais sur une erreur de lecture.
///
/// Guideline Apple 2.3.10 : on ne nomme que le store de la plateforme, jamais
/// « Google Play » sur iOS ni « App Store » sur Android.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  Future<void> _ouvrirStore() async {
    final url = Platform.isIOS ? StoreLinks.appStore : StoreLinks.playStore;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Rien à faire de plus : le candidat peut ouvrir le store lui-même.
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Platform.isIOS ? 'l\'App Store' : 'Google Play';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SfCard(
              variant: SfCardVariant.hero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.refreshCw,
                      size: 28, color: AppColors.blue),
                  const SizedBox(height: 14),
                  const SfHeadline(kUpdateRequiredTitle),
                  const SizedBox(height: 10),
                  Text(
                    kUpdateRequiredBody,
                    style: AppFonts.ui(
                        size: 14, height: 1.45, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                  SfButton(
                    label: 'Mettre à jour sur $store',
                    variant: SfButtonVariant.blue,
                    icon: LucideIcons.externalLink,
                    onPressed: _ouvrirStore,
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
