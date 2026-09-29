-- ============================================================================
-- V637 — TCF SL B1 — lot 03 (point : pronoms y / en + pronoms COD/COI)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, tous sur les substitutions pronominales (haut du B1) :
-- « en » de quantité, « y » pour à+lieu, COI animé (téléphoner à → lui),
-- COD direct (aider → l''), « en » pour de+chose (parler de), « y » pour
-- à+chose (penser à), COI pluriel (expliquer à → leur), place du pronom
-- devant l''infinitif, rendre à qqn → lui (piège COD), remercier → les
-- (piège COI). UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b003-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Les abricots du marché de Perpignan sont superbes en ce moment : Carmen ___ achète deux kilos chaque samedi. »',
   'Le mécanisme testé est le **pronom « en » de quantité** : il reprend « des abricots » quand le verbe est suivi d''une expression de quantité (« deux kilos ») → « Carmen en achète deux kilos ». « Les » désignerait la totalité définie des abricots, incompatible avec la quantité partielle précisée juste après. « Y » remplace un complément en « à » (lieu ou chose), pas un partitif. « Leur » est un pronom COI réservé à des personnes (« écrire à ses parents → leur écrire »).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_en'),

  ('33333333-b003-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Bakary s''est inscrit à la médiathèque de Brest en janvier ; il ___ retourne trois fois par semaine. »',
   'Le mécanisme testé est le **pronom « y » pour « à + lieu »** : « retourner À la médiathèque » → « il y retourne ». « En » reprendrait un complément introduit par « de » : il conviendrait à « revenir DE la médiathèque → il en revient », pas à « retourner à ». « La » est un pronom COD : « la retourner » signifierait retourner un objet (une crêpe, une carte), contresens ici. « Lui » est un COI animé (« téléphoner à quelqu''un → lui téléphoner »), impossible pour un lieu.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_y'),

  ('33333333-b003-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Sa grand-mère vit seule près de Limoges, alors Nadia ___ téléphone tous les dimanches soir. »',
   'Le mécanisme testé est le **COI animé** : « téléphoner À quelqu''un » est une construction indirecte → pronom COI « lui » (« Nadia lui téléphone »). « La » et « l'' » sont des pronoms COD : ils supposeraient « téléphoner quelqu''un », construction qui n''existe pas en français — c''est LE piège classique de ce verbe. « Y » remplace « à + chose ou lieu », jamais une personne : « y téléphone » ne peut pas renvoyer à la grand-mère.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_coi'),

  ('33333333-b003-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Son petit frère bloque sur les fractions, alors Ines ___ aide chaque soir après le dîner. »',
   'Le mécanisme testé est le **COD direct** : « aider QUELQU''UN » se construit sans préposition → pronom COD élidé « l'' » (« Ines l''aide »). « Lui » est le piège inverse de « téléphoner » : beaucoup d''apprenants calquent « aider à quelqu''un », construction fautive — le COI est ici impossible. « Y » reprend « à + chose/lieu » et ne désigne jamais une personne. « En » reprend un complément en « de » ou une quantité, sans rapport avec ce contexte.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_cod'),

  ('33333333-b003-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « La hausse des loyers inquiète tout le quartier : on ___ parle même chez le coiffeur. »',
   'Le mécanisme testé est le **pronom « en » pour « de + chose »** : « parler DE quelque chose » → « on en parle ». « Le » est un COD : « parler » ne se construit directement qu''avec une langue (« parler le portugais »), pas avec un sujet de conversation. « Y » remplacerait un complément en « à » (« penser à la hausse → y penser »), mais parler exige « de ». « Lui » est un COI animé : « parler à quelqu''un → lui parler » — or ici on parle D''un sujet, pas À une personne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_en'),

  ('33333333-b003-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Le rendez-vous à la préfecture est jeudi à 9 heures ; Hanae ___ pense depuis plusieurs jours. »',
   'Le mécanisme testé est le **pronom « y » pour « à + chose »** : « penser À quelque chose » → « Hanae y pense ». « En » ne s''emploie avec « penser » que dans la demande d''opinion (« Qu''en penses-tu ? » = penser DE), ce qui n''est pas le sens ici. « Le » est un COD impossible : « penser » est indirect quand il signifie « avoir en tête ». « Lui » servirait pour une personne (« penser à sa sœur → penser à elle / lui »), pas pour un rendez-vous, qui est une chose.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_y'),

  ('33333333-b003-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Les nouveaux apprentis ne connaissaient pas les machines, alors le chef d''atelier ___ a expliqué les consignes de sécurité. »',
   'Le mécanisme testé est le **COI pluriel** : « expliquer quelque chose À quelqu''un » → pronom COI « leur » pour les apprentis (« il leur a expliqué les consignes »). « Les » est le piège COD : il est impossible car le COD est déjà occupé par « les consignes » — les apprentis sont bien le complément indirect. « Lui » est un COI correct mais singulier, alors que « les apprentis » sont plusieurs. « Y » ne remplace que « à + chose/lieu », jamais des personnes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_coi'),

  ('33333333-b003-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Votre dossier est enfin complet : vous devez ___ à la sous-préfecture d''Annecy avant le 30 juin. »',
   'Le mécanisme testé est la **place du pronom devant l''infinitif** : avec « devoir + infinitif », le pronom COD se met immédiatement AVANT l''infinitif → « vous devez le déposer ». « Déposer-le » colle le pronom après le verbe avec un trait d''union : cette place n''existe qu''à l''impératif affirmatif (« Déposez-le ! »). « Lui déposer » emploie un COI alors que « déposer quelque chose » est direct — le dossier est un COD. « Y déposer » laisserait le verbe sans COD et ferait doublon avec « à la sous-préfecture », déjà exprimé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronom_cod'),

  ('33333333-b003-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « J''ai enfin croisé Samira au marché couvert de Dijon : je ___ ai rendu son écharpe. »',
   'Le mécanisme testé est la **distinction COD / COI avec un verbe à double complément** : « rendre quelque chose À quelqu''un » — l''écharpe est le COD, Samira le destinataire indirect → COI « lui » (« je lui ai rendu son écharpe »). « La » et « l'' » sont les pièges COD : « Samira » étant féminin, on est tenté de la pronominaliser en « la », mais la place du COD est déjà prise par « son écharpe ». « Leur » est bien un COI, mais pluriel, alors que Samira est une seule personne.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronoms_cod_coi'),

  ('33333333-b003-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Ses collègues l''ont beaucoup soutenu pendant son arrêt maladie ; Bruno veut ___ remercier avec une boîte de chocolats. »',
   'Le mécanisme testé est la **construction directe de « remercier »** : on remercie QUELQU''UN, sans préposition → pronom COD pluriel « les » (« Bruno veut les remercier »). « Leur » est LE piège : on calque « dire merci À quelqu''un », mais « remercier » n''accepte pas ce COI — « leur remercier » est fautif. « Lui » cumule deux erreurs : pronom indirect ET singulier, alors que les collègues sont plusieurs. « Y » ne pronominalise que « à + chose/lieu », jamais des personnes.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_pronoms_cod_coi');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b003-2100-0000-000000000001', '33333333-b003-1000-0000-000000000001', 'y', 'false', '1'),
  ('33333333-b003-2200-0000-000000000001', '33333333-b003-1000-0000-000000000001', 'en', 'true', '2'),
  ('33333333-b003-2300-0000-000000000001', '33333333-b003-1000-0000-000000000001', 'les', 'false', '3'),
  ('33333333-b003-2400-0000-000000000001', '33333333-b003-1000-0000-000000000001', 'leur', 'false', '4'),

  ('33333333-b003-2100-0000-000000000002', '33333333-b003-1000-0000-000000000002', 'y', 'true', '1'),
  ('33333333-b003-2200-0000-000000000002', '33333333-b003-1000-0000-000000000002', 'en', 'false', '2'),
  ('33333333-b003-2300-0000-000000000002', '33333333-b003-1000-0000-000000000002', 'la', 'false', '3'),
  ('33333333-b003-2400-0000-000000000002', '33333333-b003-1000-0000-000000000002', 'lui', 'false', '4'),

  ('33333333-b003-2100-0000-000000000003', '33333333-b003-1000-0000-000000000003', 'la', 'false', '1'),
  ('33333333-b003-2200-0000-000000000003', '33333333-b003-1000-0000-000000000003', 'y', 'false', '2'),
  ('33333333-b003-2300-0000-000000000003', '33333333-b003-1000-0000-000000000003', 'lui', 'true', '3'),
  ('33333333-b003-2400-0000-000000000003', '33333333-b003-1000-0000-000000000003', 'l''', 'false', '4'),

  ('33333333-b003-2100-0000-000000000004', '33333333-b003-1000-0000-000000000004', 'l''', 'true', '1'),
  ('33333333-b003-2200-0000-000000000004', '33333333-b003-1000-0000-000000000004', 'lui', 'false', '2'),
  ('33333333-b003-2300-0000-000000000004', '33333333-b003-1000-0000-000000000004', 'y', 'false', '3'),
  ('33333333-b003-2400-0000-000000000004', '33333333-b003-1000-0000-000000000004', 'en', 'false', '4'),

  ('33333333-b003-2100-0000-000000000005', '33333333-b003-1000-0000-000000000005', 'le', 'false', '1'),
  ('33333333-b003-2200-0000-000000000005', '33333333-b003-1000-0000-000000000005', 'y', 'false', '2'),
  ('33333333-b003-2300-0000-000000000005', '33333333-b003-1000-0000-000000000005', 'lui', 'false', '3'),
  ('33333333-b003-2400-0000-000000000005', '33333333-b003-1000-0000-000000000005', 'en', 'true', '4'),

  ('33333333-b003-2100-0000-000000000006', '33333333-b003-1000-0000-000000000006', 'en', 'false', '1'),
  ('33333333-b003-2200-0000-000000000006', '33333333-b003-1000-0000-000000000006', 'y', 'true', '2'),
  ('33333333-b003-2300-0000-000000000006', '33333333-b003-1000-0000-000000000006', 'le', 'false', '3'),
  ('33333333-b003-2400-0000-000000000006', '33333333-b003-1000-0000-000000000006', 'lui', 'false', '4'),

  ('33333333-b003-2100-0000-000000000007', '33333333-b003-1000-0000-000000000007', 'les', 'false', '1'),
  ('33333333-b003-2200-0000-000000000007', '33333333-b003-1000-0000-000000000007', 'lui', 'false', '2'),
  ('33333333-b003-2300-0000-000000000007', '33333333-b003-1000-0000-000000000007', 'leur', 'true', '3'),
  ('33333333-b003-2400-0000-000000000007', '33333333-b003-1000-0000-000000000007', 'y', 'false', '4'),

  ('33333333-b003-2100-0000-000000000008', '33333333-b003-1000-0000-000000000008', 'le déposer', 'true', '1'),
  ('33333333-b003-2200-0000-000000000008', '33333333-b003-1000-0000-000000000008', 'déposer-le', 'false', '2'),
  ('33333333-b003-2300-0000-000000000008', '33333333-b003-1000-0000-000000000008', 'lui déposer', 'false', '3'),
  ('33333333-b003-2400-0000-000000000008', '33333333-b003-1000-0000-000000000008', 'y déposer', 'false', '4'),

  ('33333333-b003-2100-0000-000000000009', '33333333-b003-1000-0000-000000000009', 'la', 'false', '1'),
  ('33333333-b003-2200-0000-000000000009', '33333333-b003-1000-0000-000000000009', 'lui', 'true', '2'),
  ('33333333-b003-2300-0000-000000000009', '33333333-b003-1000-0000-000000000009', 'l''', 'false', '3'),
  ('33333333-b003-2400-0000-000000000009', '33333333-b003-1000-0000-000000000009', 'leur', 'false', '4'),

  ('33333333-b003-2100-0000-00000000000a', '33333333-b003-1000-0000-00000000000a', 'leur', 'false', '1'),
  ('33333333-b003-2200-0000-00000000000a', '33333333-b003-1000-0000-00000000000a', 'lui', 'false', '2'),
  ('33333333-b003-2300-0000-00000000000a', '33333333-b003-1000-0000-00000000000a', 'y', 'false', '3'),
  ('33333333-b003-2400-0000-00000000000a', '33333333-b003-1000-0000-00000000000a', 'les', 'true', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b003-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; options de même catégorie (pronoms,
--     ou groupes pronom+infinitif pour l''item 8 sur la place du pronom).
-- [x] Distribution des bonnes réponses : pos1=3, pos2=3, pos3=2, pos4=2 (équilibrée, 4 positions utilisées).
-- [x] Tous les items sur pronoms y/en + COD/COI, mécanismes tous différents :
--     en de quantité, y = à+lieu, COI animé (téléphoner → lui), COD direct (aider → l''),
--     en = de+chose (parler de), y = à+chose (penser à), COI pluriel (expliquer → leur),
--     place du pronom devant l''infinitif, double complément (rendre à → lui),
--     construction directe piégeuse (remercier → les).
-- [x] Aucun point interdit (pas d''imparfait/PC, relatifs, subjonctif,
--     connecteurs+gérondif, comparatifs/accord PP).
-- [x] competence_code par item : struct_pronom_en ×2, struct_pronom_y ×2,
--     struct_pronom_cod ×2, struct_pronom_coi ×2, struct_pronoms_cod_coi ×2.
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée, 3 distracteurs démontés.
-- [x] Contextes tous différents : marché de Perpignan, médiathèque de Brest,
--     grand-mère de Limoges, devoirs du petit frère, loyers du quartier,
--     rendez-vous en préfecture, atelier (apprentis), dossier à Annecy,
--     écharpe rendue à Dijon, collègues remerciés.
-- [x] Prénoms variés et originaux (Carmen, Bakary, Nadia, Ines, Hanae, Samira, Bruno).
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- [x] Longueurs de phrases homogènes, calibrées haut B1.
-- ============================================================================
