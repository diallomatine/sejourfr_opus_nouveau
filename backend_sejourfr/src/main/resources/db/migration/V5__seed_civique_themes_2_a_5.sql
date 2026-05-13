-- ============================================================================
-- Questions officielles - Thematiques 2 a 5 du module civique
-- Source : site du ministere de l'Interieur (livret du citoyen)
-- ============================================================================
-- Themes :
--   2 - 11111111-0000-0000-0000-000000000002 (CIV_INSTITUTIONS)
--   3 - 11111111-0000-0000-0000-000000000003 (CIV_DROITS_DEVOIRS)
--   4 - 11111111-0000-0000-0000-000000000004 (CIV_HISTOIRE_GEO)
--   5 - 11111111-0000-0000-0000-000000000005 (CIV_SOCIETE)
-- ============================================================================

-- ============================================================================
-- THEME 2 : Systeme institutionnel et politique (46 questions)
-- ============================================================================

-- Q1 - Qui nomme le Premier ministre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui nomme le Premier ministre ?',
        'Le Premier ministre est nomme par le president de la Republique (article 8 de la Constitution). Il dirige l''action du gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Le president de la Republique', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'L''Assemblee nationale', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Le Conseil constitutionnel', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Les citoyens au suffrage direct', FALSE,
        3);

-- Q2 - Le Parlement est compose :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Le Parlement est compose :',
        'Le Parlement francais est bicameral : il comprend l''Assemblee nationale (deputes) et le Senat (senateurs).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'De l''Assemblee nationale et du Senat',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Du president et des ministres', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Du Conseil constitutionnel uniquement',
        FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Des maires et des prefets', FALSE, 3);

-- Q3 - Qu'est-ce que le pouvoir executif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que le pouvoir executif ? Le pouvoir :',
        'Le pouvoir executif est charge d''appliquer les lois et de diriger la politique de la nation. En France, il est exerce par le president et le gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003',
        'D''appliquer les lois et de diriger l''Etat', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De juger les citoyens', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De modifier la Constitution', FALSE, 3);

-- Q4 - Les dirigeants sont elus par les citoyens dans :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Les dirigeants sont elus par les citoyens dans :',
        'Dans une democratie, les dirigeants sont elus par les citoyens lors d''elections libres. La France est une democratie representative.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une democratie', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une dictature', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une monarchie absolue', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une theocratie', FALSE, 3);

-- Q5 - A-t-on le droit de ne pas respecter une loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
        'A-t-on le droit de ne pas respecter une loi ?',
        'Non. Tout citoyen doit respecter la loi. Ne pas la respecter expose a des sanctions penales ou civiles, prononcees par les tribunaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Non, tout le monde doit respecter la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005',
        'Oui, si on n''est pas d''accord avec elle', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Oui, dans son foyer prive', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Oui, si on est mineur', FALSE, 3);

-- Q6 - Qui doit respecter la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui doit respecter la loi ?',
        'Toute personne presente sur le territoire francais doit respecter la loi : citoyens francais, etrangers, residents, touristes, dirigeants politiques.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006',
        'Toute personne presente sur le territoire francais', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les citoyens francais', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les majeurs', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les personnes salariees',
        FALSE, 3);

-- Q7 - Quel est le role de l'autorite judiciaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le role de l''autorite judiciaire ?',
        'L''autorite judiciaire fait respecter la loi, tranche les conflits entre personnes et sanctionne les infractions. Elle est independante du pouvoir politique.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007',
        'Faire respecter la loi et juger les litiges', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Nommer le president', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Diriger l''armee', FALSE, 3);

-- Q8 - Quel pouvoir detient un juge ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel pouvoir detient un juge ? Le pouvoir :',
        'Le juge exerce le pouvoir judiciaire : il dit le droit, tranche les litiges et sanctionne les infractions, en toute independance.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Judiciaire', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Legislatif', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Executif', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Constituant', FALSE, 3);

-- Q9 - L'autorite judiciaire est exercee par :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'L''autorite judiciaire est exercee par :',
        'L''autorite judiciaire est exercee par les juges et magistrats, dans les tribunaux. Ils sont independants des pouvoirs executif et legislatif.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les juges et les magistrats', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les deputes et senateurs', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Le president seul', FALSE, 3);

-- Q10 - Que se passe-t-il si un ministre ne respecte pas la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Que se passe-t-il si un ministre ne respecte pas la loi ?',
        'Un ministre, comme tout citoyen, est soumis a la loi. Il peut etre juge par la Cour de justice de la Republique pour les actes commis dans ses fonctions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il peut etre juge comme tout citoyen',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Rien, il a l''immunite totale', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il perd seulement son poste', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il decide lui-meme de sa sanction', FALSE,
        3);

-- Q11 - Qui est elu lors des elections legislatives ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est elu lors des elections legislatives ?',
        'Les elections legislatives elisent les deputes de l''Assemblee nationale, au suffrage universel direct.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les deputes', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Le president', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les maires', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les senateurs', FALSE, 3);

-- Q12 - Combien de deputes composent l'Assemblee nationale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien de deputes composent l''Assemblee nationale ?',
        'L''Assemblee nationale compte 577 deputes, elus pour 5 ans au suffrage universel direct, chacun dans une circonscription.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '577 deputes', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '348 deputes', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '500 deputes', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '1000 deputes', FALSE, 3);

-- Q13 - Quand sont elus les senateurs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quand sont elus les senateurs ?',
        'Les senateurs sont elus pour 6 ans au suffrage indirect, par environ 162 000 "grands electeurs" (deputes, conseillers regionaux, departementaux, municipaux). Le Senat est renouvele par moitie tous les 3 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 3 ans, par moitie', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 5 ans en meme temps', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 10 ans', FALSE, 3);

-- Q14 - Qui est elu lors des elections municipales ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est elu lors des elections municipales ?',
        'Les elections municipales elisent les conseillers municipaux. Ces conseillers elisent ensuite le maire de la commune.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e',
        'Les conseillers municipaux (qui elisent le maire)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Le president de la Republique', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Les deputes', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Les prefets', FALSE, 3);

-- Q15 - Qui est elu lors des elections presidentielles ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est elu lors des elections presidentielles ?',
        'L''election presidentielle elit le president de la Republique, au suffrage universel direct, pour un mandat de 5 ans, depuis 1962.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Le president de la Republique', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Le Premier ministre', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Les senateurs', FALSE, 3);

-- Q16 - A partir de quel age a-t-on le droit de voter ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'A partir de quel age a-t-on le droit de voter ?',
        'En France, le droit de vote est accorde a partir de 18 ans, age de la majorite civile fixe depuis 1974.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '18 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '16 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '21 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '25 ans', FALSE, 3);

-- Q17 - Pour combien de temps est elu le president ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps est elu le president de la Republique francaise ?',
        'Le president de la Republique est elu pour 5 ans (quinquennat) depuis la reforme constitutionnelle de 2000.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '5 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '4 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '6 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '7 ans', FALSE, 3);

-- Q18 - Pour combien de temps sont elus les deputes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps sont elus les deputes ?',
        'Les deputes sont elus pour 5 ans au suffrage universel direct, par circonscription.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '5 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '4 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '6 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '7 ans', FALSE, 3);

-- Q19 - Pour combien de temps sont elus les senateurs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps sont elus les senateurs ?',
        'Les senateurs sont elus pour 6 ans au suffrage universel indirect. Le Senat est renouvele par moitie tous les 3 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '6 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '5 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '3 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '9 ans', FALSE, 3);

-- Q20 - Qui possede le pouvoir executif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui possede le pouvoir executif ?',
        'Le pouvoir executif est detenu par le president de la Republique et le gouvernement (Premier ministre et ministres).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Le president et le gouvernement', TRUE,
        0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'L''Assemblee nationale et le Senat',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Les tribunaux', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Le Conseil constitutionnel', FALSE, 3);

