-- Qualifie les CO dont l'audio ENONCE les propositions avec leurs lettres alors
-- que l'ecran en affiche aussi le texte (cf. 00_schema/V037).
--
-- Numero V590 et non V0xx : l'ordre d'execution suit le NUMERO, pas le dossier.
-- Les questions CO sont inserees par V500 (a2), V530 (b1) et V560 (b2) ; un
-- backfill pose en 00_schema s'executerait AVANT elles et ne trouverait aucune
-- ligne. V590 est donc le premier numero libre apres le dernier lot CO.
-- (Les V800-V899 du sous-dossier audio_drafts/ n'inserent que des brouillons,
-- publies en questions a l'execution, jamais par une migration.)
--
-- Predicat, verifiable et non une liste d'UUID :
--   * question CO portant un media AUDIO ;
--   * transcript qui enumere les 4 propositions dans l'ordre A -> D avec leurs
--     lettres, donc l'audio les nomme ;
--   * aucune proposition reduite a une lettre (> 2 caracteres partout), donc
--     l'ecran affiche bien leur texte : c'est ce qui les separe des CO
--     FULL_AUDIO / des seeds a labels « A »/« Reponse A », qui restent NULL ou
--     FULL_AUDIO et ne sont pas touchees.
-- Borne, deterministe et idempotent (audio_mode IS NULL) : un rejeu ne change
-- plus rien. Sur la base de reference, il qualifie exactement 20 questions.

UPDATE questions q
SET audio_mode = 'WRITTEN_QUESTION_SPOKEN_CHOICES',
    updated_at = now()
FROM medias m
WHERE m.id = q.media_id
  AND q.question_type = 'CO'
  AND q.audio_mode IS NULL
  AND m.type = 'AUDIO'
  AND m.transcript ~ 'A\.\s.*\sB\.\s.*\sC\.\s.*\sD\.\s'
  AND NOT EXISTS (
      SELECT 1 FROM choices c
      WHERE c.question_id = q.id
        AND length(trim(c.label)) <= 2
  );
