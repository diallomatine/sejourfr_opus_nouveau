-- ============================================================================
-- V666 — TCF SL B2 — lot 06 (point : double pronominalisation)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la double pronominalisation (ordre COD/COI 3e personne,
-- impératif affirmatif et négatif, me/te/nous/vous + le/la/les, lui/leur + en,
-- COD + y). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c006-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Karim réclame sa caution depuis deux mois : l''agence immobilière ___ remboursera à la fin du bail. »',
   'Avec deux pronoms de **3e personne, l''ordre est COD (le/la/les) avant COI (lui/leur)** : « la » reprend « sa caution » (féminin singulier) et « lui » reprend « à Karim » → « la lui remboursera ». « lui la » inverse cet ordre obligatoire. « le lui » se trompe de genre : « caution » est féminin. « la leur » se trompe de nombre du destinataire : Karim est une seule personne, « leur » renverrait à plusieurs bénéficiaires.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Tes collègues de Strasbourg attendent le compte rendu : envoie-___ sans tarder ! »',
   'À l''**impératif affirmatif, les pronoms se placent après le verbe, reliés par des traits d''union, dans l''ordre COD puis COI** : « le » = le compte rendu, « leur » = tes collègues → « envoie-le-leur ». « leur-le » inverse l''ordre propre à l''impératif affirmatif. « le-lui » désigne un destinataire singulier alors que « tes collègues » est pluriel. « la-leur » se trompe de genre : « compte rendu » est masculin.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Des plans de la vieille ville ? Bien sûr, je ___ mettrai plusieurs de côté à l''accueil. »',
   'Le quantifieur « plusieurs » impose le pronom **« en » (quantité indéterminée : des plans)**, et dans la combinaison les pronoms **me/te/nous/vous précèdent « en »** → « je vous en mettrai plusieurs ». « en vous » inverse cet ordre, séquence impossible en français. « vous les » reprendrait un COD défini (ces plans précis), incompatible avec « plusieurs », qui exige « en ». « vous y » : « y » remplace un lieu ou un complément en « à », pas un COD quantifié.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ta recette de tajine aux abricots est délicieuse : tu ___ donnes par message ? »',
   'Quand le COI est un pronom de **1re ou 2e personne (me, te, nous, vous), il se place AVANT le pronom COD le/la/les** : « me » (à moi) puis « la » (ta recette, féminin singulier) → « tu me la donnes ». « la me » inverse cet ordre, séquence inexistante. « me le » se trompe de genre : « recette » est féminin. « me les » se trompe de nombre : il n''y a qu''une seule recette à transmettre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Olena adore les fleurs des champs : son voisin Hugo ___ apporte souvent le dimanche. »',
   'Hugo apporte « des fleurs » (quantité indéfinie) → pronom **« en » ; dans la combinaison, le COI lui/leur précède toujours « en »** → « lui en apporte » (lui = à Olena). « en lui » inverse cet ordre obligatoire. « les lui » reprendrait des fleurs définies et identifiées (ces fleurs-là), alors qu''il s''agit d''apports indéfinis et répétés. « lui les » cumule deux fautes : ordre interdit (COD défini après COI) et COD défini inadapté au sens.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ses élèves adorent la médiathèque de Roubaix : l''instituteur ___ emmène chaque vendredi après-midi. »',
   'Le lieu « à la médiathèque » se pronominalise en **« y », et le pronom COD (les = ses élèves) se place AVANT « y »** → « les y emmène ». « y les » inverse cet ordre, séquence impossible. « les en » : « en » marquerait la provenance (« de là-bas »), contresens puisque l''instituteur les conduit VERS la médiathèque. « leur y » : « emmener » se construit avec un COD (emmener quelqu''un), pas avec un COI « leur ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom'),

  ('33333333-c006-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Tes étudiantes réclament leurs notes, encore provisoires : ne ___ annonce pas avant la délibération ! »',
   'À l''**impératif négatif, les pronoms reviennent AVANT le verbe, dans l''ordre de la phrase déclarative : COD (les = leurs notes) puis COI (leur = aux étudiantes)** → « ne les leur annonce pas ». « leur les » inverse cet ordre. « les lui » désigne une destinataire singulière alors que « tes étudiantes » est pluriel. « la leur » se trompe de nombre du COD : « leurs notes » est pluriel, « la » ne peut pas les reprendre.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_double_pronom');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c006-2100-0000-000000000001', '33333333-c006-1000-0000-000000000001', 'lui la', 'false', '1'),
  ('33333333-c006-2200-0000-000000000001', '33333333-c006-1000-0000-000000000001', 'la lui', 'true', '2'),
  ('33333333-c006-2300-0000-000000000001', '33333333-c006-1000-0000-000000000001', 'le lui', 'false', '3'),
  ('33333333-c006-2400-0000-000000000001', '33333333-c006-1000-0000-000000000001', 'la leur', 'false', '4'),

  ('33333333-c006-2100-0000-000000000002', '33333333-c006-1000-0000-000000000002', 'le-leur', 'true', '1'),
  ('33333333-c006-2200-0000-000000000002', '33333333-c006-1000-0000-000000000002', 'leur-le', 'false', '2'),
  ('33333333-c006-2300-0000-000000000002', '33333333-c006-1000-0000-000000000002', 'le-lui', 'false', '3'),
  ('33333333-c006-2400-0000-000000000002', '33333333-c006-1000-0000-000000000002', 'la-leur', 'false', '4'),

  ('33333333-c006-2100-0000-000000000003', '33333333-c006-1000-0000-000000000003', 'en vous', 'false', '1'),
  ('33333333-c006-2200-0000-000000000003', '33333333-c006-1000-0000-000000000003', 'vous les', 'false', '2'),
  ('33333333-c006-2300-0000-000000000003', '33333333-c006-1000-0000-000000000003', 'vous en', 'true', '3'),
  ('33333333-c006-2400-0000-000000000003', '33333333-c006-1000-0000-000000000003', 'vous y', 'false', '4'),

  ('33333333-c006-2100-0000-000000000004', '33333333-c006-1000-0000-000000000004', 'me la', 'true', '1'),
  ('33333333-c006-2200-0000-000000000004', '33333333-c006-1000-0000-000000000004', 'la me', 'false', '2'),
  ('33333333-c006-2300-0000-000000000004', '33333333-c006-1000-0000-000000000004', 'me le', 'false', '3'),
  ('33333333-c006-2400-0000-000000000004', '33333333-c006-1000-0000-000000000004', 'me les', 'false', '4'),

  ('33333333-c006-2100-0000-000000000005', '33333333-c006-1000-0000-000000000005', 'en lui', 'false', '1'),
  ('33333333-c006-2200-0000-000000000005', '33333333-c006-1000-0000-000000000005', 'les lui', 'false', '2'),
  ('33333333-c006-2300-0000-000000000005', '33333333-c006-1000-0000-000000000005', 'lui les', 'false', '3'),
  ('33333333-c006-2400-0000-000000000005', '33333333-c006-1000-0000-000000000005', 'lui en', 'true', '4'),

  ('33333333-c006-2100-0000-000000000006', '33333333-c006-1000-0000-000000000006', 'y les', 'false', '1'),
  ('33333333-c006-2200-0000-000000000006', '33333333-c006-1000-0000-000000000006', 'les y', 'true', '2'),
  ('33333333-c006-2300-0000-000000000006', '33333333-c006-1000-0000-000000000006', 'les en', 'false', '3'),
  ('33333333-c006-2400-0000-000000000006', '33333333-c006-1000-0000-000000000006', 'leur y', 'false', '4'),

  ('33333333-c006-2100-0000-000000000007', '33333333-c006-1000-0000-000000000007', 'leur les', 'false', '1'),
  ('33333333-c006-2200-0000-000000000007', '33333333-c006-1000-0000-000000000007', 'les lui', 'false', '2'),
  ('33333333-c006-2300-0000-000000000007', '33333333-c006-1000-0000-000000000007', 'les leur', 'true', '3'),
  ('33333333-c006-2400-0000-000000000007', '33333333-c006-1000-0000-000000000007', 'la leur', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c006-1000-…-01..07 / choices
--     2100-2400 par position).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 combinaisons de deux pronoms compléments à chaque fois).
-- [x] Distribution des bonnes réponses : pos1:2 (items 2, 4), pos2:2 (1, 6),
--     pos3:2 (3, 7), pos4:1 (5) — 4 positions utilisées, aucune ne dépasse 2.
-- [x] Point unique : double pronominalisation (COD avant COI à la 3e personne,
--     impératif affirmatif « envoie-le-leur », me/te/nous/vous + le/la/les,
--     « plusieurs » → vous en, lui + en, les + y, impératif négatif) — aucun
--     point de la liste interdite (pas de relatifs composés, concordance,
--     discours rapporté, etc.).
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (ordre des pronoms,
--     impératif affirmatif/négatif, « plusieurs » exige « en »…) et chacun des
--     3 distracteurs démonté (ordre, genre, nombre, rection).
-- [x] Contextes tous différents (caution de logement, compte rendu
--     professionnel, plans à l''office de tourisme, recette de cuisine, fleurs
--     entre voisins, sortie scolaire à la médiathèque, notes d''examen) ;
--     prénoms/villes variés (Karim, Hugo, Olena, Strasbourg, Roubaix).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
