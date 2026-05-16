-- ============================================================================
-- Questions officielles - Thématiques 2 à 5 du module civique
-- Source : site du ministère de l'Intérieur (livret du citoyen)
-- ============================================================================
-- Thèmes :
--   2 - 11111111-0000-0000-0000-000000000002 (CIV_INSTITUTIONS)
--   3 - 11111111-0000-0000-0000-000000000003 (CIV_DROITS_DEVOIRS)
--   4 - 11111111-0000-0000-0000-000000000004 (CIV_HISTOIRE_GEO)
--   5 - 11111111-0000-0000-0000-000000000005 (CIV_SOCIETE)
-- ============================================================================

-- ============================================================================
-- THÈME 2 : Système institutionnel et politique (46 questions)
-- ============================================================================

-- Q1 - Qui nomme le Premier ministre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui nomme le Premier ministre ?',
        'Le Premier ministre est nommé par le président de la République (article 8 de la Constitution). Il dirige l''action du gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Le président de la République', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'L''Assemblée nationale', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Le Conseil constitutionnel', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000001', 'Les citoyens au suffrage direct', FALSE,
        3);

-- Q2 - Le Parlement est composé :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Le Parlement est composé :',
        'Le Parlement français est bicaméral : il comprend l''Assemblée nationale (députés) et le Sénat (sénateurs).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'De l''Assemblée nationale et du Sénat',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Du président et des ministres', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Du Conseil constitutionnel uniquement',
        FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000002', 'Des maires et des préfets', FALSE, 3);

-- Q3 - Qu'est-ce que le pouvoir exécutif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que le pouvoir exécutif ? Le pouvoir :',
        'Le pouvoir exécutif est chargé d''appliquer les lois et de diriger la politique de la nation. En France, il est exercé par le président et le gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003',
        'D''appliquer les lois et de diriger l''État', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De juger les citoyens', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000003', 'De modifier la Constitution', FALSE, 3);

-- Q4 - Les dirigeants sont élus par les citoyens dans :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Les dirigeants sont élus par les citoyens dans :',
        'Dans une démocratie, les dirigeants sont élus par les citoyens lors d''élections libres. La France est une démocratie représentative.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une démocratie', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une dictature', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une monarchie absolue', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000004', 'Une théocratie', FALSE, 3);

-- Q5 - A-t-on le droit de ne pas respecter une loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'MISE_SITUATION',
        'A-t-on le droit de ne pas respecter une loi ?',
        'Non. Tout citoyen doit respecter la loi. Ne pas la respecter expose à des sanctions pénales ou civiles, prononcées par les tribunaux.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Non, tout le monde doit respecter la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005',
        'Oui, si on n''est pas d''accord avec elle', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Oui, dans son foyer privé', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000005', 'Oui, si on est mineur', FALSE, 3);

-- Q6 - Qui doit respecter la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui doit respecter la loi ?',
        'Toute personne présente sur le territoire français doit respecter la loi : citoyens français, étrangers, résidents, touristes, dirigeants politiques.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006',
        'Toute personne présente sur le territoire français', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les citoyens français', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les majeurs', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000006', 'Uniquement les personnes salariées',
        FALSE, 3);

-- Q7 - Quel est le rôle de l'autorité judiciaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le rôle de l''autorité judiciaire ?',
        'L''autorité judiciaire fait respecter la loi, tranche les conflits entre personnes et sanctionne les infractions. Elle est indépendante du pouvoir politique.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007',
        'Faire respecter la loi et juger les litiges', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Nommer le président', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000007', 'Diriger l''armée', FALSE, 3);

-- Q8 - Quel pouvoir détient un juge ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel pouvoir détient un juge ? Le pouvoir :',
        'Le juge exerce le pouvoir judiciaire : il dit le droit, tranche les litiges et sanctionne les infractions, en toute indépendance.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Judiciaire', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Législatif', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Exécutif', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000008', 'Constituant', FALSE, 3);

-- Q9 - L'autorité judiciaire est exercée par :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'L''autorité judiciaire est exercée par :',
        'L''autorité judiciaire est exercée par les juges et magistrats, dans les tribunaux. Ils sont indépendants des pouvoirs exécutif et législatif.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les juges et les magistrats', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les députés et sénateurs', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000009', 'Le président seul', FALSE, 3);

-- Q10 - Que se passe-t-il si un ministre ne respecte pas la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Que se passe-t-il si un ministre ne respecte pas la loi ?',
        'Un ministre, comme tout citoyen, est soumis à la loi. Il peut être jugé par la Cour de justice de la République pour les actes commis dans ses fonctions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il peut être jugé comme tout citoyen',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Rien, il a l''immunité totale', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il perd seulement son poste', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000a', 'Il décide lui-même de sa sanction', FALSE,
        3);

-- Q11 - Qui est élu lors des élections législatives ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est élu lors des élections législatives ?',
        'Les élections législatives élisent les députés de l''Assemblée nationale, au suffrage universel direct.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les députés', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Le président', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les maires', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000b', 'Les sénateurs', FALSE, 3);

-- Q12 - Combien de députés composent l'Assemblée nationale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien de députés composent l''Assemblée nationale ?',
        'L''Assemblée nationale compte 577 députés, élus pour 5 ans au suffrage universel direct, chacun dans une circonscription.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '577 députés', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '348 députés', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '500 députés', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000c', '1000 députés', FALSE, 3);

-- Q13 - Quand sont élus les sénateurs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quand sont élus les sénateurs ?',
        'Les sénateurs sont élus pour 6 ans au suffrage indirect, par environ 162 000 "grands électeurs" (députés, conseillers régionaux, départementaux, municipaux). Le Sénat est renouvelé par moitié tous les 3 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 3 ans, par moitié', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 5 ans en même temps', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000d', 'Tous les 10 ans', FALSE, 3);

-- Q14 - Qui est élu lors des élections municipales ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est élu lors des élections municipales ?',
        'Les élections municipales elisent les conseillers municipaux. Ces conseillers élisent ensuite le maire de la commune.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e',
        'Les conseillers municipaux (qui élisent le maire)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Le président de la République', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Les députés', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000e', 'Les préfets', FALSE, 3);

-- Q15 - Qui est élu lors des élections présidentielles ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui est élu lors des élections présidentielles ?',
        'L''élection présidentielle élit le président de la République, au suffrage universel direct, pour un mandat de 5 ans, depuis 1962.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Le président de la République', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Le Premier ministre', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000000f', 'Les sénateurs', FALSE, 3);

-- Q16 - À partir de quel âge a-t-on le droit de voter ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'À partir de quel âge a-t-on le droit de voter ?',
        'En France, le droit de vote est accordé à partir de 18 ans, âge de la majorité civile fixée depuis 1974.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '18 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '16 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '21 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000010', '25 ans', FALSE, 3);

-- Q17 - Pour combien de temps est élu le président ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps est élu le président de la République française ?',
        'Le président de la République est élu pour 5 ans (quinquennat) depuis la réforme constitutionnelle de 2000.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '5 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '4 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '6 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000011', '7 ans', FALSE, 3);

-- Q18 - Pour combien de temps sont élus les députés ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps sont élus les députés ?',
        'Les députés sont élus pour 5 ans au suffrage universel direct, par circonscription.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '5 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '4 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '6 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000012', '7 ans', FALSE, 3);

-- Q19 - Pour combien de temps sont élus les sénateurs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Pour combien de temps sont élus les sénateurs ?',
        'Les sénateurs sont élus pour 6 ans au suffrage universel indirect. Le Sénat est renouvelé par moitié tous les 3 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '6 ans', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '5 ans', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '3 ans', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000013', '9 ans', FALSE, 3);

-- Q20 - Qui possède le pouvoir exécutif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui possède le pouvoir exécutif ?',
        'Le pouvoir exécutif est détenu par le président de la République et le gouvernement (Premier ministre et ministres).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Le président et le gouvernement', TRUE,
        0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'L''Assemblée nationale et le Sénat',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Les tribunaux', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000014', 'Le Conseil constitutionnel', FALSE, 3);

-- Q21 - Quelle condition est nécessaire pour voter aux élections ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quelle condition est nécessaire pour voter aux élections ?',
        'Pour voter en France, il faut être majeur (18 ans), de nationalité française (sauf élections locales et européennes pour les ressortissants UE), jouir de ses droits civils, et être inscrit sur les listes électorales.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015',
        'Être majeur, citoyen et inscrit sur les listes électorales', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Avoir suivi des études supérieures',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Être propriétaire', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000015', 'Payer un impôt spécifique', FALSE, 3);

