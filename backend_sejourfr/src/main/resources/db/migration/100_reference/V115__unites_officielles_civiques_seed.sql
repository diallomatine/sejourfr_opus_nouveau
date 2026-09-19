-- ============================================================================
-- V115 — REFERENCE : les 16 unites officielles de l'examen civique, et le
--        RATTACHEMENT des 46 notions internes
-- ----------------------------------------------------------------------------
-- Le DDL est en `00_schema/V068__unites_officielles_examen_civique.sql`, qui
-- porte aussi tout l'argumentaire (pourquoi cette table existe a cote de
-- `civic_notions`, ou vit quoi, et les trois garde-fous de D-38).
--
-- SOURCE DE DROIT : arrete du 10 octobre 2025 relatif au programme, aux epreuves
-- et aux modalites d'organisation de l'examen civique -- JORF n° 0240 du
-- 12 octobre 2025, NOR INTV2527907A, articles 1 a 3 et ANNEXE I. Verifie sur
-- Legifrance le 2026-09-19 :
--   https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000052381620
--
-- Arbitrages : docs/decisions/plan-parcours-tcf.md D-25, D-26, D-35, D-38, D-41.
--
-- 🛑 POURQUOI ICI ET PAS EN V068. `civic_official_units.theme_code` porte une FK
-- reelle vers `themes(code)`, et les 5 themes civiques sont seedes par V101 --
-- donc APRES tout `00_schema/`. Un INSERT en V068 viole la FK, mesure faite.
-- Le decoupage suit la convention des dossiers : le DDL en `00_schema/`, la
-- donnee de reference en `100_reference/`.
--
-- 🛑 CETTE MIGRATION NE TOUCHE PAS AU FILTRE DE MENTION (D-41). Le retrait de
-- `q.difficulty = :mention` est P8.2b, APRES P8.A.
-- ============================================================================

