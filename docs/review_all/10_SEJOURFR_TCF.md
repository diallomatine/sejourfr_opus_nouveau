# SejourFR — Module TCF IRN

> Prérequis : `00_SEJOURFR_SPEC_MAITRE.md` lu, `AUDIT.md` produit et validé.
> Ce document couvre : diagnostic rapide, diagnostic complet, résultats, paywall, plan, refonte Réviser EE/EO, micro-exercices, rapports IA, modèle de données, API, tests.

---

# 1. Rappels de format (source : référentiel projet)

Le TCF IRN comporte **4 épreuves obligatoires** :

| Épreuve | Format réel | Code |
|---|---|---|
| Compréhension orale | 25 QCM / 20 min | `CO` |
| Compréhension écrite | 25 QCM / 35 min | `CE` |
| Expression écrite | 3 exercices / 30 min | `EE` |
| Expression orale | 3 exercices / 10 min | `EO` |

**STRUCTURE n'est pas une épreuve IRN.** Elle reste une catégorie d'entraînement, exclue des examens blancs IRN et **jamais affichée comme priorité de plan** (arbitrage A8).

Correspondance niveau / démarche : A2 = CSP, B1 = CR, B2 = NAT.

---

# 2. Les tâches EE et EO

Ce modèle est **nouveau**. Il doit être créé.

## 2.1. Expression écrite

| Tâche | Intitulé utilisateur | Longueur | Durée indicative | Niveau visé |
|---|---|---|---|---|
| EE1 | Message | 60–120 mots | ~8 min | A2 → B1 |
| EE2 | Récit / expérience | 120–150 mots | ~10 min | B1 |
| EE3 | Donner son opinion | 150–180 mots | ~12 min | B1 → B2 |

## 2.2. Expression orale

| Tâche | Intitulé utilisateur | Format | Durée officielle |
|---|---|---|---|
| EO1 | Se présenter / échange guidé | réponse libre | **3 min** |
| EO2 | Obtenir des informations | poser des questions à partir d'une situation | **3 min 30, sans préparation** |
| EO3 | Donner son opinion | exposé argumenté | **3 min 30** |

Total EO : **10 minutes**, conforme au format IRN. Ces durées sont la référence :
`tcf_task.max_duration_seconds` vaut 180 / 210 / 210. **Aucun plafond audio global.**
Le plafond d'entrée du LLM est dérivé de la tâche, jamais d'une constante.

## 2.3. Compétences (moteur, 8 par épreuve maximum)

Codes internes, préfixés par épreuve. `label_user` obligatoire, stocké en base.

**EE**

| Code | Label utilisateur |
|---|---|
| `ee_consigne` | Respecter la consigne |
| `ee_developper` | Développer ses idées |
| `ee_argumenter` | Développer ses arguments |
| `ee_nuancer` | Nuancer son opinion |
| `ee_coherence` | Relier ses idées |
| `ee_lexique` | Utiliser un vocabulaire adapté |
| `ee_correction_langue` | Correction de la langue |
| `ee_registre` | Adapter le registre |

**EO**

| Code | Label utilisateur |
|---|---|
| `eo_consigne` | Respecter la consigne |
| `eo_developper` | Développer sa réponse |
| `eo_argumenter` | Développer ses arguments |
| `eo_nuancer` | Nuancer son opinion |
| `eo_coherence` | Relier ses idées |
| `eo_lexique` | Utiliser un vocabulaire adapté |
| `eo_interaction` | Poser des questions / interagir |
| `eo_fluidite` | Fluidité et aisance |

