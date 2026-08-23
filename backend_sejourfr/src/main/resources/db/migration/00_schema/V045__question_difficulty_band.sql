-- ============================================================================
-- V045 — CALIBRATION DU CONTENU : la bande de difficulte d'une question.
-- ----------------------------------------------------------------------------
-- Phase 4 du moteur de progression V4.2 (§7, §6.2). Spec :
-- docs/plan/SEJOURFR_PROGRESSION_ENGINE_V4_2.md — regles :
-- docs/regles/progression.md.
--
-- POURQUOI UNE COLONNE DE PLUS, ALORS QUE `difficulty` EXISTE DEJA.
-- `questions.difficulty` porte l'axe « procedure visee OU palier CECRL »
-- (CSP / CR / NAT / A2 / B1 / B2). Il ne dit RIEN de la difficulte d'une
-- question a l'interieur de son palier : une question B1 peut etre facile ou
-- difficile pour du B1.
--
-- Sans cette distinction, deux series du meme palier ne sont pas comparables —
-- 20 questions faciles et 20 questions dures produisent deux scores qu'on
-- additionne comme s'ils mesuraient la meme chose. Le blueprint qualifiant de
-- §6.2 (6 EASY / 10 MEDIUM / 4 HARD sur 20) n'existe que pour fermer ca.
--
-- 🛑 NULLABLE, ET SANS VALEUR PAR DEFAUT.
-- La spec (§7, « migration progressive ») propose de basculer l'existant en
-- MEDIUM. On ne le fait PAS : ce serait affirmer une mesure qui n'a pas eu
-- lieu, sur 100 % du catalogue, et cette affirmation deviendrait indiscernable
-- d'un vrai tag le jour ou on commencera a taguer.
--
-- L'effet pratique est le meme, et il est plus honnete : une serie dont une
-- seule question n'a pas de bande est UNCALIBRATED (§6.3). Elle compte dans la
-- maitrise, dans la confiance et dans la progression visible, avec un poids
-- reduit a 0,50 — mais elle ne verrouille jamais un palier. Le candidat
-- travaille, le moteur ne conclut pas.
--
-- LA DIFFICULTE EMPIRIQUE (§7, « a terme »).
-- Elle se calcule a partir du taux de reussite reel par item, deja disponible
-- dans attempt_questions + answers. La vue ci-dessous l'expose ; elle ne
-- REMPLACE rien automatiquement. Un tag pose par un humain et une statistique
-- ne se contredisent pas en silence : la console propose, un humain tranche.
-- ============================================================================

ALTER TABLE questions
    ADD COLUMN difficulty_band varchar(8);

ALTER TABLE questions
    ADD CONSTRAINT questions_difficulty_band_valide
        CHECK (difficulty_band IS NULL OR difficulty_band IN ('EASY', 'MEDIUM', 'HARD'));

COMMENT ON COLUMN questions.difficulty_band IS
    'Bande de difficulte DANS le palier (V4.2 §7). NULL = non taguee, et sa '
    'serie est alors UNCALIBRATED. Distinct de questions.difficulty, qui porte '
    'le palier CECRL / la procedure visee.';

-- Le tirage d'une serie calibree cherche « n questions de ce type, de ce
-- palier, de cette bande, les moins vues recemment ».
CREATE INDEX idx_questions_band
    ON questions (module, question_type, difficulty, difficulty_band)
    WHERE is_active = true AND difficulty_band IS NOT NULL;

-- ----------------------------------------------------------------------------
-- La difficulte OBSERVEE, par item.
--
-- Une vue, pas une table : il n'y a rien a materialiser ni a garder synchronise,
-- et une seconde copie du taux de reussite finirait par diverger de celui qu'on
-- lit ailleurs. Le volume est celui du journal de reponses, deja indexe.
--
-- `reponses` est expose a cote du taux parce qu'un taux sur trois reponses ne
-- veut rien dire : c'est l'appelant qui decide de son seuil de confiance, la
-- vue ne cache pas la taille de l'echantillon.
-- ----------------------------------------------------------------------------
CREATE VIEW question_empirical_difficulty AS
SELECT q.id                                            AS question_id,
       q.module                                        AS module,
       q.question_type                                 AS question_type,
       q.difficulty                                    AS difficulty,
       q.difficulty_band                               AS difficulty_band_declaree,
       count(a.id)                                     AS reponses,
       count(a.id) FILTER (WHERE a.is_correct)         AS reussies,
       CASE WHEN count(a.id) = 0 THEN NULL
            ELSE count(a.id) FILTER (WHERE a.is_correct)::double precision / count(a.id)
       END                                             AS taux_reussite
FROM questions q
         LEFT JOIN attempt_questions aq ON aq.question_id = q.id
         LEFT JOIN answers a ON a.attempt_question_id = aq.id
WHERE q.is_active = true
GROUP BY q.id, q.module, q.question_type, q.difficulty, q.difficulty_band;

COMMENT ON VIEW question_empirical_difficulty IS
    'Taux de reussite reel par item (V4.2 §7). Propose une bande, ne l''impose '
    'jamais : un tag humain et une statistique ne se contredisent pas en silence.';
