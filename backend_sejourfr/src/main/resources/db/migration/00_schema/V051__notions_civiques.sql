-- ============================================================================
-- V051 — LE RÉFÉRENTIEL DE NOTIONS CIVIQUES, ET DE QUOI LE TAGGER (lot L8).
-- ----------------------------------------------------------------------------
-- Spec : 50_ §6.1 (« méthode, pas liste figée »), qui remplace 20_ §2.
--
-- 🛑 CE RÉFÉRENTIEL N'EST PAS FIGÉ, ET LA BASE LE DIT.
-- 50_ §6.1 est explicite : les 40 notions sont un « référentiel de TRAVAIL »,
-- « destiné à être ajusté APRÈS le tagging », à la porte de revue §6.1.3. D'où
-- `merged_into_id` : une notion qui fusionne n'est jamais SUPPRIMÉE, elle est
-- désactivée et pointe vers celle qui la reprend. Les questions déjà taguées
-- gardent leur lien, et l'historique de la décision reste lisible en base.
--
-- 🛑 DEUX TABLES, PARCE QU'IL Y A DEUX AUTORITÉS.
--   * `questions.civic_notion_id` — le tag VALIDÉ. Une seule notion, posée par
--     un humain. C'est lui qui fait foi partout ailleurs (plan, révision,
--     examens blancs).
--   * `question_notion_suggestions` — ce qu'une machine PROPOSE, avec sa
--     confiance. Plusieurs par question, et aucune ne vaut décision.
-- Les confondre reviendrait à laisser un modèle décider du programme civique.
-- 50_ §6.1.3 le dit pour les fusions, et ça vaut pour le tagging lui-même :
-- « le job propose, un humain valide ».
--
-- 🛑 `civic_notion_id` NULL = PAS ENCORE TAGUÉE, jamais « sans notion ».
-- Une question non taguée n'est pas hors programme : elle attend. C'est
-- l'invariant `null = inconnu` du dépôt, appliqué à un chantier éditorial.
--
-- 🛑 AUCUN APPEL LLM N'EST DÉCLENCHÉ PAR CETTE MIGRATION, ni par le code qui
-- l'accompagne. La table de suggestions est CRÉÉE VIDE : la remplir coûte de
-- l'argent, et c'est une décision du propriétaire (règle du dépôt).
--
-- La RÈGLE DE VOLUME de 20_ §2.5 (« 6 questions par notion et par mention »)
-- est annulée par 50_ §6.1 et n'est PAS inscrite en base : elle se mesure à la
-- lecture, par mention, et se dégrade par notion — jamais « ce thème n'a pas de
-- notions ». Une contrainte figerait un seuil que le tagging doit pouvoir
-- faire bouger.
-- ============================================================================

CREATE TABLE civic_notions (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code           varchar(64)  NOT NULL,
    label          varchar(200) NOT NULL,
    -- Le thème d'appartenance, par son CODE (`CIV_PRINCIPES`…) : les thèmes
    -- sont seedés et leurs UUID ne sont pas des données éditoriales.
    theme_code     varchar(64)  NOT NULL,
    display_order  smallint     NOT NULL,
    is_active      boolean      NOT NULL DEFAULT true,
    -- Notion qui reprend celle-ci après une fusion (porte de revue §6.1.3).
    -- NULL = notion vivante. Une notion fusionnée est désactivée, jamais
    -- supprimée : ses questions gardent leur lien et la décision reste lisible.
    merged_into_id uuid REFERENCES civic_notions (id),
    created_at     timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT uq_civic_notion_code UNIQUE (code),
    CONSTRAINT chk_civic_notion_merge_desactive CHECK (
        merged_into_id IS NULL OR is_active = false
    ),
    CONSTRAINT chk_civic_notion_pas_de_fusion_sur_soi CHECK (merged_into_id <> id)
);

COMMENT ON TABLE civic_notions IS
    'Referentiel de TRAVAIL des notions civiques (50_ §6.1). Ajustable a la '
    'porte de revue apres tagging : une notion fusionnee est desactivee et '
    'pointe vers celle qui la reprend, jamais supprimee.';

CREATE INDEX idx_civic_notion_theme
    ON civic_notions (theme_code, display_order)
    WHERE is_active = true;

-- Le tag VALIDE d'une question. Additif : colonne nullable, aucune reecriture.
ALTER TABLE questions
    ADD COLUMN civic_notion_id uuid REFERENCES civic_notions (id);

COMMENT ON COLUMN questions.civic_notion_id IS
    'Notion civique VALIDEE PAR UN HUMAIN. NULL = pas encore taguee, jamais '
    '« sans notion » : une question non taguee attend, elle n''est pas hors '
    'programme.';

