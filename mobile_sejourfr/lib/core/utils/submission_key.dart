import 'dart:math';

/// Cles d'idempotence des soumissions payantes (backend V046).
///
/// Le probleme qu'elles ferment : une production EE/EO part, le reseau lache
/// avant la reponse, le client renvoie — et le serveur, qui n'a aucun moyen de
/// reconnaitre la meme production, paie une seconde correction IA et decompte
/// une seconde fois le quota du candidat. Sur mobile le cas est plus frequent
/// que sur le web : reseau cellulaire, application mise en arriere-plan.
///
/// 🛑 **Une cle par PRODUCTION, jamais par requete.** Une cle regeneree a chaque
/// envoi ne protege de rien : c'est precisement le renvoi qui doit porter la
/// meme cle que l'envoi initial. Elle ne change que lorsque le candidat commence
/// une *autre* production.
///
/// Le serveur traite une cle absente comme « ce client ne sait pas encore se
/// repeter sans dommage » et garde l'ancien comportement : ne jamais envoyer de
/// cle bricolee pour « faire propre ».
///
/// Miroir de `web_sejoufr/lib/idempotency.ts`.
class SubmissionKeys {
  SubmissionKeys();

  final Map<String, String> _keys = <String, String>{};
  static final Random _random = Random.secure();

  /// La cle stable de la production designee par [identity], creee au premier
  /// appel.
  ///
  /// [identity] designe LA production : typiquement `'$attemptId:$taskId'` pour
  /// une tache complete, `'$promptId'` pour un petit sujet.
  ///
  /// Pourquoi une identite plutot qu'un `reset()` : un reset oublie est
  /// silencieux — deux productions differentes partiraient sous la meme cle, et
  /// la seconde recevrait le rapport de la premiere. Une identite fausse, elle,
  /// se voit immediatement.
  String keyFor(String identity) =>
      _keys.putIfAbsent(identity, SubmissionKeys.newKey);

  /// Oublie tout : a appeler quand l'ecran quitte definitivement le parcours.
  void clear() => _keys.clear();

  /// UUID v4 tire au sort. La qualite aleatoire importe peu : la cle est bornee
  /// a un utilisateur cote serveur, une collision entre deux comptes est sans
  /// effet.
  static String newKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
