# Analyse de `SPEC_EVALUATION_IA_TCF_IRN.md`

> **Quoi ?** Revue critique de la spec d'évaluation IA (écrite hors du projet, sans accès
> au code) confrontée à **ce qui tourne réellement** aujourd'hui : rubriques, service
> d'évaluation, calcul du niveau, seeds de sujets, persona de l'examinateur vocal.
>
> **Pour qui ?** Tout le monde. Langage simple, pas de jargon non expliqué.
>
> **Statut :** document de décision. Rien n'est implémenté. À lire avant d'arbitrer.
>
> **Date :** 2026-08-03 · **Version 2** — intègre une **revue contradictoire** (l'auteur de
> la spec a relu cette analyse et a émis 5 objections). Les arbitrages sont tracés en §6 ;
> les sections concernées ont été corrigées en conséquence.

---

## Résumé en une phrase

La spec **se trompe sur l'état actuel** (elle « corrige » des choses déjà faites) et
**propose plusieurs mauvaises solutions coûteuses** (double évaluation systématique, échelle
0-4 en interne, grilles en base, campagne de calibration à 480 copies). Mais elle **voit juste
sur le fond** : il faut arrêter de noter avec 4 critères universels, dire clairement si la
tâche a été accomplie, assumer notre incertitude — et **admettre que notre note orale est
incomplète** puisqu'elle ignore la voix.

**Recommandation : on ne fait pas la spec.** On fait un banc de mesure (phase 0) + les gains
à coût faible (phase 1), on mesure, et on décide de la suite avec des chiffres.

---

## 1. Ce que la spec croit corriger… mais qui est déjà fait

C'est le point le plus important à comprendre : la spec a été écrite **sans voir le code**.
Elle « corrige » donc des problèmes qui n'existent pas chez nous.

| Ce que la spec dit corriger | Réalité chez nous | Vérifié dans |
|---|---|---|
| « Supprimer les longueurs 60-120, 120-150, 150-180 mots » | Corrigé par V723 : EE1 = 30-60, EE2/EE3 = 60-90 | seeds `300_tcf/production/ee/**` |
| « Durées EO à corriger » | Déjà bon : EO1 = 180 s, EO2 et EO3 = 210 s | seeds `300_tcf/production/eo/**` |
| « Ne pas plafonner le niveau au niveau visé de la tâche » | Déjà écrit noir sur blanc : le niveau peut être au-dessus **ou** en dessous de la cible | `production-rubrics-v3.json`, section « Deux dimensions distinctes » |
| « Ne pas sanctionner l'accent » | Déjà fait — **mais par défaut, pas par choix** : on n'évalue rien de la voix parce qu'on ne l'a pas (cf. §4.5). C'est une **limite**, pas un avantage. | `production-rubrics-v3.json`, section orale |
| « Ne pas compter les fautes mécaniquement » | Déjà dans le prompt | idem |
| « Ne pas afficher une note officielle TCF » | Déjà notre position produit | `docs/notation-ia-eo-ee.md` |

➡️ **Environ 30 % de la spec ne sert à rien.** Ça ne veut pas dire que le reste est mauvais —
au contraire.

> ⚠️ Point à vérifier quand même : la spec affirme « depuis le 12 mai 2025, le TCF IRN évalue
> jusqu'au niveau B2 » et donne les durées EO (3 min / 3 min 30 / 3 min 30). Nos seeds
> **concordent** avec ces durées, et notre bilan est déjà plafonné à B2 — donc pas d'alerte.
> Mais les deux sources pourraient se tromper ensemble : une vérification directe auprès de
> France Éducation international coûte 10 minutes et lève le doute.

---

## 2. Ce que la spec voit juste, et qui nous manque vraiment

Quatre manques réels. C'est la partie utile du document.

### A. On ne dit jamais **si la tâche a été accomplie**

