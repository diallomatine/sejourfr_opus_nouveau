# Audit du référentiel civique — reconstruit à partir du corpus réel

> 🛑 **Aucun appel LLM.** L'audit s'est fait en lisant les 840 questions
> `CONNAISSANCE` une à une et en interrogeant la base. Le pré-tagging est en pause.
> 🛑 **Aucun `civic_notion_id` n'a été modifié.** Aucune migration, aucun code.
> Ce document est une **analyse**, pas un changement.

Corpus audité : les **840 questions civiques actives de type `CONNAISSANCE`**,
réparties en 5 thèmes. (La base contient 1 016 questions civiques actives ; les
176 `MISE_SITUATION` relèvent des domaines `sit_*`, hors périmètre — voir §6.)

| Thème | CSP | CR | NAT | Total | Notions aujourd'hui | Notions recommandées |
|---|---:|---:|---:|---:|---:|---:|
| `CIV_HISTOIRE_GEO` | 73 | 72 | 70 | 215 | 10 | **12** |
| `CIV_INSTITUTIONS` | 67 | 90 | 57 | 214 | 9 | **8** |
| `CIV_DROITS_DEVOIRS` | 45 | 72 | 49 | 166 | 8 | **9** |
| `CIV_SOCIETE` | 54 | 72 | 40 | 166 | 8 | **12** |
| `CIV_PRINCIPES` | 19 | 44 | 16 | 79 | 6 | **5** |
| **Total** | **258** | **350** | **232** | **840** | **41** | **46** |

---

## 0. Les trois constats qui commandent tout le reste

### 0.1 🛑 Les trois mentions ne sont pas trois niveaux du même programme

C'est le résultat le plus important de l'audit, et il a été trouvé **indépendamment
sur les cinq thèmes**. CSP, CR et NAT ne posent pas les mêmes questions sur les
mêmes sujets à des difficultés différentes : **ils posent des questions sur des
sujets différents.**

| Thème | Ce que le CSP ignore totalement | Ce que le CR ignore totalement | Ce que le NAT ignore totalement |
|---|---|---|---|
| `CIV_HISTOIRE_GEO` | Napoléon (0), l'Europe (0), les écrivains (0) | l'Europe (0) | les fêtes et jours fériés (0) |
| `CIV_INSTITUTIONS` | le Conseil constitutionnel, les tribunaux, le département et la région | **le gouvernement (0)** | la commune, le Premier ministre |
| `CIV_DROITS_DEVOIRS` | la DDHC et les textes (0), le droit européen (0) | le droit européen (0) | les interdits du quotidien (0) |
| `CIV_SOCIETE` | la nationalité (0) | les papiers d'identité (0), les urgences (0), la nationalité (0) | **l'école (0), la santé (0)**, les urgences (0) |
| `CIV_PRINCIPES` | la laïcité (0), l'égalité (0), les libertés (0) | — | — |

**Conséquence directe et inévitable** : avec `questionsMinParNotion = 5` évalué
*par mention*, une part importante du référentiel sera marquée
`contenuInsuffisant` **quelle que soit la taxonomie choisie**. Ce n'est pas un
défaut de découpage — c'est le contenu qui manque. Sur les 46 notions
recommandées, **11 seulement franchissent 5 dans les trois mentions** :

| Thème | Notions ≥ 5 partout | Notions viables dans 1 ou 2 mentions |
|---|---:|---:|
| `CIV_HISTOIRE_GEO` | 3 | 9 |
| `CIV_INSTITUTIONS` | 5 | 3 |
| `CIV_DROITS_DEVOIRS` | 0 | 9 |
| `CIV_SOCIETE` | 2 | 10 |
| `CIV_PRINCIPES` | 0 | 5 |

🛑 **Il faut décider si une notion mono-mention est acceptable.** L'audit dit
oui : « Devenir français » (0/0/10) n'a aucun sens pour un candidat CSP, et
« Les numéros d'urgence » (8/0/0) aucun pour un candidat NAT. Ce ne sont pas des
notions ratées, ce sont des notions **justement ciblées**. Mais cela veut dire
que le moteur doit traiter `contenuInsuffisant` comme *« pas pour cette
mention »* et non comme *« notion mal faite »*.

### 0.2 ⚠️ Entre 13 % et 22 % du corpus est de la reformulation

Mesuré en base par similarité trigramme, à l'intérieur d'un même thème **et**
d'une même mention :

| Seuil de similarité | Questions qui reformulent une autre | Part du corpus |
|---|---:|---:|
| Identiques après normalisation | 19 | 2,3 % |
| ≥ 0,55 (reformulation nette) | 107 | 12,7 % |
| ≥ 0,45 (reformulation large) | 183 | 21,8 % |

Le seuil de 0,45 est celui qui attrape les paires citées par les auditeurs —
`Quel pouvoir détient un juge ?` / `Quel type de pouvoir est exercé par un juge ?`
(0,45), `Combien y a-t-il de départements en France ?` /
`Combien la France compte-t-elle de départements ?` (0,63) — au prix de quelques
faux positifs. **La vérité est entre 107 et 183 questions.**

