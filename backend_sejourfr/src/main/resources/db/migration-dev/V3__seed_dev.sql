-- ============================================================================
-- Seed dev uniquement (charge depuis db/migration-dev en profil dev)
-- ============================================================================
-- Utilisateurs :
--   admin@sejourfr.fr / Admin123!
--   user@sejourfr.fr  / User123!
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Utilisateurs
-- ---------------------------------------------------------------------------
INSERT INTO users (id, email, password_hash, first_name, last_name, target_procedure, target_level, role, is_active) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001',
   'admin@sejourfr.fr',
   '$2b$10$mQXIx9PyqIynrivTPMejDu3TtLjm1t0KgCzzkZj2vMB3H/nay2FG2',
   'Abdoul', 'K.',
   NULL, NULL,
   'ADMIN', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000002',
   'user@sejourfr.fr',
   '$2b$10$wE3C1plI1itm6y.2gU571esnUgiREg6Ri8qNNsYAv84hWLqfZbwF6',
   'Mariam', 'Diallo',
   'CR', 'B1',
   'USER', TRUE),
  ('aaaaaaaa-0000-0000-0000-000000000003',
   'karim.test@sejourfr.fr',
   '$2b$10$wE3C1plI1itm6y.2gU571esnUgiREg6Ri8qNNsYAv84hWLqfZbwF6',
   'Karim', 'Benyahia',
   'CR', 'B1',
   'USER', TRUE);

-- ---------------------------------------------------------------------------
-- Abonnements
-- ---------------------------------------------------------------------------
INSERT INTO user_subscriptions (id, user_id, plan_id, status, starts_at) VALUES
  ('bbbbbbbb-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000002',
   '33333333-0000-0000-0000-000000000002',  -- Premium mensuel
   'ACTIVE',
   NOW() - INTERVAL '15 days');

-- ---------------------------------------------------------------------------
-- Questions Civique (extraites du mockup admin)
-- ---------------------------------------------------------------------------

-- Q1 - Thème 1 (Principes) - CSP - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000001-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CSP', 'CONNAISSANCE',
        'Quelle est la devise de la République française ?',
        'La devise est inscrite à l''article 2 de la Constitution.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'Liberté, Fraternité, Solidarité', FALSE, 0),
  ('c1000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000001', 'Liberté, Égalité, Fraternité', TRUE, 1),
  ('c1000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000001', 'Liberté, Justice, Paix', FALSE, 2),
  ('c1000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000001', 'Unité, Travail, Patrie', FALSE, 3);

-- Q2 - Thème 1 - CR - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000001-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'CR', 'CONNAISSANCE',
        'Que signifie la laïcité ?',
        'Loi du 9 décembre 1905.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000002-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000002', 'L''interdiction de toute religion', FALSE, 0),
  ('c1000002-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000002', 'La séparation des religions et de l''État', TRUE, 1),
  ('c1000002-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000002', 'L''obligation de pratiquer une religion d''État', FALSE, 2),
  ('c1000002-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000002', 'Le respect de la religion majoritaire', FALSE, 3);

-- Q3 - Thème 1 - NAT - Mise en situation
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000001-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000001', 'NAT', 'MISE_SITUATION',
        'Un collègue refuse de serrer la main d''une collègue pour des raisons religieuses. Que faites-vous ?',
        'L''égalité hommes-femmes est un principe fondamental.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000003-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000003', 'Je le félicite', FALSE, 0),
  ('c1000003-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000003', 'Je rappelle l''égalité hommes-femmes', TRUE, 1),
  ('c1000003-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'Je ne dis rien', FALSE, 2),
  ('c1000003-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000003', 'Je le dénonce', FALSE, 3);

-- Q4 - Thème 2 (Institutions) - CSP - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000002-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui élit le président de la République en France ?',
        'Suffrage universel direct depuis 1962.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000004-0000-0000-0000-000000000001', 'c0000002-0000-0000-0000-000000000001', 'Le Parlement', FALSE, 0),
  ('c1000004-0000-0000-0000-000000000002', 'c0000002-0000-0000-0000-000000000001', 'Les citoyens au suffrage universel direct', TRUE, 1),
  ('c1000004-0000-0000-0000-000000000003', 'c0000002-0000-0000-0000-000000000001', 'Le Conseil constitutionnel', FALSE, 2),
  ('c1000004-0000-0000-0000-000000000004', 'c0000002-0000-0000-0000-000000000001', 'Les maires', FALSE, 3);