-- Q22 - Qui peut voter aux élections en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui peut voter aux élections en France ?',
        'Aux élections nationales, seuls les citoyens français majeurs et inscrits sur les listes peuvent voter. Les ressortissants UE peuvent voter aux municipales et européennes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016',
        'Les citoyens français majeurs inscrits sur les listes électorales', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016',
        'Tous les résidents en France, français ou non', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016', 'Uniquement les fonctionnaires', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000016', 'Toute personne de plus de 16 ans', FALSE,
        3);

-- Q23 - Que signifie "suffrage universel" ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Que signifie "suffrage universel" ?',
        'Le suffrage universel signifie que tous les citoyens majeurs ont le droit de voter, sans condition de fortune, de sexe ou d''éducation. En France : universel masculin en 1848, étendu aux femmes en 1944.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017',
        'Tous les citoyens majeurs ont le droit de vote', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Le vote est obligatoire pour tous', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Seuls les hommes peuvent voter', FALSE,
        2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000017', 'Le vote des étrangers est autorisé',
        FALSE, 3);

-- Q24 - Concernant les partis politiques, quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Concernant les partis politiques, quelle proposition est correcte ?',
        'Les partis politiques se forment librement et concourent à l''expression du suffrage (article 4 de la Constitution). Le multipartisme est garanti.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018',
        'Plusieurs partis politiques peuvent exister librement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018', 'Il n''y a qu''un seul parti autorisé',
        FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018', 'Les partis politiques sont interdits',
        FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000018',
        'Seuls les ministres peuvent créer un parti', FALSE, 3);

-- Q25 - Quel est le rôle des députés ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le rôle des députés ?',
        'Les députés votent les lois, contrôlent l''action du gouvernement et représentent les citoyens de leur circonscription à l''Assemblée nationale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019',
        'Voter les lois et contrôler le gouvernement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Diriger les ministères', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Juger les criminels', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000019', 'Nommer le président', FALSE, 3);
-- Q26 - La séparation des pouvoirs : quels sont les trois pouvoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'La séparation des pouvoirs est un principe fondamental. Quels sont les trois pouvoirs concernés ?',
        'Selon Montesquieu, les trois pouvoirs sont : législatif (faire les lois), exécutif (les appliquer), judiciaire (sanctionner leur non-respect). Ils doivent être séparés pour éviter la concentration du pouvoir.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Législatif, exécutif, judiciaire', TRUE,
        0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Politique, économique, militaire', FALSE,
        1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'National, régional, local', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001a', 'Civil, pénal, administratif', FALSE, 3);

-- Q27 - Qui possède le pouvoir législatif ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui possède le pouvoir législatif ?',
        'Le pouvoir législatif est détenu par le Parlement, composé de l''Assemblée nationale et du Sénat. Il vote les lois et le budget de l''État.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b',
        'Le Parlement (Assemblée nationale + Sénat)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Le président seul', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Les juges', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001b', 'Les maires', FALSE, 3);

-- Q28 - Qui sanctionne l'auteur d'un vol ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui sanctionne l''auteur d''un vol ?',
        'Le vol est une infraction pénale. C''est un tribunal, dans le cadre du pouvoir judiciaire, qui juge et sanctionne l''auteur du vol.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Un tribunal (juge)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Le maire', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'La victime elle-même', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001c', 'Le Premier ministre', FALSE, 3);

-- Q29 - Qui élit les députés ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui élit les députés ?',
        'Les députés sont élus par les citoyens français majeurs au suffrage universel direct, par circonscription.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d',
        'Les citoyens majeurs au suffrage universel direct', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Les sénateurs', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Le président de la République', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001d', 'Les maires', FALSE, 3);

-- Q30 - Qui vote les lois ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui vote les lois ?',
        'Les lois sont votées par le Parlement (Assemblée nationale + Sénat). C''est le pouvoir législatif.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le Parlement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le président seul', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Le Conseil constitutionnel', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001e', 'Les juges', FALSE, 3);

-- Q31 - Qui réside au palais de l'Élysée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui réside au palais de l''Élysée ?',
        'Le palais de l''Élysée, à Paris, est la résidence officielle du président de la République depuis 1873.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le président de la République', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le Premier ministre', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le président du Sénat', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000001f', 'Le maire de Paris', FALSE, 3);

-- Q32 - Combien y a-t-il de départements en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien y a-t-il de départements en France ?',
        'La France compte 101 départements : 96 en métropole et 5 outre-mer (Guadeloupe, Martinique, Guyane, La Réunion, Mayotte).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020',
        '101 départements (96 en métropole, 5 outre-mer)', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '50', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '83', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000020', '120', FALSE, 3);

-- Q33 - Qui représente l'État dans un département ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui représente l''État dans un département ?',
        'Le préfet est le représentant de l''État dans un département. Il est nommé par le président sur proposition du Premier ministre.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le préfet', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le maire', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le député', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000021', 'Le procureur', FALSE, 3);

-- Q34 - Qui dirige la commune ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Qui dirige la commune ?',
        'Le maire dirige la commune. Il est élu par le conseil municipal pour 6 ans. Il est officier d''état civil et de police judiciaire.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le maire', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le préfet', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le député', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000022', 'Le ministre de l''Intérieur', FALSE, 3);

-- Q35 - Est-ce que le président a tous les pouvoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Est-ce que le président de la République a tous les pouvoirs ?',
        'Non. Les pouvoirs sont séparés : le président partage le pouvoir exécutif avec le gouvernement, le Parlement vote les lois, et la justice est indépendante.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Non, les pouvoirs sont séparés', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Oui, il décide de tout', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023',
        'Oui, il peut modifier seul la Constitution', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000023', 'Oui, sauf en cas de guerre', FALSE, 3);

-- Q36 - Qui est le préfet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui est le préfet ?',
        'Le préfet est le représentant de l''État dans le département (ou la région). Il met en œuvre la politique du gouvernement au niveau local.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024',
        'Le représentant de l''État dans le département', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Un élu municipal', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Le chef de la police nationale', FALSE,
        2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000024', 'Un juge spécialisé', FALSE, 3);

-- Q37 - Quel est le rôle du Parlement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le rôle du Parlement ?',
        'Le Parlement vote les lois, autorise le budget de l''État et contrôle l''action du gouvernement.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025',
        'Voter les lois et contrôler le gouvernement', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Diriger les ministères', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Rendre la justice', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000025', 'Nommer les préfets', FALSE, 3);

-- Q38 - Quel est le régime politique de la France aujourd'hui ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000026', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel est le régime politique de la France aujourd''hui ?',
        'La France est sous le régime de la Ve République depuis 1958. C''est une république semi-présidentielle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La Ve République', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La IVe République', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'L''Empire', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000026', 'La monarchie constitutionnelle', FALSE,
        3);

-- ---------- UNION EUROPÉENNE ----------

-- Q39 - Combien d'États font partie de l'UE au 1er janvier 2025 ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000027', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Combien d''États font partie de l''Union européenne au 1er janvier 2025 ?',
        'L''Union européenne compte 27 États membres depuis le retrait du Royaume-Uni (Brexit) en 2020.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '27 États', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '15 États', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '28 États', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000027', '50 États', FALSE, 3);

-- Q40 - Quel État n'est pas membre de l'UE ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000028', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Quel État n''est pas membre de l''Union européenne ?',
        'La Suisse n''est pas membre de l''Union européenne. Elle a refusé plusieurs fois par référendum. Le Royaume-Uni est sorti de l''UE en 2020 (Brexit).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'La Suisse', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Italie', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Allemagne', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000028', 'L''Espagne', FALSE, 3);

-- Q41 - Quelle condition pour voter aux élections européennes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-000000000029', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quelle condition est nécessaire pour voter aux élections européennes ?',
        'Pour voter aux élections européennes, il faut être majeur, ressortissant d''un État membre de l''UE et inscrit sur les listes électorales en France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029',
        'Être majeur et citoyen d''un État membre de l''UE', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029',
        'Être obligatoirement de nationalité française', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029', 'Résider en Belgique', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-000000000029', 'Parler trois langues européennes', FALSE,
        3);

