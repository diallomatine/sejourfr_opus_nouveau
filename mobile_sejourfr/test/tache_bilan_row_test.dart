import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/tache_bilan_row.dart';

/// Vécu le 2026-08-06 : sur un examen blanc EO, les évaluations des tâches 1 et
/// 2 ont échoué (submissions `FAILED`). Le bilan les rendait « Non évaluée »
/// avec une icône « rien à voir ici », alors que la relance
/// (`POST /api/production-submissions/{id}/retry`) était à un tap invisible.
/// Le web disait déjà « Évaluation échouée — à relancer » : on s'aligne dessus.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('une evaluation en echec est nommee et garde son chevron',
      (tester) async {
    await pump(tester, const TacheBilanRow(name: 'Tâche 1', failed: true));

    expect(find.text('Évaluation échouée — à relancer'), findsOneWidget);
    expect(find.text('Non évaluée'), findsNothing);
    // Le chevron est la seule affordance qui mène a l'ecran de relance.
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleMinus), findsNothing);
  });

  testWidgets('une tache sans production reste « Non rendue »', (tester) async {
    await pump(tester, const TacheBilanRow(name: 'Tâche 2', notRendered: true));

    expect(find.text('Non rendue'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('une evaluation en cours prime sur l’echec', (tester) async {
    await pump(
      tester,
      const TacheBilanRow(name: 'Tâche 3', pending: true, failed: true),
    );

    expect(find.text('Évaluation IA en cours…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('une tache evaluee montre son NIVEAU, jamais une note',
      (tester) async {
    // Décision produit du 2026-08-08 : au TCF, un correcteur attribue un
    // niveau par tâche ; la note /20 ne porte que sur l'épreuve entière, dont
    // le bilan est rendu au-dessus de ces lignes.
    await pump(
      tester,
      const TacheBilanRow(
        name: 'Tâche 1',
        niveau: NiveauCecrl.b2,
        evaluated: true,
      ),
    );

    expect(find.text('Niveau B2'), findsOneWidget);
    expect(find.textContaining('/ 20'), findsNothing);
    expect(find.textContaining('12,5'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('le plancher ne se dit pas « Niveau A1 non atteint »',
      (tester) async {
    await pump(
      tester,
      const TacheBilanRow(
        name: 'Tâche 2',
        niveau: NiveauCecrl.a1NonAtteint,
        evaluated: true,
      ),
    );

    expect(find.text('A1 non atteint'), findsOneWidget);
  });

  testWidgets('une eval trop ancienne pour porter un niveau garde son rapport',
      (tester) async {
    // ~100 évaluations d'avant le contrat v4 n'ont pas de `niveauObserve` : on
    // n'invente rien, mais le chevron doit rester — le rapport existe.
    await pump(
      tester,
      const TacheBilanRow(name: 'Tâche 3', evaluated: true),
    );

    expect(find.text('Évaluée'), findsOneWidget);
    expect(find.text('Non évaluée'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });
}
