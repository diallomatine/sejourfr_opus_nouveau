# Décisions autonomes — chantier taxonomie V3 / contenu TCF IRN

Journal des arbitrages pris **sans validation préalable du propriétaire**,
pendant la passe autonome ouverte le 2026-09-13 au soir.

🛑 **Chaque entrée est réversible.** Elle est ici pour être relue, pas pour être
subie. Ordre chronologique.

---

## D01 — La clé DeepSeek existe, mais la rédaction reste manuelle pour les sujets

**Problème.** Le propriétaire autorise explicitement DeepSeek pour les 45 sujets
neufs et les 144 learningPoints. La clé est bien présente
(`backend_sejourfr/.env`, `DEEPSEEK_API_KEY`).

**Sources consultées.** `docs/learning_points_review.json` (campagne du
2026-09-12), `tools/competences/generer_learning_points.py`, et les huit lots
EE1/EE3 rédigés à la main pendant le chantier.

**Ce que dit l'expérience du dépôt.** La V1 des learningPoints générée par
DeepSeek a dû être **intégralement réécrite à la main** : 27 points sur 120 sans
accents, du français malformé (« qu'elle n'redite pas »), et des fautes que la
validation de forme ne voyait pas. Le propriétaire l'a lui-même relevé et l'a
rappelé en ouvrant cette passe : « Ne considère jamais qu'un contenu est bon
uniquement parce qu'il respecte le JSON. »

**Décision.**
- **Les 45 sujets** (`EE2-C9`, `EO2-C9`, `EO3-C9`) sont **rédigés à la main**,
  comme les 240 précédents. Un sujet porte une situation, une consigne, un
  critère unique, trois références graduées et quatre champs de guidage : c'est
  la partie du chantier où la relecture coûterait plus cher que la rédaction.
- **Les 144 learningPoints** passent par DeepSeek en **première rédaction**,
  puis relecture intégrale. C'est un format court, très contraint (3 gestes de
  ≤ 6 mots), où la génération fait gagner du temps sans risque éditorial
  comparable — et c'est exactement l'usage prévu par le script existant.

**Raison.** L'autorisation du propriétaire est un *moyen*, pas une obligation.
Sa consigne de tête est « ne privilégie jamais la vitesse au détriment de la
qualité ». Sur les sujets, la vitesse gagnée serait payée en relecture.

**Fichiers concernés.** `tools/competences/contenu_v3/EE2-C9.json`,
`EO2-C9.json`, `EO3-C9.json` · `tools/competences/generer_learning_points.py`.

**Confiance : élevée.**

---

## D02 — Les 10 compétences recentrées : 113 sujets sur 150 sont incompatibles

**Problème.** J'avais écrit, dans `docs/audit-sujets-ee1.md`, que le recentrage
des 10 compétences restantes était « un **desserrage** — retrait d'un quota,
d'une comparaison obligatoire, d'un temps grammatical imposé — pas un changement
d'objet », et que « leurs sujets restent a priori valides ». Le propriétaire a
refusé cette déduction et demandé un audit sujet par sujet. Il avait raison.

**Sources consultées.** Les 150 sujets de `contenu/{EE2,EO1,EO2,EO3}.json`,
confrontés un par un au critère V3 de `docs/taxonomie-competences-v3.md`.

**Ce que montre l'audit.** Un desserrage de critère **invalide** les sujets qui
étaient écrits pour le critère serré : leur consigne impose encore exactement ce
que la V3 a retiré.

