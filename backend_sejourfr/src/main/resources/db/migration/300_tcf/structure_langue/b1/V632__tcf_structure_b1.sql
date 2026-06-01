-- ============================================================================
-- V632 — TCF Structure B1
-- ----------------------------------------------------------------------------
-- 30 nouvelles questions de structure niveau B1.
-- IDs générés avec gen_random_uuid().
-- ============================================================================

-- Question 1
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « J''ai oublié le nom de la personne ___ m''a téléphoné ce matin. »',
     'Le pronom relatif remplace le sujet du verbe « a téléphoné ». On utilise donc « qui ». « Que » remplace un COD, « dont » un complément introduit par « de », et « où » un lieu ou un moment.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_qui')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('que', false, 1),
  ('qui', true, 2),
  ('dont', false, 3),
  ('où', false, 4)
) AS v(label, is_correct, display_order);

-- Question 2
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Si nous partions plus tôt, nous ___ moins de circulation. »',
     'Avec « si + imparfait », la principale se met au conditionnel présent : « aurions ». Cette structure exprime une hypothèse possible ou imaginaire.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_si_imparfait_conditionnel')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('avons', false, 1),
  ('aurons', false, 2),
  ('aurions', true, 3),
  ('avions', false, 4)
) AS v(label, is_correct, display_order);

-- Question 3
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Remplacez le complément : « Elle pense à ses vacances. → Elle ___ pense souvent. »',
     'Le complément « à ses vacances » se remplace par « y », car le verbe « penser à quelque chose » prend la préposition « à ». « En » reprend plutôt un complément introduit par « de ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_pronom_y')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('en', false, 1),
  ('la', false, 2),
  ('y', true, 3),
  ('les', false, 4)
) AS v(label, is_correct, display_order);

-- Question 4
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Il faut que vous ___ cette réponse avant de continuer. »',
     'Après « il faut que », on utilise le subjonctif. À la 2e personne du pluriel du verbe « comprendre », la forme correcte est « compreniez ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_subjonctif_obligation')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('comprenez', false, 1),
  ('comprendrez', false, 2),
  ('comprendriez', false, 3),
  ('compreniez', true, 4)
) AS v(label, is_correct, display_order);

-- Question 5
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Quand j''étais enfant, je ___ souvent chez mes grands-parents. »',
     'Pour une habitude dans le passé, on utilise l''imparfait : « allais ». Le passé composé indiquerait une action ponctuelle terminée.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_imparfait_habitude')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('suis allé', false, 1),
  ('irai', false, 2),
  ('allais', true, 3),
  ('vais', false, 4)
) AS v(label, is_correct, display_order);

-- Question 6
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Elle a réussi son examen ___ elle avait beaucoup travaillé. »',
     'On exprime ici la cause : elle a réussi parce qu''elle avait travaillé. Le connecteur correct est « parce que ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_connecteur_cause')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('donc', false, 1),
  ('parce qu''', true, 2),
  ('mais', false, 3),
  ('pourtant', false, 4)
) AS v(label, is_correct, display_order);

-- Question 7
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Le document ___ j''ai besoin est dans mon sac. »',
     'Le verbe « avoir besoin de » se construit avec « de ». Le pronom relatif correspondant est « dont » : le document dont j''ai besoin.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_dont')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('que', false, 1),
  ('qui', false, 2),
  ('dont', true, 3),
  ('où', false, 4)
) AS v(label, is_correct, display_order);

-- Question 8
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Nous sommes arrivés en retard, ___ le professeur nous a acceptés. »',
     'On oppose deux idées : arriver en retard et être accepté malgré cela. Le connecteur adapté est « pourtant ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_connecteur_opposition')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('car', false, 1),
  ('pourtant', true, 2),
  ('donc', false, 3),
  ('parce que', false, 4)
) AS v(label, is_correct, display_order);

-- Question 9
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Avant de sortir, elle ___ toutes les fenêtres. »',
     'Le plus-que-parfait exprime une action terminée avant une autre action passée. Ici, fermer les fenêtres est antérieur à sortir : « avait fermé ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_plus_que_parfait')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('fermait', false, 1),
  ('a fermé', false, 2),
  ('avait fermé', true, 3),
  ('fermera', false, 4)
) AS v(label, is_correct, display_order);

