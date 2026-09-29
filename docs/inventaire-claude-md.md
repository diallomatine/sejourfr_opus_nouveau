# Inventaire de `CLAUDE.md` (racine) — préalable à la restructuration

> **Statut : EXÉCUTÉ le 2026-08-23.** L'inventaire ci-dessous est conservé comme trace de la
> décision ; le **tableau de contrôle** en fin de document dit où chaque section a atterri.

**Mesure du 2026-08-23** : `CLAUDE.md` racine = **343 599 chars**, 4 551 lignes, 24 sections
H2. La limite est de **150 000 chars**, et le fichier est rechargé **intégralement à chaque
requête**. Il faut donc en sortir **~320k** et le ramener à un index court qui pointe vers
des fichiers lus à la demande.

---

## Le critère retenu

La bonne question n'est pas « est-ce important ? » — ici **tout** est important. C'est :

> **Un agent qui ne lit pas ça risque-t-il de casser quelque chose sur une tâche où il
> n'avait aucune raison d'ouvrir le fichier ?**

Trois issues :

1. **Routage** — ce qui dit *quel fichier ouvrir*. Résident par définition.
2. **Invariant transverse qui casse en silence** — une règle qui s'applique à des tâches qui
   n'en ont pas l'air : parité 3 fronts, aucun test front, aucune campagne LLM payante,
   jamais de `.md` non demandé, mode orchestrateur, jamais de couleur en dur,
   `null = inconnu jamais mauvais`, couches Controller → Service → Manager → Repository. Si
   ce n'est pas résident, c'est violé par un agent qui travaille ailleurs. Résident,
   **compressé à la règle + le pourquoi en une ligne**.
3. **Détail de sous-système** — une règle dont on a besoin *seulement quand on est déjà
   dedans*, et où le fichier à ouvrir porte le nom du sous-système. À la demande. **C'est la
   très grande majorité du fichier.**

Deux critères secondaires qui tranchent les cas limites :

- **Un garde-fou déjà cassé une fois, documenté avec son coût** (ex. `END_SENSITIVITY_MEDIUM`
  → 4 jours sans temps réel) a une valeur énorme **mais il est scopé** : il ne se déclenche
  que si on touche la VAD. À la demande.
- **Le journal d'arbitrages** (« v15 est v14 au bit près sauf… », « révoque la règle du… »,
  « mesuré en base »). C'est ce qui empêche de re-litiger une décision — donc précieux — mais
  c'est **archivistique** : nécessaire quand on rouvre ce sous-système, jamais autrement.
  **C'est le plus gros gisement du fichier, et de loin.**

## Catégories de destination

| Code | Destination | Ce qui y va |
|---|---|---|
| **R** | reste dans `CLAUDE.md` | routage + invariants transverses + vocabulaire minimal pour comprendre une demande |
| **D** | `docs/regles/<sujet>.md` *(à créer)* | la loi serveur d'un sous-système : ce qu'on ne doit pas casser |
| **A** | `docs/decisions/<sujet>.md` *(à créer)* | le journal daté des arbitrages/révocations : ce qu'on ne doit pas re-litiger |
| **E** | fusion dans un `docs/*.md` **existant** | `notation-ia-eo-ee`, `api-endpoints`, `migrations-flyway`, `plan-tests-backend`, `exams-tcf`, `setup-paiement-*`, `roadmap` |
| **S** | supprimé | doublon strict, ré-transcription du code, ou périmé |

**Pourquoi séparer D et A** : le fichier « règles » est ce qu'on doit respecter, le fichier
« décisions » ce qu'on ne doit pas rouvrir. En pratique on a besoin des règles à chaque
édition, des décisions seulement quand on est tenté de changer une règle. Les fusionner
rendrait `docs/regles/plan.md` illisible (96k) ; les séparer le ramène à ~15k.

---

## Inventaire section par section

