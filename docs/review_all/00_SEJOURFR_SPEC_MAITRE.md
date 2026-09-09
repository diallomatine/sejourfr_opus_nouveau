# SejourFR — Spécification maître

> **Statut** : spécification de référence pour la refonte « Diagnostic → Plan → Entraînement ciblé ».
> **Documents liés** :
> - `10_SEJOURFR_TCF.md` — module TCF IRN (diagnostics, paywall, plan, Réviser EE/EO, micro-exercices, prompts IA)
> - `20_SEJOURFR_CIVIQUE.md` — module Examen civique (notions, diagnostic, plan, révision, examens blancs)
> - `30_SEJOURFR_ECRANS.md` — inventaire complet des écrans, états standards, navigation, matrice de parité
> - `40_SEJOURFR_AUDIT.md` — photographie mesurée du dépôt réel
> - `50_SEJOURFR_CORRECTIFS.md` — **rectifications après audit ; fait autorité sur tous les autres**
>
> **Ordre de lecture pour Claude Code** : ce document → `10_` → `20_` → `30_` → `40_` → `50_`.
>
> ⚠ **Plusieurs hypothèses de ce document sont fausses** (web en Angular, EE/EO non modélisés,
> abonnement mensuel). Elles sont corrigées une par une dans `50_`. Ne jamais appliquer une section
> de ce document sans avoir vérifié qu'elle n'y est pas rectifiée.
> **Ordre d'implémentation** : PHASE 0 (audit) → TCF → Civique.

---

# 0. Comment utiliser ces documents

1. Claude Code exécute d'abord la **PHASE 0 — AUDIT** (§2). Il ne produit **aucun code** à ce stade, uniquement `AUDIT.md`.
2. L'audit est relu et validé humainement.
3. Les specs sont alors ajustées si l'audit révèle des écarts (nommage, tables existantes, contraintes).
4. L'implémentation démarre lot par lot (§14), TCF d'abord.

Règle permanente : **aucune règle pédagogique n'est codée dans le front**. Niveaux, priorités, états de maîtrise, quotas, déblocages sont calculés côté backend et exposés tels quels. Le web et le mobile n'affichent que ce que l'API renvoie.

---

# 1. Contexte et écart à combler

## 1.1. Ce que fait l'application aujourd'hui

- Deux modules : **TCF IRN** (CO / CE / STRUCTURE) et **Examen civique** (5 thèmes, 3 mentions CSP / CR / NAT).
- Logique de **catalogue** : séries de QCM, examens blancs, favoris, révision des erreurs.
- Banque TCF : questions CE et STRUCTURE calibrées A2/B1/B2, avec `competence_code`. **CO, EE et EO ne sont pas encore modélisés.**
- Civique : questions rattachées à un **thème** uniquement. Il n'existe **aucune notion** en base.
- Non abonné : **1 correction IA en EE** et **1 correction IA en EO**.
- Web (Angular) et mobile (Flutter) fonctionnent **entièrement en ligne**, avec un comportement identique.

## 1.2. Ce que la refonte introduit

| Élément | Statut |
|---|---|
| Diagnostic écrit rapide | **Nouveau** |
| Diagnostic TCF complet (4 épreuves) | **Nouveau** |
| Modèle EE / EO (tâches, sujets, compétences, productions, rapports IA) | **Nouveau** |
| Moteur de plan TCF | **Nouveau** |
| Micro-exercices de compétence + rapport IA court | **Nouveau** |
| Paywall contextualisé | **Nouveau** (remplace le paywall générique) |
| Référentiel de **notions** civiques + tagging du catalogue | **Nouveau — chantier de contenu, pas seulement de code** |
| Diagnostic civique | **Nouveau** |
| Moteur de plan civique + répétition espacée | **Nouveau** |
| Quotas séparés diagnostic / entraînement | **Nouveau** |
| Thèmes civiques, mentions, examens blancs, banque CE/STRUCTURE | **Existant — à conserver** |

## 1.3. Le vrai risque du projet