**Rattachement compétence → tâche** (une compétence n'est pertinente que pour certaines tâches) :

| Tâche | Compétences actives |
|---|---|
| EE1 | `ee_consigne`, `ee_registre`, `ee_lexique`, `ee_correction_langue` |
| EE2 | `ee_consigne`, `ee_developper`, `ee_coherence`, `ee_lexique`, `ee_correction_langue` |
| EE3 | `ee_consigne`, `ee_argumenter`, `ee_nuancer`, `ee_coherence`, `ee_lexique`, `ee_correction_langue` |
| EO1 | `eo_consigne`, `eo_developper`, `eo_fluidite`, `eo_lexique` |
| EO2 | `eo_consigne`, `eo_interaction`, `eo_fluidite`, `eo_lexique` |
| EO3 | `eo_consigne`, `eo_argumenter`, `eo_nuancer`, `eo_coherence`, `eo_fluidite` |

Règle : **3 compétences actives maximum affichées** par tâche, choisies par le moteur parmi celles en défaut.

---

# 3. Diagnostic écrit rapide

## 3.1. Principe

**Une seule production écrite, sur un sujet transversal.** Ce sujet n'est ni EE1, ni EE2, ni EE3 : il ne reproduit aucune tâche du TCF. Il est conçu pour que le candidat mobilise naturellement, dans un même texte, plusieurs capacités observables :

décrire · raconter · expliquer · donner son avis · justifier · développer · relier ses idées · vocabulaire et correction de la langue.

- Longueur demandée : **150 à 220 mots**.
- Durée réelle visée : **8 à 10 minutes**. C'est une porte d'entrée, pas un premier examen.
- Wording imposé : « **Niveau estimé sur cet exercice** ». Jamais « votre niveau TCF ».

## 3.2. Avant l'exercice

Trois questions, une seule page :

1. Quel examen préparez-vous ? `TCF IRN` / `Examen civique` / `Les deux`
2. Quel niveau visez-vous ? `A2 — CSP` / `B1 — CR` / `B2 — naturalisation`
3. Avez-vous une date d'examen ? `Oui, le [date]` / `Pas encore`

Ces réponses irriguent tout le tunnel : « Objectif B2 avant le 18 octobre ».

## 3.3. Le sujet

Pool de sujets en base (`quick_diag_subject`), tirage aléatoire, tous construits sur le même patron en trois mouvements — **décrire, raconter, projeter/justifier** — sans jamais nommer de tâche TCF.

Sujet de référence :

> « Parlez-nous un peu de vous et de votre quotidien. Décrivez votre lieu de vie, racontez une expérience récente qui vous a marqué, puis expliquez quelque chose que vous aimeriez changer dans votre quotidien et pourquoi. »

Chaque sujet stocke ses `observation_targets` (les capacités qu'il permet d'observer), utilisés par le prompt.

Interface : un seul champ de saisie, compteur de mots vivant, indication « 150–220 mots », sauvegarde du brouillon en continu. Pas de chronomètre bloquant.

Seuil de recevabilité : **100 mots**. En dessous, pas d'analyse, message « Nous n'avons pas assez d'éléments pour estimer votre niveau », invitation à compléter. **Aucun appel LLM déclenché.**

## 3.4. Tunnel : le compte vient avant le résultat

C'est le point le plus important de cette section, et il est volontairement différent de ce qu'on ferait par réflexe.

```
Écran sujet
   └─ rédaction (anonyme, brouillon local + serveur sur anon_id)
        └─ [Valider mon diagnostic]
             └─ Écran « Votre analyse est prête »
                  « Créez votre compte pour découvrir votre niveau estimé
                    et vos axes de progression. »
                  [Créer mon compte]   ·   [J'ai déjà un compte]
                       └─ création / connexion
                            └─ APPEL LLM déclenché ICI
                                 └─ Résultat complet, gratuit (§3.6)
                                      └─ CTA « Faire mon diagnostic TCF complet »
```

Trois raisons, à respecter à la lettre :

1. **Commercialement** : la personne a déjà investi 10 minutes, elle veut son résultat. C'est le meilleur moment pour demander un compte — et on ne demande pas d'argent.
2. **Techniquement** : l'appel IA n'est déclenché **qu'après** création du compte. On ne paie pas les diagnostics abandonnés.
3. **Continuité** : la production est rattachée au compte, donc réutilisable par le diagnostic complet et par le plan.

Contraintes d'implémentation :

- la production est persistée sur l'`anon_id` **avant** l'écran de compte, jamais perdue si l'inscription échoue ou est reprise plus tard ;
- rattachement automatique `anon_id → user_id` à la création, y compris si l'utilisateur se connecte à un compte existant ;
- l'écran « Votre analyse est prête » ne doit pas mentir : rien n'est encore analysé. Formulation exacte imposée : « Votre texte est enregistré. Créez votre compte pour lancer l'analyse. » ;
- pendant l'analyse (5 à 15 s), écran d'attente explicite, jamais un spinner nu.

## 3.5. Traitement

**Un seul appel LLM** sur la production unique (`PROMPT_QUICK_DIAG_v1`, §10.1), source `DIAGNOSTIC_QUICK`.

Le modèle observe les capacités, le moteur décide de l'affichage. Les signaux de compétence produits ici sont **provisoires** et seront écrasés par le diagnostic complet.

## 3.6. Écran de résultat (spec de rendu)

Ordre imposé. Aucun paywall.

```
[Header]      ← retour · « Votre estimation »
              sous-titre : « Diagnostic rapide terminé »

[Bloc 1 — Résultat]           carte principale, l'élément dominant de l'écran
              « Niveau estimé sur cet exercice »
              B1                                 ← Fraunces, très grand
              « Votre objectif : B2 »
              jauge : A2 ─── ● B1 ───── ○ B2
                             Vous      Objectif
              phrase de contexte générée (1 à 2 phrases, jamais plus)
              ⚠ aucun pourcentage

[Bloc 2 — Ce que nous avons observé]
              exactement 3 lignes : 1 positive (vert ✓) + 2 à améliorer (ambre ↑)
              titre court + une phrase secondaire
              vocabulaire candidat uniquement

[Bloc 3 — Transition]         carte de fond bleu clair, visuellement différente
              « Ce n'est qu'une première estimation »
              « Cet exercice analyse votre manière de vous exprimer à l'écrit.
                Au TCF, votre niveau dépend aussi de votre expression orale,
                de votre compréhension orale et de votre compréhension écrite. »
              en évidence : « Votre niveau peut donc être différent selon les épreuves. »

[Bloc 4 — Diagnostic complet]
              « Découvrez où vous en êtes vraiment au TCF »
              4 lignes : 🎧 CO · 📖 CE · ✍️ EE · 🎤 EO
              « À la fin, vous connaîtrez :
                ✓ votre niveau par épreuve
                ✓ les tâches qui vous limitent
                ✓ vos priorités pour atteindre votre objectif »
              [CTA principal] Faire mon diagnostic complet
              sous-texte : « 4 épreuves · environ 75 min · vous pouvez le faire en plusieurs fois »

[Bloc 5 — Aperçu des priorités]   secondaire, discret
              🟠 Développer vos arguments
              🟡 Organiser et relier vos idées
              🔒 Vos priorités en expression orale
              🔒 Vos priorités en compréhension
              libellé du cadenas : « Complétez votre diagnostic pour les découvrir »
              ⚠ le cadenas ne signifie PAS « payez »
              ⚠ ne jamais nommer ici une tâche TCF précise : elle n'a pas été évaluée

[Pied]        une ligne, très discrète :
              « Avec Premium, votre diagnostic peut devenir un plan d'entraînement personnalisé. »
              ⚠ aucun bouton, aucune ouverture automatique de paywall
```

## 3.7. Abus

Le diagnostic rapide **n'est pas verrouillé agressivement**. Un `anon_id` ne résiste pas à une navigation privée, et chercher à l'empêcher coûterait plus cher que le problème.

- rate limit : 3 soumissions / heure / IP, 1 analyse / heure / compte ;
- 1 analyse gratuite par compte, les suivantes sont Premium ;
- le vrai verrou anti-abus commence au **diagnostic complet**, qui exige un compte avec e-mail vérifié (§4.6).

# 4. Diagnostic TCF complet

## 4.1. Format retenu (arbitrage A2)

4 sections **indépendantes et reprenables**, format réduit :

| Section | Contenu | Durée |
|---|---|---|
| CO | 15 items (sur 25), 5 A2 / 5 B1 / 5 B2 | ~13 min |
| CE | 15 items (sur 25), 5 A2 / 5 B1 / 5 B2 | ~20 min |
| EE | **EE1 + EE2 + EE3** — les 3 tâches, format réel | 30 min |
| EO | **EO1 + EO2 + EO3** — les 3 tâches, format réel (3 / 3 min 30 / 3 min 30) | 10 min |

Total ~75 min, en 4 sessions séparées. Toutes les valeurs sont **configurables** (`diagnostic_config`).

**Règle non négociable : on ne réduit que la compréhension, jamais la production.**
Le plan raisonne par tâche. Afficher « EO Tâche 2 est votre priorité » alors qu'EO2 n'a
jamais été évaluée est une faute produit — la personnalisation devient une fiction.
CO et CE sont réduites parce qu'elles sont des QCM dont le niveau s'estime correctement
sur un échantillon ; EE et EO ne le sont pas parce que chaque tâche évalue autre chose.

Nommage imposé : « **Diagnostic TCF — 4 épreuves** ». Interdit d'appeler cela un examen blanc.
L'examen blanc intégral au format réel reste un objet distinct, Premium.

## 4.2. Séquencement

- Écran d'accueil listant les 4 sections avec leur état : `À faire` / `Terminée` / `En cours`.
- Ordre recommandé mais libre. Une section commencée doit être terminée d'une traite (chronomètre par section).
- Reprise possible **7 jours**. Au-delà, on calcule sur les sections réalisées, les autres sont « non évaluée ».
- Après chaque section : mini-confirmation « Section terminée — plus que N » + progression. **Aucun résultat détaillé n'est affiché avant la fin** (le résultat est le moment de conversion, il ne doit pas être dilué).

## 4.3. Calcul du niveau

### CO et CE (déterministe)

Chaque item porte `difficulty` ∈ {A2, B1, B2}. Répartition imposée : 5 A2 / 5 B1 / 5 B2.

```
taux(niveau) = bonnes réponses sur les items de ce niveau / nombre d'items de ce niveau

niveau_épreuve =
  B2 si taux(A2) ≥ 0.80 et taux(B1) ≥ 0.70 et taux(B2) ≥ 0.60
  B1 si taux(A2) ≥ 0.80 et taux(B1) ≥ 0.60
  A2 si taux(A2) ≥ 0.60
  A1 sinon
```

Seuils centralisés en configuration, jamais en dur.

### EE et EO (LLM + agrégation)

Chaque tâche est évaluée par le LLM (`PROMPT_EE_TASK_v1`, `PROMPT_EO_TASK_v1`) qui renvoie :

- un niveau par tâche (`A1..C1`) ;
- pour chaque compétence active de la tâche, un statut `ACQUIS | FRAGILE | A_TRAVAILLER` + une justification courte + un extrait de la production comme preuve.

```
niveau_épreuve(EE) = min(niveau(EE1), niveau(EE2), niveau(EE3))
niveau_épreuve(EO) = min(niveau(EO1), niveau(EO2), niveau(EO3))
```

Le minimum est retenu volontairement : au TCF, une tâche ratée plafonne le résultat.
Les 3 tâches étant évaluées, **chaque tâche dispose de son propre niveau et de ses propres
statuts de compétence** : c'est ce qui autorise le plan à nommer une tâche précise comme priorité.

### Niveau global (arbitrage A7)

```
niveau_global = min(niveau_CO, niveau_CE, niveau_EE, niveau_EO)
```

Les épreuves non évaluées sont **exclues du minimum** et signalées explicitement à l'écran.

## 4.4. Détermination des priorités

Score de priorité par **tâche** (pas par compétence) :

```
gap_tache      = distance(niveau_tache, niveau_cible)          // 0, 1, 2, 3
gap_epreuve    = distance(niveau_epreuve, niveau_cible)
severite_comp  = 2 × (nb compétences A_TRAVAILLER) + 1 × (nb FRAGILE)
poids_epreuve  = 1.0 si l'épreuve est sous l'objectif, 0.3 sinon

score = (3 × gap_tache + 2 × gap_epreuve + severite_comp) × poids_epreuve
```

Tri décroissant, **3 priorités maximum affichées**. En cas d'égalité : EO avant EE avant CE avant CO (l'expression est ce qui bloque le plus souvent et se travaille le mieux).

