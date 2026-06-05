-- ============================================================================
-- V245 — Civique : Droits et devoirs (lot 5)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000003 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f3000002-0000-0000-0000-0000000000a7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Le mariage pour tous (entre personnes de même sexe) est-il légal en France ?',
   'Oui. La loi du 17 mai 2013, dite ''Mariage pour tous'', autorise le mariage entre personnes de même sexe et leur ouvre l''adoption.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000a8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le pacte civil de solidarité (PACS) ?',
   'Le PACS, créé en 1999, est un contrat conclu entre deux personnes majeures (de même sexe ou non) pour organiser leur vie commune. C''est moins formel que le mariage mais a des effets juridiques.',
   'true', '2026-05-27 17:40:29.958969+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b1', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que le droit à un environnement équilibré selon la Charte de 2004 ?',
   'L''article 1er de la Charte de l''environnement reconnaît le droit pour chacun de vivre dans un environnement équilibré et respectueux de la santé. Adossée à la Constitution depuis 2005.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b2', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que la ''liberté syndicale'' en droit français ?',
   'La liberté syndicale (préambule de 1946) garantit le droit de créer ou d''adhérer à un syndicat pour défendre ses intérêts professionnels. Elle est protégée constitutionnellement.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b3', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le droit de grève est-il garanti constitutionnellement en France ?',
   'Oui. Le droit de grève est garanti par le préambule de la Constitution de 1946. Il s''exerce dans le cadre des lois qui le réglementent (préavis pour les fonctionnaires, etc.).',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b4', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que prévoit le droit à l''instruction selon la Constitution ?',
   'Le préambule de 1946 dispose que ''l''organisation de l''enseignement public gratuit et laïque à tous les degrés est un devoir de l''État''. L''instruction est gratuite jusqu''au lycée.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b5', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la notion de ''service public'' en droit administratif français ?',
   'Un service public est une activité d''intérêt général assurée par une personne publique (État, collectivités) ou sous son contrôle. Il est régi par les principes d''égalité, de continuité et d''adaptabilité.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b6', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Quels principes régissent le service public en France ?',
   'Les ''lois de Rolland'' énoncent trois principes : continuité (le service ne s''interrompt pas), égalité (même service pour tous les usagers) et mutabilité/adaptabilité (le service s''adapte aux besoins).',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b7', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Le droit à la santé est-il reconnu en France ?',
   'Oui. Le préambule de 1946 garantit à tous, notamment à l''enfant, à la mère, aux travailleurs âgés, la protection de la santé. C''est un droit constitutionnel.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-0000000000b8', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Qu''est-ce que le ''devoir de fraternité'' reconnu en France ?',
   'Le Conseil constitutionnel a reconnu en 2018 le principe de fraternité comme principe à valeur constitutionnelle, découlant de la devise républicaine. Il a notamment justifié l''aide humanitaire désintéressée.',
   'true', '2026-05-27 17:40:29.980861+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('f77aca76-95b9-49fb-8478-d69a3b446588', 'f3000002-0000-0000-0000-0000000000a7',
   'Oui, depuis la loi du 17 mai 2013',
   'true', '0'),

  ('508fef41-4d28-4942-b96a-d59a50f45027', 'f3000002-0000-0000-0000-0000000000a7',
   'Non, c''est interdit',
   'false', '1'),

  ('4c154fb3-c86a-4996-bb9a-fd75253101e4', 'f3000002-0000-0000-0000-0000000000a7',
   'Uniquement le PACS',
   'false', '2'),

  ('54ee7d5f-10f1-4d42-a486-d4d3ded04b15', 'f3000002-0000-0000-0000-0000000000a7',
   'Uniquement entre adultes consentants étrangers',
   'false', '3'),

  ('90eebfe8-340e-41e9-ab5e-1eb899b13ebd', 'f3000002-0000-0000-0000-0000000000a8',
   'Un contrat pour organiser la vie commune (entre 2 majeurs)',
   'true', '0'),

  ('a07bea4a-2dc0-4f2d-85a4-9e7639679c3e', 'f3000002-0000-0000-0000-0000000000a8',
   'Un permis de conduire',
   'false', '1'),

  ('1595eb42-0dfd-4da0-be22-1ef0a61594cb', 'f3000002-0000-0000-0000-0000000000a8',
   'Une assurance médicale',
   'false', '2'),

  ('c3652fd3-7eb5-4c08-884b-ccb5ddc214ca', 'f3000002-0000-0000-0000-0000000000a8',
   'Une carte de transport',
   'false', '3'),

  ('6a7098d0-c11c-4e0b-83c0-84dce847d560', 'f3000002-0000-0000-0000-0000000000b1',
   'Le droit à un environnement équilibré et respectueux de la santé',
   'true', '0'),

  ('a2ae3abf-4c33-482e-83d4-4b6d8b554d4c', 'f3000002-0000-0000-0000-0000000000b1',
   'Le droit à la pollution',
   'false', '1'),

  ('9cdff61e-cd96-4e3d-aa2d-47ed16f7fe34', 'f3000002-0000-0000-0000-0000000000b1',
   'Un droit européen non intégré',
   'false', '2'),

  ('534c0f41-49af-400b-8e7f-ea362fddc03a', 'f3000002-0000-0000-0000-0000000000b1',
   'Aucun droit spécifique',
   'false', '3'),

  ('267268ab-08b5-44ae-a971-9b618c50ea76', 'f3000002-0000-0000-0000-0000000000b2',
   'Le droit de créer et d''adhérer à un syndicat',
   'true', '0'),

  ('e2e30a91-d874-4f18-a5d1-24b39a5bacff', 'f3000002-0000-0000-0000-0000000000b2',
   'L''obligation d''être syndiqué',
   'false', '1'),

  ('9090640d-4be4-4ba0-8ad9-ef1ea0d5d317', 'f3000002-0000-0000-0000-0000000000b2',
   'Un droit interdit',
   'false', '2'),

  ('6041edec-1b90-4a77-8ba8-e347aa971a9f', 'f3000002-0000-0000-0000-0000000000b2',
   'Un droit réservé aux fonctionnaires',
   'false', '3'),

  ('008e3e6c-d0be-4754-a408-44271f09ca55', 'f3000002-0000-0000-0000-0000000000b3',
   'Oui, par le préambule de 1946',
   'true', '0'),

  ('e6c1333f-bb84-4b9b-9f63-33de645d9abf', 'f3000002-0000-0000-0000-0000000000b3',
   'Non, c''est interdit',
   'false', '1'),

  ('362c009f-b861-4458-8b13-c3637a90160b', 'f3000002-0000-0000-0000-0000000000b3',
   'Uniquement pour le privé',
   'false', '2'),

  ('5dfc61d5-43d2-4415-b1f9-411e071ec43d', 'f3000002-0000-0000-0000-0000000000b3',
   'Uniquement pour le public',
   'false', '3'),

  ('1617c56a-68b4-48fa-af6e-58929e64fc19', 'f3000002-0000-0000-0000-0000000000b4',
   'L''enseignement public gratuit et laïque à tous les degrés',
   'true', '0'),

  ('4138ac3e-1b0b-4fe1-b47a-77b179ace064', 'f3000002-0000-0000-0000-0000000000b4',
   'L''enseignement uniquement religieux',
   'false', '1'),

  ('bdfd4fc1-9db0-474f-b74c-612e4fffbf4f', 'f3000002-0000-0000-0000-0000000000b4',
   'L''enseignement payant pour tous',
   'false', '2'),

  ('d058d74f-3359-42b1-80d0-941b8a3d36d1', 'f3000002-0000-0000-0000-0000000000b4',
   'Aucun droit à l''instruction',
   'false', '3'),

  ('19882669-6e73-44f3-83b1-44443d3884a2', 'f3000002-0000-0000-0000-0000000000b5',
   'Une activité d''intérêt général assurée par une personne publique',
   'true', '0'),

  ('2f84f156-0bde-43e4-a1c8-d73a25257e2a', 'f3000002-0000-0000-0000-0000000000b5',
   'Une entreprise privée',
   'false', '1'),

  ('7bd41cae-7d8f-4a14-821d-a1da42ebd80a', 'f3000002-0000-0000-0000-0000000000b5',
   'Une association religieuse',
   'false', '2'),

  ('b779ff1e-ea77-4510-b6c9-358cee71df1c', 'f3000002-0000-0000-0000-0000000000b5',
   'Un loisir',
   'false', '3'),

  ('09087cab-b6bf-4c21-86a8-c3e55d988cf6', 'f3000002-0000-0000-0000-0000000000b6',
   'Continuité, égalité, mutabilité',
   'true', '0'),

  ('0198934a-310d-4137-abda-7065a56afcbd', 'f3000002-0000-0000-0000-0000000000b6',
   'Gratuité, secret, rapidité',
   'false', '1'),

  ('e9899197-8861-40f7-ae4d-27845bc44feb', 'f3000002-0000-0000-0000-0000000000b6',
   'Religion, tradition, hiérarchie',
   'false', '2'),

  ('b5921f1e-9b5b-4695-9954-b611c1d30e83', 'f3000002-0000-0000-0000-0000000000b6',
   'Aucun principe particulier',
   'false', '3'),

  ('632203c4-cd01-4d8a-8d72-26597362a4f9', 'f3000002-0000-0000-0000-0000000000b7',
   'Oui, garanti par le préambule de 1946',
   'true', '0'),

  ('ba0b9cad-4be4-4dc5-8cc7-9f72beeb55dc', 'f3000002-0000-0000-0000-0000000000b7',
   'Non, c''est privatisé',
   'false', '1'),

  ('defa1a5f-93bc-43ea-8426-f16b757dd113', 'f3000002-0000-0000-0000-0000000000b7',
   'Uniquement les retraités',
   'false', '2'),

  ('51f30b72-e195-4016-bf7e-83a3019e4ea5', 'f3000002-0000-0000-0000-0000000000b7',
   'Uniquement les Français nés en France',
   'false', '3'),

  ('87e7ebd6-33c9-4bd0-9d69-cbc495381d76', 'f3000002-0000-0000-0000-0000000000b8',
   'Un principe constitutionnel découlant de la devise républicaine (2018)',
   'true', '0'),

  ('a20de9bf-9d81-432f-bd26-9cbe5aec4fb3', 'f3000002-0000-0000-0000-0000000000b8',
   'Une obligation religieuse',
   'false', '1'),

  ('dd67fcd2-ae7f-4817-8b5b-5e47099be12b', 'f3000002-0000-0000-0000-0000000000b8',
   'Une simple coutume',
   'false', '2'),

  ('79231cdb-9e5e-4de9-b819-660d262678e7', 'f3000002-0000-0000-0000-0000000000b8',
   'Aucune valeur juridique',
   'false', '3');