-- Q21 - Quelle condition est necessaire pour voter aux elections ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quelle condition est necessaire pour voter aux elections ?',
        'Pour voter en France, il faut etre majeur (18 ans), de nationalite francaise (sauf elections locales et europeennes pour les ressortissants UE), jouir de ses droits civils, et etre inscrit sur les listes electorales.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015',
        'Etre majeur, citoyen et inscrit sur les listes electorales', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Avoir suivi des etudes superieures',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Etre proprietaire', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Payer un impot specifique', FALSE, 3);

-- Q22 - Qui peut voter aux elections en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui peut voter aux elections en France ?',
        'Aux elections nationales, seuls les citoyens francais majeurs et inscrits sur les listes peuvent voter. Les ressortissants UE peuvent voter aux municipales et europeennes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016',
        'Les citoyens francais majeurs inscrits sur les listes electorales', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016',
        'Tous les residents en France, francais ou non', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016', 'Uniquement les fonctionnaires', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016', 'Toute personne de plus de 16 ans', FALSE,
        3);

-- Q23 - Que signifie "suffrage universel" ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Que signifie "suffrage universel" ?',
        'Le suffrage universel signifie que tous les citoyens majeurs ont le droit de voter, sans condition de fortune, de sexe ou d''education. En France : universel masculin en 1848, etendu aux femmes en 1944.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017',
        'Tous les citoyens majeurs ont le droit de vote', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Le vote est obligatoire pour tous', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Seuls les hommes peuvent voter', FALSE,
        2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Le vote des etrangers est autorise',
        FALSE, 3);

-- Q24 - Concernant les partis politiques, quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Concernant les partis politiques, quelle proposition est correcte ?',
        'Les partis politiques se forment librement et concourent a l''expression du suffrage (article 4 de la Constitution). Le multipartisme est garanti.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018',
        'Plusieurs partis politiques peuvent exister librement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018', 'Il n''y a qu''un seul parti autorise',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018', 'Les partis politiques sont interdits',
        FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018',
        'Seuls les ministres peuvent creer un parti', FALSE, 3);

-- Q25 - Quel est le role des deputes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le role des deputes ?',
        'Les deputes votent les lois, controlent l''action du gouvernement et representent les citoyens de leur circonscription a l''Assemblee nationale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019',
        'Voter les lois et controler le gouvernement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Diriger les ministeres', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Juger les criminels', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Nommer le president', FALSE, 3);
-- Q26 - La separation des pouvoirs : quels sont les trois pouvoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'La separation des pouvoirs est un principe fondamental. Quels sont les trois pouvoirs concernes ?',
        'Selon Montesquieu, les trois pouvoirs sont : legislatif (faire les lois), executif (les appliquer), judiciaire (sanctionner leur non-respect). Ils doivent etre separes pour eviter la concentration du pouvoir.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Legislatif, executif, judiciaire', TRUE,
        0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Politique, economique, militaire', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'National, regional, local', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Civil, penal, administratif', FALSE, 3);

-- Q27 - Qui possede le pouvoir legislatif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui possede le pouvoir legislatif ?',
        'Le pouvoir legislatif est detenu par le Parlement, compose de l''Assemblee nationale et du Senat. Il vote les lois et le budget de l''Etat.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b',
        'Le Parlement (Assemblee nationale + Senat)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Le president seul', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Les juges', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Les maires', FALSE, 3);

-- Q28 - Qui sanctionne l'auteur d'un vol ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui sanctionne l''auteur d''un vol ?',
        'Le vol est une infraction penale. C''est un tribunal, dans le cadre du pouvoir judiciaire, qui juge et sanctionne l''auteur du vol.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Un tribunal (juge)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Le maire', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'La victime elle-meme', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Le Premier ministre', FALSE, 3);

-- Q29 - Qui elit les deputes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui elit les deputes ?',
        'Les deputes sont elus par les citoyens francais majeurs au suffrage universel direct, par circonscription.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d',
        'Les citoyens majeurs au suffrage universel direct', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Les senateurs', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Le president de la Republique', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Les maires', FALSE, 3);

-- Q30 - Qui vote les lois ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui vote les lois ?',
        'Les lois sont votees par le Parlement (Assemblee nationale + Senat). C''est le pouvoir legislatif.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le Parlement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le president seul', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le Conseil constitutionnel', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Les juges', FALSE, 3);

-- Q31 - Qui reside au palais de l'Elysee ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui reside au palais de l''Elysee ?',
        'Le palais de l''Elysee, a Paris, est la residence officielle du president de la Republique depuis 1873.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le president de la Republique', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le Premier ministre', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le president du Senat', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le maire de Paris', FALSE, 3);

-- Q32 - Combien y a-t-il de departements en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien y a-t-il de departements en France ?',
        'La France compte 101 departements : 96 en metropole et 5 outre-mer (Guadeloupe, Martinique, Guyane, La Reunion, Mayotte).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020',
        '101 departements (96 en metropole, 5 outre-mer)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '50', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '83', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '120', FALSE, 3);

-- Q33 - Qui represente l'Etat dans un departement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui represente l''Etat dans un departement ?',
        'Le prefet est le representant de l''Etat dans un departement. Il est nomme par le president sur proposition du Premier ministre.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le prefet', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le maire', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le depute', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le procureur', FALSE, 3);

-- Q34 - Qui dirige la commune ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui dirige la commune ?',
        'Le maire dirige la commune. Il est elu par le conseil municipal pour 6 ans. Il est officier d''etat civil et de police judiciaire.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le maire', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le prefet', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le depute', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le ministre de l''Interieur', FALSE, 3);

-- Q35 - Est-ce que le president a tous les pouvoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Est-ce que le president de la Republique a tous les pouvoirs ?',
        'Non. Les pouvoirs sont separes : le president partage le pouvoir executif avec le gouvernement, le Parlement vote les lois, et la justice est independante.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Non, les pouvoirs sont separes', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Oui, il decide de tout', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023',
        'Oui, il peut modifier seul la Constitution', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Oui, sauf en cas de guerre', FALSE, 3);

-- Q36 - Qui est le prefet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui est le prefet ?',
        'Le prefet est le representant de l''Etat dans le departement (ou la region). Il met en oeuvre la politique du gouvernement au niveau local.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024',
        'Le representant de l''Etat dans le departement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Un elu municipal', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Le chef de la police nationale', FALSE,
        2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Un juge specialise', FALSE, 3);

-- Q37 - Quel est le role du Parlement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le role du Parlement ?',
        'Le Parlement vote les lois, autorise le budget de l''Etat et controle l''action du gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025',
        'Voter les lois et controler le gouvernement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Diriger les ministeres', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Rendre la justice', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Nommer les prefets', FALSE, 3);

-- Q38 - Quel est le regime politique de la France aujourd'hui ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000026', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le regime politique de la France aujourd''hui ?',
        'La France est sous le regime de la Ve Republique depuis 1958. C''est une republique semi-presidentielle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La Ve Republique', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La IVe Republique', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'L''Empire', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La monarchie constitutionnelle', FALSE,
        3);

-- ---------- UNION EUROPEENNE ----------

-- Q39 - Combien d'Etats font partie de l'UE au 1er janvier 2025 ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000027', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien d''Etats font partie de l''Union europeenne au 1er janvier 2025 ?',
        'L''Union europeenne compte 27 Etats membres depuis le retrait du Royaume-Uni (Brexit) en 2020.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '27 Etats', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '15 Etats', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '28 Etats', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '50 Etats', FALSE, 3);

-- Q40 - Quel Etat n'est pas membre de l'UE ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000028', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel Etat n''est pas membre de l''Union europeenne ?',
        'La Suisse n''est pas membre de l''Union europeenne. Elle a refuse plusieurs fois par referendum. Le Royaume-Uni est sorti de l''UE en 2020 (Brexit).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'La Suisse', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Italie', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Allemagne', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Espagne', FALSE, 3);

-- Q41 - Quelle condition pour voter aux elections europeennes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000029', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quelle condition est necessaire pour voter aux elections europeennes ?',
        'Pour voter aux elections europeennes, il faut etre majeur, ressortissant d''un Etat membre de l''UE et inscrit sur les listes electorales en France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029',
        'Etre majeur et citoyen d''un Etat membre de l''UE', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029',
        'Etre obligatoirement de nationalite francaise', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029', 'Resider en Belgique', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029', 'Parler trois langues europeennes', FALSE,
        3);