CREATE INDEX idx_question_civic_notion
    ON questions (civic_notion_id)
    WHERE civic_notion_id IS NOT NULL;

-- Ce qu'une machine PROPOSE. Aucune de ces lignes ne vaut decision.
CREATE TABLE question_notion_suggestions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id uuid NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    notion_id   uuid NOT NULL REFERENCES civic_notions (id) ON DELETE CASCADE,
    -- 0 a 1. Sert a reperer les notions qui se disputent les memes questions
    -- (§6.1.3 : « plus de 30 % de suggestions hesitantes entre elles »).
    confidence  numeric(4, 3) NOT NULL,
    model       varchar(120),
    created_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_question_notion_suggestion UNIQUE (question_id, notion_id),
    CONSTRAINT chk_question_notion_confidence CHECK (confidence >= 0 AND confidence <= 1)
);

COMMENT ON TABLE question_notion_suggestions IS
    'Propositions de tagging par une machine, avec confiance. CREEE VIDE : la '
    'remplir coute un appel LLM paye, et c''est une decision du proprietaire. '
    'Le job propose, un humain valide (50_ §6.1.3).';

CREATE INDEX idx_question_notion_suggestion_question
    ON question_notion_suggestions (question_id, confidence DESC);

-- ----------------------------------------------------------------------------
-- Le référentiel de travail de `50_` §6.1.1 : 40 notions, cinq thèmes.
--
-- 🛑 Ces 40 notions ne sont NI validées NI définitives. Elles servent à
-- commencer le tagging, qui dira lesquelles fusionnent, lesquelles se scindent
-- et lesquelles disparaissent (porte de revue §6.1.3). Les quatre couples que
-- la spec signale comme « à surveiller » sont seedés tels quels, séparés :
-- `dd_logement` / `vs_logement_pratique`, `pv_laicite` / `vs_laicite_quotidien`,
-- `inst_commune` / `inst_departement_region`, `hg_patrimoine` /
-- `hg_langue_culture`. Les fusionner d'avance déciderait à la place des pièces.
--
-- UUID déterministes, `ON CONFLICT DO NOTHING` : rejouable sans effet.
-- ----------------------------------------------------------------------------

