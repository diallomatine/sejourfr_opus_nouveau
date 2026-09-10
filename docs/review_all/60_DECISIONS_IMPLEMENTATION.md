# Décisions prises pendant l'implémentation, sans arbitrage du propriétaire

> **À quoi sert ce document.** Le propriétaire a demandé que les lots
> s'enchaînent sans l'attendre. Chaque fois qu'un choix ne se déduisait **pas**
> de `50_` (qui fait autorité), de `40_AUDIT`, ni d'un invariant déjà écrit dans
> `CLAUDE.md`, il est consigné ici : **ce qui a été décidé, l'alternative
> écartée, et ce que coûte le retour arrière**. Rien ici n'est définitif : c'est
> une liste de choses à confirmer ou à corriger.
>
> Il ne consigne **pas** les décisions qui découlaient directement d'une spec ou
> d'un invariant du dépôt — celles-là sont dans le code et dans `docs/regles/`.
>
> Ordre : par lot, le plus récent en bas.

---

# Où en sont les lots (au 2026-09-10)

| Lot | État | Ce qui reste |
|---|---|---|
| **L1** socle | ✅ livré | — |
| **L4** diagnostic TCF 4 épreuves | ✅ livré | 1 réserve : sévérité EE/EO dérivée des bandes du correcteur (§5.3 interdit une 7ᵉ famille de prompts) |
| **L5** paywall contextualisé | ✅ livré | — (la date d'examen qui l'alimente est arrivée en L3) |
| **L7** boucle de réévaluation | ✅ livré | T28 (« Progrès ») renvoyé à L11 |
| **L3** diagnostic écrit rapide | ✅ livré | pool de sujets (D-L3-3) si voulu |
| **L8** référentiel de notions | 🟡 **moitié code livrée** | **~1 016 taggings** — décisions humaines, pas des lignes à écrire |
| **L9** diagnostic civique | ⛔ bloqué | dépend du tagging (L8) |
| **L10** Plan civique + Leitner | ⛔ bloqué | dépend du tagging (L8) |
| **L11** examens blancs + Progrès | 🟡 **moitié codable** | « branchés » dépend de L10 ; **T28 est libre et c'est le prochain morceau** |
| **L6** rapport micro + EO1 | 🟡 code livré | ~15 sujets EO1 (D-L6-2) |
| **L12** supervision des coûts IA | ✅ livré | — |

**Ce qui bloque vraiment n'est pas du code.** `50_` §9 le dit, l'audit §9 le
répète : les trois chantiers du chemin critique sont éditoriaux — ~1 016
taggings, ~120 mises en situation, ~15 sujets EO1.

---


---

# L7 — la boucle de réévaluation

## D-L7-1 · L'éligibilité est une **route dédiée**, pas un champ du diagnostic

**Décidé** : `GET /api/tcf-diagnostics/eligibility`, un DTO à part
(`TcfReassessmentEligibilityDto`).

**Alternative écartée** : ajouter `canReassess` / `locked` sur
`TcfDiagnosticDto`. Refusé parce que la question se pose **aussi quand il n'y a
aucun diagnostic** (le `/current` rend alors 204) : le champ aurait été
inatteignable exactement dans le cas où l'écran doit décider quoi afficher.

**Retour arrière** : trivial tant que rien d'autre ne consomme la route.

## D-L7-2 · Une priorité terminée ouvre la porte du **délai**, jamais celle du paiement

`10_` §4.6 dit « 1 tous les 14 jours, **ou** déclenchée par le plan quand une
priorité est terminée », sans préciser si la dérogation vaut aussi pour
l'abonnement.

**Décidé** : elle ne vaut que pour le délai. Un compte gratuit qui termine une
priorité voit toujours le paywall.

**Pourquoi** : l'inverse rendrait la réévaluation gratuite pour quiconque
termine une étape — c'est-à-dire pour la cible même du produit. Ce serait un
changement de modèle économique, pas un détail d'implémentation.