-- Q42 - A quelle frequence les elections europeennes sont-elles organisees ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'A quelle frequence les elections europeennes sont-elles organisees ?',
        'Les elections europeennes ont lieu tous les 5 ans, simultanement dans tous les Etats membres de l''UE.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002a', 'Tous les 5 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002a', 'Tous les ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002a', 'Tous les 3 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002a', 'Tous les 10 ans', FALSE, 3);

-- Q43 - Quel pays est un pays fondateur de l'UE ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel pays est un pays fondateur de l''Union europeenne ?',
        'Les 6 pays fondateurs (CEE 1957) sont : France, Allemagne, Italie, Belgique, Pays-Bas et Luxembourg.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La France', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'L''Espagne', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La Pologne', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La Grece', FALSE, 3);

-- Q44 - Quelle est la monnaie utilisee en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Quelle est la monnaie utilisee en France ?',
        'L''euro est la monnaie de la France depuis le 1er janvier 2002, partagee avec 19 autres pays de la zone euro.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'L''euro', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'Le franc', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'La livre sterling', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'Le dollar', FALSE, 3);

-- Q45 - Qui elit les deputes europeens ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui elit les deputes europeens ?',
        'Les deputes du Parlement europeen sont elus au suffrage universel direct par les citoyens des Etats membres, tous les 5 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les citoyens des Etats membres de l''UE',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les chefs d''Etat', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'La Cour de justice europeenne', FALSE, 3);

-- Q46 - Quand celebre-t-on la journee de l'Europe ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quand celebre-t-on la journee de l''Europe ?',
        'La journee de l''Europe est celebree le 9 mai, en commemoration de la declaration de Robert Schuman du 9 mai 1950, acte fondateur de la construction europeenne.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 9 mai', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 14 juillet', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 1er janvier', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 11 novembre', FALSE, 3);
-- ============================================================================
-- THEME 3 : Droits et devoirs (30 questions)
-- ============================================================================

-- Q1 - Comment s'appelle la Constitution actuelle de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Comment s''appelle la Constitution actuelle de la France ?',
        'La Constitution actuelle est celle de la Ve Republique, adoptee le 4 octobre 1958.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de la Ve Republique',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de 1789', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution europeenne', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de l''Empire', FALSE, 3);

-- Q2 - Texte qui enonce les droits et devoirs des personnes residant en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Comment s''appelle le texte qui enonce les droits et devoirs des personnes residant en France ?',
        'La Charte des droits et devoirs du citoyen francais, etablie en 2012, rappelle les principes fondamentaux et les valeurs essentielles de la Republique.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002',
        'La Charte des droits et devoirs du citoyen francais', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'Le Code civil', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'La Bible', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'Le Code du travail', FALSE, 3);

-- Q3 - Concernant les droits individuels, quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Concernant les droits individuels, quelle proposition est correcte ?',
        'Les droits individuels (liberte, surete, propriete, libre expression, etc.) sont garantis a toute personne sur le territoire francais, sans discrimination.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003',
        'Ils sont garantis a toute personne, sans discrimination', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003', 'Ils sont reserves aux citoyens francais',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003',
        'Ils s''achetent par un titre de propriete', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003', 'Ils dependent de la religion', FALSE, 3);

-- Q4 - De quelle annee date la Declaration des droits de l'homme ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'De quelle annee date la Declaration des droits de l''homme et du citoyen ?',
        'La Declaration des droits de l''homme et du citoyen a ete adoptee le 26 aout 1789, pendant la Revolution francaise. Elle a valeur constitutionnelle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000004', '1789', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000004', '1848', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000004', '1905', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000004', '1958', FALSE, 3);

-- Q5 - Lequel de ces droits est un droit fondamental ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Lequel de ces droits est un droit fondamental ?',
        'Le droit a la liberte, le droit a la surete, le droit a la propriete sont des droits fondamentaux inscrits dans la Declaration de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'La liberte', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit a la voiture', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit aux vacances', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit a un smartphone', FALSE, 3);

-- Q6 - Parmi ces textes, lequel garantit les droits et libertes en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Parmi ces textes, lequel garantit les droits et libertes en France ?',
        'La Declaration des droits de l''homme et du citoyen de 1789, integree au "bloc de constitutionnalite", garantit les droits et libertes fondamentales.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006',
        'La Declaration des droits de l''homme et du citoyen', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le Code de la route', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le manuel scolaire', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le journal officiel', FALSE, 3);

-- Q7 - Qu'est-ce que la liberte d'expression ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la liberte d''expression ?',
        'La liberte d''expression est le droit de dire, ecrire ou publier ses opinions, dans le respect des lois (pas d''injures, de diffamation, d''incitation a la haine).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007',
        'Le droit d''exprimer ses opinions dans le respect de la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'Le droit de dire tout sans limite', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'L''interdiction de parler en public',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'Une liberte reservee aux journalistes',
        FALSE, 3);

-- Q8 - Quel droit permet a une personne de se defendre devant la justice ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel droit permet a une personne de se defendre devant la justice ?',
        'Le droit a la defense (et le droit a un avocat) est un principe fondamental. Toute personne accusee a le droit d''etre defendue, presumee innocente jusqu''a preuve du contraire.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit a la defense (et a un avocat)',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit de vote', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit de propriete', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit a la sante', FALSE, 3);

-- Q9 - Quel est le texte fondateur etablissant les droits et devoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Quel est le texte fondateur etablissant en France les droits et les devoirs de chaque citoyen ?',
        'La Declaration des droits de l''homme et du citoyen de 1789 est le texte fondateur des droits et libertes en France. Elle reste integree a la Constitution actuelle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009',
        'La Declaration des droits de l''homme et du citoyen (1789)', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'Le Code de la sante publique', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'Le Traite de Rome', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'La Charte des Nations unies', FALSE, 3);

-- Q10 - Quel texte a ete adopte pendant la Revolution francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel texte a ete adopte pendant la Revolution francaise ?',
        'La Declaration des droits de l''homme et du citoyen a ete adoptee le 26 aout 1789 par l''Assemblee nationale constituante, pendant la Revolution.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a',
        'La Declaration des droits de l''homme et du citoyen', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'Le Traite de Rome', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'La Constitution de la Ve Republique',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'La loi de 1905', FALSE, 3);

-- Q11 - Quelle liberte permet de ne pas avoir de religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quelle liberte permet a une personne de ne pas avoir de religion ?',
        'La liberte de conscience, garantie par la laicite, permet de croire, de ne pas croire ou de changer de religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberte de conscience', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberte du commerce', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberte de la presse', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberte de circulation', FALSE, 3);

-- Q12 - Une femme peut avorter :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Une femme peut avorter :',
        'Le droit a l''interruption volontaire de grossesse (IVG) est garanti depuis la loi Veil de 1975. Il est inscrit dans la Constitution depuis 2024.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000c', 'C''est un droit garanti par la loi', TRUE,
        0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000c', 'C''est totalement interdit', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000c', 'Uniquement avec l''accord de son mari',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000c', 'Uniquement avec autorisation religieuse',
        FALSE, 3);

-- Q13 - Est-il toujours possible de divorcer ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Est-il toujours possible de divorcer ?',
        'Oui, le divorce est legal en France depuis 1792. Toute personne mariee peut demander le divorce, selon des procedures definies par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Oui, c''est un droit garanti par la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Non, le divorce est interdit', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d',
        'Seulement avec l''accord des deux familles', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Uniquement apres 10 ans de mariage',
        FALSE, 3);

-- Q14 - La peine de mort est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'La peine de mort est :',
        'La peine de mort a ete abolie en France le 9 octobre 1981 par la loi Badinter. Son abolition est inscrite dans la Constitution depuis 2007.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'Abolie en France depuis 1981', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'En vigueur pour les crimes graves', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e',
        'Appliquee uniquement dans certaines regions', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'Prevue par la Constitution actuelle',
        FALSE, 3);

