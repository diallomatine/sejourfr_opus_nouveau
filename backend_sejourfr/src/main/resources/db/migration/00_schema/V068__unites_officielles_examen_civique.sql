-- ============================================================================
-- V068 — LES 16 UNITES OFFICIELLES DE L'EXAMEN CIVIQUE, ET LE RATTACHEMENT
--        DES 46 NOTIONS INTERNES
-- ----------------------------------------------------------------------------
-- SOURCE DE DROIT : arrete du 10 octobre 2025 relatif au programme, aux
-- epreuves et aux modalites d'organisation de l'examen civique -- JORF n° 0240
-- du 12 octobre 2025, NOR INTV2527907A, articles 1 a 3 et ANNEXE I.
-- Verifie sur Legifrance le 2026-09-19 :
--   https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052381620
--
-- Arbitrages : docs/decisions/plan-parcours-tcf.md D-25, D-26, D-38, D-41
-- (2026-09-19). Cadre fonctionnel : docs/progression/civique/SPEC_cycle_plan_civique.md.
-- Mesures qui l'ont produite : docs/audits/AUDIT_cycle_plan_civique_v2.md.
--
-- ============================================================================
-- POURQUOI CETTE TABLE EXISTE, ALORS QUE `civic_notions` EXISTE DEJA
-- ============================================================================
-- Ce ne sont pas deux versions du meme objet, ce sont DEUX OBJETS DE NATURE
-- DIFFERENTE, et le depot a paye cher de les avoir confondus :
--
--   * `civic_notions` (46 actives) est une TAXONOMIE EDITORIALE. V058 le dit :
--     « le referentiel a ete reconstruit A PARTIR DU CORPUS REEL plutot que
--     deduit ». Elle sert a ECRIRE et a RELIRE des questions, et a choisir quoi
--     faire travailler. Elle bouge (`merged_into_id`, `is_active`).
--   * `civic_official_units` (16) est LE PROGRAMME. Elle sert a TIRER un examen
--     conforme et a MESURER un candidat. Elle ne bouge que si l'arrete bouge.
--
-- 🛑 LA PHRASE DE V058 EST REVOQUEE (D-25). « CSP, CR et NAT ne sont pas trois
-- niveaux du meme programme : ce sont trois programmes differents » est FAUX au
-- regard de l'arrete -- art. 3 : « POUR TOUTES LES MENTIONS, l'epreuve [...]
-- comprenant quarante questions », sur UNE SEULE annexe I. Le raisonnement etait
-- circulaire : le corpus a ete ecrit par mention, puis on a deduit du corpus que
-- le programme l'etait. Mesure a l'appui : sur 976 questions actives, 15 (1,5 %)
-- citent une demarche, et AUCUNE n'est exclusive d'une demarche.
-- V058 reste en base telle quelle : une migration livree ne se reecrit pas.
--
-- ============================================================================
-- CE QUI EST ICI, ET CE QUI EST AILLEURS (D-38)
-- ============================================================================
--   * ICI            : le quota par unite (`exam_quota`).
--   * CivicExamFormat: 40 questions, seuil 32, 45 min, partage 28 / 12.
--   * NULLE PART     : les totaux par thematique (11 / 6 / 11 / 8 / 4). Ils se
--                      DERIVENT par somme des quotas. Les declarer en ferait une
--                      2e copie, et un jour l'une des deux aurait tort.
--
-- ============================================================================
-- LES TROIS GARDE-FOUS, PARCE QU'ON MET DE LA LOI DANS UNE TABLE (D-38)
-- ============================================================================
--   1. SEEDEE PAR MIGRATION, PAS EDITABLE EN ADMIN. Aucun endpoint, aucun ecran.
--      `AdminCivicNotionController` ne sait que LIRE le referentiel et taguer une
--      question -- il ne cree aucune notion, et il ne touchera pas cette table.
--      Une valeur d'arrete ne se modifie pas depuis une interface.
--   2. LA SOMME DES QUOTAS VAUT 40, ET LES MISES EN SITUATION 12 : verifie par
--      un TEST NORMATIF (`CivicOfficialUnitSeedIT`), pas par un CHECK.
--      🛑 Postgres refuse une sous-requete en contrainte de verification
--      (« cannot use subquery in check constraint ») et un CHECK est PAR LIGNE :
--      il ne peut pas sommer 16 lignes. Un trigger serait disproportionne sur une
--      table seedee une fois et jamais editee. D-38 autorisait les deux.
--   3. LES 16 LIGNES ET LEURS QUOTAS SONT VERROUILLES par le meme test, avec
--      l'arrete cite.
--
-- ============================================================================
-- 🛑 POURQUOI LE SEED N'EST PAS ICI, MAIS EN V115
-- ============================================================================
-- `civic_official_units.theme_code` porte une FK REELLE vers `themes(code)` --
-- contrairement a `civic_notions.theme_code`, qui n'en a pas. Cette FK vaut son
-- prix : une unite officielle rangee sous un theme inexistant serait une trace
-- fausse. Mais elle impose un ORDRE : les 5 themes civiques sont seedes par
-- `100_reference/V101__ref_themes.sql`, donc APRES toute migration de
-- `00_schema/`. Un INSERT ici echouerait -- mesure faite, la FK est violee.
--
-- D'ou le decoupage, qui suit d'ailleurs la convention des dossiers :
--   * V068 (00_schema)     : le DDL -- table, colonne, index, contraintes.
--   * V115 (100_reference) : le SEED des 16 unites, le RATTACHEMENT des 46
--                            notions, et le CHECK qui exige ce rattachement.
--
-- ⚠️ C'est aussi pourquoi `civic_notions` (seedee en V051, dans 00_schema) n'a
-- jamais eu de FK sur `themes` : la contrainte etait impossible a cet endroit.
-- On ne la lui ajoute pas au passage -- ce serait une refonte de V051 hors
-- perimetre. La table neuve, elle, peut faire mieux.

