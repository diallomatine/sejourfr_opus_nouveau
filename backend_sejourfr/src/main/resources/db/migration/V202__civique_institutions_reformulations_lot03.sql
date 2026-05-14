-- ============================================================================
-- Flyway : reformulations questions officielles - THEME 2 INSTITUTIONS
-- Lot 3/4 : R25 a R36 (separation pouvoirs, lois, departement, commune)
-- is_active = FALSE
-- ============================================================================

-- R25 (de f2000000-...019 / CR / CONNAISSANCE) - Role deputes
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle est la fonction principale des deputes a l''Assemblee nationale ?',
 'Les deputes votent les lois, examinent le budget de l''Etat et controlent l''action du gouvernement. Ils representent la nation au Parlement.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Voter les lois et controler le gouvernement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Nommer le president', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Diriger l''armee', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000019', 'Juger les criminels', FALSE, 3);

-- R26 (de f2000000-...01a / CR / CONNAISSANCE) - Trois pouvoirs
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quels sont les trois pouvoirs separes dans un Etat democratique selon Montesquieu ?',
 'La separation des pouvoirs (theorie de Montesquieu, reprise par la Republique francaise) distingue le pouvoir executif, le pouvoir legislatif et le pouvoir judiciaire, qui doivent etre independants les uns des autres.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Executif, legislatif et judiciaire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Civil, militaire et religieux', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'National, regional et local', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001a', 'Politique, economique et social', FALSE, 3);

-- R27 (de f2000000-...01b / CR / CONNAISSANCE) - Qui detient le legislatif
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui exerce le pouvoir legislatif en France ?',
 'Le pouvoir legislatif est exerce par le Parlement, compose de l''Assemblee nationale et du Senat. Il vote les lois et le budget de l''Etat.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Le Parlement (Assemblee nationale et Senat)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Le president seul', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Les juges', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001b', 'Les prefets', FALSE, 3);

-- R28 (de f2000000-...01c / CR / CONNAISSANCE) - Sanction d'un vol
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Quelle autorite prononce la sanction contre l''auteur d''un vol ?',
 'L''auteur d''un vol est juge et sanctionne par un tribunal, qui releve de l''autorite judiciaire. La peine depend de la gravite des faits.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Un tribunal (autorite judiciaire)', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le maire de la commune', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le president directement', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001c', 'Le voisin de la victime', FALSE, 3);

-- R29 (de f2000000-...01d / CSP / CONNAISSANCE) - Qui elit deputes
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Comment les deputes francais sont-ils choisis ?',
 'Les deputes sont elus directement par les citoyens francais, au suffrage universel direct, dans le cadre de leur circonscription.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les citoyens francais au suffrage direct', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par le president de la Republique', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les senateurs', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001d', 'Par les maires', FALSE, 3);

-- R30 (de f2000000-...01e / CSP / CONNAISSANCE) - Qui vote les lois
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quelle institution a la responsabilite de voter les lois en France ?',
 'Les lois sont votees par le Parlement (Assemblee nationale et Senat). C''est le pouvoir legislatif.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le Parlement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le president', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Le Conseil d''Etat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001e', 'Les juges', FALSE, 3);

-- R31 (de f2000000-...01f / CSP / CONNAISSANCE) - Palais Elysee
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Quel responsable politique habite et travaille au palais de l''Elysee ?',
 'Le palais de l''Elysee, situe a Paris, est la residence officielle du president de la Republique francaise depuis 1848.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le president de la Republique', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le Premier ministre', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le president du Senat', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-00000000001f', 'Le maire de Paris', FALSE, 3);

-- R32 (de f2000000-...020 / NAT / CONNAISSANCE) - Nombre departements
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
 'Combien la France compte-t-elle de departements (metropole et outre-mer) ?',
 'La France compte 101 departements : 96 en metropole (avec la Corse divisee en deux) et 5 departements d''outre-mer (Guadeloupe, Martinique, Guyane, La Reunion, Mayotte).', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '101', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '50', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '500', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000020', '13', FALSE, 3);

-- R33 (de f2000000-...021 / CR / CONNAISSANCE) - Etat dans departement
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Qui est le representant de l''Etat dans un departement francais ?',
 'Le prefet represente l''Etat dans le departement. Il est nomme par decret en Conseil des ministres et assure la mise en oeuvre des politiques nationales sur le territoire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le prefet', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le maire du chef-lieu', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le president du conseil departemental', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000021', 'Le procureur', FALSE, 3);

-- R34 (de f2000000-...022 / CSP / CONNAISSANCE) - Qui dirige commune
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
 'Qui est a la tete d''une commune en France ?',
 'Une commune est dirigee par le maire, elu par les conseillers municipaux apres les elections municipales. Il est aussi officier d''etat civil et de police judiciaire.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le maire', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le prefet', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le depute', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000022', 'Le president de la Republique', FALSE, 3);

-- R35 (de f2000000-...023 / CR / CONNAISSANCE) - President pouvoirs limites
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Le president de la Republique francaise dispose-t-il de pouvoirs sans limite ?',
 'Non. Le president detient des pouvoirs importants mais limites par la Constitution, la separation des pouvoirs, le controle du Parlement et la justice. Il n''est pas un monarque absolu.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Non, ses pouvoirs sont limites par la Constitution', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, il a tous les pouvoirs', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, sauf en periode de paix', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000023', 'Oui, jusqu''au prochain referendum', FALSE, 3);

-- R36 (de f2000000-...024 / CR / CONNAISSANCE) - Qui est le prefet
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f2000001-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
 'Comment definir la fonction de prefet ?',
 'Le prefet est un haut fonctionnaire de l''Etat nomme par le president en Conseil des ministres. Il represente l''Etat et le gouvernement dans le departement, et veille a l''application des lois.', FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Le representant de l''Etat dans un departement', TRUE, 0),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Un elu de la population', FALSE, 1),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Un juge de la Cour de cassation', FALSE, 2),
(gen_random_uuid(), 'f2000001-0000-0000-0000-000000000024', 'Le maire le plus age du departement', FALSE, 3);