-- Le seed, thematique par thematique (annexe I de l'arrete).
-- UUID fixes et lisibles (patron de `themes`) : une table seedee une fois se
-- reference par un id stable, y compris depuis un test.
INSERT INTO civic_official_units (id, code, theme_code, label, display_order, exam_quota, question_type)
VALUES
-- T1 — Principes et valeurs de la Republique : 3 + 2 + 6 = 11
('16161616-0000-0000-0000-000000000001', 'P1_DEVISE_SYMBOLES',   'CIV_PRINCIPES',
 'Devise et symboles', 1, 3, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000002', 'P2_LAICITE',           'CIV_PRINCIPES',
 'Laïcité', 2, 2, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000003', 'P3_MISES_EN_SITUATION','CIV_PRINCIPES',
 'Mises en situation', 3, 6, 'MISE_SITUATION'),

-- T2 — Systeme institutionnel et politique : 3 + 2 + 1 = 6
('16161616-0000-0000-0000-000000000004', 'I1_DEMOCRATIE_VOTE',   'CIV_INSTITUTIONS',
 'Démocratie et droit de vote', 1, 3, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000005', 'I2_ORGANISATION_REPUBLIQUE', 'CIV_INSTITUTIONS',
 'Organisation de la République', 2, 2, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000006', 'I3_INSTITUTIONS_EUROPEENNES', 'CIV_INSTITUTIONS',
 'Institutions européennes', 3, 1, 'CONNAISSANCE'),

-- T3 — Droits et devoirs : 2 + 3 + 6 = 11
('16161616-0000-0000-0000-000000000007', 'D1_DROITS_FONDAMENTAUX', 'CIV_DROITS_DEVOIRS',
 'Droits fondamentaux', 1, 2, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000008', 'D2_OBLIGATIONS_DEVOIRS', 'CIV_DROITS_DEVOIRS',
 'Obligations et devoirs', 2, 3, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000009', 'D3_MISES_EN_SITUATION',  'CIV_DROITS_DEVOIRS',
 'Mises en situation', 3, 6, 'MISE_SITUATION'),

-- T4 — Histoire, geographie et culture : 3 + 3 + 2 = 8
('16161616-0000-0000-0000-000000000010', 'H1_PERIODES_PERSONNAGES', 'CIV_HISTOIRE_GEO',
 'Périodes et personnages historiques', 1, 3, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000011', 'H2_TERRITOIRES_GEOGRAPHIE', 'CIV_HISTOIRE_GEO',
 'Territoires et géographie', 2, 3, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000012', 'H3_PATRIMOINE',            'CIV_HISTOIRE_GEO',
 'Patrimoine français', 3, 2, 'CONNAISSANCE'),

-- T5 — Vivre dans la societe francaise : 1 + 1 + 1 + 1 = 4
('16161616-0000-0000-0000-000000000013', 'S1_S_INSTALLER',      'CIV_SOCIETE',
 'S''installer et résider', 1, 1, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000014', 'S2_ACCES_AUX_SOINS',  'CIV_SOCIETE',
 'Accès aux soins', 2, 1, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000015', 'S3_TRAVAILLER',       'CIV_SOCIETE',
 'Travailler', 3, 1, 'CONNAISSANCE'),
('16161616-0000-0000-0000-000000000016', 'S4_AUTORITE_PARENTALE_EDUCATION', 'CIV_SOCIETE',
 'Autorité parentale et système éducatif', 4, 1, 'CONNAISSANCE');

-- ============================================================================
-- LE RATTACHEMENT DES 46 NOTIONS INTERNES
-- ============================================================================
-- 🛑 C'EST UNE CORRESPONDANCE ARBITREE, PAS UNE MESURE. Elle a ete construite a
-- partir du `label` ET de la `description` de chaque notion -- les descriptions
-- de V058 nomment leurs frontieres, ce qui permet de trancher. Le detail, avec
-- les neuf rattachements discutables, vit dans
-- docs/audits/AUDIT_cycle_plan_civique_v2.md, annexe A.
--
UPDATE civic_notions n SET official_unit_id = u.id
FROM civic_official_units u
WHERE u.code = CASE n.code
    -- T1 Principes -----------------------------------------------------------
    WHEN 'pv_symboles_devise'            THEN 'P1_DEVISE_SYMBOLES'
    WHEN 'pv_laicite'                    THEN 'P2_LAICITE'
    -- ⚠️ « Le principe, pas l'organe » (sa description) : l'annexe I n'a pas de
    -- notion « principe republicain » hors Devise et Laicite.
    WHEN 'pv_republique_democratie'      THEN 'I1_DEMOCRATIE_VOTE'
    -- ⚠️ L'egalite comme DROIT, pas comme mot de la devise (sa description).
    WHEN 'pv_egalite_non_discrimination' THEN 'D1_DROITS_FONDAMENTAUX'
    -- ⚠️ Sa propre description l'annonce : « Recouvrement ASSUME avec
    -- CIV_DROITS_DEVOIRS [...] la frontiere la plus fragile du referentiel ».
    WHEN 'pv_libertes_ddhc'              THEN 'D1_DROITS_FONDAMENTAUX'

    -- T2 Institutions --------------------------------------------------------
    WHEN 'inst_elections'                THEN 'I1_DEMOCRATIE_VOTE'
    WHEN 'inst_constitution'             THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_president'                THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_gouvernement'             THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_parlement'                THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_collectivites'            THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_justice'                  THEN 'I2_ORGANISATION_REPUBLIQUE'
    WHEN 'inst_ue'                       THEN 'I3_INSTITUTIONS_EUROPEENNES'

    -- T3 Droits et devoirs ---------------------------------------------------
    WHEN 'dd_textes_fondateurs'          THEN 'D1_DROITS_FONDAMENTAUX'
    WHEN 'dd_libertes_limites'           THEN 'D1_DROITS_FONDAMENTAUX'
    -- ⚠️ Chevauche S2 et S3 ; sa regle tranche : « un droit devant un JUGE reste
    -- ici ; un formulaire a un GUICHET part la-bas ».
    WHEN 'dd_droits_sociaux'             THEN 'D1_DROITS_FONDAMENTAUX'
    -- ⚠️ Chevauche S4 (autorite parentale) ; le sujet reste la sphere intime.
    WHEN 'dd_vie_privee_famille'         THEN 'D1_DROITS_FONDAMENTAUX'
    -- ⚠️ Chevauche I2 (les tribunaux) ; sa regle tranche : « ce que FONT les
    -- forces de l'ordre est un service ; ce que je peux LEUR OPPOSER est un droit ».
    WHEN 'dd_police_justice'             THEN 'D1_DROITS_FONDAMENTAUX'
    -- ⚠️ Chevauche I3 ; sa description exclut « le fonctionnement POLITIQUE de l'UE ».
    WHEN 'dd_protection_europeenne'      THEN 'D1_DROITS_FONDAMENTAUX'
    WHEN 'dd_devoirs_citoyen'            THEN 'D2_OBLIGATIONS_DEVOIRS'
    WHEN 'dd_interdits_quotidien'        THEN 'D2_OBLIGATIONS_DEVOIRS'
    WHEN 'dd_infractions_peines'         THEN 'D2_OBLIGATIONS_DEVOIRS'

    -- T4 Histoire ------------------------------------------------------------
    WHEN 'hg_revolution'                 THEN 'H1_PERIODES_PERSONNAGES'
    WHEN 'hg_napoleon_xixe'              THEN 'H1_PERIODES_PERSONNAGES'
    WHEN 'hg_republiques'                THEN 'H1_PERIODES_PERSONNAGES'
    WHEN 'hg_guerres_resistance'         THEN 'H1_PERIODES_PERSONNAGES'
    WHEN 'hg_conquetes_droits'           THEN 'H1_PERIODES_PERSONNAGES'
    -- ⚠️ Chevauche I3 ; sa description exclut « les institutions D'AUJOURD'HUI ».
    -- La construction europeenne est une PERIODE, vue de France.
    WHEN 'hg_europe'                     THEN 'H1_PERIODES_PERSONNAGES'
    WHEN 'hg_geographie'                 THEN 'H2_TERRITOIRES_GEOGRAPHIE'
    WHEN 'hg_patrimoine'                 THEN 'H3_PATRIMOINE'
    WHEN 'hg_litterature'                THEN 'H3_PATRIMOINE'
    WHEN 'hg_arts_sciences'              THEN 'H3_PATRIMOINE'
    WHEN 'hg_art_de_vivre'               THEN 'H3_PATRIMOINE'
    -- ⚠️ Chevauche P1 ; sa description renvoie « le 14 juillet comme FETE
    -- NATIONALE ET SYMBOLE » vers CIV_PRINCIPES, le reste est du calendrier.
    WHEN 'hg_fetes_jours_feries'         THEN 'H3_PATRIMOINE'

    -- T5 Vivre dans la societe francaise -------------------------------------
    WHEN 'vs_papiers_identite'           THEN 'S1_S_INSTALLER'
    WHEN 'vs_sejour_asile'               THEN 'S1_S_INSTALLER'
    WHEN 'vs_nationalite_francaise'      THEN 'S1_S_INSTALLER'
    -- ⚠️ RATTACHEMENT FAIBLE, signale comme tel : le permis et la securite
    -- routiere ne figurent dans AUCUNE des quatre unites officielles de T5.
    WHEN 'vs_deplacements_route'         THEN 'S1_S_INSTALLER'
    WHEN 'vs_sante_soins'                THEN 'S2_ACCES_AUX_SOINS'
    -- ⚠️ Chevauche S3 (cotisations, retraite) ; la Secu penche vers les soins.
    WHEN 'vs_protection_sociale_aides'   THEN 'S2_ACCES_AUX_SOINS'
    -- 🛑 ARBITRAGE DU PROPRIETAIRE (Q-F28, D-35), et ce n'est PAS un choix
    -- d'audit : l'annexe I range explicitement les NUMEROS D'URGENCE sous
    -- « L'acces aux soins ». L'audit v1 la donnait « sans rattachement ».
    WHEN 'vs_urgences_secours'           THEN 'S2_ACCES_AUX_SOINS'
    WHEN 'vs_travail_contrat_salaire'    THEN 'S3_TRAVAILLER'
    WHEN 'vs_travail_entreprise'         THEN 'S3_TRAVAILLER'
    WHEN 'vs_emploi_formation'           THEN 'S3_TRAVAILLER'
    WHEN 'vs_ecole_scolarite'            THEN 'S4_AUTORITE_PARENTALE_EDUCATION'
    WHEN 'vs_famille_etat_civil'         THEN 'S4_AUTORITE_PARENTALE_EDUCATION'
  END
  AND n.is_active = true;

-- 🛑 UNE NOTION ACTIVE SANS UNITE OFFICIELLE EST UNE NOTION HORS PROGRAMME.
-- Le CHECK est pose APRES l'UPDATE, et il vaut pour l'avenir : la prochaine
-- notion editoriale devra dire de quelle unite de l'arrete elle releve.
-- Les 14 desactivees restent a NULL, et c'est le sens de la clause.
ALTER TABLE civic_notions
    ADD CONSTRAINT chk_civic_notion_rattachee
    CHECK (is_active = false OR official_unit_id IS NOT NULL);
