-- ============================================================================
-- V054 — DE QUOI MESURER LE PRÉ-TAGGING, ET DE QUOI LE RELIRE VITE.
-- ----------------------------------------------------------------------------
-- Complète `question_notion_suggestions` (V051). Additif et nullable sauf
-- `prompt_version` : la table est créée VIDE par V051 et le reste — aucune
-- ligne à réécrire, donc aucun défaut à inventer rétroactivement.
--
-- 🛑 CETTE MIGRATION N'OUVRE AUCUN CHEMIN D'APPLICATION AUTOMATIQUE.
-- Aucun trigger, aucune règle, aucune vue modifiable, aucune contrainte qui
-- lierait `question_notion_suggestions.notion_id` à `questions.civic_notion_id`.
-- Poser le tag validé reste un UPDATE explicite du service, déclenché par un
-- geste humain. « Le job propose, un humain valide » (50_ §6.1.3) : ce qui est
-- ajouté ici sert à MESURER ce geste, jamais à le remplacer.
--
-- 🛑 POURQUOI `prompt_version` EST NOT NULL.
-- Le dépôt versionne et ne réécrit jamais. 50_ §6.1.2 nomme le prompt
-- `PROMPT_TAG_NOTION_v1` et ce « v1 » n'avait nulle part où s'écrire : `model`
-- ne suffit pas, car MÊME MODÈLE + PROMPT DIFFÉRENT = CALIBRATION DIFFÉRENTE.
-- Sans cette colonne, deux campagnes incomparables se mélangeraient dans le
-- même taux de VALIDATED, et ce taux ne voudrait plus rien dire.
-- Le DEFAULT posé ici ne sert qu'à traverser l'ALTER sur une table vide : il
-- est RETIRÉ juste après, pour qu'aucune écriture future ne puisse omettre sa
-- version de prompt en silence.
--
-- 🛑 LE VERDICT QUALIFIE LA RELECTURE D'UNE QUESTION, PAS UNE LIGNE ISOLÉE.
-- Les quatre gestes du relecteur (20_ §3.2 étape 3) doivent produire quatre
-- états DISTINCTS et mesurables :
--   VALIDATED — il retient la notion la MIEUX NOTÉE par la machine ;
--   CORRECTED — il retient une AUTRE notion (le tag est posé quand même) ;
--   REJECTED  — aucune ne convient, aucun tag posé ;
--   SKIPPED   — il passe, la question reste dans la file.
-- Avant ce lot, « rejeter » et « passer » n'écrivaient RIEN — indiscernables en
-- base — et « valider » et « corriger » produisaient la MÊME écriture : on ne
-- pouvait donc pas mesurer si le modèle avait raison, ce qui est tout l'intérêt
-- du pré-tagging.
-- 🛑 VALIDATED vs CORRECTED est déterminé PAR LE SERVEUR, en comparant la
-- notion retenue à la suggestion la mieux notée. C'est la métrique de qualité
-- du modèle : un client qui pourrait l'annoncer lui-même pourrait la mentir.
-- Le verdict est écrit sur TOUTES les suggestions de la question relue : il dit
-- ce que la PROPOSITION de la machine valait pour cette question, et ne laisse
-- derrière lui aucune ligne « jamais relue » qui fausserait le reste à faire.
-- Se mesure donc en `COUNT(DISTINCT question_id)`, jamais en `COUNT(*)`.
-- ============================================================================

ALTER TABLE question_notion_suggestions
    ADD COLUMN prompt_version varchar(32) NOT NULL DEFAULT 'PROMPT_TAG_NOTION_v1',
    ADD COLUMN rationale      text,
    ADD COLUMN review_verdict varchar(16),
    ADD COLUMN reviewed_by    uuid REFERENCES users (id),
    ADD COLUMN reviewed_at    timestamptz,
    -- Le lot de production qui a écrit la ligne. NULL = écrite hors campagne.
    -- Justification : une campagne de pré-tagging se joue PAR LOTS (50_ §6.1.2
    -- ordonne même les thèmes), et un lot raté doit pouvoir être purgé ou
    -- rejoué SEUL. Sans cet identifiant, la seule prise serait
    -- `model + fenêtre de created_at` — approximatif, et faux dès que deux lots
    -- se chevauchent ou qu'une reprise partielle a eu lieu. Une colonne
    -- nullable, aucun coût d'écriture, et elle évite un DELETE approximatif sur
    -- des lignes qui portent du travail humain (`review_verdict`).
    ADD COLUMN batch_id       uuid;

ALTER TABLE question_notion_suggestions
    ALTER COLUMN prompt_version DROP DEFAULT;

ALTER TABLE question_notion_suggestions
    ADD CONSTRAINT chk_question_notion_review_verdict CHECK (
        review_verdict IS NULL
            OR review_verdict IN ('VALIDATED', 'CORRECTED', 'REJECTED', 'SKIPPED')
    ),
    -- Un verdict sans date ne se mesure pas : on ne saurait ni dans quel ordre
    -- ni à quelle campagne rattacher la relecture.
    ADD CONSTRAINT chk_question_notion_review_date CHECK (
        review_verdict IS NOT NULL OR reviewed_at IS NULL
    );

COMMENT ON COLUMN question_notion_suggestions.prompt_version IS
    'Version du prompt qui a produit la suggestion (PROMPT_TAG_NOTION_v1, 50_ '
    '§6.1.2). NOT NULL sans defaut : meme modele + prompt different = '
    'calibration differente, et deux campagnes incomparables ne doivent jamais '
    'se melanger dans le meme taux de VALIDATED.';

COMMENT ON COLUMN question_notion_suggestions.rationale IS
    'La phrase par laquelle la machine justifie sa proposition (20_ §3.2). '
    'Prevue des l''origine, perdue a l''implementation : c''est elle qui fait '
    'passer le relecteur de 15 s a 6 s par question.';

COMMENT ON COLUMN question_notion_suggestions.review_verdict IS
    'Ce que la relecture HUMAINE a fait de la proposition : VALIDATED (notion '
    'la mieux notee retenue) / CORRECTED (une autre retenue) / REJECTED '
    '(aucune ne convient) / SKIPPED (passee). NULL = pas encore relue. '
    'VALIDATED vs CORRECTED est deduit PAR LE SERVEUR : c''est la metrique de '
    'qualite du modele, un client ne peut pas l''annoncer. Ecrit sur toutes '
    'les suggestions de la question relue, donc compte en COUNT(DISTINCT '
    'question_id).';

COMMENT ON COLUMN question_notion_suggestions.reviewed_by IS
    'L''administrateur qui a tranche. NULL possible : une relecture faite hors '
    'ecran (script, reprise) ne s''invente pas un auteur.';

COMMENT ON COLUMN question_notion_suggestions.batch_id IS
    'Lot de production de la suggestion, pour rejouer ou purger UN lot precis '
    'sans toucher aux autres. NULL = ecrite hors campagne.';

-- Le taux VALIDATED / CORRECTED est LA mesure du pre-tagging : on la lit
-- souvent et sur une table qui portera ~1 000 lignes par campagne.
CREATE INDEX idx_question_notion_suggestion_verdict
    ON question_notion_suggestions (review_verdict)
    WHERE review_verdict IS NOT NULL;

-- Purger ou rejouer un lot doit rester une operation bornee.
CREATE INDEX idx_question_notion_suggestion_batch
    ON question_notion_suggestions (batch_id)
    WHERE batch_id IS NOT NULL;
