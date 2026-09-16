# SejourFR — Spécification "progression par épreuve" TCF IRN + Examen civique (V2)

> V2 : corrige l'absence de niveau cible, la jauge sans référentiel, le plafonnement des examens blancs, les ambiguïtés de la règle anti-yoyo, le traitement EO/EE/STRUCTURE, et complète le volet civique (seuil, mention, thèmes).

## 0. Objectif produit

Ajouter une progression visible et stable sur l'accueil, sans confondre :

1. **le niveau estimé actuel** : vision durable de l'utilisateur ;
2. **le niveau cible** : déduit de la démarche visée (CSP/CR/NAT) — **absent de la V1, ajouté ici** ;
3. **la dernière évaluation** : résultat brut le plus récent ;
4. **les compétences / thèmes à travailler** : alimentent le Plan, ne font pas sauter le niveau global.

Principe UX (inchangé) :
- Accueil = "Où j'en suis ?"
- Plan = "Qu'est-ce que je dois travailler maintenant ?"
- Historique / Voir les résultats = "Pourquoi l'app dit que j'en suis là ?"

---

# 1. Avant de coder : audit obligatoire (STOP 1)

**Hard STOP — ne pas écrire de code avant validation de cette section.**

Ne pas créer un second système de score si l'application sait déjà calculer les résultats.

Identifier et documenter dans un compte-rendu court (« donnée existante → usage dans la progression ») :
- `Attempt` parent + sous-attempts TCF (`TCF_CO`, `TCF_CE`, `TCF_EO`, `TCF_EE`) ;
- le résultat final de chaque sous-attempt, et si un **niveau plafond par template** existe déjà (cf. §4.3) ;
- le mapping score → niveau déjà utilisé pour CO / CE ;
- **confirmer l'existence réelle** de `production_submissions` + `ai_evaluations` pour EO / EE (la V1 les supposait sans vérification — si elles n'existent pas encore, le traitement EO/EE bascule en mode dégradé, cf. §5.4) ;
- le système actuel de compétences / mastery / Learning Plan ;
- les attempts, réponses et `UserQuestionStatus` de l'examen civique ;
- la taxonomie des thèmes civiques et tout calcul de maîtrise déjà existant ;
- le champ ou la logique qui porte la **mention visée** de l'utilisateur (CSP/CR/NAT) — nécessaire pour le niveau cible.

**Règle :** aucune duplication du résultat brut. La nouvelle fonctionnalité est une **projection de progression** construite à partir des résultats existants.

**Livrable de cette étape :** la cartographie ci-dessus + confirmation ou infirmation de l'existence de EO/EE en base. Attendre validation avant de poursuivre.

---

# 2. Niveau cible (nouveau)

| Mention | Niveau cible TCF |
|---|---|
| CSP (carte pluriannuelle) | A2 |
| CR (carte de résident) | B1 |
| NAT (naturalisation) | B2 |

- `targetLevel` est dérivé de la mention de l'utilisateur, pas saisi séparément.
- Le statut affiché par épreuve se calcule **backend**, en comparant `estimatedLevel` à `targetLevel` :

| Comparaison | Statut |
|---|---|
| estimé ≥ cible | `TARGET_REACHED` → "Objectif atteint" |
| estimé = cible − 1 | `CLOSE_TO_TARGET` → "Proche de l'objectif" |
| estimé < cible − 1 ou `À évaluer` | `TO_REINFORCE` → "À renforcer" |

Corrige l'incohérence de la maquette V1 ("Objectif : naturalisation" + "Atteindre B1 partout" — la naturalisation exige B2).

---

# 3. TCF IRN — Sources qui modifient le niveau estimé

## 3.1 Évaluations qualifiantes

| Source | Modifie le niveau estimé ? |
|---|---:|
| Diagnostic rapide d'une épreuve | Oui |
| Épreuve complète réalisée seule | Oui |
| Épreuve complète dans un examen blanc complet | Oui |
| Petite série CO / CE | Non |
| Sujet isolé EO / EE | Non |
| Micro-entraînement de compétence | Non |

### Important

Un **sujet isolé EO/EE** continue de :
- mettre à jour les compétences ;
- alimenter le Plan ;
- produire son rapport IA (si disponible).

Il ne change jamais directement le niveau global EO/EE.

Pour EO / EE, une évaluation qualifiante = une **épreuve complète** avec ses tâches attendues et un résultat final agrégé.

