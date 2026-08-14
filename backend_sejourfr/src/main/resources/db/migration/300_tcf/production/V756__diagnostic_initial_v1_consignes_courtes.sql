-- ==========================================================================
-- V756 — Diagnostic INITIAL_TCF v1 : consignes raccourcies, bornes réduites
--
-- Motif produit : les deux sujets livrés en V755 se lisaient comme un examen
-- complet dès le premier contact (4 puces à l'écrit, 4 étapes à l'oral, 100-130
-- mots, 2 à 3 minutes). Le diagnostic doit se lire « 5 minutes et je découvre
-- mon niveau ». On corrige les sujets EN PLACE dans la version 1 : seuls deux
-- diagnostics ont été menés à terme, leur analyse est figée et n'est jamais
-- relue avec les bornes du sujet.
--
-- On NE crée PAS de version 2 : les UUID des deux tâches sont référencés par
-- diagnostic_sessions ET servent de clé stable à l'audio de consigne sur R2.
-- Aucun identifiant ne bouge ici, aucune ligne n'est créée ni supprimée, et
-- diagnostic_task_skills (les deux allowlists de 8 compétences) n'est pas
-- touchée : les incises « et ce que vous en avez pensé » (EE2-C7), « dites ce
-- que vous cherchez » (EO1-C3) et « (activités, horaires, tarif, inscription) »
-- (EO2-C4) sont conservées exprès pour que ces compétences restent observables.
--
-- ⚠ L'audio de consigne de l'oral (instruction_audio_url) a été généré depuis
-- l'ANCIEN texte : il est désormais faux. Sa régénération est une opération
-- admin explicite et payante, hors migration :
--   POST /api/admin/diagnostics/INITIAL_TCF/versions/1/instruction-audio
--
-- Ciblage par (diagnostic_code, diagnostic_version, epreuve) — jamais par UUID
-- recopié. Bornées, déterministes, rejouables sans effet.
-- ==========================================================================

-- V755 avait reposé chk_prod_task_tcf_irn_ee_word_bounds en y inscrivant EN DUR
-- les bornes du sujet diagnostic (100-130) : le même piège que V723, qui avait
-- figé mots_min = 60 et bloqué des copies recevables. On le referme pour de bon
-- en exemptant les sujets diagnostiques de la table officielle du TCF IRN : ce
-- ne sont pas des tâches officielles, leurs bornes sont éditoriales et vivent
-- dans production_tasks.mots_min/mots_max, source de vérité unique injectée dans
-- le prompt du correcteur et appliquée à la soumission (ProductionTextBounds).
-- La contrainte continue de verrouiller strictement les 6 tâches officielles.
ALTER TABLE production_tasks
    DROP CONSTRAINT IF EXISTS chk_prod_task_tcf_irn_ee_word_bounds;

UPDATE production_tasks
SET consigne = E'Vous avez récemment commencé une nouvelle activité près de chez vous : sport, cours de français, bénévolat, association…\n\nÉcrivez à un ami pour lui raconter :\n- quelle activité vous avez choisie, et où ;\n- comment s''est passée votre première fois, et ce que vous en avez pensé ;\n- si vous lui conseillez d''essayer, et pourquoi.\n\nÉcrivez environ 100 à 120 mots.',
    mots_min = 100,
    mots_max = 120
WHERE diagnostic_code = 'INITIAL_TCF'
  AND diagnostic_version = 1
  AND epreuve = 'TCF_EE';

UPDATE production_tasks
SET consigne = E'Vous venez d''arriver dans une nouvelle ville et vous cherchez une activité pour rencontrer des gens et pratiquer votre français.\n\nVous parlez avec une personne d''une maison de quartier :\n1. présentez-vous et dites ce que vous cherchez ;\n2. posez-lui vos questions (activités, horaires, tarif, inscription) ;\n3. dites laquelle vous choisiriez et pourquoi.\n\nPour finir : en groupe ou seul, que préférez-vous pour pratiquer le français, et pourquoi ?\n\nParlez environ 2 minutes.',
    duree_min_sec = 90,
    duree_max_sec = 150
WHERE diagnostic_code = 'INITIAL_TCF'
  AND diagnostic_version = 1
  AND epreuve = 'TCF_EO';

ALTER TABLE production_tasks
    ADD CONSTRAINT chk_prod_task_tcf_irn_ee_word_bounds CHECK (
        epreuve <> 'TCF_EE'
        OR diagnostic_code IS NOT NULL
        OR (tache_numero = 1 AND mots_min = 30 AND mots_max = 60)
        OR (tache_numero IN (2, 3) AND mots_min = 40 AND mots_max = 90)
    );