Le risque principal n'est pas technique, il est **éditorial** :

- il faut créer un référentiel de notions civiques puis re-tagger tout le catalogue de questions ;
- il faut créer la banque de sujets EE et EO (3 tâches × 3 niveaux) et les micro-exercices par compétence ;
- il faut produire les audios CO.

Les specs prévoient donc systématiquement un **mode dégradé** qui fonctionne quand le contenu n'est pas encore complet (voir §7.4, `10_` §9, `20_` §3.4).

---

# 2. PHASE 0 — AUDIT (à exécuter en premier)

## 2.1. Brief à donner à Claude Code

> Avant toute implémentation, réalise un audit complet du code existant et produis un unique fichier `AUDIT.md` à la racine du dépôt.
>
> **Ne modifie aucun fichier de code. Ne crée aucune migration. Ne propose aucun refactoring dans cette phase.**
>
> Objectif : établir la photographie exacte de l'existant afin que les specs `10_SEJOURFR_TCF.md` et `20_SEJOURFR_CIVIQUE.md` soient adaptées au code réel plutôt que l'inverse.

## 2.2. Plan imposé de `AUDIT.md`

```
1. Inventaire technique
   1.1 Versions (Java, Spring Boot, Angular, Flutter, PostgreSQL, Flyway)
   1.2 Modules / packages backend et leur responsabilité
   1.3 Structure du front Angular (routes, feature modules, state)
   1.4 Structure de l'app Flutter (routes, couche données, cache éventuel)
   1.5 Dernière migration Flyway appliquée + convention de nommage

2. Modèle de données existant
   2.1 Tables réelles + colonnes + index (extrait du schéma, pas de l'ERD théorique)
   2.2 Écarts constatés entre l'ERD du projet et la base réelle
   2.3 Table Question : colonnes exactes, valeurs distinctes de module / question_type /
       difficulty / competence_code / theme_id, volumétrie par croisement
   2.4 Attempt / AttemptQuestion / Answer : quels contextes sont déjà distingués,
       comment un examen blanc se distingue d'une série
   2.5 UserQuestionStatus : ce qui est stocké, ce qui ne l'est pas
   2.6 Plan / UserSubscription / Plan tarifaire : état exact du modèle d'abonnement

3. Volumétrie de contenu (requêtes SQL + résultats)
   3.1 TCF : nb de questions par question_type × difficulty × competence_code
   3.2 TCF : nb de passages, nb de médias (url vs inline_svg), audios CO existants
   3.3 Civique : nb de questions par thème × mention
   3.4 Civique : nb de questions ayant une explication non vide
   3.5 Civique : les questions distinguent-elles déjà connaissances vs mise en situation ?
       Si oui comment, si non quel signal permettrait de les séparer
   3.6 Examens blancs : templates existants et règles de tirage

4. Fonctionnalités IA existantes
   4.1 Où et comment les appels LLM sont déclenchés (service, provider, modèle)
   4.2 Prompts actuels (copiés intégralement dans l'audit)
   4.3 Format de réponse attendu et parsing
   4.4 Où est stocké le résultat d'une correction IA
   4.5 Comment le quota gratuit 1 EE / 1 EO est implémenté aujourd'hui
   4.6 Coût moyen observé par correction si mesurable

5. Expression écrite / orale existantes
   5.1 Que peut faire un utilisateur aujourd'hui en EE et en EO
   5.2 Modèle de données associé s'il existe
   5.3 Workflow audio EO : enregistrement, upload, stockage, transcription

6. Écrans existants (web et mobile)
   6.1 Arborescence des écrans Réviser / Examens / Progrès / Profil
   6.2 Pour chaque écran : existe en web ? en mobile ? divergences constatées
   6.3 Composants réutilisables du design system et tokens de couleur réels
   6.4 Comment la navigation par onglets est gérée

7. Écarts web / mobile
   7.1 Fonctionnalités présentes d'un côté seulement
   7.2 Endpoints appelés par l'un et pas par l'autre
   7.3 Duplication de logique métier côté client (à signaler, ne pas corriger)

8. Points de blocage identifiés pour la refonte
   Pour chaque point : description, impact, options, recommandation

9. Estimation d'effort par lot (§14 de la spec maître)
   Tableau : lot / complexité (S/M/L/XL) / dépendances / risques

10. Questions ouvertes nécessitant un arbitrage produit
```