-- Q42 - À quelle fréquence les élections européennes sont-elles organisées ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'À quelle fréquence les élections européennes sont-elles organisées ?',
        'Les élections européennes ont lieu tous les 5 ans, simultanément dans tous les États membres de l''UE.',
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
        'Quel pays est un pays fondateur de l''Union européenne ?',
        'Les 6 pays fondateurs (CEE 1957) sont : France, Allemagne, Italie, Belgique, Pays-Bas et Luxembourg.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La France', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'L''Espagne', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La Pologne', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002b', 'La Grèce', FALSE, 3);

-- Q44 - Quelle est la monnaie utilisée en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CSP', 'CONNAISSANCE',
        'Quelle est la monnaie utilisée en France ?',
        'L''euro est la monnaie de la France depuis le 1er janvier 2002, partagée avec 19 autres pays de la zone euro.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'L''euro', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'Le franc', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'La livre sterling', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002c', 'Le dollar', FALSE, 3);

-- Q45 - Qui élit les députés européens ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'CR', 'CONNAISSANCE',
        'Qui élit les députés européens ?',
        'Les députés du Parlement européen sont élus au suffrage universel direct par les citoyens des États membres, tous les 5 ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les citoyens des États membres de l''UE',
        TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les chefs d''État', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'Les ministres', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002d', 'La Cour de justice européenne', FALSE, 3);

-- Q46 - Quand célèbre-t-on la journée de l'Europe ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f2000000-0000-0000-0000-00000000002e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000002', 'NAT', 'CONNAISSANCE',
        'Quand célèbre-t-on la journée de l''Europe ?',
        'La journée de l''Europe est célébrée le 9 mai, en commémoration de la déclaration de Robert Schuman du 9 mai 1950, acte fondateur de la construction européenne.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 9 mai', TRUE, 0),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 14 juillet', FALSE, 1),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 1er janvier', FALSE, 2),
       (gen_random_uuid(), 'f2000000-0000-0000-0000-00000000002e', 'Le 11 novembre', FALSE, 3);
-- ============================================================================
-- THÈME 3 : Droits et devoirs (30 questions)
-- ============================================================================

-- Q1 - Comment s'appelle la Constitution actuelle de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Comment s''appelle la Constitution actuelle de la France ?',
        'La Constitution actuelle est celle de la Ve République, adoptée le 4 octobre 1958.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de la Ve République',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de 1789', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution européenne', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000001', 'La Constitution de l''Empire', FALSE, 3);

-- Q2 - Texte qui enonce les droits et devoirs des personnes résidant en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Comment s''appelle le texte qui énonce les droits et devoirs des personnes résidant en France ?',
        'La Charte des droits et devoirs du citoyen français, établie en 2012, rappelle les principes fondamentaux et les valeurs essentielles de la République.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002',
        'La Charte des droits et devoirs du citoyen français', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'Le Code civil', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'La Bible', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000002', 'Le Code du travail', FALSE, 3);

-- Q3 - Concernant les droits individuels, quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Concernant les droits individuels, quelle proposition est correcte ?',
        'Les droits individuels (liberté, sûreté, propriété, libre expression, etc.) sont garantis à toute personne sur le territoire français, sans discrimination.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003',
        'Ils sont garantis à toute personne, sans discrimination', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003', 'Ils sont réservés aux citoyens français',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003',
        'Ils s''achètent par un titre de propriété', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000003', 'Ils dépendent de la religion', FALSE, 3);

-- Q4 - De quelle année date la Déclaration des droits de l'homme ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'De quelle année date la Déclaration des droits de l''homme et du citoyen ?',
        'La Déclaration des droits de l''homme et du citoyen a été adoptée le 26 août 1789, pendant la Révolution française. Elle a valeur constitutionnelle.',
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
        'Le droit à la liberté, le droit à la sûreté, le droit à la propriété sont des droits fondamentaux inscrits dans la Déclaration de 1789.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'La liberté', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit à la voiture', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit aux vacances', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000005', 'Le droit à un smartphone', FALSE, 3);

-- Q6 - Parmi ces textes, lequel garantit les droits et libertés en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Parmi ces textes, lequel garantit les droits et libertés en France ?',
        'La Déclaration des droits de l''homme et du citoyen de 1789, intégrée au "bloc de constitutionnalité", garantit les droits et libertés fondamentales.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006',
        'La Déclaration des droits de l''homme et du citoyen', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le Code de la route', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le manuel scolaire', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000006', 'Le journal officiel', FALSE, 3);

-- Q7 - Qu'est-ce que la liberté d'expression ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que la liberté d''expression ?',
        'La liberté d''expression est le droit de dire, écrire ou publier ses opinions, dans le respect des lois (pas d''injures, de diffamation, d''incitation à la haine).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007',
        'Le droit d''exprimer ses opinions dans le respect de la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'Le droit de dire tout sans limite', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'L''interdiction de parler en public',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000007', 'Une liberté réservée aux journalistes',
        FALSE, 3);

-- Q8 - Quel droit permet à une personne de se défendre devant la justice ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel droit permet à une personne de se défendre devant la justice ?',
        'Le droit à la défense (et le droit à un avocat) est un principe fondamental. Toute personne accusée a le droit d''être défendue, présumée innocente jusqu''à preuve du contraire.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit à la défense (et à un avocat)',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit de vote', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit de propriété', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000008', 'Le droit à la santé', FALSE, 3);

-- Q9 - Quel est le texte fondateur établissant les droits et devoirs ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Quel est le texte fondateur établissant en France les droits et les devoirs de chaque citoyen ?',
        'La Déclaration des droits de l''homme et du citoyen de 1789 est le texte fondateur des droits et libertés en France. Elle reste intégrée à la Constitution actuelle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009',
        'La Déclaration des droits de l''homme et du citoyen (1789)', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'Le Code de la santé publique', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'Le Traité de Rome', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000009', 'La Charte des Nations unies', FALSE, 3);

-- Q10 - Quel texte a été adopté pendant la Révolution française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel texte a été adopté pendant la Révolution française ?',
        'La Déclaration des droits de l''homme et du citoyen a été adoptée le 26 août 1789 par l''Assemblée nationale constituante, pendant la Révolution.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a',
        'La Déclaration des droits de l''homme et du citoyen', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'Le Traité de Rome', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'La Constitution de la Ve République',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000a', 'La loi de 1905', FALSE, 3);

-- Q11 - Quelle liberté permet de ne pas avoir de religion ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quelle liberté permet à une personne de ne pas avoir de religion ?',
        'La liberté de conscience, garantie par la laïcité, permet de croire, de ne pas croire ou de changer de religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberté de conscience', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberté du commerce', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberté de la presse', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000b', 'La liberté de circulation', FALSE, 3);

-- Q12 - Une femme peut avorter :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Une femme peut avorter :',
        'Le droit à l''interruption volontaire de grossesse (IVG) est garanti depuis la loi Veil de 1975. Il est inscrit dans la Constitution depuis 2024.',
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
        'Oui, le divorce est légal en France depuis 1792. Toute personne mariée peut demander le divorce, selon des procédures définies par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Oui, c''est un droit garanti par la loi',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Non, le divorce est interdit', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d',
        'Seulement avec l''accord des deux familles', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000d', 'Uniquement après 10 ans de mariage',
        FALSE, 3);

-- Q14 - La peine de mort est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'La peine de mort est :',
        'La peine de mort a été abolie en France le 9 octobre 1981 par la loi Badinter. Son abolition est inscrite dans la Constitution depuis 2007.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'Abolie en France depuis 1981', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'En vigueur pour les crimes graves', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e',
        'Appliquée uniquement dans certaines régions', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000e', 'Prévue par la Constitution actuelle',
        FALSE, 3);

-- Q15 - Limites aux libertés individuelles : quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Concernant les limites aux libertés individuelles, quelle proposition est correcte ?',
        'Les libertés individuelles ne sont jamais absolues : elles s''arrêtent là où commencent celles des autres, et sont encadrées par la loi pour protéger l''ordre public et autrui.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Les libertés ont des limites fixées par la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f', 'Les libertés sont absolues, sans limite',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Les libertés ne s''appliquent qu''au domicile privé', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000000f',
        'Il n''existe pas de libertés individuelles en France', FALSE, 3);

