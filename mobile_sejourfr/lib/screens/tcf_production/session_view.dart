import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';

/// Vue generique d'une session EE ou EO, pour que les ecrans communs
/// (progression, bilan) puissent les manipuler de la meme facon sans dupliquer
/// le code.
class SessionView {
  const SessionView({
    required this.epreuve,
    required this.tasks,
    required this.submissions,
    required this.completed,
  });

  final EpreuveType epreuve;
  final List<ProductionTaskDto> tasks;
  final Map<int, ProductionSubmissionDto> submissions;
  final int completed;

  int get total => tasks.length;
  bool get isStarted => tasks.isNotEmpty;
  bool get isCompleted => completed >= total && total > 0;

  ProductionTaskDto? taskAt(int i) =>
      (i >= 0 && i < tasks.length) ? tasks[i] : null;

  /// Moyenne des notes /20 (null si aucune submission notee).
  double? get noteMoyenne {
    double sum = 0;
    int count = 0;
    for (final sub in submissions.values) {
      final n = sub.evaluation?.noteSurVingt;
      if (n != null) {
        sum += n;
        count++;
      }
    }
    if (count == 0) return null;
    return sum / count;
  }

  /// Niveau CECRL global derivé : la majorité (ou le plus haut en cas d'egalite)
  /// parmi les niveaux estimes des submissions.
  NiveauCecrl? get niveauGlobal {
    final counts = <NiveauCecrl, int>{};
    for (final sub in submissions.values) {
      final n = sub.evaluation?.niveauCecrl;
      if (n != null) counts[n] = (counts[n] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final tops = counts.entries.where((e) => e.value == maxCount).toList();
    // En cas d'egalite : prendre le niveau le plus haut sur l'echelle.
    tops.sort((a, b) => a.key.scaleIndex.compareTo(b.key.scaleIndex));
    return tops.last.key;
  }
}

/// Selecteur qui retourne la SessionView pour une epreuve donnee, en lisant
/// le bon provider sous-jacent (eoSession ou eeSession).
SessionView? readSessionView(WidgetRef ref, EpreuveType epreuve) {
  if (epreuve == EpreuveType.tcfEo) {
    final s = ref.watch(eoSessionProvider).value;
    if (s == null || !s.isStarted) return null;
    return SessionView(
      epreuve: epreuve,
      tasks: s.tasks,
      submissions: s.submissions,
      completed: s.submissions.length,
    );
  }
  if (epreuve == EpreuveType.tcfEe) {
    final s = ref.watch(eeSessionProvider).value;
    if (s == null || !s.isStarted) return null;
    return SessionView(
      epreuve: epreuve,
      tasks: s.tasks,
      submissions: s.submissions,
      completed: s.submissions.length,
    );
  }
  return null;
}

/// Reset l'etat de la session correspondante (apres bilan, retour menu...).
void resetSession(WidgetRef ref, EpreuveType epreuve) {
  if (epreuve == EpreuveType.tcfEo) {
    ref.read(eoSessionProvider.notifier).reset();
  } else if (epreuve == EpreuveType.tcfEe) {
    ref.read(eeSessionProvider.notifier).reset();
  }
}