**Aujourd'hui.** Un candidat doit écrire un message qui « annonce + décrit + invite ». Il
oublie l'invitation. L'IA baisse un peu la note du critère « pertinence » — et c'est tout. Le
candidat voit **14/20** et un commentaire flou. Il ne sait pas qu'il a oublié un tiers de la
consigne.

**La spec propose** une liste à cocher, affichée **avant** la grammaire :

```
✓ Nouvelle annoncée
✓ Logement décrit
○ Invitation absente
```

**Mon avis : totalement d'accord.** C'est l'amélioration la plus utile de toute la spec, et
c'est celle qui coûte le moins cher — une case en plus dans le format de réponse de l'IA,
aucun changement de base de données.

> ⚠️ **Nuance importante à ne pas rater.** On a délibérément écrit dans les rubriques
> « ne jamais exiger l'exhaustivité » pour EO1 et EO2. C'était un bon choix : le sujet propose
> des **pistes**, pas une check-list. Il faut donc distinguer deux choses :
> - les points **vraiment obligatoires** de la consigne → ils comptent dans la note ;
> - les **pistes suggérées** → affichées à titre informatif, **sans pénaliser**.
>
> Sans cette distinction, on casserait une règle qu'on a mis du temps à poser.

### B. On n'exprime jamais **notre degré de certitude**

**Aujourd'hui.** On affiche « 13/20 » sur le même ton, qu'il s'agisse d'un texte écrit propre
de 90 mots ou d'un dialogue oral transcrit en direct, hachuré, à moitié illisible.
**Ce n'est pas honnête.**

**La spec propose** une confiance (faible / moyenne / haute) avec ses raisons. L'affichage
devient :

> **Niveau estimé : B1 — confiance moyenne**
> (transcription temps réel partiellement incertaine)

**Mon avis : d'accord, et c'est très peu cher.** Ça protège aussi le produit : on promet une
**estimation pédagogique**, pas un verdict.

### C. Aucun contrôle automatique avant d'appeler l'IA

**Aujourd'hui.** On vérifie le nombre de mots et la durée, c'est tout. Il manque des
vérifications toutes simples, faites par le serveur, **sans IA** :

- le texte est-il **en français** ? (aujourd'hui, un texte en anglais part chez l'IA et
  reçoit une note) ;
- le candidat a-t-il **recopié la consigne** pour faire du volume ? ;
- en oral temps réel, le candidat a-t-il **vraiment parlé** ? (partiellement géré).

**Mon avis : d'accord.** C'est du code déterministe, pas cher, et ça évite des notes absurdes
tout en économisant des appels IA inutiles.

### D. L'examinateur de la Tâche 2 improvise tout

C'est le manque le plus **structurel**.