Une épreuve déjà au niveau cible ne génère **aucune** priorité : elle apparaît dans « Déjà au niveau attendu ».

Pour CO et CE, la « tâche » n'existe pas : la priorité porte sur l'épreuve et se décline en `competence_code` CE existants (`ce_inference_intention`, `ce_ton_auteur`…) et, en renfort seulement, sur des points STRUCTURE.

## 4.5. Écran de résultat (spec de rendu)

```
[Header]      « Mon diagnostic TCF » + badge « Diagnostic complet »

[Bloc 1 — Niveau]
              « Votre niveau estimé »
              B1                                    ← très grand
              « Objectif : B2 »
              jauge A2 ── ● B1 ── ○ B2
              phrase contextualisée générée
              si une épreuve manque : bandeau « Compréhension orale non évaluée »

[Bloc 2 — Niveau par épreuve]      4 cartes
              🎧 Compréhension orale     B2   Objectif atteint       (vert)
              📖 Compréhension écrite    B2   Objectif atteint       (vert)
              ✍️ Expression écrite       B1   À renforcer            (ambre)
              🎤 Expression orale        B1   Prioritaire            (rouge)
              le niveau est l'élément dominant, pas le pourcentage

[Bloc 3 — Blocage]                 bloc de conversion principal
              titre : « Ce qui vous empêche aujourd'hui d'atteindre B2 »
              3 priorités maximum, hiérarchie Épreuve → Tâche
              🔴 Priorité 1 — Expression orale, Tâche 3
                 « Développer vos arguments et mieux nuancer votre opinion. »
              🟠 Priorité 2 — Expression écrite, Tâche 3
              🟡 Priorité 3 — Expression orale, Tâche 2

[Bloc 4 — Rassurance]
              « Vous n'avez pas besoin de tout retravailler »
              « Votre plan se concentrera d'abord sur les tâches qui ont
                le plus d'impact pour atteindre B2. »

[Bloc 5 — Teaser du plan]
              « Votre plan B2 est prêt »
              1. EO · Tâche 3      Prioritaire
              2. EE · Tâche 3      À renforcer
              3. EO · Tâche 2      À renforcer
              « + 4 compétences ciblées détectées dans vos réponses »
              [CTA] Découvrir mon plan B2

[Pied]        « Estimation SejourFR, non officielle. »
              [lien secondaire] Revoir mes réponses          ← gratuit, non verrouillé
```

**Règle absolue : aucun résultat du diagnostic n'est masqué derrière le paywall.** Le paywall porte sur le plan, pas sur le constat.

## 4.6. Répétition du diagnostic

Gratuit : 1 seul. Nouvelle tentative → écran :

> Votre diagnostic initial a déjà été réalisé.
> Passez Premium pour réévaluer votre niveau et mesurer votre progression.