**Si le propriétaire veut l'inverse** : une ligne dans `TcfReassessmentService`
(inverser l'ordre des deux portes). Verrouillé par le test
`lePlanNouvrePasLaPorteCommerciale`.

## D-L7-3 · « Priorité terminée » = **étape franchie du Plan**, lue et non redéfinie

**Décidé** : `LearningPlanPriorityResolver.franchies` (transfert prouvé), avec
une observation postérieure au dernier diagnostic.

**Alternative écartée** : une définition propre à la réévaluation (« la priorité
n°1 a changé », « une compétence est passée SOLID »). Refusé : deux lectures du
même historique se sont déjà contredites en production sur ce dépôt, et le
journal de `franchies` documente l'incident.

**Coût mesuré** : une requête d'historique (index existant) + deux fonctions
pures, à chaque lecture de l'éligibilité. Pas de construction du Plan complet.

## D-L7-4 · L'écran T11 remplace la liste des sections quand le diagnostic est **clos**

Avant L7, un diagnostic terminé affichait quatre cartes « Terminée » et un
bouton « Voir mon résultat ». `30_` §5.6 décrit un écran différent (T11).

**Décidé** : `status == COMPLETED` ⇒ T11, sur web **et** mobile.

**Ce qui n'a pas été touché** : rien du parcours de passation.

## D-L7-5 · Le paywall de réévaluation réutilise `DIAGNOSTIC_REPORT`

**Décidé** : `ctaLocation = DIAGNOSTIC_REPORT`, distingué par
`screen = "diagnostic_tcf_reevaluation"` côté web.

**Alternative écartée** : une valeur d'enum `REASSESSMENT`. Refusé pour ce lot :
elle touche le backend et les trois fronts, et l'analyse du funnel garde le
grain nécessaire par `screen`.

**À trancher** si le propriétaire veut une ligne dédiée dans la table « quel
écran déclenche l'achat ? ».

## D-L7-6 · Le bloc « Progrès TCF » (T28) n'est **pas** dans ce lot

`30_` §7 demande un historique des estimations et une évolution par épreuve sur
l'écran Progrès. Ce lot livre la **comparaison entre deux diagnostics**, sur
l'écran de résultat.

**Décidé** : T28 reste dans **L11** (« Examens blancs branchés + Progrès
unifié », `50_` §8), qui est le lot de cet écran. Livrer une moitié de T28 ici
aurait créé deux endroits qui affichent la même évolution.

## D-L7-7 · Une **baisse** de niveau est servie et affichée

Aucune spec ne dit quoi faire quand une réévaluation mesure moins bien.

**Décidé** : `BAISSE` existe, est servie, et les fronts l'affichent (« Votre
niveau a baissé »), sans dramatiser (pas de rouge, pas d'alerte).

**Pourquoi** : masquer une baisse rendrait invendable exactement ce que la
réévaluation payante promet de mesurer.

**Si le propriétaire préfère un autre ton**, c'est un libellé dans
`lib/tcf-diagnostic.ts` + son miroir Dart, rien d'autre.

## Réserve ouverte

Le champ `daysUntilAvailable` est servi **aussi** quand le Plan a ouvert la
porte en avance (avec `triggeredByPlan = true`), pour que l'écran puisse dire
*pourquoi* le bouton est là. Aucun écran ne l'utilise encore dans ce sens : ils
affichent la phrase du Plan. À supprimer si ça reste inutilisé.


---

# L3 — le diagnostic écrit rapide

## D-L3-1 · La FORME du diagnostic est une **donnée**, pas un drapeau

**Décidé** : un diagnostic a une étape orale **si et seulement si** son couple
(`diagnostic_code`, `diagnostic_version`) porte un sujet `TCF_EO` actif.
`INITIAL_TCF` v1 en a un, `QUICK_TCF` v1 n'en a pas. Aucun booléen de
configuration ne double cette information.

**Alternative écartée** : un `quick-diagnostic.enabled: true`. Refusé parce
qu'un drapeau peut **contredire** le contenu servi : à `true` avec un seed
absent, le candidat se voit réclamer une production dont le sujet n'existe pas.

**Retour arrière** : `DIAGNOSTIC_CODE=INITIAL_TCF`. Aucune migration, aucun
recalcul. Les sessions déjà passées gardent la forme sous laquelle elles ont été
menées — V050 rend l'oral **facultatif**, elle ne le supprime jamais.

## D-L3-2 · Aucune table `quick_diag_subject`

`50_` §5.1 la liste comme « seule table réellement nouvelle du module TCF ».

**Décidé** : ne pas la créer. Le même tableau, deux lignes plus haut, tranche
que `tcf_subject` reste `production_tasks` — « une tâche = un sujet dans le
dépôt. **Ne pas séparer** sans besoin avéré ». Un sujet de diagnostic rapide est
exactement cela : un énoncé, des bornes de mots, et une allowlist de compétences
observables (`diagnostic_task_skills`), c'est-à-dire les `observation_targets`
de la spec sous leur nom du dépôt.

**Ce qu'une seconde table aurait coûté** : un second tirage, un second jeu de
bornes, un second lien aux compétences, et un second chemin de soumission.

## D-L3-3 · **Un seul sujet**, pas un pool

`10_` §3.3 demande « un pool de sujets, tirage aléatoire ».

**Décidé** : un seul énoncé en v1 — le sujet de référence de la spec.

**Pourquoi** : `uq_prod_task_diagnostic UNIQUE (diagnostic_code,
diagnostic_version, epreuve)` (V029) impose une tâche par modalité et par
version, et cette unicité **garantit** que la lecture publique (visiteur sans
compte) et la création de session servent le même énoncé. La relâcher apporte
peu ici : le diagnostic rapide se fait **une fois par compte**, il n'y a donc
pas de « je retombe sur le même sujet », et des énoncés différents rendraient
les niveaux estimés moins comparables entre candidats.

**Le code serveur sait déjà tirer** (`writtenPool`, `drawWrittenTask`,
`writtenTaskOrDraw`, et le paramètre `writtenTaskId` que le client renvoie).
Ouvrir le pool = remplacer cette unicité par un index sur
(code, version, epreuve, id) et seeder les énoncés. **Trois énoncés
supplémentaires sont rédigés** et attendent cette décision :

1. **Votre ville et vos habitudes** — décrivez votre quartier ou votre ville, et
   ce qu'on y trouve ; racontez une sortie ou une rencontre qui s'y est passée
   récemment ; expliquez ce qui manque selon vous à cet endroit, et pourquoi
   cela compte pour vous.
2. **Votre travail ou vos études** — décrivez en quoi consistent vos journées ;
   racontez un moment récent qui s'est bien, ou mal, passé ; expliquez ce que
   vous aimeriez faire dans un an, et pourquoi.
3. **Une personne qui compte pour vous** — décrivez cette personne et ce qui la
   caractérise ; racontez un moment passé avec elle dont vous vous souvenez ;
   expliquez ce qu'elle vous a appris, et ce que vous aimeriez lui dire
   aujourd'hui.

Tous partagent la **même allowlist** de 8 compétences : deux candidats tirant
deux sujets doivent être mesurés sur exactement les mêmes signaux, sans quoi le
niveau dépendrait du tirage.

## D-L3-4 · **Aucune version v2** des rubriques de diagnostic

`50_` §5.3 demande « une nouvelle version de `diagnostic-analysis-rubrics`
(v1 → v2), adaptée à une production unique écrite ».

**Décidé** : garder la v1, inchangée.

**Pourquoi, mesuré sur le fichier** : la v1 est déjà **par production**, pas par
paire. Elle prend `analysis_type=INITIAL_DIAGNOSTIC` et `modality`, et sa seule
section orale (« Oral enregistré ») ne se déclenche que sur `modality=EO`, qui
n'arrivera jamais sur le diagnostic rapide. Le « un seul appel LLM » de `10_`
§3.5 découle de la production unique, sans toucher au prompt.

**Ce qu'un bump aurait coûté** : rendre incomparables les mesures v1 déjà
faites, pour un contenu identique. Le dépôt a une mesure de ce risque
(v10/v11 : un bloc ajouté à une grille fait tomber l'accord exact de 81,8 % à
75,6 %).

## D-L3-5 · Bornes de mots : **recevabilité 100-300**, demande 150-220

`10_` §3.3 donne deux nombres différents : « Longueur demandée : 150 à
220 mots » et « Seuil de recevabilité : 100 mots ».

**Décidé** : `mots_min = 100`, `mots_max = 300` — ces colonnes portent la
recevabilité (ce que le serveur accepte). La demande de 150-220 vit dans la
consigne, que le correcteur lit pour juger si les éléments demandés sont
accomplis.

**Le plafond à 300 est un choix**, la spec n'en donne pas : un diagnostic ne
doit pas renvoyer chez lui quelqu'un qui a écrit **plus**. Le but est de
mesurer, et refuser un texte généreux perd exactement la personne qu'on cherche
à convertir.

## D-L3-6 · Les rate-limits de `10_` §3.7 sont déjà tenus, **par construction**

**Constaté, pas décidé.** La décision Q1 (`50_` §3.1) supprime toute soumission
anonyme : le texte ne touche jamais le serveur sans jeton. « 3 soumissions /
heure / IP » n'a donc plus de surface à protéger, et la seule route publique
(`/api/public/diagnostics/current`, lecture de contenu seedé) a déjà sa limite
(120 / 10 min). « 1 analyse gratuite par compte » est garanti par l'unicité
`(user_id, diagnostic_code, diagnostic_version)`, et « 1 analyse / heure /
compte » par le fait qu'un compte n'a qu'une session, plus le plafond de
3 relances.

**Aucun code ajouté** : un limiteur de plus aurait gardé une porte qui n'existe
plus.

## D-L3-7 · La date d'examen est posée **au moment du compte**, best-effort

`10_` §3.2 place les trois questions **avant** l'exercice. La colonne
`users.exam_date` existe depuis V047 (L1) mais **aucun front ne l'écrivait** —
`passRecommande` et le compte à rebours du paywall (L5) ne pouvaient donc jamais
s'afficher.

**Décidé** : la date est demandée là où le candidat remplit déjà un formulaire —
l'écran de compte du tunnel (web) et l'écran de démarche (mobile) — et non sur
un quatrième écran avant l'exercice.

**Pourquoi** : trois questions avant de rédiger allongent la porte d'entrée que
`10_` §3.1 veut courte ; et la démarche (question 2) était déjà demandée à
l'inscription.

🛑 **Elle ne voyage jamais dans la requête d'inscription** (`50_` §3.1 :
authentification et métier ne se mélangent pas) : appel séparé, après, et
**best-effort** — un échec ne fait pas échouer un compte déjà créé.

## D-L3-8 · L'écran de résultat garde sa structure, et gagne les blocs 3 et 4

`10_` §3.6 impose cinq blocs. L'écran livré (web `DiagnosticReport`, mobile
`DiagnosticResultView`) en a déjà une version **plus riche** — héros global,
« Mes 4 épreuves », prochaine étape, offre — construite pour le diagnostic
précédent.