| # | Section | L. | Chars | Nature | Usage | Décision | Justification |
|---|---|---|---|---|---|---|---|
| — | Préambule / en-tête | 1-10 | 497 | routage | Haute | **R** | Dit ce qu'est le monorepo et d'aller lire les `CLAUDE.md` locaux. |
| 1 | Les 4 sous-projets | 11-25 | 1 425 | routage | Haute | **R** (→900) | Le tableau dossier/stack/port dit où aller ; la typo `web_sejoufr` est un piège réel. |
| 2 | Domaine métier (vocabulaire) | 26-112 | 6 400 | glossaire + enums | Haute | **R** 1 500 / **D** `domaine.md` 4 900 | Il faut savoir ce qu'est une « épreuve » pour lire une demande ; les 80 enums sont **dans le code**, leur détail non. |
| 3 | Freemium | 113-253 | 9 639 | règle métier | Moyenne | **D** `freemium.md` 8 900 / **E** roadmap 700 / **R** 400 | Ne se déclenche que sur un écran d'accès ; contient en plus une formulation **révoquée 766 lignes plus loin**. |
| 4 | Identité IP des appelants | 254-276 | 1 346 | règle serveur | Basse | **D** `mesure-audience.md` | On n'y touche qu'en écrivant un rate-limit. |
| 5 | Mesure d'audience landings | 277-346 | 4 791 | **legacy déclaré** | Archive | **A** `mesure-audience.md` | Le texte dit lui-même « LEGACY depuis le 2026-08-21, supprimés, conservé pour relire l'historique ». |
| 6 | Funnel d'acquisition | 347-425 | 5 365 | règle serveur | Basse | **D** `mesure-audience.md` | Un seul endpoint admin + 2 colonnes ; scopé. |
| 7 | Analytics | 426-554 | 8 332 | règle + arbitrages | Basse | **D** 5 800 / **A** 2 500 | Un écran admin ; les 5 arbitrages propriétaire sont du journal. |
| 8 | Temps des examens blancs | 555-643 | 6 388 | règle serveur | Moyenne | **E** `docs/exams-tcf.md` | `docs/exams-tcf.md` existe déjà et couvre exactement ce périmètre. |
| 9 | Diagnostic + Plan personnalisé | 644-1405 | **58 251** | règle + journal | Moyenne | **D** `diagnostic.md` + `plan.md` ~22k / **A** ~35k / **R** 600 | Le plus gros bloc : ~60 % est du journal daté (V040/V041/V042, révocations, mesures en base). |
| 10 | Plan adaptatif | 1406-1901 | **38 069** | règle + journal | Moyenne | **D** `plan.md` ~16k / **A** ~21k / **R** 300 | **Même sujet que §9** — les fusionner supprime la dérive à deux têtes. |
| 11 | Notation IA EE/EO | 1902-3038 | **88 354** | repères + journal versions | Moyenne | **E** notation-ia ~30k / **D** `notation-ia.md` ~14k / **A** ~44k / **R** 600 | La section dit elle-même « le quoi et le pourquoi vivent dans `docs/notation-ia-eo-ee.md`, ici uniquement de quoi se repérer » — 88k de « repères » dément la phrase. |
| 12 | Niveau QCM plancher A1 | 3039-3094 | 3 925 | règle serveur | Basse | **D** `qcm.md` | Une méthode, trois appelants ; scopé. |
| 13 | Ordre propositions QCM | 3095-3176 | 5 918 | règle serveur | Basse | **D** `qcm.md` | Idem, plus une dette de contenu à consigner. |
| 14 | Audio non conservé | 3177-3237 | 4 311 | **règle transverse** | Moyenne | **R** 250 / **D** `audio-productions.md` 4 000 | « Aucun audio de candidat n'est stocké » **doit** être résident : c'est légal et ça casse en silence ; le détail non. |
| 15 | Module Compétences TCF | 3238-3853 | **44 425** | règle + journal contrats | Moyenne | **D** `competences.md` ~15k / **A** ~29k / **R** 250 | ~65 % est le diff des contrats v1→v6 et les campagnes de banc. |
| 16 | Identité visuelle | 3854-3863 | 485 | routage + invariant | Haute | **R** | Déjà un index, et « jamais de couleur/font en dur » casse en silence. |
| 17 | API backend partagée | 3864-3871 | 294 | routage | Haute | **R** | Base URL, CORS, JWT + renvoi vers `api-endpoints`. |
| 18 | Démarrage local | 3872-3895 | 998 | commandes | Haute | **R** | Les commandes de build/test, utilisées à chaque vérification. |
| 19 | Comptes seed | 3896-3903 | 301 | données dev | Haute | **R** | Trois lignes, indispensables dès qu'on teste. |
| 20 | Architecture mentale | 3904-3942 | 2 340 | **invariant transverse** | Haute | **R** (→1 300) | La convention de couches se viole en silence à chaque fichier créé. |
| 21 | Préférences de collaboration | 3943-4130 | 13 374 | **invariants transverses** | Haute | **R** ~4 500 / **E** `plan-tests-backend` ~8 900 | Orchestrateur, aucun test front, parité 3 fronts, aucune campagne LLM : restent. Les gabarits de test backend ont déjà leur doc. |
| 22 | Paiements multi-source | 4131-4508 | 24 341 | règle + setup + mappings | Basse | **D** `paiements.md` ~8k / **E** setup + api-endpoints ~14k / **E** roadmap ~2k / **R** 400 | Les mappings de webhooks et les étapes de setup store sont de la documentation pure, et 4 docs existent déjà. |
| 23 | Git | 4509-4515 | 298 | routage | Haute | **R** | Remote, branche par défaut, monorepo à un seul git. |
| 24 | Documentation détaillée | 4516-4551 | 2 761 | **index** | Haute | **R** | C'est déjà l'index — il devient la colonne vertébrale du nouveau fichier. |