Premium : réévaluation possible, mais **pas à volonté** — 1 tous les 14 jours, ou déclenchée par le plan quand une priorité est terminée. Sinon la mesure de progression n'a plus de sens.

---

# 5. Paywall contextualisé

Déclenché uniquement par : CTA « Découvrir mon plan », tentative d'accès à un bloc verrouillé du plan, ou 2e correction IA.

```
[Header]      croix de fermeture · logo SejourFR
[Hero]        icône cible
              « Votre plan B2 est prêt »
              « Vous êtes actuellement estimé B1. SejourFR a identifié les priorités
                à travailler pour vous rapprocher de B2. »
              si date d'examen connue : « Objectif B2 avant le 18 octobre — il vous reste 39 jours. »

[Rappel diagnostic]     carte compacte
              « Vos premières priorités »
              🔴 EO — Tâche 3
              🟠 EE — Tâche 3
              🟡 EO — Tâche 2

[Valeur]      exactement 4 bénéfices, jamais une liste de fonctionnalités
              🎯 Travaillez ce qui compte vraiment
              ✨ Comprenez pourquoi vous restez B1
              📈 Voyez réellement votre progression
              🔄 Un plan qui s'adapte

[Offre]       Premium — 14,99 € / mois
              [option, arbitrage A14] Pack 3 mois — 34,99 € (11,66 €/mois)
              ⚠ ne jamais inventer une période d'essai qui n'existe pas

[CTA sticky]  Commencer mon plan B2
              « Annulable à tout moment. »
              liens : Restaurer mes achats · Conditions · Confidentialité
```

Personnalisation obligatoire : niveau actuel, niveau cible, les 3 priorités réelles, et la date d'examen si renseignée. Un paywall sans ces éléments est un bug.

---

# 6. Page Plan

Un seul écran, deux variantes, **même structure**. La variante gratuite n'est pas un écran vide avec un cadenas : c'est le même plan, dont l'accompagnement est verrouillé.

## 6.1. Structure commune

```
[Segmented control]     TCF IRN | Examen civique
[Header]                « Mon plan » · « Votre parcours personnalisé vers B2 »

[1. Objectif]           Niveau actuel  B1   →   Objectif  B2
                        « Plan mis à jour selon vos derniers résultats. »
                        ⚠ aucun pourcentage de progression inventé

[2. À faire maintenant] LE bloc dominant de l'écran
                        🎤 Expression orale
                        Tâche 3 · Donner son opinion        [badge PRIORITÉ N°1]
                        « Objectif de cette séance : développer un argument
                          et apprendre à nuancer votre opinion. »
                        ~8 min · Entraînement ciblé
                        [CTA] Commencer

[3. Votre semaine]      « 2 sur 4 étapes terminées »
                        ✓ Développer un argument
                        ✓ Structurer une réponse
                        ○ Nuancer son opinion
                        ○ Simulation TCF — Tâche 3

[4. Vos priorités]      3 cartes maximum
                        🔴 Expression orale — Tâche 3
                           B1 → B2 · 2 / 5 étapes terminées
                           Argumenter · Nuancer · Relier les idées
                           [Voir le parcours →]
                        🟠 Expression écrite — Tâche 3
                        🟡 Expression orale — Tâche 2

[5. Déjà au niveau]     visuellement secondaire
                        ✓ Compréhension orale — B2
                        ✓ Compréhension écrite — B2

[6. Progression]        n'apparaît qu'après un changement réel
                        « Progression détectée »
                        ✓ Développer un argument
                        « Vos dernières réponses montrent une amélioration.
                          Votre prochaine priorité devient : Nuancer votre opinion. »

[7. Historique]         étapes terminées, repliable
[Bottom nav]            Accueil / Réviser / Plan / Progrès / Profil — Plan actif
```

## 6.2. Variante non abonné

Mêmes blocs 1, 2 (partiel), 4, mais :

- bloc 2 devient **« Votre première étape est prête »** : la tâche et l'objectif de séance sont visibles, puis 3 lignes verrouillées — 🔒 Exercice recommandé, 🔒 Correction personnalisée, 🔒 Suivi de cette compétence ;
- bloc 3 (semaine) remplacé par le **teaser de parcours** :

```
1  Comprendre la structure d'une réponse B2      🔒
2  Développer un argument                        🔒
3  Nuancer son opinion                           🔒
4  Simulation TCF — Tâche 3                      🔒
5  Réévaluation                                  🔒
```

- bloc 4 : les 3 priorités sont **entièrement visibles** (titre, tâche, objectif). Seul « Voir le parcours » est verrouillé ;
- bloc final :

```
« Passez du diagnostic à la progression »
« Votre diagnostic vous montre quoi améliorer.
  Avec Premium, SejourFR vous accompagne étape par étape pour le travailler. »
✓ entraînements choisis selon vos difficultés
✓ corrections et conseils personnalisés
✓ plan adapté à vos progrès
[CTA sticky] Débloquer mon plan B2 — Premium · 14,99 €/mois
```

L'API renvoie pour chaque bloc `locked: bool` et `lock_reason`. Le client n'en décide jamais.

## 6.3. Parcours d'une priorité

En ouvrant « Expression orale — Tâche 3 » :

```
[Pourquoi cette tâche est dans votre plan]
   « Lors de votre diagnostic, votre réponse était compréhensible,
     mais elle ne montrait pas encore suffisamment un niveau B2. »
   citation d'un extrait réel de sa production           ← très fort, à faire

[À travailler]      3 maximum
   🔴 Développer ses arguments
   🟠 Nuancer son opinion
   🟠 Relier ses idées
   ✅ Vocabulaire : bon niveau

[Parcours]          étapes ordonnées, une seule active
   1. Comprendre       ✅  Structure d'une réponse B2
   2. S'entraîner      ✅  Développer un argument
   3. S'entraîner      ←   Nuancer son avis            [Commencer]
   4. Mise en situation    Sujet TCF réel
   5. Évaluation           Vérifier si le niveau a progressé
```

Génération du parcours : 1 étape « Comprendre » (fiche courte), 1 à 2 étapes par compétence en défaut (2 à 3 micro-exercices chacune), 1 simulation de tâche complète, 1 réévaluation.

## 6.4. Recalcul du plan

