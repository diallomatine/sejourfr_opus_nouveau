-- ============================================================================
-- V8 : Seed de test pour le module TCF
--
-- 12 questions de TEST (4 par niveau A2/B1/B2), couvrant les 3 catégories :
--   - CO (Compréhension orale) : avec audio
--   - CE (Compréhension écrite) : avec image ou texte de passage
--   - STRUCTURE : texte seul (grammaire/lexique)
--
-- URLs externes : samplelib.com pour l'audio (placeholders techniques,
-- contenu non francophone — à remplacer par du TTS FR plus tard),
-- picsum.photos pour les images (placeholders libres).
-- Le texte attendu reste dans la colonne `transcript` des médias.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Thématiques TCF (3 catégories officielles)
-- ----------------------------------------------------------------------------

INSERT INTO themes (id, module, code, name, description, display_order) VALUES
                                                                            ('22222222-0000-0000-0000-000000000001', 'TCF', 'TCF_CO',        'Compréhension orale',    'Écouter et comprendre des messages, dialogues, annonces.', 1),
                                                                            ('22222222-0000-0000-0000-000000000002', 'TCF', 'TCF_CE',        'Compréhension écrite',   'Lire et comprendre textes courts, panneaux, e-mails.',     2),
                                                                            ('22222222-0000-0000-0000-000000000003', 'TCF', 'TCF_STRUCTURE', 'Structure de la langue', 'Grammaire, conjugaison, lexique en contexte.',             3)
    ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Médias (table `medias`)
-- Colonnes : id, type, url, storage_key, original_filename, content_type,
--            size_bytes, duration_sec, alt_text, transcript, created_at
-- ----------------------------------------------------------------------------

INSERT INTO medias (id, type, url, storage_key, original_filename, content_type, size_bytes, duration_sec, alt_text, transcript, created_at) VALUES

                                                                                                                                                 -- ---- AUDIOS (placeholders techniques samplelib.com) ----
                                                                                                                                                 ('33333333-0000-0000-0000-000000000001', 'AUDIO',
                                                                                                                                                  'https://download.samplelib.com/mp3/sample-9s.mp3',
                                                                                                                                                  NULL, 'sample-9s.mp3', 'audio/mpeg', NULL, 9,
                                                                                                                                                  'Annonce courte en gare',
                                                                                                                                                  'Le train à destination de Lyon partira voie 12 dans dix minutes.',
                                                                                                                                                  CURRENT_TIMESTAMP),

                                                                                                                                                 ('33333333-0000-0000-0000-000000000002', 'AUDIO',
                                                                                                                                                  'https://download.samplelib.com/mp3/sample-12s.mp3',
                                                                                                                                                  NULL, 'sample-12s.mp3', 'audio/mpeg', NULL, 12,
                                                                                                                                                  'Message vocal d''un collègue',
                                                                                                                                                  'Bonjour Marie, c''est Paul. Je voulais te dire que la réunion de demain est reportée à jeudi 14h. Rappelle-moi si tu peux.',
                                                                                                                                                  CURRENT_TIMESTAMP),

                                                                                                                                                 ('33333333-0000-0000-0000-000000000003', 'AUDIO',
                                                                                                                                                  'https://download.samplelib.com/mp3/sample-15s.mp3',
                                                                                                                                                  NULL, 'sample-15s.mp3', 'audio/mpeg', NULL, 15,
                                                                                                                                                  'Bref reportage radio',
                                                                                                                                                  'Selon la dernière étude publiée ce matin, la consommation d''électricité des ménages français a diminué de 4,2% sur l''année écoulée.',
                                                                                                                                                  CURRENT_TIMESTAMP),

                                                                                                                                                 -- ---- IMAGES (placeholders libres picsum.photos) ----
                                                                                                                                                 ('33333333-0000-0000-0000-000000000010', 'IMAGE',
                                                                                                                                                  'https://picsum.photos/seed/panneau-mairie/600/400',
                                                                                                                                                  NULL, 'panneau-mairie.jpg', 'image/jpeg', NULL, NULL,
                                                                                                                                                  'Panneau d''information devant une mairie',
                                                                                                                                                  NULL,
                                                                                                                                                  CURRENT_TIMESTAMP),

                                                                                                                                                 ('33333333-0000-0000-0000-000000000011', 'IMAGE',
                                                                                                                                                  'https://picsum.photos/seed/affiche-cinema/600/400',
                                                                                                                                                  NULL, 'affiche-cinema.jpg', 'image/jpeg', NULL, NULL,
                                                                                                                                                  'Affiche de cinéma colorée',
                                                                                                                                                  NULL,
                                                                                                                                                  CURRENT_TIMESTAMP),

                                                                                                                                                 ('33333333-0000-0000-0000-000000000012', 'IMAGE',
                                                                                                                                                  'https://picsum.photos/seed/sms-rdv/600/400',
                                                                                                                                                  NULL, 'sms-rdv.jpg', 'image/jpeg', NULL, NULL,
                                                                                                                                                  'Capture d''écran d''un SMS médical',
                                                                                                                                                  NULL,
                                                                                                                                                  CURRENT_TIMESTAMP)
    ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Passages (table `passages`)