-- Q5 - Thème 2 - CR - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000002-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quelle est la durée du mandat présidentiel ?',
        'Quinquennat depuis 2000.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000005-0000-0000-0000-000000000001', 'c0000002-0000-0000-0000-000000000002', '4 ans', FALSE, 0),
  ('c1000005-0000-0000-0000-000000000002', 'c0000002-0000-0000-0000-000000000002', '5 ans', TRUE, 1),
  ('c1000005-0000-0000-0000-000000000003', 'c0000002-0000-0000-0000-000000000002', '7 ans', FALSE, 2),
  ('c1000005-0000-0000-0000-000000000004', 'c0000002-0000-0000-0000-000000000002', '6 ans', FALSE, 3);

-- Q6 - Thème 2 - NAT - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000002-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quels sont les trois pouvoirs séparés selon Montesquieu ?',
        'Principe fondamental de la séparation des pouvoirs.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000006-0000-0000-0000-000000000001', 'c0000002-0000-0000-0000-000000000003', 'Exécutif, militaire, religieux', FALSE, 0),
  ('c1000006-0000-0000-0000-000000000002', 'c0000002-0000-0000-0000-000000000003', 'Législatif, exécutif, judiciaire', TRUE, 1),
  ('c1000006-0000-0000-0000-000000000003', 'c0000002-0000-0000-0000-000000000003', 'Présidentiel, parlementaire, médiatique', FALSE, 2),
  ('c1000006-0000-0000-0000-000000000004', 'c0000002-0000-0000-0000-000000000003', 'Civil, pénal, administratif', FALSE, 3);

-- Q7 - Thème 3 (Droits) - CSP - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000003-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
        'À quel âge devient-on majeur en France ?',
        'La majorité civile est fixée à 18 ans depuis 1974.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000007-0000-0000-0000-000000000001', 'c0000003-0000-0000-0000-000000000001', '16 ans', FALSE, 0),
  ('c1000007-0000-0000-0000-000000000002', 'c0000003-0000-0000-0000-000000000001', '18 ans', TRUE, 1),
  ('c1000007-0000-0000-0000-000000000003', 'c0000003-0000-0000-0000-000000000001', '21 ans', FALSE, 2),
  ('c1000007-0000-0000-0000-000000000004', 'c0000003-0000-0000-0000-000000000001', '20 ans', FALSE, 3);

-- Q8 - Thème 3 - CR - Mise en situation
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000003-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Vous êtes témoin d''un accident dans la rue. Que devez-vous faire ?',
        'L''assistance à personne en danger est une obligation légale.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000008-0000-0000-0000-000000000001', 'c0000003-0000-0000-0000-000000000002', 'Partir rapidement', FALSE, 0),
  ('c1000008-0000-0000-0000-000000000002', 'c0000003-0000-0000-0000-000000000002', 'Porter assistance et prévenir les secours', TRUE, 1),
  ('c1000008-0000-0000-0000-000000000003', 'c0000003-0000-0000-0000-000000000002', 'Filmer la scène', FALSE, 2),
  ('c1000008-0000-0000-0000-000000000004', 'c0000003-0000-0000-0000-000000000002', 'Attendre quelqu''un d''autre', FALSE, 3);