-- Q15 - Limites aux libertes individuelles : quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Concernant les limites aux libertes individuelles, quelle proposition est correcte ?',
        'Les libertes individuelles ne sont jamais absolues : elles s''arretent la ou commencent celles des autres, et sont encadrees par la loi pour proteger l''ordre public et autrui.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Les libertes ont des limites fixees par la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f', 'Les libertes sont absolues, sans limite',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Les libertes ne s''appliquent qu''au domicile prive', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Il n''existe pas de libertes individuelles en France', FALSE, 3);

-- Q16 - En France, est-il legal d'etre marie a plusieurs personnes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'En France, est-ce legal d''etre marie a plusieurs personnes en meme temps ?',
        'Non. La polygamie est interdite en France. Le mariage est l''union de deux personnes seulement. La bigamie est un delit penal.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Non, la polygamie est interdite', TRUE,
        0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, c''est autorise sans restriction',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, avec autorisation de la mairie',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, selon les traditions familiales',
        FALSE, 3);

-- Q17 - Faut-il reduire ses dechets ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Faut-il reduire ses dechets ?',
        'Oui, la reduction des dechets est un devoir citoyen pour proteger l''environnement, prevu par le Code de l''environnement. Le tri et le recyclage sont obligatoires.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Oui, pour proteger l''environnement',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Non, ce n''est pas important', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Uniquement les commerces', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'C''est interdit par la loi', FALSE, 3);

-- Q18 - Jeter une bouteille dans la rue est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Jeter une bouteille dans la rue est :',
        'Jeter ses dechets dans la rue est une infraction (depot sauvage). C''est puni par une amende pouvant aller jusqu''a 1500 euros.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Une infraction punie par la loi', TRUE,
        0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Autorise dans les grandes villes', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012',
        'Sans consequence si la bouteille est en verre', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Recommande la nuit', FALSE, 3);

-- Q19 - Pourquoi les libertes individuelles peuvent-elles etre limitees ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Pourquoi les libertes individuelles peuvent-elles etre limitees ?',
        'Les libertes peuvent etre limitees pour proteger l''ordre public, la securite, la sante ou les libertes d''autrui. Ces limites doivent etre proportionnees et fixees par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013',
        'Pour proteger les droits des autres et l''ordre public', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Selon le bon vouloir du president', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Pour favoriser une religion', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Pour limiter le travail des etrangers',
        FALSE, 3);

-- Q20 - Que doit faire une personne en cas d'accident ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Que doit faire une personne en cas d''accident ?',
        'L''assistance a personne en danger est une obligation legale. Il faut prevenir les secours (15 SAMU, 17 Police, 18 Pompiers, 112 numero europeen) et aider sans se mettre en danger.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014',
        'Porter assistance et prevenir les secours', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014', 'Partir rapidement', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014', 'Filmer la scene', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014',
        'Attendre que quelqu''un d''autre intervienne', FALSE, 3);

-- Q21 - Que permet la citoyennete francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Que permet la citoyennete francaise ?',
        'La citoyennete francaise donne des droits (voter, etre elu, exercer certaines fonctions) et des devoirs (respecter la loi, payer ses impots, defense, jury d''assises).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015',
        'D''avoir des droits politiques (voter, etre elu) et des devoirs', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'D''etre dispense d''impots', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'D''etre au-dessus des lois', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'De voyager partout sans visa', FALSE, 3);

-- Q22 - Que risque une personne qui ne respecte pas la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
        'Que risque une personne qui ne respecte pas la loi ?',
        'Selon la gravite, les sanctions vont de l''amende a la prison. Toute infraction est jugee par un tribunal et peut entrainer des consequences penales et civiles.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016',
        'Une sanction (amende, prison) prononcee par un tribunal', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'Rien, la loi est seulement indicative',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'Une simple remontrance verbale', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'L''expulsion automatique du territoire',
        FALSE, 3);

-- Q23 - Quel est le role de la gendarmerie ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel est le role de la gendarmerie ?',
        'La gendarmerie assure la securite publique, principalement en zone rurale et periurbaine. Elle exerce des missions de police judiciaire et administrative, sous tutelle du ministere de l''Interieur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017',
        'Assurer la securite, principalement en zone rurale', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Eduquer les enfants', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Faire la guerre a l''etranger', FALSE, 3);

-- Q24 - Quel est le role de la police ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
        'Quel est le role de la police ?',
        'La police nationale assure la securite des personnes et des biens, principalement en zone urbaine. Elle previent et constate les infractions, fait respecter l''ordre public.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018',
        'Assurer la securite et faire respecter la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Juger les criminels', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Voter les lois', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Eduquer les enfants', FALSE, 3);

-- Q25 - Qu'est-ce qu'une infraction ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Qu''est-ce qu''une infraction ?',
        'Une infraction est un comportement interdit par la loi et puni. Il en existe trois categories : contraventions (les moins graves), delits, crimes (les plus graves).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019',
        'Une violation de la loi punie par celle-ci', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un type d''impot', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un texte de loi', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un titre administratif', FALSE, 3);

-- Q26 - Comment peut-on reduire ses dechets ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Comment peut-on reduire ses dechets ?',
        'On peut reduire ses dechets en triant, recyclant, compostant les dechets organiques, achetant en vrac, evitant le suremballage et reparant plutot que jetant.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a',
        'En triant, recyclant et evitant le gaspillage', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En jetant tout dans la nature', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En achetant toujours plus emballe', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En brulant ses dechets soi-meme', FALSE,
        3);

-- Q27 - Deposer une machine a laver cassee sur le trottoir est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Deposer une machine a laver cassee sur le trottoir est :',
        'Deposer un encombrant sur le trottoir sans demande prealable est interdit. Il faut prendre rendez-vous avec le service "encombrants" de la mairie ou se rendre en dechetterie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b',
        'Interdit : il faut prendre rendez-vous pour les encombrants ou aller en dechetterie', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Autorise tous les jours', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Autorise dans les grandes villes', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Une bonne action ecologique', FALSE, 3);

-- Q28 - En quoi consiste la traite des etres humains ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'En quoi consiste la traite des etres humains ?',
        'La traite des etres humains consiste a exploiter une personne (travail force, prostitution, esclavage...) par la contrainte. C''est un crime grave puni par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c',
        'Exploiter une personne par la force (travail force, prostitution...)', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'Un type de commerce legal', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'L''immigration legale', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'L''accueil des refugies', FALSE, 3);

-- Q29 - Que doit faire une victime de violences ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Que doit faire une victime de violences ?',
        'Une victime de violences peut contacter les secours (17 Police, 15 SAMU), porter plainte au commissariat ou a la gendarmerie, et appeler le 3919 (violences conjugales) ou 119 (enfance en danger).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d',
        'Appeler les secours, porter plainte ou contacter une association', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Garder le silence et se taire', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Se venger soi-meme', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Demenager sans rien dire', FALSE, 3);

-- Q30 - Quelle est l'infraction la plus grave ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quelle est l''infraction la plus grave ?',
        'Les infractions sont classees en trois categories par gravite croissante : contraventions, delits, crimes. Le crime (meurtre, viol...) est l''infraction la plus grave.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Le crime', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'La contravention', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Le delit', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Toutes les infractions sont equivalentes',
        FALSE, 3);
-- ============================================================================
-- THEME 4 : Histoire, geographie et culture (46 questions)
-- ============================================================================

-- ---------- HISTOIRE ----------

-- Q1 - En quelle annee a debute la Revolution francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'En quelle annee a debute la Revolution francaise ?',
        'La Revolution francaise debute en 1789. La prise de la Bastille a lieu le 14 juillet 1789.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1789', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1689', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1848', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1914', FALSE, 3);

-- Q2 - Qui etait Napoleon Ier ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait Napoleon Ier ?',
        'Napoleon Bonaparte (1769-1821) fut empereur des Francais de 1804 a 1814 puis en 1815. Il a reorganise l''Etat (Code civil, prefets, lycees) et conquis une grande partie de l''Europe.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002',
        'Un empereur francais (debut du XIXe siecle)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un roi du Moyen Age', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un president de la Ve Republique', FALSE,
        2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un philosophe des Lumieres', FALSE, 3);