-- Colonnes : id, type (enum PassageType : TEXTE/AUDIO/DIALOGUE),
--            content, media_id, theme_id
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES
                                                       ('44444444-0000-0000-0000-000000000001', 'TEXTE',
                                                        E'Bonjour Léa,\n\nJ''espère que tu vas bien. Je voulais te proposer de déjeuner ensemble samedi prochain, vers 12h30, au restaurant italien près de la mairie. Si cette date ne te convient pas, dis-le-moi, on peut décaler à dimanche.\n\nÀ très vite,\nClaire',
                                                        '22222222-0000-0000-0000-000000000002'),

                                                       ('44444444-0000-0000-0000-000000000002', 'TEXTE',
                                                        E'À partir du 1er septembre, le ticket de bus passera de 1,90€ à 2,10€. Cette augmentation, la première depuis trois ans, doit financer le renouvellement de la flotte. Les abonnements mensuels restent inchangés, et la gratuité demeure pour les moins de 12 ans et les personnes âgées de plus de 70 ans.',
                                                        '22222222-0000-0000-0000-000000000002'),

                                                       ('44444444-0000-0000-0000-000000000003', 'TEXTE',
                                                        E'Le télétravail s''est généralisé depuis 2020 dans de nombreuses entreprises françaises. Si certains salariés y voient un gain en autonomie et en équilibre de vie, d''autres déplorent un isolement croissant et une perte de cohésion d''équipe. Une enquête récente montre que 58% des cadres souhaitent un modèle hybride, alternant bureau et domicile, plutôt qu''un retour intégral en présentiel.',
                                                        '22222222-0000-0000-0000-000000000002')
    ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- QUESTIONS — Niveau A2 (CSP)
--
-- Colonnes de `questions` : id, module, theme_id, passage_id, media_id,
--   difficulty, question_type, statement, explanation, is_active,
--   created_at (NOT NULL), updated_at
-- ============================================================================

-- Q1 : CO A2 — annonce de gare
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000001', 'TCF',
     '22222222-0000-0000-0000-000000000001', 'A2', 'CO',
     'Vous entendez cette annonce dans une gare. Quelle est la destination du train ?',
     'L''annonce dit « Le train à destination de Lyon ». La destination est donc Lyon.',
     '33333333-0000-0000-0000-000000000001', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000001', 'Paris',      false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000001', 'Lyon',       true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000001', 'Marseille',  false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000001', 'Toulouse',   false, 4);

-- Q2 : CE A2 — image (panneau de mairie)
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000002', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'A2', 'CE',
     'Vous voyez cette affiche devant la mairie. Que pouvez-vous y faire ?',
     'Une affiche devant une mairie indique généralement les services administratifs disponibles.',
     '33333333-0000-0000-0000-000000000010', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000002', 'Acheter du pain',                       false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000002', 'Effectuer une démarche administrative', true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000002', 'Réserver un hôtel',                     false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000002', 'Faire du sport',                        false, 4);

-- Q3 : CE A2 — texte court (e-mail Claire)
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, passage_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000003', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'A2', 'CE',
     'Quel jour Claire propose-t-elle de déjeuner ?',
     'Claire écrit « samedi prochain, vers 12h30 ». La date proposée est donc samedi.',
     '44444444-0000-0000-0000-000000000001', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000003', 'Vendredi', false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000003', 'Samedi',   true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000003', 'Dimanche', false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000003', 'Lundi',    false, 4);

