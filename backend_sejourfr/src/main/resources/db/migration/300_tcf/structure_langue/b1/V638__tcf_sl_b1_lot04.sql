-- ============================================================================
-- V638 — TCF SL B1 — lot 04 (point : subjonctif présent après déclencheurs courants)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B1'.
-- 10 items, tous sur le subjonctif présent après déclencheurs courants (haut B1),
-- déclencheurs tous différents : il faut que, pour que, bien que, avant que (+ ne
-- explétif), je suis contente que, je crains que (+ ne explétif), il est important
-- que, il vaut mieux que — plus deux contrastes avec l''indicatif après « je pense
-- que » (affirmatif) et « j''espère que ». Contextes de phrase tous différents.
-- UUID déterministes, rejouables dev + recette.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-b004-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Pour renouveler ton titre de séjour, il faut que tu ___ la demande en ligne avant la fin du mois. »',
   '« **Il faut que** » exprime la nécessité et déclenche obligatoirement le **subjonctif présent** → « fasses ». « Fais » est l''indicatif présent : il décrirait un fait réel, alors qu''ici l''action est seulement exigée, pas encore accomplie. « Feras » est un futur de l''indicatif, impossible après « que » introduit par « il faut ». « Ferais » est un conditionnel présent, réservé à l''hypothèse ou à la politesse — la structure impersonnelle de nécessité ne l''admet pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_il_faut_que'),

  ('33333333-b004-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Yousra traduit la lettre de l''école pour que sa mère ___ comprendre la décision du directeur. »',
   '« **Pour que** » est une conjonction de **but** : le résultat visé n''est pas encore réalisé, donc subjonctif présent → « puisse ». « Peut » est l''indicatif présent : il affirmerait un fait acquis, alors que la compréhension est justement l''objectif de la traduction. « Pourra » est un futur de l''indicatif, exclu après une conjonction finale. « Pouvait » est un imparfait de l''indicatif : il renverrait à une capacité passée, sans rapport avec le but exprimé.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_il_faut_que'),

  ('33333333-b004-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Bien que le loyer ___ plus élevé qu''à Limoges, Tarek a choisi un appartement en plein centre de Lyon. »',
   '« **Bien que** » introduit une **concession** (le fait est réel mais n''empêche pas la décision) et impose le subjonctif présent → « soit ». C''est un piège du haut B1 : le fait est avéré, beaucoup d''apprenants mettent donc « est » (indicatif présent), mais la conjonction concessive commande le mode, pas la réalité du fait. « Sera » est un futur de l''indicatif, doublement impossible. « Serait » est un conditionnel : il transformerait la concession en simple hypothèse non confirmée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_il_faut_que'),

  ('33333333-b004-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Dépêche-toi de composter ton billet avant que le train ne ___ du quai numéro trois. »',
   '« **Avant que** » situe l''action principale **avant un événement non encore réalisé** : subjonctif présent obligatoire → « parte » (le « ne » est ici explétif, sans valeur négative). « Part » est l''indicatif présent : il constaterait un départ en cours, ce que la conjonction d''antériorité interdit. « Partira » est un futur de l''indicatif, jamais admis après « avant que ». « Partait » est un imparfait : il décrirait un arrière-plan passé, incohérent avec l''impératif « dépêche-toi ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_il_faut_que'),

  ('33333333-b004-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Je suis très contente que vous ___ tous à la crémaillère de Mariam samedi prochain à Dijon. »',
   'Après un **verbe de sentiment** (« je suis contente que »), la subordonnée prend le **subjonctif présent** → « veniez » : on exprime une réaction affective, pas une simple information. « Venez » est l''indicatif présent : il ne ferait qu''énoncer le fait, sans marquer la dépendance au sentiment. « Viendrez » est un futur de l''indicatif — la date future (« samedi prochain ») ne change pas le mode exigé par le déclencheur. « Viendriez » est un conditionnel, qui suggérerait une venue hypothétique soumise à condition.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_sentiment'),

  ('33333333-b004-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Je crains que nous n''___ pas assez de temps pour visiter tout le musée avant la fermeture de dix-huit heures. »',
   '« **Je crains que** » est un verbe de **crainte** : il déclenche le subjonctif présent (avec « ne » explétif, sans valeur négative) → « ayons ». « Avons » est l''indicatif présent : il poserait le manque de temps comme un fait certain, alors que la crainte porte sur une éventualité. « Aurons » est un futur de l''indicatif, incompatible avec un déclencheur de crainte. « Aurions » est un conditionnel présent : il introduirait une hypothèse avec condition implicite, ce que la phrase ne contient pas.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_sentiment'),

  ('33333333-b004-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Je pense que Bogdan ___ nous aider à repeindre la cuisine dimanche : il me l''a promis hier soir. »',
   'Piège inverse du haut B1 : « **je pense que** » à la forme **affirmative** exprime une quasi-certitude et appelle l''**indicatif**, ici le futur → « viendra » (l''aide est prévue pour dimanche, et la promesse renforce la certitude). « Vienne » est le subjonctif : il ne s''emploie qu''avec la forme négative ou interrogative (« je ne pense pas qu''il vienne »). « Viendrait » est un conditionnel, qui marquerait une information non confirmée — contredit par « il me l''a promis ». « Venait » est un imparfait, sans cohérence avec une action future.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_important_que'),

  ('33333333-b004-1000-0000-000000000008', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « J''espère que tu ___ ton entretien d''embauche de jeudi matin à Strasbourg, tu l''as tellement préparé ! »',
   'Contrairement aux verbes de souhait (« je souhaite que » + subjonctif), « **espérer que** » se construit avec l''**indicatif**, le plus souvent au futur → « réussiras » : l''espoir est tourné vers un fait que l''on tient pour probable. « Réussisses » est le subjonctif : c''est le piège classique par analogie avec « souhaiter », mais « espérer » ne le déclenche pas. « Réussissais » est un imparfait, incohérent avec un entretien à venir jeudi. « Réussirais » est un conditionnel, qui affaiblirait l''espoir en pure hypothèse.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_sentiment'),

  ('33333333-b004-1000-0000-000000000009', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Il est important que chaque locataire ___ la parole au moins une fois pendant l''assemblée générale de l''immeuble. »',
   '« **Il est important que** » est une **expression impersonnelle de jugement** : elle impose le subjonctif présent → « prenne ». « Prend » est l''indicatif présent : il décrirait ce qui se passe réellement, alors que la phrase formule une recommandation, pas un constat. « Prendra » est un futur de l''indicatif, exclu après une tournure impersonnelle de nécessité. « Prenait » est un imparfait : il situerait l''action dans un passé descriptif, sans lien avec le jugement exprimé au présent.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_important_que'),

  ('33333333-b004-1000-0000-00000000000a', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
   'Complétez : « Avec une fièvre pareille, il vaut mieux que tu ___ tout de suite à la pharmacie de garde du boulevard Carnot. »',
   '« **Il vaut mieux que** » est une expression impersonnelle de **conseil/préférence** : elle exige le subjonctif présent → « ailles ». « Vas » est l''indicatif présent : il constaterait un déplacement en cours, alors que la phrase recommande une action encore à faire. « Iras » est un futur de l''indicatif, impossible derrière ce déclencheur impersonnel. « Irais » est un conditionnel présent : seul il pourrait exprimer un conseil (« tu irais bien… »), mais jamais à l''intérieur de la complétive en « que » commandée par « il vaut mieux ».',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL,
   'struct_subjonctif_important_que');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-b004-2100-0000-000000000001', '33333333-b004-1000-0000-000000000001', 'fais', 'false', '1'),
  ('33333333-b004-2200-0000-000000000001', '33333333-b004-1000-0000-000000000001', 'fasses', 'true', '2'),
  ('33333333-b004-2300-0000-000000000001', '33333333-b004-1000-0000-000000000001', 'feras', 'false', '3'),
  ('33333333-b004-2400-0000-000000000001', '33333333-b004-1000-0000-000000000001', 'ferais', 'false', '4'),

  ('33333333-b004-2100-0000-000000000002', '33333333-b004-1000-0000-000000000002', 'peut', 'false', '1'),
  ('33333333-b004-2200-0000-000000000002', '33333333-b004-1000-0000-000000000002', 'pourra', 'false', '2'),
  ('33333333-b004-2300-0000-000000000002', '33333333-b004-1000-0000-000000000002', 'puisse', 'true', '3'),
  ('33333333-b004-2400-0000-000000000002', '33333333-b004-1000-0000-000000000002', 'pouvait', 'false', '4'),

  ('33333333-b004-2100-0000-000000000003', '33333333-b004-1000-0000-000000000003', 'soit', 'true', '1'),
  ('33333333-b004-2200-0000-000000000003', '33333333-b004-1000-0000-000000000003', 'est', 'false', '2'),
  ('33333333-b004-2300-0000-000000000003', '33333333-b004-1000-0000-000000000003', 'sera', 'false', '3'),
  ('33333333-b004-2400-0000-000000000003', '33333333-b004-1000-0000-000000000003', 'serait', 'false', '4'),

  ('33333333-b004-2100-0000-000000000004', '33333333-b004-1000-0000-000000000004', 'part', 'false', '1'),
  ('33333333-b004-2200-0000-000000000004', '33333333-b004-1000-0000-000000000004', 'parte', 'true', '2'),
  ('33333333-b004-2300-0000-000000000004', '33333333-b004-1000-0000-000000000004', 'partira', 'false', '3'),
  ('33333333-b004-2400-0000-000000000004', '33333333-b004-1000-0000-000000000004', 'partait', 'false', '4'),

  ('33333333-b004-2100-0000-000000000005', '33333333-b004-1000-0000-000000000005', 'venez', 'false', '1'),
  ('33333333-b004-2200-0000-000000000005', '33333333-b004-1000-0000-000000000005', 'viendrez', 'false', '2'),
  ('33333333-b004-2300-0000-000000000005', '33333333-b004-1000-0000-000000000005', 'viendriez', 'false', '3'),
  ('33333333-b004-2400-0000-000000000005', '33333333-b004-1000-0000-000000000005', 'veniez', 'true', '4'),

  ('33333333-b004-2100-0000-000000000006', '33333333-b004-1000-0000-000000000006', 'ayons', 'true', '1'),
  ('33333333-b004-2200-0000-000000000006', '33333333-b004-1000-0000-000000000006', 'avons', 'false', '2'),
  ('33333333-b004-2300-0000-000000000006', '33333333-b004-1000-0000-000000000006', 'aurons', 'false', '3'),
  ('33333333-b004-2400-0000-000000000006', '33333333-b004-1000-0000-000000000006', 'aurions', 'false', '4'),

  ('33333333-b004-2100-0000-000000000007', '33333333-b004-1000-0000-000000000007', 'vienne', 'false', '1'),
  ('33333333-b004-2200-0000-000000000007', '33333333-b004-1000-0000-000000000007', 'viendrait', 'false', '2'),
  ('33333333-b004-2300-0000-000000000007', '33333333-b004-1000-0000-000000000007', 'viendra', 'true', '3'),
  ('33333333-b004-2400-0000-000000000007', '33333333-b004-1000-0000-000000000007', 'venait', 'false', '4'),

  ('33333333-b004-2100-0000-000000000008', '33333333-b004-1000-0000-000000000008', 'réussisses', 'false', '1'),
  ('33333333-b004-2200-0000-000000000008', '33333333-b004-1000-0000-000000000008', 'réussiras', 'true', '2'),
  ('33333333-b004-2300-0000-000000000008', '33333333-b004-1000-0000-000000000008', 'réussissais', 'false', '3'),
  ('33333333-b004-2400-0000-000000000008', '33333333-b004-1000-0000-000000000008', 'réussirais', 'false', '4'),

  ('33333333-b004-2100-0000-000000000009', '33333333-b004-1000-0000-000000000009', 'prend', 'false', '1'),
  ('33333333-b004-2200-0000-000000000009', '33333333-b004-1000-0000-000000000009', 'prendra', 'false', '2'),
  ('33333333-b004-2300-0000-000000000009', '33333333-b004-1000-0000-000000000009', 'prenait', 'false', '3'),
  ('33333333-b004-2400-0000-000000000009', '33333333-b004-1000-0000-000000000009', 'prenne', 'true', '4'),

  ('33333333-b004-2100-0000-00000000000a', '33333333-b004-1000-0000-00000000000a', 'vas', 'false', '1'),
  ('33333333-b004-2200-0000-00000000000a', '33333333-b004-1000-0000-00000000000a', 'iras', 'false', '2'),
  ('33333333-b004-2300-0000-00000000000a', '33333333-b004-1000-0000-00000000000a', 'ailles', 'true', '3'),
  ('33333333-b004-2400-0000-00000000000a', '33333333-b004-1000-0000-00000000000a', 'irais', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes (33333333-b004-1000-…-01..0a, choices 2100/2200/2300/2400).
-- [x] 4 propositions / 1 correcte par item ; 4 formes verbales du même verbe à chaque fois.
-- [x] Distribution des bonnes réponses : pos1=2, pos2=3, pos3=3, pos4=2 (équilibrée, 4 positions utilisées).
-- [x] Tous les items sur le subjonctif présent, déclencheurs tous différents :
--     il faut que, pour que, bien que (fait réel ≠ mode), avant que + ne explétif,
--     sentiment (contente que), crainte (je crains que + ne explétif),
--     il est important que, il vaut mieux que + 2 contrastes indicatif
--     (« je pense que » affirmatif → futur ; « j''espère que » → futur).
-- [x] Aucun point interdit (pas d''imparfait/PC en mécanisme testé, pas de relatifs,
--     pas de y/en ni COD/COI, pas de connecteurs+gérondif, pas de comparatifs/accord PP).
-- [x] competence_code répartis : struct_subjonctif_il_faut_que ×4 (items 1-4),
--     struct_subjonctif_sentiment ×3 (items 5, 6, 8), struct_subjonctif_important_que ×3 (items 7, 9, 10).
-- [x] explanation ≥ 80 caractères, point clé en **gras**, règle nommée, 3 distracteurs démontés.
-- [x] Contextes tous différents (titre de séjour, traduction scolaire, logement Lyon,
--     gare, crémaillère Dijon, musée, peinture cuisine, entretien Strasbourg,
--     assemblée d''immeuble, pharmacie de garde) ; prénoms variés (Yousra, Tarek,
--     Mariam, Bogdan) ; calibrage haut B1.
-- [x] Apostrophes SQL doublées partout ; pas de medias/passages (SVG/SSML : N/A pour SL).
-- ============================================================================
