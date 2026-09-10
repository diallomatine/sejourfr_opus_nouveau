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