-- Q4 : STRUCTURE A2 — article défini
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000004', 'TCF',
     '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE',
     'Complétez : « Marie va ___ école tous les matins. »',
     '« École » est un nom féminin commençant par une voyelle, on utilise « à l'' » devant.',
     true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000004', 'au',    false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000004', 'à la',  false, 2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000004', 'à l''', true,  3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000004', 'aux',   false, 4);

-- ============================================================================
-- QUESTIONS — Niveau B1 (CR)
-- ============================================================================

-- Q5 : CO B1 — message vocal
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000005', 'TCF',
     '22222222-0000-0000-0000-000000000001', 'B1', 'CO',
     'Vous écoutez ce message vocal. Pourquoi Paul appelle-t-il ?',
     'Paul dit « la réunion de demain est reportée à jeudi ». Il appelle pour informer d''un changement de date.',
     '33333333-0000-0000-0000-000000000002', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000005', 'Pour annuler la réunion',                   false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000005', 'Pour reporter la réunion à une autre date', true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000005', 'Pour confirmer l''heure de la réunion',     false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000005', 'Pour proposer un nouveau lieu',             false, 4);

-- Q6 : CE B1 — article transports
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, passage_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000006', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'B1', 'CE',
     'Selon l''article, qui peut continuer à voyager gratuitement ?',
     'L''article précise « la gratuité demeure pour les moins de 12 ans et les personnes âgées de plus de 70 ans ».',
     '44444444-0000-0000-0000-000000000002', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000006', 'Les étudiants',                                                   false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000006', 'Les enfants de moins de 12 ans et les seniors de plus de 70 ans', true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000006', 'Les salariés en arrêt maladie',                                   false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000006', 'Tous les habitants de la ville',                                  false, 4);

-- Q7 : CE B1 — image affiche cinéma
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000007', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'B1', 'CE',
     'Vous regardez cette affiche dans la rue. À quel type d''événement vous invite-t-elle ?',
     'Une affiche colorée avec des éléments visuels artistiques évoque typiquement un événement culturel.',
     '33333333-0000-0000-0000-000000000011', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000007', 'Une réunion politique',         false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000007', 'Une projection de film',        true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000007', 'Une manifestation sportive',    false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000007', 'Une vente de meubles',          false, 4);

-- Q8 : STRUCTURE B1 — conditionnel
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000008', 'TCF',
     '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE',
     'Complétez : « Si j''avais le temps, je ___ plus souvent au cinéma. »',
     'La structure « Si + imparfait » dans la subordonnée appelle un conditionnel présent dans la principale : « j''irais ».',
     true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000008', 'vais',    false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000008', 'irais',   true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000008', 'allais',  false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000008', 'aille',   false, 4);

-- ============================================================================
-- QUESTIONS — Niveau B2 (NAT)
-- ============================================================================

-- Q9 : CO B2 — reportage radio
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000009', 'TCF',
     '22222222-0000-0000-0000-000000000001', 'B2', 'CO',
     'Selon ce reportage, comment a évolué la consommation d''électricité des ménages ?',
     'Le reportage dit « a diminué de 4,2% sur l''année écoulée », c''est donc une baisse.',
     '33333333-0000-0000-0000-000000000003', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000009', 'Elle a augmenté légèrement',   false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000009', 'Elle a baissé d''environ 4%',  true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000009', 'Elle est restée stable',       false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000009', 'Elle a doublé en un an',       false, 4);

-- Q10 : CE B2 — tribune télétravail
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, passage_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000010', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'B2', 'CE',
     'Quelle est la position majoritaire des cadres selon le texte ?',
     'Le texte indique que « 58% des cadres souhaitent un modèle hybride ».',
     '44444444-0000-0000-0000-000000000003', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000010', 'Un retour total au bureau',                  false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000010', 'Un télétravail à 100%',                      false, 2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000010', 'Un modèle hybride entre bureau et domicile', true,  3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000010', 'Une réduction du temps de travail',          false, 4);

-- Q11 : CE B2 — image SMS rendez-vous
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, media_id, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000011', 'TCF',
     '22222222-0000-0000-0000-000000000002', 'B2', 'CE',
     'Vous recevez ce SMS de votre médecin. Quelle action devez-vous entreprendre ?',
     'Un SMS de rappel de rendez-vous médical demande généralement une confirmation de la part du patient.',
     '33333333-0000-0000-0000-000000000012', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000011', 'Confirmer ou annuler le rendez-vous', true,  1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000011', 'Payer une facture en ligne',          false, 2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000011', 'Télécharger une ordonnance',          false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000011', 'Prendre un nouveau rendez-vous',      false, 4);

-- Q12 : STRUCTURE B2 — subjonctif
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active, created_at, updated_at) VALUES
    ('55555555-0000-0000-0000-000000000012', 'TCF',
     '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE',
     'Complétez : « Bien qu''il ___ très fatigué, il a tenu jusqu''à la fin de la réunion. »',
     'La conjonction « bien que » est toujours suivie du subjonctif. À la 3e personne du singulier de « être » : « soit ».',
     true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000012', 'est',    false, 1),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000012', 'soit',   true,  2),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000012', 'serait', false, 3),
                                                                            (gen_random_uuid(), '55555555-0000-0000-0000-000000000012', 'sera',   false, 4);