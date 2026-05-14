-- ============================================================================
-- Flyway : reformulations questions officielles - THÈME 2 INSTITUTIONS
-- Lot 3/4 : R25 à R36 (separation pouvoirs, lois, département, commune)
-- is_active = FALSE
-- ============================================================================

-- R25 (de f2000000-...019 / CR / CONNAISSANCE) - Rôle députés
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la fonction principale des députés à l''Assemblée nationale ?',
 'Les députés votent les lois, examinent le budget de l''État et controlent l''action du gouvernement. Ils représentent la nation au Parlement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Voter les lois et contrôler le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Nommer le président', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Diriger l''armee', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Juger les criminels', FALSE, 3);

-- R26 (de f2000000-...01a / CR / CONNAISSANCE) - Trois pouvoirs
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quels sont les trois pouvoirs séparés dans un État démocratique selon Montesquieu ?',
 'La separation des pouvoirs (théorie de Montesquieu, reprise par la République française) distingue le pouvoir exécutif, le pouvoir législatif et le pouvoir judiciaire, qui doivent être indépendants les uns des autres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Exécutif, législatif et judiciaire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Civil, militaire et religieux', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'National, régional et local', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Politique, économique et social', FALSE, 3);

-- R27 (de f2000000-...01b / CR / CONNAISSANCE) - Qui detient le législatif
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui exerce le pouvoir législatif en France ?',
 'Le pouvoir législatif est exercé par le Parlement, composé de l''Assemblée nationale et du Sénat. Il vote les lois et le budget de l''État.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Le Parlement (Assemblée nationale et Sénat)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Le président seul', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Les juges', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Les préfets', FALSE, 3);

-- R28 (de f2000000-...01c / CR / CONNAISSANCE) - Sanction d'un vol
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle autorité prononcé la sanction contre l''auteur d''un vol ?',
 'L''auteur d''un vol est jugé et sanctionne par un tribunal, qui releve de l''autorité judiciaire. La peine dépend de la gravite des faits.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Un tribunal (autorité judiciaire)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le maire de la commune', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le président directement', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le voisin de la victime', FALSE, 3);

-- R29 (de f2000000-...01d / CSP / CONNAISSANCE) - Qui elit députés
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment les députés français sont-ils choisis ?',
 'Les députés sont élus directement par les citoyens français, au suffrage universel direct, dans le cadre de leur circonscription.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les citoyens français au suffrage direct', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par le président de la République', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les sénateurs', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les maires', FALSE, 3);

-- R30 (de f2000000-...01e / CSP / CONNAISSANCE) - Qui vote les lois
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle institution à la responsabilité de voter les lois en France ?',
 'Les lois sont votées par le Parlement (Assemblée nationale et Sénat). C''est le pouvoir législatif.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le Parlement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le président', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le Conseil d''État', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Les juges', FALSE, 3);

-- R31 (de f2000000-...01f / CSP / CONNAISSANCE) - Palais Élysée
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel responsable politique habite et travaille au palais de l''Élysée ?',
 'Le palais de l''Élysée, situé à Paris, est la résidence officielle du président de la République française depuis 1848.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le président de la République', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le Premier ministre', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le président du Sénat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le maire de Paris', FALSE, 3);

-- R32 (de f2000000-...020 / NAT / CONNAISSANCE) - Nombre départements
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien la France compte-t-elle de départements (métropole et outre-mer) ?',
 'La France compte 101 départements : 96 en métropole (avec la Corse divisée en deux) et 5 départements d''outre-mer (Guadeloupe, Martinique, Guyane, La Réunion, Mayotte).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '101', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '50', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '500', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '13', FALSE, 3);

-- R33 (de f2000000-...021 / CR / CONNAISSANCE) - État dans département
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui est le représentant de l''État dans un département français ?',
 'Le préfet représente l''État dans le département. Il est nommé par décret en Conseil des ministres et assure la mise en œuvre des politiques nationales sur le territoire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le préfet', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le maire du chef-lieu', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le président du conseil départemental', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le procureur', FALSE, 3);

-- R34 (de f2000000-...022 / CSP / CONNAISSANCE) - Qui dirige commune
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est à la tête d''une commune en France ?',
 'Une commune est dirigée par le maire, élu par les conseillers municipaux après les élections municipales. Il est aussi officier d''état civil et de police judiciaire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le maire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le préfet', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le député', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le président de la République', FALSE, 3);

-- R35 (de f2000000-...023 / CR / CONNAISSANCE) - Président pouvoirs limites
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le président de la République française dispose-t-il de pouvoirs sans limite ?',
 'Non. Le président detient des pouvoirs importants mais limites par la Constitution, la separation des pouvoirs, le contrôle du Parlement et la justice. Il n''est pas un monarque absolu.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Non, ses pouvoirs sont limités par la Constitution', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, il à tous les pouvoirs', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, sauf en période de paix', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, jusqu''au prochain référendum', FALSE, 3);

-- R36 (de f2000000-...024 / CR / CONNAISSANCE) - Qui est le préfet
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment definir la fonction de préfet ?',
 'Le préfet est un haut fonctionnaire de l''État nommé par le président en Conseil des ministres. Il représente l''État et le gouvernement dans le département, et veille à l''application des lois.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Le représentant de l''État dans un département', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Un élu de la population', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Un juge de la Cour de cassation', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Le maire le plus âge du département', FALSE, 3);