-- Q3 - Lequel de ces personnages historiques est francais ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Lequel de ces personnages historiques est francais ?',
        'Jeanne d''Arc (1412-1431), originaire de Domremy, est une figure majeure de l''histoire de France. Elle a contribue a liberer la France pendant la guerre de Cent Ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Jeanne d''Arc', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Winston Churchill', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'George Washington', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Christophe Colomb', FALSE, 3);

-- Q4 - Dans quelle Republique est-on aujourd'hui ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Dans quelle Republique est-on aujourd''hui ?',
        'Nous sommes sous la Ve Republique, fondee en 1958 par Charles de Gaulle.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La Ve Republique', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La IIIe Republique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La IVe Republique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La VIe Republique', FALSE, 3);

-- Q5 - Qu'est-ce que la Shoah ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qu''est-ce que la Shoah ?',
        'La Shoah est le genocide des Juifs d''Europe par l''Allemagne nazie pendant la Seconde Guerre mondiale (1939-1945). Six millions de Juifs ont ete extermines.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005',
        'Le genocide des Juifs par les nazis (1939-1945)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005',
        'Une bataille de la Premiere Guerre mondiale', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005', 'Une revolution europeenne', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005', 'Une fete religieuse', FALSE, 3);

-- Q6 - Quel pays a ete colonise par la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quel pays ou region du monde a ete colonise par la France ?',
        'L''Algerie, la Tunisie, le Maroc, le Senegal, le Mali, l''Indochine et de nombreux autres pays d''Afrique et d''Asie ont ete colonises par la France entre le XVIIe et le XXe siecle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'L''Algerie', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'La Suede', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'Le Bresil', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'L''Australie', FALSE, 3);

-- Q7 - Qui a rendu l'ecole gratuite, laique et obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui a rendu l''ecole gratuite, laique et obligatoire ?',
        'Jules Ferry, ministre de l''Instruction publique, a fait voter les lois rendant l''ecole gratuite (1881), obligatoire et laique (1882).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Jules Ferry', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Charles de Gaulle', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Napoleon Bonaparte', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Francois Mitterrand', FALSE, 3);

-- Q8 - Quand a eu lieu la Seconde Guerre mondiale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand a eu lieu la Seconde Guerre mondiale ?',
        'La Seconde Guerre mondiale s''est deroulee de 1939 a 1945. Elle a oppose les Allies (dont la France libre) a l''Axe (Allemagne nazie, Italie, Japon).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1939-1945', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1914-1918', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1945-1950', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1789-1799', FALSE, 3);

-- Q9 - Quand a eu lieu la Premiere Guerre mondiale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand a eu lieu la Premiere Guerre mondiale ?',
        'La Premiere Guerre mondiale s''est deroulee de 1914 a 1918. Elle s''est terminee par l''armistice signe le 11 novembre 1918.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1914-1918', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1939-1945', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1870-1871', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1789-1799', FALSE, 3);

-- Q10 - En quelle annee a ete creee la CEE ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'En quelle annee a ete creee la Communaute Economique Europeenne (CEE) ?',
        'La CEE a ete creee en 1957 par le traite de Rome, signe par 6 pays fondateurs : France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg. Elle est devenue l''Union europeenne en 1993.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1957', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1945', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1989', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '2002', FALSE, 3);

-- Q11 - Le 11 novembre est un jour ferie. A quoi correspond cette date ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Le 11 novembre est un jour ferie. A quoi correspond cette date ?',
        'Le 11 novembre commemore l''armistice de 1918, qui a mis fin a la Premiere Guerre mondiale, et rend hommage aux soldats morts pour la France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b',
        'L''armistice de 1918 (fin de la Premiere Guerre mondiale)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fin de la Seconde Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fete nationale', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fete de la Republique', FALSE, 3);

-- Q12 - Premier president elu sous la Ve Republique ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui a ete le premier President elu sous la Ve Republique ?',
        'Charles de Gaulle a ete le premier president de la Ve Republique, elu en 1958 (par les grands electeurs) puis reelu en 1965 au suffrage universel direct.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Charles de Gaulle', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Francois Mitterrand', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Georges Pompidou', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Jacques Chirac', FALSE, 3);

-- Q13 - Quand l'esclavage a-t-il ete aboli definitivement en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'En quelle annee l''esclavage a-t-il ete aboli definitivement en France ?',
        'L''esclavage a ete aboli definitivement en France le 27 avril 1848, sous l''impulsion de Victor Schoelcher. Il avait deja ete aboli une premiere fois en 1794, puis retabli par Napoleon en 1802.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1848', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1789', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1905', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1945', FALSE, 3);

-- Q14 - Depuis quelle annee l'ecole publique est-elle gratuite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Depuis quelle annee l''ecole publique est-elle gratuite ?',
        'L''ecole publique est gratuite depuis 1881, grace a la loi Jules Ferry. L''instruction est devenue obligatoire et laique en 1882.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1881', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1789', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1905', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1968', FALSE, 3);

-- Q15 - Combien y a-t-il eu de republiques en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Combien y a-t-il eu de republiques en France ?',
        'La France a connu cinq republiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946), Ve (1958, actuelle).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '5 republiques', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '3 republiques', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '1 seule republique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '10 republiques', FALSE, 3);

-- Q16 - Roi de France au moment de la Revolution ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait le roi de France au moment de la Revolution francaise ?',
        'Louis XVI etait roi de France au debut de la Revolution. Il a ete guillotine le 21 janvier 1793, marquant la fin de la monarchie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Louis XVI', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Louis XIV (le Roi-Soleil)', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Napoleon Ier', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Henri IV', FALSE, 3);

-- Q17 - Qui a fonde la Ve Republique ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui a fonde la Ve Republique ?',
        'Charles de Gaulle a fonde la Ve Republique en 1958, en redigeant une nouvelle Constitution adoptee par referendum.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Charles de Gaulle', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Napoleon III', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Jules Ferry', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Francois Mitterrand', FALSE, 3);

-- Q18 - Que celebre-t-on le 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Que celebre-t-on le 14 juillet ?',
        'Le 14 juillet, fete nationale, commemore la prise de la Bastille (14 juillet 1789), symbole de la Revolution francaise.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012',
        'La fete nationale (prise de la Bastille 1789)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'La fin de la Seconde Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'La fete des Meres', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'L''anniversaire du president', FALSE, 3);

-- Q19 - Quelle guerre a eu lieu entre 1914 et 1918 ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle guerre a eu lieu entre 1914 et 1918 ?',
        'La Premiere Guerre mondiale (Grande Guerre) s''est deroulee de 1914 a 1918. Elle a oppose principalement la France, le Royaume-Uni et la Russie a l''Allemagne et l''Autriche-Hongrie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La Premiere Guerre mondiale', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La Seconde Guerre mondiale', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La guerre d''Algerie', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La guerre de Cent Ans', FALSE, 3);

-- Q20 - Pourquoi l'annee 1958 est importante ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Pourquoi l''annee 1958 est importante pour la France ?',
        'En 1958, la Ve Republique est fondee avec l''adoption de la nouvelle Constitution (4 octobre 1958), et Charles de Gaulle revient au pouvoir.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Fondation de la Ve Republique', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Debut de la Premiere Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Independance de la France', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Abolition de l''esclavage', FALSE, 3);
-- ---------- GEOGRAPHIE ----------

-- Q21 - Quel fleuve coule en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quel fleuve coule en France ?',
        'La Seine, la Loire, le Rhone et la Garonne sont les principaux fleuves francais. La Seine traverse Paris.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'La Seine', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'L''Amazone', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'Le Nil', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'Le Mississippi', FALSE, 3);

-- Q22 - Quelle ville est francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle ville est francaise ?',
        'Lyon, Marseille, Paris, Bordeaux, Toulouse, Lille, Strasbourg, Nantes... sont les grandes villes francaises.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Lyon', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Madrid', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Berlin', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Rome', FALSE, 3);