## 3.2 STRUCTURE — hors périmètre (précision V2)

D'après le référentiel produit, **STRUCTURE n'est pas une épreuve du TCF IRN** (catégorie d'entraînement uniquement, exclue des examens blancs IRN). En conséquence :
- STRUCTURE n'a **pas de carte** dans "Où vous en êtes" ;
- STRUCTURE n'a **pas de scope** dans `user_exam_progress` ;
- les résultats STRUCTURE alimentent uniquement les compétences / le Plan.

Les 4 cartes affichées sont donc : CO, CE, EO, EE — jamais 5.

---

# 4. Niveau estimé ≠ dernière évaluation

Chaque épreuve TCF expose séparément :

```text
estimatedLevel
targetLevel
latestEvaluationLevel
latestEvaluationDate
latestEvaluationSource
trend
```

Exemple :

```text
Expression écrite
Niveau estimé : A2 (cible : B1)
Dernière évaluation : B1 · 14/09/2026
Tendance : PROGRESSING_TO_B1
```

L'écran d'accueil affiche en priorité `estimatedLevel`, jamais `latestEvaluationLevel` seul.

---

# 5. Algorithme de niveau estimé TCF (simplifié — décision produit)

**Décision validée :** on retient une règle simple à expliquer plutôt qu'une moyenne pondérée multi-facteurs. Plus facile à tester, à justifier à l'utilisateur, suffisante pour le MVP.

## 5.1 Normalisation

Réutiliser l'ordre CECRL déjà présent dans le projet (A1 < A2 < B1 < B2 ...).

## 5.2 Plafonnement par template (nouveau — comble un trou de la V1)

Le niveau produit par une évaluation ne peut **jamais dépasser le niveau du template de l'évaluation**. Un 25/25 sur un examen blanc A2 donne au maximum un niveau candidat A2, pas B2. À vérifier lors de l'audit (§1) si un tel plafond existe déjà dans le moteur de scoring CO/CE ; sinon l'ajouter explicitement dans le service de progression.

## 5.3 Règle anti-yoyo — précisée

### Initialisation

S'il n'existe encore aucun niveau estimé :
- diagnostic rapide terminé → initialise le niveau, `confidence = LOW` ;
- épreuve complète terminée → initialise le niveau, `confidence = MEDIUM` ;
- sinon → `estimatedLevel = null`, UI "À évaluer".

### Changement de niveau (montée ou descente)

`estimatedLevel` change uniquement si :

1. les **2 dernières évaluations qualifiantes consécutives** (dans l'ordre chronologique, sans en sauter) soutiennent le même niveau, supérieur ou inférieur au niveau actuel ;
2. au moins **une des deux** est une épreuve complète (diagnostic seul insuffisant) ;
3. en cas d'évaluations non consécutives soutenant le nouveau niveau (ex : B1, A2, B1), le niveau **ne change pas** — seule une paire strictement consécutive déclenche le changement.

### Table de décision `trend`

| Dernière évaluation vs estimé | Avant-dernière évaluation | Trend |
|---|---|---|
| = estimé | — | `STABLE` |
| = estimé + 1, avant-dernière aussi + 1 | (déclenche la montée, cf. règle ci-dessus) | `STABLE` (nouveau niveau atteint) |
| = estimé + 1, avant-dernière = estimé | — | `PROGRESSING_TO_NEXT` |
| = estimé + 1, avant-dernière < estimé | — | `TO_CONFIRM` |
| = estimé − 1, avant-dernière aussi − 1 | (déclenche la descente) | `STABLE` (nouveau niveau atteint) |
| = estimé − 1, avant-dernière = estimé | — | `DECLINING` |
| une seule évaluation qualifiante existante | — | `NOT_ENOUGH_DATA` |
| aucune | — | (UI "À évaluer", pas de trend) |

Ne jamais afficher une précision artificielle du type "A2.6".

Utilisateur qui n'enchaîne que des diagnostics : le niveau reste bloqué à l'initialisation. L'UI doit alors afficher un message explicite type "Faites une épreuve complète pour confirmer votre niveau" plutôt que rester silencieuse.

---

# 6. Quand recalculer ?

Déclencher un recalcul **uniquement lorsqu'un résultat est finalisé**, via un event listener `@TransactionalEventListener(phase = AFTER_COMMIT)` (ou équivalent existant) branché sur :

## TCF
- validation d'un diagnostic rapide ;
- finalisation d'un sous-attempt CO ;
- finalisation d'un sous-attempt CE ;
- fin de l'évaluation IA agrégée EO (si disponible, cf. §1) ;
- fin de l'évaluation IA agrégée EE (si disponible, cf. §1).

Fonctionne pareil pour une épreuve lancée seule ou une sous-épreuve d'examen blanc.

Ne pas recalculer le niveau global :
- à chaque question ;
- après une série d'entraînement ;
- après un petit sujet EO/EE.

Ces actions continuent d'actualiser compétences / Plan.

---

# 7. Projection persistée

Avant de créer une table, vérifier si une table/projection équivalente existe déjà (audit §1).

Sinon créer une projection légère :

```sql
user_exam_progress
------------------
id
user_id
track                    -- TCF_IRN / CIVIC
scope                    -- TCF_CO / TCF_CE / TCF_EO / TCF_EE / CIVIC_GLOBAL / CIVIC_THEME
theme_id                 -- nullable, renseigné uniquement si scope = CIVIC_THEME
mention                  -- CSP / CR / NAT — nécessaire pour ne pas mélanger les historiques si l'utilisateur change d'objectif
estimated_level          -- nullable pour civique
target_level             -- dérivé de mention, nullable pour civique
trend
confidence
last_evaluation_type
last_evaluation_level
last_evaluation_score
last_evaluation_at
last_source_attempt_id   -- traçabilité + dédoublonnage
qualifying_evidence_count
algo_version              -- pour permettre un recalcul global si la règle évolue
updated_at

UNIQUE(user_id, track, scope, theme_id, mention)
```

Cette table ne stocke pas le rapport complet. Elle référence / résume les résultats déjà présents.

Le calcul doit être **rejouable et idempotent** à partir de l'historique — un même `attempt_id` ne doit jamais être compté deux fois (déduplication explicite sur `last_source_attempt_id` / table d'évènements traités).

---

# 8. Service métier conseillé

```java
AssessmentProgressService
```

Responsabilités :

```text
recomputeTcfProgress(userId, examType)
getTcfOverview(userId)
getTcfHistory(userId, examType)
recomputeCivicProgress(userId, scope)   // global ou par thème
getCivicOverview(userId)
```

Le service :
1. charge les évaluations qualifiantes existantes (en excluant tout résultat non `COMPLETED`/finalisé, ou toute évaluation IA en erreur/incomplète) ;
2. applique le plafond de template (§5.2) ;
3. calcule `estimatedLevel` + `trend` selon la règle des 2 évaluations consécutives (§5.3) ;
4. met à jour la projection (upsert `ON CONFLICT`) ;
5. n'altère jamais les résultats bruts.

Brancher ce service sur les événements existants de finalisation d'Attempt et d'évaluation IA.

---

# 9. API accueil — TCF

```json
{
  "track": "TCF_IRN",
  "targetLevel": "B1",
  "items": [
    {
      "examType": "TCF_CO",
      "label": "Compréhension orale",
      "estimatedLevel": "B1",
      "targetLevel": "B1",
      "status": "TARGET_REACHED",
      "latestEvaluationLevel": "B1",
      "latestEvaluationAt": "2026-09-14T18:42:00Z",
      "latestEvaluationSource": "FULL_EXAM",
      "trend": "STABLE",
      "hasHistory": true
    },
    {
      "examType": "TCF_EE",
      "label": "Expression écrite",
      "estimatedLevel": "A2",
      "targetLevel": "B1",
      "status": "CLOSE_TO_TARGET",
      "latestEvaluationLevel": "B1",
      "latestEvaluationAt": "2026-09-14T18:42:00Z",
      "latestEvaluationSource": "FULL_EXAM",
      "trend": "PROGRESSING_TO_NEXT",
      "hasHistory": true
    }
  ]
}
```

Si EO/EE n'existent pas encore en base (cf. audit §1), l'item correspondant renvoie `"status": "NOT_AVAILABLE"` plutôt que `"À évaluer"` — l'UI affiche alors "Bientôt disponible" et masque le CTA.

L'accueil ne recalcule jamais la progression : il lit cette projection. Un seul appel API pour les 4 cartes.

---

# 10. Accueil — section "Où vous en êtes" (TCF)

Position : **À faire maintenant → Où vous en êtes → Votre Plan** (inchangé).

Pour chaque épreuve disponible :

```text
Expression écrite
A2 · cible B1
En progression vers B1
Dernière évaluation : B1
Voir les résultats →
```

Cas sans donnée :

```text
Expression écrite
À évaluer
Aucune évaluation complète
Faire une évaluation →
```

Cas non disponible (EO/EE si pas encore implémenté côté IA) :

```text
Expression orale
Bientôt disponible
```

**La jauge de progression (%) de la maquette V1 est supprimée** : elle ne référençait aucun barème réel. La remplacer par une **échelle de niveaux** (A1 · A2 · B1 · B2), le niveau estimé mis en évidence et un repère visuel sur le niveau cible. Ne jamais afficher un pourcentage à côté d'un niveau CECRL.

---

# 11. Page "Voir les résultats" — TCF

Route conceptuelle : `/progression/tcf/{examType}`

## Bloc 1 — Synthèse

```text
Expression écrite

Niveau estimé actuel : A2 (cible : B1)
Dernière évaluation : B1 · 14 septembre
En progression vers B1

Votre niveau estimé s'appuie sur vos évaluations récentes.
Une seule évaluation ne change pas immédiatement votre niveau.
```

## Bloc 2 — Évolution récente

3 à 5 dernières évaluations qualifiantes :

```text
14 sept.  Épreuve complète      B1
08 sept.  Examen blanc          A2
02 sept.  Diagnostic rapide     A2
```

Chaque ligne cliquable vers le rapport existant si disponible. Pour un diagnostic sans rapport détaillé, afficher le résumé existant — ne pas fabriquer un rapport complet.

## Bloc 3 — Historique complet

CTA "Voir tout l'historique", liste paginée si nécessaire, filtres : Tous / Diagnostics / Épreuves-examens blancs. Pas de statistiques complexes en V1.

---

# 12. Examen civique — même philosophie, métrique différente

Pas de niveau CECRL pour le civique. Sur le toggle **Examen civique**, "Où vous en êtes" montre :

1. l'état global de l'épreuve, **avec le seuil de réussite (32/40)** ;
2. la progression par thème, **filtrée sur la mention active de l'utilisateur** (CSP/CR/NAT — les questions et le seuil peuvent différer selon la mention, à confirmer lors de l'audit §1).

