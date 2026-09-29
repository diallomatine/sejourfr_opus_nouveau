-- ============================================================================
-- V032 — Reprise d'une session EO temps réel après coupure réseau
-- ----------------------------------------------------------------------------
-- Problème corrigé : le WebSocket du candidat tombe (métro, ascenseur, bascule
-- wifi/4G, appli passée en arrière-plan) et la session était perdue POUR DE BON
-- — alors que le slot de simulation, lui, avait déjà été débité au premier
-- fragment de transcript. Le candidat payait une simulation qu'il n'avait pas
-- pu terminer.
--
-- Trois colonnes, toutes additives et nullable (rien à rejouer sur l'existant) :
--
--   * resumption_handle — dernier « handle de reprise » émis par le fournisseur
--     et relayé par le client. Le serveur le garde pour pouvoir rouvrir la même
--     conversation ; il reste exploitable 2 h après la fin de la session côté
--     fournisseur. Stocké côté serveur ET pas seulement en mémoire du client :
--     sinon une appli tuée par le système perdrait la session malgré tout.
--   * resumption_count — nombre de reprises déjà accordées, borné en service
--     (sejourfr.realtime.gemini.session-resumption.max-resumptions). Sans
--     borne, une session pourrait faire émettre des tokens indéfiniment.
--   * last_turn_index — index du dernier tour appliqué au transcript. C'est ce
--     qui rend POST /transcript IDEMPOTENT : un client qui réémet un tour après
--     un timeout réseau ne le duplique plus, et n'a plus à choisir entre
--     « risquer un doublon » et « perdre le tour ». NULL = client historique
--     qui n'envoie pas d'index (comportement d'avant, inchangé).
--
-- Aucune de ces colonnes n'entre dans un calcul de note, de niveau ou de quota.
-- ============================================================================

ALTER TABLE realtime_sessions
    ADD COLUMN resumption_handle text,
    ADD COLUMN resumption_count  integer DEFAULT 0 NOT NULL,
    ADD COLUMN last_turn_index   integer;

COMMENT ON COLUMN realtime_sessions.resumption_handle IS
    'Dernier handle de reprise relayé par le client. Verrouillé côté serveur dans le setup du token de reprise (le client ne peut poser aucun champ de setup).';
COMMENT ON COLUMN realtime_sessions.resumption_count IS
    'Reprises déjà accordées sur cette session. Bornées par sejourfr.realtime.gemini.session-resumption.max-resumptions.';
COMMENT ON COLUMN realtime_sessions.last_turn_index IS
    'Index du dernier tour appliqué au transcript : rend POST /transcript idempotent face à un réessai réseau. NULL = client sans index.';