-- Q9 - Thème 3 - NAT - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000003-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Quel impôt finance les services publics locaux ?',
        'Les collectivités sont financées par les impôts locaux.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000009-0000-0000-0000-000000000001', 'c0000003-0000-0000-0000-000000000003', 'L''impôt sur le revenu', FALSE, 0),
  ('c1000009-0000-0000-0000-000000000002', 'c0000003-0000-0000-0000-000000000003', 'Les taxes locales', TRUE, 1),
  ('c1000009-0000-0000-0000-000000000003', 'c0000003-0000-0000-0000-000000000003', 'La TVA', FALSE, 2),
  ('c1000009-0000-0000-0000-000000000004', 'c0000003-0000-0000-0000-000000000003', 'Aucun impôt', FALSE, 3);

-- Q10 - Thème 4 (Histoire) - CSP - Connaissance
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000004-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'En quelle année a eu lieu la Révolution française ?',
        'Prise de la Bastille le 14 juillet 1789.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000010-0000-0000-0000-000000000001', 'c0000004-0000-0000-0000-000000000001', '1689', FALSE, 0),
  ('c1000010-0000-0000-0000-000000000002', 'c0000004-0000-0000-0000-000000000001', '1789', TRUE, 1),
  ('c1000010-0000-0000-0000-000000000003', 'c0000004-0000-0000-0000-000000000001', '1815', FALSE, 2),
  ('c1000010-0000-0000-0000-000000000004', 'c0000004-0000-0000-0000-000000000001', '1848', FALSE, 3);

-- Q11 - Thème 5 (Société) - CSP - Mise en situation
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('c0000005-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
        'Votre voisin organise une fête bruyante tard dans la nuit. Que faites-vous d''abord ?',
        'Le dialogue est toujours la première étape avant d''alerter les autorités.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000011-0000-0000-0000-000000000001', 'c0000005-0000-0000-0000-000000000001', 'J''appelle directement la police', FALSE, 0),
  ('c1000011-0000-0000-0000-000000000002', 'c0000005-0000-0000-0000-000000000001', 'Je vais poliment lui en parler', TRUE, 1),
  ('c1000011-0000-0000-0000-000000000003', 'c0000005-0000-0000-0000-000000000001', 'Je tape contre le mur', FALSE, 2),
  ('c1000011-0000-0000-0000-000000000004', 'c0000005-0000-0000-0000-000000000001', 'Je porte plainte immédiatement', FALSE, 3);

-- ---------------------------------------------------------------------------
-- Questions TCF
-- ---------------------------------------------------------------------------

-- Q12 - TCF Structure - A2
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('d0000003-0000-0000-0000-000000000001', 'TCF',
        '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE',
        'Hier, je ___ au cinéma avec mes amis.',
        'Passé composé avec être : il s''accorde avec le sujet.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000012-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000001', 'vais', FALSE, 0),
  ('c1000012-0000-0000-0000-000000000002', 'd0000003-0000-0000-0000-000000000001', 'suis allé', TRUE, 1),
  ('c1000012-0000-0000-0000-000000000003', 'd0000003-0000-0000-0000-000000000001', 'ai allé', FALSE, 2),
  ('c1000012-0000-0000-0000-000000000004', 'd0000003-0000-0000-0000-000000000001', 'allerai', FALSE, 3);

