# Audit — spec "progression par épreuve" TCF IRN + civique V2

> Audit obligatoire demandé par `docs/progression/spec-progression-tcf-civique-v2.md` §1 (« Hard STOP — ne pas écrire de code avant validation de cette section »). Aucun code écrit. En attente du go du propriétaire.

## Verdict en une phrase

**Une bonne partie de ce que demande la spec V2 tourne déjà en production, sous un autre nom.** Créer `user_exam_progress` + `AssessmentProgressService` + `/api/me/progress/tcf` reconstruirait un système qui existe déjà (`ProgressService.tcf()` / `TcfProfileService` / `TcfLevelEstimatorService`) — exactement le doublon que la spec interdit elle-même dans son §1. Le vrai travail restant est un **delta ciblé** sur l'existant, pas une nouvelle table ni un nouveau service.

---

## A. Attempt / sous-attempts TCF

1. `Attempt` — `backend_sejourfr/src/main/java/com/sejourfr/app/entity/Attempt.java`. Sous-attempts via `parent_attempt_id`, `EpreuveType` (`TCF_CO`/`TCF_CE`/`TCF_EO`/`TCF_EE`/`TCF_STRUCTURE`/`TCF_COMPLET` conteneur) — confirmé par `docs/regles/domaine.md`.
2. Niveau CECRL déjà **persisté** sur `attempts.cecrl_level`, calculé **une seule fois** par `TcfLevelEstimatorService` (score calibré 100-499, poids par strate A2/B1/B2, correction du hasard `GUESS_BASELINE = 0.25`, plancher A1 si une bonne réponse). Commentaire du fichier (lignes 24-28) : *« Avant ce service, deux méthodes divergentes coexistaient […] désormais le niveau est calculé ici une seule fois, persisté […], et relu partout »*.
3. **Plafond par template (§5.2 de la spec) — CONFIRMÉ : la question ne se pose pas structurellement, rien à ajouter.** Chaque examen CO/CE (module, diagnostic rapide, ou complet) tire toujours un **mélange stratifié A2+B1+B2**, jamais un niveau unique — la prémisse de la spec ("un examen marqué A2 pourrait produire B2") ne correspond à aucune réalité du moteur.
   - `AttemptCompositionService.drawTcfEpreuveStrata` (`backend_sejourfr/src/main/java/com/sejourfr/app/service/attempt/AttemptCompositionService.java:248-261`) : toute épreuve CO/CE tire `count/3` questions A2, puis B1, puis B2 (8+9+8 pour un examen module 25Q).
   - `V111__exam_templates_tcf_50q_55min.sql:1-5` confirme la même stratification pour le diagnostic/mix.
   - `TcfLevelEstimatorService.estimateQcm` (l.87-92) calcule le niveau depuis le **score calibré pondéré par strate**, pas d'un "niveau de template" — le plafond effectif est déjà porté par la composition des questions (on ne peut pas bien répondre à des B2 qu'on n'a pas vues).
   - Seul plafond explicite présent : `capB2` (l.152-156), **global** (l'IRN ne classe jamais au-delà de B2), sans rapport avec un template.

**Verdict** : réutilisable tel quel. **Rien à ajouter dans `TcfLevelEstimatorService`.**

## B. EO / EE — `production_submissions` / `ai_evaluations`

4. **Confirmées, matures.** Migration fondatrice `V011__schema_production.sql`, puis `V017` (source), `V022` (version rubriques), `V041` (`NON_EVALUABLE`), `V042` (rejugement productions inexploitables). Entité `AiEvaluation` activement consommée par `TcfProfileService.bestProduction`.
5. Agrégation multi-tâches → niveau unique : **déjà faite**. `TcfProfileService.bestProduction` prend le meilleur niveau **par tâche évaluée**, dédupliqué par soumission (la plus récente fait foi), avec repli sur le diagnostic (`diagnostic_production_analyses`) **seulement** si aucune vraie production n'existe (règle "une baseline n'est jamais concurrente d'une preuve réelle", commentaire lignes 44-67).

**Verdict** : le §1 de la spec pose une question déjà tranchée positivement. **Aucun mode dégradé à prévoir** — EO/EE sont pleinement en base et déjà agrégées vers un niveau.

## C. Compétences / mastery / niveau d'épreuve

6. `SkillMasteryEngine`/`transferProven()` mesure la maîtrise d'une **compétence individuelle** (EE1..EE3/EO1..EO3) — structurellement distinct d'un **niveau CECRL d'épreuve**. Pas de recouvrement : ce système ne peut pas produire un `estimatedLevel` TCF_EE. Seul `TcfProfileService` le fait.
7. `ProgressService.competences()` compte des compétences travaillées/maîtrisées (un nombre), **différent** de ce que veut `user_exam_progress` (un niveau CECRL par épreuve). Ce dernier existe déjà, dans le même service, via `ProgressService.tcf()` (lignes ~115-170) + `TcfProfileService` + `TcfDiagnosticProgressionResolver`.

**Verdict** : le moteur de mastery est hors-sujet pour cette spec (pas de conflit). Le niveau par épreuve existe déjà ailleurs, dans le même fichier backend déjà touché cette session pour un autre bug.

## D. Civique

8-10. Attempts/réponses civiques : pipeline diagnostic civique (`CivicDiagnosticSession`, `CivicDiagnosticViewService`). Taxonomie des thèmes : `ThemeManager`/`CivicNotionManager`. `CivicPlanService.compteurs(UUID userId)` (`CivicPlanService.java:370-374`, record `Compteurs(travaillees, maitrisees, grainNotion)`) alimente `ProgressDto.Civique` — **confirmé global uniquement**, aucun champ par thème.

**Détail par thème — CONFIRMÉ : existe déjà, ailleurs que dans `Compteurs`, à brancher plutôt qu'à créer.**
   - `CivicPlanService.themeLignes()` (l.293-330) produit déjà `CivicPlanDto.ThemeLigne` (`CivicPlanDto.java:174-184`) : `themeId, code, label, etat (CivicThemeState), grain, cibles, maitrisees, travaillees, enCours`.
   - `CivicThemeState` a **exactement 4 valeurs** : `SOLIDE`, `A_RENFORCER`, `FAIBLE`, `NON_EVALUE` — même doctrine "non évalué ≠ faible" que le reste du repo (javadoc du fichier cite explicitement l'incident V040/V041/V042).
   - Ce détail est consommé aujourd'hui par l'écran Plan/Réviser civique, **pas par `ProgressDto.Civique`** (qui n'a que `historique`, `travaillees`, `maitrisees`, `grainNotion`).

**Décision produit (2026-09-16)** : pas de traduction vers les 4 labels de la spec V2 §12.2 (`NOT_EVALUATED`/`TO_REINFORCE`/`PROGRESSING`/`SOLID`) — cette partie de la spec est corrigée/obsolète. `CivicThemeState` (`SOLIDE`/`A_RENFORCER`/`FAIBLE`/`NON_EVALUE`) est réutilisé **tel quel** dans `ProgressDto.Civique` : un dérivé se relit, pas de traduction inutile dans le DTO. La traduction en libellé UI ("Solide", "À renforcer"...) se fait uniquement côté front.

**Verdict** : rien à créer côté calcul. Étendre `ProgressDto.Civique` avec la liste déjà produite par `CivicPlanService.themeLignes()`, `CivicThemeState` brut.

## E. Mention visée (CSP/CR/NAT)

11. `TargetProcedure` (`backend_sejourfr/src/main/java/com/sejourfr/app/enums/TargetProcedure.java`) — `getRequiredTcfLevel()` (l.39), `niveauVise(procedure, declare)` (l.98). **C'est la table des paliers, source unique déjà verrouillée par des tests sur les 3 fronts** (règle du CLAUDE.md racine : ne jamais la réécrire ailleurs). `TcfDiagnosticService.cible(User)` (l.192) l'appelle déjà pour produire `targetLevel`.

**Verdict** : rien à créer. Tout existe et sert déjà `ProgressService.tcf()`.

## F. Doublons potentiels

12. Pas de table `user_exam_progress` existante — mais **le calcul équivalent tourne déjà à la lecture**, sans projection persistée (`ProgressService.tcf()` interroge `TcfDiagnosticSession` + `TcfProfileService` à chaque appel). C'est cohérent avec la doctrine `backend_sejourfr/CLAUDE.md` : *« un dérivé se relit, il ne se persiste pas »*. **Créer `user_exam_progress` avec recalcul par event listener irait à l'encontre de cet invariant du dépôt**, sauf preuve mesurée d'un problème de performance — aucune trace d'un tel problème trouvée dans l'audit.
13. `GET /api/me/progress` existant renvoie déjà, pour TCF : `actuel`/`objectif`/`evolution` par épreuve + historique de diagnostics + compétences. Structure **suffisamment proche** de ce que demande §9 pour être **étendue** (ajouter un `status` TARGET_REACHED/CLOSE_TO_TARGET/TO_REINFORCE — dérivable trivialement de `actuel` vs `objectif`, déjà servis tous les deux ; enrichir `evolution` en trend plus fin si le produit le veut vraiment) plutôt que dupliquée sous un nouvel endpoint `/api/me/progress/tcf`.
14. **Déjà affiché** : `web_sejoufr/app/_components/progres/ProgresMouvement.tsx` et `mobile_sejourfr/lib/screens/progres/progres_mouvement.dart` rendent déjà niveau + évolution par épreuve, sur un écran "Progrès" existant (T28).

**Verdict** : `user_exam_progress` et `/api/me/progress/tcf` tels que décrits dans la spec sont **des doublons d'un système qui tourne déjà**. Le travail réel est un delta ciblé sur l'existant (statut calculé, trend affiné si besoin, plafond template à confirmer), pas une nouvelle table ni un nouveau service.

## G. Règles déjà tranchées à ne pas réinventer

15. `docs/decisions/contradictions-ouvertes.md` (l.175) mentionne littéralement « progression par épreuve » — collision de nom seulement : ce passage concerne le coût en requêtes du Plan (21 requêtes), sans rapport avec cette spec. À ne pas confondre.
16. `docs/regles/progression.md` § « Écran Progrès (T28) » **est** la réalisation actuelle de l'essentiel de cette spec, avec ses propres règles déjà écrites : pas de %, pas de gamification, `INCONNUE ≠ STABLE`, les 4 épreuves toujours servies, "maîtrisée" = `transferProven` (règle qu'on vient tout juste d'aligner cette session dans `ProgressService`). Le moteur **V4.2** (SHADOW, `progression.engine.*`) est un système **différent et sans rapport direct** : il mesure la maîtrise micro-compétence par `LearningEvidence`/epoch, pas un niveau CECRL d'épreuve — à ne pas toucher, juste à ne pas confondre dans la suite.
17. Principe "null = inconnu, jamais mauvais" : **la spec V2 le respecte telle qu'écrite**. Le tableau §2 (`estimé < cible − 1 ou "À évaluer"` → `TO_REINFORCE`) fusionne bien deux cas dans le libellé de *statut produit*, mais `estimatedLevel` lui-même reste `null` correctement distinct (§4) — ce n'est pas un défaut de conception. **Risque réel seulement à l'implémentation** : si l'écran affiche un jour "À renforcer" sans distinguer nulle part "jamais mesuré" de "mesuré faible", ça recrée la confusion que `docs/decisions/diagnostic.md` (V040/V041/V042) a déjà coûtée cher. À surveiller à l'implémentation, pas à corriger dans la spec.

---

## Recommandation

Ne pas implémenter la spec telle qu'écrite (nouvelle table + nouveau service + nouveaux endpoints). À la place, approche "delta" validée par le propriétaire (2026-09-16) :

1. ~~Confirmer précisément le plafond template CO/CE (§A.3) et le détail civique par thème (§D)~~ — **fait, voir sections A.3 et D ci-dessus.** Plafond template : ne se pose pas structurellement (examens toujours stratifiés A2+B1+B2), rien à ajouter. Détail civique par thème : existe déjà (`CivicPlanService.themeLignes()`), à brancher sur `ProgressDto.Civique`.
2. Étendre `ProgressService.tcf()` / `GET /api/me/progress` pour exposer un `status` (TARGET_REACHED/CLOSE_TO_TARGET/TO_REINFORCE) calculé depuis `actuel`/`objectif` déjà servis, plutôt que créer `/api/me/progress/tcf`.
3. Revoir la partie "trend"/règle anti-yoyo de la spec (§5.3) au regard de ce que fait déjà `TcfDiagnosticProgressionResolver.evolution` — enrichir sur place, pas remplacer.
4. Plafond template : confirmé sans objet, aucune modification de `TcfLevelEstimatorService`.
5. Détail civique par thème : étendre `ProgressDto.Civique` avec `CivicPlanService.themeLignes()` — pas de nouveau calcul de maîtrise à écrire. Trancher au produit le mapping `FAIBLE` (pas d'équivalent "PROGRESSING" direct dans la spec).
6. Ne toucher ni `SkillMasteryEngine` ni le moteur V4.2 (SHADOW) : hors-sujet, aucun rapport avec cette spec.
7. Pas de nouvelle table `user_exam_progress` sauf preuve mesurée d'un problème de performance sur la lecture à la volée actuelle.

**Le point 1 (STOP) est confirmé. En attente du go pour les points 2 à 6 (implémentation delta backend + front).**
