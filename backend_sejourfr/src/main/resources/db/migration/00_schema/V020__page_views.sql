-- ============================================================================
-- V020 — Mesure d'audience des landings (compteur agrégé, sans traceur)
-- ----------------------------------------------------------------------------
-- Objectif : savoir combien de visiteurs consultent une page de campagne (ex.
-- `/reussir`, le lien de bio réseaux) et combien cliquent son CTA, découpé par
-- réseau de provenance. Réponse à « est-ce que TikTok convertit ? ».
--
-- CE QUI N'EST PAS STOCKÉ : aucune adresse IP, aucun user-agent, aucun
-- identifiant de visiteur, aucun cookie ni stockage navigateur. La page
-- `/confidentialite` peut donc continuer d'affirmer qu'aucun traceur n'est
-- déposé, et aucune CMP n'est requise. Ne PAS ajouter de colonne identifiante
-- ici sans repasser sur la politique de confidentialité.
--
-- MODÈLE AGRÉGÉ, pas de journal d'événements : une ligne par
-- (page, source, type d'événement, jour), incrémentée en place via
-- `INSERT ... ON CONFLICT DO UPDATE` (atomique, pas de lecture-modification-
-- écriture concurrente). La table ne peut donc pas enfler : sa taille est
-- bornée par (pages suivies × sources × 2 événements × jours) — quelques
-- dizaines de lignes par mois. C'est volontairement l'inverse du problème
-- signalé sur les attempts invités (cf. CLAUDE.md racine).
--
-- Conséquence assumée : on compte des VUES, pas des visiteurs uniques —
-- dédupliquer demanderait de marquer le terminal, ce qu'on refuse ici.
-- ============================================================================

CREATE TABLE page_views
(
    id         uuid        NOT NULL PRIMARY KEY,
    -- Chemin de la page suivie ("/reussir"). Le backend n'accepte qu'une
    -- liste blanche (PageViewService.TRACKED_PATHS) : c'est ce qui borne la
    -- cardinalité de la table face à un endpoint public.
    path       varchar(160) NOT NULL,
    -- Réseau de provenance normalisé : tiktok / instagram / whatsapp /
    -- facebook / youtube / direct / autre. Jamais de valeur libre.
    source     varchar(40) NOT NULL,
    -- VIEW (page affichée) ou CTA (clic sur l'appel à l'action principal).
    event      varchar(20) NOT NULL,
    -- Jour civil Europe/Paris de l'événement.
    day        date        NOT NULL,
    hits       bigint      NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_page_views_bucket UNIQUE (path, source, event, day)
);

COMMENT ON TABLE page_views IS
    'Compteur d''audience agrégé des landings. Aucune donnée personnelle : ni IP, ni user-agent, ni identifiant de visiteur.';

-- Lecture admin type : « /reussir sur les 30 derniers jours, par source ».
CREATE INDEX idx_page_views_path_day ON page_views (path, day DESC);
