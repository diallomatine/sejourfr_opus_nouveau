# Domaine métier — vocabulaire et enums

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 26-112 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Domaine métier (vocabulaire)

- **Module** : `CIVIQUE` ou `TCF`
- **TargetProcedure** (civique) : `CSP` / `CR` / `NAT`. **Le palier de français exigé
  est porté par l'enum** (`CSP→A2`, `CR→B1`, `NAT→B2`, seuils du 1ᵉʳ janvier 2026) :
  `TargetProcedure.getRequiredTcfLevel()` est LA source de vérité, `TargetProcedure.niveauVise(
  procedure, declare)` applique le **plancher** (`max` sur l'ordre CECRL — NAT+B1 ⇒ B2, CSP+B2
  ⇒ B2, procédure absente ⇒ le déclaré, rien ⇒ null). Ne jamais réécrire cette table ailleurs :
  elle a vécu en 6 copies, d'où un candidat NAT tiré vers le B1. Miroirs **gelés par test de
  chaque côté** — `TargetProcedureTest` ⇄ `web/lib/target-level.test.ts` ⇄
  `mobile/test/target_procedure_levels_test.dart` (technique `SkillLabelsTest`).
  `users.target_level` est **posé par le serveur** au choix de la démarche
  (`MeService.updateTargetProcedure`, seul point d'écriture) et **re-dérivé à la lecture**
  (`AuthenticatedUser.targetLevel`) : aucun front ne peut recevoir un couple contradictoire,
  même sur une ligne héritée. **L'inscription y passe aussi** : `RegisterRequest.targetProcedure`
  est **facultatif** (le web l'envoie depuis l'écran de compte du diagnostic, le mobile a son
  écran `/target-path` dédié) et `AuthService.register` **appelle** `updateTargetProcedure` au
  lieu d'écrire les colonnes — le champ était absent du DTO serveur, donc jeté en silence, et
  les comptes créés en fin de diagnostic sortaient sans démarche ni palier. Une démarche
  inconnue est refusée en **400 nommé** (champ, valeur reçue, valeurs acceptées).
- **TargetLevel** (TCF) : `A2` / `B1` / `B2`
- **AttemptType** : `TRAINING` (correction immédiate) / `MOCK_EXAM` (examen blanc, chrono,
  pas de correction live) / `REVIEW`
- **Epreuve** (granularité fine, orthogonale à `mode`/`module`) : `CIVIQUE` / `TCF_CO` /
  `TCF_CE` / `TCF_STRUCTURE` / `TCF_EO` / `TCF_EE` / `TCF_COMPLET`. `TCF_COMPLET` est un
  conteneur d'examen blanc TCF ; sous-attempts liés via `attempts.parent_attempt_id`.
- **QuestionType** : `CONNAISSANCE` / `MISE_SITUATION` (civique) · `CO` / `CO_IMAGE` / `CE` /
  `STRUCTURE` (TCF). `CO_IMAGE` = format de Compréhension orale « image + 4 propositions
  lues » : `media_id` porte l'image, `audio_media_id` l'audio, choix en lettres A/B/C/D.
  Tiré dans les mêmes pools que `CO` (un filtre `CO` inclut `CO_IMAGE`). Publié depuis un
  `audio_question_draft` portant une image (`inline_svg` ou `image_url`). Image
  remplaçable côté admin via `POST /api/admin/{questions,audio-drafts}/{id}/image` (R2).
- **Difficulty** (questions QCM) : `CSP` / `CR` / `NAT` / `A2` / `B1` / `B2` — c'est l'axe
  « procédure visée **ou** palier CECRL », **pas** une échelle facile/moyen/difficile. Ne pas y
  ajouter `EASY/MEDIUM/HARD` : l'enum irrigue tous les DTO de questions, d'examens et de lots,
  donc les 3 fronts (cf. `SkillDifficulty` ci-dessous, qui existe pour cette raison).
- **MediaType** : `AUDIO` / `IMAGE` / `VIDEO`
- **NiveauCecrl** (eval IA EO/EE) : `A1_NON_ATTEINT` / `A1` / `A2` / `B1` / `B2` / `C1` /
  `C2`. Distinct de `TargetLevel` (palier visé par l'utilisateur).
- **SubmissionStatut** (EO/EE) : `SUBMITTED` → `TRANSCRIBING` (EO) → `EVALUATING` →
  `EVALUATED` | `FAILED`.
- **Compétences TCF** (module de micro-entraînement EE/EO, voie parallèle aux productions
  complètes — cf. la section dédiée plus bas) :
  - **SkillSection** : `EE` / `EO`
  - **SkillTaskCode** : `EE1` / `EE2` / `EE3` / `EO1` / `EO2` / `EO3`. Référentiel officiel
    porté par l'**enum** (section, numéro de tâche, titre, palier cible), **pas** par une table.
  - **SkillDifficulty** : `EASY` / `MEDIUM` / `HARD` (libellés FR *Accessible / Intermédiaire /
    Exigeant*). Difficulté d'un sujet **à l'intérieur de sa compétence**, purement éditoriale :
    aucune règle serveur ne s'y appuie et l'IA ne la reçoit pas. Enum **distinct** de
    `Difficulty`, qui ne contient pas ces valeurs.
  - **SkillReferenceLevel** : `INSUFFICIENT` / `EXPECTED` / `EXCELLENT` — les 3 références
    comparatives d'un sujet, servies **seulement après** une production (403 sinon).
  - **SkillSelfEvaluation** : `REUSSI` / `INCERTAIN` / `DIFFICILE` (« Je pense avoir réussi » /
    « Je ne suis pas sûr » / « J'ai eu du mal »). Déclarative, facultative, **jamais** envoyée
    au correcteur et sans effet sur le verdict.
  - **SkillCriterionStatus** : `VALIDATED` / `PARTIAL` / `NOT_VALIDATED` (« Critère validé » /
    « Critère partiellement atteint » / « **Critère non atteint** ») — le verdict IA sur le
    **critère unique** du sujet. **Ni note /20 — jamais —, mais le niveau CECRL est rendu
    depuis le contrat v3** (cf. la section dédiée). `NOT_VALIDATED` ne se dit **pas** « à
    retravailler » : cette formulation était quasi synonyme du statut de sujet `TO_REINFORCE`
    et confondait le verdict d'**une tentative** avec l'état d'**un sujet**.
  - **SkillPromptStatus** : `TODO` / `TREATED` / `VALIDATED` / `TO_REINFORCE` (« À faire » /
    « Fait » / « Validé » / « À renforcer »). **Dérivé serveur** (`SkillStatusResolver`),
    jamais persisté, jamais recalculé par un front.
  - **SituationNiveauVise** : `OBJECTIF_ATTEINT` / `PROCHE` / `EN_CHEMIN` (« Tu as atteint ton
    objectif » / « Tu es proche du niveau visé » / « Encore du chemin vers ton objectif »).
    Compare le `level_reached` d'une micro-production au palier qu'exige la démarche.
    **Dérivé serveur** (`SkillLevelProgressResolver`), jamais persisté, jamais recalculé par un
    front. À ne pas confondre avec `SituationDansNiveau`, qui situe une production **dans son
    propre palier** (« A2 solide ») : celui-ci la situe **par rapport à l'objectif**. Aucun des
    3 libellés ne nomme un manque.
  - **SkillAttemptStatut** : `RECORDED` (rendu sans analyse — état **final**) · `SUBMITTED` →
    `TRANSCRIBING` (EO) → `EVALUATING` → `EVALUATED` | `FAILED`.
- **Role** : `USER` / `ADMIN`
- **AuthProvider** (exposé dans `/api/auth/me`) : `LOCAL` / `GOOGLE` / `APPLE`. Sur iOS,
  **Google ET Apple côte à côte** (Apple obligatoire d'après les guidelines App Store dès
  qu'un autre social sign-in est proposé). Champ immutable.

Le backend est la **source de vérité** des DTOs. Les 3 fronts maintiennent leurs miroirs
**à la main** :

- `admin_sejourfr/src/types/api.ts`
- `web_sejoufr/lib/types.ts`
- `mobile_sejourfr/lib/core/models/*.dart`

→ Quand un DTO Java change, mettre à jour les 3.