-- Question 10
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Je n''ai pas encore vu le film, mais mes amis ___ ont parlé. »',
     'Le verbe « parler de quelque chose » se construit avec « de ». Le pronom qui reprend ce complément est « en » : ils en ont parlé.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_pronom_en')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('le', false, 1),
  ('y', false, 2),
  ('en', true, 3),
  ('lui', false, 4)
) AS v(label, is_correct, display_order);

-- Question 11
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Le train partira dès que tous les voyageurs ___. »',
     'Avec « dès que » dans un contexte futur, on utilise le futur simple : « seront montés ». Cela indique une action future accomplie avant le départ.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_futur_anterieur')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('montent', false, 1),
  ('sont montés', false, 2),
  ('seront montés', true, 3),
  ('montaient', false, 4)
) AS v(label, is_correct, display_order);

-- Question 12
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Transformez à la voix passive : « Les élèves ont préparé la salle. »',
     'Au passif, le COD devient sujet : « la salle ». Le verbe se construit avec « être » au même temps que l''actif : « a été préparée ». Accord féminin singulier avec « salle ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_voix_passive_passe_compose')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('La salle est préparée par les élèves.', false, 1),
  ('La salle a été préparée par les élèves.', true, 2),
  ('La salle était préparée par les élèves.', false, 3),
  ('La salle sera préparée par les élèves.', false, 4)
) AS v(label, is_correct, display_order);

-- Question 13
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Je te téléphonerai quand je ___ chez moi. »',
     'Après « quand » avec une idée future, on utilise le futur simple en français : « serai ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_futur_apres_quand')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('suis', false, 1),
  ('étais', false, 2),
  ('serai', true, 3),
  ('serais', false, 4)
) AS v(label, is_correct, display_order);

-- Question 14
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Elle parle français ___ son arrivée en France. »',
     'Pour indiquer le point de départ d''une situation qui continue, on utilise « depuis » : depuis son arrivée.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_expression_temps_depuis')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('pendant', false, 1),
  ('depuis', true, 2),
  ('il y a', false, 3),
  ('pour', false, 4)
) AS v(label, is_correct, display_order);

-- Question 15
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Bien qu''il ___ fatigué, il est venu nous aider. »',
     'Après « bien que », on utilise le subjonctif. La forme correcte est « soit ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_subjonctif_concession')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('est', false, 1),
  ('était', false, 2),
  ('soit', true, 3),
  ('sera', false, 4)
) AS v(label, is_correct, display_order);

-- Question 16
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Les lettres que j''ai ___ hier sont déjà parties. »',
     'Avec l''auxiliaire « avoir », le participe passé s''accorde avec le COD placé avant le verbe. « Les lettres » est féminin pluriel, donc « écrites ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_accord_participe_avoir')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('écrit', false, 1),
  ('écrite', false, 2),
  ('écrits', false, 3),
  ('écrites', true, 4)
) AS v(label, is_correct, display_order);

-- Question 17
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Il travaille beaucoup ___ réussir son concours. »',
     'Quand le sujet est le même dans les deux parties de la phrase, on utilise « pour + infinitif ». Ici : il travaille pour réussir.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_expression_but_pour')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('pour', true, 1),
  ('pour que', false, 2),
  ('parce que', false, 3),
  ('donc', false, 4)
) AS v(label, is_correct, display_order);

-- Question 18
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Il est sorti ___ prendre l''air. »',
     'Le but est exprimé avec « pour + infinitif » quand le sujet est le même : il est sorti pour prendre l''air.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_but_infinitif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('afin que', false, 1),
  ('pour', true, 2),
  ('parce que', false, 3),
  ('malgré', false, 4)
) AS v(label, is_correct, display_order);

-- Question 19
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Cette ville est ___ grande que je l''imaginais. »',
     'Pour comparer deux éléments avec un degré supérieur, on utilise « plus ... que ». La phrase correcte est « plus grande que ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_comparatif_superiorite')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('aussi', false, 1),
  ('moins', false, 2),
  ('plus', true, 3),
  ('très', false, 4)
) AS v(label, is_correct, display_order);

-- Question 20
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « C''est le restaurant ___ nous avons dîné samedi soir. »',
     'Le pronom relatif « où » remplace un complément de lieu. Ici, on a dîné dans ce restaurant.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_pronom_relatif_ou')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('que', false, 1),
  ('qui', false, 2),
  ('où', true, 3),
  ('dont', false, 4)
) AS v(label, is_correct, display_order);