-- Q16 - En France, est-il légal d'être marié à plusieurs personnes ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'En France, est-il légal d''être marié à plusieurs personnes en même temps ?',
        'Non. La polygamie est interdite en France. Le mariage est l''union de deux personnes seulement. La bigamie est un délit pénal.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Non, la polygamie est interdite', TRUE,
        0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, c''est autorisé sans restriction',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, avec autorisation de la mairie',
        FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000010', 'Oui, selon les traditions familiales',
        FALSE, 3);

-- Q17 - Faut-il réduire ses déchets ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Faut-il réduire ses déchets ?',
        'Oui, la réduction des déchets est un devoir citoyen pour protéger l''environnement, prévu par le Code de l''environnement. Le tri et le recyclage sont obligatoires.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Oui, pour protéger l''environnement',
        TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Non, ce n''est pas important', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'Uniquement les commerces', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000011', 'C''est interdit par la loi', FALSE, 3);

-- Q18 - Jeter une bouteille dans la rue est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Jeter une bouteille dans la rue est :',
        'Jeter ses déchets dans la rue est une infraction (dépôt sauvage). C''est puni par une amende pouvant aller jusqu''à 1500 euros.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Une infraction punie par la loi', TRUE,
        0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Autorisé dans les grandes villes', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012',
        'Sans conséquence si la bouteille est en verre', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000012', 'Recommandé la nuit', FALSE, 3);

-- Q19 - Pourquoi les libertés individuelles peuvent-elles être limitées ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'Pourquoi les libertés individuelles peuvent-elles être limitées ?',
        'Les libertés peuvent être limitées pour protéger l''ordre public, la sécurité, la santé ou les libertés d''autrui. Ces limites doivent être proportionnées et fixées par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013',
        'Pour protéger les droits des autres et l''ordre public', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Selon le bon vouloir du président', FALSE,
        1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Pour favoriser une religion', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000013', 'Pour limiter le travail des étrangers',
        FALSE, 3);

-- Q20 - Que doit faire une personne en cas d'accident ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Que doit faire une personne en cas d''accident ?',
        'L''assistance à personne en danger est une obligation légale. Il faut prévenir les secours (15 SAMU, 17 Police, 18 Pompiers, 112 numéro européen) et aider sans se mettre en danger.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014',
        'Porter assistance et prévenir les secours', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014', 'Partir rapidement', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014', 'Filmer la scène', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000014',
        'Attendre que quelqu''un d''autre intervienne', FALSE, 3);

-- Q21 - Que permet la citoyenneté française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Que permet la citoyenneté française ?',
        'La citoyenneté française donne des droits (voter, être élu, exercer certaines fonctions) et des devoirs (respecter la loi, payer ses impôts, défense, jury d''assises).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015',
        'D''avoir des droits politiques (voter, être élu) et des devoirs', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'D''être dispensé d''impôts', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'D''être au-dessus des lois', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000015', 'De voyager partout sans visa', FALSE, 3);

-- Q22 - Que risque une personne qui ne respecte pas la loi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
        'Que risque une personne qui ne respecte pas la loi ?',
        'Selon la gravité, les sanctions vont de l''amende à la prison. Toute infraction est jugée par un tribunal et peut entraîner des conséquences pénales et civiles.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016',
        'Une sanction (amende, prison) prononcée par un tribunal', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'Rien, la loi est seulement indicative',
        FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'Une simple remontrance verbale', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000016', 'L''expulsion automatique du territoire',
        FALSE, 3);

-- Q23 - Quel est le rôle de la gendarmerie ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quel est le rôle de la gendarmerie ?',
        'La gendarmerie assure la sécurité publique, principalement en zone rurale et périurbaine. Elle exerce des missions de police judiciaire et administrative, sous tutelle du ministère de l''Intérieur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017',
        'Assurer la sécurité, principalement en zone rurale', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Voter les lois', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Éduquer les enfants', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000017', 'Faire la guerre à l''étranger', FALSE, 3);

-- Q24 - Quel est le rôle de la police ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'CONNAISSANCE',
        'Quel est le rôle de la police ?',
        'La police nationale assure la sécurité des personnes et des biens, principalement en zone urbaine. Elle prévient et constate les infractions, fait respecter l''ordre public.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018',
        'Assurer la sécurité et faire respecter la loi', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Juger les criminels', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Voter les lois', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000018', 'Éduquer les enfants', FALSE, 3);

-- Q25 - Qu'est-ce qu'une infraction ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Qu''est-ce qu''une infraction ?',
        'Une infraction est un comportement interdit par la loi et puni. Il en existe trois catégories : contraventions (les moins graves), délits, crimes (les plus graves).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019',
        'Une violation de la loi punie par celle-ci', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un type d''impôt', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un texte de loi', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-000000000019', 'Un titre administratif', FALSE, 3);

-- Q26 - Comment peut-on réduire ses déchets ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CSP', 'MISE_SITUATION',
        'Comment peut-on réduire ses déchets ?',
        'On peut réduire ses déchets en triant, recyclant, compostant les déchets organiques, achetant en vrac, évitant le suremballage et réparant plutôt que jetant.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a',
        'En triant, recyclant et évitant le gaspillage', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En jetant tout dans la nature', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En achetant toujours plus emballé', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001a', 'En brûlant ses déchets soi-même', FALSE,
        3);

-- Q27 - Déposer une machine à laver cassée sur le trottoir est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Déposer une machine à laver cassée sur le trottoir est :',
        'Déposer un encombrant sur le trottoir sans demande préalable est interdit. Il faut prendre rendez-vous avec le service "encombrants" de la mairie ou se rendre en déchetterie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b',
        'Interdit : il faut prendre rendez-vous pour les encombrants ou aller en déchetterie', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Autorisé tous les jours', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Autorisé dans les grandes villes', FALSE,
        2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001b', 'Une bonne action écologique', FALSE, 3);

-- Q28 - En quoi consiste la traite des êtres humains ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'NAT', 'CONNAISSANCE',
        'En quoi consiste la traite des êtres humains ?',
        'La traite des êtres humains consiste à exploiter une personne (travail forcé, prostitution, esclavage...) par la contrainte. C''est un crime grave puni par la loi.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c',
        'Exploiter une personne par la force (travail forcé, prostitution...)', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'Un type de commerce légal', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'L''immigration légale', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001c', 'L''accueil des réfugiés', FALSE, 3);

-- Q29 - Que doit faire une victime de violences ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'MISE_SITUATION',
        'Que doit faire une victime de violences ?',
        'Une victime de violences peut contacter les secours (17 Police, 15 SAMU), porter plainte au commissariat ou à la gendarmerie, et appeler le 3919 (violences conjugales) ou 119 (enfance en danger).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d',
        'Appeler les secours, porter plainte ou contacter une association', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Garder le silence et se taire', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Se venger soi-même', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001d', 'Déménager sans rien dire', FALSE, 3);

-- Q30 - Quelle est l'infraction la plus grave ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f3000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000003', 'CR', 'CONNAISSANCE',
        'Quelle est l''infraction la plus grave ?',
        'Les infractions sont classées en trois catégories par gravité croissante : contraventions, délits, crimes. Le crime (meurtre, viol...) est l''infraction la plus grave.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Le crime', TRUE, 0),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'La contravention', FALSE, 1),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Le délit', FALSE, 2),
       (gen_random_uuid(), 'f3000000-0000-0000-0000-00000000001e', 'Toutes les infractions sont équivalentes',
        FALSE, 3);
-- ============================================================================
-- THÈME 4 : Histoire, géographie et culture (46 questions)
-- ============================================================================

-- ---------- HISTOIRE ----------

-- Q1 - En quelle année a débuté la Révolution française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'En quelle année a débuté la Révolution française ?',
        'La Révolution française débute en 1789. La prise de la Bastille a lieu le 14 juillet 1789.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1789', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1689', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1848', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000001', '1914', FALSE, 3);

-- Q2 - Qui était Napoléon Ier ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était Napoléon Ier ?',
        'Napoléon Bonaparte (1769-1821) fut empereur des Français de 1804 à 1814 puis en 1815. Il a réorganisé l''État (Code civil, préfets, lycées) et conquis une grande partie de l''Europe.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002',
        'Un empereur français (début du XIXe siècle)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un roi du Moyen Âge', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un président de la Ve République', FALSE,
        2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000002', 'Un philosophe des Lumières', FALSE, 3);

