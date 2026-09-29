-- ============================================================================
-- V033 — L'audio d'une production de candidat n'est PLUS STOCKÉ
-- ----------------------------------------------------------------------------
-- Décision produit (motif : consentement) : l'enregistrement d'un candidat sert
-- UNIQUEMENT à produire la transcription — dont le correcteur a besoin — puis il
-- disparaît. Aucune production de candidat n'est désormais écrite sur R2, et
-- aucun écran ne propose de la réécouter : on ne garde que le texte.
--
-- Ce que cette migration fait : elle DESSERRE deux contraintes qui exigeaient un
-- média stocké. Rien d'autre.
--
-- 🛑 CE QU'ELLE NE FAIT PAS, ET NE DOIT JAMAIS FAIRE :
--   * elle ne supprime AUCUN objet R2 (décision explicite : « laisser Cloudflare
--     tel quel, ne supprime rien ») ;
--   * elle ne vide AUCUNE clé déjà persistée — `production_submissions.media_url`
--     et `user_skill_attempts.audio_object_key` gardent leurs valeurs
--     historiques ;
--   * elle ne supprime pas les colonnes : elles deviennent LEGACY, en lecture
--     seule, plus jamais écrites par le code.
-- Ne pas ajouter ici (ni ailleurs) de purge, de job de suppression ou de DELETE
-- rétroactif.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. production_submissions : une soumission orale n'a plus ni média ni texte.
--    Sa production vit dans `transcriptions` — exactement comme la voie temps
--    réel depuis V017, pour la même raison (l'audio ne transite plus par R2).
--    La contrainte se réduit donc à ce qui reste vrai : on ne peut jamais avoir
--    un média ET un texte sur la même ligne.
-- ----------------------------------------------------------------------------
ALTER TABLE production_submissions
    DROP CONSTRAINT chk_prod_sub_audio_or_text;

ALTER TABLE production_submissions
    ADD CONSTRAINT chk_prod_sub_audio_or_text CHECK (
        media_url IS NULL OR texte_soumis IS NULL
    );

COMMENT ON COLUMN production_submissions.media_url IS
    'LEGACY, plus jamais écrite depuis V033. Clé R2 des productions orales enregistrées avant que l''audio cesse d''être stocké. Conservée telle quelle ; la production d''une soumission orale vit désormais uniquement dans transcriptions.texte.';

-- ----------------------------------------------------------------------------
-- 2. user_skill_attempts : une tentative orale n'a plus de clé audio, sa
--    production est sa transcription. « Une tentative sans production n'existe
--    pas » reste vrai — on ajoute simplement la troisième source légitime.
-- ----------------------------------------------------------------------------
ALTER TABLE user_skill_attempts
    DROP CONSTRAINT chk_user_skill_attempts_has_production;

ALTER TABLE user_skill_attempts
    ADD CONSTRAINT chk_user_skill_attempts_has_production CHECK (
        written_production IS NOT NULL
        OR audio_object_key IS NOT NULL
        OR transcript IS NOT NULL
    );

COMMENT ON COLUMN user_skill_attempts.audio_object_key IS
    'LEGACY, plus jamais écrite depuis V033. Clé R2 des productions orales enregistrées avant que l''audio cesse d''être stocké. Conservée telle quelle.';

COMMENT ON COLUMN user_skill_attempts.transcript IS
    'Transcription Whisper (EO). Depuis V033 elle est SYSTÉMATIQUE et produite pendant la requête de soumission, même sans analyse IA demandée : sans elle il ne resterait rien de la production, puisque l''audio n''est plus conservé.';
