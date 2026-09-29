-- ============================================================================
-- V072 — Une etape de COMPREHENSION (et une unite CIVIQUE) se travaille par
--        DEUX SERIES, et chaque serie lancee laisse sa trace
-- ----------------------------------------------------------------------------
-- Arbitrages du proprietaire (2026-09-20), regles fermees :
--   1. une competence CO/CE (une unite civique) se valide par 2 series REUSSIES ;
--   2. une serie = 20 questions, reussie a 16/20 (le seuil se DERIVE de
--      learning-plan.comprehension.solid-ratio x la taille de la serie) ;
--   3. LE FILET DES 4 SERIES TERMINEES EST SUPPRIME (revoque D-16) ;
--   4. la serie 2 ne se debloque qu'apres REUSSITE de la serie 1 ;
--   5. une serie reussie une fois est DEFINITIVEMENT validee -- la refaire et
--      la rater ne la devalide pas, la carte affiche le DERNIER score.
-- Regle metier : docs/regles/plan.md. Journal : docs/decisions-autonomes-parcours-tcf.md.
--
-- ----------------------------------------------------------------------------
-- POURQUOI CE LIEN EST PERSISTE, ALORS QUE LE DEPOT PERSISTE SI PEU
-- ----------------------------------------------------------------------------
-- La doctrine du depot est « un derive se relit, il ne se persiste pas »
-- (backend_sejourfr/CLAUDE.md) : statuts, verrous, niveaux, maitrise se
-- recalculent a la lecture, et c'est ce qui rend un recalibrage gratuit.
--
-- Cette table est la TROISIEME exception, et elle a EXACTEMENT le critere des
-- deux premieres (plan_pinned_priorities en V065, journey en V066) : elle
-- persiste une DECISION PRISE A UN INSTANT, que rien ne permet de recalculer
-- apres coup.
--
-- Ici, la decision est « le candidat a lance la serie n°2 de CETTE etape-ci ».
-- Un attempt de serie ciblee ne porte aucune trace de l'etape qui l'a lance :
-- il porte 20 questions de comprehension, et c'est tout. Le rattacher apres
-- coup exigerait de DEVINER -- par la date, par la competence, par le niveau --
-- et ces trois devinettes se trompent des que le candidat travaille la meme
-- competence depuis deux endroits, ou refait une serie deja validee. C'est le
-- meme raisonnement que l'epingle du Plan (« l'etape en cours pouvait etre a
-- 0/5, donc ne se lisait nulle part ») et que l'ORDRE du parcours (« il depend
-- de l'ordre d'arrivee des evaluations »).
--
-- 🛑 ON PERSISTE LE LIEN, JAMAIS LE VERDICT.
-- Pas de colonne `reussie`, pas de colonne `validee`, pas de colonne `score` :
--   · « cette serie est reussie »  se relit sur l'attempt (score >= seuil) ;
--   · « cette carte est validee »  se relit comme « il existe, parmi les essais
--     de cette carte, au moins un essai reussi ».
-- Figer le verdict ici le ferait diverger de l'attempt le jour ou le ratio de
-- reussite bouge -- et ce ratio a deja UNE autorite
-- (learning-plan.comprehension.solid-ratio), qu'aucune colonne ne doit doubler.
--
-- 🛑 AUCUNE UNICITE SUR (step_id, series_index), ET C'EST LE POINT.
-- « Refaire » une serie AJOUTE une ligne. C'est ce qui donne, sans aucune
-- ecriture supplementaire, le DERNIER score (la ligne la plus recente) et
-- l'historique complet des essais. Une contrainte d'unicite aurait oblige a
-- ecraser une ligne -- donc a perdre un essai reellement joue, ce que le depot
-- ne fait nulle part.
--
-- L'unicite qui compte, en revanche, est sur `attempt_id` : un attempt appartient
-- a UNE carte et une seule. Sans elle, un double appel (double tap, renvoi apres
-- coupure) aurait pu coller la meme session sur les deux cartes de l'etape, et
-- valider les deux d'un coup.
--
-- ON SUPPRIME EN CASCADE, des deux cotes : cette table ne porte aucune donnee
-- propre. Un cycle historise puis efface, ou un attempt efface, n'a pas a
-- laisser un lien orphelin -- il ne dirait plus rien de personne.
--
-- AUCUNE DONNEE EXISTANTE N'EST TOUCHEE : pas d'UPDATE, pas de backfill, pas de
-- retro-remplissage. Les etapes deja closes le restent ; celles encore ouvertes
-- repartent de zero carte, ce qui est litteralement vrai -- aucune serie n'avait
-- jusqu'ici ete lancee DEPUIS une carte.
-- ============================================================================

CREATE TABLE journey_step_series
(
    id           uuid PRIMARY KEY,
    step_id      uuid        NOT NULL REFERENCES journey_step (id) ON DELETE CASCADE,
    series_index smallint    NOT NULL,
    attempt_id   uuid        NOT NULL UNIQUE REFERENCES attempts (id) ON DELETE CASCADE,
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_journey_step_series_index CHECK (series_index >= 1)
);

-- La lecture de l'ecran : « les essais de cette etape, carte par carte ». Une
-- seule requete pour les deux cartes, et pour toutes les etapes ouvertes d'un
-- cycle quand la file en porte plusieurs.
CREATE INDEX idx_journey_step_series_step ON journey_step_series (step_id, series_index);

COMMENT ON TABLE journey_step_series IS
    'Le LIEN entre une carte de serie d''une etape (1 ou 2) et l''attempt lance depuis elle. '
        'Une ligne par ESSAI : refaire une serie ajoute une ligne, rien n''est ecrase. '
        'Aucun verdict n''est persiste ici -- « reussie » se relit sur l''attempt.';