**Aujourd'hui.** En jeu de rôle (EO2), l'examinateur IA reçoit une seule phrase de contexte
(« l'examinateur joue le guichetier ») et **invente tous les faits au fur et à mesure** : les
prix, les horaires, les délais.

Deux conséquences :
1. Il peut **se contredire** en cours d'échange (dire 12 € puis 15 €).
2. On n'a **aucune vérité de référence** : impossible de savoir objectivement si le candidat
   a obtenu les bonnes informations.

**La spec propose** une fiche de scénario structurée (rôle, objectif, informations à
détenir, contraintes de l'agent).

**Mon avis : d'accord sur le fond, mais c'est le chantier le plus lourd.** Il implique une
nouvelle colonne en base, la réécriture du persona T2, et la **réécriture des ~20 sujets
EO T2** existants. → Phase 2, pas phase 1.

---

## 3. Ce sur quoi je ne suis PAS d'accord

### ❌ La double évaluation systématique (§4.2)

**La spec veut** faire tourner l'IA **deux fois** sur chaque production, plus une troisième
passe d'arbitrage en cas de désaccord.

**Pourquoi non :**
- On tourne à **température 0**, c'est-à-dire que l'IA choisit systématiquement le mot le plus
  probable. ⚠️ **Attention : ce n'est pas parfaitement reproductible** — l'arithmétique
  interne, le traitement par lots côté fournisseur et les mises à jour silencieuses du modèle
  peuvent faire diverger deux appels identiques. Mais la variation reste faible : on paierait
  double pour gratter peu.
- Surtout, le vrai problème n'est pas la variabilité, c'est le **biais systématique** (l'IA est
  trop gentille **tout le temps**). Refaire tourner le même modèle ne corrige pas un biais — il
  le répète à l'identique.
- **Coût** : un examen blanc complet = 6 évaluations. Doubler, c'est doubler la facture IA à
  chaque examen, et doubler la latence perçue.

**Contre-proposition :** une seule passe par défaut. Une deuxième passe **uniquement** en zone
floue (score juste à la limite d'un palier, confiance faible, résultat incohérent avec les
critères, production difficile à interpréter) — et **avec un modèle différent**, sinon ça ne
sert à rien.

➡️ **Conséquence directe :** puisque la reproductibilité n'est pas garantie, le banc de mesure
doit **rejouer le même lot 3 fois** et mesurer la stabilité. Si un même texte oscille entre 11
et 14/20 d'une exécution à l'autre, c'est une information capitale — et aujourd'hui on n'en
sait rien.

### ❌ Passer les critères sur une échelle 0-4 **en interne** (§5)

**La spec veut** remplacer nos notes /20 par des notes 0-1-2-3-4.

**Pourquoi non :** on perd énormément de finesse dans le **calcul**. Avec 4 critères notés de 0
à 4, un seul critère qui bouge d'un cran fait basculer toute la note. Les effets de seuil
deviennent violents et injustes. Notre échelle /20 est **déjà ancrée sur le CECRL** par bandes
(16-20 = B2, 11-15 = B1, 6-10 = A2, 1-5 = A1).

> ✅ **En revanche, l'objection sur l'affichage est juste et je l'accepte.** Une IA ne distingue
> pas honnêtement un 13 d'un 14. Afficher « Lexique : 13/20 » suggère une précision qui
> n'existe pas.
>
> **Décision :** on garde le **/20 en interne** (calcul, seuils, banc de mesure), mais **par
> critère on affiche une bande qualitative**, pas un nombre :
>
> > **Conduite de l'échange : satisfaisante**
> > Vous posez des questions pertinentes, mais vous relancez rarement l'interlocuteur.
>
> **La note globale /20 reste affichée** : c'est le repère qu'un candidat attend d'un examen,
> et le supprimer serait vécu comme une perte. La fausse précision est un problème au niveau
> du critère (4 nombres qui bougent), pas au niveau du résultat d'ensemble.

### ❌ La table de conversion note → niveau de la spec (§15.4)

**La spec propose** : `10 à 20/20 = B2`.

**Pourquoi non :** c'est **beaucoup trop généreux** — la moitié de l'échelle donnerait B2. Et
c'est en contradiction avec sa propre §5.1 (où B1 = 75 % et B2 = 100 %). Nos seuils actuels
(≥ 15 → B2, ≥ 12 → B1, ≥ 7 → A2) sont bien plus défendables.

➡️ **On garde les nôtres** — mais ils méritent d'être recalibrés pour de vrai (cf. §5.4).

### ❌ Mettre les grilles de notation en base de données (§18.3)

**La spec veut** stocker la rubrique de chaque tâche en base.

**Pourquoi non :** chez nous elles vivent dans un **fichier versionné**
(`production-rubrics-v3.json`), validé au démarrage de l'application. C'est mieux :
- on voit l'historique des changements dans Git ;
- on ne peut pas casser la notation par une mauvaise ligne SQL ;
- l'appli **refuse de démarrer** si la grille est incohérente (poids qui ne font pas 1,00,
  critère inconnu, tâche sans barème).

Ce serait une **régression d'architecture**.

**Seule exception :** la **fiche de scénario EO2** (point D ci-dessus), qui est une donnée
propre à chaque sujet → elle, oui, va en base.

### ❌ La table `conversation_turns` (§18.2)

**La spec veut** stocker chaque tour de parole en base avec temps de réponse, pauses,
interruptions, ratio de temps de parole.

**Pourquoi non :**
- Ces mesures viennent du **client** (téléphone ou navigateur) : elles ne sont pas fiables.
  Une latence peut venir du réseau, pas du candidat. Noter quelqu'un sur une mesure fausse est
  pire que ne pas le noter du tout.
- Ça crée une table qui grossit vite, alors qu'on a déjà identifié la croissance des tables
  comme un point de vigilance avant l'ouverture publique (cf. `CLAUDE.md` racine).

**Contre-proposition :** garder le transcript en texte (comme aujourd'hui) et demander à l'IA
correctrice de produire son analyse de l'échange **dans sa réponse structurée**. Aucune
nouvelle table.

### ❌ La campagne de calibration à 480 productions (§20)

**La spec demande** 20 productions annotées par niveau **et** par tâche, chacune corrigée par
2 professeurs de FLE → **480 productions × 2 correcteurs**. C'est un projet à plusieurs
milliers d'euros et plusieurs mois, posé comme **prérequis à la mise en production**.

**Mon avis :** d'accord avec le **principe**, pas avec l'échelle. Progression retenue :
- **36 à 60 productions** pour démarrer (36 = 6 tâches × 6 cas, structure propre) ;
- enrichissement continu vers **100-150 cas** ;
- **double annotation humaine uniquement** sur les cas ambigus et les frontières A2/B1/B2 —
  c'est là que l'argent d'annotation est utile, pas sur un A1 évident.

### ⚠️ Afficher un niveau CECRL par tâche (§1.2, §15.1)

**La spec veut** afficher « niveau démontré : A2 » sur chaque tâche.

**Mon objection initiale** était : sur un message de 40 mots, annoncer un niveau CECRL n'est
pas sérieux — le niveau ne devrait apparaître qu'au bilan d'une épreuve complète.

> ✅ **Objection levée en revue contradictoire.** La formulation suivante **répond** au
> problème au lieu de le contourner :
>
> > **Performance observée sur cette tâche : proche du niveau B1**
> > Estimation pédagogique, confiance moyenne. Le niveau final dépend des trois tâches.
>
> Le « proche de » + la confiance affichée + le rappel que le niveau réel vient du bilan
> lèvent le risque de fausse promesse. Et pour un outil d'**entraînement**, ne rien dire du
> tout est effectivement moins utile pour le candidat.
>
> Bonus : c'est **presque gratuit**. Le serveur **calcule et stocke déjà** ce niveau par
> soumission (`niveau_cecrl`, dérivé de lexique + morphosyntaxe + cohérence) — on refuse juste
> de l'exposer. Il n'y a qu'à l'afficher.
>
> **Deux garde-fous :** jamais affiché sans la confiance à côté ; le bilan d'épreuve reste le
> **seul** niveau qui fait foi.

---

## 4. Mon propre diagnostic (ce que la spec ne dit pas)

Au-delà de la spec, voici ce que je vois en lisant le code.

### 4.1 Les 4 critères sont les mêmes pour les 6 tâches

**C'est le vrai défaut de fond.**

Aujourd'hui, qu'il s'agisse d'un petit message de 40 mots à un ami ou d'une argumentation
orale de 3 min 30, on pose exactement les **mêmes 4 questions** à l'IA : pertinence, lexique,
morphosyntaxe, cohérence. Seuls les **poids** changent d'une tâche à l'autre.

Résultat : **les commentaires sont génériques parce que les questions sont génériques.**

Exemple concret : sur EO2 (obtenir des informations en dialogue), « cohérence » ne veut pas
dire grand-chose. Ce qui compte vraiment, c'est **est-ce qu'il a mené l'échange et obtenu ce
qu'il voulait**. Ce critère n'existe nulle part dans la grille.

➡️ **C'est là que la spec a le plus raison**, et c'est presque gratuit à corriger : c'est un
fichier JSON.

### 4.2 On a empilé tellement de tolérances que l'IA est probablement devenue trop gentille

Liste des consignes actuelles données à l'IA :

- ne jamais pénaliser la longueur ;
- ne pas évaluer l'orthographe à l'oral ;
- ne pas exiger l'exhaustivité ;
- l'examinateur est « témoin de la compréhension » → porter la réussite au crédit du candidat ;
- bénéfice du doute systématique sur la transcription ;
- ne jamais conclure « incompréhensible ».

Chaque règle prise **isolément** est justifiée — chacune a été ajoutée pour corriger un vrai
problème. Mises **bout à bout**, elles poussent mécaniquement les notes vers le haut.

Or notre produit sert à dire au candidat **s'il va réussir le vrai TCF**. Une IA trop
indulgente est un **mauvais service** : le candidat paie l'examen officiel en croyant être B1,
et échoue.

Je pense que c'est une grosse partie de l'insatisfaction actuelle. **Mais je ne peux pas
l'affirmer sans mesure** (cf. 4.4).

### 4.3 Les exemples de calibration sont trop pauvres

L'IA ne dispose que de **3 exemples** de référence pour se caler. Or ces 3 exemples sont :

- **tous des écrits** → aucun oral ;
- **aucun dialogue temps réel bruité** ;
- **aucun cas A1 ou A1 non atteint** ;
- niveaux couverts : A2, B1, B2 seulement.

Autrement dit : **l'IA n'a aucun repère exactement là où le risque est le plus grand.**

Corriger ça est très peu cher : ajouter des exemples par tâche, dont un dialogue oral réaliste
(avec sa transcription hachée) et un cas bas niveau.

### 4.4 Et surtout : **on ne sait pas mesurer si on s'améliore**

C'est **le point bloquant**. Aujourd'hui, si on change le prompt, on n'a **aucun moyen de
savoir** si la notation devient meilleure ou pire. On avance à l'intuition.

On logue bien l'écart entre la note de l'IA et le calcul serveur, et la divergence de niveau —
mais personne ne les regarde, et ça ne répond pas à la question « est-ce qu'on note juste ? ».

➡️ Tant qu'on n'a pas un petit banc de test reproductible, **toute modification est un pari**.
C'est la priorité n° 1, avant même de changer les grilles.

### 4.5 Notre note orale est **structurellement incomplète** — et on ne le dit pas

*(Ajouté après revue contradictoire.)*

À l'oral, on ne juge que le **texte transcrit**. On sait donc évaluer le vocabulaire, la
grammaire, le contenu, l'organisation, et une partie de l'interaction. On **ne sait pas**
évaluer l'aisance, la fluidité, l'intelligibilité, les hésitations, la prononciation — qui font
pourtant partie de l'évaluation orale réelle.

Ce n'est pas un choix pédagogique, c'est une **contrainte technique** qu'on avait présentée
comme un avantage. Il faut le dire au candidat, noir sur blanc :

> Évaluation principalement fondée sur la transcription. Les caractéristiques fines de la voix
> ne sont pas entièrement évaluées.

**Pourquoi on ne corrige pas ça tout de suite — deux obstacles sérieux :**

**(a) Pour 2 tâches sur 3, l'audio n'existe pas de notre côté.** En EO temps réel (T1 et T2),
le client parle **directement à Gemini** et ne nous relaie que du texte
(`realtime_sessions.transcript`). Aucun audio n'atteint nos serveurs. Analyser la voix
supposerait de capturer et remonter l'audio du candidat : nouveau chantier, nouveau coût de
stockage, et une vraie question de vie privée (on stockerait de la voix). En l'état, l'analyse
audio ne serait possible que sur les productions **asynchrones** (celles passées par Whisper) →
un candidat qui fait T1 en temps réel et un autre qui le fait en enregistré seraient notés sur
des critères **différents**. Inacceptable.

**(b) Risque d'équité, et il est sérieux.** Notre public, ce sont des personnes en démarche de
titre de séjour ou de naturalisation — donc massivement des accents non natifs. Demander à une
IA de juger « prononciation et fluidité » sur de l'audio, c'est le terrain où ces modèles sont
connus pour être moins performants selon l'accent et la langue maternelle. On risquerait de
fabriquer un correcteur qui pénalise systématiquement certaines origines. La spec le dit
elle-même (§7.2 : intelligibilité, pas imitation d'un natif) — mais elle ne dit pas comment
l'empêcher.

**Ce qu'on peut faire sans attendre, sans audio et sans biais d'accent :** le **débit**
(mots ÷ durée) et les **pauses longues** sont déjà calculables à partir de ce que Whisper
renvoie. C'est un vrai indice de fluidité, totalement neutre vis-à-vis de l'accent.

> ⚠️ Attention : ça **inverse** notre règle actuelle « ne jamais juger le débit ni la durée ».
> C'est une décision produit assumée, pas un ajustement discret — et elle doit être répercutée
> dans `docs/notation-ia-eo-ee.md`.

---

## 5. Plan proposé

Par phases, de la plus rentable à la plus lourde.

### Phase 0 — Le banc de mesure *(à faire en premier)*

- Un jeu de **36 à 60 productions de référence** (6 par tâche : écrites + orales, du A1 au B2,
  dont des cas bruités, des hors-sujet, des textes mémorisés), avec pour chacune : le résultat
  attendu, l'accomplissement attendu, le niveau ou la zone attendue, les erreurs importantes,
  la confiance attendue. Enrichissement continu vers **100-150 cas**.
- **Double annotation humaine ciblée** : uniquement sur les cas ambigus et les frontières
  A2/B1/B2.
- Une **commande reproductible** qui rejoue tout le lot et sort : accord exact, accord à ±1
  niveau, **matrice de confusion par tâche**, sévérité moyenne par tâche.
- **Stabilité sur 3 exécutions** du même lot (la température 0 ne garantit pas la
  reproductibilité — cf. §3).

**Sans ça, on ne saura jamais si les phases suivantes améliorent quoi que ce soit.**

### Phase 1 — Fort impact, coût faible *(essentiellement du JSON + affichage)*

1. **Critères propres à chaque tâche** (rubriques v4) au lieu des 4 critères universels.
   EO2 gagne un vrai critère « obtention des informations et conduite de l'échange ».
2. **Confiance** (faible / moyenne / haute) + ses raisons, affichée au candidat.
3. **Bloc « accomplissement »** : liste à cocher des points de la consigne, traités /
   oubliés, affichée **avant** la grammaire — en respectant la distinction
   « obligatoire vs piste » (cf. §2.A).
4. **Contrôles automatiques avant l'IA** : langue du texte, recopiage de la consigne, prise
   de parole réelle.
5. **Exemples de calibration enrichis** : un par tâche, dont un A1 et un dialogue oral bruité.
6. **Avertissement « évaluation fondée sur la transcription »** sur toute production orale
   (cf. §4.5).
7. **Affichage par critère en bandes qualitatives** au lieu d'un nombre — la note globale /20
   reste affichée (cf. §3).
8. **« Performance observée : proche du niveau B1 — confiance moyenne »** par tâche, avec le
   rappel que le niveau final dépend des 3 tâches (cf. §3).
9. **Preuves extraites de la production** pour chaque critère, et **1 à 2 priorités maximum**
   (pas une liste décourageante).

### Phase 2 — Structurel *(coût réel)*

10. **Fiche de scénario EO2** en base → examinateur cohérent + vérité de référence pour la
    check-list. Implique la réécriture des ~20 sujets EO T2.
11. **Quelques plafonds** (ex. « pas d'opinion identifiable en T3 → le niveau ne peut pas
    dépasser A2 »), appliqués côté serveur, après le calcul du niveau.
12. **Recalibrage des seuils** de niveau, sur la base des mesures de la phase 0.

### Phase 3 — Optionnel, décidé par la mesure

13. **Débit et pauses longues** depuis les données Whisper (indice de fluidité neutre vis-à-vis
    de l'accent). ⚠️ Inverse la règle actuelle « ne pas juger le débit » → décision produit.
14. **Analyse audio réelle**, sous trois conditions cumulatives :
    - l'audio doit d'abord exister pour les **3 tâches** (donc capturer l'audio du temps réel) ;
    - on mesure l'**effort de compréhension**, jamais la conformité à un accent ;
    - **contrôle de biais obligatoire sur le banc** : si le score varie selon la langue
      maternelle à niveau égal, on ne livre pas.
15. Deuxième passe IA **uniquement** en zone floue, avec un **modèle différent**.
16. Règles de cohérence au bilan d'épreuve (ex. « pas de B2 global si T3 est à A2 »).

---

## 6. Arbitrages issus de la revue contradictoire

L'auteur de la spec a relu cette analyse et émis 5 objections. Verdict :

| Objection | Verdict | Ce que ça change |
|---|---|---|
| **1. Température 0 n'est pas parfaitement déterministe** | ✅ **Accepté** — j'avais surestimé | Conclusion inchangée (pas de double appel systématique), mais ajout d'une mesure de **stabilité sur 3 exécutions** en phase 0 |
| **2. Ne rien analyser de la voix n'est pas « mieux »** | ✅ **Accepté sur le cadrage**, ⚠️ **différé sur la mise en œuvre** | Nouvelle §4.5 : c'est une **limite**, pas un avantage → **avertissement au candidat en phase 1**. Analyse audio maintenue en phase 3, sous conditions (audio absent en temps réel + risque de biais d'accent) |
| **3. Le /20 donne une fausse précision** | ✅ **Accepté** (ce n'était pas un désaccord : il visait l'affichage, moi le calcul) | /20 conservé **en interne** ; **bandes qualitatives par critère** à l'affichage ; note globale /20 conservée |
| **4. Le niveau par tâche ne doit pas être supprimé** | ✅ **Accepté — sa version est meilleure que la mienne** | « Performance observée : proche du niveau B1 » + confiance + rappel que le bilan fait foi. Presque gratuit (déjà calculé et stocké) |
| **5. 30-60 productions, c'est un début** | ✅ **Accepté — sa progression est plus fine** | 36-60 pour démarrer → 100-150 en continu ; double annotation ciblée sur les frontières A2/B1/B2 |

**Non remis en cause par la revue** (et largement validé par elle) : refus de la double
évaluation systématique, refus de l'échelle 0-4 en interne, refus de la table `10/20 = B2`,
refus des rubriques en base, refus de la table `conversation_turns`, diagnostic sur
l'empilement des tolérances, priorité au banc de mesure.

---

## 7. Garde-fous si on y va

Non négociables, quelle que soit la phase retenue :

- **Parité web ⇄ mobile ⇄ admin.** Le format de réponse de l'IA change → les miroirs de DTO
  (`web_sejoufr/lib/types.ts`, `mobile_sejourfr/lib/core/models/*.dart`,
  `admin_sejourfr/src/types/api.ts`) et les écrans de résultat doivent être mis à jour **dans
  la même passe**.
- **`docs/notation-ia-eo-ee.md` mis à jour dans la même passe.** C'est une exigence explicite
  du `CLAUDE.md` racine, et elle est justifiée : c'est la référence grand public de la
  notation. Concerné en priorité : l'avertissement « fondé sur la transcription », le passage
  aux bandes qualitatives, l'affichage d'un niveau par tâche, et — si on fait la phase 3 —
  l'inversion de la règle sur le débit.
- **Tests** sur chaque nouvelle règle de calcul (unitaires pour la math, intégration si ça
  traverse la base).
- **Versionner, ne jamais réécrire.** Nouvelle rubrique = `v4`. On ne touche pas à `v3` —
  sinon les anciennes évaluations deviennent illisibles et incomparables.

---

## 8. Tableau de synthèse : verdict section par section

| Section de la spec | Verdict | Pourquoi |
|---|---|---|
| §1.1 Longueurs et durées TCF IRN | ✅ Corrigé | Seeds conformes (30-60 / 60-90 / 60-90 ; 180 s / 210 s) |
| §1.2 Distinguer difficulté et niveau attribué | ✅ Déjà fait | Le niveau n'est pas plafonné à la cible |
| §1.2 Afficher un niveau par tâche | ✅ **Accepté** (révisé) | Version hedgée : « performance proche de B1 » + confiance + le bilan fait foi |
| §2 Ordre de priorité (tâche avant langue) | ✅ D'accord | À traduire dans les rubriques v4 |
| §3 Familles de critères (pragma / linguistique / socio) | ✅ D'accord | Bon cadre pour redécouper les critères par tâche |
| §4.1 Contrôles déterministes avant le LLM | ✅ D'accord | Manque réel, peu cher |
| §4.2 Double évaluation systématique | ❌ Refusé | Coût ×2 pour corriger la mauvaise variable (biais ≠ variance) |
| §4.3 Confiance explicite | ✅ D'accord | Manque réel, peu cher, honnête |
| §5 Échelle 0-4 par critère | ❌ Refusé **en interne**, ✅ accepté **à l'affichage** | Calcul en /20 ; bandes qualitatives à l'écran |
| §6.1 Seuils de niveau | ⚠️ À recalibrer | Principe OK, valeurs à dériver de la mesure |
| §6.2 Plafonnements | ✅ D'accord, version courte | Quelques plafonds ciblés, pas la liste entière |
| §6.3 Ne pas compter les fautes | ✅ Déjà fait | Dans le prompt actuel |
| §7.2 Intelligibilité, pas accent | ⚠️ Revu | Déjà fait **par défaut** (pas d'audio). C'est une limite à annoncer, pas un acquis — cf. §4.5 |
| §8-§10 Critères EO par tâche | ✅ D'accord | Cœur de la phase 1 |
| §9.2 Fiche de scénario EO2 | ✅ D'accord | Phase 2, chantier lourd mais justifié |
| §9.4 Journal de conversation en base | ❌ Refusé | Mesures client peu fiables + table qui grossit |
| §11-§14 Critères EE par tâche | ✅ D'accord | Cœur de la phase 1 |
| §15.2 Moyenne simple des 3 tâches | ❌ Refusé | On fait déjà mieux (moyenne pondérée 1/2/3) |
| §15.3 Règles de cohérence d'épreuve | ⚠️ Intéressant | Version allégée, phase 3 |
| §15.4 Table note → niveau | ❌ Refusé | 10/20 = B2 est bien trop généreux et s'auto-contredit |
| §16 Écran de résultats | ⚠️ Partiel | Beaucoup existe déjà ; neuf = check-list, confiance, bandes, plan d'entraînement |
| §16.8 Plan d'entraînement | ⚠️ Conditionnel | À ne faire que si les exercices sont **cliquables**, sinon c'est décoratif |
| §17 Schéma JSON de sortie | ⚠️ Partiel | Bonnes idées à greffer sur notre schéma, pas à remplacer |
| §18.1 Versionnement des évaluations | ✅ D'accord | On stocke déjà modèle + prompt-version ; à compléter |
| §18.3 Rubriques en base | ❌ Refusé | Régression : on perd Git + validation au démarrage |
| §19 Règles obligatoires du prompt | ✅ D'accord | Largement déjà en place, à compléter |
| §20 Calibration à 480 copies | ⚠️ Réduit | 36-60 → 100-150, double annotation ciblée sur les frontières |
| §21 Ordre d'implémentation | ⚠️ Réordonné | Il manque la phase 0 (mesure) en tête |