Déclencheurs : fin d'un micro-exercice, fin d'une simulation de tâche, fin d'un examen blanc, fin d'une réévaluation, changement d'objectif.

Le plan est **matérialisé** (`tcf_plan` + `tcf_plan_item`) avec `plan_version` incrémenté à chaque recalcul, pour pouvoir afficher « ce qui a changé » et pour la cohérence web/mobile.

Règle de stabilité : la priorité n°1 **ne change pas** tant que son parcours n'est pas terminé ou qu'une réévaluation ne l'a pas retirée. Un plan qui change d'avis à chaque exercice détruit la confiance.

---

# 7. Refonte Réviser → Expression écrite / orale

Principe directeur : **Plan = le GPS, Réviser = la bibliothèque.** Deux entrées, un seul système pédagogique.

## 7.1. Niveau 1 — Réviser › Expression écrite

3 cartes de tâche :

```
Expression écrite
« Choisissez une tâche pour vous entraîner. »

Tâche 1 — Message                60–120 mots
Écrire un message simple et clair            12 sujets
Tâche 2 — Récit / expérience     120–150 mots
Raconter, expliquer, décrire                 10 sujets
Tâche 3 — Donner son opinion     150–180 mots     🔴 Prioritaire dans votre plan
Argumenter et organiser ses idées            14 sujets
```

Le badge « Prioritaire dans votre plan » n'apparaît qu'après diagnostic. C'est le lien naturel entre les deux menus.

## 7.2. Niveau 2 — À l'intérieur d'une tâche

Le toggle change de libellé :

`Sujets | Compétences` → **`S'entraîner | Travailler une compétence`**

En-tête commun :

```
Expression écrite — Tâche 3
Donner son opinion et argumenter
150–180 mots · Niveau B1 → B2
```

### Onglet « S'entraîner »

```
[Sujet recommandé]        n'apparaît que si diagnostic disponible
   ⭐ Recommandé pour vous
   « Pensez-vous que le télétravail améliore la qualité de vie ? »
   « Ce sujet vous permettra notamment de travailler votre argumentation. »
   [Commencer]

[Tous les sujets]         liste libre, groupée par thématique
   Vie professionnelle · Réseaux sociaux · Transports · Vie en ville …
```

L'utilisateur doit **toujours** pouvoir choisir librement. On ne ferme jamais la bibliothèque.

### Onglet « Travailler une compétence »

```
[À travailler en priorité]        n'apparaît que si diagnostic disponible
   🔴 Développer ses arguments
      « Apprendre à expliquer et illustrer une idée. »        3 exercices courts
   🟠 Nuancer son opinion
      « Éviter les réponses trop catégoriques. »              3 exercices courts
   🟡 Relier ses idées
      « Utiliser des liens logiques plus naturels. »          2 exercices courts

[Toutes les compétences]          repliées, secondaires
   ✓ Décrire   ✓ Expliquer   ✓ Donner des exemples   ✓ Vocabulaire …
```

Sans diagnostic : pas de section prioritaire, toutes les compétences à plat + encart « Faites votre diagnostic pour savoir par où commencer ».

## 7.3. Niveau 3 — Page d'une compétence

```
[Titre]        Développer ses arguments

[Pourquoi travailler cette compétence ?]
   « Pour atteindre B2 en tâche 3, donner son opinion ne suffit pas.
     Vous devez aussi expliquer pourquoi, développer vos idées et les illustrer. »

[Dans votre diagnostic]        si disponible — bloc le plus percutant
   « Vos arguments étaient compréhensibles, mais souvent trop courts
     pour montrer régulièrement un niveau B2. »
   + extrait réel de sa production

[Entraînement ciblé]           mini-parcours, pas une liste plate
   1. Développer une raison        2–3 min
      « Pourquoi certaines personnes préfèrent-elles travailler à domicile ? »
   2. Ajouter un exemple           3 min
   3. Défendre une opinion         4 min

[Mettre en pratique]
   « Faire une Tâche 3 complète »
```

## 7.4. Expression orale

Structure strictement identique, avec :

- enregistrement audio à la place de la saisie ;
- phase de préparation pilotée **uniquement** par `tcf_task.prep_seconds` : si la valeur est à 0, aucune phase de préparation n'est affichée. Aucune règle de préparation codée en dur par tâche dans l'interface ;
- lecture de son propre enregistrement disponible dans le rapport ;
- transcription affichée dans le rapport (« Ce que nous avons entendu »), avec avertissement qu'elle peut contenir des approximations.

---

# 8. Micro-exercices et rapport IA court

C'est le point le plus sensible : le rapport d'un petit sujet **ne doit pas ressembler** au rapport d'une tâche complète.

## 8.1. Règle cardinale

L'IA juge **la compétence visée**, pas tout ce qu'elle voit. Une faute de conjugaison mineure ne doit jamais voler l'attention sur un exercice qui travaille « développer une raison ». Le prompt l'impose explicitement (§10.4).

## 8.2. Structure imposée du rapport court (6 blocs)

```
[1. Verdict sur la compétence]
   Développer une raison
   🟠 En progression
   « Vous avez donné une raison claire, mais elle reste encore peu développée. »
   ⚠ jamais de niveau CECRL sur un exercice de 2 phrases
   valeurs autorisées : À travailler | En progression | Maîtrisé

[2. Ce qui est réussi]          2 éléments maximum
   ✓ Raison claire — « Vous expliquez que le télétravail permet de gagner du temps. »
   ✓ Réponse pertinente — « Votre réponse répond directement à la question. »

[3. Le point précis à améliorer]      UN seul, jamais une liste
   « Votre raison manque encore de développement. Vous dites que le télétravail
     fait gagner du temps, mais vous n'expliquez pas suffisamment comment. »
   👉 « Après votre raison, ajoutez une conséquence ou un exemple. »

[4. Avant → Après]              indispensable
   Votre réponse :
     « Je préfère travailler à domicile parce que je gagne du temps. »
   Version améliorée :
     « Je préfère travailler à domicile parce que je gagne du temps.
       Par exemple, je n'ai plus besoin de passer une heure dans les transports,
       ce qui me permet de commencer ma journée plus sereinement. »
   surlignage des ajouts, avec étiquettes : raison → exemple → conséquence

[5. À retenir]                  règle courte, réutilisable
   « Pour développer une raison : Idée → Pourquoi ? → Exemple / conséquence »
   « C'est pratique parce que… Par exemple… Cela permet de… »

[6. Prochaine action]           JAMAIS un simple « Retour »
   selon l'état de la compétence :
   - non maîtrisée      → « Essayez encore une fois » + consigne ciblée + [Faire le sujet suivant →]
   - en progression     → « 🎉 Cette compétence progresse » + [Passer au niveau suivant →]
   - maîtrisée          → « ✅ Compétence maîtrisée. Votre prochaine priorité : Nuancer votre opinion »
                          + [Continuer mon plan →]
```