## 2.3. Règles pour l'audit

- Toute affirmation sur le contenu de la base est **accompagnée de la requête SQL** utilisée.
- Aucun chiffre estimé : soit mesuré, soit marqué `non mesurable, raison :`.
- Les prompts LLM existants sont recopiés **intégralement**.
- Les écarts entre l'ERD documenté et la base réelle sont listés explicitement.
- Longueur cible : 400 à 800 lignes. Pas de code d'implémentation.

## 2.4. Critères d'acceptation de la phase 0

- [ ] `AUDIT.md` existe et suit le plan imposé.
- [ ] Aucun autre fichier n'a été créé ou modifié.
- [ ] Les 10 sections sont remplies.
- [ ] Les volumétries §3 sont chiffrées avec requêtes.
- [ ] La section 8 propose une recommandation par blocage.

---

# 3. Arbitrages produits (tranchés)

| # | Question | Décision | Justification |
|---|---|---|---|
| A1 | Format du diagnostic rapide | **Une seule production écrite, sur un sujet transversal** (150–220 mots, 8–10 min) qui n'est ni EE1, ni EE2, ni EE3 | Donne assez de matière à l'IA sans reproduire artificiellement une tâche du TCF, et sans ressembler à un premier examen |
| A2 | Le diagnostic complet est-il un examen blanc intégral ? | **Non, mais les 3 tâches EE et les 3 tâches EO sont toutes évaluées.** Seules CO et CE sont réduites (15 items chacune). ~75 min, séquencé en 4 sections reprenables. L'examen blanc intégral en conditions réelles reste un objet distinct | Le plan raisonne par tâche : nommer « EO tâche 2 » comme priorité sans avoir évalué EO2 rendrait la personnalisation fictive. On réduit la compréhension, jamais la production |
| A3 | Le diagnostic complet est-il gratuit ? | **Oui, une fois**, quota séparé des essais IA d'entraînement | C'est l'outil de vente principal, son coût est un coût d'acquisition |
| A4 | Compte obligatoire ? | **Rédaction du diagnostic rapide sans compte ; compte obligatoire pour obtenir le résultat.** L'appel LLM n'est déclenché qu'après création du compte | La personne a déjà investi 10 min et veut son résultat : meilleur moment pour demander un compte, et on ne paie pas les diagnostics abandonnés |
| A5 | Unité visible du plan | **Épreuve → Tâche** (TCF) / **Thème → Notion** (civique). Les compétences fines restent internes | Compréhensible par le candidat |
| A6 | Nombre de compétences visibles | **3 maximum par tâche**, **3 priorités maximum** sur la page Plan | Évite le mur de 8 compétences |
| A7 | Niveau global TCF affiché | **Le plus bas des 4 épreuves** | Au TCF IRN le niveau requis doit être atteint dans chaque épreuve : c'est factuellement juste et cela justifie naturellement le plan |
| A8 | STRUCTURE dans le plan | **Jamais comme priorité.** Proposée en renfort secondaire sous une priorité CO ou CE | Pas une épreuve IRN |
| A9 | Mention civique | **Tout le parcours civique est scopé par mention (CSP / CR / NAT)** : diagnostic, plan, examens | Périmètre et exigence diffèrent |
| A10 | Mises en situation civiques | **Type de question distinct**, rattaché à un *domaine de situation* et non à une notion factuelle. Représentées à ~30 % du diagnostic | 12 sur 40 à l'examen réel |
| A11 | Mémorisation civique | **Répétition espacée (Leitner 5 boîtes)** intégrée au plan | C'est ce qui crée la valeur sur du factuel |
| A12 | Seuils de maîtrise | **Chiffrés dans les specs**, centralisés backend, exposés en configuration | Sinon incohérence entre modules |
| A13 | Plans TCF et civique | **Deux moteurs séparés**, segmented control partout, accueil qui agrège | Mécaniques pédagogiques différentes |
| A14 | Tarif | Garder **14,99 €/mois** et **ajouter un pack 3 mois** | Public à échéance d'examen bornée ; à valider par test |
| A15 | Offline | **Online-first conservé.** Les specs prévoient les crochets (versionnement, idempotence) mais l'offline n'est pas dans le périmètre | L'app est aujourd'hui 100 % en ligne |