-- Q3 - Lequel de ces personnages historiques est français ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Lequel de ces personnages historiques est français ?',
        'Jeanne d''Arc (1412-1431), originaire de Domrémy, est une figure majeure de l''histoire de France. Elle a contribué à libérer la France pendant la guerre de Cent Ans.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Jeanne d''Arc', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Winston Churchill', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'George Washington', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000003', 'Christophe Colomb', FALSE, 3);

-- Q4 - Dans quelle République est-on aujourd'hui ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Dans quelle République est-on aujourd''hui ?',
        'Nous sommes sous la Ve République, fondée en 1958 par Charles de Gaulle.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La Ve République', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La IIIe République', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La IVe République', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000004', 'La VIe République', FALSE, 3);

-- Q5 - Qu'est-ce que la Shoah ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qu''est-ce que la Shoah ?',
        'La Shoah est le génocide des Juifs d''Europe par l''Allemagne nazie pendant la Seconde Guerre mondiale (1939-1945). Six millions de Juifs ont été exterminés.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005',
        'Le génocide des Juifs par les nazis (1939-1945)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005',
        'Une bataille de la Première Guerre mondiale', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005', 'Une révolution européenne', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000005', 'Une fête religieuse', FALSE, 3);

-- Q6 - Quel pays a été colonisé par la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quel pays ou région du monde a été colonisé par la France ?',
        'L''Algérie, la Tunisie, le Maroc, le Sénégal, le Mali, l''Indochine et de nombreux autres pays d''Afrique et d''Asie ont été colonisés par la France entre le XVIIe et le XXe siècle.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'L''Algérie', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'La Suède', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'Le Brésil', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000006', 'L''Australie', FALSE, 3);

-- Q7 - Qui a rendu l'école gratuite, laïque et obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui a rendu l''école gratuite, laïque et obligatoire ?',
        'Jules Ferry, ministre de l''Instruction publique, a fait voter les lois rendant l''école gratuite (1881), obligatoire et laïque (1882).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Jules Ferry', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Charles de Gaulle', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'Napoléon Bonaparte', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000007', 'François Mitterrand', FALSE, 3);

-- Q8 - Quand a eu lieu la Seconde Guerre mondiale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand a eu lieu la Seconde Guerre mondiale ?',
        'La Seconde Guerre mondiale s''est déroulée de 1939 à 1945. Elle a opposé les Alliés (dont la France libre) à l''Axe (Allemagne nazie, Italie, Japon).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1939-1945', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1914-1918', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1945-1950', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000008', '1789-1799', FALSE, 3);

-- Q9 - Quand a eu lieu la Première Guerre mondiale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand a eu lieu la Première Guerre mondiale ?',
        'La Première Guerre mondiale s''est déroulée de 1914 à 1918. Elle s''est terminée par l''armistice signé le 11 novembre 1918.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1914-1918', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1939-1945', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1870-1871', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000009', '1789-1799', FALSE, 3);

-- Q10 - En quelle année a été créée la CEE ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'En quelle année a été créée la Communauté Économique Européenne (CEE) ?',
        'La CEE a été créée en 1957 par le traité de Rome, signé par 6 pays fondateurs : France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg. Elle est devenue l''Union européenne en 1993.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1957', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1945', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '1989', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000a', '2002', FALSE, 3);

-- Q11 - Le 11 novembre est un jour férié. À quoi correspond cette date ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Le 11 novembre est un jour férié. À quoi correspond cette date ?',
        'Le 11 novembre commémore l''armistice de 1918, qui a mis fin à la Première Guerre mondiale, et rend hommage aux soldats morts pour la France.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b',
        'L''armistice de 1918 (fin de la Première Guerre mondiale)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fin de la Seconde Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fête nationale', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000b', 'La fête de la République', FALSE, 3);

-- Q12 - Premier président élu sous la Ve République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui a été le premier Président élu sous la Ve République ?',
        'Charles de Gaulle a été le premier président de la Ve République, élu en 1958 (par les grands électeurs) puis réélu en 1965 au suffrage universel direct.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Charles de Gaulle', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'François Mitterrand', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Georges Pompidou', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000c', 'Jacques Chirac', FALSE, 3);

-- Q13 - Quand l'esclavage a-t-il été aboli définitivement en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'En quelle année l''esclavage a-t-il été aboli définitivement en France ?',
        'L''esclavage a été aboli définitivement en France le 27 avril 1848, sous l''impulsion de Victor Schœlcher. Il avait déjà été aboli une première fois en 1794, puis rétabli par Napoléon en 1802.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1848', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1789', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1905', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000d', '1945', FALSE, 3);

-- Q14 - Depuis quelle année l'école publique est-elle gratuite ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Depuis quelle année l''école publique est-elle gratuite ?',
        'L''école publique est gratuite depuis 1881, grâce à la loi Jules Ferry. L''instruction est devenue obligatoire et laïque en 1882.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1881', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1789', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1905', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000e', '1968', FALSE, 3);

-- Q15 - Combien y a-t-il eu de républiques en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Combien y a-t-il eu de républiques en France ?',
        'La France a connu cinq républiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946), Ve (1958, actuelle).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '5 républiques', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '3 républiques', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '1 seule république', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000000f', '10 républiques', FALSE, 3);

-- Q16 - Roi de France au moment de la Révolution ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était le roi de France au moment de la Révolution française ?',
        'Louis XVI était roi de France au début de la Révolution. Il a été guillotiné le 21 janvier 1793, marquant la fin de la monarchie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Louis XVI', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Louis XIV (le Roi-Soleil)', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Napoléon Ier', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000010', 'Henri IV', FALSE, 3);

-- Q17 - Qui a fondé la Ve République ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui a fondé la Ve République ?',
        'Charles de Gaulle a fondé la Ve République en 1958, en rédigeant une nouvelle Constitution adoptée par référendum.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Charles de Gaulle', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Napoléon III', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'Jules Ferry', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000011', 'François Mitterrand', FALSE, 3);

-- Q18 - Que célèbre-t-on le 14 juillet ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Que célèbre-t-on le 14 juillet ?',
        'Le 14 juillet, fête nationale, commémore la prise de la Bastille (14 juillet 1789), symbole de la Révolution française.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012',
        'La fête nationale (prise de la Bastille 1789)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'La fin de la Seconde Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'La fête des Mères', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000012', 'L''anniversaire du président', FALSE, 3);

-- Q19 - Quelle guerre a eu lieu entre 1914 et 1918 ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle guerre a eu lieu entre 1914 et 1918 ?',
        'La Première Guerre mondiale (Grande Guerre) s''est déroulée de 1914 à 1918. Elle a opposé principalement la France, le Royaume-Uni et la Russie à l''Allemagne et l''Autriche-Hongrie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La Première Guerre mondiale', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La Seconde Guerre mondiale', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La guerre d''Algérie', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000013', 'La guerre de Cent Ans', FALSE, 3);

-- Q20 - Pourquoi l'année 1958 est importante ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Pourquoi l''année 1958 est importante pour la France ?',
        'En 1958, la Ve République est fondée avec l''adoption de la nouvelle Constitution (4 octobre 1958), et Charles de Gaulle revient au pouvoir.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Fondation de la Ve République', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Début de la Première Guerre mondiale',
        FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Indépendance de la France', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000014', 'Abolition de l''esclavage', FALSE, 3);
-- ---------- GEOGRAPHIE ----------

-- Q21 - Quel fleuve coule en France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quel fleuve coule en France ?',
        'La Seine, la Loire, le Rhône et la Garonne sont les principaux fleuves français. La Seine traverse Paris.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'La Seine', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'L''Amazone', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'Le Nil', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000015', 'Le Mississippi', FALSE, 3);

-- Q22 - Quelle ville est française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle ville est française ?',
        'Lyon, Marseille, Paris, Bordeaux, Toulouse, Lille, Strasbourg, Nantes... sont les grandes villes françaises.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Lyon', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Madrid', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Berlin', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000016', 'Rome', FALSE, 3);

-- Q23 - Quel océan borde la côte ouest française ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quel océan borde la côte ouest française ?',
        'L''océan Atlantique borde la côte ouest de la France. La côte sud est bordée par la mer Méditerranée.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''océan Atlantique', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''océan Pacifique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''océan Indien', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000017', 'L''océan Arctique', FALSE, 3);

