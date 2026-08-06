import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  testWidgets('une note reste affichee telle quelle', (tester) async {
    await pump(tester, const TacheBilanRow(name: 'Tâche 1', score: 12.5));

    expect(find.textContaining('12,5'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });
}
