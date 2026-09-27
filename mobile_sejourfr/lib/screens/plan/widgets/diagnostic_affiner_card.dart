import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/preparation_labels.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';

/// **La proposition SECONDAIRE de diagnostic** (D-69, 2026-09-28) — sous « À
/// faire maintenant » sur le Plan et sur l'Accueil, TCF comme civique.
///
/// 🛑 **Jamais le CTA rouge, jamais à la place de l'action du Plan** : une note
/// ([SfNoteCard]) et un bouton en ligne ([SfButtonVariant.line]). Titre, texte,
/// libellé et destination viennent tous de [diagnosticAAffiner] ; `info` nul ⇒
/// rien n'est rendu.
///
/// Composée des briques du kit, miroir de `DiagnosticAffinerCard` côté web.
class DiagnosticAffinerCard extends StatelessWidget {
  const DiagnosticAffinerCard({super.key, required this.info, this.onOpen});

  final DiagnosticAAffiner? info;

  /// Appelé juste avant d'ouvrir le diagnostic (mesure d'audience).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final info = this.info;
    if (info == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SfNoteCard(
        icon: LucideIcons.clipboardCheck,
        title: info.titre,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfTiny(info.texte),
            const SizedBox(height: 12),
            SfButton(
              label: info.cta,
              variant: SfButtonVariant.line,
              onPressed: () {
                onOpen?.call();
                context.push(info.route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