🛑 **Tous les comptages de ce rapport sont donc des majorants.** Plusieurs
cellules franchissent le seuil de 5 **par la redondance et non par le contenu** :

| Cellule | Questions | Faits réellement distincts |
|---|---:|---:|
| `hg_arts_sciences` / NAT | 6 | **3** (Baker ×2, Chagall ×2, Cézanne ×2) |
| `hg_geographie` / NAT | 5 | **3** |
| `vs_urgences_secours` / CSP | 8 | **5** |
| `inst_collectivites` / NAT | 3 | **2** |
| `dd_libertes_limites` / NAT | 7 | **4** (4 reformulations de « pourquoi limiter une liberté ») |

**Un seuil « 5 sujets distincts » serait plus juste qu'un seuil « 5 questions »** —
mais c'est une décision produit, pas un constat d'audit.

### 0.3 ⚠️ Environ 35 questions sont mal rangées de THÈME

Signalées, **jamais déplacées** : c'est un autre chantier. Les flux ne
s'annulent pas — ils convergent vers deux thèmes.

| Flux | Questions | Exemples |
|---|---:|---|
| `CIV_HISTOIRE_GEO` → `CIV_PRINCIPES` | 8 | drapeau, Marianne, coq, hymne, devise ×2, langue officielle, loi de 1905 |
| `CIV_INSTITUTIONS` → `CIV_DROITS_DEVOIRS` | 8 | présomption d'innocence, droit à l'avocat, « qui doit respecter la loi », impôts |
| `CIV_DROITS_DEVOIRS` → `CIV_INSTITUTIONS` | 7 | « nom de la Constitution » ×2, service public ×2, subsidiarité, souveraineté, impôts locaux |
| `CIV_INSTITUTIONS` → `CIV_SOCIETE` | 3 | police nationale, 17, 112 |
| `CIV_SOCIETE` → `CIV_INSTITUTIONS` | 3 | âge d'électeur, Frontex, INSEE |
| `CIV_INSTITUTIONS` → `CIV_PRINCIPES` | 3 | parité, « démocratie » ×2 |
| divers | ~3 | IVe République (INST → HG), permis (DD → SOC), école laïque (SOC → PRINCIPES) |

🛑 **Effet de bord à traiter dans la même passe.** Si les 8 questions partent de
`CIV_INSTITUTIONS`, `inst_justice` tombe à **CSP 0** et `inst_constitution` à
**CSP 2**. Déplacer sans écrire les questions de remplacement rendrait trois
notions inservables aux candidats CSP.

**Le bénéficiaire net est `CIV_PRINCIPES`**, qui gagne ~12 questions dont 6 en
CSP — sa mention la plus affamée (19 questions).

---

## 1. `CIV_HISTOIRE_GEO` — 215 questions

### Référentiel actuel

| Notion | CSP | CR | NAT | Verdict |
|---|---:|---:|---:|---|
| `hg_revolution` | 5 | 5 | 4 | trop étroite en NAT |
| `hg_dates_republique` | 2 | 4 | 8 | le titre nomme une **forme** de question, pas un objet |
| `hg_loi_1905` | 0 | 1 | 0 | 🛑 **une seule question dans tout le thème** |
| `hg_guerres_resistance` | 8 | 6 | 6 | ✅ la seule saine |
| `hg_conquetes_droits` | 1 | 2 | 11 | NAT-only |
| `hg_europe` | 0 | 0 | 6 | NAT-only, structurel |
| `hg_geographie` | 17 | 11 | 5 | ✅ tient, et **n'est pas** un fourre-tout |
| `hg_patrimoine` | 9 | 4 | 1 | frontière avec géo non écrite |
| `hg_langue_culture` | 3 | 19 | 14 | 🛑 **fourre-tout : son noyau « langue » = 2 questions** |
| `hg_fetes_jours_feries` | 8 | 2 | 0 | ✅ création confirmée, mais CSP-only |

