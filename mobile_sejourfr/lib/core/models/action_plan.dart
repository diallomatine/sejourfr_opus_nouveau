/// Le **plan d'action « pour viser X »** — briques PARTAGEES.
///
/// Le micro-exercice de competence (`SkillNiveauViseDto`) et la production
/// complete EE/EO (`VersionCiblee`) sortent du **meme second appel LLM** et
/// rendent le **meme plan** : des leviers, une version plus aboutie (ou, a
/// l'oral, des passages redits) et une tournure a retenir. Les formes sont
/// identiques au champ pres — deux jeux de classes jumelles auraient diverge au
/// premier champ ajoute, et les widgets qui les affichent sont eux aussi
/// partages (`screens/tcf_production/widgets/action_plan.dart`).
///
/// Seule la **cle exterieure** differe : le DTO de competence arrive en
/// camelCase (`exempleCible`, `aRetenir`), le bloc `version_ciblee` du feedback
/// en snake_case (`exemple_cible`, `a_retenir`). Les cles INTERIEURES, elles,
/// sont les memes des deux cotes — c'est pourquoi ces lectures fonctionnent
/// telles quelles pour les deux contrats.
library;

String? _trimmedOrNull(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

/// Un levier : ce qu'on fait, et avec quels mots.
class ActionPlanLevier {
  const ActionPlanLevier({required this.action, this.exemple});

  /// 6 mots maximum, a l'imperatif.
  final String action;

  /// 5 mots maximum, un bout de langue recopiable tel quel.
  final String? exemple;

  static ActionPlanLevier? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final action = _trimmedOrNull(json['action']);
    if (action == null) return null;
    return ActionPlanLevier(
      action: action,
      exemple: _trimmedOrNull(json['exemple']),
    );
  }

  static List<ActionPlanLevier> listFrom(Object? raw) {
    if (raw is! List) return const <ActionPlanLevier>[];
    return raw
        .map(ActionPlanLevier.fromJsonNullable)
        .whereType<ActionPlanLevier>()
        .toList(growable: false);
  }
}

/// Un passage a mettre en evidence dans [ActionPlanExempleCible.texte].
///
/// **[extrait] est garanti sous-chaine exacte du texte** par le serveur (il
/// refuse le bloc entier sinon) : le surlignage se fait par simple recherche de
/// chaine, sans normalisation ni approximation. Introuvable malgre tout ⇒ on
/// rend le texte brut, jamais d'erreur.
class ActionPlanSegment {
  const ActionPlanSegment({required this.extrait, this.apport});

  final String extrait;

  /// Ce que le passage apporte, 3 mots maximum.
  final String? apport;

  static ActionPlanSegment? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final extrait = _trimmedOrNull(json['extrait']);
    if (extrait == null) return null;
    return ActionPlanSegment(
      extrait: extrait,
      apport: _trimmedOrNull(json['apport']),
    );
  }
}

/// La reponse du candidat reecrite au niveau vise, et les endroits ou se joue
/// la difference. **Production ECRITE seulement.**
class ActionPlanExempleCible {
  const ActionPlanExempleCible({required this.texte, required this.segments});

  final String texte;
  final List<ActionPlanSegment> segments;

  static ActionPlanExempleCible? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final texte = _trimmedOrNull(json['texte']);
    if (texte == null) return null;
    final raw = json['segments'];
    return ActionPlanExempleCible(
      texte: texte,
      segments: raw is! List
          ? const <ActionPlanSegment>[]
          : raw
              .map(ActionPlanSegment.fromJsonNullable)
              .whereType<ActionPlanSegment>()
              .toList(growable: false),
    );
  }
}

/// Un passage de la production **orale**, redit au niveau vise.
///
/// L'oral n'a **jamais** de texte modele complet : ce que lit le correcteur est
/// une transcription automatique, en refaire un beau discours tromperait le
/// candidat sur ce qu'il a reellement dit. [original] est le passage exact du
/// candidat, resolu par le SERVEUR depuis un numero de segment — aucun entier
/// n'arrive jusqu'ici.
class ActionPlanReformulation {
  const ActionPlanReformulation({
    required this.original,
    required this.reformule,
    this.apport,
  });

  final String original;
  final String reformule;

  /// Ce que la reformulation apporte, 3 mots maximum.
  final String? apport;

  static ActionPlanReformulation? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final original = _trimmedOrNull(json['original']);
    final reformule = _trimmedOrNull(json['reformule']);
    if (original == null || reformule == null) return null;
    return ActionPlanReformulation(
      original: original,
      reformule: reformule,
      apport: _trimmedOrNull(json['apport']),
    );
  }

  static List<ActionPlanReformulation> listFrom(Object? raw) {
    if (raw is! List) return const <ActionPlanReformulation>[];
    return raw
        .map(ActionPlanReformulation.fromJsonNullable)
        .whereType<ActionPlanReformulation>()
        .toList(growable: false);
  }
}

/// La tournure a emporter ailleurs.
class ActionPlanMemo {
  const ActionPlanMemo({required this.formule, this.explication});

  /// 8 mots maximum, ecrite comme un patron.
  final String formule;

  /// 14 mots maximum, quand et pourquoi elle sert.
  final String? explication;

  static ActionPlanMemo? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final formule = _trimmedOrNull(json['formule']);
    if (formule == null) return null;
    return ActionPlanMemo(
      formule: formule,
      explication: _trimmedOrNull(json['explication']),
    );
  }
}