-- Question 21
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Transformez au discours indirect : Paul dit : « Je suis malade. »',
     'Au discours indirect au présent, on garde le présent et on adapte le pronom : Paul dit qu''il est malade.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_discours_indirect_declaratif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('Paul dit qu''il est malade.', true, 1),
  ('Paul dit s''il est malade.', false, 2),
  ('Paul dit qu''il soit malade.', false, 3),
  ('Paul dit que je suis malade.', false, 4)
) AS v(label, is_correct, display_order);

-- Question 22
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Nous avons pris un taxi ___ ne pas arriver en retard. »',
     'Avec un infinitif négatif, on utilise « pour ne pas + infinitif » : pour ne pas arriver en retard.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_but_negatif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('pour ne pas', true, 1),
  ('pour que ne pas', false, 2),
  ('afin que', false, 3),
  ('parce que', false, 4)
) AS v(label, is_correct, display_order);

-- Question 23
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Je cherche quelqu''un qui ___ réparer mon ordinateur. »',
     'Après « chercher quelqu''un qui », quand l''existence de la personne n''est pas certaine, on emploie souvent le subjonctif : « puisse ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_subjonctif_apres_chercher')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('peut', false, 1),
  ('pourra', false, 2),
  ('puisse', true, 3),
  ('pouvait', false, 4)
) AS v(label, is_correct, display_order);

-- Question 24
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Les enfants se sont ___ les mains avant de manger. »',
     'Avec un verbe pronominal, si le COD est placé après le verbe, le participe passé ne s''accorde pas. Ici, « les mains » est après, donc « lavé ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_participe_pronominal')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('lavé', true, 1),
  ('lavés', false, 2),
  ('lavées', false, 3),
  ('laver', false, 4)
) AS v(label, is_correct, display_order);

-- Question 25
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Il conduit ___ téléphonant, ce qui est dangereux. »',
     'Le gérondif se forme avec « en + participe présent ». Il exprime ici deux actions simultanées : conduire et téléphoner.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_gerondif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('à', false, 1),
  ('en', true, 2),
  ('de', false, 3),
  ('pour', false, 4)
) AS v(label, is_correct, display_order);

-- Question 26
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Elle est partie sans ___ au revoir. »',
     'Après « sans », on utilise l''infinitif : « sans dire au revoir ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_preposition_sans_infinitif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('dit', false, 1),
  ('dire', true, 2),
  ('disant', false, 3),
  ('dira', false, 4)
) AS v(label, is_correct, display_order);

-- Question 27
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Je lui ai demandé ___ il voulait venir avec nous. »',
     'Pour rapporter une question fermée, on utilise « si » au discours indirect : demander si quelqu''un veut venir.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_discours_indirect_question')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('que', false, 1),
  ('si', true, 2),
  ('ce que', false, 3),
  ('dont', false, 4)
) AS v(label, is_correct, display_order);

-- Question 28
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Ce problème est difficile, mais il n''est pas ___. »',
     'Le contraire de « possible » est « impossible ». Ici, on veut dire qu''il est difficile mais qu''on peut le résoudre.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_prefixe_negatif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('possible', false, 1),
  ('impossible', true, 2),
  ('possibilité', false, 3),
  ('possiblement', false, 4)
) AS v(label, is_correct, display_order);

-- Question 29
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Il est le ___ joueur de son équipe cette saison. »',
     'Le superlatif de « bon » est « le meilleur ». On ne dit pas « le plus bon ».',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_superlatif_meilleur')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('plus bon', false, 1),
  ('meilleur', true, 2),
  ('mieux', false, 3),
  ('bon plus', false, 4)
) AS v(label, is_correct, display_order);

-- Question 30
WITH q AS (
  INSERT INTO questions
    (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
     is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
  VALUES
    (gen_random_uuid(), 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B1', 'STRUCTURE',
     'Complétez : « Je vais acheter ce dictionnaire ___ améliorer mon vocabulaire. »',
     'Le but s''exprime avec « pour + infinitif » quand le sujet est le même : j''achète ce dictionnaire pour améliorer mon vocabulaire.',
     true, now(), now(), 'ACTIVE', NULL, NULL, 'struct_but_pour_infinitif')
  RETURNING id
)
INSERT INTO choices (id, question_id, label, is_correct, display_order)
SELECT gen_random_uuid(), q.id, v.label, v.is_correct, v.display_order
FROM q, (VALUES
  ('car', false, 1),
  ('donc', false, 2),
  ('pour', true, 3),
  ('malgré', false, 4)
) AS v(label, is_correct, display_order);