-- Q23 - Quel ocean borde la cote ouest francaise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quel ocean borde la cote ouest francaise ?',
        'L''ocean Atlantique borde la cote ouest de la France. La cote sud est bordee par la mer Mediterranee.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''ocean Atlantique', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''ocean Pacifique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''ocean Indien', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''ocean Arctique', FALSE, 3);

-- Q24 - Qu'est-ce que Paris ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce que Paris ?',
        'Paris est la capitale de la France. C''est le siege du gouvernement, du Parlement et la plus grande ville du pays.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'La capitale de la France', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Un departement d''outre-mer', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Un fleuve', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Une chaine de montagnes', FALSE, 3);

-- Q25 - Capitale de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle est la capitale de la France ?',
        'Paris est la capitale de la France depuis le Moyen Age. C''est la plus grande ville de France avec plus de 2 millions d''habitants.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Lyon', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Marseille', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Bordeaux', FALSE, 3);

-- Q26 - Continent ou se situe la France metropolitaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Sur quel continent se situe la France metropolitaine ?',
        'La France metropolitaine est situee sur le continent europeen, dans l''ouest de l''Europe.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Europe', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Afrique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Asie', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Amerique', FALSE, 3);

-- Q27 - Quelle ile est un departement d'outre-mer ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle ile est un departement d''outre-mer francais ?',
        'La Guadeloupe, la Martinique, La Reunion et Mayotte sont les iles departements d''outre-mer. La Guyane est aussi un DOM mais sur le continent sud-americain.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'La Reunion', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'Madagascar', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'L''Islande', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'Cuba', FALSE, 3);

-- Q28 - Combien y a-t-il de regions en France metropolitaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Combien y a-t-il de regions en France metropolitaine ?',
        'La France metropolitaine compte 13 regions depuis la reforme territoriale de 2016. Avec les 5 regions d''outre-mer, la France compte 18 regions au total.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '13 regions', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '22 regions', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '101 regions', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '6 regions', FALSE, 3);

-- Q29 - Quelle ville est un grand port maritime ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle ville est un grand port maritime ?',
        'Marseille est le premier port maritime de France et un des plus grands de Mediterranee. Le Havre, Dunkerque et Bordeaux sont aussi des grands ports.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001d', 'Marseille', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001d', 'Lyon', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001d', 'Strasbourg', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001d', 'Toulouse', FALSE, 3);

-- Q30 - Quelle est la mer au sud de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle est la mer au sud de la France metropolitaine ?',
        'La mer Mediterranee borde le sud de la France, de la frontiere espagnole a la frontiere italienne, en passant par Marseille, Nice et la Cote d''Azur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La Mediterranee', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer du Nord', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer Baltique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer Caspienne', FALSE, 3);

-- Q31 - Ville au bord de la Mediterranee ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle ville est situee au bord de la mer Mediterranee ?',
        'Marseille, Nice, Toulon, Montpellier... Plusieurs grandes villes francaises sont situees sur la cote mediterraneenne.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Marseille', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Lille', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Strasbourg', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Rennes', FALSE, 3);

-- Q32 - Ou se situe la Corse ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Ou se situe la Corse ?',
        'La Corse est une ile francaise situee en mer Mediterranee, au sud de la France metropolitaine, a l''ouest de l''Italie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'En mer Mediterranee', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'Dans l''ocean Atlantique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'En Manche', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'Dans la mer du Nord', FALSE, 3);

-- Q33 - Chaine de montagnes entre la France et l'Italie ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Quelle chaine de montagnes est situee entre la France et l''Italie ?',
        'Les Alpes separent la France de l''Italie. Le point culminant est le mont Blanc (4 808 m), plus haut sommet d''Europe occidentale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Alpes', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Pyrenees', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Le Massif central', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Vosges', FALSE, 3);

-- ---------- CULTURE ----------

-- Q34 - Qui etait Moliere ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait Moliere ?',
        'Moliere (1622-1673) etait un dramaturge et comedien francais du XVIIe siecle. Il est l''auteur de comedies celebres comme "L''Avare", "Le Misanthrope", "Tartuffe".',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un dramaturge francais du XVIIe siecle',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un peintre italien', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un explorateur portugais', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un compositeur allemand', FALSE, 3);

-- Q35 - Qui etait Charles Baudelaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait Charles Baudelaire ?',
        'Charles Baudelaire (1821-1867) est un poete francais majeur du XIXe siecle, auteur des "Fleurs du Mal" (1857).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un poete francais (XIXe siecle)', TRUE,
        0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un peintre impressionniste', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un scientifique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un homme politique', FALSE, 3);

-- Q36 - Qui etait George Sand ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait George Sand ?',
        'George Sand (1804-1876, vrai nom Aurore Dupin) etait une romanciere francaise du XIXe siecle. Elle est connue pour ses romans (La Mare au Diable, La Petite Fadette) et son engagement social.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une romanciere francaise du XIXe siecle',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une chanteuse americaine', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une reine d''Angleterre', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une cineaste italienne', FALSE, 3);

-- Q37 - Qui etait Simone de Beauvoir ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait Simone de Beauvoir ?',
        'Simone de Beauvoir (1908-1986) etait une philosophe, romanciere et figure du feminisme francais. Auteure du "Deuxieme Sexe" (1949), texte fondateur du feminisme contemporain.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025',
        'Une philosophe et romanciere francaise, figure du feminisme', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une danseuse de l''Opera', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une chimiste belge', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une exploratrice polaire', FALSE, 3);

-- Q38 - Qui etait Albert Camus ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000026', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait Albert Camus ?',
        'Albert Camus (1913-1960) etait un ecrivain et philosophe francais, ne en Algerie. Prix Nobel de litterature en 1957, auteur de "L''Etranger", "La Peste".',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026',
        'Un ecrivain francais (Prix Nobel de litterature 1957)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un footballeur', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un peintre cubiste', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un industriel', FALSE, 3);

-- Q39 - Qui etait Paul Cezanne ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000027', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait Paul Cezanne ?',
        'Paul Cezanne (1839-1906) etait un peintre francais post-impressionniste, originaire d''Aix-en-Provence. Considere comme l''un des plus grands peintres modernes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un peintre francais post-impressionniste',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un compositeur', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un explorateur', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un homme politique', FALSE, 3);

-- Q40 - Qui etait Marc Chagall ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000028', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait Marc Chagall ?',
        'Marc Chagall (1887-1985) etait un peintre francais d''origine russe, l''un des plus grands artistes du XXe siecle. Il a notamment peint le plafond de l''Opera Garnier de Paris.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un peintre francais d''origine russe',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un musicien anglais', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un sculpteur grec', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un cuisinier italien', FALSE, 3);

-- Q41 - Qui etait Josephine Baker ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000029', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui etait Josephine Baker ?',
        'Josephine Baker (1906-1975) etait une artiste franco-americaine, danseuse et chanteuse, mais aussi resistante pendant la Seconde Guerre mondiale. Entree au Pantheon en 2021.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029',
        'Une artiste, resistante, entree au Pantheon en 2021', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une scientifique francaise', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une exploratrice', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une religieuse', FALSE, 3);

-- Q42 - Qui etait une chanteuse francaise celebre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait une chanteuse francaise celebre ?',
        'Edith Piaf (1915-1963) est une icone de la chanson francaise. Ses chansons "La Vie en rose", "Non, je ne regrette rien" sont mondialement celebres.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Edith Piaf', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Madonna', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Maria Callas', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Aretha Franklin', FALSE, 3);

-- Q43 - Qu'est-ce que le Louvre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce que le Louvre ?',
        'Le Louvre est l''un des plus grands musees du monde, situe a Paris. Il abrite des oeuvres majeures comme la Joconde, la Venus de Milo, la Victoire de Samothrace.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un grand musee a Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un opera', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Une bibliotheque universitaire', FALSE,
        2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un stade de football', FALSE, 3);