-- 🛑 CETTE MIGRATION NE TOUCHE PAS AU FILTRE DE MENTION (D-41). Le retrait de
-- `q.difficulty = :mention` est P8.2b, APRES P8.A : P8.A doit etre ecrit et
-- teste avant que le retrait change les resultats de tirage, sinon un ecart de
-- mesure n'est plus attribuable. Verifie : aucun des trois garde-fous ci-dessus
-- ne lit `questions.difficulty`. La separation tient.
-- ============================================================================

CREATE TABLE civic_official_units (
    id            uuid         PRIMARY KEY,
    code          varchar(40)  NOT NULL,
    -- Le theme d'appartenance, par son CODE. FK reelle, contrairement a
    -- `civic_notions.theme_code` : `themes.code` porte `uk_theme_code`, et une
    -- unite officielle rangee sous un theme inexistant serait une trace fausse.
    theme_code    varchar(64)  NOT NULL REFERENCES themes (code),
    -- Le libelle de l'annexe I, tel qu'il s'affiche au candidat. C'est ce que
    -- l'ecran lit : le vocabulaire interne (`lot`, `step`, `notion`) n'apparait
    -- jamais (D-21).
    label         varchar(160) NOT NULL,
    display_order smallint     NOT NULL,
    -- Le nombre de questions que l'examen reel tire sur cette unite. Somme = 40.
    exam_quota    smallint     NOT NULL,
    -- 🛑 LE TYPE DE QUESTION QUE L'UNITE PORTE, et non un booleen « est-ce une
    -- mise en situation ». C'est ce que le tirage conforme (P8.A) consommera
    -- directement, et ca reutilise le vocabulaire de `questions.question_type`
    -- au lieu d'en inventer un second.
    question_type varchar(24)  NOT NULL,
    created_at    timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT uq_civic_official_unit_code UNIQUE (code),
    CONSTRAINT uq_civic_official_unit_order UNIQUE (theme_code, display_order),
    CONSTRAINT chk_civic_official_unit_quota CHECK (exam_quota BETWEEN 1 AND 40),
    CONSTRAINT chk_civic_official_unit_type CHECK (
        question_type IN ('CONNAISSANCE', 'MISE_SITUATION')
    )
);

-- 🛑 UNE SEULE unite de mises en situation par thematique. L'annexe I en place
-- une en « Principes et valeurs » et une en « Droits et devoirs », et aucune
-- ailleurs. Deux lignes MISE_SITUATION sur le meme theme voudraient dire que
-- l'arrete a change ; l'index le refuse.
CREATE UNIQUE INDEX uq_civic_official_unit_mes_par_theme
    ON civic_official_units (theme_code)
    WHERE question_type = 'MISE_SITUATION';

COMMENT ON TABLE civic_official_units IS
    'Les 16 unites du programme officiel de l''examen civique (arrete du '
    '10 octobre 2025, annexe I) : 14 notions de connaissance + 2 unites de mises '
    'en situation. LE PROGRAMME, a distinguer de `civic_notions`, qui est la '
    'taxonomie editoriale. Seedee par migration, jamais editable en admin.';
COMMENT ON COLUMN civic_official_units.exam_quota IS
    'Questions tirees sur cette unite dans un examen de 40. Somme des 16 = 40, '
    'dont 12 en MISE_SITUATION. Verifie par test normatif, pas par CHECK : un '
    'CHECK est par ligne et ne peut pas sommer 16 lignes.';

-- ============================================================================
-- LE RATTACHEMENT DES NOTIONS INTERNES — la colonne, ici ; les valeurs, en V115
-- ============================================================================
-- NULLABLE, et c'est voulu : les 14 notions DESACTIVEES (dont 13 fusionnees) ne
-- sont plus au programme et n'ont rien a rattacher.
--
-- ⚠️ `chk_civic_notion_rattachee` -- « une notion ACTIVE porte toujours une
-- unite » -- n'est PAS ici : elle ne peut etre posee qu'APRES l'UPDATE qui
-- rattache les 46, donc en V115. C'est la seule contrainte du lot qui quitte
-- `00_schema/`, et elle le fait pour une raison nommee : elle depend de donnees
-- que ce dossier n'a pas le droit de seeder.
ALTER TABLE civic_notions
    ADD COLUMN official_unit_id uuid REFERENCES civic_official_units (id);

COMMENT ON COLUMN civic_notions.official_unit_id IS
    'L''unite du programme officiel dont cette notion editoriale releve (arrete '
    'du 10 octobre 2025, annexe I). Correspondance ARBITREE, pas mesuree : cf. '
    'AUDIT_cycle_plan_civique_v2.md annexe A. NULL sur une notion desactivee.';

CREATE INDEX idx_civic_notion_official_unit
    ON civic_notions (official_unit_id)
    WHERE official_unit_id IS NOT NULL;