## 8.3. Contrat de rendu et évolutions d'affichage

Le rapport est stocké en JSON conforme à `MicroReport.schema.json` (§10.5), avec `schema_version`.

Le front possède un `MicroReportRenderer` qui **route sur `schema_version`**. Ajouter, retirer ou renommer un bloc affiché =

1. nouvelle version du prompt (`PROMPT_MICRO_EE_v2`) ;
2. `schema_version` incrémentée ;
3. nouveau renderer ajouté, **l'ancien conservé** ;
4. les anciens rapports restent lisibles à l'identique.

Interdiction de migrer d'anciens rapports vers un nouveau schéma : ils ont été produits par un autre prompt, les re-mapper produit des affichages faux.

## 8.4. Mise à jour de l'état de la compétence

Le LLM renvoie un verdict par exercice. Le **moteur** décide de l'état :

```
A_TRAVAILLER   → état par défaut, ou après un verdict « à travailler »
EN_PROGRESSION → 1 verdict « en progression » ou « maîtrisé »
MAITRISEE      → 2 verdicts « maîtrisé » consécutifs sur 2 exercices différents
                 ET validation de la compétence dans une simulation de tâche complète
```

Décroissance : une compétence `MAITRISEE` non revue depuis **30 jours** repasse `EN_PROGRESSION` et peut réapparaître dans le plan.

Une compétence passée `MAITRISEE` est retirée des priorités affichées et déclenche le bloc « Progression détectée » de la page Plan.

---

# 9. Mode dégradé contenu

| Contenu manquant | Comportement |
|---|---|
| Aucun audio CO | Section CO absente du diagnostic, épreuve « non évaluée », exclue du min, aucune priorité CO |
| Aucun sujet EO en base | Section EO absente, même traitement |
| Pas de micro-exercice pour une compétence | L'étape correspondante est remplacée par une simulation de tâche |
| Moins de 15 items CE d'un niveau | Le diagnostic tire ce qui existe et ajuste les dénominateurs ; l'écart est loggé pour l'admin |
| Fiche « Comprendre » absente | L'étape 1 du parcours est ignorée |

Aucun de ces cas ne produit d'erreur visible.

---

# 10. Prompts LLM et contrats de retour

Règles générales : `00_` §8. Tous les prompts sont stockés en base ou en ressources versionnées, jamais en dur dans le code métier.

## 10.1. `PROMPT_QUICK_DIAG_v1`

**System**

```
Tu es examinateur TCF. Tu évalues des productions écrites de candidats étrangers
préparant le TCF IRN. Tu réponds UNIQUEMENT par un objet JSON valide, sans texte
autour, sans balises markdown.

Règles :
- Tu évalues uniquement ce qui est écrit, jamais l'identité ou la situation du candidat.
- Le niveau renvoyé est celui observé SUR CET EXERCICE, pas un niveau TCF officiel.
- L'exercice n'est pas une tâche du TCF : ne reproche jamais au candidat de ne pas
  avoir respecté un format d'épreuve.
- Tu écris tous les textes destinés au candidat en français simple, à la 2e personne
  du pluriel, sans jargon linguistique. Interdits : "cohésion discursive", "morphosyntaxe",
  "connecteurs logiques" employés seuls, tout pourcentage.
- Tu ne donnes jamais de conseil sur la procédure administrative ni sur l'examen lui-même.
```

**User**

```
Objectif du candidat : {target_level}

Consigne donnée au candidat :
{subject_statement}

Capacités que ce sujet permet d'observer : {observation_targets}

Production du candidat ({word_count} mots) :
"""
{production_text}
"""

Il s'agit d'UNE SEULE production transversale, pas d'une tâche du TCF.
N'évalue donc pas le respect d'un format de tâche : évalue les capacités observées.

Renvoie un JSON conforme à ce schéma :
{
  "estimated_level": "A1|A2|B1|B2|C1",
  "confidence": "low|medium|high",
  "context_sentence": "1 à 2 phrases adressées au candidat, expliquant ce qui
                       caractérise son niveau et ce qui manque pour le niveau supérieur",
  "observations": [
    { "type": "strength",     "title": "max 8 mots", "detail": "1 phrase" },
    { "type": "improvement",  "title": "max 8 mots", "detail": "1 phrase" },
    { "type": "improvement",  "title": "max 8 mots", "detail": "1 phrase" }
  ],
  "competence_signals": [
    { "code": "ee_developper|ee_argumenter|ee_nuancer|ee_coherence|ee_lexique|ee_correction_langue|ee_registre|ee_consigne",
      "status": "ACQUIS|FRAGILE|A_TRAVAILLER",
      "evidence": "extrait exact de la production, max 120 caractères" }
  ]
}

Contraintes : exactement 1 "strength" et exactement 2 "improvement".
"competence_signals" contient entre 4 et 8 entrées.
```

**Traitement** : seuls `estimated_level`, `context_sentence` et `observations` sont affichés. `competence_signals` alimente l'aperçu des priorités (bloc 5) et sera écrasé par le diagnostic complet.

## 10.2. `PROMPT_EE_TASK_v1`

**System** : identique au précédent, plus :

```
Tu évalues une tâche d'expression écrite du TCF IRN. Tu connais les descripteurs CECRL.
Tu justifies chaque statut de compétence par un extrait EXACT de la production.
Si la production ne respecte pas la consigne (hors sujet, longueur très insuffisante),
tu le signales via "off_task": true et tu plafonnes le niveau à A2.
```

**User**