-- Q44 - Qui etait Jean de La Fontaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui etait Jean de La Fontaine ?',
        'Jean de La Fontaine (1621-1695) etait un poete francais du XVIIe siecle, celebre pour ses Fables ("Le Corbeau et le Renard", "La Cigale et la Fourmi"...).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c',
        'Un poete francais celebre pour ses Fables', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un architecte', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un mathematicien', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un peintre', FALSE, 3);

-- Q45 - Quel ecrivain est francais ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quel ecrivain est francais ?',
        'Victor Hugo (1802-1885) est l''un des plus grands ecrivains francais. Auteur des "Miserables", "Notre-Dame de Paris", il fut aussi homme politique et defenseur des droits humains.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002d', 'Victor Hugo', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002d', 'Ernest Hemingway', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002d', 'William Shakespeare', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002d', 'Miguel de Cervantes', FALSE, 3);

-- Q46 - Dans quelle ville se trouve la tour Eiffel ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Dans quelle ville se trouve la tour Eiffel ?',
        'La tour Eiffel se trouve a Paris, sur le Champ-de-Mars. Construite par Gustave Eiffel pour l''Exposition universelle de 1889.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Lyon', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Marseille', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Bordeaux', FALSE, 3);

-- Q47 - Quand celebre-t-on Noel ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand celebre-t-on Noel ?',
        'Noel est celebre le 25 decembre. C''est une fete chretienne, mais aussi un jour ferie en France et une fete familiale celebree par beaucoup de Francais quelle que soit leur religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 25 decembre', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 31 octobre', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 14 fevrier', FALSE, 3);
-- ============================================================================
-- THEME 5 : Vivre dans la societe francaise (31 questions)
-- ============================================================================

-- ---------- NUMEROS D'URGENCE ----------

-- Q1 - Quel numero d'urgence permet d'appeler le SAMU ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel numero d''urgence permet d''appeler le SAMU ?',
        'Le 15 est le numero du SAMU (Service d''Aide Medicale Urgente). Il s''appelle en cas d''urgence medicale grave (malaise, accident, blessure...).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 15', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 17', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 18', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 112', FALSE, 3);

-- Q2 - Quel numero d'urgence permet d'appeler les pompiers ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel numero d''urgence permet d''appeler les pompiers ?',
        'Le 18 est le numero des pompiers. Ils interviennent pour les incendies, les accidents, les secours d''urgence et les catastrophes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 18', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 15', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 17', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 119', FALSE, 3);

-- Q3 - Qu'est-ce qu'un numero d'urgence ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce qu''un numero d''urgence ?',
        'Un numero d''urgence est un numero gratuit que l''on peut appeler en cas de situation grave : 15 (SAMU), 17 (Police), 18 (Pompiers), 112 (numero europeen).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003',
        'Un numero gratuit pour contacter les secours', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numero personnel du president', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numero de la mairie', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numero pour reserver un taxi', FALSE,
        3);

-- ---------- PERMIS DE CONDUIRE ----------

-- Q4 - Apres avoir obtenu le permis, que faut-il faire pour conduire sa voiture ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Apres avoir obtenu le permis de conduire, que faut-il faire pour pouvoir conduire sa voiture ?',
        'Apres l''obtention du permis, il faut faire immatriculer son vehicule (carte grise) et le faire assurer obligatoirement (assurance auto au minimum responsabilite civile).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004',
        'Assurer son vehicule (l''assurance est obligatoire)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Rien, le permis suffit', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Demander une autorisation a la mairie',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Passer un test medical chaque annee',
        FALSE, 3);

-- ---------- MARIAGE & ETAT CIVIL ----------

-- Q5 - A quelles conditions un mariage est-il reconnu juridiquement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'A quelles conditions un mariage est-il reconnu juridiquement en France ?',
        'Un mariage est juridiquement reconnu en France uniquement s''il est celebre par un officier d''etat civil (le maire ou son adjoint) a la mairie. Les mariages religieux n''ont pas de valeur civile.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005',
        'S''il est celebre a la mairie par un officier d''etat civil', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'S''il est celebre dans un lieu religieux',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'Si les parents donnent leur accord',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'S''il est annonce dans le journal', FALSE,
        3);

-- Q6 - Quand faut-il declarer son enfant a l'etat civil ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Quand faut-il declarer son enfant au service d''etat civil de la mairie ?',
        'La declaration de naissance doit etre faite dans les 5 jours suivant la naissance (jour de l''accouchement non compris), a la mairie du lieu de naissance.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Dans les 5 jours apres la naissance',
        TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Dans le mois qui suit', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Au premier anniversaire', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Avant l''entree a l''ecole', FALSE, 3);

-- ---------- TRAVAIL & EMPLOI ----------

-- Q7 - Le travail non declare est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Le travail non declare est :',
        'Le travail non declare (travail au noir) est illegal. Il prive le travailleur de droits sociaux (chomage, retraite, securite sociale) et expose employeur et salarie a des sanctions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Interdit et puni par la loi', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Autorise pour les petits emplois', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Sans consequence', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Encourage par l''Etat', FALSE, 3);

-- Q8 - Que doit faire un employeur pour fixer un salaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Que doit faire un employeur pour fixer un salaire ?',
        'L''employeur doit respecter le SMIC (salaire minimum legal) et la convention collective applicable. Le salaire ne peut etre inferieur au SMIC.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Respecter au minimum le SMIC', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Decider seul du montant', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Payer ce que le salarie demande', FALSE,
        2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Adapter le salaire au sexe du salarie',
        FALSE, 3);

-- Q9 - Qu'est-ce que le SMIC ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que le SMIC ?',
        'Le SMIC (Salaire Minimum Interprofessionnel de Croissance) est le salaire horaire minimum legal en dessous duquel un employeur ne peut pas payer un salarie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Le salaire minimum legal en France', TRUE,
        0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Un impot paye par les salaries', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Le nom d''une assurance', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Une aide sociale pour les chomeurs',
        FALSE, 3);

-- Q10 - Premiere demarche pour chercher un emploi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Quelle est la premiere demarche a realiser pour chercher un emploi ?',
        'La premiere demarche est de s''inscrire a France Travail (anciennement Pole Emploi). Cela permet de beneficier d''un accompagnement et eventuellement d''indemnites de chomage.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'S''inscrire a France Travail', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'Attendre une convocation de l''Etat',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a',
        'Demander une autorisation a la prefecture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'Ouvrir un compte bancaire', FALSE, 3);

-- Q11 - Quelle est la duree legale du travail par semaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quelle est la duree legale du temps de travail par semaine ?',
        'La duree legale du temps de travail en France est de 35 heures par semaine pour un temps plein, depuis les lois Aubry de 2000.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '35 heures', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '40 heures', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '48 heures', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '30 heures', FALSE, 3);

-- Q12 - Qui est aide par France Travail ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Qui est aide par France Travail ?',
        'France Travail (ex-Pole Emploi) accompagne les demandeurs d''emploi : inscription, recherche d''emploi, indemnites, formation. Les entreprises peuvent egalement etre aidees dans leurs recrutements.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les demandeurs d''emploi', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les retraites', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les eleves d''ecole primaire', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les touristes etrangers', FALSE, 3);

-- Q13 - Etranger en situation reguliere peut creer son entreprise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Une personne etrangere en situation reguliere peut creer son entreprise :',
        'Oui. Toute personne etrangere en situation reguliere peut creer une entreprise en France, dans les memes conditions qu''un citoyen francais.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d',
        'Oui, dans les memes conditions qu''un Francais', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d', 'Non, c''est reserve aux Francais', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d',
        'Oui, mais uniquement en s''associant a un Francais', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d', 'Oui, mais apres 10 ans de residence',
        FALSE, 3);

-- Q14 - Une femme peut-elle creer son entreprise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
        'Une femme peut-elle creer son entreprise ?',
        'Oui. L''egalite hommes-femmes est un principe constitutionnel. Une femme peut creer son entreprise dans les memes conditions qu''un homme, sans autorisation particuliere.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e',
        'Oui, dans les memes conditions qu''un homme', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Non, c''est reserve aux hommes', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Oui, avec l''autorisation de son mari',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Oui, uniquement dans certains secteurs',
        FALSE, 3);

