import 'package:flutter/widgets.dart';

import '../../../core/models/journey_models.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../journey_labels.dart';

/// **L'examen d'un bloc, lu sans geste** — « Examen blanc · Passé le 26 sept.
/// 2026 » et, à droite, son résultat servi (« Niveau B1 », « 17/20 »,
/// « Passé »).
///
/// 🛑 **Une seule lecture pour deux écrans** (D-69 ter) : la consultation d'un
/// cycle clos (« Mes cycles ») et l'examen PASSÉ du Plan courant. Deux rendus
/// auraient fini par ne pas dire la même chose d'un même examen.
class JourneyExamLu extends StatelessWidget {
  const JourneyExamLu({super.key, required this.exam});

  final JourneyStep exam;

  @override
  Widget build(BuildContext context) {
    final resultat = journeyArchiveExamResult(exam);
    return SfExamStepAction(
      title: kJourneyExamTitle,
      subtitle: journeyArchiveExamSubtitle(exam),
      trailing: resultat == null ? null : SfExamStepDone(label: resultat),
    );
  }
}
