import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/repositories.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/journey_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../journey_labels.dart';
import '../learning_plan_provider.dart';

/// **Le jalon « Faire un examen blanc complet »** (2026-09-27, D-68) — sous la
/// carte « À faire maintenant », au-dessus du cycle.
///
/// 🛑 **Rien n'est décidé ici** : le jalon n'apparaît que si le serveur le SERT
/// ([Journey.examenComplet]), et sa phrase se lit sur la raison servie. Le geste
/// (`measurementCycle`) est refusé en 409 par la même autorité.
///
/// 🛑 **Une confirmation d'abord** : le geste met de côté le cycle en cours
/// (« interrompu » dans « Mes cycles »). Puis [relireSourcesDuCompte] relit le
/// Plan, le parcours et l'Accueil — le cycle d'examens s'affiche aussitôt.
///
/// Composé des briques du kit ([SfSection], [SfCard], [SfButton]), miroir de
/// `ExamenCompletJalon` côté web (`app/_components/plan/ExamenCompletJalon.tsx`).
class ExamenCompletJalon extends ConsumerStatefulWidget {
  const ExamenCompletJalon({
    super.key,
    required this.journey,
    required this.module,
  });

  final Journey? journey;
  final AppModule module;

  @override
  ConsumerState<ExamenCompletJalon> createState() => _ExamenCompletJalonState();
}

class _ExamenCompletJalonState extends ConsumerState<ExamenCompletJalon> {
  bool _occupe = false;
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final jalon = widget.journey?.examenComplet;
    if (jalon == null) return const SizedBox.shrink();
    final erreur = _erreur;
    return SfSection(
      title: kJourneyJalonTitle,
      flush: true,
      child: SfCard(
        variant: SfCardVariant.soft,
        child: SfStack(
          pad: false,
          children: [
            Text(
              journeyJalonText(jalon, widget.module),
              style: AppFonts.ui(size: 14, color: AppColors.ink2, height: 1.45),
            ),
            SfButton(
              label: _occupe ? kJourneyJalonBusy : kJourneyJalonCta,
              // Bleu en TCF, rouge en civique (token du module, Navigation v2).
              variant: widget.module == AppModule.civique
                  ? SfButtonVariant.civique
                  : SfButtonVariant.blue,
              onPressed: _occupe ? null : _confirmer,
            ),
            if (erreur != null)
              Text(
                erreur,
                style:
                    AppFonts.ui(size: 12, color: AppColors.red, height: 1.45),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmer() async {
    final confirme = await showAppSheet<bool>(
      context,
      icon: LucideIcons.flag,
      title: kJourneyJalonConfirmTitle,
      sub: journeyJalonConfirmMessage(
        widget.journey?.cycle?.complete ?? false,
        widget.module,
      ),
      children: [
        AppButton(
          label: kJourneyJalonConfirmCta,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AppButton(
          label: kJourneyJalonConfirmCancel,
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
    if (confirme != true || !mounted) return;
    unawaited(_lancer());
  }

  Future<void> _lancer() async {
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await ref
          .read(learningPlanRepositoryProvider)
          .measurementCycle(module: widget.module);
      // 🛑 **On ATTEND la relecture** : Plan, parcours, Accueil — le bouton
      // reste occupé jusqu'à ce que le cycle d'examens soit lu.
      if (mounted) await relireSourcesDuCompte(ref);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erreur = kJourneyJalonError);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }
}
