/// **Les phrases de l'onglet Profil** (Navigation v2, phase 4b — maquette
/// `docs/redesign/sejourfr-navigation-mobile.html`, `#profil`). Textes
/// éditoriaux repris tels quels (R8), sauf « Mon abonnement » → **« Mon
/// pass »** (R6 : « abonnement » n'est jamais visible). Toute valeur (nom,
/// démarche, pass, échéance) est servie.
library;

const String kProfileTitle = 'Profil';
const String kProfileLead = 'Votre compte, votre objectif et vos réglages.';
const String kProfileEdit = 'Modifier';

/// « Objectif : Naturalisation française » — la démarche servie.
String profileObjectif(String demarche) => 'Objectif : $demarche';

const String kProfileObjectifSection = 'Mon objectif';
const String kProfileObjectifNone = 'Choisir mon parcours';
const String kProfileObjectifEdit = 'Parcours visé — toucher pour modifier';
const String kProfileObjectifNoneMeta =
    'Définissez votre objectif administratif';

const String kProfileAccountSection = 'Mon compte';

const String kProfilePassTitle = 'Mon pass';
const String kProfilePassActive = 'Actif';
const String kProfilePassFree = 'Gratuit';
const String kProfilePassFreeMeta = 'Accès limité — débloquez tout SejourFR';
const String kProfilePassActiveMeta = 'Accès actif';

/// « {nom du pass} · Valable jusqu'au {échéance} ».
String profilePassMeta(String nom, String detail) => '$nom · $detail';
String profilePassUntil(String date) => "Valable jusqu'au $date";

const String kProfileInfosTitle = 'Mes informations';
const String kProfileProgressionTitle = 'Ma progression';
const String kProfileProgressionMeta = 'Maîtrise par parcours et niveau estimé';
const String kProfileHelpTitle = 'Aide';
const String kProfileHelpMeta = 'Questions fréquentes et contact';
const String kProfileAboutTitle = 'À propos de SejourFR';
const String kProfileAboutMeta = 'Outil indépendant · sources officielles';