-- Q24 - Qu'est-ce que Paris ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce que Paris ?',
        'Paris est la capitale de la France. C''est le siège du gouvernement, du Parlement et la plus grande ville du pays.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'La capitale de la France', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Un département d''outre-mer', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Un fleuve', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000018', 'Une chaîne de montagnes', FALSE, 3);

-- Q25 - Capitale de la France ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quelle est la capitale de la France ?',
        'Paris est la capitale de la France depuis le Moyen Âge. C''est la plus grande ville de France avec plus de 2 millions d''habitants.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Lyon', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Marseille', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000019', 'Bordeaux', FALSE, 3);

-- Q26 - Continent où se situe la France métropolitaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Sur quel continent se situe la France métropolitaine ?',
        'La France métropolitaine est située sur le continent européen, dans l''ouest de l''Europe.', TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Europe', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Afrique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Asie', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001a', 'L''Amérique', FALSE, 3);

-- Q27 - Quelle île est un département d'outre-mer ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle île est un département d''outre-mer français ?',
        'La Guadeloupe, la Martinique, La Réunion et Mayotte sont les îles départements d''outre-mer. La Guyane est aussi un DOM mais sur le continent sud-américain.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'La Réunion', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'Madagascar', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'L''Islande', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001b', 'Cuba', FALSE, 3);

-- Q28 - Combien y a-t-il de régions en France métropolitaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Combien y a-t-il de régions en France métropolitaine ?',
        'La France métropolitaine compte 13 régions depuis la réforme territoriale de 2016. Avec les 5 régions d''outre-mer, la France compte 18 régions au total.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '13 régions', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '22 régions', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '101 régions', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001c', '6 régions', FALSE, 3);

-- Q29 - Quelle ville est un grand port maritime ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle ville est un grand port maritime ?',
        'Marseille est le premier port maritime de France et un des plus grands de Méditerranée. Le Havre, Dunkerque et Bordeaux sont aussi des grands ports.',
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
        'Quelle est la mer au sud de la France métropolitaine ?',
        'La mer Méditerranée borde le sud de la France, de la frontière espagnole à la frontière italienne, en passant par Marseille, Nice et la Côte d''Azur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La Méditerranée', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer du Nord', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer Baltique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001e', 'La mer Caspienne', FALSE, 3);

-- Q31 - Ville au bord de la Méditerranée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quelle ville est située au bord de la mer Méditerranée ?',
        'Marseille, Nice, Toulon, Montpellier... Plusieurs grandes villes françaises sont situées sur la côte méditerranéenne.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Marseille', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Lille', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Strasbourg', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000001f', 'Rennes', FALSE, 3);

-- Q32 - Où se situe la Corse ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000020', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Où se situe la Corse ?',
        'La Corse est une île française située en mer Méditerranée, au sud de la France métropolitaine, à l''ouest de l''Italie.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'En mer Méditerranée', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'Dans l''océan Atlantique', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'En Manche', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000020', 'Dans la mer du Nord', FALSE, 3);

-- Q33 - Chaîne de montagnes entre la France et l'Italie ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000021', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Quelle chaîne de montagnes est située entre la France et l''Italie ?',
        'Les Alpes séparent la France de l''Italie. Le point culminant est le mont Blanc (4 808 m), plus haut sommet d''Europe occidentale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Alpes', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Pyrénées', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Le Massif central', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000021', 'Les Vosges', FALSE, 3);

-- ---------- CULTURE ----------

-- Q34 - Qui était Molière ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000022', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était Molière ?',
        'Molière (1622-1673) était un dramaturge et comédien français du XVIIe siècle. Il est l''auteur de comédies célèbres comme "L''Avare", "Le Misanthrope", "Tartuffe".',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un dramaturge français du XVIIe siècle',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un peintre italien', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un explorateur portugais', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000022', 'Un compositeur allemand', FALSE, 3);

-- Q35 - Qui était Charles Baudelaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000023', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était Charles Baudelaire ?',
        'Charles Baudelaire (1821-1867) est un poète français majeur du XIXe siècle, auteur des "Fleurs du Mal" (1857).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un poète français (XIXe siècle)', TRUE,
        0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un peintre impressionniste', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un scientifique', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000023', 'Un homme politique', FALSE, 3);

-- Q36 - Qui était George Sand ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000024', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était George Sand ?',
        'George Sand (1804-1876, vrai nom Aurore Dupin) était une romancière française du XIXe siècle. Elle est connue pour ses romans (La Mare au Diable, La Petite Fadette) et son engagement social.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une romancière française du XIXe siècle',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une chanteuse américaine', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une reine d''Angleterre', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000024', 'Une cinéaste italienne', FALSE, 3);

-- Q37 - Qui était Simone de Beauvoir ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000025', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était Simone de Beauvoir ?',
        'Simone de Beauvoir (1908-1986) était une philosophe, romancière et figure du féminisme français. Auteure du "Deuxième Sexe" (1949), texte fondateur du féminisme contemporain.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025',
        'Une philosophe et romancière française, figure du féminisme', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une danseuse de l''Opéra', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une chimiste belge', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000025', 'Une exploratrice polaire', FALSE, 3);

-- Q38 - Qui était Albert Camus ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000026', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était Albert Camus ?',
        'Albert Camus (1913-1960) était un écrivain et philosophe français, né en Algérie. Prix Nobel de littérature en 1957, auteur de "L''Étranger", "La Peste".',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026',
        'Un écrivain français (Prix Nobel de littérature 1957)', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un footballeur', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un peintre cubiste', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000026', 'Un industriel', FALSE, 3);

-- Q39 - Qui était Paul Cézanne ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000027', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était Paul Cézanne ?',
        'Paul Cézanne (1839-1906) était un peintre français post-impressionniste, originaire d''Aix-en-Provence. Considéré comme l''un des plus grands peintres modernes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un peintre français post-impressionniste',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un compositeur', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un explorateur', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000027', 'Un homme politique', FALSE, 3);

-- Q40 - Qui était Marc Chagall ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000028', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était Marc Chagall ?',
        'Marc Chagall (1887-1985) était un peintre français d''origine russe, l''un des plus grands artistes du XXe siècle. Il a notamment peint le plafond de l''Opéra Garnier de Paris.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un peintre français d''origine russe',
        TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un musicien anglais', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un sculpteur grec', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000028', 'Un cuisinier italien', FALSE, 3);

-- Q41 - Qui était Joséphine Baker ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-000000000029', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'NAT', 'CONNAISSANCE',
        'Qui était Joséphine Baker ?',
        'Joséphine Baker (1906-1975) était une artiste franco-américaine, danseuse et chanteuse, mais aussi résistante pendant la Seconde Guerre mondiale. Entrée au Panthéon en 2021.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029',
        'Une artiste, résistante, entrée au Panthéon en 2021', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une scientifique française', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une exploratrice', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-000000000029', 'Une religieuse', FALSE, 3);

-- Q42 - Qui était une chanteuse française célèbre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était une chanteuse française célèbre ?',
        'Édith Piaf (1915-1963) est une icône de la chanson française. Ses chansons "La Vie en rose", "Non, je ne regrette rien" sont mondialement célèbres.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Édith Piaf', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Madonna', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Maria Callas', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002a', 'Aretha Franklin', FALSE, 3);

-- Q43 - Qu'est-ce que le Louvre ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce que le Louvre ?',
        'Le Louvre est l''un des plus grands musées du monde, situé à Paris. Il abrite des œuvres majeures comme la Joconde, la Vénus de Milo, la Victoire de Samothrace.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un grand musée à Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un opéra', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Une bibliothèque universitaire', FALSE,
        2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002b', 'Un stade de football', FALSE, 3);

-- Q44 - Qui était Jean de La Fontaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Qui était Jean de La Fontaine ?',
        'Jean de La Fontaine (1621-1695) était un poète français du XVIIe siècle, célèbre pour ses Fables ("Le Corbeau et le Renard", "La Cigale et la Fourmi"...).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c',
        'Un poète français célèbre pour ses Fables', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un architecte', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un mathématicien', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002c', 'Un peintre', FALSE, 3);

-- Q45 - Quel écrivain est français ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CR', 'CONNAISSANCE',
        'Quel écrivain est français ?',
        'Victor Hugo (1802-1885) est l''un des plus grands écrivains français. Auteur des "Misérables", "Notre-Dame de Paris", il fut aussi homme politique et défenseur des droits humains.',
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
        'La tour Eiffel se trouve à Paris, sur le Champ-de-Mars. Construite par Gustave Eiffel pour l''Exposition universelle de 1889.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Paris', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Lyon', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Marseille', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002e', 'Bordeaux', FALSE, 3);

