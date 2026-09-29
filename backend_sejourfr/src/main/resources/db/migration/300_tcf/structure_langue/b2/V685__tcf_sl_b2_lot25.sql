-- ============================================================================
-- V685 — TCF SL B2 — lot 25 (point : futur antérieur (antériorité dans le futur))
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 6 items, tous sur le futur antérieur exprimant l'antériorité dans le futur
-- (une fois que / quand / d'ici / après que / dès que / depuis + repère futur).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c019-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Une fois que les déménageurs ___ le camion, Khadija leur offrira un café. »',
   'La conjonction « une fois que » indique que le déchargement sera **entièrement achevé avant** l''action principale au futur (« offrira ») : c''est l''**antériorité dans le futur**, exprimée par le **futur antérieur** « auront déchargé ». « Déchargeront » (futur simple) placerait les deux actions sur le même plan, sans marquer l''achèvement préalable qu''exige « une fois que ». « Ont déchargé » (passé composé) situerait l''action dans le passé par rapport au moment où l''on parle, incompatible avec une principale au futur. « Auraient déchargé » (conditionnel passé) exprimerait un irréel du passé ou une information non confirmée, pas une antériorité future.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur'),

  ('33333333-c019-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Quand tu reviendras de ta mission de six mois à Dakar, ta fille ___ à marcher. »',
   'Le repère est futur (« quand tu reviendras ») et l''apprentissage de la marche sera **accompli avant** ce retour : on emploie le **futur antérieur** « aura appris », qui marque l''**antériorité dans le futur**. « Apprendra » (futur simple) signifierait que l''enfant commencera seulement à apprendre après le retour — contresens ici. « A appris » (passé composé) renverrait à un fait déjà accompli au moment où l''on parle, alors que la mission n''a pas encore eu lieu. « Aurait appris » (conditionnel passé) marquerait une hypothèse irréelle ou une information rapportée, pas un accompli du futur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur'),

  ('33333333-c019-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « D''ici dimanche soir, Tomás ___ les trois cents pages de son mémoire. »',
   '« D''ici dimanche soir » fixe une **échéance future** à laquelle l''action sera **terminée** : c''est l''**accompli du futur**, rendu par le **futur antérieur** « aura relu ». « Relira » (futur simple) annoncerait simplement une action à venir sans garantir son achèvement à l''échéance, alors que « d''ici » appelle précisément ce bilan d''achèvement. « A relu » (passé composé) présenterait la relecture comme déjà faite au moment présent, ce que contredit l''échéance future. « Aurait relu » (conditionnel passé) exprimerait un reproche ou un irréel (« il aurait relu si… »), pas une antériorité dans le futur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur'),

  ('33333333-c019-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Après que la mairie de Besançon ___ les travaux, la rue des Tilleuls rouvrira à la circulation. »',
   '« Après que » se construit avec l''**indicatif**, et l''achèvement des travaux précède la réouverture au futur (« rouvrira ») : cette **antériorité dans le futur** se marque par le **futur antérieur** « aura achevé ». « Achèvera » (futur simple) n''exprimerait pas l''antériorité pourtant imposée par « après que » : les deux actions sembleraient simultanées. « A achevé » (passé composé) ancrerait les travaux dans le passé du locuteur, incompatible avec une réouverture encore à venir. « Aurait achevé » (conditionnel passé) relèverait de l''hypothèse non réalisée ou de l''information non vérifiée, pas d''un fait programmé dans le futur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur'),

  ('33333333-c019-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Ngozi, préviens-nous dès que ton avion ___ à Marseille. »',
   'On préviendra **après** que l''atterrissage sera **complètement accompli** : avec « dès que » et une principale à valeur de futur (l''impératif « préviens-nous »), l''action antérieure se met au **futur antérieur** « aura atterri » (**antériorité dans le futur**). « Atterrira » (futur simple) présenterait l''atterrissage comme simultané à l''appel, alors qu''on téléphone une fois l''avion posé. « A atterri » (passé composé) signifierait que l''avion est déjà au sol au moment où l''on parle, ce qui annulerait la consigne. « Aurait atterri » (conditionnel passé) exprimerait un fait hypothétique ou non confirmé, pas un accompli futur attendu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur'),

  ('33333333-c019-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « À ton retour du stage à Lyon, Hana et moi ___ dans le nouvel appartement depuis un mois. »',
   '« Depuis un mois » mesuré à partir d''un repère futur (« à ton retour ») impose un **accompli antérieur à ce repère** : le **futur antérieur** « aurons emménagé » exprime cette **antériorité dans le futur**. « Emménagerons » (futur simple) est incompatible avec « depuis un mois », qui suppose l''installation déjà réalisée au moment du retour. « Avons emménagé » (passé composé) daterait l''emménagement par rapport au présent du locuteur, alors que toute la phrase se situe dans le futur. « Aurions emménagé » (conditionnel passé) introduirait un irréel ou une éventualité non confirmée, sans rapport avec ce bilan d''accompli futur.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_futur_anterieur');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c019-2100-0000-000000000001', '33333333-c019-1000-0000-000000000001', 'déchargeront', 'false', '1'),
  ('33333333-c019-2200-0000-000000000001', '33333333-c019-1000-0000-000000000001', 'auront déchargé', 'true', '2'),
  ('33333333-c019-2300-0000-000000000001', '33333333-c019-1000-0000-000000000001', 'ont déchargé', 'false', '3'),
  ('33333333-c019-2400-0000-000000000001', '33333333-c019-1000-0000-000000000001', 'auraient déchargé', 'false', '4'),

  ('33333333-c019-2100-0000-000000000002', '33333333-c019-1000-0000-000000000002', 'apprendra', 'false', '1'),
  ('33333333-c019-2200-0000-000000000002', '33333333-c019-1000-0000-000000000002', 'a appris', 'false', '2'),
  ('33333333-c019-2300-0000-000000000002', '33333333-c019-1000-0000-000000000002', 'aurait appris', 'false', '3'),
  ('33333333-c019-2400-0000-000000000002', '33333333-c019-1000-0000-000000000002', 'aura appris', 'true', '4'),

  ('33333333-c019-2100-0000-000000000003', '33333333-c019-1000-0000-000000000003', 'aura relu', 'true', '1'),
  ('33333333-c019-2200-0000-000000000003', '33333333-c019-1000-0000-000000000003', 'relira', 'false', '2'),
  ('33333333-c019-2300-0000-000000000003', '33333333-c019-1000-0000-000000000003', 'a relu', 'false', '3'),
  ('33333333-c019-2400-0000-000000000003', '33333333-c019-1000-0000-000000000003', 'aurait relu', 'false', '4'),

  ('33333333-c019-2100-0000-000000000004', '33333333-c019-1000-0000-000000000004', 'achèvera', 'false', '1'),
  ('33333333-c019-2200-0000-000000000004', '33333333-c019-1000-0000-000000000004', 'a achevé', 'false', '2'),
  ('33333333-c019-2300-0000-000000000004', '33333333-c019-1000-0000-000000000004', 'aura achevé', 'true', '3'),
  ('33333333-c019-2400-0000-000000000004', '33333333-c019-1000-0000-000000000004', 'aurait achevé', 'false', '4'),

  ('33333333-c019-2100-0000-000000000005', '33333333-c019-1000-0000-000000000005', 'aura atterri', 'true', '1'),
  ('33333333-c019-2200-0000-000000000005', '33333333-c019-1000-0000-000000000005', 'atterrira', 'false', '2'),
  ('33333333-c019-2300-0000-000000000005', '33333333-c019-1000-0000-000000000005', 'a atterri', 'false', '3'),
  ('33333333-c019-2400-0000-000000000005', '33333333-c019-1000-0000-000000000005', 'aurait atterri', 'false', '4'),

  ('33333333-c019-2100-0000-000000000006', '33333333-c019-1000-0000-000000000006', 'emménagerons', 'false', '1'),
  ('33333333-c019-2200-0000-000000000006', '33333333-c019-1000-0000-000000000006', 'avons emménagé', 'false', '2'),
  ('33333333-c019-2300-0000-000000000006', '33333333-c019-1000-0000-000000000006', 'aurons emménagé', 'true', '3'),
  ('33333333-c019-2400-0000-000000000006', '33333333-c019-1000-0000-000000000006', 'aurions emménagé', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes (33333333-c019-1000-…-01..06 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 formes conjuguées du même verbe : futur antérieur, futur simple,
--     passé composé, conditionnel passé — toutes grammaticalement existantes).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:1, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : futur antérieur (antériorité dans le futur) — déclencheurs
--     variés : une fois que, quand + repère futur, d''ici + échéance, après que,
--     dès que + impératif, depuis + repère futur. Aucun point de la liste interdite
--     (le conditionnel passé n''apparaît que comme distracteur, jamais comme point testé).
-- [x] explanation ≥ 80 caractères, règle nommée en **gras** (antériorité dans le
--     futur / accompli du futur) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (déménagement, mission à Dakar, relecture de
--     mémoire, travaux municipaux à Besançon, atterrissage à Marseille,
--     emménagement avant retour de stage à Lyon) ; prénoms variés (Khadija,
--     Tomás, Ngozi, Hana).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