-- Q13 - TCF Structure - B1
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('d0000003-0000-0000-0000-000000000002', 'TCF',
        '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE',
        'Il faut que tu ___ à l''heure demain.',
        'Subjonctif présent du verbe être après "il faut que".', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000013-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000002', 'es', FALSE, 0),
  ('c1000013-0000-0000-0000-000000000002', 'd0000003-0000-0000-0000-000000000002', 'sois', TRUE, 1),
  ('c1000013-0000-0000-0000-000000000003', 'd0000003-0000-0000-0000-000000000002', 'seras', FALSE, 2),
  ('c1000013-0000-0000-0000-000000000004', 'd0000003-0000-0000-0000-000000000002', 'étais', FALSE, 3);

-- Q14 - TCF Structure - B2
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('d0000003-0000-0000-0000-000000000003', 'TCF',
        '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE',
        'Si j''avais su, je ___ autrement.',
        'Conditionnel passé dans une hypothèse irréelle du passé.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000014-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000003', 'agirais', FALSE, 0),
  ('c1000014-0000-0000-0000-000000000002', 'd0000003-0000-0000-0000-000000000003', 'aurais agi', TRUE, 1),
  ('c1000014-0000-0000-0000-000000000003', 'd0000003-0000-0000-0000-000000000003', 'agis', FALSE, 2),
  ('c1000014-0000-0000-0000-000000000004', 'd0000003-0000-0000-0000-000000000003', 'aie agi', FALSE, 3);

-- Q15 - TCF CE - A2
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('d0000002-0000-0000-0000-000000000001', 'TCF',
        '22222222-0000-0000-0000-000000000002', 'A2', 'CE',
        'Sur un panneau "Défense de stationner du lundi au vendredi de 8h à 18h", puis-je me garer le samedi matin ?',
        'La restriction ne concerne pas les week-ends.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
  ('c1000015-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'Non, jamais', FALSE, 0),
  ('c1000015-0000-0000-0000-000000000002', 'd0000002-0000-0000-0000-000000000001', 'Oui, c''est autorisé', TRUE, 1),
  ('c1000015-0000-0000-0000-000000000003', 'd0000002-0000-0000-0000-000000000001', 'Uniquement avec un permis spécial', FALSE, 2),
  ('c1000015-0000-0000-0000-000000000004', 'd0000002-0000-0000-0000-000000000001', 'Seulement après 18h', FALSE, 3);

-- ---------------------------------------------------------------------------
-- Conversations (échanges utilisateur <-> admin) - exemples
-- ---------------------------------------------------------------------------

-- Conversation 1 : utilisateur a une question, pas encore lue par l'admin
INSERT INTO conversations (id, user_id, subject, status, last_message_at, unread_for_admin, unread_for_user)
VALUES ('e0000000-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000002',
        'Question sur l''examen civique',
        'NOUVEAU',
        NOW() - INTERVAL '2 hours',
        TRUE, FALSE);
INSERT INTO messages (id, conversation_id, sender_type, author_id, body, created_at) VALUES
  ('e0001000-0000-0000-0000-000000000001',
   'e0000000-0000-0000-0000-000000000001',
   'USER',
   'aaaaaaaa-0000-0000-0000-000000000002',
   'Bonjour, je prépare la naturalisation et je voudrais savoir combien de questions de mise en situation il y a dans l''examen civique ? Merci !',
   NOW() - INTERVAL '2 hours');

-- Conversation 2 : échange complet, admin a déjà répondu
INSERT INTO conversations (id, user_id, subject, status, last_message_at, unread_for_admin, unread_for_user)
VALUES ('e0000000-0000-0000-0000-000000000002',
        'aaaaaaaa-0000-0000-0000-000000000003',
        'Problème d''accès à un audio TCF',
        'REPONDU',
        NOW() - INTERVAL '1 day',
        FALSE, TRUE);
INSERT INTO messages (id, conversation_id, sender_type, author_id, body, created_at) VALUES
  ('e0002000-0000-0000-0000-000000000001',
   'e0000000-0000-0000-0000-000000000002',
   'USER',
   'aaaaaaaa-0000-0000-0000-000000000003',
   'Bonjour, l''audio de la question 12 du module TCF ne se lance pas chez moi. Je suis sur Android.',
   NOW() - INTERVAL '2 days'),
  ('e0002000-0000-0000-0000-000000000002',
   'e0000000-0000-0000-0000-000000000002',
   'ADMIN',
   'aaaaaaaa-0000-0000-0000-000000000001',
   'Bonjour Karim, merci pour le retour. Pourriez-vous me préciser la version d''Android et le modèle du téléphone ? Nous regardons cela rapidement.',
   NOW() - INTERVAL '1 day');