---

## Doublons (même info à plusieurs endroits)

| Info | Endroits | Gravité |
|---|---|---|
| **Règle freemium** | §3 (transverse), §15 (Compétences), §9 « On floute l'ACTION », §10 « La première place est toujours ouverte » | 🔴 **contradiction active**, voir plus bas |
| **Règles du Plan** | §9 (31 puces) **et** §10 (10 sous-sections) — §10 dit « complète §9, ne la remplace pas » | 🔴 dérive garantie |
| **Notation IA** | §11 (88k) **et** `docs/notation-ia-eo-ee.md` (339k), déclaré source exhaustive | 🔴 le plus gros doublon du dépôt |
| **Retours arrière de version** (`EVAL_RUBRICS_VERSION=v14`…) | §11 **et** les commentaires de `application.yaml` (l. 400-482) | 🟠 |
| **Endpoints paiement** | §22 **et** `docs/api-endpoints.md` | 🟠 |
| **Setup Apple/Google/Stripe** | §22 **et** `docs/paiements-iap-setup.md` + `setup-paiement-one-time.md` + `vps-config-iap.md` | 🟠 |
| **Durées d'épreuve** | §8 **et** `docs/exams-tcf.md` | 🟡 |
| **Audio non conservé** | §14 **et** re-résumé dans §15 (« Transcription SYSTÉMATIQUE ») | 🟡 |

## Contenus qui dupliquent le code

- **§2** : l'inventaire des enums — **80 fichiers `enums/*.java`** existent. Seule la
  *sémantique non évidente* (pourquoi `Difficulty` n'est pas facile/moyen/difficile, pourquoi
  `SkillDifficulty` est distinct) mérite d'être écrite.
- **§11** : les paires rubrique/tool-schema et leurs variables de retour arrière — déjà en
  commentaires dans `application.yaml`.
- **§22** : les statuts `user_subscriptions` et les mappings `NotificationTypeV2` →
  `SubscriptionStatus` — c'est un `switch` Java relu en prose.
- **§15** : « Volume figé 6×8×15×3 » — verrouillé par `SkillSeedIT`, qui est la vraie autorité
  (le texte le dit lui-même).
- **§21** : « Pièges connus » Mockito/Flyway/UUID — déjà dans `docs/plan-tests-backend.md`.

