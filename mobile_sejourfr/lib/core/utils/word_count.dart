/// Le nombre de mots d'un texte : ce que comptent la zone d'écriture d'une
/// production EE, celle du diagnostic et « Revoir ma réponse ». Une seule
/// règle, pour qu'un même texte n'affiche jamais deux comptes différents.
int compterMots(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}
