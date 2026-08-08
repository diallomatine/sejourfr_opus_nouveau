-- QUALITE DE TRANSCRIPTION — ce qu'on payait deja sans le lire, et ce qu'on
-- mesure nous-memes.
--
-- Motif : le bug « mot coupe en deux » a hache les transcriptions temps reel du
-- 28 juin au 4 juillet 2026 sans qu'aucun chiffre ne le signale. On repare un
-- cas, on reste aveugle au suivant. Ces colonnes rendent la question
-- « nos transcriptions se degradent-elles ? » repondable en UNE requete.
--
-- Deux familles, volontairement distinctes :
--   * les trois indicateurs WHISPER (avg_logprob, no_speech_prob,
--     compression_ratio) : deja factures dans la reponse verbose_json, jamais
--     lus jusqu'ici. NULL pour le temps reel, qui n'expose rien ;
--   * les deux indicateurs MAISON (taux_formes_suspectes, taux_collages,
--     qualite_degradee) : deterministes, gratuits, calcules sur le texte final,
--     donc valables pour les DEUX sources — y compris le temps reel, qui est la
--     plus abimee. Cf. TranscriptionQualityAudit.
--
-- Aucune de ces colonnes n'entre dans un calcul de note, de niveau ou de seuil.

ALTER TABLE transcriptions
    ADD COLUMN avg_logprob            double precision,
    ADD COLUMN no_speech_prob         double precision,
    ADD COLUMN compression_ratio      double precision,
    ADD COLUMN segments_count         integer,
    ADD COLUMN taux_formes_suspectes  double precision,
    ADD COLUMN taux_collages          double precision,
    ADD COLUMN qualite_degradee       boolean;

COMMENT ON COLUMN transcriptions.avg_logprob IS
    'Whisper verbose_json : moyenne des segments[].avg_logprob ponderee par leur duree. NULL en temps reel.';
COMMENT ON COLUMN transcriptions.no_speech_prob IS
    'Whisper verbose_json : PIRE segments[].no_speech_prob. NULL en temps reel.';
COMMENT ON COLUMN transcriptions.compression_ratio IS
    'Whisper verbose_json : PIRE segments[].compression_ratio (indice de radotage). NULL en temps reel.';
COMMENT ON COLUMN transcriptions.segments_count IS
    'Nombre de segments renvoyes par Whisper. NULL en temps reel.';
COMMENT ON COLUMN transcriptions.taux_formes_suspectes IS
    'Indicateur maison : part des mots de 1 a 3 lettres du candidat absents de l inventaire ferme. Les deux sources.';
COMMENT ON COLUMN transcriptions.taux_collages IS
    'Indicateur maison : part des positions ou deux formes suspectes se suivent (signature du mot coupe).';
COMMENT ON COLUMN transcriptions.qualite_degradee IS
    'Vrai quand un des deux taux maison depasse son seuil. Plafonne la confiance et elargit le filet oral ; ne touche JAMAIS la note.';

-- Index partiel : la seule question posee en routine est « lesquelles sont
-- degradees, et quand ». Partiel parce que le cas nominal est ultra-majoritaire.
CREATE INDEX idx_transcription_degradee
    ON transcriptions (created_at)
    WHERE qualite_degradee;
