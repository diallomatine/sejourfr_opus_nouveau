-- ============================================================================
-- V667 — TCF SL B2 — lot 07 (point : registres de langue)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur le choix du mot adapté au registre (soutenu / courant /
-- familier) selon la situation de communication. Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c007-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (lettre de motivation) : « Madame la Directrice, je me permets de ___ un entretien afin de vous exposer mon parcours. »',
   'Le **registre soutenu** d''une lettre de motivation impose « solliciter », verbe consacré de la correspondance formelle pour demander poliment quelque chose à un supérieur. « Réclamer » suppose qu''on exige un dû et sonne revendicatif, inadapté face à un recruteur. « Exiger » est encore plus autoritaire : on n''exige rien de la personne qu''on veut convaincre de nous embaucher. « Quémander » est péjoratif (demander avec une insistance humiliante) et se disqualifie dans une lettre où l''on se met en valeur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (message entre amies) : « La soirée chez Nadia était vraiment ___, on a ri jusqu''à deux heures du matin ! »',
   'Le **registre familier** d''un message entre amies appelle « sympa », adjectif typique de l''oral spontané et des textos. « Plaisante » relève du registre courant-soutenu de l''écrit et paraît guindé dans ce contexte. « Délectable » appartient au registre soutenu et qualifie surtout un plaisir raffiné (un mets, une lecture), pas une fête. « Exquise » est également soutenu et précieux : grammaticalement correct, mais en complet décalage de registre avec « on a ri » et le ton du texto.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (courrier à la mairie de Besançon) : « Je vous saurais gré de bien vouloir ___ mon dossier de demande de logement dans les meilleurs délais. »',
   'Dans un courrier administratif, le **registre soutenu** (déjà signalé par « je vous saurais gré ») exige « examiner », verbe officiel pour l''étude d''un dossier par un service. « Regarder » est du registre courant, trop vague pour une procédure : on regarde un paysage, on examine un dossier. « Zieuter » est franchement familier (jeter un coup d''œil) et impensable face à une administration. « Éplucher » est familier-imagé (passer au crible avec suspicion) : la connotation est déplacée quand on demande un service.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (mémoire universitaire de Mei) : « Les loyers ont ___ augmenté dans les grandes métropoles entre 2015 et 2025. »',
   'Un écrit académique relève du **registre soutenu** : seul « considérablement » convient pour quantifier une forte hausse dans un mémoire. « Vachement » est un intensif typiquement familier, exclu de tout écrit universitaire. « Drôlement » appartient aussi au registre familier de l''oral (« il fait drôlement froid ») et détonnerait dans une analyse chiffrée. « Carrément » est familier et marque en plus une affirmation tranchée de l''oral spontané, pas une mesure objective : le décalage de registre disqualifie ces trois adverbes pourtant grammaticalement corrects.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (texto de Tarek à un copain) : « Trois heures à porter des cartons pour le déménagement, je suis complètement ___ ! »',
   'Dans un texto entre copains, le **registre familier** appelle « crevé », l''adjectif courant de l''oral pour dire « très fatigué ». « Fourbu » relève du registre littéraire (à l''origine pour un cheval épuisé) et surprendrait dans un SMS. « Harassé » appartient au registre soutenu de l''écrit : grammaticalement juste, mais en rupture de ton avec « copain » et « cartons ». « Las » est littéraire et exprime en outre une lassitude morale plus qu''un épuisement physique : double décalage, de registre et de nuance.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (courriel de l''entreprise de Sofia à un client) : « Nous vous prions de bien vouloir nous ___ pour ce retard de livraison indépendant de notre volonté. »',
   'La **formule consacrée du registre commercial formel** est « nous prions de bien vouloir nous excuser » : « excuser » est le verbe attendu dans la correspondance professionnelle. « Pardonner » relève de la sphère personnelle ou morale (on pardonne une offense, pas un retard de colis) et sonne exagérément solennel. « Absoudre » appartient au vocabulaire religieux ou juridique (absoudre un péché, un accusé) : registre totalement déplacé. « Disculper » signifie prouver l''innocence de quelqu''un — contresens en plus du décalage, car l''entreprise reconnaît le retard.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres'),

  ('33333333-c007-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez (discussion entre copains au lycée) : « Tu as vu la ___ que le frère de Yanis vient de s''acheter ? Un vrai bolide ! »',
   'Entre lycéens, le **registre familier** (confirmé par « bolide » et « copains ») appelle « bagnole », terme familier par excellence pour une voiture. « Automobile » relève du registre soutenu, voire vieilli ou administratif : personne ne dit « l''automobile de ton frère » dans une cour de lycée. « Véhicule » est le terme administratif et technique (constat, code de la route), neutre mais froid, en décalage avec l''enthousiasme du propos. « Berline » est un terme technico-commercial qui désigne une carrosserie précise : registre des concessionnaires, pas de la conversation entre copains.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_registres');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c007-2100-0000-000000000001', '33333333-c007-1000-0000-000000000001', 'réclamer', 'false', '1'),
  ('33333333-c007-2200-0000-000000000001', '33333333-c007-1000-0000-000000000001', 'solliciter', 'true', '2'),
  ('33333333-c007-2300-0000-000000000001', '33333333-c007-1000-0000-000000000001', 'exiger', 'false', '3'),
  ('33333333-c007-2400-0000-000000000001', '33333333-c007-1000-0000-000000000001', 'quémander', 'false', '4'),

  ('33333333-c007-2100-0000-000000000002', '33333333-c007-1000-0000-000000000002', 'plaisante', 'false', '1'),
  ('33333333-c007-2200-0000-000000000002', '33333333-c007-1000-0000-000000000002', 'délectable', 'false', '2'),
  ('33333333-c007-2300-0000-000000000002', '33333333-c007-1000-0000-000000000002', 'exquise', 'false', '3'),
  ('33333333-c007-2400-0000-000000000002', '33333333-c007-1000-0000-000000000002', 'sympa', 'true', '4'),

  ('33333333-c007-2100-0000-000000000003', '33333333-c007-1000-0000-000000000003', 'examiner', 'true', '1'),
  ('33333333-c007-2200-0000-000000000003', '33333333-c007-1000-0000-000000000003', 'regarder', 'false', '2'),
  ('33333333-c007-2300-0000-000000000003', '33333333-c007-1000-0000-000000000003', 'zieuter', 'false', '3'),
  ('33333333-c007-2400-0000-000000000003', '33333333-c007-1000-0000-000000000003', 'éplucher', 'false', '4'),

  ('33333333-c007-2100-0000-000000000004', '33333333-c007-1000-0000-000000000004', 'vachement', 'false', '1'),
  ('33333333-c007-2200-0000-000000000004', '33333333-c007-1000-0000-000000000004', 'drôlement', 'false', '2'),
  ('33333333-c007-2300-0000-000000000004', '33333333-c007-1000-0000-000000000004', 'considérablement', 'true', '3'),
  ('33333333-c007-2400-0000-000000000004', '33333333-c007-1000-0000-000000000004', 'carrément', 'false', '4'),

  ('33333333-c007-2100-0000-000000000005', '33333333-c007-1000-0000-000000000005', 'fourbu', 'false', '1'),
  ('33333333-c007-2200-0000-000000000005', '33333333-c007-1000-0000-000000000005', 'crevé', 'true', '2'),
  ('33333333-c007-2300-0000-000000000005', '33333333-c007-1000-0000-000000000005', 'harassé', 'false', '3'),
  ('33333333-c007-2400-0000-000000000005', '33333333-c007-1000-0000-000000000005', 'las', 'false', '4'),

  ('33333333-c007-2100-0000-000000000006', '33333333-c007-1000-0000-000000000006', 'pardonner', 'false', '1'),
  ('33333333-c007-2200-0000-000000000006', '33333333-c007-1000-0000-000000000006', 'absoudre', 'false', '2'),
  ('33333333-c007-2300-0000-000000000006', '33333333-c007-1000-0000-000000000006', 'disculper', 'false', '3'),
  ('33333333-c007-2400-0000-000000000006', '33333333-c007-1000-0000-000000000006', 'excuser', 'true', '4'),

  ('33333333-c007-2100-0000-000000000007', '33333333-c007-1000-0000-000000000007', 'bagnole', 'true', '1'),
  ('33333333-c007-2200-0000-000000000007', '33333333-c007-1000-0000-000000000007', 'automobile', 'false', '2'),
  ('33333333-c007-2300-0000-000000000007', '33333333-c007-1000-0000-000000000007', 'véhicule', 'false', '3'),
  ('33333333-c007-2400-0000-000000000007', '33333333-c007-1000-0000-000000000007', 'berline', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c007-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 verbes de demande, 4 adjectifs appréciatifs, 4 verbes d''étude,
--     4 adverbes d''intensité, 4 adjectifs de fatigue, 4 verbes du pardon,
--     4 noms de voiture) — toutes grammaticalement existantes et plausibles.
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:1, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : registres de langue (soutenu / courant / familier selon la
--     situation de communication) — aucun point de la liste interdite (pas de
--     relatifs composés, concordance, subjonctif, passif, paronymes, etc.).
-- [x] explanation ≥ 80 caractères, nomme le mécanisme (**registre soutenu /
--     familier / formule consacrée**) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (lettre de motivation, texto entre amies,
--     courrier mairie de Besançon, mémoire universitaire, texto déménagement,
--     courriel commercial, discussion de lycéens) ; prénoms variés (Nadia,
--     Mei, Tarek, Sofia, Yanis).
-- [x] Contenu 100 % original ; pas de SVG ni SSML (items texte purs).
-- [x] Apostrophes SQL doublées ; created_at ''2026-06-07 12:00:00+02''.
-- ============================================================================
