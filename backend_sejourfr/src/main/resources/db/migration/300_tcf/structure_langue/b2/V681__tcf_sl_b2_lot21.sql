-- ============================================================================
-- V681 — TCF SL B2 — lot 21 (point : place de l'adverbe)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la place de l'adverbe (adverbes courts aux temps composés,
-- locution « pas encore », adverbes de temps datés, adverbe + infinitif,
-- verbe pronominal, négation « ne … jamais »). Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c015-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Depuis son inscription au cours du soir de Rennes, Yuki ___. »',
   'Aux temps composés, les **adverbes courts de quantité (beaucoup, trop, assez)** se placent entre l''auxiliaire et le participe passé : « a beaucoup progressé ». « A progressé beaucoup à l''oral » détache l''adverbe du noyau verbal, tour perçu comme un calque de l''anglais. « Beaucoup a progressé à l''oral » insère l''adverbe entre le sujet et l''auxiliaire, position impossible en français standard. « A progressé à l''oral beaucoup » rejette l''adverbe en fin de phrase, registre oral relâché, fautif à l''écrit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Il n''est que 9 h 30, mais Sofian ___. »',
   'La **règle des adverbes courts aux temps composés** : « déjà » se place entre l''auxiliaire et le participe passé → « a déjà terminé ». « A terminé déjà sa tournée de livraisons » brise le groupe auxiliaire-participe sans aucune justification stylistique. « Déjà a terminé sa tournée de livraisons » : l''adverbe ne peut pas s''intercaler entre le sujet et l''auxiliaire (sauf inversion littéraire, absente ici). « A terminé sa tournée de livraisons déjà » relègue « déjà » en fin de phrase, tour du français parlé familier, non standard à l''écrit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Trois mois après le dépôt de son dossier, Mariam ___. »',
   'Dans la négation, la locution « **pas encore** » forme un bloc soudé placé entre l''auxiliaire et le participe passé : « n''a pas encore reçu ». « N''a encore pas reçu sa carte Vitale » inverse les deux adverbes : cet ordre, rare et fortement insistant, ne correspond pas au sens neutre attendu ici. « N''a pas reçu encore sa carte Vitale » rejette « encore » après le participe, construction maladroite et non standard. « Encore n''a pas reçu sa carte Vitale » placerait l''adverbe avant la négation, ce qui exigerait une inversion littéraire (« Encore n''a-t-elle pas reçu… ») absente ici.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pavlo ___ et attend la réponse avec impatience. »',
   'Les **adverbes de temps datés (hier, aujourd''hui, demain)** ne se placent jamais entre l''auxiliaire et le participe : ils vont en tête ou en fin de proposition → « a passé son entretien d''embauche hier ». « A hier passé son entretien d''embauche » viole cette interdiction, contrairement aux adverbes courts comme « déjà » ou « bien ». « Hier a passé son entretien d''embauche » intercale l''adverbe entre le sujet et le verbe, calque de l''anglais agrammatical en français. « A passé hier son entretien d''embauche » coupe le participe de son COD court : cette insertion n''est tolérée qu''avec un complément long et détaché.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Pour éviter tout refus de votre demande de logement, vous ___ avant de l''envoyer. »',
   'Un **adverbe court qui modifie un infinitif (bien, mal, mieux, trop)** se place devant cet infinitif : « devez bien relire ». « Devez relire bien le formulaire » postpose l''adverbe et rompt le lien direct adverbe-infinitif, tour maladroit et non standard. « Bien devez relire le formulaire » ferait porter « bien » sur « devez », position agrammaticale devant un verbe conjugué dont le sujet est exprimé. « Devez relire le formulaire bien » rejette l''adverbe en fin de phrase, registre oral relâché, incorrect à l''écrit.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Depuis qu''elle habite Strasbourg, Lin ___. »',
   'Avec un **verbe pronominal au passé composé**, l''adverbe court de fréquence « toujours » se place entre l''auxiliaire « être » et le participe : « s''est toujours déplacée ». « S''est déplacée toujours à vélo » sépare l''adverbe du noyau verbal qu''il modifie, ordre non standard en français écrit. « Toujours s''est déplacée à vélo » intercalerait l''adverbe entre le sujet et le pronom réfléchi, position impossible hors inversion littéraire. « S''est déplacée à vélo toujours » repousse l''adverbe en toute fin d''énoncé, tour oral relâché et fautif.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe'),

  ('33333333-c015-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Malgré les grèves de bus de cet hiver, Tomás ___. »',
   'Dans la négation « **ne … jamais** », l''adverbe « jamais » occupe la même place que « pas » : entre l''auxiliaire et le participe passé → « n''est jamais arrivé ». « Jamais n''est arrivé en retard à l''atelier » exigerait la mise en relief littéraire de « jamais » en tête de phrase, impossible ici après le sujet exprimé. « N''est arrivé jamais en retard à l''atelier » rejette « jamais » après le participe, ordre agrammatical en français standard. « N''est arrivé en retard à l''atelier jamais » relègue la négation en toute fin de phrase, calque d''autres langues, incorrect.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_place_adverbe');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c015-2100-0000-000000000001', '33333333-c015-1000-0000-000000000001', 'a progressé beaucoup à l''oral', 'false', '1'),
  ('33333333-c015-2200-0000-000000000001', '33333333-c015-1000-0000-000000000001', 'a beaucoup progressé à l''oral', 'true', '2'),
  ('33333333-c015-2300-0000-000000000001', '33333333-c015-1000-0000-000000000001', 'beaucoup a progressé à l''oral', 'false', '3'),
  ('33333333-c015-2400-0000-000000000001', '33333333-c015-1000-0000-000000000001', 'a progressé à l''oral beaucoup', 'false', '4'),

  ('33333333-c015-2100-0000-000000000002', '33333333-c015-1000-0000-000000000002', 'a déjà terminé sa tournée de livraisons', 'true', '1'),
  ('33333333-c015-2200-0000-000000000002', '33333333-c015-1000-0000-000000000002', 'a terminé déjà sa tournée de livraisons', 'false', '2'),
  ('33333333-c015-2300-0000-000000000002', '33333333-c015-1000-0000-000000000002', 'déjà a terminé sa tournée de livraisons', 'false', '3'),
  ('33333333-c015-2400-0000-000000000002', '33333333-c015-1000-0000-000000000002', 'a terminé sa tournée de livraisons déjà', 'false', '4'),

  ('33333333-c015-2100-0000-000000000003', '33333333-c015-1000-0000-000000000003', 'n''a encore pas reçu sa carte Vitale', 'false', '1'),
  ('33333333-c015-2200-0000-000000000003', '33333333-c015-1000-0000-000000000003', 'n''a pas reçu encore sa carte Vitale', 'false', '2'),
  ('33333333-c015-2300-0000-000000000003', '33333333-c015-1000-0000-000000000003', 'n''a pas encore reçu sa carte Vitale', 'true', '3'),
  ('33333333-c015-2400-0000-000000000003', '33333333-c015-1000-0000-000000000003', 'encore n''a pas reçu sa carte Vitale', 'false', '4'),

  ('33333333-c015-2100-0000-000000000004', '33333333-c015-1000-0000-000000000004', 'a hier passé son entretien d''embauche', 'false', '1'),
  ('33333333-c015-2200-0000-000000000004', '33333333-c015-1000-0000-000000000004', 'hier a passé son entretien d''embauche', 'false', '2'),
  ('33333333-c015-2300-0000-000000000004', '33333333-c015-1000-0000-000000000004', 'a passé hier son entretien d''embauche', 'false', '3'),
  ('33333333-c015-2400-0000-000000000004', '33333333-c015-1000-0000-000000000004', 'a passé son entretien d''embauche hier', 'true', '4'),

  ('33333333-c015-2100-0000-000000000005', '33333333-c015-1000-0000-000000000005', 'devez relire bien le formulaire', 'false', '1'),
  ('33333333-c015-2200-0000-000000000005', '33333333-c015-1000-0000-000000000005', 'devez bien relire le formulaire', 'true', '2'),
  ('33333333-c015-2300-0000-000000000005', '33333333-c015-1000-0000-000000000005', 'bien devez relire le formulaire', 'false', '3'),
  ('33333333-c015-2400-0000-000000000005', '33333333-c015-1000-0000-000000000005', 'devez relire le formulaire bien', 'false', '4'),

  ('33333333-c015-2100-0000-000000000006', '33333333-c015-1000-0000-000000000006', 's''est déplacée toujours à vélo', 'false', '1'),
  ('33333333-c015-2200-0000-000000000006', '33333333-c015-1000-0000-000000000006', 'toujours s''est déplacée à vélo', 'false', '2'),
  ('33333333-c015-2300-0000-000000000006', '33333333-c015-1000-0000-000000000006', 's''est toujours déplacée à vélo', 'true', '3'),
  ('33333333-c015-2400-0000-000000000006', '33333333-c015-1000-0000-000000000006', 's''est déplacée à vélo toujours', 'false', '4'),

  ('33333333-c015-2100-0000-000000000007', '33333333-c015-1000-0000-000000000007', 'n''est jamais arrivé en retard à l''atelier', 'true', '1'),
  ('33333333-c015-2200-0000-000000000007', '33333333-c015-1000-0000-000000000007', 'jamais n''est arrivé en retard à l''atelier', 'false', '2'),
  ('33333333-c015-2300-0000-000000000007', '33333333-c015-1000-0000-000000000007', 'n''est arrivé jamais en retard à l''atelier', 'false', '3'),
  ('33333333-c015-2400-0000-000000000007', '33333333-c015-1000-0000-000000000007', 'n''est arrivé en retard à l''atelier jamais', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c015-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 ordonnancements du même groupe verbal, tous composés de mots existants).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2 — max autorisé 3).
-- [x] Point unique : place de l''adverbe (adverbe court de quantité « beaucoup »,
--     adverbe court « déjà », bloc négatif « pas encore », adverbe daté « hier »,
--     adverbe court devant infinitif « bien », fréquence avec pronominal
--     « toujours », négation « ne … jamais ») — aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, nomme la règle de placement (**gras**)
--     et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (cours du soir à Rennes, tournée de livraisons,
--     carte Vitale, entretien d''embauche, demande de logement, vélo à Strasbourg,
--     ponctualité à l''atelier malgré les grèves) ; prénoms variés (Yuki, Sofian,
--     Mariam, Pavlo, Lin, Tomás).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