**Décidé** : ne pas la remplacer, et ajouter les deux blocs réellement absents :
la **transition** (« Ce n'est qu'une première estimation ») et l'appel au
**diagnostic TCF complet**, qui existe depuis L4.

**Le bloc 3 n'est pas négociable** : avec une seule production écrite, annoncer
un palier sans dire de quoi il est tiré laisserait le candidat croire qu'il
connaît son niveau TCF. Il ne le connaît pas.

Les deux ne s'affichent que tant que les 4 épreuves ne sont pas mesurées : une
fois le profil complet, il n'y a plus rien à relativiser ni à proposer.

## Réserves ouvertes

- Un candidat qui avait une session `INITIAL_TCF` **en cours** ne la verra plus
  après la bascule (la lecture se fait par (code, version)). Son diagnostic
  **terminé**, lui, reste en base et continue d'alimenter son profil. L'audit et
  V756 indiquent que très peu de diagnostics ont été menés à terme ; le coût réel
  est donc proche de zéro, mais il n'est pas nul.
- `DiagnosticOralInexploitableIT` et `DiagnosticPostSignupSequenceIT` sont
  désormais **épinglés** sur `INITIAL_TCF` : ils portent sur la paire. Ce qu'ils
  gardent reste vivant (filet de l'oral inexploitable, séquencement de deux
  productions) pour le diagnostic TCF 4 épreuves et les examens blancs.


---

# L12 — la supervision des coûts IA

## D-L12-1 · Le « coût moyen d'un diagnostic » est un **rapport de deux totaux**

`00_` §8.4 demande « le coût moyen d'un diagnostic complet ».

**Décidé** : `SUM(cout_micro_usd)` des sources `DIAGNOSTIC%` sur la fenêtre,
divisé par le nombre de diagnostics **clos** sur la même fenêtre.

**Pourquoi pas une vraie moyenne par session** : `v_ai_usage` ne porte pas
l'identifiant de la soumission — son `usage_id` est celui de la ligne
d'évaluation, de transcription ou d'analyse. Rattacher chaque appel à sa session
demanderait de **réécrire une vue livrée**, et le dépôt versionne au lieu de
réécrire.

**Ce que la différence coûte** : elle ne se voit que sur les diagnostics à cheval
sur les bornes, et elle s'efface dès que la fenêtre dépasse quelques jours. Si
le propriétaire veut la moyenne exacte, c'est un `v_ai_usage` v2 avec une
colonne `submission_id`, l'ancienne vue restant chargeable.

## D-L12-2 · Le coût moyen ne compte **que** les micro-USD