-- Q15 - A partir de quel age un mineur peut-il travailler ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'A partir de quel age un mineur peut-il travailler ?',
        'Un mineur peut travailler a partir de 16 ans (avec autorisation parentale). Des 14 ans, il peut faire des petits travaux pendant les vacances scolaires sous conditions strictes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f',
        'A partir de 16 ans (avec accord parental)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'A partir de 18 ans seulement', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'A partir de 12 ans', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'A tout age, sans restriction', FALSE, 3);

-- ---------- SANTE ----------

-- Q16 - Organisme pour rembourser les frais de sante ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Aupres de quel organisme faut-il demander le remboursement des frais de sante ?',
        'Les remboursements de frais de sante sont assures par l''Assurance Maladie (CPAM - Caisse Primaire d''Assurance Maladie), qui fait partie de la Securite sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'L''Assurance Maladie (CPAM)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'La mairie', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'La prefecture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'France Travail', FALSE, 3);

-- Q17 - Acces aux soins : quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Concernant l''acces aux soins, quelle proposition est correcte ?',
        'L''acces aux soins est un droit en France. Le systeme de Securite sociale permet a toute personne residant en France de beneficier d''une prise en charge des frais de sante.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011',
        'Toute personne residant en France a droit aux soins', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011', 'Seuls les Francais ont acces aux soins',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011',
        'Les soins sont reserves aux personnes salariees', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011', 'L''acces aux soins depend de la religion',
        FALSE, 3);

-- Q18 - Probleme de sante non urgent : a qui s'adresser ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
        'En cas de probleme de sante non urgent, a qui faut-il s''adresser en premier ?',
        'En cas de probleme de sante non urgent, il faut consulter son medecin traitant. Il est le premier contact dans le parcours de soins et oriente si necessaire vers un specialiste.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'Au medecin traitant', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'Aux urgences de l''hopital', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'A la police', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'A la mairie', FALSE, 3);

-- Q19 - Quel est le role du medecin traitant ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Quel est le role du medecin traitant ?',
        'Le medecin traitant est le premier contact pour les questions de sante. Il coordonne le parcours de soins, oriente vers les specialistes et permet un meilleur remboursement par la Securite sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013',
        'Suivre la sante du patient et coordonner les soins', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Faire uniquement de la chirurgie', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Rembourser les soins', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Vendre des medicaments', FALSE, 3);

-- Q20 - Quand se rendre aux urgences de l'hopital ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Dans quelles situations doit-on se rendre aux urgences de l''hopital ?',
        'Les urgences sont reservees aux situations graves et imminentes : accident, malaise grave, hemorragie, douleur intense, perte de conscience. Pour les soins non urgents, voir un medecin traitant.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014',
        'Pour une urgence vitale ou un accident grave', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour un simple rhume', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour faire renouveler une ordonnance',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour un controle de routine', FALSE, 3);

-- Q21 - Objectif des vaccinations obligatoires ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Quel est l''objectif des vaccinations obligatoires ?',
        'Les vaccinations obligatoires protegent l''enfant contre certaines maladies graves et evitent leur propagation. En France, 11 vaccins sont obligatoires pour les enfants nes depuis 2018.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015',
        'Proteger la sante individuelle et collective', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Rapporter de l''argent a l''Etat', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Reduire le nombre de naissances', FALSE,
        2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Empecher les enfants d''aller a l''ecole',
        FALSE, 3);

-- Q22 - A quoi sert la carte Vitale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'A quoi sert la carte Vitale ?',
        'La carte Vitale est la carte d''assure social. Elle permet de beneficier des remboursements de l''Assurance Maladie en attestant des droits a la Securite sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'A etre rembourse de ses frais de sante',
        TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'A voter aux elections', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'A passer les frontieres', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'A retirer de l''argent au distributeur',
        FALSE, 3);

-- Q23 - A quoi sert une mutuelle sante ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'A quoi sert une mutuelle sante ?',
        'La mutuelle (complementaire sante) rembourse la partie des frais de sante qui n''est pas prise en charge par la Securite sociale. Elle est facultative mais fortement recommandee.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017',
        'A completer les remboursements de la Securite sociale', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017',
        'A remplacer entierement la Securite sociale', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017', 'A assurer la voiture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017', 'A payer les impots', FALSE, 3);

-- ---------- ECOLE ----------

-- Q24 - Jusqu'a quel age l'ecole est-elle obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Jusqu''a quel age l''ecole est-elle obligatoire ?',
        'L''instruction est obligatoire de 3 a 16 ans en France (depuis 2019, l''age d''entree a ete abaisse a 3 ans, contre 6 ans auparavant).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''a 16 ans', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''a 12 ans', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''a 18 ans', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''a 21 ans', FALSE, 3);

-- Q25 - L'autorite parentale prevoit l'obligation :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'L''autorite parentale prevoit l''obligation :',
        'L''autorite parentale impose aux parents de proteger, eduquer, instruire et assurer l''entretien de leurs enfants jusqu''a leur majorite (18 ans).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019',
        'De proteger, nourrir, eduquer et instruire les enfants', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De choisir un metier pour ses enfants',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De marier ses enfants', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De rendre les enfants tres riches', FALSE,
        3);

-- Q26 - Pour qui l'ecole est-elle obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Pour qui l''ecole est-elle obligatoire ?',
        'L''instruction est obligatoire pour tous les enfants de 3 a 16 ans residant en France, qu''ils soient francais ou etrangers, en situation reguliere ou non.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a',
        'Pour tous les enfants de 3 a 16 ans en France', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les enfants francais',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les garcons', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les enfants pauvres',
        FALSE, 3);

-- Q27 - Quel diplome obtient-on a la fin du lycee ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel diplome obtient-on a la fin du lycee ?',
        'A la fin du lycee, les eleves passent le baccalaureat (le "bac"), diplome qui sanctionne la fin des etudes secondaires et permet de poursuivre dans l''enseignement superieur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le baccalaureat (bac)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le brevet', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'La licence', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le master', FALSE, 3);

-- Q28 - Etablissements apres l'ecole elementaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Dans quels etablissements scolaires vont les eleves apres l''ecole elementaire ?',
        'Apres l''ecole elementaire (jusqu''au CM2), les eleves vont au college (6e a 3e), puis au lycee (2nde, 1ere, terminale).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'Au college', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'A l''universite', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'En maternelle', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'Directement au travail', FALSE, 3);

-- Q29 - Pour qui l'ecole est-elle obligatoire (variante) ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Pour qui l''ecole est-elle obligatoire ?',
        'L''ecole est obligatoire pour tous les enfants residant sur le territoire francais, quelle que soit leur nationalite ou la situation administrative de leurs parents.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d',
        'Pour tous les enfants, sans distinction de nationalite', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d', 'Seulement pour les enfants nes en France',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d', 'Seulement pour les enfants de salaries',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d',
        'Seulement pour les enfants de plus de 6 ans', FALSE, 3);

-- Q30 - Un enfant inscrit a l'ecole :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Un enfant inscrit a l''ecole :',
        'Un enfant inscrit a l''ecole doit la frequenter de maniere reguliere. L''assiduite est obligatoire. Les absences injustifiees peuvent etre sanctionnees.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e',
        'Doit y aller regulierement (assiduite obligatoire)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'Peut y aller quand il le souhaite', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'N''est pas tenu de suivre les cours',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'Peut choisir lui-meme ses matieres',
        FALSE, 3);

-- Q31 - Les enfants qui ne parlent pas francais :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Les enfants qui ne parlent pas francais :',
        'Les enfants qui ne parlent pas francais sont accueillis a l''ecole dans des dispositifs adaptes (UPE2A - Unite Pedagogique pour Eleves Allophones Arrivants) pour apprendre le francais et suivre une scolarite normale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f',
        'Sont accueillis a l''ecole avec un soutien adapte pour apprendre le francais', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f', 'Ne peuvent pas aller a l''ecole', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f',
        'Doivent attendre de parler francais pour y aller', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f', 'Sont renvoyes dans leur pays d''origine',
        FALSE, 3);