```
Tâche : {task_code} — {task_label}
Consigne donnée au candidat : {subject_statement}
Longueur attendue : {min_words}–{max_words} mots
Niveau visé par le candidat : {target_level}
Compétences à évaluer : {competence_codes_with_labels}

Production du candidat ({word_count} mots) :
"""
{production_text}
"""

Renvoie un JSON conforme à :
{
  "task_level": "A1|A2|B1|B2|C1",
  "off_task": false,
  "summary_for_candidate": "2 phrases maximum, ce qui caractérise cette production",
  "competences": [
    { "code": "...", "status": "ACQUIS|FRAGILE|A_TRAVAILLER",
      "comment": "1 phrase en langage candidat",
      "evidence": "extrait exact, max 120 caractères" }
  ],
  "top_improvement": {
    "competence_code": "...",
    "what": "1 phrase : le problème",
    "how": "1 phrase : l'action concrète à faire la prochaine fois"
  },
  "improved_excerpt": {
    "original": "un passage exact de la production, 1 à 2 phrases",
    "improved": "le même passage réécrit au niveau visé",
    "added_elements": ["exemple", "conséquence", "nuance"]
  }
}
Une entrée "competences" par compétence demandée, ni plus ni moins.
```

## 10.3. `PROMPT_EO_TASK_v1`

Identique à EE, avec en amont une **transcription** (Whisper ou équivalent) et ces différences :

- l'entrée est la transcription + la durée réelle + le nombre de mots par minute ;
- ajout des compétences `eo_fluidite` et `eo_interaction` ;
- consigne au modèle :

```
La production vient d'une transcription automatique. Ignore la ponctuation et les
approximations orthographiques : elles proviennent de la transcription, pas du candidat.
N'évalue jamais l'orthographe. Les hésitations et répétitions sont normales à l'oral :
ne les pénalise que si elles empêchent la compréhension.
```

- champ supplémentaire dans la réponse : `"speech_rate_comment"` (1 phrase, uniquement si le débit est très bas ou très élevé, sinon `null`).

## 10.4. `PROMPT_MICRO_EE_v1` (le plus important)

**System**

```
Tu corriges un MICRO-EXERCICE. Ce n'est pas une tâche complète du TCF.
Tu évalues UNE SEULE compétence : {competence_label}.

Règles impératives :
- Tu ne commentes AUCUN autre aspect que cette compétence. Une faute de conjugaison,
  d'orthographe ou de vocabulaire ne doit pas être mentionnée si elle n'empêche pas
  la compétence visée d'être évaluée.
- Tu ne donnes JAMAIS de niveau CECRL. La production est trop courte.
- Tu écris en français simple, 2e personne du pluriel, sans jargon.
- Tu réponds uniquement par un JSON valide, sans texte autour.
- La "version améliorée" doit rester proche de la production du candidat : tu
  l'enrichis, tu ne la réécris pas entièrement. Le candidat doit reconnaître ses mots.
```

**User**

```
Compétence travaillée : {competence_code} — {competence_label}
Objectif de l'exercice : {exercise_goal}
Consigne : {exercise_statement}
Réponse du candidat :
"""
{production_text}
"""

Renvoie un JSON conforme à :
{
  "verdict": "A_TRAVAILLER|EN_PROGRESSION|MAITRISE",
  "verdict_sentence": "1 phrase adressée au candidat, expliquant le verdict",
  "strengths": [
    { "title": "max 5 mots", "detail": "1 phrase citant ce que le candidat a fait" }
  ],
  "main_improvement": {
    "what": "1 à 2 phrases : le point précis à améliorer, uniquement sur la compétence visée",
    "action": "1 phrase impérative, très concrète, commençant par un verbe"
  },
  "before_after": {
    "original": "la réponse du candidat, ou l'extrait pertinent",
    "improved": "la même réponse enrichie",
    "added_labels": ["raison", "exemple", "conséquence", "nuance", "connecteur"]
  },
  "rule_to_remember": {
    "title": "max 8 mots",
    "formula": "schéma court, ex : Idée → Pourquoi ? → Exemple",
    "example": "1 exemple de phrase type"
  }
}
"strengths" contient 1 ou 2 entrées, jamais plus.
"added_labels" ne contient que des étiquettes présentes dans "improved".
```

**Le bloc 6 (prochaine action) n'est PAS généré par le LLM.** Il est construit par le moteur à partir du verdict et de l'état de la compétence. C'est une décision produit, pas une évaluation.

## 10.5. `MicroReport.schema.json` (extrait)

```json
{
  "type": "object",
  "required": ["schema_version","verdict","verdict_sentence","strengths",
               "main_improvement","before_after","rule_to_remember"],
  "properties": {
    "schema_version": { "const": 1 },
    "verdict": { "enum": ["A_TRAVAILLER","EN_PROGRESSION","MAITRISE"] },
    "strengths": { "type": "array", "minItems": 1, "maxItems": 2 },
    "before_after": {
      "type": "object",
      "required": ["original","improved","added_labels"]
    }
  }
}
```

Validation stricte à la réception. Non conforme → 1 relance avec l'erreur, puis échec propre (§`00_` 8.2).

## 10.6. `PROMPT_MICRO_EO_v1`

Identique à 10.4, avec l'avertissement transcription de 10.3 et l'interdiction d'évaluer l'orthographe.

## 10.7. Génération de contenu (admin uniquement)

`PROMPT_GEN_MICRO_EXERCISES_v1` : à partir d'une compétence et d'une tâche, propose 5 micro-exercices (consigne, objectif, durée, réponse attendue type). Sortie **toujours en brouillon**, jamais publiée sans validation humaine. Source `ADMIN_CONTENT`.

---

# 11. Modèle de données

Noms indicatifs, à aligner sur les conventions relevées dans `AUDIT.md`.

