/// **Le jour civil à Paris**, sans base de fuseaux embarquée.
///
/// Le serveur compte tout ce qui est journalier en **Europe/Paris**
/// (`FenetreMesure.PARIS`) : la mesure d'audience, et — pour la séance du Plan
/// — la journée à laquelle un front compare `lastActivityAt`. Comparer en heure
/// de l'appareil ferait diverger deux candidats du même compte selon l'endroit
/// d'où ils ouvrent l'app.
///
/// 🛑 **Aucun paquet `timezone` n'est ajouté pour ça.** La règle européenne
/// tient en quatre lignes et ne bouge pas : UTC+1, UTC+2 du **dernier dimanche
/// de mars à 01:00 UTC** au **dernier dimanche d'octobre à 01:00 UTC**. Le web,
/// lui, s'appuie sur l'`Intl` du navigateur, qui porte déjà la base — les deux
/// répondent la même chose.
library;

/// Le jour civil parisien de [instant], sous la forme `"2026-08-21"`.
String parisDay(DateTime instant) {
  final paris = instant.toUtc().add(Duration(hours: _parisOffsetHours(instant.toUtc())));
  final month = paris.month.toString().padLeft(2, '0');
  final day = paris.day.toString().padLeft(2, '0');
  return '${paris.year}-$month-$day';
}

/// `true` quand les deux instants tombent le même jour civil à Paris.
bool sameParisDay(DateTime a, DateTime b) => parisDay(a) == parisDay(b);

int _parisOffsetHours(DateTime utc) {
  final debut = _dernierDimanche(utc.year, 3);
  final fin = _dernierDimanche(utc.year, 10);
  return !utc.isBefore(debut) && utc.isBefore(fin) ? 2 : 1;
}

/// Le dernier dimanche du mois, à 01:00 UTC — l'heure de bascule européenne.
DateTime _dernierDimanche(int annee, int mois) {
  final dernierJour = DateTime.utc(annee, mois + 1, 0, 1);
  // `DateTime.sunday` vaut 7 : un dimanche recule de zéro jour.
  return dernierJour.subtract(Duration(days: dernierJour.weekday % 7));
}
