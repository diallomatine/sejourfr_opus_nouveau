-- ============================================================================
-- V053 — LE DIAGNOSTIC CIVIQUE AVANT LE COMPTE (arbitrage du 2026-09-10).
-- ----------------------------------------------------------------------------
-- Le propriétaire a tranché : « que ce soit le diagnostic examen civique ou
-- TCF, l'utilisateur doit pouvoir passer le diagnostic AVANT de créer son
-- compte ; il répond au QCM et seulement après on lui demande de créer son
-- compte pour voir le résultat. »
--
-- 🛑 POURQUOI UNE SESSION SANS COMPTE, ET PAS UN STOCKAGE LOCAL. Le TCF, lui,
-- garde ses deux productions sur l'appareil (cf. PublicDiagnosticController) :
-- c'est du texte et de l'audio, il n'y a rien à corriger tant qu'un modèle
-- n'est pas appelé. Le civique est du QCM : le corriger côté client obligerait
-- à SERVIR LES BONNES RÉPONSES à un visiteur, et jouer 40 questions hors
-- `attempts` obligerait à écrire un SECOND RUNNER — les deux sont interdits.
-- On réutilise donc la mécanique d'attempt invité qui existe déjà pour la démo
-- (user_id NULL + client_ip), et le diagnostic devient une session sans
-- porteur, adoptée au moment de l'inscription.
--
-- 🛑 LA SESSION EXISTE DÈS LE PREMIER TIRAGE, avant le compte. C'est elle qui
-- porte `attempts.civic_diagnostic_id` : sans ça, l'attempt invité serait un
-- examen blanc aux yeux de toutes les grilles, dès la première question.
-- ============================================================================

ALTER TABLE civic_diagnostic_sessions
    ALTER COLUMN user_id DROP NOT NULL;

-- L'IP du visiteur, exactement comme `attempts.client_ip` : c'est le seul lien
-- entre le navigateur et sa session tant qu'aucun compte n'existe, et c'est ce
-- qui empêche d'adopter le diagnostic d'un tiers dont on aurait l'identifiant.
ALTER TABLE civic_diagnostic_sessions
    ADD COLUMN client_ip varchar(45);

COMMENT ON COLUMN civic_diagnostic_sessions.client_ip IS
    'IP du visiteur pour une session sans compte (miroir de attempts.client_ip). '
    'Sert au controle d''adoption : on n''adopte que la session de SON navigateur.';

-- Une session a toujours un porteur : un compte, ou une IP le temps du tunnel
-- invité. Sans cette contrainte, une ligne orpheline serait adoptable par
-- n'importe qui.
ALTER TABLE civic_diagnostic_sessions
    ADD CONSTRAINT chk_civic_diagnostic_porteur
        CHECK (user_id IS NOT NULL OR client_ip IS NOT NULL);

CREATE INDEX idx_civic_diagnostic_invite
    ON civic_diagnostic_sessions (client_ip, started_at DESC)
    WHERE user_id IS NULL;