```
tcf_task
  id, epreuve (CO|CE|EE|EO), code (EE1..EO3), label_user, min_words, max_words,
  duration_seconds, max_duration_seconds, prep_seconds, order, active
  -- max_duration_seconds : plafond audio EO par tâche (180 / 210 / 210). Pas de constante globale.

quick_diag_subject
  id, statement, min_words, max_words, observation_targets(text[]), active

tcf_competence
  id, epreuve, code, label_user, description_user, order, active

tcf_task_competence
  task_id, competence_id, is_default_active

tcf_subject                       -- sujets de tâche complète
  id, task_id, statement, context, theme_label, difficulty, media_id, active

tcf_micro_exercise                -- petits sujets
  id, competence_id, task_id, statement, goal, expected_elements(jsonb),
  duration_seconds, order, difficulty, active, status(DRAFT|PUBLISHED)

tcf_production                    -- toute production du candidat
  id, user_id, client_submission_id, kind(TASK|MICRO), task_id, subject_id,
  micro_exercise_id, text, audio_media_id, transcript, word_count,
  duration_seconds, context(DIAGNOSTIC|TRAINING|SIMULATION), created_at

tcf_ai_report
  id, production_id, prompt_id, prompt_version, schema_version, model,
  payload(jsonb), verdict, task_level, tokens_in, tokens_out, cost_cents, created_at

user_tcf_competence_state
  user_id, competence_id, task_id, status(A_TRAVAILLER|EN_PROGRESSION|MAITRISEE),
  consecutive_mastered, last_evaluated_at, mastered_at, updated_at

tcf_diagnostic
  id, user_id|anon_id, type(QUICK|FULL), status(IN_PROGRESS|COMPLETED|EXPIRED),
  target_level, exam_date, started_at, completed_at, expires_at

tcf_diagnostic_section
  diagnostic_id, epreuve, status, score_raw, level_computed, completed_at

tcf_diagnostic_result
  diagnostic_id, level_global, level_co, level_ce, level_ee, level_eo,
  context_sentence, payload(jsonb), computed_at

tcf_plan
  id, user_id, target_level, plan_version, computed_at, next_item_id

tcf_plan_item
  id, plan_id, rank, kind(PRIORITY), epreuve, task_id, current_level, target_level,
  reason_text, evidence_excerpt, status, priority_score

tcf_plan_step
  id, plan_item_id, order, kind(UNDERSTAND|MICRO|SIMULATION|REEVALUATION),
  competence_id, micro_exercise_id, subject_id, status(TODO|DONE|SKIPPED),
  completed_at

ai_usage
  id, user_id, source, prompt_id, prompt_version, model,
  tokens_in, tokens_out, cost_cents, success, created_at
```

Contraintes à poser explicitement :

- unicité `tcf_diagnostic(user_id, type=FULL)` pour les comptes gratuits ;
- unicité `tcf_production(client_submission_id)` — idempotence ;
- index sur `user_tcf_competence_state(user_id, status)`.

---

# 12. API

```
POST   /api/v1/tcf/diagnostics/quick                 { target_level, exam_date? } → { diagnostic_id, subject }
PUT    /api/v1/tcf/diagnostics/quick/{id}/draft      { text }                    -- sauvegarde continue, anonyme
POST   /api/v1/tcf/diagnostics/quick/{id}/submit     { text, client_submission_id }
                                                     -- persiste SANS déclencher le LLM
POST   /api/v1/tcf/diagnostics/quick/{id}/analyze    -- authentifié uniquement ; déclenche le LLM
                                                     -- rattache anon_id → user_id
GET    /api/v1/tcf/diagnostics/quick/{id}/result     → écran §3.6

POST   /api/v1/tcf/diagnostics/full                  → { diagnostic_id, sections[] }
GET    /api/v1/tcf/diagnostics/full/{id}/view        → état des sections, reprise
POST   /api/v1/tcf/diagnostics/full/{id}/sections/{epreuve}/start
POST   /api/v1/tcf/diagnostics/full/{id}/sections/{epreuve}/submit
GET    /api/v1/tcf/diagnostics/full/{id}/result/view → écran §4.5

GET    /api/v1/tcf/plan/view                         → écran §6.1 ou §6.2 selon droits
GET    /api/v1/tcf/plan/items/{itemId}/view          → écran §6.3
POST   /api/v1/tcf/plan/recompute                    (interne / admin)

GET    /api/v1/tcf/revise/ee                         → §7.1
GET    /api/v1/tcf/revise/tasks/{taskCode}/view      → §7.2, onglets et badges inclus
GET    /api/v1/tcf/revise/competences/{code}/view    → §7.3

POST   /api/v1/tcf/productions                       { kind, subject_id|micro_exercise_id, text|audio, client_submission_id }
GET    /api/v1/tcf/productions/{id}/report           → rapport avec schema_version

GET    /api/v1/entitlements                          → quotas restants par source
GET    /api/v1/paywall/view?context=...              → §5, personnalisé
```

Toute réponse « view » contient `locked` et `lock_reason` par bloc, `computed_at`, `plan_version` le cas échéant.

---

# 13. Tests attendus

**Moteur**

- [ ] calcul de niveau CO/CE aux frontières exactes des seuils ;
- [ ] `niveau_épreuve = min(3 tâches)` en EE comme en EO ;
- [ ] aucune priorité ne peut nommer une tâche non évaluée (test de garde) ;
- [ ] `niveau_global = min(épreuves évaluées)`, épreuve non évaluée exclue ;
- [ ] tri des priorités, égalité tranchée EO > EE > CE > CO ;
- [ ] aucune priorité générée sur une épreuve déjà au niveau cible ;
- [ ] priorité n°1 stable tant que son parcours n'est pas terminé ;
- [ ] passage `EN_PROGRESSION` → `MAITRISEE` uniquement avec 2 verdicts + simulation ;
- [ ] décroissance à 30 jours.

**Diagnostic rapide**

- [ ] la production est persistée avant l'écran de création de compte et survit à un abandon ;
- [ ] aucun appel LLM n'est déclenché avant authentification ;
- [ ] rattachement `anon_id → user_id` correct à l'inscription comme à la connexion ;
- [ ] production sous 100 mots : message dédié, aucun appel LLM, aucun quota consommé ;
- [ ] l'aperçu des priorités (bloc 5) ne nomme jamais une tâche TCF.

**Quotas**

- [ ] un diagnostic complet ne décrémente pas les essais EE/EO gratuits ;
- [ ] 2e diagnostic complet refusé en gratuit, message correct ;
- [ ] échec LLM → quota non décrémenté ;
- [ ] rejeu du même `client_submission_id` → même rapport, pas de 2e appel LLM.

**IA**

- [ ] réponse non conforme au schéma → 1 relance puis échec propre ;
- [ ] production hors sujet → `off_task: true` et niveau plafonné ;
- [ ] rapport `schema_version: 1` toujours affichable après passage en v2.

**Mode dégradé**

- [ ] diagnostic sans CO : résultat cohérent, aucune priorité CO, aucun message d'erreur ;
- [ ] compétence sans micro-exercice : le parcours saute à la simulation.

**Parité**

- [ ] pour chaque écran du §3 au §7, un test de rendu web et mobile vérifiant le même inventaire de blocs dans le même ordre.
