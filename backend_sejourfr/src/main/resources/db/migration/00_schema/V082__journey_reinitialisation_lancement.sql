-- ============================================================================
-- V082 — Lancement du cycle d'examens pour TOUS (D-69 ter, 2026-09-28)
-- ----------------------------------------------------------------------------
-- Decision du proprietaire : « mettre a TOUT LE MONDE un plan NON FAIT avec
-- uniquement des examens blancs ». Chaque cycle EN COURS ou EN ATTENTE au
-- moment du deploiement est MARQUE ; il est remplace a sa premiere lecture
-- (JourneyService, sous le verrou du parcours) : le cycle en cours est
-- historise INTERROMPU, le cycle en attente vide de ses lots (SUPERSEDED), et
-- un cycle d'examens neuf devient courant.
--
-- 🛑 Pourquoi un MARQUEUR et non une migration qui fabrique les cycles : la
-- construction d'un cycle a une autorite unique en Java (poserLeCycleDExamens) ;
-- la recopier en SQL en ferait une seconde. Le marqueur est pose UNE fois, par
-- Flyway, sur un ensemble deterministe (les cycles vivants a cet instant) : un
-- cycle cree ensuite naît a false et n'est jamais reinitialise. Aucune ligne
-- creee ici, aucun resultat touche ; les cycles deja HISTORISES ne bougent pas.
-- ============================================================================

ALTER TABLE journey
    ADD COLUMN reinitialiser_au_lancement boolean NOT NULL DEFAULT false;

-- @@MARQUAGE_DU_LANCEMENT@@
UPDATE journey
SET reinitialiser_au_lancement = true
WHERE status IN ('EN_COURS', 'EN_ATTENTE');
