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
  ///
  /// 🛑 Ne veut **pas** dire « pas de plan » : depuis l'arbitrage du
  /// 2026-09-12, le Plan existe dès cette étape. Le fait à lire est
  /// [ModulePreparation.planDisponible].
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
    this.estimationSessionId,
    this.niveau,
    this.cible,
    this.aRenforcer,
    this.planDisponible = false,
    this.prochaineEpreuve,
  });

  final PreparationEtape etape;

  /// Avancement (2 épreuves, 14 questions). `null` si la notion n'a pas de sens
  /// à cette étape.
  final int? fait;
  final int? total;

  /// Le diagnostic à **reprendre** : le complet dès qu'il est ouvert.
  final String? sessionId;

  /// **TCF** : la session du diagnostic **RAPIDE** déjà clos.
  ///
  /// 🛑 **Servie à toutes les étapes**, indépendamment de [etape] et de
  /// [sessionId] — dès que le complet démarre, [sessionId] désigne le complet,
  /// et sans ce champ le rapport du rapide (le seul résultat que le candidat
  /// possède alors) devenait introuvable. `null` = aucun rapide clos, donc rien
  /// à relire : c'est le seul état où la porte du Plan n'affiche pas de rapport.
  final String? estimationSessionId;

  /// **TCF** : 🛑 `null` = pas encore mesuré, jamais A1.
  final NiveauCecrl? niveau;
  final NiveauCecrl? cible;

  /// **CIVIQUE** : thèmes à renforcer ou faibles.
  ///
  /// 🛑 `null` tant qu'aucun diagnostic n'est clos — `0` voudrait dire « tout
  /// est solide », ce qui est une tout autre nouvelle.
  final int? aRenforcer;

  /// 🛑 **Le Plan de ce module est-il constructible maintenant ?** C'est le
  /// seul fait sur lequel un écran ouvre la page Plan.
  ///
  /// Depuis l'arbitrage du 2026-09-12, le diagnostic complet n'est **plus un
  /// prérequis** : dès que le rapide est clos, le Plan existe — provisoire mais
  /// réel, bâti uniquement sur ce que le rapide a mesuré. Ne pas le déduire de
  /// [etape] : le serveur rend ici, mot pour mot, la condition de son propre
  /// moteur.
  final bool planDisponible;

  /// **TCF** : la prochaine épreuve du diagnostic **COMPLET**, celle par
  /// laquelle on reprend.
  ///
  /// 🛑 `null` quand il n'y a rien à reprendre (complet jamais démarré, ou
  /// terminé) — jamais déduite d'un compteur.
  final EpreuveType? prochaineEpreuve;

  factory ModulePreparation.fromJson(Map<String, dynamic> json) =>
      ModulePreparation(
        etape: PreparationEtape.fromWire(json['etape'] as String),
        fait: (json['fait'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
        sessionId: json['sessionId'] as String?,
        estimationSessionId: json['estimationSessionId'] as String?,
        niveau: json['niveau'] != null
            ? NiveauCecrl.fromWire(json['niveau'] as String)
            : null,
        cible: json['cible'] != null
            ? NiveauCecrl.fromWire(json['cible'] as String)
            : null,
        aRenforcer: (json['aRenforcer'] as num?)?.toInt(),
        planDisponible: json['planDisponible'] as bool? ?? false,
        prochaineEpreuve: json['prochaineEpreuve'] != null
            ? EpreuveType.fromWire(json['prochaineEpreuve'] as String)
            : null,
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