**Seul arbitrage restant à confirmer** : A14, le prix du pack 3 mois. Tous les autres sont tranchés et ne doivent pas être rouverts par l'implémentation.

---

# 4. Parcours cible

## 4.1. TCF

```
Découverte
   └─ Diagnostic écrit rapide : 1 sujet transversal, 150–220 mots (~10 min, sans compte)
        └─ « Valider mon diagnostic »
             └─ Création de compte  ← l'analyse IA est déclenchée ICI
                  └─ Résultat intégralement visible, aucun paywall
                       └─ CTA : « Faire mon diagnostic TCF complet »
                            └─ Diagnostic TCF complet, gratuit une fois
                               (~75 min, 4 sections reprenables, EE1-2-3 et EO1-2-3 évaluées)
                                 └─ Résultat intégralement visible : niveau par épreuve + 3 priorités
                                      └─ CTA : « Découvrir mon plan B2 »
                                           └─ Plan version gratuite (priorités visibles, accompagnement verrouillé)
                                                └─ Paywall contextualisé
                                                     └─ Plan Premium → entraînements ciblés → réévaluation → plan
```

## 4.2. Civique

```
Choix de la mention (CSP / CR / NAT)
   └─ Diagnostic civique gratuit une fois (20-25 questions, ~15 min)
        └─ Résultat : score, niveau par thème, notions faibles, priorités
             └─ Plan civique version gratuite
                  └─ Paywall
                       └─ Plan Premium → questions ciblées par notion → révision espacée → examen blanc → plan mis à jour
```

## 4.3. Règle de conversion commune

Ne jamais enchaîner `résultat → liste de fonctionnalités → abonnement`.
Toujours enchaîner `résultat → cause du blocage → le plan existe déjà → abonnement pour l'exécuter`.

---

# 5. Principes pédagogiques transverses

## 5.1. Visible vs moteur

| Niveau | TCF | Civique | Visible par l'utilisateur |
|---|---|---|---|
| 1 | Épreuve | Thème | Oui |
| 2 | Tâche | Notion | Oui |
| 3 | Compétence | — | Partiellement (3 max, en langage simple) |
| 4 | Micro-exercice | Question ciblée | Oui, à l'intérieur du niveau 2 |
| 5 | Simulation / examen blanc | Examen blanc | Oui |
| 6 | Réévaluation | Réévaluation | Oui, sous forme de progression |

## 5.2. Traduction obligatoire

Aucun libellé technique n'est affiché tel quel. Table de correspondance maintenue en base (`competence.label_user`), jamais en dur dans le front.

| Interne | Affiché |
|---|---|
| `ee_argumenter` | Développer vos arguments |
| `ee_nuancer` | Nuancer votre opinion |
| `ee_coherence` | Mieux relier vos idées |
| `cohesion_score = 0.63` | *jamais affiché* |

## 5.3. Interdits d'affichage

- Pourcentage de progression vers un niveau CECRL sans formule documentée.
- Niveau CECRL attribué à une production de moins de 40 mots.
- Plus de 3 priorités simultanées.
- Plus de 3 compétences actives par tâche.
- Une correction qui se termine sans action suivante proposée.

---

# 6. Parité web / mobile

## 6.1. Règle de parité

**Tout écran spécifié dans `10_` et `20_` existe en Angular et en Flutter**, avec :

- le même inventaire de blocs, dans le même ordre ;
- les mêmes textes (source unique de traduction, voir §6.3) ;
- les mêmes états (chargement, vide, erreur, verrouillé) ;
- les mêmes événements analytics.