**Décidé** : les lignes anciennes (centimes d'euro) n'entrent pas dans la
moyenne.

**Pourquoi** : mélanger deux unités et deux devises dans une moyenne est
exactement ce que V048 interdit. Mieux vaut une moyenne qui ne porte que sur la
période où le coût est réellement connu qu'une moyenne fausse sur toute
l'histoire.

## D-L12-3 · Pas de croisement gratuit / abonné

`00_` §7.2 proposait une `source` du type `FREE_EE_TRAINING`.

**Constaté, pas décidé** : ces valeurs sont **incalculables a posteriori** —
savoir si un appel a été payé par un quota gratuit exige l'état de l'abonnement
*à l'instant de l'appel*, que rien ne persiste. V048 l'avait déjà tranché ; cet
écran s'y tient et n'affiche que ce que les lignes portent réellement.

Le croisement reste possible, par une jointure datée sur `user_subscriptions` —
c'est un travail à part, et il vaut mieux le faire explicitement que de remplir
une colonne de valeurs devinées.

## D-L12-4 · Le « pack 3 mois » de `00_` §14 n'est pas dans ce lot

`00_` §14 rangeait L12 comme « Pack 3 mois, optimisation paywall, tableau de
bord coûts IA ». `50_` §8 **remplace** ce plan et ne retient que « supervision
des coûts IA ».

**Décidé** : suivre `50_`, qui fait autorité. Un nouveau pass est une décision
de grille tarifaire (Stripe + Apple + Google), pas une tâche d'implémentation —
`docs/bascule-prix-integral.md` documente ce que coûte l'ouverture d'une durée.


---

# L6 — le rapport de micro-sujet et le contenu EO1

## D-L6-1 · Seul le bloc 6 manquait

L'audit (§9) résume L6 par « déjà livré ; reste : aligner le rapport de
micro-sujet sur les 6 blocs de `10_` §8.2 ; contenu EO1 ».

**Mesuré sur l'écran** : les blocs 1 à 5 existent déjà, et sous une forme plus
riche que la spec — carte de niveau (bloc 1), leviers (blocs 2-3), exemple cible
avant/après (bloc 4), mémo « à retenir » (bloc 5). Le routage par
`schema_version` demandé par §8.3 existe aussi : `levelProgress` présent ⇒
contrat v3, absent ⇒ restitution historique conservée telle quelle.

**Ce qui manquait vraiment** : le **bloc 6**, « Prochaine action », et la spec
est catégorique — « JAMAIS un simple « Retour » ». L'écran offrait deux boutons
neutres, identiques quel que soit le verdict.

**Décidé** : trois sorties, une par verdict **servi**. Critère non atteint ⇒ on
rejoue le même point (enchaîner un sujet de plus sur une compétence non acquise
n'empile que des échecs). Partiel ⇒ sujet suivant. Validé ⇒ retour au plan.

Sans analyse (production rendue sans analyse demandée, ou analyse en cours), on
retombe sur les deux actions neutres : proposer « Essayez encore une fois » sans
savoir ce qui a été mesuré serait un jugement inventé.

## D-L6-2 · Les sujets EO1 ne sont **pas** produits sans arbitrage

Blocage B12 de l'audit : EO1 n'a **qu'un sujet par niveau** (3 au total, contre
20 pour EO2). Un candidat qui refait EO1 retombe sur le même sujet.

**Décidé** : ne pas les écrire cette nuit. Ce n'est pas un manque de temps —
c'est le même raisonnement que **D3** (les ~120 mises en situation civiques),
que le propriétaire a lui-même gardé comme une décision d'auteur : du contenu
seedé est difficile à retirer une fois en base, et un sujet EO1 mal calibré
fausse une mesure de niveau.

**Ce qu'il faut décider** : viser ~18 sujets EO1 (6 par palier A2/B1/B2), ou
accepter la répétition. L'audit le classe explicitement « non bloquant ».

**Ce que ça coûte à écrire** : chaque sujet EO1 est un énoncé court (se
présenter, poser des questions utiles à un interlocuteur), plus son rattachement
aux compétences `EO1-C*` existantes. Aucune migration de schéma, aucun code :
uniquement un seed sur `production_tasks` + `diagnostic_task_skills`, sur le
modèle de V755.


---

# L8 — le référentiel de notions civiques

## D-L8-1 · La moitié **code** est livrée, la moitié **contenu** ne l'est pas

L'audit (§9) le dit lui-même : « **Chantier éditorial, pas de code.** La partie
code (tables + écran de tagging) est **M** ; la partie contenu est le vrai
coût. » Et `50_` §9 : « Le code n'est pas le chemin critique. »

**Livré** : le référentiel de travail seedé (40 notions, 5 thèmes), le tag
validé sur `questions`, la table de suggestions, la file de tagging paginée,
l'écran d'administration, et la couverture mesurée par notion × mention qui
alimente la porte de revue §6.1.3.

**Non livré, et volontairement** : les ~1 016 taggings eux-mêmes. Ce sont des
validations humaines ; les produire sans le propriétaire reviendrait à décider
seul du programme civique, et `50_` §6.1.3 l'interdit explicitement — « le job
propose, un humain valide ».

## D-L8-2 · Deux tables, parce qu'il y a **deux autorités**

**Décidé** : `questions.civic_notion_id` porte le tag **validé** (une notion,
posée par un humain, c'est lui qui fait foi partout) ;
`question_notion_suggestions` porte ce qu'une machine **propose** (plusieurs par
question, avec confiance).

**Pourquoi pas une seule colonne avec un drapeau `validated`** : parce qu'une
suggestion non validée se serait mise à compter comme couverture au premier
`GROUP BY` distrait, et le plan civique se serait construit sur ce qu'un modèle
a cru voir.

## D-L8-3 · La table de suggestions est créée **vide**, et rien ne la remplit

**Décidé** : aucun job de suggestion n'est écrit.

**Pourquoi** : le remplir, c'est 1 016 appels LLM payants. La règle du dépôt est
sans ambiguïté — « aucun test ni aucune mesure qui appelle un LLM payant sans
demande explicite ; on **propose** la mesure et son coût, il décide ».

**Ce qu'il resterait à faire, le jour où c'est décidé** : un job qui lit les
questions non taguées, demande à un modèle 1 à 3 notions avec confiance parmi
les 40, et écrit dans `question_notion_suggestions`. L'écran les affiche déjà.
Aucune migration, aucun changement de contrat.

## D-L8-4 · Aucune fusion préventive

`50_` §6.1.1 signale quatre couples « à surveiller » : `dd_logement` /
`vs_logement_pratique`, `pv_laicite` / `vs_laicite_quotidien`, `inst_commune` /
`inst_departement_region`, `hg_patrimoine` / `hg_langue_culture`.

**Décidé** : les seeder **séparés**. Les fusionner d'avance déciderait à la
place des pièces, alors que la spec veut trancher « sur pièces », après le
tagging.

**Le mécanisme de fusion existe** : `merged_into_id` + désactivation. Une notion
fusionnée n'est jamais supprimée — les questions déjà taguées gardent leur lien
et la décision reste lisible en base. Le service refuse de poser une notion
fusionnée, en nommant celle qui la reprend.

## D-L8-5 · La règle de volume n'est **pas** en base

`50_` §6.1 remplace « 6 questions par notion et par mention » par une règle qui
**dégrade** (≥ 5 ⇒ éligible comme priorité ; 1 à 4 ⇒ visible en révision
seulement ; 0 ⇒ invisible ; < 12 toutes mentions ⇒ candidate à la fusion).

**Décidé** : aucune contrainte SQL, aucun seuil appliqué côté serveur. Les
comptes sont servis, l'appelant tranche pour **sa** mention.

**Pourquoi** : une contrainte figerait un seuil que le tagging doit précisément
pouvoir faire bouger, et un verdict global effacerait la nuance par mention qui
est tout l'intérêt de la nouvelle règle. L'écran d'administration colore les
lignes selon ces seuils — c'est un confort de lecture, pas une décision.

---

# Ce qui reste, et pourquoi ça ne se code pas cette nuit

**L9** (diagnostic civique + mises en situation) et **L10** (Plan civique +
Leitner) dépendent tous deux du **tagging**, qui est le chantier de D-L8-1. Un
plan civique par notions sur un catalogue non tagué n'aurait rien à proposer ;
un diagnostic civique tirerait au hasard dans des notions vides.

**L11** a deux moitiés. « Examens blancs branchés » dépend des boîtes de Leitner
(L10), qui n'existent pas. « Progrès unifié » (T28, `30_` §7) est indépendant et
codable : le socle existe (profil TCF par épreuve, comparaison de diagnostics
livrée en L7, moteur de progression V4.2). C'est le prochain morceau à prendre.

**Les trois chantiers de contenu** de `50_` §9 restent entiers, et le document
les nomme lui-même comme le chemin critique : ~1 016 taggings, ~120 mises en
situation, ~15 sujets EO1.


---

# Alignement sur les maquettes `grok_ecran` (2026-09-10)

Le propriétaire a fourni cinq écrans de référence — diagnostic rapide,
diagnostic complet, paywall, plan premium, plan gratuit — et a rappelé le
parcours voulu :

> un seul diagnostic à faire (le **rapide**) → son rapport → on propose le
> **diagnostic complet** (toutes les épreuves, comme un examen blanc) → et c'est
> **dans le rapport du complet** qu'on met en avant le paywall, puis le plan.

## D-M-1 · Le rapport du diagnostic RAPIDE cesse de ressembler à celui du complet

**Constaté** : l'écran affichait « Mes 4 épreuves » avec leurs niveaux, les
priorités et le bloc d'offre — après **une seule production écrite**. Trois
épreuves sur quatre s'affichaient en « — », juste sous une carte qui venait de
dire « ce n'est qu'une première estimation ».

**Décidé**, tant que le profil n'est pas complet :

- le hero dit « **Niveau estimé sur cet exercice** » — wording imposé par
  `10_` §3.1, « jamais votre niveau TCF » ;
- le bloc **« Ce que nous avons observé »** apparaît : exactement trois lignes,
  une positive et deux à améliorer ;
- les **4 épreuves** et le bloc d'**offre** n'apparaissent plus. Ils reviennent
  dès que les quatre épreuves sont mesurées.

🛑 **Le paywall ne se joue plus sur le rapport rapide.** Pousser l'abonnement
après une seule production écrite vend un plan bâti sur presque rien. Il se joue
sur le rapport du **complet**, où le candidat a ses quatre niveaux et ses
priorités réelles sous les yeux — c'est exactement ce que le propriétaire a
demandé.

## D-M-2 · Les trois observations se **choisissent** dans du servi, elles ne se jugent pas

La ligne positive est une observation que le serveur a marquée `SOLID` sur la
production écrite ; les deux « à améliorer » sont les priorités que le serveur a
**classées**. Le front filtre et met en mots — il ne classe pas.

🛑 **Aucune ligne n'est fabriquée pour remplir le bloc** : pas d'observation
solide ⇒ pas de ligne positive ; aucune priorité ⇒ pas de bloc.

## D-M-3 · Le rapport du COMPLET gagne les mentions et l'aperçu du plan

- chaque épreuve porte sa **mention** : « Objectif atteint » / « À renforcer » /
  « Prioritaire ». 🛑 Elle se lit sur des **faits servis** — `dejaAuNiveau` et le
  rang 1 des priorités — jamais sur une comparaison de paliers faite au front.
  Absente sur une épreuve non mesurée : « Non évaluée » + « À renforcer » serait
  un verdict que personne n'a rendu ;
- un bloc **« Votre plan B2 est prêt »** : les trois priorités en forme courte
  (« EO · Tâche 3 ») avec leur pastille, et le compte réel de compétences
  ciblées.

**Nouveau champ serveur** : `TcfDiagnosticResultDto.tachesSousLaCible`.
🛑 **Non plafonné**, contrairement aux priorités bornées à trois : le lire sur
la liste tronquée afficherait « 3 » quel que soit le nombre réel. Une tâche
**non mesurée** n'y entre pas — elle n'est pas « sous la cible », elle est
inconnue.

## D-M-4 · Le paywall parle du plan **quand il le connaît**, et pas autrement

La maquette montre quatre bénéfices qui parlent du plan (« Comprenez pourquoi
vous restez B1 », « Un plan qui s'adapte »), là où la feuille servait une liste
générique sur le catalogue de questions.

**Décidé** : deux jeux. Contextualisé ⇒ les bénéfices du plan et le CTA
« Commencer mon plan B2 ». Ouvert depuis un cadenas quelconque (examen blanc,
correction IA) ⇒ la liste générique et « Voir les abonnements ».

**Pourquoi pas un seul jeu** : servir les bénéfices du plan à quelqu'un qui n'a
pas encore de plan promettrait un contenu qui n'existe pas. C'est la même règle
que L5 — « un paywall qui ment est pire qu'un paywall générique ».

Le deuxième bénéfice nomme le palier **réellement mesuré** ; sans lui, on garde
la formulation générale plutôt qu'un palier inventé.

## Reste à faire sur les écrans

- **Plan premium / plan gratuit** : les deux écrans existent déjà et sont plus
  riches que les maquettes (séance du jour, jalons, cycle de palier, changements
  récents). Ils n'ont **pas** été repris cette passe — il faut les comparer
  ligne à ligne aux maquettes 04 et 05, et c'est un travail à part entière.
- **T28 « Progrès »** : toujours pas commencé (cf. §L11).
- 🛑 **Aucun de ces écrans n'a été ouvert.** `tsc`, `build` et `analyze` passent,
  les tests aussi — mais rien ne remplace un œil sur le rendu.


---

# L9 + l'architecture des deux parcours (arbitrage du 2026-09-10)

Le propriétaire a tranché la structure d'ensemble :

> **TCF** : diagnostic rapide → diagnostic complet → Plan
> **Civique** : diagnostic → Plan
> **Accueil** : agrège l'état des deux
> **Plan / Réviser / Examens / Progrès** : toggle TCF | Examen civique
> « Mais il n'y a qu'un seul état backend. Les trois écrans ne créent pas trois
> parcours différents. »

## Correction : L9 n'était **pas** bloqué par le tagging

**J'avais écrit** que L9 et L10 étaient bloqués sur le tagging des 1 016
questions. **C'est faux, et la spec le disait déjà** :

- `20_` §3.4, mode dégradé : « Thème sous le seuil de tagging → **Plan et
  diagnostic au niveau thème** pour ce thème uniquement » ;
- `20_` §4.5, bloc 4 : « (au niveau thème si le tagging n'est pas suffisant) ».

Le repli par thème n'est pas un contournement : c'est le mode dégradé **conçu**.
Le tagging rend le plan plus fin, il ne le conditionne pas. Attendre le chantier
éditorial aurait privé le candidat de ce qui était déjà mesurable — les 5
thèmes, les 1 016 questions et les 176 mises en situation existent depuis le
début.

## D-L9-1 · **Un seul** diagnostic civique, et c'est une asymétrie assumée

**Décidé** (arbitrage) : pas de rapide + complet côté civique.

**Pourquoi** : le civique est du QCM **déterministe**, rapide et sans coût LLM.
Un pré-diagnostic n'apporterait rien et dupliquerait le tunnel du TCF. Le TCF a
deux diagnostics parce qu'ils servent deux objectifs différents — le rapide crée
la confiance et donne une estimation, le complet mesure réellement CO/CE/EE/EO.

Conséquence dans le code : `PreparationEtape.ESTIMATION_FAITE` n'existe **que**
côté TCF.

## D-L9-2 · UN SEUL ÉTAT BACKEND, trois portes

**Décidé** : `GET /api/me/preparation` sert l'état des deux modules, et
l'Accueil, le Plan et les Examens le lisent tous les trois.

**Pourquoi c'est structurel** : trois écrans qui déduiraient chacun leur version
proposeraient trois choses différentes au même candidat. C'est le défaut le plus
cher du dépôt (« une règle = une autorité »), appliqué à la navigation.

🛑 **Le serveur expose l'ÉTAPE, pas la phrase.** « Faire mon diagnostic
complet » et « Votre plan TCF n'est pas encore prêt » vivent dans
`lib/preparation.ts` et son miroir Dart.

## D-L9-3 · Le diagnostic civique n'est PAS un examen blanc, et la base le dit

`attempts.civic_diagnostic_id`, exactement comme V049 l'a fait pour le TCF.
Sans lui, un diagnostic occuperait un slot de la grille d'examens blancs et
compterait dans « examens blancs passés ». Les 6 requêtes de comptage portent
désormais **les deux** filtres.

## D-L9-4 · Ce que la composition garantit, et ce qu'elle ne garantit pas

**Garanti** : un minimum de 3 questions de connaissance par thème (`20_` §4.2 :
« ne jamais évaluer un thème sur une seule question »), et 7 mises en situation
tirées **à part** pour pouvoir les compter séparément.

**Pas encore garanti** : « aucune notion évaluée plus de 2 fois » et « réparties
sur des notions différentes » — ces deux contraintes **exigent** le tagging.
Elles arriveront avec lui, sans changer le contrat.

🛑 **Le mode dégradé ne fait jamais échouer le diagnostic** : un catalogue
sous-doté sur une mention donne un diagnostic plus court, et les thèmes non
servis ressortent « non évalué ». Refuser d'ouvrir priverait le candidat de tout,
y compris de ce qui était mesurable.

## D-L9-5 · Le plan civique v1 est **par thème**, et il le dit à l'écran

L'onglet civique du Plan affiche les thèmes à travailler, dans l'ordre servi par
le diagnostic, chacun ouvrant l'entraînement correspondant — plus une phrase qui
annonce que le plan deviendra « notion par notion » quand le référentiel sera
complété.

**Ce n'est pas L10.** La répétition espacée (Leitner) et le plan par notion
restent entiers. Mais un plan par thème est utilisable **aujourd'hui**, et c'est
le repli que la spec a conçu.

## Reste à faire

- **Miroir mobile** du diagnostic civique, de « Ma préparation » et du toggle ;
- **toggle sur Réviser, Examens et Progrès** (la 3ᵉ porte : les Examens) ;
- **L10** : Leitner + plan par notion, qui eux demandent vraiment le tagging ;
- **T28 « Progrès »**, toujours pas commencé.


---

# Le diagnostic civique passe à 40 questions (2026-09-10)

**Arbitré** : « passe à 40 questions, comme l'examen, et comme ça à la fin on a
quelque chose de cohérent. »

`20_` §4.2 proposait 17 + 7 = 24. Le compte est aligné sur l'épreuve réelle :
**28 connaissances + 12 mises en situation = 40**, le ratio des mises en
situation restant celui de l'examen (12/40), que la spec citait déjà comme
référence.

## Ce que ça change, et pourquoi c'est mieux

Avec 24 questions, il fallait **projeter** : « soit environ 30 / 40 à l'examen ».
Une projection se discute — le candidat peut se demander sur quoi elle repose.
Avec 40, **le score EST le résultat** : 30 / 40, seuil 32, rien à convertir.

Conséquence dans le code : `formatQuestions` (40) est désormais **servi** à côté
de `seuilReussite` (32), et l'écran choisit sa phrase.

- `posees == formatQuestions` ⇒ on annonce le seuil, sans « soit environ » ;
- catalogue sous-doté sur une mention ⇒ on **projette**, et on le dit.

🛑 **La projection n'est pas supprimée pour autant** : le mode dégradé de
`20_` §3.4 reste possible, et un report doit alors se présenter comme un report.

## Le plancher par thème monte de 3 à 4

28 questions de connaissance sur 5 thèmes en autorisent 4 chacun (20) et
laissent 8 au complément. Un plancher qui ne bouge pas quand le total grandit
rend le minimum de moins en moins significatif.

## Ce qui distingue encore le diagnostic de l'examen blanc

Le format est le même, la nature ne l'est pas — et `20_` §4.1 l'oppose sur trois
axes, dont **deux tiennent toujours** :

| | Diagnostic | Examen blanc |
|---|---|---|
| Format | 40 questions | 40 questions |
| **Couverture** | **équilibrée** sur les 5 thèmes, plancher par thème | **représentative** de l'examen |
| **Effet** | **crée** le plan | **met à jour** le plan |

C'est la couverture qui compte : un examen blanc représentatif peut ne poser que
deux questions sur un thème, ce qui ne permet pas d'en juger l'état. Le
diagnostic garantit un plancher, précisément pour que chaque thème reçoive un
état exploitable.

🛑 **Le diagnostic reste NON CHRONOMÉTRÉ**, et c'est une décision : un
diagnostic doit mesurer ce que quelqu'un sait, pas à quelle vitesse. Ajouter les
45 minutes de l'épreuve en ferait un examen blanc déguisé, ce que §4.1 interdit.
**À confirmer** si le propriétaire préfère l'inverse — c'est une ligne de
configuration.

---

# Le mobile de L9 (2026-09-10)

Livré en parité avec le web :

- modèles et repository du diagnostic civique, `PreparationDto` et ses libellés
  (miroirs mot pour mot de `lib/preparation.ts` et `lib/civic-diagnostic.ts`) ;
- écrans du diagnostic civique et de son résultat, routes enregistrées ;
- carte **« Ma préparation »** en tête de l'Accueil ;
- **toggle TCF | Examen civique** sur le Plan, avec la raison exacte pour
  laquelle chaque module n'est pas encore prêt.

## D-M-5 · ~~L'onglet civique du Plan mobile ne simule pas un plan~~ — **RÉVOQUÉ**

**Ce que j'avais décidé** : sur mobile, l'onglet civique renvoyait au résultat du
diagnostic au lieu d'afficher les thèmes prioritaires, au motif qu'« une liste
sans action n'est pas un plan ».

**Révoqué le 2026-09-10 par le propriétaire** : « quand il fait le diagnostic
civique, il peut **déjà voir son plan civique** ».

**Mon erreur** : j'ai traité l'absence de Leitner comme si elle rendait le plan
par thème illégitime. Elle ne le rend pas illégitime — `20_` §3.4 le **conçoit**.
Et la « liste sans action » n'en était pas une : chaque thème ouvre son
entraînement (`/civique/theme/:id`), exactement comme sur le web. J'ai construit
un obstacle qui n'existait pas.

**Corrigé** : les deux fronts servent le même plan civique par thème, avec la
même phrase qui annonce qu'il deviendra « notion par notion » avec le
référentiel.

## Reste à faire

- **toggle sur Réviser, Examens et Progrès** — la 3ᵉ porte (les Examens) n'est
  toujours pas branchée ;
- **L10** : Leitner + plan par notion, qui demandent le tagging ;
- **T28 « Progrès »**.


---

# Le toggle du Plan (2026-09-10)

**Correction de deux affirmations fausses de ma part.**

## Le toggle existait déjà ailleurs

J'ai écrit trois fois que le toggle « TCF | Examen civique » restait à faire sur
Réviser, Examens et Progrès. **C'est faux** : `ModuleSwitch` existe côté mobile
(`selectedModuleProvider`), Réviser le porte, et Progrès affiche les deux
modules **côte à côte** — une variante, pas une absence. Rien à faire de ce côté.

## Le toggle du Plan ne doit jamais attendre

**Décidé** : sur `/plan`, les deux onglets se rendent **au premier rendu**,
avant même que l'état de préparation soit connu.

**Pourquoi c'est une vraie correction** : mon implémentation ne rendait rien tant
que `/api/me/preparation` n'avait pas répondu. Sur un compte neuf — les deux
diagnostics à faire — la page restait donc sans **aucune** porte vers le
civique, exactement le cas que le propriétaire vise : « même si aucun diagnostic
n'est fait des 2 côtés ». Un toggle est une **navigation**, pas un résultat : il
n'a pas à attendre une mesure.

Deux gardes qui vont avec :

- **un clic l'emporte sur le défaut** : l'onglet ne se déplace jamais sous les
  doigts du candidat quand la réponse serveur arrive ;
- **l'échec de l'appel ne masque rien** : les deux onglets restent là, et le plan
  TCF reste atteignable — il existait avant cet onglet.

## Un appel réseau en moins

`CivicPlanPanel` relisait l'état de préparation pour retrouver l'identifiant de
session. Il le reçoit désormais de l'onglet, qui l'a déjà : deux appels pour la
même vérité, c'est celle qu'on regarde le moins qui finit par mentir.


---

# Le bug qui rendait mes écrans nus (2026-09-10)

> « je ne vois toujours pas de toggle dans /plan »

**Le toggle était bien là. Il n'avait simplement aucun style.**

## Ce qui s'est passé

`<style jsx>` (styled-jsx) scope ses règles aux éléments rendus par **le même
composant** : il ajoute une classe de scope aux éléments du JSX voisin et
réécrit `.plm-tabs` en `.plm-tabs.jsx-1a2b`.

Quand la balise vit dans un `Styles()` séparé qui **ne rend que le
`<style>`**, aucun élément ne reçoit cette classe. Les règles sont bien
injectées dans la page, et elles ne matchent **rien**.

Résultat : deux `<button>` aux styles par défaut du navigateur, côte à côte,
sans bordure, sans fond, sans padding. Ça ne se lit pas comme un toggle — ça ne
se lit pas du tout.

## Sept écrans étaient concernés

Pas seulement le toggle : `CivicDiagnosticHub`, `CivicDiagnosticResult`,
`TcfDiagnosticHub`, `TcfDiagnosticResult`, `CivicPlanPanel`, `PlanModules`,
`PreparationCard`. Soit **tout ce que j'ai écrit dans cette session, plus
l'écran de L4**. Le motif s'est propagé par copie.

## La correction

`<style>` **sans** l'attribut `jsx` — du CSS global, ce que **tout le reste du
dépôt** utilise déjà (`app/(app)/layout.tsx`, `PaywallSheet`, `/profil`…).
Vérifié : aucun autre composant n'utilisait `<style jsx>`.

Deux précautions qui vont avec :

- toutes les classes sont **préfixées** (`.plm-`, `.cvd-`, `.cvr-`, `.cvp-`,
  `.prep-`, `.tcfd-`, `.tcfr-`) ;
- les sélecteurs d'**élément** (`li[data-tone="hot"]`) sont désormais **scopés
  sous leur conteneur** — en global, ils auraient teinté n'importe quel `li`
  du site portant le même attribut.

Un commentaire est posé sur chaque `Styles()` pour que personne ne « corrige »
en remettant l'attribut.

## Ce que ça dit de ma vérification

`tsc`, `npm run build` et les tests passaient à chaque fois — et ils passaient
pour de bonnes raisons : le code était valide, le markup était rendu, le CSS
était syntaxiquement correct. **Aucun de ces outils ne vérifie qu'une règle
s'applique à quelque chose.**

C'est exactement la limite que j'ai signalée à chaque livraison — « je n'ai
ouvert aucun écran » — et c'est la première fois qu'elle coûte quelque chose de
visible. Le prochain écran écrit avec un `Styles()` doit être ouvert avant
d'être annoncé.


---

# Le toggle du Plan est celui des Examens (2026-09-10)

> « remets le même toggle qui se trouve dans /examens-blancs, avec 2 couleurs
> différentes. »

**J'avais écrit un troisième toggle** — des pastilles bleues, sans icône, sans
la distinction de couleur — alors que le produit en avait déjà un, et le bon.

## Ce que j'ai fait, et pourquoi pas une copie

`50_` §10 et `CLAUDE.md` disent la même chose : « duplication = signal, à la 2ᵉ
occurrence on extrait ». Le toggle était **inline dans `/examens-blancs`** côté
web ; il en fallait un identique sur `/plan`. Le copier aurait garanti qu'ils
divergent.

- **Web** : extrait dans `app/_components/ModuleToggle.tsx`, avec ses styles.
  `/examens-blancs` l'importe désormais au lieu de le définir, et ses règles CSS
  locales ont été **supprimées** — deux définitions du même contrôle, c'est
  celle qu'on regarde le moins qui finit par mentir.
- **Mobile** : rien à extraire, `SegmentedTabs` + `parcoursSegments` existaient
  déjà et portaient déjà les deux couleurs. Mes onglets maison sont supprimés.

## Les deux couleurs ne sont pas décoratives

🛑 Rouge = TCF, bleu = civique — **partout** dans le produit : les icônes de
module des examens blancs, les cartes de Progrès, les pastilles de thème. Un
candidat reconnaît son parcours à la couleur avant de lire le mot. Un toggle
monochrome cassait ce repère au moment précis où il sert le plus.


---

# Trois défauts trouvés à l'usage sur le diagnostic civique (2026-09-10)

> « Je viens de faire un diagnostic examen civique, à la fin je suis sur
> `/sessions/…`, un peu éloigné d'une page de diagnostic. Et puis je reviens
> dans `/plan`, on me demande toujours de faire un diagnostic. »

Un seul parcours réel a mis au jour trois défauts que ni `tsc`, ni le build, ni
2 828 tests n'ont vus. Le deuxième et le troisième **découlaient** du premier.

## 1. Le runner ne savait pas qu'il portait un diagnostic

L4 avait résolu exactement ce problème pour le TCF avec `TCF_DIAGNOSTIC_PARAM` :
une section de diagnostic ramène au diagnostic, jamais au bilan de série. **Je
ne l'ai pas fait pour le civique** — j'ai poussé le runner sans marqueur.

**Corrigé** : `CIVIC_DIAGNOSTIC_PARAM`, mêmes trois points de sortie que le TCF
(reprise d'un attempt déjà fini, bouton « quitter », fin de série).

🛑 **Une différence assumée** : le TCF ramène au **hub** (il a quatre sections,
il faut montrer les trois autres) ; le civique mène **droit au résultat** — il
n'en a qu'une, et le renvoyer à un accueil qui redemanderait « Voir mon
résultat » ajouterait une étape à un parcours terminé.

## 2. La session n'était jamais close

Le résultat n'était atteignable que par le hub, et seul `POST /result` clôt la
session. Le candidat ne revenant jamais au hub, la session restait
`IN_PROGRESS` — **pour toujours**.

**Deux corrections, à deux niveaux** :

- l'écran de résultat appelle `result()` (POST, idempotent) et non
  `readResult()` : ouvrir son résultat clôt son diagnostic ;
- 🛑 **et surtout, une clôture PARESSEUSE côté serveur** : si l'attempt est
  terminé mais la session ouverte, elle se clôt **à la première lecture**. Sans
  ça, un candidat qui répond à ses 40 questions puis ferme l'app garderait un
  diagnostic « en cours » indéfiniment. C'est le même patron que la clôture
  paresseuse de l'examen complet : **l'état vrai est celui de l'attempt**, la
  session le rattrape.

Cette seconde correction répare aussi les sessions **déjà bloquées** : aucune
migration, elles se réparent à la première ouverture.

## 3. Le Plan disait « Faire » à quelqu'un qui avait commencé

`planIndisponible` rendait la même carte quel que soit l'état du module.

🛑 **Un diagnostic commencé ne se « fait » pas, il se REPREND.** Redemander
« Faire mon diagnostic » à quelqu'un qui vient d'en répondre la moitié lui fait
croire que son travail est perdu. La carte porte désormais l'avancement réel
(« Vous avez répondu à 14 questions sur 40. ») — servi, jamais fabriqué.

## Ce que ça confirme

Les trois défauts sont **invisibles à la compilation** : le code était valide, le
markup rendu, les tests verts. Le premier parcours réel les a tous les trois
sortis en une minute.

C'est la deuxième fois dans cette session (après le CSS non appliqué). La leçon
est la même et elle est maintenant écrite : **un écran neuf doit être parcouru
de bout en bout avant d'être annoncé fini.**


---

# Les deux diagnostics sur `/reussir` (2026-09-10)

**Demandé** : deux grosses cartes, TCF IRN et Examen civique, pour que le
visiteur choisisse son diagnostic et le fasse.

## D-R-1 · On fait choisir un EXAMEN, pas une profondeur de diagnostic

La section `#diagnostic` proposait « Diagnostic rapide » et « Diagnostic
complet » — deux **parcours TCF**, décrits dans les termes d'avant L3 (« EE +
EO », « puis CO + CE »).

**Décidé** : les deux cartes portent désormais les deux **examens**.

**Pourquoi c'est mieux, et pas seulement demandé** : un visiteur sait quel examen
il passe ; il ne sait pas ce qu'est un « diagnostic complet ». La profondeur du
parcours TCF (rapide puis complet) se découvre **ensuite**, une fois entré — et
c'est exactement l'ordre de l'architecture arbitrée.

## D-R-2 · ~~Le CTA civique passe par l'inscription~~ — **RÉVOQUÉ le 2026-09-10**

> ⚠️ **Cette décision est fausse et a été annulée le jour même.** Elle est
> conservée en entier parce que son *motif* était une erreur d'analyse, pas une
> préférence : le corriger vaut d'être écrit. Ce qui fait foi désormais :
> « Le diagnostic civique se passe AVANT le compte (V053) », plus bas.

~~🛑 **Le diagnostic civique ne peut pas commencer sans compte**, contrairement
au TCF. Le civique est un QCM rattaché à un `attempt`, donc à un utilisateur ; le
TCF rapide, lui, se rédige sur l'appareil et ne demande le compte qu'au moment
de l'analyse (`50_` §3.1).~~

~~**Décidé** : le CTA civique envoie `/inscription?next=/diagnostic-civique` pour
un visiteur, et directement au diagnostic pour un compte connecté.~~

**Pourquoi c'était faux** : « un attempt est rattaché à un utilisateur » est
inexact dans ce dépôt depuis longtemps — la **démo invitée** joue des attempts
`user_id IS NULL` + `client_ip` depuis 2026-05. La contrainte que j'ai
invoquée n'existait pas ; je l'ai déduite du modèle sans vérifier le code qui la
contredisait à trois fichiers de là (`AttemptService.startGuestDemo`).

La carte TCF portait seule le badge **« Sans compte »**. Les deux le portent
maintenant : la différence était un défaut, pas un avantage à mettre en scène.

## D-R-3 · Deux formulations que L3 avait rendues fausses

En relisant la page, deux promesses ne tenaient plus depuis que le diagnostic
rapide n'a **qu'une production écrite** :

- le hero annonçait « **1 écrit + 1 oral** » — un enregistrement qui n'arrive
  jamais ;
- la FAQ décrivait « un exercice d'expression écrite, **puis un oral
  enregistré** ».

Corrigées. Ce n'était pas demandé, mais une landing qui promet une étape
inexistante coûte plus cher qu'un écran mal cadré : le candidat le découvre
**après** être entré.

`DIAGNOSTIC_COMPREHENSION_LABEL` n'avait plus d'appelant après la refonte de la
section : supprimée plutôt que laissée en place — une constante orpheline
laisse croire qu'un écran l'affiche.


---

# Le diagnostic se passe AVANT le compte — des DEUX côtés (2026-09-10)

**Demandé, verbatim** : *« et en plus que ce soit le diagnostic examen civique ou
tcf, l'utilisateur doit pouvoir passer le diagnostic avant de créer son compte,
il saisit le texte ou répond au qcm et seulement après on lui demande de créer
son compte pour voir le resultat. »*

Le TCF le faisait déjà (`50_` §3.1). Le civique, non — et **D-R-2 prétendait que
c'était impossible**. Ça ne l'était pas.

## D-G-1 · Le civique PERSISTE sa session invitée, le TCF garde tout sur l'appareil

C'est la décision de fond de ce lot, et les deux mécaniques diffèrent
**volontairement**.

| | TCF invité | Civique invité |
|---|---|---|
| Ce qui est produit | un texte (et un audio) | 40 réponses à un QCM |
| Où ça vit avant le compte | **l'appareil** (IndexedDB / `SharedPreferences`) | **le serveur** (attempt invité) |
| Ce que l'appareil garde | la production entière | **deux UUID** : la session et son attempt |

**Pourquoi le civique ne peut pas faire comme le TCF**, et c'est le vrai
argument — deux invariants du dépôt l'interdisent :

1. corriger du QCM côté client obligerait à **servir les bonnes réponses à un
   visiteur** ;
2. jouer 40 questions hors `attempts` obligerait à écrire un **second runner** —
   explicitement interdit (« un second runner divergerait du premier à la
   première évolution »).

**Décidé** : on réutilise la mécanique d'attempt invité **qui existe déjà** pour
la démo (`user_id IS NULL` + `client_ip`), et `civic_diagnostic_sessions.user_id`
devient nullable, avec un `client_ip` en regard (V053).

**Ce que ça coûte si on revient dessus** : une migration (rendre `user_id`
`NOT NULL` à nouveau) et la suppression de deux routes publiques. Les sessions
invitées non adoptées devraient être purgées d'abord — rien ne les purge
aujourd'hui, et c'est un **manque assumé** : elles sont inertes (invisibles de
tout écran connecté, exclues des grilles par `civic_diagnostic_id`), mais elles
s'accumulent. À traiter le jour où le volume le justifie.

## D-G-2 · La session existe dès le premier tirage, pas à l'adoption

On aurait pu ne créer que l'attempt et fabriquer la session au moment de
l'inscription.

**Décidé** : la session existe **avant** le compte.

**Pourquoi** : c'est elle qui porte `attempts.civic_diagnostic_id`. Sans elle,
les 40 questions d'un visiteur seraient un **examen blanc** aux yeux de toutes
les grilles — dès la première question, et pendant tout le temps qu'il met à
répondre. Les six requêtes de `AttemptRepository` qui filtrent
`AND a.civicDiagnostic IS NULL` n'ont pas de seconde chance.

## D-G-3 · La démarche est demandée AVANT le tirage

Le tirage dépend de la mention (CSP / CR / NAT) : un CSP ne doit pas être mesuré
sur des questions de naturalisation. Un visiteur n'a pas encore déclaré la
sienne.

**Décidé** : l'écran d'entrée du diagnostic civique demande la démarche — trois
boutons —, la passe au tirage, et **préremplit** ensuite le formulaire de compte.

**L'alternative rejetée** : tirer sur CSP par défaut sans rien demander. Le
périmètre le plus étroit est le bon repli quand on ne sait pas (le serveur le
garde pour une `procedure` absente), mais un candidat **naturalisation** mesuré
sur le programme d'une carte de séjour repart avec un diagnostic **flatteur** et
un plan **incomplet** — sur le segment qui a le plus à travailler. Une question
valait mieux.

## D-G-4 · L'adoption ne rejoue rien, et applique le quota du compte

`POST /api/civic-diagnostics/{id}/adopt` pose le porteur sur la session, sur son
attempt et sur les lignes `answers` restées sans compte. **Aucune question n'est
retirée, aucune réponse n'est rejouée** : un second tirage rendrait au candidat
un résultat qui n'est pas celui qu'il vient de passer.

**Le quota s'applique** (`20_` §4.3, « le premier est offert ») : un compte qui a
déjà son diagnostic gratuit voit l'adoption refusée.

**Ce que ça coûte, et je l'assume** : ce candidat-là **perd** les 40 réponses
qu'il vient de donner. Le cas est rare (il faut *se connecter* à un compte qui a
déjà son diagnostic, au lieu de s'inscrire) et il a déjà un résultat à lire. Les
fronts retombent silencieusement sur le diagnostic du compte plutôt que
d'afficher une erreur. **L'alternative — adopter quand même — casserait le
freemium** : il suffirait de se déconnecter pour se refaire un diagnostic gratuit
autant de fois qu'on veut.

## D-G-5 · Une session adoptée n'est plus lisible publiquement

`GET /api/public/civic-diagnostics/{id}` rend **404** dès que la session a un
porteur, même depuis la même IP.

**Pourquoi ce n'est pas de la prudence excessive** : deux personnes derrière le
même NAT (une box, un cybercafé, un foyer) partagent une IP. Sans cette porte,
la seconde lirait l'avancement du diagnostic de la première rien qu'en ayant son
identifiant.

## D-G-6 · Le mobile gagne un mode invité sur le runner

Le runner mobile n'appelait que les routes authentifiées : un visiteur recevait
un 401 sur sa première réponse.

**Décidé** : `AttemptsRepository.getById/submitAnswer/finish` prennent un
`guest`, qui bascule le préfixe sur `/api/public/attempts` et pose
`skipAuth`/`skipRefresh`. `RunnerController` le dérive d'une seule règle —
**pas de compte ⇒ session de visiteur** — parce qu'une session atteinte sans être
authentifié ne peut être que publique. Les favoris sont sautés (l'API publique
n'expose pas `/api/me/*`).

**Aucun second runner n'a été écrit**, et `/runner/:id` rejoint l'allowlist des
pages publiques du router, à côté de `/diagnostic`.

## D-G-7 · Ce qui a été corrigé au passage

- Le badge **« Sans compte »** est sur les **deux** cartes, sur `/reussir` comme
  sur `/diagnostic` : il décrivait une asymétrie qui n'existe plus.
- L'eyebrow du runner disait « Examen blanc · Démo » au-dessus des 40 questions
  d'un diagnostic civique invité. Il dit « Diagnostic · Examen civique ».
- Les commentaires « 24 questions contre 40 » (backend et fronts) dataient
  d'avant le passage à 40 : la comparaison était devenue fausse.

## D-G-8 · Le `DiagnosticVariant` mobile est supprimé

Le mobile posait encore le choix « rapide / complet » que le web avait déjà
abandonné.

**Décidé** : `diagnostic_variant.dart` est supprimé, l'écran d'entrée fait
choisir un **examen**, et l'événement d'audience porte `rapid` — miroir du
`currentDiagnosticType` posé une fois côté web. Le sous-titre d'en-tête de la
présentation disparaît : un budget au-dessus du titre ne vaudrait que pour une
des deux cartes, et chaque carte annonce le sien.