**La preuve du fourre-tout** : `grep -niE "langue|francophon"` ne renvoie que
**deux** lignes sur 215 — « Quelle est la langue officielle de la France ? »
(dont l'explication dit *article 2 de la Constitution*, donc `CIV_PRINCIPES`) et
« Quelle institution promeut la langue française dans le monde ? ». Les 36 autres
questions de la notion sont de la **culture** : écrivains, peintres, chanteuses,
gastronomie, sport. **Le nom de la notion ment sur son contenu.**

### Référentiel recommandé — 12 notions

| Code | Libellé utilisateur | CSP | CR | NAT | Total |
|---|---|---:|---:|---:|---:|
| `hg_revolution` | Les rois de France et la Révolution | 9 | 7 | 5 | 21 ✅ |
| `hg_napoleon_empires` | Napoléon et les empires | **0** | 5 | 5 | 10 |
| `hg_republiques` | Les cinq républiques | **2** | 7 | 8 | 17 |
| `hg_guerres_resistance` | Les guerres du XXᵉ siècle et la décolonisation | 8 | 9 | 9 | 26 ✅ |
| `hg_conquetes_droits` | Les conquêtes sociales et les transformations de la société | **1** | **3** | 12 | 16 |
| `hg_europe` | La construction européenne | **0** | **0** | 6 | 6 |
| `hg_geographie` | Géographie de la France et outre-mer | 17 | 11 | 5 | 33 ✅ |
| `hg_patrimoine` | Monuments et sites emblématiques | 9 | 5 | **1** | 15 |
| `hg_litterature` | Les grands écrivains français | **0** | 12 | 8 | 20 |
| `hg_arts_sciences` | Artistes et savants français | **3** | 6 | 6 | 15 |
| `hg_art_de_vivre` | Gastronomie, sport et art de vivre | 9 | **3** | **2** | 14 |
| `hg_fetes_jours_feries` | Fêtes et jours fériés en France | 8 | **2** | **0** | 10 |

### Mouvements

**Ajouts (5)** — `hg_napoleon_empires` (grappe de 10 questions sans notion
d'accueil : Code civil, 18 brumaire, Waterloo, Trois Glorieuses, Sedan, Second
Empire, Restauration, Alsace-Lorraine) ; `hg_republiques` ; `hg_litterature` ;
`hg_arts_sciences` ; `hg_art_de_vivre`.

**Suppressions (2)** — 🛑 `hg_loi_1905` (1 question, elle-même mal rangée de
thème) ; 🛑 `hg_langue_culture` **dissoute** en trois notions.

**Fusions (2)** — `hg_revolution` + Ancien Régime : séparés ils font 5/5/4 et
3/2/2, fusionnés 9/7/5. `hg_guerres_resistance` + décolonisation : un
`hg_empire_colonial` autonome ferait **0/3/3**, sous le seuil partout.

**Renommages (2)** — `hg_dates_republique` → **« Les cinq républiques »** : le
libellé actuel nomme la *forme* de la question (« une date »), et c'est
précisément ce qui alimentait le litige avec les conquêtes de droits.
`hg_conquetes_droits` → **« Les conquêtes sociales et les transformations de la
société »**, ce qui accueille Mai 68 sous un libellé honnête.

### Les questions qui tranchent les cas litigieux

- **Mai 68** : le corpus n'en contient que **2 questions, dont 0 en CSP**. Une
  notion dédiée serait sous le seuil dans les trois mentions. Le renommage
  ci-dessus règle le problème sans fabriquer une notion famélique.
- **La Ve République** : 2 CSP / 2 CR / 6 NAT, et en réalité **1 seul fait** de
  chaque côté en CSP et CR (`L78 ≈ L142`, `L55 ≈ L60`). Pas de notion dédiée ;
  elle devient le noyau de `hg_republiques`.
- **Frontière droits ⇄ dates**, à écrire dans les deux descriptions avec ce
  couple : `L37` « Quel président a **aboli la peine de mort** ? » → conquêtes ·
  `L201` « Qui a été le **premier président socialiste** ? » → républiques.
  **Même réponse (Mitterrand), notions différentes** — c'est la substance qui
  tranche, pas la forme.
- **Frontière géographie ⇄ patrimoine**, non écrite aujourd'hui : **situer sur
  une carte → géographie ; nommer un site célèbre → patrimoine.** Sans elle,
  `hg_patrimoine` tombe à 4 en CR (Étretat et le Mont-Saint-Michel basculent).

### Couverture

**203 / 215 (94 %)**. 9 mal rangées de thème, **3 orphelines réelles** : l'OIF
(`L129`), le 13 novembre 2015 (`L172`), la COP21 (`L183`). Ces deux dernières
esquissent une notion « La France d'aujourd'hui dans le monde » qui atteindrait
4 en NAT et **0 ailleurs** — laissées orphelines plutôt qu'enfouies dans le
prochain fourre-tout.

---

## 2. `CIV_INSTITUTIONS` — 214 questions

### Référentiel actuel

| Notion | CSP | CR | NAT | Verdict |
|---|---:|---:|---:|---|
| `inst_constitution` | 4 | 13 | 12 | bicéphale ; CSP à 2 après nettoyage |
| `inst_president` | 10 | 7 | 8 | ✅ la seule sans reproche |
| `inst_gouvernement` | 12 | **0** | 3 | 🛑 **zéro question CR** |
| `inst_parlement` | 14 | 13 | 6 | large mais insécable |
| `inst_elections` | 10 | 11 | 9 | ✅ |
| `inst_commune` | 7 | 4 | **0** | 🛑 à fusionner |
| `inst_departement_region` | **0** | 6 | 3 | 🛑 à fusionner |
| `inst_justice` | **2** | 13 | 7 | 🛑 CSP effondré (0 réel) |
| `inst_ue` | 8 | 17 | 7 | ✅ insécable |

🛑 **La découverte la plus inattendue : `inst_gouvernement` n'a aucune question
CR.** La mention la plus fournie du thème (90 questions) ne contient rien sur le
Premier ministre, les ministres, Matignon ou le Conseil des ministres. Le
gouvernement n'y apparaît qu'**en creux**, dans des questions dont le sujet est
ailleurs : l'ordonnance, le 49.3.

### Référentiel recommandé — 8 notions

C'est **moins** que le plafond arithmétique de 11, et c'est le déséquilibre par
mention qui l'impose : toute 9ᵉ notion tombe sous 5 dans au moins une mention.

| Code | Libellé utilisateur | CSP | CR | NAT | Total |
|---|---|---:|---:|---:|---:|
| `inst_constitution` | La Constitution et la séparation des pouvoirs | **4** | 13 | 12 | 29 |
| `inst_president` | Le président de la République | 10 | 7 | 8 | 25 ✅ |
| `inst_gouvernement` | Le gouvernement et l'administration de l'État | 12 | 6 | 5 | 23 ✅ |
| `inst_parlement` | Le Parlement : Assemblée nationale et Sénat | 14 | 13 | 6 | 33 ✅ |
| `inst_elections` | Les élections et le droit de vote | 10 | 11 | 9 | 30 ✅ |
| `inst_collectivites` | Les collectivités territoriales : commune, département, région | 7 | 10 | **3** | 20 |
| `inst_justice` | La justice, les tribunaux et les magistrats | **2** | 13 | 7 | 22 |
| `inst_ue` | L'Union européenne | 8 | 17 | 7 | 32 ✅ |

### Mouvements

**Fusion (1)** — 🛑 `inst_commune` + `inst_departement_region` →
`inst_collectivites`. Ce ne sont pas deux notions qui se recouvrent : ce sont
**deux moitiés d'une seule, chacune morte dans une mention différente.**

| | CSP | CR | NAT |
|---|---:|---:|---:|
| `inst_commune` seule | 7 | 4 | **0** |
| `inst_departement_region` seule | **0** | 6 | 3 |
| **fusionnées** | **7** | **10** | 3 |

Le CSP ne pose *que* des questions communales, le NAT *que* des questions
départementales. Les garder séparées, c'est garantir qu'un candidat CSP ne verra
jamais l'une et qu'un candidat NAT ne verra jamais l'autre. Trois questions
portent d'ailleurs **déjà** sur les collectivités comme un tout et ne rentrent
dans ni l'une ni l'autre (« Quel échelon territorial constitue la base de
l'organisation administrative française ? », « À quel échelon sont rattachés les
collèges ? », « Quel est le principe d'autonomie financière des collectivités ? »).

**Élargissements (2)** — `inst_gouvernement` absorbe l'administration de l'État
(le préfet, le décret et l'ordonnance, le budget, la Cour des comptes) : c'est
la seule façon de lui donner un CR. Réduite au gouvernement stricto sensu, elle
resterait à **CR 0 · NAT 3**. `inst_elections` absorbe l'encadrement de la vie
politique (partis, financement, parité, transparence).

**Scissions : aucune.** Trois ont été testées et chiffrées, toutes échouent :

| Scission testée | CSP | CR | NAT |
|---|---:|---:|---:|
| Parlement → « qui y siège » | 7 | 6 | **4** |
| Parlement → « ce qu'il fait » | 7 | 7 | **2** |
| Élections → « le droit de vote » | **2** | 6 | **4** |
| Constitution → « les trois pouvoirs » | 2 | 12 | **2** |
| Constitution → « le texte et son gardien » | **0** | **1** | 10 |
| UE → « construction et institutions » | **0** | … | … |

⚠️ **La distinction national / local / européen, elle, est bien portée par le
corpus** — et elle est déjà réalisée, mais **transversalement** : les municipales
vivent dans `inst_collectivites`, les européennes dans `inst_ue`. C'est la bonne
réponse : elle nourrit deux notions fragiles au lieu d'en créer une troisième.

### Les trous à combler

| Trou | Manque | Effet |
|---|---|---|
| `inst_justice` en CSP | ~5 questions (« Qui juge en France ? », « Un juge reçoit-il des ordres du gouvernement ? ») | **CSP réel = 0** |
| `inst_constitution` en CSP | ~3 questions (« Qu'est-ce que la Constitution ? », « Depuis quand la Ve République ? ») | **CSP réel = 2** |
| `inst_collectivites` en NAT | ~2 questions (statut de Paris/Lyon/Marseille, métropoles) | 3 questions pour **2 faits** |

**Dix questions à écrire, et le thème est complet.**

### Couverture

**214 / 214**, aucune orpheline — le corpus institutionnel est dense et bien
centré. Mais **26 questions n'y entrent que par tolérance** : 16 relèvent d'un
autre thème (§0.3) et 10 sont rangées faute de mieux (l'argent public et la
Cour des comptes dans `inst_gouvernement`, les symboles européens et la monnaie
dans `inst_ue`).

---

## 3. `CIV_DROITS_DEVOIRS` — 166 questions

### Référentiel actuel

| Notion | CSP | CR | NAT | Total | Verdict |
|---|---:|---:|---:|---:|---|
| `dd_droits_fondamentaux` | ~2 | ~55 | ~35 | **~123** | 🛑 **74 % du thème** |
| `dd_devoirs_citoyen` | 5 | 4 | 3 | 12 | tient en CSP |
| `dd_egalite_loi` | 1 | 2 | 2 | **5** | 🛑 sous le seuil partout |
| `dd_travail` | 4 | 1 | 2 | **7** | 🛑 |
| `dd_protection_sociale` | 1 | 0 | 1 | **2** | 🛑 |
| `dd_ecole_enfance` | 5 | 0 | 1 | 6 | 🛑 |
| `dd_logement` | 0 | 1 | 0 | **1** | 🛑 **une seule question** |
| `dd_liberte_culte` | 0 | 2 | 0 | **2** | 🛑 **deux questions** |

🛑 **Cinq notions sur huit portent 1 à 7 questions.** Le thème fonctionne
aujourd'hui comme **une seule notion plus un décor.**

**La preuve du fourre-tout** — ce que contient une séance
« À travailler : Les droits fondamentaux » : la prescription des délits (6 ans),
le siège de la CEDH (Strasbourg), le PACS, le droit à l'image, le principe de
précaution, la double peine, la hiérarchie des normes, la liberté de conscience.
**Huit sujets sans rapport dans une même série Leitner.**

### Référentiel recommandé — 9 notions

| Code | Libellé utilisateur | CSP | CR | NAT | Total |
|---|---|---:|---:|---:|---:|
| `dd_textes_fondateurs` | La Déclaration de 1789 et les textes qui garantissent nos droits | **0** | 11 | 8 | 19 |
| `dd_protection_europeenne` | Les droits protégés au-delà de la France : CEDH, Union européenne | **0** | **0** | 8 | 8 |
| `dd_libertes_limites` | Les libertés individuelles et leurs limites | **1** | 15 | 7 | 23 |
| `dd_infractions_peines` | L'infraction et la peine : du principe de légalité aux interdits absolus | **1** | 13 | 7 | 21 |
| `dd_interdits_quotidien` | Ce qui est interdit au quotidien, et ce qu'on risque | 10 | **3** | **0** | 13 |
| `dd_police_justice` | Police, justice : mes droits quand la loi s'applique à moi | 12 | 9 | **3** | 24 |
| `dd_devoirs_citoyen` | Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement | 5 | 6 | **4** | 15 |
| `dd_vie_privee_famille` | Vie privée, image, données personnelles et vie de famille | 5 | 10 | **3** | 18 |
| `dd_droits_sociaux` | Travailler, se soigner, être logé, aller à l'école : les droits sociaux | 10 | **3** | **4** | 17 |

🛑 **Aucune notion de ce thème n'atteint 5 dans les trois mentions.** La notion
la plus proche est `dd_devoirs_citoyen` : **il lui manque une seule question
NAT.** C'est le meilleur rapport effort/gain de tout l'audit.

### Mouvements

**Scission majeure** — `dd_droits_fondamentaux` (~123) éclatée en **six**
notions : textes (19), Europe (8), libertés (23), principes pénaux (21),
procédure et forces de l'ordre (24), intime (18).

**La coupe pénale en deux**, et sa justification : réviser « la prescription des
délits est de 6 ans » et « le port de la ceinture est obligatoire » dans la même
séance, ce sont deux apprentissages sans rapport. Et la coupe épouse les
mentions : **le quotidien est CSP (10/3/0), le principe est CR/NAT (1/13/7).**

**Fusion (4 → 1)** — `dd_travail` + `dd_protection_sociale` + `dd_ecole_enfance`
+ `dd_logement` → `dd_droits_sociaux`. Le corpus lui-même les traite comme un
bloc : `L68` « Quels sont les droits sociaux fondamentaux en France ? » énumère
précisément santé, éducation, travail, sécurité matérielle et logement dans une
seule réponse.

**Suppressions (3)** — 🛑 `dd_egalite_loi` (5 questions, sous le seuil partout) ;
🛑 `dd_logement` (**1** question, le DALO) ; 🛑 `dd_liberte_culte` (**2**
questions, toutes deux sur la liberté de *conscience* et toutes deux justifiées
par la laïcité dans leur explication — elles seraient aussi légitimes dans
`pv_laicite`, arbitrage signalé, non rendu).

**Renommage obligatoire** — 🛑 `dd_devoirs_citoyen` s'appelle aujourd'hui
« Les devoirs : lois, impôts, **jury** ». Le corpus ne contient **aucune
question sur le jury d'assises** : il n'apparaît que dans l'explication d'une
autre question. **Le libellé promet un contenu inexistant.**

### La frontière droit ⇄ démarche, à écrire une fois pour toutes

Elle sert des deux côtés (`dd_droits_sociaux` ⇄ `CIV_SOCIETE`) :

> **La question se règle-t-elle devant un juge, ou devant un guichet ?**
> Un juge, une commission de recours, une sanction → **droit**.
> Un formulaire, un dossier, une aide, un rendez-vous → **démarche**.

Exemple : le **droit au logement opposable** et le recours qu'il ouvre → droit ;
monter un dossier HLM, l'APL, l'état des lieux, le préavis → démarche.

### Couverture

**158 / 166 (95 %)**, **0 orpheline**. 8 mal rangées de thème. Mais **quatre
poches restent sous le seuil partout** et ne survivent que rattachées à une
notion plus large — ce sont elles qui désignent les notions **manquantes faute
de contenu** :

| Poche | CSP/CR/NAT | Ce qu'il faudrait |
|---|---|---|
| **Droit des étrangers** (asile, double peine, apatridie) | 0/2/1 | ~12 questions — sujet central pour ce public, quasi absent |
| **Égalité femmes-hommes et violences** | 1/3/2 | ~10 questions — **aucune question CSP** |
| **Environnement** (Charte 2004, précaution, tri) | 1/2/1 | ~10 questions |
| État de droit / hiérarchie des normes | 0/0/2 | — |

⚠️ **Le vrai levier sur ce thème n'est pas le découpage, c'est l'écriture.** Le
CR pèse 72 questions et n'en a que **3** sur travail, santé, école et logement
réunis.

---

## 4. `CIV_SOCIETE` — 166 questions

### Référentiel actuel

| Notion | Ce que le corpus lui donne | Verdict |
|---|---|---|
| `vs_demarches` | papiers (7 CSP) + séjour (14) + nationalité (10 NAT) + résidus | 🛑 **~35 questions, 3 sujets étrangers** |
| `vs_sante` | 2 / 13 / **0** | vraie notion, sous seuil en CSP et NAT |
| `vs_logement_pratique` | 3 / 1 / 0 = **4** | 🛑 sous le seuil dans les trois mentions |
| `vs_emploi` | 2 / 25 / 6 = 33 | 🛑 trop large : contrat / collectif / recherche |
| `vs_transports_securite` | urgences 8 + route 5 + transports **1** | 🛑 deux notions collées |
| `vs_budget_impots` | **2** | 🛑 inexistante |
| `vs_vie_collective` | 5 hétérogènes | 🛑 second fourre-tout, libellé indéfendable |
| `vs_laicite_quotidien` | **1** | 🛑 et c'est un doublon de `CIV_PRINCIPES` |

### Référentiel recommandé — 12 notions

| Code | Libellé utilisateur | CSP | CR | NAT | Total |
|---|---|---:|---:|---:|---:|
| `vs_ecole_scolarite` | L'école et les études | 12 | 11 | **0** | 23 |
| `vs_sante_soins` | Se soigner : médecin, Sécu, remboursements | **2** | 13 | **0** | 15 |
| `vs_travail_contrat_salaire` | Le contrat de travail et le salaire | **2** | 16 | **1** | 19 |
| `vs_travail_entreprise` | Les salariés dans l'entreprise | **0** | **4** | 5 | 9 |
| `vs_emploi_formation` | Chercher un emploi, se former, créer son activité | **0** | 5 | **0** | 5 |
| `vs_protection_sociale_aides` | La protection sociale et les aides | 5 | 6 | 7 | 18 ✅ |
| `vs_famille_etat_civil` | La famille, le couple et l'état civil | 6 | 6 | 10 | 22 ✅ |
| `vs_sejour_asile` | Le séjour des étrangers et l'asile | **1** | 9 | **4** | 14 |
| `vs_nationalite_francaise` | Devenir français | **0** | **0** | 10 | 10 |
| `vs_papiers_identite` | Ses papiers et les guichets de l'administration | 8 | **0** | **0** | 8 |
| `vs_urgences_secours` | Les numéros d'urgence et les secours | 8 | **0** | **0** | 8 |
| `vs_deplacements_route` | Se déplacer : permis, sécurité routière, transports | 5 | **0** | **1** | 6 |

**12 notions là où le plafond annonçait 8** — et c'est justifié : **4 d'entre
elles sont mono-mention par nature du sujet** (papiers, urgences, route en CSP ;
nationalité en NAT). Revenir à 8 supposerait de recoller des sujets étrangers,
c'est-à-dire de **recréer `vs_demarches` et `vs_transports_securite`.**

### Mouvements

**Éclatement de `vs_demarches`** → `vs_papiers_identite` (8) +
`vs_sejour_asile` (14) + `vs_nationalite_francaise` (10), le reste dispersé.
Preuve : un candidat CSP à qui on dit « À travailler : les démarches
administratives » recevrait une série mêlant *validité de la carte d'identité*,
*différence réfugié / protection subsidiaire* et *droit du sang*.

⚠️ **La grille par interlocuteur (mairie / préfecture / CAF / CPAM) a été testée
et ne tient pas** : mairie ≈ 8, CAF ≈ 4, CPAM ≈ 3, OFII ≈ 4, France Travail 2.
Une seule atteindrait 5, et elle découperait en travers de l'école, de la
famille et du logement. Raison de fond : **les énoncés sont écrits en
« Que désigne X ? », pas en « À qui s'adresser pour X ? »** — 4 questions
seulement posent la question du guichet. **Le corpus se découpe par situation de
vie**, et c'est le découpage retenu.

**Éclatement de `vs_emploi` (33)** → contrat et salaire (19) + entreprise (9) +
recherche et formation (5), les cotisations partant vers la protection sociale.
« Que signifie CDI ? », « Que désigne l'AGS ? » et « Qui est aidé par France
Travail ? » ne se révisent pas dans la même séance.

**Scission de `vs_transports_securite`** → urgences (8/0/0) + route (5/0/1).
Rien ne relie « Le 18 est le numéro des pompiers » et « Le permis A1 se passe à
16 ans ». Les garder groupées n'achèterait **aucune couverture** (la notion
fusionnée resterait à 0 en CR et 1 en NAT), seulement de l'incohérence.

**Suppressions (4)** — 🛑 `vs_laicite_quotidien` (**1** question, doublon de
`CIV_PRINCIPES` ; zéro question sur la laïcité au travail, à l'hôpital ou à la
cantine) ; 🛑 `vs_logement_pratique` (4) ; 🛑 `vs_budget_impots` (**2**) ;
🛑 `vs_vie_collective` (5 sans rapport, et « Vivre ensemble et respect des
règles » est indéfendable après « À travailler : »).

**Ajouts (5)** — `vs_ecole_scolarite` (23) et `vs_famille_etat_civil` (22) sont
les deux grosses masses que le référentiel actuel **n'a aucune notion pour
accueillir** : leurs 45 questions n'ont aujourd'hui d'autre destination que
`vs_demarches` ou `vs_vie_collective`.

### Couverture

**157 / 166 (95 %)**. 7 orphelines, 2 mal rangées de thème.

| Orpheline | Mention | Ce qu'elle révèle |
|---|---|---|
| « Qu'est-ce qu'un dossier de surendettement ? » | CR | **budget / banque : 2 questions** dans tout le thème |
| « Que désigne la caution dans la location ? » | CR | **logement locatif : 4 questions** |
| « L'école publique est-elle laïque ? » | CSP | → `pv_laicite` (doublon) |
| « Le tabac est-il interdit aux mineurs ? » | CSP | notion manquante : **les âges de la vie** |
| « Quel âge pour entrer en boîte de nuit ? » | CSP | idem |
| « Que désigne l'INSEE ? » | CSP | → `CIV_INSTITUTIONS` |
| « Quel établissement prête des livres gratuitement ? » | CSP | **services publics de proximité** |

⚠️ **Une 13ᵉ notion existe en creux : « La majorité et les âges de la vie »** —
travail à 14/16, permis à 16/17/18, tabac et boîte de nuit à 18, mariage à 18,
vote à 18, émancipation à 16, retraite à 64. Environ 10 questions. Non retenue
parce qu'elle **volerait ses questions à quatre autres notions** et que le
moteur ne sait pas attribuer une question à deux notions — mais c'est la
meilleure candidate suivante, et elle réglerait deux orphelines.

---

## 5. `CIV_PRINCIPES` — 79 questions

🛑 **Verdict sans appel : aucun découpage ne produit une seule notion servable
dans les trois mentions.**

| Grappe | CSP | CR | NAT | Total |
|---|---:|---:|---:|---:|
| Symboles et devise | **17** | 11 | 4 | 32 |
| La République : régime, démocratie, souveraineté | 1 | **8** | 4 | 13 |
| Laïcité | 0 | **5** | **5** | 10 |
| Égalité et non-discrimination | 0 | **9** | 1 | 10 |
| Libertés fondamentales et DDHC | 0 | **7** | 1 | 8 |
| *(relèvent d'un autre thème)* | 1 | 4 | 1 | 6 |

**La cause n'est pas le découpage** : le CSP n'a que **19 questions, dont 17 sur
les symboles**, et le NAT n'en a que **16**, éparpillées sur cinq sujets. Même
en fusionnant tout en une seule notion, NAT resterait à 16 — soit trois notions
au maximum, et aucune n'atteindrait le seuil en CSP.

### Référentiel recommandé — 5 notions, dont aucune universelle

| Code | Libellé utilisateur | CSP | CR | NAT | Servable en |
|---|---|---:|---:|---:|---|
| `pv_symboles_devise` | Les symboles et la devise de la République | 17 | 11 | **4** | CSP, CR |
| `pv_republique_democratie` | La République : régime, démocratie, souveraineté | **1** | 8 | **4** | CR |
| `pv_laicite` | La laïcité | **0** | 5 | 5 | CR, NAT |
| `pv_egalite_non_discrimination` | Égalité et refus des discriminations | **0** | 9 | **1** | CR |
| `pv_libertes_ddhc` | Les libertés fondamentales et la Déclaration de 1789 | **0** | 7 | **1** | CR |

**Mouvements** : `pv_symboles` + `pv_devise_valeurs` → fusionnées (le corpus ne
les distingue pas : « Que signifie la liberté dans la devise ? » et « Que
représente Marianne ? » sont la même révision). `pv_libertes_fondamentales` +
`pv_ddhc` → fusionnées (8 questions à elles deux). **Ajout** :
`pv_republique_democratie` — une grappe de 13 questions qui n'a aujourd'hui
**aucune notion d'accueil**.

**Zéro orpheline réelle.** Les deux candidates se classent : « loi du 15 mars
2004 » → laïcité, « Que signifie la liberté ? » → devise. **Six questions
relèvent d'un autre thème** (école gratuite et âge de scolarité →
`CIV_DROITS_DEVOIRS`, droit de vote des femmes 1944 → `CIV_HISTOIRE_GEO`, rôle
des associations → `CIV_SOCIETE`).

### 🛑 Ce que le moteur permet déjà, et qui sauve la situation

**La bascule thème → notion se fait par thème** (`grainDuTheme`, seuil de 80 %
de tagging sur les `CONNAISSANCE`). `CIV_PRINCIPES` peut donc **rester au grain
thème** pendant que les quatre autres passent au grain notion. Le moteur le gère
déjà — **sans une ligne de code.**

Le remède au déséquilibre est **éditorial, pas taxonomique** : il faut écrire
des questions CSP et NAT sur ce thème. Et le premier apport viendra gratuitement
du rangement des thèmes : **`CIV_PRINCIPES` récupère ~12 questions mal rangées,
dont 6 en CSP** (§0.3).

---

## 6. Ce qui reste à trancher — 6 décisions qui ne m'appartiennent pas

| # | Décision | Enjeu chiffré |
|---|---|---|
| 1 | **Une notion mono-mention est-elle acceptable ?** | 35 des 46 notions recommandées ne franchissent pas 5 dans les trois mentions. Si non, le référentiel tombe à ~11 notions et redevient un ensemble de fourre-tout. |
| 2 | **Les 176 `MISE_SITUATION` entrent-elles dans le référentiel de notions ?** | `CIV_SOCIETE` passerait de 166 à 213 questions et son plafond de 8 à 10 ; `vs_emploi_formation` (5, pile au seuil) ne devient confortable qu'avec elles. Aujourd'hui la file de tagging les exclut explicitement. |
| 3 | **Le seuil doit-il compter 5 questions ou 5 sujets distincts ?** | 13 à 22 % du corpus est de la reformulation ; au moins 5 cellules franchissent le seuil par la redondance. |
| 4 | **Le préfet : gouvernement ou collectivités ?** | Aux collectivités, `inst_gouvernement` retombe à **CR 2** et il faut fusionner président + gouvernement en un `inst_executif` (7 notions au lieu de 8). |
| 5 | **Les 5 numéros d'urgence et le rôle de la police : `CIV_DROITS_DEVOIRS` ou `CIV_SOCIETE` / `CIV_INSTITUTIONS` ?** | `dd_police_justice` survit dans les deux hypothèses (12/9/3 ou 7/9/3), mais le plafond du thème passe de 9 à 8. |
| 6 | **Où vivent les symboles ?** | Les symboles européens (5 questions) sont dans `inst_ue`, les symboles nationaux dans `CIV_PRINCIPES`. Les traiter pareil ferait perdre 3 CSP à `inst_ue`. Arbitrage transverse. |

### Les notions justes que seul le manque de contenu empêche

Elles sont nommées ici pour ne pas être réinventées plus tard :

- **Mai 68 et les transformations de la société** — 2 questions, 0 en CSP.
- **L'empire colonial et la décolonisation** — 0/3/3.
- **Le droit des étrangers** — 0/2/1, alors que c'est le sujet le plus proche de
  la vie des candidats.
- **L'égalité femmes-hommes et les violences faites aux femmes** — 1/3/2.
- **Les sciences et les inventions françaises** — 2/2/0.
- **La majorité et les âges de la vie** — ~10 questions, mais transversale.
- **Le budget, la banque et les impôts du particulier** — 2 questions.

---

## 7. Ce qu'il faut écrire — par ordre de rentabilité

| Priorité | Ce qu'il faut écrire | Volume | Ce que ça débloque |
|---|---|---:|---|
| 1 | 1 question NAT sur les devoirs (jury d'assises, article 13 DDHC) | **1** | `dd_devoirs_citoyen` devient la **première** notion du thème servable partout |
| 2 | Questions CSP sur la justice (« Qui juge en France ? ») | 5 | `inst_justice` passe de **CSP 0** à servable |
| 3 | Questions CSP sur la Constitution | 3 | `inst_constitution` passe de **CSP 2** à servable |
| 4 | Questions CSP et NAT sur `CIV_PRINCIPES` | ~15 | débloque le grain notion sur le thème le plus affamé |
| 5 | Questions CR sur les droits sociaux | ~10 | le CR pèse 72 questions et n'en a que **3** sur le sujet |
| 6 | Questions NAT sur les collectivités | 2 | `inst_collectivites` passe de 3 (2 faits) à servable |
| 7 | Questions CSP sur Napoléon | 5 | `hg_napoleon_empires` passe de **CSP 0** à servable |
| 8 | Questions NAT sur le travail parlementaire | 4 | rend possible la scission de `inst_parlement` |

---

## 8. Ce que je propose comme suite

1. **Tu valides ou corriges le référentiel recommandé** — notion par notion, ou
   en bloc avec des exceptions.
2. **Tu tranches les 6 décisions du §6** — en particulier la n°1, qui change le
   référentiel du simple au quadruple.
3. **Ensuite seulement** : une migration Flyway qui pose le référentiel validé
   (aucun `civic_notion_id` touché), puis la reprise du pré-tagging sur ce
   référentiel — le prompt et les descriptions seront à réécrire, puisque les
   notions changent.

🛑 **Rien de tout cela n'est fait.** Le pré-tagging reste en pause, les 50
questions du pilote v3 restent en attente de ta relecture, et les 790 restantes
n'ont pas été lancées.