Divergences autorisées, et **seulement** celles-ci :

| Sujet | Web | Mobile |
|---|---|---|
| Navigation | barre latérale ou header | bottom nav 5 onglets |
| Enregistrement audio EO | MediaRecorder | plugin natif |
| Paiement | Stripe Checkout web | achat in-app si requis par le store, sinon web |
| Largeur | conteneur centré max 480 px sur les écrans du tunnel | plein écran, référence 390 px |

Le tunnel diagnostic → paywall → plan est conçu **mobile-first** et rendu en colonne unique max 480 px sur web. Aucune version « desktop enrichie » de ces écrans.

## 6.2. Aucune logique métier côté client

Sont interdits côté Angular et Flutter :

- calcul d'un niveau CECRL ;
- calcul d'une priorité ou d'un ordre de priorités ;
- décision de verrouillage Premium (le backend renvoie `locked: true` + `lock_reason`) ;
- décrément d'un quota ;
- seuil de maîtrise.

Le backend expose des **vues prêtes à afficher** (§6.4).

## 6.3. Textes

Les textes produits par l'IA (observations, verdicts, conseils) arrivent dans la réponse API.
Les textes d'interface sont dans un fichier de traduction unique par plateforme, généré depuis une **source commune** `i18n/fr.json` versionnée dans le dépôt backend et copiée à la build. Aucun texte du tunnel n'est écrit en dur dans un composant.

## 6.4. Endpoints orientés écran — et leur limite

Pour chaque écran du tunnel, **un endpoint unique** renvoie les **données de décision** dont l'écran a besoin, en une fois :

```
GET /api/v1/tcf/plan
→ { target_level, current_level, next_action, week_progress, priorities[],
    achieved[], recent_change, entitlements: { locked: [...] },
    plan_version, computed_at }
```

Ce que le backend décide, et lui seul : les niveaux, l'ordre et le contenu des priorités,
quelle est la prochaine action, ce qui est verrouillé et pourquoi, les états de maîtrise,
les quotas, les textes générés par l'IA.

Ce que le backend **ne fait pas** : dicter la mise en page. Il ne renvoie ni ordre de blocs,
ni titres de sections, ni structure de header. **Angular et Flutter possèdent le rendu.**
L'ordre des blocs décrit dans `10_` et `20_` est une spec de conception que les deux clients
implémentent, pas un contrat d'API.

C'est cette frontière qui garantit la parité sans transformer le backend en moteur de gabarits.

## 6.5. Crochets offline (non implémentés maintenant)

À prévoir dès maintenant, sans travail supplémentaire notable :

- toute vue renvoie `computed_at` et une `etag` ;
- toute soumission (réponse QCM, production EE, audio EO) porte un `client_submission_id` (**UUID généré par le client, obligatoire**) et l'API est **idempotente** sur cet identifiant ;
- les identifiants d'entités **suivent la convention déjà en place dans le dépôt** (voir `AUDIT.md` §2.1). Ne pas migrer un schéma existant vers des UUID pour cette refonte : seul `client_submission_id` doit être un UUID.

---

# 7. Freemium, quotas et droits d'accès

## 7.1. Matrice

| Fonction | Gratuit | Premium |
|---|---|---|
| Diagnostic écrit rapide | rédaction libre, **1 analyse** (compte requis pour le résultat) | illimité |
| Diagnostic TCF complet | **1** | réévaluations selon règles |
| Diagnostic civique | **1** | réévaluations |
| Résultat des diagnostics | **intégral, consultable à vie** | idem |
| Aperçu du plan (objectif, 3 priorités, 1re étape) | oui | oui |
| Entraînement EE corrigé par IA | 1 | illimité selon fair use |
| Entraînement EO corrigé par IA | 1 | illimité selon fair use |
| Micro-exercices de compétence | non | oui |
| Parcours d'une priorité, réévaluation, adaptation du plan | non | oui |
| Séries QCM civiques et examens blancs | règles existantes conservées | oui |

