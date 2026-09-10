import 'enums.dart';

/// **Où en sont les deux préparations** — l'état UNIQUE des deux modules.
///
/// 🛑 **TROIS PORTES, UN SEUL ÉTAT.** L'Accueil (« quelle est ma prochaine
/// action ? »), le Plan (« pourquoi n'est-il pas encore prêt ? ») et les
/// Examens (« où retrouver mon diagnostic ? ») lisent tous les trois ce modèle.
/// Trois écrans qui déduiraient chacun leur version finiraient par proposer
/// trois choses différentes au même candidat (arbitrage du 2026-09-10).
///
/// 🛑 **Asymétrie assumée** : le TCF a DEUX diagnostics (rapide puis complet),
/// le civique UN SEUL. Le civique est du QCM déterministe, rapide et sans coût
/// LLM — un pré-diagnostic n'y apporterait rien et dupliquerait le tunnel du
/// TCF. D'où [PreparationEtape.estimationFaite], qui n'existe que côté TCF.

enum PreparationEtape {
  diagnosticAFaire('DIAGNOSTIC_A_FAIRE'),
  diagnosticEnCours('DIAGNOSTIC_EN_COURS'),

  /// **TCF uniquement** : la première estimation est faite, le complet non.
  estimationFaite('ESTIMATION_FAITE'),

  planPret('PLAN_PRET');

  const PreparationEtape(this.wire);
  final String wire;

  static PreparationEtape fromWire(String value) =>
      PreparationEtape.values.firstWhere((e) => e.wire == value);
}

class ModulePreparation {
  const ModulePreparation({
    required this.etape,
    this.fait,
    this.total,
    this.sessionId,
    this.niveau,
    this.cible,
    this.aRenforcer,
  });

  final PreparationEtape etape;

  /// Avancement (2 épreuves, 14 questions). `null` si la notion n'a pas de sens
  /// à cette étape.
  final int? fait;
  final int? total;
  final String? sessionId;

  /// **TCF** : 🛑 `null` = pas encore mesuré, jamais A1.
  final NiveauCecrl? niveau;
  final NiveauCecrl? cible;

  /// **CIVIQUE** : thèmes à renforcer ou faibles.
  ///
  /// 🛑 `null` tant qu'aucun diagnostic n'est clos — `0` voudrait dire « tout
  /// est solide », ce qui est une tout autre nouvelle.
  final int? aRenforcer;

  factory ModulePreparation.fromJson(Map<String, dynamic> json) =>
      ModulePreparation(
        etape: PreparationEtape.fromWire(json['etape'] as String),
        fait: (json['fait'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
        sessionId: json['sessionId'] as String?,
        niveau: json['niveau'] != null
            ? NiveauCecrl.fromWire(json['niveau'] as String)
            : null,
        cible: json['cible'] != null
            ? NiveauCecrl.fromWire(json['cible'] as String)
            : null,
        aRenforcer: (json['aRenforcer'] as num?)?.toInt(),
      );
}

class PreparationDto {
  const PreparationDto({required this.tcf, required this.civique});

  final ModulePreparation tcf;
  final ModulePreparation civique;

  factory PreparationDto.fromJson(Map<String, dynamic> json) => PreparationDto(
        tcf: ModulePreparation.fromJson(json['tcf'] as Map<String, dynamic>),
        civique:
            ModulePreparation.fromJson(json['civique'] as Map<String, dynamic>),
      );
}
