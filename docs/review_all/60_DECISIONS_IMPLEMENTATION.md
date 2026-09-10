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