INSERT INTO civic_notions (id, code, label, theme_code, display_order)
VALUES
    ('c1010000-0000-5000-8000-000000000001', 'pv_laicite', 'La laïcité', 'CIV_PRINCIPES', 1),
    ('c1010000-0000-5000-8000-000000000002', 'pv_symboles', 'Les symboles de la République', 'CIV_PRINCIPES', 2),
    ('c1010000-0000-5000-8000-000000000003', 'pv_devise_valeurs', 'La devise et les valeurs républicaines', 'CIV_PRINCIPES', 3),
    ('c1010000-0000-5000-8000-000000000004', 'pv_egalite_non_discrimination', 'Égalité et refus des discriminations', 'CIV_PRINCIPES', 4),
    ('c1010000-0000-5000-8000-000000000005', 'pv_libertes_fondamentales', 'Les libertés fondamentales', 'CIV_PRINCIPES', 5),
    ('c1010000-0000-5000-8000-000000000006', 'pv_ddhc', 'La Déclaration des droits de l''homme et du citoyen', 'CIV_PRINCIPES', 6),
    ('c1010000-0000-5000-8000-000000000007', 'inst_constitution', 'La Constitution et la Ve République', 'CIV_INSTITUTIONS', 1),
    ('c1010000-0000-5000-8000-000000000008', 'inst_president', 'Le Président de la République', 'CIV_INSTITUTIONS', 2),
    ('c1010000-0000-5000-8000-000000000009', 'inst_gouvernement', 'Le Gouvernement et le Premier ministre', 'CIV_INSTITUTIONS', 3),
    ('c1010000-0000-5000-8000-000000000010', 'inst_parlement', 'Le Parlement : Assemblée nationale et Sénat', 'CIV_INSTITUTIONS', 4),
    ('c1010000-0000-5000-8000-000000000011', 'inst_elections', 'Les élections et le droit de vote', 'CIV_INSTITUTIONS', 5),
    ('c1010000-0000-5000-8000-000000000012', 'inst_commune', 'La commune et le maire', 'CIV_INSTITUTIONS', 6),
    ('c1010000-0000-5000-8000-000000000013', 'inst_departement_region', 'Le département et la région', 'CIV_INSTITUTIONS', 7),
    ('c1010000-0000-5000-8000-000000000014', 'inst_justice', 'La justice et les tribunaux', 'CIV_INSTITUTIONS', 8),
    ('c1010000-0000-5000-8000-000000000015', 'inst_ue', 'L''Union européenne', 'CIV_INSTITUTIONS', 9),
    ('c1010000-0000-5000-8000-000000000016', 'dd_droits_fondamentaux', 'Les droits fondamentaux', 'CIV_DROITS_DEVOIRS', 1),
    ('c1010000-0000-5000-8000-000000000017', 'dd_devoirs_citoyen', 'Les devoirs : lois, impôts, jury', 'CIV_DROITS_DEVOIRS', 2),
    ('c1010000-0000-5000-8000-000000000018', 'dd_egalite_loi', 'L''égalité devant la loi', 'CIV_DROITS_DEVOIRS', 3),
    ('c1010000-0000-5000-8000-000000000019', 'dd_travail', 'Droits et devoirs au travail', 'CIV_DROITS_DEVOIRS', 4),
    ('c1010000-0000-5000-8000-000000000020', 'dd_protection_sociale', 'Protection sociale et assurance maladie', 'CIV_DROITS_DEVOIRS', 5),
    ('c1010000-0000-5000-8000-000000000021', 'dd_ecole_enfance', 'École obligatoire et droits de l''enfant', 'CIV_DROITS_DEVOIRS', 6),
    ('c1010000-0000-5000-8000-000000000022', 'dd_logement', 'Droits et obligations liés au logement', 'CIV_DROITS_DEVOIRS', 7),
    ('c1010000-0000-5000-8000-000000000023', 'dd_liberte_culte', 'La liberté de culte et ses limites', 'CIV_DROITS_DEVOIRS', 8),
    ('c1010000-0000-5000-8000-000000000024', 'hg_revolution', 'La Révolution française et 1789', 'CIV_HISTOIRE_GEO', 1),
    ('c1010000-0000-5000-8000-000000000025', 'hg_dates_republique', 'Les grandes dates de la République', 'CIV_HISTOIRE_GEO', 2),
    ('c1010000-0000-5000-8000-000000000026', 'hg_loi_1905', 'La séparation des Églises et de l''État', 'CIV_HISTOIRE_GEO', 3),
    ('c1010000-0000-5000-8000-000000000027', 'hg_guerres_resistance', 'Les guerres mondiales et la Résistance', 'CIV_HISTOIRE_GEO', 4),
    ('c1010000-0000-5000-8000-000000000028', 'hg_conquetes_droits', 'Les grandes conquêtes de droits', 'CIV_HISTOIRE_GEO', 5),
    ('c1010000-0000-5000-8000-000000000029', 'hg_europe', 'La construction européenne', 'CIV_HISTOIRE_GEO', 6),
    ('c1010000-0000-5000-8000-000000000030', 'hg_geographie', 'Géographie de la France et outre-mer', 'CIV_HISTOIRE_GEO', 7),
    ('c1010000-0000-5000-8000-000000000031', 'hg_patrimoine', 'Patrimoine et monuments', 'CIV_HISTOIRE_GEO', 8),
    ('c1010000-0000-5000-8000-000000000032', 'hg_langue_culture', 'Langue française, culture et francophonie', 'CIV_HISTOIRE_GEO', 9),
    ('c1010000-0000-5000-8000-000000000033', 'vs_demarches', 'Les démarches administratives courantes', 'CIV_SOCIETE', 1),
    ('c1010000-0000-5000-8000-000000000034', 'vs_sante', 'Se soigner au quotidien', 'CIV_SOCIETE', 2),
    ('c1010000-0000-5000-8000-000000000035', 'vs_logement_pratique', 'Se loger : bail, aides, voisinage', 'CIV_SOCIETE', 3),
    ('c1010000-0000-5000-8000-000000000036', 'vs_emploi', 'Travailler et chercher un emploi', 'CIV_SOCIETE', 4),
    ('c1010000-0000-5000-8000-000000000037', 'vs_transports_securite', 'Transports, sécurité routière et urgences', 'CIV_SOCIETE', 5),
    ('c1010000-0000-5000-8000-000000000038', 'vs_budget_impots', 'Budget, banque et impôts', 'CIV_SOCIETE', 6),
    ('c1010000-0000-5000-8000-000000000039', 'vs_vie_collective', 'Vivre ensemble et respect des règles', 'CIV_SOCIETE', 7),
    ('c1010000-0000-5000-8000-000000000040', 'vs_laicite_quotidien', 'La laïcité dans la vie quotidienne', 'CIV_SOCIETE', 8)
ON CONFLICT (code) DO NOTHING;