-- Q47 - Quand célèbre-t-on Noël ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f4000000-0000-0000-0000-00000000002f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000004', 'CSP', 'CONNAISSANCE',
        'Quand célèbre-t-on Noël ?',
        'Noël est célébré le 25 décembre. C''est une fête chrétienne, mais aussi un jour férié en France et une fête familiale célébrée par beaucoup de Français quelle que soit leur religion.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 25 décembre', TRUE, 0),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 1er janvier', FALSE, 1),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 31 octobre', FALSE, 2),
       (gen_random_uuid(), 'f4000000-0000-0000-0000-00000000002f', 'Le 14 février', FALSE, 3);
-- ============================================================================
-- THÈME 5 : Vivre dans la société française (31 questions)
-- ============================================================================

-- ---------- NUMÉROS D'URGENCE ----------

-- Q1 - Quel numéro d'urgence permet d'appeler le SAMU ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000001', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel numéro d''urgence permet d''appeler le SAMU ?',
        'Le 15 est le numéro du SAMU (Service d''Aide Médicale Urgente). Il s''appelle en cas d''urgence médicale grave (malaise, accident, blessure...).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 15', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 17', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 18', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000001', 'Le 112', FALSE, 3);

-- Q2 - Quel numéro d'urgence permet d'appeler les pompiers ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000002', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel numéro d''urgence permet d''appeler les pompiers ?',
        'Le 18 est le numéro des pompiers. Ils interviennent pour les incendies, les accidents, les secours d''urgence et les catastrophes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 18', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 15', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 17', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000002', 'Le 119', FALSE, 3);

-- Q3 - Qu'est-ce qu'un numéro d'urgence ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000003', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Qu''est-ce qu''un numéro d''urgence ?',
        'Un numéro d''urgence est un numéro gratuit que l''on peut appeler en cas de situation grave : 15 (SAMU), 17 (Police), 18 (Pompiers), 112 (numéro européen).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003',
        'Un numéro gratuit pour contacter les secours', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numéro personnel du président', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numéro de la mairie', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000003', 'Le numéro pour réserver un taxi', FALSE,
        3);

-- ---------- PERMIS DE CONDUIRE ----------

-- Q4 - Après avoir obtenu le permis, que faut-il faire pour conduire sa voiture ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000004', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Après avoir obtenu le permis de conduire, que faut-il faire pour pouvoir conduire sa voiture ?',
        'Après l''obtention du permis, il faut faire immatriculer son véhicule (carte grise) et le faire assurer obligatoirement (assurance auto au minimum responsabilité civile).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004',
        'Assurer son véhicule (l''assurance est obligatoire)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Rien, le permis suffit', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Demander une autorisation à la mairie',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000004', 'Passer un test médical chaque année',
        FALSE, 3);

-- ---------- MARIAGE & ÉTAT CIVIL ----------

-- Q5 - À quelles conditions un mariage est-il reconnu juridiquement ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000005', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'À quelles conditions un mariage est-il reconnu juridiquement en France ?',
        'Un mariage est juridiquement reconnu en France uniquement s''il est célébré par un officier d''état civil (le maire ou son adjoint) à la mairie. Les mariages religieux n''ont pas de valeur civile.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005',
        'S''il est célébré à la mairie par un officier d''état civil', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'S''il est célébré dans un lieu religieux',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'Si les parents donnent leur accord',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000005', 'S''il est annoncé dans le journal', FALSE,
        3);

-- Q6 - Quand faut-il déclarer son enfant à l'état civil ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000006', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Quand faut-il déclarer son enfant au service d''état civil de la mairie ?',
        'La déclaration de naissance doit être faite dans les 5 jours suivant la naissance (jour de l''accouchement non compris), à la mairie du lieu de naissance.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Dans les 5 jours après la naissance',
        TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Dans le mois qui suit', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Au premier anniversaire', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000006', 'Avant l''entrée à l''école', FALSE, 3);

-- ---------- TRAVAIL & EMPLOI ----------

-- Q7 - Le travail non déclaré est :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000007', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Le travail non déclaré est :',
        'Le travail non déclaré (travail au noir) est illégal. Il prive le travailleur de droits sociaux (chômage, retraite, sécurité sociale) et expose employeur et salarié à des sanctions.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Interdit et puni par la loi', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Autorisé pour les petits emplois', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Sans conséquence', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000007', 'Encouragé par l''État', FALSE, 3);

-- Q8 - Que doit faire un employeur pour fixer un salaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000008', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Que doit faire un employeur pour fixer un salaire ?',
        'L''employeur doit respecter le SMIC (salaire minimum légal) et la convention collective applicable. Le salaire ne peut être inférieur au SMIC.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Respecter au minimum le SMIC', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Décider seul du montant', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Payer ce que le salarié demande', FALSE,
        2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000008', 'Adapter le salaire au sexe du salarié',
        FALSE, 3);

-- Q9 - Qu'est-ce que le SMIC ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000009', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Qu''est-ce que le SMIC ?',
        'Le SMIC (Salaire Minimum Interprofessionnel de Croissance) est le salaire horaire minimum légal en dessous duquel un employeur ne peut pas payer un salarié.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Le salaire minimum légal en France', TRUE,
        0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Un impôt payé par les salariés', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Le nom d''une assurance', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000009', 'Une aide sociale pour les chômeurs',
        FALSE, 3);

-- Q10 - Première démarche pour chercher un emploi ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Quelle est la première démarche à réaliser pour chercher un emploi ?',
        'La première démarche est de s''inscrire à France Travail (anciennement Pôle Emploi). Cela permet de bénéficier d''un accompagnement et éventuellement d''indemnités de chômage.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'S''inscrire à France Travail', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'Attendre une convocation de l''État',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a',
        'Demander une autorisation à la préfecture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000a', 'Ouvrir un compte bancaire', FALSE, 3);

-- Q11 - Quelle est la durée légale du travail par semaine ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quelle est la durée légale du temps de travail par semaine ?',
        'La durée légale du temps de travail en France est de 35 heures par semaine pour un temps plein, depuis les lois Aubry de 2000.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '35 heures', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '40 heures', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '48 heures', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000b', '30 heures', FALSE, 3);

-- Q12 - Qui est aidé par France Travail ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Qui est aidé par France Travail ?',
        'France Travail (ex-Pôle Emploi) accompagne les demandeurs d''emploi : inscription, recherche d''emploi, indemnités, formation. Les entreprises peuvent également être aidées dans leurs recrutements.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les demandeurs d''emploi', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les retraités', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les élèves d''école primaire', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000c', 'Les touristes étrangers', FALSE, 3);

-- Q13 - Étranger en situation régulière peut créer son entreprise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Une personne étrangère en situation régulière peut créer son entreprise :',
        'Oui. Toute personne étrangère en situation régulière peut créer une entreprise en France, dans les mêmes conditions qu''un citoyen français.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d',
        'Oui, dans les mêmes conditions qu''un Français', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d', 'Non, c''est réservé aux Français', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d',
        'Oui, mais uniquement en s''associant à un Français', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000d', 'Oui, mais après 10 ans de résidence',
        FALSE, 3);

-- Q14 - Une femme peut-elle créer son entreprise ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
        'Une femme peut-elle créer son entreprise ?',
        'Oui. L''égalité hommes-femmes est un principe constitutionnel. Une femme peut créer son entreprise dans les mêmes conditions qu''un homme, sans autorisation particulière.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e',
        'Oui, dans les mêmes conditions qu''un homme', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Non, c''est réservé aux hommes', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Oui, avec l''autorisation de son mari',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000e', 'Oui, uniquement dans certains secteurs',
        FALSE, 3);

-- Q15 - À partir de quel âge un mineur peut-il travailler ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000000f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'À partir de quel âge un mineur peut-il travailler ?',
        'Un mineur peut travailler à partir de 16 ans (avec autorisation parentale). Dès 14 ans, il peut faire des petits travaux pendant les vacances scolaires sous conditions strictes.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f',
        'À partir de 16 ans (avec accord parental)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'À partir de 18 ans seulement', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'À partir de 12 ans', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000000f', 'À tout âge, sans restriction', FALSE, 3);

-- ---------- SANTÉ ----------