Réutiliser obligatoirement les thèmes déjà définis, les réponses QCM existantes, le score/résultat d'examen déjà existant, et le moteur de mastery existant s'il sait déjà mesurer les thèmes.

## 12.1 Quelles activités mettent à jour quoi ?

```text
Diagnostic civique global / examen complet / examen blanc complet
    -> résultat global + tous les thèmes couverts

Série thématique
    -> thème concerné uniquement, résultat global inchangé
```

## 12.2 Calcul thème

**Priorité absolue : réutiliser le moteur de maîtrise existant** (mastery / successRate / skill score / confidence / observed count).

Si aucun calcul n'existe, score glissant configurable (N dernières réponses du thème, taux de réussite, nombre d'observations, date de dernière activité) — seuils **centralisés en config backend**, jamais codés en dur côté Flutter/front.

Statuts : `NOT_EVALUATED`, `TO_REINFORCE`, `PROGRESSING`, `SOLID`. Le pourcentage est une mesure interne, jamais une note officielle.

## 12.3 Accueil — toggle Examen civique

```text
Où vous en êtes

Examen civique — Naturalisation
Dernier résultat : 31 / 40 (seuil 32) · Non atteint
Dernière évaluation : 12 sept.
Voir les résultats →

Vos thèmes
[Thème A]  Solide
[Thème B]  En progression
[Thème C]  À renforcer
[Thème D]  À évaluer
```

