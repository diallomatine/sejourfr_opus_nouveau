-- Troisieme valeur d'audio_mode : WRITTEN_QUESTION_SPOKEN_CHOICES.
--
-- Certaines CO ont un document sonore qui ENONCE les 4 propositions avec leurs
-- lettres (« A. … B. … C. … D. … ») ALORS QUE l'ecran en affiche aussi le texte.
-- Elles ne sont ni WRITTEN_QUESTION (l'ecran est la seule source de l'ordre,
-- donc melangeable) ni FULL_AUDIO (l'audio seul, ecran reduit aux lettres) :
-- c'est un troisieme point du meme axe. Melanger une telle question
-- desynchronise la lettre dite de la lettre affichee — le candidat qui entend
-- « B », retient B et clique B se trompe alors qu'il avait compris.
--
-- DDL seule ici (convention 00_schema). Le backfill des lignes concernees vit
-- dans 300_tcf/co_comprehension_orale/V590, qui s'execute APRES les lots de
-- questions CO (V500/V530/V560) : un UPDATE pose ici ne trouverait aucune ligne.

ALTER TABLE questions DROP CONSTRAINT IF EXISTS chk_question_audio_mode;

ALTER TABLE questions ADD CONSTRAINT chk_question_audio_mode
    CHECK (
        audio_mode IS NULL
        OR audio_mode IN ('WRITTEN_QUESTION', 'FULL_AUDIO', 'WRITTEN_QUESTION_SPOKEN_CHOICES')
    );

COMMENT ON COLUMN questions.audio_mode IS
    'Mode d''audio des questions de Comprehension Orale : WRITTEN_QUESTION (document seul, propositions affichees a l''ecran -> melangeables), FULL_AUDIO (tout lu, ecran reduit aux lettres) ou WRITTEN_QUESTION_SPOKEN_CHOICES (l''audio enonce les propositions avec leurs lettres ET l''ecran affiche leur texte -> jamais melangeables). NULL pour les questions non audio.';