-- Q16 - Organisme pour rembourser les frais de santé ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000010', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Auprès de quel organisme faut-il demander le remboursement des frais de santé ?',
        'Les remboursements de frais de santé sont assurés par l''Assurance Maladie (CPAM - Caisse Primaire d''Assurance Maladie), qui fait partie de la Sécurité sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'L''Assurance Maladie (CPAM)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'La mairie', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'La préfecture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000010', 'France Travail', FALSE, 3);

-- Q17 - Accès aux soins : quelle proposition est correcte ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000011', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Concernant l''accès aux soins, quelle proposition est correcte ?',
        'L''accès aux soins est un droit en France. Le système de Sécurité sociale permet à toute personne résidant en France de bénéficier d''une prise en charge des frais de santé.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011',
        'Toute personne résidant en France a droit aux soins', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011', 'Seuls les Français ont accès aux soins',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011',
        'Les soins sont réservés aux personnes salariées', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000011', 'L''accès aux soins dépend de la religion',
        FALSE, 3);

-- Q18 - Problème de santé non urgent : à qui s'adresser ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000012', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'MISE_SITUATION',
        'En cas de problème de santé non urgent, à qui faut-il s''adresser en premier ?',
        'En cas de problème de santé non urgent, il faut consulter son médecin traitant. Il est le premier contact dans le parcours de soins et oriente si nécessaire vers un spécialiste.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'Au médecin traitant', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'Aux urgences de l''hôpital', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'À la police', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000012', 'À la mairie', FALSE, 3);

-- Q19 - Quel est le rôle du médecin traitant ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000013', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Quel est le rôle du médecin traitant ?',
        'Le médecin traitant est le premier contact pour les questions de santé. Il coordonne le parcours de soins, oriente vers les spécialistes et permet un meilleur remboursement par la Sécurité sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013',
        'Suivre la santé du patient et coordonner les soins', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Faire uniquement de la chirurgie', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Rembourser les soins', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000013', 'Vendre des médicaments', FALSE, 3);

-- Q20 - Quand se rendre aux urgences de l'hôpital ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000014', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Dans quelles situations doit-on se rendre aux urgences de l''hôpital ?',
        'Les urgences sont réservées aux situations graves et imminentes : accident, malaise grave, hémorragie, douleur intense, perte de conscience. Pour les soins non urgents, voir un médecin traitant.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014',
        'Pour une urgence vitale ou un accident grave', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour un simple rhume', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour faire renouveler une ordonnance',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000014', 'Pour un contrôle de routine', FALSE, 3);

-- Q21 - Objectif des vaccinations obligatoires ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000015', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Quel est l''objectif des vaccinations obligatoires ?',
        'Les vaccinations obligatoires protègent l''enfant contre certaines maladies graves et évitent leur propagation. En France, 11 vaccins sont obligatoires pour les enfants nés depuis 2018.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015',
        'Protéger la santé individuelle et collective', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Rapporter de l''argent à l''État', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Réduire le nombre de naissances', FALSE,
        2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000015', 'Empêcher les enfants d''aller à l''école',
        FALSE, 3);

-- Q22 - À quoi sert la carte Vitale ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000016', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'À quoi sert la carte Vitale ?',
        'La carte Vitale est la carte d''assuré social. Elle permet de bénéficier des remboursements de l''Assurance Maladie en attestant des droits à la Sécurité sociale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'À être remboursé de ses frais de santé',
        TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'À voter aux élections', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'À passer les frontières', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000016', 'À retirer de l''argent au distributeur',
        FALSE, 3);

-- Q23 - À quoi sert une mutuelle santé ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000017', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'À quoi sert une mutuelle santé ?',
        'La mutuelle (complémentaire santé) rembourse la partie des frais de santé qui n''est pas prise en charge par la Sécurité sociale. Elle est facultative mais fortement recommandée.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017',
        'À compléter les remboursements de la Sécurité sociale', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017',
        'À remplacer entièrement la Sécurité sociale', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017', 'À assurer la voiture', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000017', 'À payer les impôts', FALSE, 3);

-- ---------- ÉCOLE ----------

-- Q24 - Jusqu'à quel âge l'école est-elle obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000018', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Jusqu''à quel âge l''école est-elle obligatoire ?',
        'L''instruction est obligatoire de 3 à 16 ans en France (depuis 2019, l''âge d''entrée a été abaissé à 3 ans, contre 6 ans auparavant).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''à 16 ans', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''à 12 ans', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''à 18 ans', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000018', 'Jusqu''à 21 ans', FALSE, 3);

-- Q25 - L'autorité parentale prévoit l'obligation :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-000000000019', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'L''autorité parentale prévoit l''obligation :',
        'L''autorité parentale impose aux parents de protéger, éduquer, instruire et assurer l''entretien de leurs enfants jusqu''à leur majorité (18 ans).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019',
        'De protéger, nourrir, éduquer et instruire les enfants', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De choisir un métier pour ses enfants',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De marier ses enfants', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-000000000019', 'De rendre les enfants très riches', FALSE,
        3);

-- Q26 - Pour qui l'école est-elle obligatoire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001a', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Pour qui l''école est-elle obligatoire ?',
        'L''instruction est obligatoire pour tous les enfants de 3 à 16 ans résidant en France, qu''ils soient français ou étrangers, en situation régulière ou non.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a',
        'Pour tous les enfants de 3 à 16 ans en France', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les enfants français',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les garçons', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001a', 'Uniquement pour les enfants pauvres',
        FALSE, 3);

-- Q27 - Quel diplôme obtient-on à la fin du lycée ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001b', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CSP', 'CONNAISSANCE',
        'Quel diplôme obtient-on à la fin du lycée ?',
        'À la fin du lycée, les élèves passent le baccalauréat (le "bac"), diplôme qui sanctionne la fin des études secondaires et permet de poursuivre dans l''enseignement supérieur.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le baccalauréat (bac)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le brevet', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'La licence', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001b', 'Le master', FALSE, 3);

-- Q28 - Établissements après l'école élémentaire ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001c', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Dans quels établissements scolaires vont les élèves après l''école élémentaire ?',
        'Après l''école élémentaire (jusqu''au CM2), les élèves vont au collège (6e à 3e), puis au lycée (2de, 1re, terminale).',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'Au collège', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'À l''université', FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'En maternelle', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001c', 'Directement au travail', FALSE, 3);

-- Q29 - Pour qui l'école est-elle obligatoire (variante) ?
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001d', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Pour qui l''école est-elle obligatoire ?',
        'L''école est obligatoire pour tous les enfants résidant sur le territoire français, quelle que soit leur nationalité ou la situation administrative de leurs parents.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d',
        'Pour tous les enfants, sans distinction de nationalité', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d', 'Seulement pour les enfants nés en France',
        FALSE, 1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d', 'Seulement pour les enfants de salariés',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001d',
        'Seulement pour les enfants de plus de 6 ans', FALSE, 3);

-- Q30 - Un enfant inscrit à l'école :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001e', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
        'Un enfant inscrit à l''école :',
        'Un enfant inscrit à l''école doit la fréquenter de manière régulière. L''assiduité est obligatoire. Les absences injustifiées peuvent être sanctionnées.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e',
        'Doit y aller régulièrement (assiduité obligatoire)', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'Peut y aller quand il le souhaite', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'N''est pas tenu de suivre les cours',
        FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001e', 'Peut choisir lui-même ses matières',
        FALSE, 3);

-- Q31 - Les enfants qui ne parlent pas français :
INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active)
VALUES ('f5000000-0000-0000-0000-00000000001f', 'CIVIQUE',
        '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
        'Les enfants qui ne parlent pas français :',
        'Les enfants qui ne parlent pas français sont accueillis à l''école dans des dispositifs adaptés (UPE2A - Unité Pédagogique pour Élèves Allophones Arrivants) pour apprendre le français et suivre une scolarité normale.',
        TRUE);
INSERT INTO choices (id, question_id, label, is_correct, display_order)
VALUES (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f',
        'Sont accueillis à l''école avec un soutien adapté pour apprendre le français', TRUE, 0),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f', 'Ne peuvent pas aller à l''école', FALSE,
        1),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f',
        'Doivent attendre de parler français pour y aller', FALSE, 2),
       (gen_random_uuid(), 'f5000000-0000-0000-0000-00000000001f', 'Sont renvoyés dans leur pays d''origine',
        FALSE, 3);