-- SSML multi-voix écrit à la main pour les exemples EO (dialogues examinateur ↔ candidat).
-- `contenu` reste la transcription lisible affichée à l'écran ; `ssml_text` est le SSML
-- prêt pour Azure Speech. NULL => le batch audio retombe sur la génération auto depuis `contenu`.
ALTER TABLE production_examples ADD COLUMN ssml_text TEXT;

-- Purge des exemples existants : ils seront re-seedés avec leur SSML multi-voix.
DELETE FROM production_examples;