## 7.2. Sources de consommation

Un enregistrement `ai_usage` par appel LLM, avec `source` :

```
DIAGNOSTIC_QUICK
DIAGNOSTIC_FULL_EE
DIAGNOSTIC_FULL_EO
FREE_EE_TRAINING
FREE_EO_TRAINING
PREMIUM_TRAINING
PREMIUM_MICRO_EXERCISE
ADMIN_CONTENT
```

Règle absolue : les appels `DIAGNOSTIC_*` **ne décrémentent jamais** `FREE_EE_TRAINING` ni `FREE_EO_TRAINING`.

## 7.3. Fair use Premium

Plafond souple par compte et par jour (valeur initiale : **40 corrections IA / jour**, dont 25 micro-exercices). Au-delà : message « Vous avez beaucoup travaillé aujourd'hui, revenez demain » — pas d'erreur technique. Valeur configurable.

## 7.4. Mode dégradé contenu

Chaque écran doit fonctionner quand le contenu manque :

- pas d'audio CO → le diagnostic complet s'exécute sans section CO, le résultat affiche `Compréhension orale : non évaluée` et le plan n'en fait pas une priorité ;
- pas de notion civique taguée → le plan travaille au niveau **thème** ;
- pas de micro-exercice pour une compétence → l'étape propose directement une simulation de tâche.

Le mode dégradé n'est **jamais** une erreur affichée à l'utilisateur.

---

# 8. Contrats LLM (règles générales)

Les prompts détaillés sont dans `10_` §10 et `20_` §9. Les règles ci-dessous s'appliquent à tous.

## 8.1. Versionnement

Chaque prompt a un identifiant et une version : `PROMPT_EE_TASK_v1`, `PROMPT_MICRO_EE_v1`…
Chaque rapport stocké porte `prompt_id`, `prompt_version`, `model`, `schema_version`, `raw_response`.

Conséquence directe, et c'est le point important : **quand l'affichage change, on incrémente `schema_version` et on garde le rendu de l'ancienne version**. Un rapport produit en v1 doit rester lisible après le passage en v2. Le front possède un `ReportRenderer` qui route sur `schema_version`.

## 8.2. Sortie

- Réponse **strictement JSON**, aucun texte hors JSON, aucun bloc markdown.
- Schéma validé côté backend (JSON Schema). Réponse non conforme → **1 seule relance** avec le message d'erreur de validation, puis échec propre.
- Échec propre = la production est enregistrée, l'utilisateur voit « Votre correction n'a pas pu être générée, elle sera réessayée », le quota **n'est pas** décrémenté, un job de reprise est planifié.

## 8.3. Garde-fous

- Longueur maximale d'entrée par production : 1 500 caractères en EE ; en EO, la durée maximale est **définie par tâche** (`tcf_task.max_duration_seconds` : 180 s pour EO1, 210 s pour EO2 et EO3). Aucun plafond audio global codé en dur.
- Le prompt reçoit **uniquement** la production, la consigne et la compétence visée. Jamais l'identité de l'utilisateur.
- Les niveaux CECRL renvoyés sont contraints à l'énumération `A1, A2, B1, B2, C1`.
- Le modèle ne décide jamais d'un déblocage, d'un quota ou d'une priorité : il **décrit**, le moteur **décide**.
- Température basse (0.2) pour les évaluations, plus haute (0.7) uniquement pour la reformulation « version améliorée ».

## 8.4. Coût

Chaque `ai_usage` stocke tokens entrée/sortie et coût estimé. Tableau de bord admin : coût par source, coût moyen d'un diagnostic complet, coût d'acquisition par abonné.

---

# 9. Design system

Rappel des tokens, à confronter aux valeurs réelles trouvées à l'audit (§6.3 de `AUDIT.md`).

