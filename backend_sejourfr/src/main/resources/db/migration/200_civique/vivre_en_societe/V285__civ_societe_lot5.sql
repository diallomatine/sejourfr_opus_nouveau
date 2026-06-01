-- ============================================================================
-- V285 — Civique : Vivre en société (lot 5)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000005 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f5000002-0000-0000-0000-0000000000e5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel âge permet l''émancipation d''un mineur en France ?',
   'L''émancipation est possible dès 16 ans, prononcée par le juge des tutelles à la demande des parents ou du mineur. Le mineur émancipé devient juridiquement majeur (sauf droits politiques).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000e6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne la ''tutelle'' juridique ?',
   'La tutelle est une mesure de protection pour les personnes (majeures ou mineures) incapables de protéger leurs intérêts. Un tuteur (désigné par le juge) prend les décisions importantes pour la personne.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000e7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le ''service civique'' en France ?',
   'Le service civique est un engagement volontaire de 6 à 12 mois (jeunes 16-25 ans, 30 ans pour personnes en situation de handicap) pour une mission d''intérêt général. Indemnisé par l''État. Différents domaines : solidarité, environnement, culture.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000e8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne la ''caution'' dans la location d''un logement ?',
   'La caution (dépôt de garantie) est une somme versée au propriétaire au début du bail. Elle est restituée au départ, déduction faite des réparations locatives éventuelles. Maximum : 1 mois de loyer hors charges (vide).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quelle distinction fait le droit français entre les syndicats représentatifs et les autres ?',
   'Un syndicat est représentatif au niveau national/professionnel s''il remplit 7 critères : indépendance, transparence financière, ancienneté, audience aux élections, etc. Cela lui donne le droit de négocier les conventions collectives.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne le ''travail dissimulé'' en droit pénal ?',
   'Le travail dissimulé (article L. 8221-1 du Code du travail) est le fait d''occuper un salarié sans déclaration préalable, sans bulletin de paie ou en sous-déclarant les heures effectuées. C''est un délit puni de 3 ans de prison.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne le ''plan d''épargne entreprise'' (PEE) ?',
   'Le PEE permet aux salariés de se constituer une épargne avec l''aide de l''employeur (abondement). Les sommes sont bloquées 5 ans (sauf cas de déblocage anticipé). Avantages fiscaux à la sortie.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f4', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la ''participation aux bénéfices'' obligatoire en entreprise ?',
   'La participation aux bénéfices, obligatoire dans les entreprises de 50 salariés ou plus, redistribue une partie des bénéfices aux salariés (formule légale). Les sommes peuvent être versées au PEE ou directement.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne le ''mandat de protection future'' ?',
   'Le mandat de protection future permet à une personne de désigner à l''avance la personne qui s''occupera de ses biens et/ou de sa personne le jour où elle ne pourra plus le faire elle-même (vieillissement, maladie).',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne le ''pacte civil de solidarité'' (PACS) sur le plan juridique ?',
   'Le PACS, créé en 1999, est un contrat entre 2 personnes majeures pour organiser leur vie commune. Il offre des droits proches du mariage (fiscalité, prestations) mais avec moins de formalités de dissolution.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la ''protection sociale'' au sens large en France ?',
   'La protection sociale couvre l''ensemble des dispositifs (Sécurité sociale, assurance chômage, retraite, aide sociale, allocations familiales) qui protègent les individus contre les risques de la vie : maladie, vieillesse, chômage, famille, pauvreté.',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-0000000000f8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne l''expression ''État-providence'' ?',
   'L''État-providence désigne le modèle social où l''État assure la protection sociale et redistribue les richesses pour réduire les inégalités (santé, retraites, allocations, services publics gratuits ou subventionnés).',
   'true', '2026-05-27 17:40:30.128245+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('8cb8e7a9-e83a-471c-b04c-a16ccace15e8', 'f5000002-0000-0000-0000-0000000000e5',
   '16 ans, sur décision du juge des tutelles',
   'true', '0'),

  ('be99e8d5-95b4-4df2-bc7f-8dad5be42c52', 'f5000002-0000-0000-0000-0000000000e5',
   '14 ans automatiquement',
   'false', '1'),

  ('f15c05fb-acd5-4fff-9e12-fd57d4e17300', 'f5000002-0000-0000-0000-0000000000e5',
   '12 ans par les parents',
   'false', '2'),

  ('f81acb3d-0a39-4889-920c-40ae9091209a', 'f5000002-0000-0000-0000-0000000000e5',
   'Impossible avant 18 ans',
   'false', '3'),

  ('0a91995a-7069-45bc-8e77-e21e9f40cc8f', 'f5000002-0000-0000-0000-0000000000e6',
   'Une mesure de protection pour personnes vulnérables',
   'true', '0'),

  ('980720f9-a2e5-411f-8f12-2b6804fde1ff', 'f5000002-0000-0000-0000-0000000000e6',
   'Une amende',
   'false', '1'),

  ('40d222ed-5dad-40c1-91ca-977e3eedd8e1', 'f5000002-0000-0000-0000-0000000000e6',
   'Un syndicat',
   'false', '2'),

  ('f14183f8-ab65-4235-9143-10789b4e22b7', 'f5000002-0000-0000-0000-0000000000e6',
   'Une assurance',
   'false', '3'),

  ('84d22c0f-3b96-4765-be22-d2b00317627a', 'f5000002-0000-0000-0000-0000000000e7',
   'Un engagement volontaire des jeunes pour l''intérêt général',
   'true', '0'),

  ('5ff35dde-3832-41b9-a02c-044cbcdef85d', 'f5000002-0000-0000-0000-0000000000e7',
   'Le service militaire obligatoire',
   'false', '1'),

  ('9d9d33e1-153b-40b4-9f2e-7c38cb268aa3', 'f5000002-0000-0000-0000-0000000000e7',
   'Un stage obligatoire',
   'false', '2'),

  ('3a552399-2c8b-4a94-b906-3929ec6933c4', 'f5000002-0000-0000-0000-0000000000e7',
   'Un mariage civil',
   'false', '3'),

  ('91c795f7-b125-4d31-b658-fa4a783e9773', 'f5000002-0000-0000-0000-0000000000e8',
   'Un dépôt de garantie restitué au départ, sauf réparations',
   'true', '0'),

  ('bbf15dd4-4ff5-4cd3-9d61-645559f809a7', 'f5000002-0000-0000-0000-0000000000e8',
   'Une amende',
   'false', '1'),

  ('53936b47-7c7e-493b-88cc-f28c1c8f5b3d', 'f5000002-0000-0000-0000-0000000000e8',
   'Un cadeau au propriétaire',
   'false', '2'),

  ('1e1c71e9-a2f7-44c2-b3d5-17bf45e5e378', 'f5000002-0000-0000-0000-0000000000e8',
   'Une assurance auto',
   'false', '3'),

  ('525efb23-9f2d-404d-91f1-c75787bfa64b', 'f5000002-0000-0000-0000-0000000000f1',
   'Représentativité à 7 critères dont l''audience aux élections',
   'true', '0'),

  ('9e3f6dbe-3f47-4a6c-8f0c-81ed26a22a82', 'f5000002-0000-0000-0000-0000000000f1',
   'Aucune distinction',
   'false', '1'),

  ('871215d5-ee2f-417d-8078-9dc92785c254', 'f5000002-0000-0000-0000-0000000000f1',
   'Uniquement les syndicats patronaux',
   'false', '2'),

  ('5440fba8-f854-414a-bb55-3a93f1d2d593', 'f5000002-0000-0000-0000-0000000000f1',
   'Une simple inscription suffit',
   'false', '3'),

  ('74acf9e5-e36b-4b26-a44d-67815d146a79', 'f5000002-0000-0000-0000-0000000000f2',
   'Travail non déclaré, délit puni de 3 ans de prison',
   'true', '0'),

  ('7444d0a4-b4e7-442e-a52e-47dc9af7f963', 'f5000002-0000-0000-0000-0000000000f2',
   'Travail bénévole légal',
   'false', '1'),

  ('a6089d24-ca82-49d6-befa-cff87a91158e', 'f5000002-0000-0000-0000-0000000000f2',
   'Travail de nuit autorisé',
   'false', '2'),

  ('1e3cd555-a5a2-4ae5-8bc9-6f3671d901c3', 'f5000002-0000-0000-0000-0000000000f2',
   'Service civique',
   'false', '3'),

  ('c233cfaf-6e12-4e4f-b52b-76f8c81932c4', 'f5000002-0000-0000-0000-0000000000f3',
   'Une épargne salariale avec abondement de l''employeur',
   'true', '0'),

  ('1a2517ca-696d-40fa-9be5-c4d8f11e5295', 'f5000002-0000-0000-0000-0000000000f3',
   'Une assurance auto',
   'false', '1'),

  ('4b47b700-fa7c-4188-908c-dfa335d2622b', 'f5000002-0000-0000-0000-0000000000f3',
   'Un syndicat',
   'false', '2'),

  ('d13a360e-a309-4821-a981-948972c43b6b', 'f5000002-0000-0000-0000-0000000000f3',
   'Une mutuelle',
   'false', '3'),

  ('28f061c0-0e15-4483-b5ad-8808814f6baf', 'f5000002-0000-0000-0000-0000000000f4',
   'Redistribution légale des bénéfices aux salariés (50+ salariés)',
   'true', '0'),

  ('00f95bad-a961-40cd-907d-3905521386fc', 'f5000002-0000-0000-0000-0000000000f4',
   'Une amende',
   'false', '1'),

  ('cde166c6-4de1-4621-8eab-f499d4edfc02', 'f5000002-0000-0000-0000-0000000000f4',
   'Un syndicat patronal',
   'false', '2'),

  ('a2ac8c40-5991-4f8b-8858-ae1bcce9c60f', 'f5000002-0000-0000-0000-0000000000f4',
   'Une assurance',
   'false', '3'),

  ('c0b91c30-5736-46e4-a49b-adea60feefb8', 'f5000002-0000-0000-0000-0000000000f5',
   'Désignation anticipée de qui gérera nos affaires en cas d''incapacité',
   'true', '0'),

  ('87a87ea0-c0db-477d-b39f-5e7e0d83c7a9', 'f5000002-0000-0000-0000-0000000000f5',
   'Un testament',
   'false', '1'),

  ('91b54a85-ab21-4778-b0a9-048555c1ca64', 'f5000002-0000-0000-0000-0000000000f5',
   'Un contrat de travail',
   'false', '2'),

  ('3a8d0447-3535-4cf5-8d1d-c2e7fd42540e', 'f5000002-0000-0000-0000-0000000000f5',
   'Un permis',
   'false', '3'),

  ('a0d24ea5-e0bc-4cd3-ad03-e9c163699754', 'f5000002-0000-0000-0000-0000000000f6',
   'Contrat civil entre 2 majeurs pour organiser la vie commune',
   'true', '0'),

  ('98d1f466-da74-4a2b-8b94-65f95ba942cd', 'f5000002-0000-0000-0000-0000000000f6',
   'Une assurance vie',
   'false', '1'),

  ('d1328199-e3e3-4b47-8363-82ab90c3e289', 'f5000002-0000-0000-0000-0000000000f6',
   'Un testament',
   'false', '2'),

  ('1c68dac9-d1c2-4fa4-b91d-e13348452acb', 'f5000002-0000-0000-0000-0000000000f6',
   'Un permis',
   'false', '3'),

  ('4655b5ec-0040-463e-b5ca-4b1d2482f186', 'f5000002-0000-0000-0000-0000000000f7',
   'Ensemble des dispositifs protégeant contre les risques de la vie',
   'true', '0'),

  ('a9100416-c290-4bb0-a5e3-789914f28141', 'f5000002-0000-0000-0000-0000000000f7',
   'Uniquement la police',
   'false', '1'),

  ('b59495e0-6ec1-491c-90f9-665308d1355a', 'f5000002-0000-0000-0000-0000000000f7',
   'Une assurance privée',
   'false', '2'),

  ('e67ae805-8832-428c-8ce4-eda00dcc9da4', 'f5000002-0000-0000-0000-0000000000f7',
   'Un syndicat unique',
   'false', '3'),

  ('491988b0-5201-4a38-86d5-e26103a2ca18', 'f5000002-0000-0000-0000-0000000000f8',
   'Modèle social où l''État assure protection et redistribution',
   'true', '0'),

  ('5f57cb76-2eb5-436c-bdc6-1459f50176da', 'f5000002-0000-0000-0000-0000000000f8',
   'Un parti politique',
   'false', '1'),

  ('daab9ec5-bbce-47e5-b5d2-643a29fbf444', 'f5000002-0000-0000-0000-0000000000f8',
   'Une religion',
   'false', '2'),

  ('f0083772-ffbb-42ad-9af4-30e3d8b797af', 'f5000002-0000-0000-0000-0000000000f8',
   'Un syndicat',
   'false', '3');