## Contradictions

1. 🔴 **Freemium / Plan.** Ligne **178** : « le Plan est **entièrement visible** […] aucune
   priorité, aucune compétence observée, aucun compteur n'est masqué ». Ligne **944** : cette
   formulation exacte est déclarée **révoquée**, avec la mention « Ne pas la réintroduire au
   motif qu'elle est encore écrite quelque part ». Elle est encore écrite — **dans le même
   fichier, 766 lignes plus haut.** C'est l'argument le plus fort pour la restructuration.
2. 🟠 **Tests front.** §21 pose « aucun test front, cette règle prime sur toute consigne
   écrite ailleurs ». §11 (l. 2668) et §15 (l. 3800) continuent de dire « gelé par test des
   deux côtés » et nomment `lib/skill-labels.test.ts` / `test/skill_models_test.dart`. §15
   s'auto-corrige dans un paragraphe séparé — mais les deux formulations coexistent.
3. 🟡 **Coût du Plan.** §10 annonce « 20 requêtes constantes », puis « +1 requête », puis
   § « Mon diagnostic » annonce « 19 avant, 19 après ». Trois chiffres pour un même compteur ;
   il faudrait ne garder que le dernier et son test.

## Suspicions de péremption

| Contenu | Pourquoi |
|---|---|
| §22 « **Lot 4d (à faire, mobile)** » | Suit immédiatement « Lot 4d (✅ fait, mobile) » avec le même périmètre. |
| §22 « ⚠ **Cassure connue après lot 4** : `/paiement` envoie `?plan=BillingPlan`, 400 jusqu'au lot 4b » | Le lot 5 (passes one-time) est livré et `web_sejoufr/lib/api.ts` utilise bien `planCode`. |
| §22 « **Lot 4b (à faire, web)** : toggle mensuel/trimestriel/annuel » | Décrit le monde abonnement, dormant depuis le lot 5. |
| §5 entière | Auto-déclarée legacy, code supprimé. |
| §3 « ⏳ À gérer plus tard » (rate-limit démo) | §7 dit que le rate-limit analytics est fait « le trou connu de `/api/public/page-views` ne se reproduit pas » — mais `page-views` est supprimé, donc le TODO n'a plus le même objet. |
| §11 « Deux drapeaux livrés ÉTEINTS » (`fluidite`, `seconde-passe`) | Aucune date, aucune mention depuis. |

## Non tranché — questions au propriétaire

1. **`mobile_sejourfr/CLAUDE.md` = 224 976 chars et `web_sejoufr/CLAUDE.md` = 226 976 chars.**
   Les deux dépassent la limite, et ils sont rechargés dès qu'un agent touche à ces dossiers.
   **Traiter dans la même passe, ou seulement la racine pour l'instant ?**
2. **Le journal d'arbitrages (`docs/decisions/`) — intégral ou condensé ?** Il représente
   ~130k et il est verbeux (chiffres de mesure, verbatims). Il a une vraie valeur (il empêche
   de re-litiger), mais il peut être réduit de moitié en gardant décision + date + motif et en
   coupant les démonstrations.
3. **`docs/notation-ia-eo-ee.md` fait déjà 339k** et la règle du dépôt dit qu'il doit rester
   « exhaustif, à jour et compréhensible par un non-informaticien ». Y verser 30k de §11 le
   rend encore plus lourd et mélange grand public et technique. **Verser dedans, ou créer
   `docs/regles/notation-ia.md` pour tout le technique et laisser le grand public tranquille ?**
4. **Il n'existe pas de `backend_sejourfr/CLAUDE.md`** — la racine en tient lieu, ce qui
   explique sa taille. **En créer un (chargé seulement quand on travaille dans le backend), ou
   tout mettre dans `docs/` ?** La première option est plus efficace mais recrée un fichier
   lourd auto-chargé.