| Token | Valeur |
|---|---|
| `--bleu-france` | `#1E3A8C` |
| `--bleu-fonce` | `#15296B` |
| `--bleu-clair` | `#E8ECF8` |
| `--rouge-france` | `#E1372F` |
| `--rouge-fonce` | `#B5251E` |
| `--rouge-clair` | `#FDECEB` |
| `--encre` | `#0F1839` |
| `--succes` | `#168F5B` |
| `--ambre` | `#E8A317` |

Typographies : Plus Jakarta Sans (corps), JetBrains Mono (labels techniques), Fraunces (moments éditoriaux — réservée aux grands nombres de niveau type `B1`).

Sémantique de couleur, non négociable :

- **rouge** = priorité 1 uniquement, jamais « erreur » dans un contexte pédagogique ;
- **ambre** = priorité 2 et 3, état « en progression » ;
- **vert** = objectif atteint, compétence maîtrisée ;
- **bleu** = action principale, identité ;
- gris = verrouillé, secondaire.

Composants communs à créer une fois et à partager entre les écrans du tunnel :

`LevelBadge`, `LevelGauge` (A2 — B1 — B2), `PriorityCard`, `LockedRow`, `StepList`, `ObservationRow`, `StickyCta`, `SegmentedControl`, `BeforeAfterBlock`.

---

# 10. Wording et CTA

CTA autorisés, contextualisés avec le niveau cible réel de l'utilisateur :

```
Faire mon diagnostic complet
Découvrir mon plan {cible}
Débloquer mon plan {cible}
Commencer mon plan {cible}
Continuer mon plan
Commencer
Voir le parcours
```

Interdits : `Passer Premium`, `S'abonner`, `Voir les fonctionnalités`, `Débloquer toutes les fonctionnalités`.

Prudence de formulation obligatoire :

- diagnostic rapide → « **Niveau estimé sur cet exercice** », jamais « Votre niveau TCF est… » ;
- diagnostic complet → « **Votre niveau estimé** », avec mention « estimation SejourFR, non officielle » en pied de page ;
- ne jamais promettre la réussite à l'examen ni un délai d'obtention.

---

# 11. États vides et entrées latérales

Chaque écran doit être spécifié pour ces cas, car ils représentent la majorité du trafic réel.

| Situation | Comportement |
|---|---|
| Plan ouvert sans aucun diagnostic | Écran d'amorce : « Votre plan commence par un diagnostic » + CTA diagnostic rapide. Jamais un écran vide. |
| Diagnostic rapide rédigé mais compte non créé | La production est conservée 30 jours sur l'`anon_id`. Au retour sur l'appareil, reprise directe à l'écran « Créez votre compte pour lancer l'analyse ». |
| Plan ouvert après diagnostic rapide seulement | Aperçu partiel : objectif, 2 observations, CTA « Faire mon diagnostic complet ». Aucune priorité inventée. |
| Diagnostic complet interrompu | Reprise proposée en tête d'écran avec sections déjà terminées cochées, valable 7 jours. |
| Diagnostic complet expiré (>7 jours) | Les sections faites sont conservées, le résultat est calculé sur ce qui existe, les épreuves manquantes affichées « non évaluée ». |
| Objectif non renseigné | Demander l'objectif avant d'afficher un plan. Défaut proposé selon la mention si connue. |
| Utilisateur Premium sans diagnostic | Même amorce que gratuit, sans verrous. |
| Fin d'abonnement | Le plan reste visible en version « aperçu », l'historique et les diagnostics restent consultables. Aucune donnée supprimée. |

---

# 12. Analytics du tunnel

Événements minimum, mêmes noms sur web et mobile, avec `platform`, `user_id` ou `anon_id`, `module`.

```
quick_diag_started / quick_diag_submitted        (texte validé, avant compte)
quick_diag_signup_gate_viewed                    (métrique critique du tunnel)
signup_started / signup_completed (avec source=quick_diag)
quick_diag_analyzed / quick_diag_result_viewed
full_diag_started / full_diag_section_completed / full_diag_abandoned / full_diag_completed
full_diag_result_viewed
plan_preview_viewed
paywall_viewed (avec current_level, target_level, priorities)
paywall_cta_clicked / checkout_started / subscription_activated
plan_viewed / next_action_started / next_action_completed
micro_exercise_started / micro_exercise_completed
competence_mastered / priority_completed / plan_recomputed
```

