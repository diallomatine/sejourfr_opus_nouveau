-- ============================================================================
-- V669 — TCF SL B2 — lot 09 (point : verbes de transport (apporter/emporter/emmener/ramener…))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur les verbes de transport de la famille porter/mener
-- (apporter, emporter, rapporter, remporter / amener, emmener, ramener).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c009-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour son trajet en car jusqu''à Clermont-Ferrand, Fatou prépare des sandwichs qu''elle compte ___ dans son sac à dos. »',
   'La famille porter/mener distingue les **objets** (porter) des **personnes** (mener), et le préfixe indique le sens du déplacement. **« Emporter »** = prendre un objet avec soi **en quittant un lieu**, sans destinataire précis : Fatou part avec ses sandwichs. « Apporter » signifierait porter les sandwichs **vers** un lieu ou un destinataire identifié (apporter un gâteau à un ami). « Emmener » se réserve aux **personnes ou animaux** qu''on conduit avec soi, jamais à des sandwichs. « Ramener » supposerait un **retour** vers le point de départ, absent ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Invité à dîner chez Tarek vendredi soir, Diego a promis d''___ une tarte aux figues faite maison. »',
   'Pour un **objet** porté **vers le lieu où l''on va et vers un destinataire** (chez Tarek), la règle des préfixes impose **« apporter »** (a- = mouvement vers). « Emporter » insiste au contraire sur le lieu qu''on **quitte**, sans destinataire (emporter un livre en vacances). « Emmener » appartient à la famille « mener », réservée aux **personnes** : on n''emmène pas une tarte. « Rapporter » impliquerait un **retour** ou une restitution à un lieu d''origine (rapporter un article défectueux au magasin), ce qui n''a pas de sens ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Jeudi matin, Rachid doit ___ son fils chez l''orthophoniste avant d''aller travailler. »',
   'Le complément est une **personne** (son fils) que Rachid conduit avec lui vers un autre lieu : c''est la famille « mener » qui s''impose → **« emmener »** (em- = partir du lieu où l''on est en prenant quelqu''un avec soi). « Emporter » et « apporter » relèvent de la famille « porter », réservée aux **objets** qu''on transporte : on ne « porte » pas son fils chez l''orthophoniste au sens grammatical. « Rapporter » cumule deux erreurs : verbe d''objet ET idée de **retour à l''origine**, absente ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La soirée s''étant terminée très tard, Wei a proposé de ___ Olena chez elle en voiture. »',
   '**« Ramener »** combine **re- (idée de retour)** et **mener (complément = personne)** : reconduire quelqu''un à son domicile ou à son point de départ. C''est exactement la situation d''Olena raccompagnée chez elle. « Rapporter » et « remporter » expriment bien le retour mais appartiennent à la famille « porter », réservée aux **objets** — on ne « rapporte » pas une personne. « Emporter » est doublement fautif : verbe d''objet ET préfixe em- qui marque l''éloignement, pas le **retour**.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Sa bouilloire neuve fuit déjà : Lucia va la ___ au magasin pour obtenir un échange. »',
   '**« Rapporter »** = **re- (retour) + porter (objet)** : porter un objet à son lieu d''origine, ici restituer la bouilloire au magasin. « Ramener » exprime bien le retour mais relève de « mener », employé pour les **personnes** ou ce qui se déplace par soi-même (ramener un ami, ramener la voiture au garage) — une bouilloire se **porte**. « Emmener » est un verbe de personnes sans idée de retour. « Emporter » est un verbe d''objet correct, mais son préfixe em- marque le simple fait de **partir avec**, sans la notion de **restitution** qu''exige le contexte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Tu peux ___ ta cousine à mon mariage en août, la salle de Périgueux est très grande. »',
   '**« Amener »** = conduire une **personne vers le lieu où se trouve l''interlocuteur** (a- = mouvement vers) : la cousine est conduite au mariage de celle ou celui qui parle. « Apporter », « emporter » et « rapporter » appartiennent à la famille « porter », réservée aux **objets** : on apporte un cadeau au mariage, on n''« apporte » pas une cousine. « Emporter » ajoute en plus l''idée d''**éloignement** du lieu de départ, contraire au mouvement vers l''interlocuteur, et « rapporter » une idée de **retour à l''origine** sans objet ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport'),

  ('33333333-c009-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À la fin du vide-greniers de Bayonne, chaque exposant doit ___ ses cartons d''invendus. »',
   '**« Remporter »** = **re- + emporter** : **reprendre et emporter les objets qu''on avait soi-même apportés** — exactement le cas des cartons d''invendus que chaque exposant a installés le matin. « Emmener » et « amener » relèvent de la famille « mener », réservée aux **personnes** : des cartons se portent, ils ne se « mènent » pas. « Ramener » cumule la même erreur de famille (mener) avec un sens de **reconduite au point de départ** qui s''applique à quelqu''un, pas à des cartons qu''on transporte à bout de bras.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_lexique_transport');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c009-2100-0000-000000000001', '33333333-c009-1000-0000-000000000001', 'apporter', 'false', '1'),
  ('33333333-c009-2200-0000-000000000001', '33333333-c009-1000-0000-000000000001', 'emporter', 'true', '2'),
  ('33333333-c009-2300-0000-000000000001', '33333333-c009-1000-0000-000000000001', 'emmener', 'false', '3'),
  ('33333333-c009-2400-0000-000000000001', '33333333-c009-1000-0000-000000000001', 'ramener', 'false', '4'),

  ('33333333-c009-2100-0000-000000000002', '33333333-c009-1000-0000-000000000002', 'emporter', 'false', '1'),
  ('33333333-c009-2200-0000-000000000002', '33333333-c009-1000-0000-000000000002', 'emmener', 'false', '2'),
  ('33333333-c009-2300-0000-000000000002', '33333333-c009-1000-0000-000000000002', 'rapporter', 'false', '3'),
  ('33333333-c009-2400-0000-000000000002', '33333333-c009-1000-0000-000000000002', 'apporter', 'true', '4'),

  ('33333333-c009-2100-0000-000000000003', '33333333-c009-1000-0000-000000000003', 'emporter', 'false', '1'),
  ('33333333-c009-2200-0000-000000000003', '33333333-c009-1000-0000-000000000003', 'apporter', 'false', '2'),
  ('33333333-c009-2300-0000-000000000003', '33333333-c009-1000-0000-000000000003', 'emmener', 'true', '3'),
  ('33333333-c009-2400-0000-000000000003', '33333333-c009-1000-0000-000000000003', 'rapporter', 'false', '4'),

  ('33333333-c009-2100-0000-000000000004', '33333333-c009-1000-0000-000000000004', 'ramener', 'true', '1'),
  ('33333333-c009-2200-0000-000000000004', '33333333-c009-1000-0000-000000000004', 'rapporter', 'false', '2'),
  ('33333333-c009-2300-0000-000000000004', '33333333-c009-1000-0000-000000000004', 'emporter', 'false', '3'),
  ('33333333-c009-2400-0000-000000000004', '33333333-c009-1000-0000-000000000004', 'remporter', 'false', '4'),

  ('33333333-c009-2100-0000-000000000005', '33333333-c009-1000-0000-000000000005', 'ramener', 'false', '1'),
  ('33333333-c009-2200-0000-000000000005', '33333333-c009-1000-0000-000000000005', 'rapporter', 'true', '2'),
  ('33333333-c009-2300-0000-000000000005', '33333333-c009-1000-0000-000000000005', 'emmener', 'false', '3'),
  ('33333333-c009-2400-0000-000000000005', '33333333-c009-1000-0000-000000000005', 'emporter', 'false', '4'),

  ('33333333-c009-2100-0000-000000000006', '33333333-c009-1000-0000-000000000006', 'apporter', 'false', '1'),
  ('33333333-c009-2200-0000-000000000006', '33333333-c009-1000-0000-000000000006', 'emporter', 'false', '2'),
  ('33333333-c009-2300-0000-000000000006', '33333333-c009-1000-0000-000000000006', 'amener', 'true', '3'),
  ('33333333-c009-2400-0000-000000000006', '33333333-c009-1000-0000-000000000006', 'rapporter', 'false', '4'),

  ('33333333-c009-2100-0000-000000000007', '33333333-c009-1000-0000-000000000007', 'emmener', 'false', '1'),
  ('33333333-c009-2200-0000-000000000007', '33333333-c009-1000-0000-000000000007', 'amener', 'false', '2'),
  ('33333333-c009-2300-0000-000000000007', '33333333-c009-1000-0000-000000000007', 'ramener', 'false', '3'),
  ('33333333-c009-2400-0000-000000000007', '33333333-c009-1000-0000-000000000007', 'remporter', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c009-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 verbes de transport de la famille porter/mener, tous existants).
-- [x] Distribution des bonnes réponses : pos1:1, pos2:2, pos3:2, pos4:2
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : verbes de transport (emporter, apporter, emmener, ramener,
--     rapporter, amener, remporter) — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, nomme la règle objets (porter) vs personnes
--     (mener) + valeur des préfixes a-/em-/re- (**gras**) et démonte chacun des
--     3 distracteurs.
-- [x] Contextes tous différents (trajet en car, dîner chez un ami, rendez-vous
--     orthophoniste, raccompagnement après soirée, échange en magasin, mariage,
--     vide-greniers) ; prénoms et villes variés (Fatou, Tarek, Diego, Rachid,
--     Wei, Olena, Lucia ; Clermont-Ferrand, Périgueux, Bayonne).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
