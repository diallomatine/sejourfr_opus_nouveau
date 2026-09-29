/// **Le format de l'examen civique, et il vient de la loi.**
///
/// 🛑 Miroir mot pour mot de `web_sejoufr/lib/civique-examen.ts` et de
/// `backend_sejourfr/.../enums/CivicExamFormat.java`, qui est l'autorité.
///
/// Source de droit : **arrêté du 10 octobre 2025** relatif au programme, aux
/// épreuves et aux modalités d'organisation de l'examen civique — JORF n° 0240
/// du 12 octobre 2025, NOR **INTV2527907A**, article 3 et annexe I.
///
/// 🛑 **Ce n'est pas un réglage produit.** Ces valeurs ne se négocient pas et ne
/// se recopient pas en littéral dans un écran — le briefing civique annonçait
/// « 40 questions », « 45 minutes » et « 32 / 40 » en dur dans trois chaînes.
///
/// ⚠️ **Ce qui n'est PAS ici, et ne doit pas y venir** : le quota par unité
/// officielle (Devise et symboles 3, Laïcité 2, …) et les totaux par thématique
/// (11 / 6 / 11 / 8 / 4). Le premier vit dans `civic_official_units` côté
/// serveur ; les seconds ne sont déclarés **nulle part** et se dérivent par
/// somme. Un front n'a besoin d'aucun des deux : il affiche un examen, il ne le
/// compose pas.
class CivicExamFormat {
  const CivicExamFormat._();

  /// Questions d'un examen civique réel.
  static const int questions = 40;

  /// Bonnes réponses exigées pour réussir (80 %).
  static const int seuil = 32;

  /// Durée maximale de l'épreuve, en minutes.
  static const int dureeMinutes = 45;

  /// L'examen de **thème** : un format **SejourFR**, jamais un format officiel.
  static const int questionsTheme = 20;

  /// Bonnes réponses exigées sur un examen de thème (80 %, comme l'officiel).
  static const int seuilTheme = 16;

  /// Durée d'un examen de thème, en minutes.
  static const int dureeThemeMinutes = 20;
}