Ne pas inventer de nouveaux thèmes : utiliser exactement la taxonomie en base.

## 12.4 Page "Voir les résultats" — Examen civique

Route conceptuelle : `/progression/civique`

**Bloc 1 — Épreuve globale** : dernier résultat, seuil de réussite, date, historique des examens complets (12 sept. 31/40, 05 sept. 27/40, 29 août 25/40), clic → rapport/correction existante.

**Bloc 2 — Progression par thème**, pour chaque thème existant : nom, statut, réussite récente (%), nombre d'observations, dernière activité. Clic thème : V1 = ouvrir les séries du thème ; V1.1 optionnelle = mini historique.

---

# 13. Endpoints proposés

```http
GET /api/me/progress/tcf
GET /api/me/progress/tcf/{examType}
GET /api/me/progress/civic
```

Le détail TCF renvoie : synthèse + 5 dernières évaluations + IDs/routes des rapports.
Le détail civique renvoie : synthèse globale + historique récent + thèmes et leur progression.

Un seul appel par carte à l'accueil (pas d'appel N+1).

---

# 14. Cas métier obligatoires (tests requis)

| Cas | Scénario | Résultat attendu |
|---|---|---|
| A — nouveau candidat | Aucune donnée EE | `estimatedLevel = null`, UI "À évaluer" |
| A (suite) | Diagnostic EE = A2 | `estimatedLevel = A2`, `confidence = LOW` |
| B — amélioration réelle | Diagnostic A2 puis examen complet B1 | `estimatedLevel` reste A2, `trend = PROGRESSING_TO_NEXT` |
| B (suite) | Nouvel examen complet B1 (2e consécutif) | `estimatedLevel = B1` |
| C — mauvaise journée | Stable B1, nouvel examen A2 (1 seul) | `latestEvaluation = A2`, `estimatedLevel` reste B1, `trend = DECLINING` |
| D — petits sujets EE réussis | 5 sujets isolés notés B1 | compétences/plan mis à jour, `estimatedLevel` EE inchangé |
| E — examen blanc complet | Sous-attempts CO/CE/EO/EE finalisés | chaque scope recalculé indépendamment, même traitement qu'une épreuve seule |
| F — civique série thématique | 10 questions d'un thème | thème mis à jour, résultat global inchangé |
| G — civique examen complet | Examen civique complet | historique global + tous les thèmes observés mis à jour |
| H — plafond template (nouveau) | Examen blanc A2 réussi à 25/25 | niveau candidat ≤ A2, jamais B2 |
| I — non consécutif (nouveau) | Évaluations B1, A2, B1 (dans cet ordre) | `estimatedLevel` ne change pas (la paire B1/B1 n'est pas consécutive) |

---

# 15. Contraintes techniques

- Recalcul idempotent, upsert `ON CONFLICT`.
- Pas de double comptage d'un même Attempt (`last_source_attempt_id` + table de déduplication).
- Ne prendre en compte que les résultats `COMPLETED`/finalisés ; une évaluation IA en erreur ou incomplète n'alimente jamais la progression.
- Recalcul à posteriori possible pour tous les utilisateurs existants (commande/job de backfill).
- Les dates viennent de la finalisation de l'évaluation, pas de l'ouverture de l'exercice.
- Seuils, poids et config de statut (`TARGET_REACHED`/`CLOSE_TO_TARGET`/`TO_REINFORCE`) externalisés en JSON versionné, jamais en dur.
- Tests unitaires sur la règle anti-yoyo (cas B, C, I).
- Tests d'intégration sur finalisation Attempt → projection.
- Frontend : aucun calcul métier du niveau, aucun accès direct aux tables source.

---

# 16. Ordre d'implémentation recommandé

1. **STOP — Audit** (§1) : cartographie existant + confirmation EO/EE + validation avant de continuer.
2. Implémenter le calcul TCF (règle des 2 évaluations consécutives + plafond template).
3. Brancher les hooks de finalisation (event listener AFTER_COMMIT).
4. Backfill des utilisateurs existants.
5. Endpoint synthèse accueil TCF.
6. Section "Où vous en êtes" (TCF) + échelle de niveaux (sans jauge %).
7. Page "Voir les résultats" TCF.
8. Réutiliser le moteur de thèmes civiques ; ajouter scope `CIVIC_THEME` si nécessaire.
9. Vue civique globale (avec seuil 32/40) + thèmes.
10. Tests des cas A à I.
11. **STOP — Revue** avant merge : vérifier qu'aucune logique de niveau n'existe côté front.

---

# 17. Définition de terminé

- L'accueil TCF affiche les épreuves disponibles (CO/CE/EO/EE, jamais STRUCTURE) avec un état cohérent et un niveau cible visible.
- Le niveau ne saute jamais après un seul résultat atypique, et jamais au-delà du niveau du template source.
- Diagnostic et examens complets alimentent le niveau ; les petits exercices alimentent le Plan sans y toucher.
- "Voir les résultats" explique clairement d'où vient le niveau.
- L'examen civique affiche son historique global (avec seuil 32/40) et l'évolution par thème, filtrée par mention.
- Toutes les données historiques existantes restent la source de vérité ; aucune logique de niveau n'est dupliquée côté frontend.
