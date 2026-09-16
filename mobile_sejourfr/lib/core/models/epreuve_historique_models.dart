import 'enums.dart';

/// Miroirs de `EpreuveHistoriqueDto` — « d'où sort mon niveau ? ».
///
/// 🛑 **Rien n'est calculé côté app** : la date, la provenance et le palier
/// arrivent servis. L'app pose des mots dessus, elle ne les déduit pas.

/// D'où vient une évaluation qualifiante.
///
/// 🛑 **Les quatre valeurs ne se fondent pas deux à deux** : une sous-épreuve
/// de diagnostic complet n'est ni le diagnostic rapide, ni un examen blanc, et
/// les confondre nommerait faux la seule ligne qui explique un palier.
enum SourceEvaluation {
  diagnosticRapide('DIAGNOSTIC_RAPIDE', 'Diagnostic rapide'),
  diagnosticComplet('DIAGNOSTIC_COMPLET', 'Diagnostic complet'),
  epreuveSeule('EPREUVE_SEULE', 'Épreuve passée seule'),
  examenBlanc('EXAMEN_BLANC', 'Examen blanc complet');

  const SourceEvaluation(this.wire, this.label);

  final String wire;

  /// 🛑 Libellé **gelé**, miroir mot pour mot de `SOURCE_EVALUATION_LABEL`
  /// (`web_sejoufr/lib/types.ts`).
  final String label;

  static SourceEvaluation? fromWire(String? value) {
    if (value == null) return null;
    for (final source in SourceEvaluation.values) {
      if (source.wire == value) return source;
    }
    return null;
  }
}

/// Une évaluation qualifiante : quand, d'où, quel palier.
class EvaluationQualifiante {
  const EvaluationQualifiante({
    required this.source,
    required this.niveau,
    this.mesureA,
  });

  final DateTime? mesureA;
  final SourceEvaluation source;
  final NiveauCecrl niveau;

  static EvaluationQualifiante? fromJson(Map<String, dynamic> json) {
    final source = SourceEvaluation.fromWire(json['source'] as String?);
    final niveau = json['niveau'] == null
        ? null
        : NiveauCecrl.fromWire(json['niveau'] as String);
    // Une ligne qu'un client ancien ne sait pas lire est ignorée, jamais rendue
    // à moitié : une évaluation sans palier n'explique rien.
    if (source == null || niveau == null) return null;
    return EvaluationQualifiante(
      mesureA: DateTime.tryParse(json['mesureA'] as String? ?? ''),
      source: source,
      niveau: niveau,
    );
  }
}

/// L'historique d'une épreuve. 🛑 [evaluations] **vide** quand rien n'a été
/// mesuré — jamais une erreur.
class EpreuveHistorique {
  const EpreuveHistorique({required this.epreuve, required this.evaluations});

  final EpreuveType epreuve;
  final List<EvaluationQualifiante> evaluations;

  static EpreuveHistorique fromJson(Map<String, dynamic> json) =>
      EpreuveHistorique(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        evaluations: (json['evaluations'] as List<dynamic>? ?? const [])
            .map((e) =>
                EvaluationQualifiante.fromJson(e as Map<String, dynamic>))
            .whereType<EvaluationQualifiante>()
            .toList(),
      );
}