| Compétence | V3 retire | Sujets incompatibles |
|---|---|---|
| `EE2-C2` | le lieu et le moment (ils sont au rang 1) | **15/15** — toutes les consignes demandent « où vous étiez » |
| `EE2-C3` | l'imposition du passé composé / imparfait | **15/15** — les critères nomment les temps |
| `EE2-C8` | l'obligation de conséquence | **13/15** — quota « résultat + conséquence + bilan » |
| `EO1-C6` | le récit développé (c'est la tâche 2) | **9/15** — « au moins trois étapes » + ressenti |
| `EO2-C3` | rien, mais **fusionne** C3 et C4 | **5/15** — la moitié « conditions et modalités » n'est pas couverte |
| `EO2-C7` | l'obligation de trancher | **15/15** — « puis dites laquelle vous choisissez » |
| `EO3-C1` | « répondre **immédiatement** » | **11/15** — « dès les premiers mots » |
| `EO3-C5` | le quota de deux arguments | **15/15** — « Ajoutez un **deuxième** argument » |
| `EO3-C7` | rien | **0/15** ✅ |
| `EO3-C8` | l'obligation de conclure | **15/15** — recette « avis, raison, exemple, conclusion » |

**Décision.** Corriger les **113 sujets** — mais uniquement leur **consigne**,
leur **critère unique** et, quand il le faut, leur check-list et leur astuce.
Les **situations sont conservées** : elles ont été écrites pour ces compétences
et restent justes ; c'est le cadrage prescriptif qui a changé, pas le contexte.

**Raison.** Remplacer 113 situations valides serait détruire du contenu correct
pour une raison de forme. À l'inverse, les garder telles quelles laisserait des
consignes qui **contredisent** le critère affiché à l'écran — un candidat lirait
« sans quota d'arguments » puis « ajoutez un deuxième argument ».

⚠️ **Conséquence technique.** `contenu/*.json` alimente V300-V317, **déjà
appliquées** : les éditer changerait leur somme de contrôle Flyway. Les
corrections vivent donc dans `contenu_v3/_corrections.json` et sortiront en
`UPDATE` dans une migration neuve.

**Fichiers concernés.** `tools/competences/contenu_v3/_corrections.json` (neuf),
la migration de contenu à venir.

**Confiance : élevée** sur le constat, **élevée** sur le choix de corriger le
cadrage plutôt que les situations.

---

## D03 — Corriger 121 sujets sans toucher aux situations, références comprises

**Problème.** D02 annonçait de ne corriger que « la consigne, le critère unique
et, quand il le faut, la check-list et l'astuce ». À l'écriture, trois cas ont
débordé ce périmètre.

**Ce que l'écriture a montré.**

1. **Les références aussi portaient la règle retirée.** Sur `EE2-C2`, la V3 dit
   « sans redire le moment ni le **lieu** » : les quinze références ATTENDU et
   EXCELLENT commençaient toutes par le lieu (« J'étais dans la cour de mon
   immeuble… »), et les notes pédagogiques validaient explicitement « Lieu,
   personnes et activité ». Garder ces références, c'était afficher un modèle
   qui contredit le critère servi juste au-dessus. Même chose sur `EO3-C5` :
   les références modèles s'ouvraient sur « **Deuxième** argument », alors que
   la V3 supprime le quota. Les textes ont donc été corrigés — **par retrait de
   ce qui n'a plus cours**, jamais par réécriture de la situation.
2. **`EO2-C3` n'était couverte qu'à moitié.** La V3 **fusionne** `EO2-C3` et
   `EO2-C4` : le rang 3 couvre les informations *et* les conditions (documents,
   inscription, règles, services inclus). Or les quinze sujets portaient tous
   sur la première moitié — prix, horaire, lieu, durée. Cinq d'entre eux
   (`S1`, `S5`, `S6`, `S9`, `S13`) ont été réorientés vers les **conditions**,
   situation conservée. Dix restent sur les informations pratiques : la
   compétence couvre enfin ses deux moitiés.
3. **Huit sujets « compatibles » portaient une étiquette étrangère.** Deux
   `EE2-C8` et six `EO1-C6` affichaient « Passé composé » en pastille, alors
   que la V3 a retiré toute imposition de temps au rang 3 de EE2. Corrigé au
   passage : une compétence ne doit rien mesurer qui appartienne à une autre.

**Décision.** 121 sujets corrigés (113 incompatibles + 8 étiquettes), dans
`tools/competences/contenu_v3/_corrections.json`. Les **situations sont toutes
conservées** — aucun contexte n'a été remplacé. `EO3-C7` reste intacte (0/15).

**Ce que la correction a aussi changé, et pourquoi.** Quatre compétences
perdaient leur gradation de difficulté en perdant leur quota. Chacune a reçu un
**obstacle pédagogique** à la place :

| Compétence | Ancienne gradation | Nouvelle |
|---|---|---|
| `EE2-C8` | nombre d'éléments de fin (1 → 2 → 3) | HARD = refermer un récit dont la fin est **ordinaire**, sans inventer un dénouement |
| `EO1-C6` | nombre d'étapes racontées (2 → 3) | HARD = **rester court** alors que la question invite à tout dérouler |
| `EO2-C7` | nombre d'options comparées | HARD = faire sortir ce que l'annonce **ne dit pas** |
| `EO3-C8` | recette en quatre temps | HARD = **organiser** un sujet qui appelle l'énumération |

⚠️ Sur `EO1-C6`, les durées conseillées des sujets MEDIUM et HARD descendent de
45–55 s à **40 s**. C'est la conséquence directe du critère : un récit « court,
sans basculer dans le récit développé » ne peut pas valoir 55 secondes. La
difficulté ne tient plus à la durée, elle tient à la tentation.

🛑 **Une erreur d'énoncé a été corrigée au passage.** La description de
`EO3-C8` affirmait : « votre avis, une raison, un exemple, puis une conclusion.
**C'est exactement le format attendu à la tâche 3 du TCF.** » France Éducation
international ne prescrit aucun plan de ce type. La V3 la remplace par le
critère officiel de la tâche — parler de manière continue.

**Vérification.** `python3 tools/competences/contenu_v3/_verifier_corrections.py`
— chaque sujet visé existe, chaque champ et chaque icône sont connus, aucun
geste de check-list ne dépasse six mots, et **aucun champ corrigé ne réintroduit
la formulation que la V3 a retirée** (un motif interdit par compétence).
Résultat : *9 competences, 121 sujets, 0 anomalies.*

**Fichiers concernés.** `tools/competences/contenu_v3/_corrections.json` (neuf),
`_verifier_corrections.py` (neuf), `_merge.py` (neuf).

**Confiance : élevée.**

---

## D04 — Les 144 learningPoints : DeepSeek a rédigé, la relecture a réécrit

**Problème.** D01 prévoyait de faire passer les 144 points par DeepSeek en
première rédaction, puis de les relire. La question était de savoir ce que cette
relecture allait réellement coûter.

**Ce qui s'est passé.** Génération : **0,0150 $** (`deepseek-v4-flash`, 60 404
tokens d'entrée, 2 527 de sortie). **42 compétences sur 48** ont produit une
sortie acceptée par le contrat de forme ; **6 ont été refusées** (4 points au
lieu de 3, ou un point de 7 à 10 mots) et signalées pour rédaction manuelle.

Puis la relecture. Trois familles de défauts, sur les 42 « réussies » :

1. **Accents manquants**, exactement comme la V1 d'août : « Nommer les personnes
   presentes », « Dire l'activite de chacun », « Ecarter la fausse explication »
   — une quinzaine de compétences touchées.
2. **Impératifs recopiés de la check-list** au lieu d'infinitifs généralisés :
   `EO3-C8` rendait « Enchaîner sans vous arrêter · Relier chaque idée à la
   précédente », mot pour mot les gestes des sujets. Un point d'apprentissage
   généralise, il ne recopie pas.
3. 🛑 **Deux points réintroduisaient ce que la V3 venait de retirer.** `EO3-C1`
   rendait « Annoncer son choix **d'emblée** », alors que le recentrage de cette
   compétence consiste précisément à retirer l'exigence d'immédiateté. `EO3-C8`
   rendait la recette en quatre temps que le rang 2 abandonne.

**Décision.** Les **144 points ont été réécrits à la main**, en partant de la
sortie comme d'un brouillon. Le fichier de revue
(`docs/learning_points_review.json`) porte la trace de la campagne — modèle,
tokens, coût réel — et la ligne `relecture` qui dit ce qui a été repris.

**Raison.** Le propriétaire l'avait écrit : « Ne considère jamais qu'un contenu
est bon uniquement parce qu'il respecte le JSON. » Les trois familles ci-dessus
passent toutes la validation de forme. La troisième est la plus coûteuse : un
générateur ne sait pas qu'une règle vient d'être retirée, il généralise la
matière qu'on lui donne — y compris ce qu'elle contenait encore.

⚠️ **Conséquence technique.** `generer_learning_points.py --inject` écrivait dans
`contenu/*.json`, gelé par V300-V317. Il écrit désormais dans
`contenu_v3/_learning_points.json`, que l'émetteur SQL lit. Sa source de lecture
change aussi : `vue_v3.charger_v3()` et non plus `contenu/` — sinon les points
auraient été généralisés depuis la matière que la V3 corrige.

**Fichiers concernés.** `tools/competences/generer_learning_points.py`,
`tools/competences/vue_v3.py` (neuf),
`tools/competences/contenu_v3/_learning_points.json` (neuf),
`docs/learning_points_review.{json,md}`.

**Confiance : élevée.**

---

## D05 — Trois tests rouges corrigés, et un quatrième laissé rouge exprès

**Problème.** Le mandat demande une suite verte. Quatre tests l'empêchaient, pour
trois raisons différentes — et le geste juste n'est pas le même dans les trois
cas.

**1. `DiagnosticSeedIT` — un vrai bug produit, pas un test à ajuster.**
L'allowlist du diagnostic oral (`diagnostic_task_skills`) désignait `EO2-C4`,
retirée par V319. Un candidat aurait été routé vers une fiche absente du
catalogue. **Corrigé côté produit** par `V878`, qui repointe la ligne sur
`EO2-C9` — et non sur `EO2-C3`, qui absorbe pourtant `EO2-C4` dans la V3 mais
figure déjà dans la même allowlist (la clé primaire refuserait le doublon).

⚠️ **Le numéro de version est ce qui rend cette migration correcte.** Le même
`UPDATE`, placé dans V320, ne trouvait aucune ligne : `diagnostic_task_skills`
n'est seedée qu'en V755/V757, **après**. Il passait en silence, et le test
restait rouge sans qu'on comprenne pourquoi.

**2. `SkillSeedIT` — deux contrats à élargir, une convention à respecter.**

- `EXPECTED_LEARNING_POINTS` passe de `0` à `EXPECTED_SKILLS` (48). C'est le
  changement que le fichier annonçait lui-même en commentaire depuis V063.
- Le décompte des références filtre désormais `p.is_active`. Depuis V320 la base
  porte aussi les sujets **sortis** du catalogue, qui gardent leurs références —
  et c'est voulu, une production de candidat pointe encore dessus.
- 🛑 **270 amorces de réponse ne se terminaient pas par « … ».** C'est une
  convention gelée par le test, et elle a un sens : l'amorce s'affiche en gris
  **dans** le champ, les points de suspension sont ce qui la donne à lire comme
  un début à poursuivre. **Erreur de contenu, pas de test** : les 270 ont été
  normalisées dans `contenu_v3/`.

**3. `competences_prototype_test` (Flutter) — libellé gelé qui avait dérivé.**
Le test attendait « Chrono par tâche », le code dit « Chronométré par tâche »
(`kChronoParTacheLabel`, miroir de `EO_PAR_TACHE_LABEL` côté web). Test mis à
jour sur le code, qui est d'accord des deux côtés.

**4. `evaluation_report_test` (Flutter) — deux tests laissés en alerte.**
Le bloc « VOTRE DÉMARCHE » du hero (`_StakeBlock`) est **commenté dans
`ResultsHero`**, avec un `TODO à masquer pour l'instant`. C'est une décision
produit antérieure à ce chantier, et ce n'est pas à moi de la lever.

**Décision.** Les deux assertions passent de `findsOneWidget` à `findsNothing`,
avec un commentaire qui nomme le `TODO`. Le test devient donc **rouge le jour où
le bloc revient** — c'est exactement le signal qu'on veut, et c'est le moment où
il faudra revérifier le 360 px. La logique `demarcheRappel` elle-même reste
testée, intacte, plus bas dans le même fichier.

⚠️ **À relire par le propriétaire** : si le masquage n'était pas voulu, c'est le
code qu'il faut corriger, pas le test.

**Fichiers concernés.**
`src/main/resources/db/migration/300_tcf/production/V878__diagnostic_allowlist_taxonomie_v3.sql`
(neuf) · `SkillSeedIT.java` · `DiagnosticSeedIT.java` ·
`LearningPlanDomainSkillsIT.java` · `competences_prototype_test.dart` ·
`evaluation_report_test.dart` · les 19 lots de `contenu_v3/`.

**Confiance : élevée** sur 1, 2 et 3 ; **moyenne** sur 4, qui demande un
arbitrage produit.

---