Métriques de pilotage : taux rédaction → soumission, **soumission → création de compte** (le mur de conversion n°1), compte → diagnostic complet lancé, **complétion du diagnostic complet section par section** (le mur n°2), diagnostic complet → paywall vu, paywall → abonnement, J7 rétention des abonnés.

---

# 13. Sécurité, abus, données personnelles

- Diagnostic rapide : **pas de verrouillage agressif.** Un `anon_id` ne résiste pas à la navigation privée et tenter de l'empêcher coûterait plus que le problème. Rate limit 3 soumissions/h/IP, 1 analyse/h/compte, 1 analyse gratuite par compte.
- Diagnostic complet : **1 par compte**, vérifié côté serveur, avec **e-mail vérifié requis**. C'est là que se situe le vrai verrou anti-abus, parce que c'est là que le coût IA est significatif.
- Rate limit sur les endpoints IA : 10 soumissions / heure / compte, 30 / heure / IP.
- Audio EO : stockage S3 chiffré, URL signées à durée courte, **suppression automatique après 12 mois**, suppression immédiate sur demande. Mention explicite dans la politique de confidentialité et consentement à la première utilisation du micro.
- Les productions écrites et orales sont des données personnelles : export et suppression doivent être possibles depuis le profil.
- Aucune donnée d'utilisateur n'est envoyée au LLM en dehors du texte de la production et de la consigne.

---

# 14. Découpage en lots

| Lot | Contenu | Dépend de |
|---|---|---|
| **L0** | Audit (`AUDIT.md`) | — |
| **L1** | Socle : entitlements, quotas séparés, `ai_usage`, versionnement des prompts, endpoints « vue », i18n commun, analytics | L0 |
| **L2** | Modèle EE/EO : tâches, sujets, compétences, productions, rapports IA + admin de contenu | L1 |
| **L3** | Diagnostic écrit rapide (backend + web + mobile) | L2 |
| **L4** | Diagnostic TCF complet séquencé + calcul du niveau par épreuve | L2, L3 |
| **L5** | Moteur de plan TCF + page Plan (gratuit et Premium) + paywall contextualisé | L4 |
| **L6** | Refonte Réviser → EE / EO + micro-exercices + rapport IA court | L2, L5 |
| **L7** | Boucle de réévaluation TCF (progression détectée, adaptation du plan) | L5, L6 |
| **L8** | Référentiel de notions civiques + outil de tagging admin + migration | L1 |
| **L9** | Diagnostic civique + mises en situation | L8 |
| **L10** | Plan civique + répétition espacée + Réviser civique | L9 |
| **L11** | Examens blancs civiques connectés au plan + Progrès unifié | L10 |
| **L12** | Pack 3 mois, optimisation paywall, tableau de bord coûts IA | L5 |

Chaque lot livre : backend + Angular + Flutter + tests, dans le même lot. **Aucun lot n'est considéré terminé si une seule des deux plateformes est faite.**

---

# 15. Definition of Done

Un lot est terminé quand :

- [ ] la logique pédagogique est backend, testée unitairement, aucun seuil en dur dans le front ;
- [ ] web et mobile affichent les mêmes blocs, dans le même ordre, avec les mêmes textes ;
- [ ] les états vide / chargement / erreur / verrouillé sont implémentés selon `30_` §3 ;
- [ ] les écrans du lot sont cochés des deux côtés dans la matrice de parité `30_` §13 ;
- [ ] les événements analytics du §12 concernés sont émis des deux côtés ;
- [ ] les quotas et verrous sont vérifiés côté serveur, jamais seulement côté client ;
- [ ] les prompts modifiés ont une version incrémentée et les anciens rapports restent affichables ;
- [ ] le mode dégradé contenu (§7.4) est testé ;
- [ ] aucune régression sur les parcours existants (séries, examens blancs, favoris, erreurs).