5. **§21 « Mode agent par défaut — Claude est l'ORCHESTRATEUR »** peut entrer en conflit avec
   une consigne de session (« ne pas appeler l'outil Agent sans demande »). **Garder tel quel,
   ou reformuler ?**

---

## Totaux

| Catégorie | Chars | Part |
|---|---|---|
| **R** — reste dans `CLAUDE.md` | **~20 000** | 5,8 % |
| **D** — `docs/regles/` (9 fichiers) | ~106 000 | 30,8 % |
| **A** — `docs/decisions/` (6 fichiers) | ~134 000 | 39,0 % |
| **E** — fusion dans docs existants | ~66 000 | 19,2 % |
| **S** — supprimé (doublons stricts, code, périmé) | ~18 000 | 5,2 % |
| **Total** | 343 599 | 100 % |

**`CLAUDE.md` final estimé : ~20 000 chars** — ≈ 6 % de l'actuel, **13 % de la limite**.

Marge volontairement large : le fichier regrossira au fil des chantiers, et repasser sous les
150k une seconde fois coûterait la même passe.

---


# Tableau de contrôle — exécuté le 2026-08-23

**Aucune ligne orpheline.** La découpe a été faite par **partition stricte des 4 552 lignes** de
l'ancien fichier, vérifiée par assertion : 0 chevauchement, 0 ligne non attribuée. Une seconde
vérification a confirmé que **4 245 des 4 248 lignes non vides** déplacées se retrouvent
**verbatim** dans `docs/` — les 3 manquantes sont la révocation appliquée (#1), citée
intégralement dans `docs/decisions/contradictions-ouvertes.md`.

## Où est allée chaque section

| # | Section d'origine | Lignes | Destination | Verbatim ? |
|---|---|---|---|---|
| — | Préambule | 1-10 | `CLAUDE.md` (§ *Comment lire ce fichier*, § *Le monorepo*) | reformulé |
| 1 | Les 4 sous-projets | 11-25 | `CLAUDE.md` (§ *Le monorepo*) | tableau + stratégie verbatim |
| 2 | Domaine métier (vocabulaire) | 26-112 | `docs/regles/domaine.md` · glossaire court dans `CLAUDE.md` | ✅ verbatim |
| 3 | Freemium | 113-253 | `docs/regles/freemium.md` | ✅ verbatim **sauf l. 178-180** (révocation #1 appliquée) |
| 4 | Identité IP des appelants | 254-276 | `docs/regles/mesure-audience.md` | ✅ verbatim |
| 5 | Mesure d'audience landings | 277-346 | `docs/decisions/mesure-audience.md` + bandeau ⚠ suspect #4 | ✅ verbatim |
| 6 | Funnel d'acquisition | 347-425 | `docs/regles/mesure-audience.md` | ✅ verbatim |
| 7 | Analytics | 426-554 | `docs/regles/mesure-audience.md` | ✅ verbatim |
| 8 | Temps des examens blancs | 555-643 | `docs/regles/examens-temps.md` | ✅ verbatim |
| 9 | Diagnostic + Plan personnalisé | 644-813, 1342-1405 | `docs/regles/diagnostic.md` | ✅ verbatim |
| 9 | ↳ partie **Plan** | 814-1195 | `docs/regles/plan.md` (1ʳᵉ moitié) | ✅ verbatim |
| 9 | ↳ journal **V040 / V041 / V042** | 1196-1341 | `docs/decisions/diagnostic.md` | ✅ verbatim |
| 10 | Plan adaptatif | 1406-1901 | `docs/regles/plan.md` (2ᵈᵉ moitié) | ✅ verbatim |
| 11 | Notation IA — règles | 1902-1915, 2034-2163, 2322-3038 | `docs/regles/notation-ia.md` | ✅ verbatim |
| 11 | ↳ journal des **versions v4 → v15** | 1916-2033, 2164-2321 | `docs/decisions/notation-ia.md` | ✅ verbatim |
| 12 | Niveau QCM plancher A1 | 3039-3094 | `docs/regles/qcm.md` | ✅ verbatim |
| 13 | Ordre propositions QCM | 3095-3176 | `docs/regles/qcm.md` | ✅ verbatim |
| 14 | Audio non conservé | 3177-3237 | `docs/regles/audio-productions.md` · invariant résident dans `CLAUDE.md` | ✅ verbatim |
| 15 | Compétences TCF — règles | 3238-3282, 3395-3422, 3479-3486, 3642-3853 | `docs/regles/competences.md` | ✅ verbatim |
| 15 | ↳ journal des **contrats v2 → v6** | 3283-3394, 3423-3478, 3487-3641 | `docs/decisions/competences.md` | ✅ verbatim |
| 16 | Identité visuelle | 3854-3863 | `CLAUDE.md` (§ *Pour tout écran*) | reformulé, tout conservé |
| 17 | API backend partagée | 3864-3871 | `CLAUDE.md` (§ *API backend partagée*) | reformulé, tout conservé |
| 18 | Démarrage local | 3872-3895 | `CLAUDE.md` (§ *Démarrage local*) | reformulé, cf. note ¹ |
| 19 | Comptes seed | 3896-3903 | `CLAUDE.md` (§ *Démarrage local*) | ✅ tableau verbatim |
| 20 | Architecture mentale par projet | 3904-3942 | **`docs/regles/collaboration.md` (annexe, verbatim)** · forme courte dans `CLAUDE.md` · couches développées dans `backend_sejourfr/CLAUDE.md` | ✅ verbatim en annexe |
| 21 | Préférences de collaboration | 3943-4130 | `docs/regles/collaboration.md` · invariants résidents dans `CLAUDE.md` | ✅ verbatim |
| 22 | Paiements — règles | 4131-4234, 4367-4508 | `docs/regles/paiements.md` | ✅ verbatim |
| 22 | ↳ **lots 1 → 5 + geste V038** | 4235-4366 | `docs/decisions/paiements.md` + bandeaux ⚠ suspects #1-3 | ✅ verbatim |
| 23 | Git | 4509-4515 | `CLAUDE.md` (§ *Git*) | ✅ verbatim |
| 24 | Documentation détaillée | 4516-4552 | `CLAUDE.md` (§ *Documentation de référence*) | index reformulé, cf. note ² |

## Supprimé — le texte retiré, cité

**Une seule suppression**, autorisée explicitement (exception à la règle « ce refactor ne
supprime rien ») parce que le texte se tranchait lui-même.

### `CLAUDE.md` l. 178-180 — formulation freemium révoquée

> **Compte gratuit, Plan personnalisé** : le Plan est **entièrement visible**,
> diagnostic compris. Aucune priorité, aucune compétence observée, aucun
> compteur n'est masqué — seul un `locked` est posé.

**Motif** : explicitement révoquée le 2026-08-21 par la règle « On floute l'ACTION pas encore
accessible, jamais le RÉSULTAT mesuré » (ancienne l. 944-949), qui ajoutait « Ne pas la
réintroduire au motif qu'elle est encore écrite quelque part » — alors qu'elle l'était, 766
lignes plus haut dans le même fichier. **Texte conservé intégralement** dans
`docs/decisions/contradictions-ouvertes.md` (#1). La fin de la ligne 180 (« La compétence de
sa ») est conservée dans `docs/regles/freemium.md` : la puce continue.

### Notes sur les reformulations du bloc résident

¹ **§18 — deux lignes non reprises** : `flutter run --dart-define=API_BASE_URL=...` (iOS sim et
Android emu). **Motif** : `mobile_sejourfr/CLAUDE.md` indique que « ces flags sont désormais
ignorés (les getters ne lisent plus `String.fromEnvironment`) » — la config passe par
`mobile_sejourfr/.env`. Les reprendre aurait propagé une consigne fausse.

² **§24 — descriptions raccourcies** : les **20 entrées** de l'index sont toutes présentes dans
le nouveau `CLAUDE.md` ; seules les descriptions longues ont été condensées (notamment le
paragraphe de 9 lignes décrivant le sommaire de `docs/notation-ia-eo-ee.md`). **La règle qu'il
portait est conservée intégralement** dans `CLAUDE.md` § *Maintenir les `CLAUDE.md` à jour* :
« doit TOUJOURS être exhaustive et à jour […] dans la même passe […] compréhensible par un
non-informaticien ».

**Récupération** : l'ancien fichier complet reste dans l'historique git —
`git show fe7579f0:CLAUDE.md`.

## Fichiers créés

### Résidents

| Fichier | Chars | Rôle |
|---|---|---|
| `CLAUDE.md` | **19 176** | Index racine : règle de lecture, monorepo, vocabulaire minimal, invariants transverses, conventions, démarrage, index par situation |
| `backend_sejourfr/CLAUDE.md` | **9 985** | *Nouveau.* Convention de couches, façon d'écrire une règle serveur, migrations, tests, parité — **zéro règle métier** |

### `docs/regles/` — la loi d'un sous-système (lue à la demande)

| Fichier | Chars |
|---|---|
| `docs/regles/notation-ia.md` | 70 044 |
| `docs/regles/plan.md` | 69 475 |
| `docs/regles/competences.md` | 22 242 |
| `docs/regles/diagnostic.md` | 18 779 |
| `docs/regles/collaboration.md` | 17 283 |
| `docs/regles/mesure-audience.md` | 16 151 |
| `docs/regles/paiements.md` | 16 111 |
| `docs/regles/freemium.md` | 11 154 |
| `docs/regles/qcm.md` | 10 753 |
| `docs/regles/examens-temps.md` | 7 176 |
| `docs/regles/domaine.md` | 7 147 |
| `docs/regles/audio-productions.md` | 4 969 |

### `docs/decisions/` — journal daté, verbatim et intégral

| Fichier | Chars |
|---|---|
| `docs/decisions/competences.md` | 25 032 |
| `docs/decisions/notation-ia.md` | 22 651 |
| `docs/decisions/diagnostic.md` | 13 562 |
| `docs/decisions/paiements.md` | 10 678 |
| `docs/decisions/contradictions-ouvertes.md` | 7 385 |
| `docs/decisions/mesure-audience.md` | 5 731 |
| `docs/decisions/suspects-perimes.md` | 5 395 |

## Fichiers NON touchés

Aucun `docs/*.md` existant n'a été modifié : `notation-ia-eo-ee.md`, `api-endpoints.md`,
`exams-tcf.md`, `migrations-flyway.md`, `plan-tests-backend.md`, `setup-paiement-one-time.md`,
`paiements-iap-setup.md`, `vps-config-iap.md`, `bascule-prix-integral.md`, `roadmap.md`,
`lots-entrainement.md`, `auth-social.md`, `identite-visuelle.md`, `pipeline-*.md`,
`refonte-entrainement.md`, et tous les sous-dossiers (`audio-pipeline/`, `diagnostiques/`,
`ia/`, `plan/`, `relatime/`, `skills/`). Les nouveaux fichiers y **renvoient**, ils n'y versent
rien.

## Ce qui reste à faire

1. **Trancher les contradictions #2 et #3** (`docs/decisions/contradictions-ouvertes.md`).
2. **Revoir les 6 suspects périmés** (`docs/decisions/suspects-perimes.md`) — chacun porte son
   bandeau à l'endroit du verbatim, aucun n'a été supprimé.
3. **`mobile_sejourfr/CLAUDE.md` (224 976 chars) et `web_sejoufr/CLAUDE.md` (226 976 chars)**
   dépassent eux aussi la limite. Passes séparées, **même patron** : index + invariants dans le
   fichier résident, règles et journal dans `docs/`.
4. **Signalé par la fusion §9 + §10** : les deux moitiés de `docs/regles/plan.md` ont été
   concaténées dans l'ordre chronologique (§9 = 2026-08-10 → 08-16, §10 = 08-21 → 08-22) sans
   aucune réécriture. La seule divergence relevée est la contradiction #3 (coût du Plan), marquée
   en place aux deux endroits.
