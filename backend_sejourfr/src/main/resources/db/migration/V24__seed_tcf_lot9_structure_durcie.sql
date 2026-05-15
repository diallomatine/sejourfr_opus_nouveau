-- ============================================================================
-- V23 : Lot 9 TCF — STRUCTURE A2/B1/B2 avec distracteurs durcis
-- ============================================================================
-- 📋 24 questions STRUCTURE :
--    - 8 questions A2 (grammaire de base)
--    - 8 questions B1 (modes, temps, pronoms intermédiaires)
--    - 8 questions B2 (subjonctif, concordance, structures complexes)
--
-- 🎯 Toutes appliquent les nouvelles règles de durcissement STRUCTURE :
--    - Distracteurs grammaticalement plausibles (jamais absurdes)
--    - Stratégies : forme valide ailleurs, confusion mode/temps,
--                   accord erroné, faux ami grammatical
--    - A2 : 1 piégeux + 1 plausible + 1 évident
--    - B1 : 2 piégeux sur 3 (formes proches)
--    - B2 : 3 distracteurs tous plausibles
--
-- 📊 Points grammaticaux couverts :
--    A2 : présent irréguliers, passé composé être/avoir, futur proche,
--         négation, articles, accord adjectifs, prépositions, pronoms COD/COI
--    B1 : imparfait vs passé composé, futur simple, conditionnel,
--         pronoms relatifs (qui/que/où), accord participe avoir,
--         expressions de temps, comparatifs, gérondif
--    B2 : subjonctif (opinion/sentiment), concordance des temps,
--         pronoms relatifs complexes (dont/lequel), participe passé COD,
--         voix passive, discours indirect, hypothèse, connecteurs
-- ============================================================================


-- ============================================================================
-- ❓ QUESTIONS STRUCTURE A2 (8)
-- ============================================================================
-- Plage UUID : 55555555-0023-0000-0000-0000000000XX

-- ──────────────────────────────────────────────────────────────────────────
-- Q1 (A2) : Présent irrégulier — verbe "venir"
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_present_verbes_irreguliers',
    'Complétez avec la forme correcte du verbe au présent : Mes parents ___ d''Espagne pour Noël.',
    'Le sujet « mes parents » est à la 3e personne du pluriel : « viennent ». La réponse B est correcte. « Vient » est la 3e personne du singulier : c''est un faux ami grammatical (la racine est juste, mais l''accord est faux). « Veulent » est le verbe « vouloir » conjugué, un piège sémantique. « Venir » est l''infinitif, jamais conjugué après un sujet.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000001', 'vient',     false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000001', 'viennent',  true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000001', 'veulent',   false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000001', 'venir',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q2 (A2) : Passé composé avec être — verbe de mouvement
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_passe_compose_etre',
    'Complétez avec la forme correcte : Marie ___ à Paris la semaine dernière.',
    'Le verbe « aller » se conjugue avec « être » au passé composé : « est allée ». Avec « être », le participe passé s''accorde avec le sujet : Marie (féminin singulier) → « allée ». La réponse C est correcte. « A allé » est piégeux : un francophone débutant peut confondre les auxiliaires, mais « aller » exige « être ». « Est allé » est piégeux aussi : auxiliaire correct mais accord oublié (Marie est féminin). « Allée » seul n''est pas un verbe conjugué.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000002', 'a allé',      false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000002', 'est allé',    false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000002', 'est allée',   true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000002', 'allée',       false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q3 (A2) : Futur proche
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_futur_proche',
    'Complétez avec le futur proche : Demain, nous ___ visiter le musée du Louvre.',
    'Le futur proche se construit avec « aller » au présent + infinitif. Avec « nous » : « allons » + « visiter ». La réponse B est correcte. « Vont » est piégeux : c''est la 3e personne du pluriel, pas la 1ère (« nous »). « Allions » est l''imparfait, ce qui est passé. « Aller visiter » avec l''auxiliaire à l''infinitif est incorrect : il faut conjuguer « aller ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000003', 'vont',           false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000003', 'allons',         true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000003', 'allions',        false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000003', 'aller',          false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q4 (A2) : Négation
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_negation',
    'Mettez la phrase à la forme négative : Je mange du pain.',
    'À la négation, « du » devient « de » devant la chose niée : « Je ne mange pas de pain ». La réponse C est correcte. « Je ne mange pas du pain » est un piège classique : la négation impose « de » au lieu de « du ». « Je mange pas de pain » manque le « ne » de la négation soutenue. « Je ne mange du pas pain » est une inversion absurde.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000004', 'Je ne mange pas du pain',  false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000004', 'Je mange pas de pain',     false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000004', 'Je ne mange pas de pain',  true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000004', 'Je ne mange du pas pain',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q5 (A2) : Articles définis/indéfinis
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_articles',
    'Complétez avec l''article correct : J''aime ___ café, mais ce matin je vais boire ___ thé.',
    'Avec « aimer » on utilise l''article défini (sens général) : « le café ». Pour boire ce matin (sens spécifique, une fois), on utilise le partitif : « du thé ». La réponse B est correcte. « du café... le thé » inverse les deux constructions. « le café... un thé » est piégeux car « un thé » est possible dans d''autres contextes, mais ici on parle de la matière à boire. « un café... le thé » accumule les deux erreurs.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000005', 'du café... le thé',  false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000005', 'le café... du thé',  true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000005', 'le café... un thé',  false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000005', 'un café... le thé',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q6 (A2) : Accord adjectif
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_accord_adjectif',
    'Complétez avec l''adjectif au bon accord : Les fleurs ___ sentent très bon dans le jardin.',
    'L''adjectif « blanc » s''accorde avec « les fleurs » (féminin pluriel) → « blanches ». La réponse C est correcte. « Blanc » est le masculin singulier : il ne s''accorde pas. « Blancs » est le masculin pluriel : faux ami orthographique très proche de la bonne réponse. « Blanche » est le féminin singulier : accord en genre correct mais pas en nombre.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000006', 'blanc',      false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000006', 'blancs',     false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000006', 'blanches',   true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000006', 'blanche',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q7 (A2) : Prépositions de lieu (pays)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_prepositions_lieu',
    'Complétez avec la préposition correcte : Cet été, ma sœur va voyager ___ Portugal et ___ Italie.',
    'Devant un pays masculin commençant par une consonne, on utilise « au » : « au Portugal ». Devant un pays féminin, on utilise « en » : « en Italie ». La réponse C est correcte. « En Portugal... en Italie » est un piège classique : la même préposition pour les deux pays est tentante, mais « Portugal » est masculin. « Au Portugal... au Italie » applique « au » partout, ignorant le genre féminin d''« Italie ». « À Portugal... à Italie » utilise la préposition réservée aux villes.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000007', 'en... en',  false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000007', 'au... au',  false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000007', 'au... en',  true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000007', 'à... à',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q8 (A2) : Pronom COD
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_pronoms_cod_coi',
    'Remplacez « ce livre » par le pronom correct : Je lis ce livre → Je ___ lis.',
    '« Ce livre » est un complément d''objet direct masculin singulier → le pronom COD est « le ». La réponse C est correcte. « Lui » est un pronom COI (complément d''objet indirect), utilisé pour des personnes avec une préposition. « La » est le COD féminin singulier (« la maison »). « Y » remplace un complément de lieu (« à Paris ») ou introduit par « à » pour une chose.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000008', 'lui',  false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000008', 'la',   false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000008', 'le',   true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000008', 'y',    false, 4);


-- ============================================================================
-- ❓ QUESTIONS STRUCTURE B1 (8)
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- Q9 (B1) : Imparfait vs passé composé
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_imparfait_passe_compose',
    'Complétez avec le temps qui convient : Quand je ___ jeune, je ___ tous les étés à la mer.',
    'Pour décrire une habitude au passé, on utilise l''imparfait : « étais » (état) + « allais » (action répétée). La réponse C est correcte. « Ai été... ai allé » mélange le passé composé (action ponctuelle) pour deux verbes : ça décrirait une seule fois. « Étais... suis allé » mixe imparfait et passé composé : le second verbe devrait aussi être à l''imparfait pour l''habitude. « Étais... ai été » contient deux erreurs : le second verbe devrait être « aller » et à l''imparfait.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000009', 'ai été... ai allé',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000009', 'étais... suis allé',      false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000009', 'étais... allais',         true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000009', 'étais... ai été',         false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q10 (B1) : Futur simple
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_futur_simple',
    'Complétez avec le futur simple : Quand tu ___ à Paris, n''oublie pas de visiter le Louvre.',
    'Avec « quand » suivi d''un futur dans la principale (« n''oublie pas »), le verbe est au futur simple : « viendras ». La réponse B est correcte. « Viens » est le présent : ne respecte pas la concordance du futur. « Es venu » est le passé composé : action déjà accomplie. « Venais » est l''imparfait : action passée habituelle. Le piège classique en B1 : après « quand » de sens futur, on utilise le futur (pas le présent comme en anglais).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000010', 'viens',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000010', 'viendras',    true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000010', 'es venu',     false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000010', 'venais',      false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q11 (B1) : Conditionnel présent (politesse)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_conditionnel_present',
    'Complétez avec la forme la plus polie : Bonjour, je ___ un café, s''il vous plaît.',
    'Au restaurant ou dans un commerce, on utilise le conditionnel pour faire une demande polie : « voudrais ». La réponse C est correcte. « Veux » est le présent : grammaticalement correct mais brusque, peu poli. « Voulais » est l''imparfait : utilisable mais moins courant dans cette situation. « Aurais voulu » est le conditionnel passé : c''est trop fort, on l''utilise pour exprimer un regret. Le piège : tous sont grammaticaux, seul le conditionnel présent est adapté à la situation.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000011', 'veux',           false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000011', 'voulais',        false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000011', 'voudrais',       true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000011', 'aurais voulu',   false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q12 (B1) : Pronoms relatifs simples (qui / que / où)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_relatif_simple',
    'Complétez avec le pronom relatif correct : C''est le livre ___ j''ai acheté hier à la librairie.',
    'Le pronom relatif remplace « le livre » qui est COD du verbe « acheté » → « que ». La réponse B est correcte. « Qui » est sujet : il faudrait que le livre fasse l''action, or ici c''est moi qui ai acheté. « Où » indique un lieu ou un temps : aucun des deux ici. « Dont » remplace un complément introduit par « de » (j''ai parlé du livre → dont j''ai parlé). Le piège fréquent en B1 : confondre qui (sujet) et que (objet).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000012', 'qui',  false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000012', 'que',  true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000012', 'où',   false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000012', 'dont', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q13 (B1) : Accord du participe passé avec avoir
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_accord_participe_avoir',
    'Complétez avec l''accord correct : Les chansons que j''ai ___ hier étaient magnifiques.',
    'Avec l''auxiliaire « avoir », le participe passé s''accorde avec le COD s''il est placé AVANT le verbe. Ici, « les chansons » (féminin pluriel) est antéposé au verbe → « écoutées ». La réponse C est correcte. « Écouté » est le masculin singulier (forme par défaut quand pas d''accord). « Écoutés » est le masculin pluriel : faux genre. « Écoutée » est le féminin singulier : faux nombre. Ce point est typiquement B1.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000013', 'écouté',     false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000013', 'écoutés',    false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000013', 'écoutées',   true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000013', 'écoutée',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q14 (B1) : Expression de temps (depuis / il y a / pendant)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_expressions_temps',
    'Complétez avec l''expression de temps correcte : Pierre habite à Lyon ___ trois ans, et il s''y plaît beaucoup.',
    'Pour exprimer une action commencée dans le passé et qui continue dans le présent, on utilise « depuis ». La réponse C est correcte. « Il y a » s''utilise pour une action terminée à un moment précis du passé (« il y a 3 ans, il a déménagé »). « Pendant » exprime une durée terminée (« il a habité à Lyon pendant 3 ans, puis il est parti »). « Pour » exprime une durée prévue dans le futur (« il part à Lyon pour 3 ans »).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000014', 'il y a',     false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000014', 'pendant',    false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000014', 'depuis',     true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000014', 'pour',       false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q15 (B1) : Superlatif
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_superlatif',
    'Complétez avec le superlatif correct : Marie est ___ étudiante de la classe.',
    'Le superlatif de supériorité se construit avec « la plus + adjectif » devant un nom féminin singulier. La réponse B est correcte. « La meilleur » est piégeux : « meilleur » est le superlatif de « bon », mais l''accord féminin manque (il faut « la meilleure »). « Plus bonne » est incorrect : « bonne » devient « meilleure » au superlatif. « Très intelligente » exprime un haut degré mais n''est pas un superlatif (pas de comparaison avec un groupe).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000015', 'la meilleur',           false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000015', 'la plus intelligente',  true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000015', 'la plus bonne',         false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000015', 'très intelligente',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q16 (B1) : Gérondif
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_gerondif',
    'Complétez avec le gérondif : Il écoute la radio ___ sa voiture.',
    'Le gérondif exprime la simultanéité avec « en + participe présent ». Forme : « en + radical + -ant ». Pour « conduire » → « en conduisant ». La réponse B est correcte. « En conduit » mélange « en » avec le participe passé : forme inexistante. « Conduisant » sans « en » est un participe présent : il faudrait une virgule et un sens différent. « À conduire » avec l''infinitif est une autre construction (« il a appris à conduire ») qui ne convient pas ici.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000016', 'en conduit',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000016', 'en conduisant',    true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000016', 'conduisant',       false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000016', 'à conduire',       false, 4);


-- ============================================================================
-- ❓ QUESTIONS STRUCTURE B2 (8)
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- Q17 (B2) : Subjonctif après expression de sentiment
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_subjonctif_sentiment',
    'Complétez avec le mode correct : Je suis vraiment heureux que tu ___ venir à mon anniversaire.',
    'Après une expression de sentiment comme « être heureux que », on utilise le subjonctif. Le subjonctif présent de « pouvoir » à la 2e personne singulier est « puisses ». La réponse C est correcte. « Peux » est l''indicatif présent, jamais après « être heureux que ». « Pourras » est le futur, écarté par la règle du subjonctif. « Pourrais » est le conditionnel, lui aussi incompatible. Les trois distracteurs sont des formes valides du verbe mais pas dans ce contexte.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000017', 'peux',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000017', 'pourras',    false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000017', 'puisses',    true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000017', 'pourrais',   false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q18 (B2) : Concordance des temps au passé
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_concordance_temps',
    'Complétez avec le temps qui respecte la concordance : Elle m''a dit qu''elle ___ son examen la veille.',
    'En discours indirect au passé, un passé composé devient plus-que-parfait : « avait passé » (action antérieure à « a dit »). La réponse C est correcte. « A passé » est le passé composé : il faudrait que les deux actions soient au même niveau temporel, ce qui n''est pas le cas. « Passait » est l''imparfait : décrit une habitude ou une action en cours, pas une action accomplie avant. « Passerait » est le conditionnel, utilisé pour le futur dans le passé, mais « la veille » indique le passé.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000018', 'a passé',        false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000018', 'passait',        false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000018', 'avait passé',    true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000018', 'passerait',      false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q19 (B2) : Pronom relatif complexe (dont)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_pronom_relatif_dont',
    'Complétez avec le pronom relatif correct : C''est l''auteur ___ je vous ai parlé hier soir.',
    'Le verbe « parler » se construit avec « de » : « parler DE quelqu''un ». Le pronom relatif qui reprend un complément introduit par « de » est « dont ». La réponse B est correcte. « Que » remplace un COD, or « parler » prend un COI. « À qui » s''utilise avec un verbe à préposition « à » (« parler à quelqu''un » est aussi possible, mais le contexte « je vous ai parlé » + d''auteur favorise le sens de « parler de »). « Auquel » s''utilise pour un référent introduit par « à » (« je pense à cet auteur → auquel »).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000019', 'que',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000019', 'dont',      true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000019', 'à qui',     false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000019', 'auquel',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q20 (B2) : Participe passé avec COD antéposé (pronom)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_accord_participe_cod_antepose',
    'Complétez avec l''accord correct : Tes clés ? Je les ai ___ sur la table de la cuisine.',
    'Avec l''auxiliaire « avoir », le participe passé s''accorde avec le COD si celui-ci est antéposé. « Les » remplace « tes clés » (féminin pluriel), antéposé au verbe → « posées ». La réponse C est correcte. « Posé » est la forme par défaut (masculin singulier) : oubli total d''accord. « Posés » accorde au masculin pluriel : faux genre. « Posée » accorde au féminin singulier : faux nombre. Ce point est un classique du B2 : il exige d''identifier le pronom COD et son genre/nombre.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000020', 'posé',      false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000020', 'posés',     false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000020', 'posées',    true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000020', 'posée',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q21 (B2) : Voix passive au passé composé
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_voix_passive',
    'Transformez à la voix passive : Le directeur a signé la lettre.',
    'À la voix passive, le COD devient sujet, et l''auxiliaire « être » se met au temps du verbe actif (passé composé → « a été »). Le participe passé s''accorde avec le nouveau sujet : « la lettre » (féminin singulier) → « signée ». La réponse C est correcte. « La lettre a signé par le directeur » est une transformation erronée : le sujet ne peut pas « signer » lui-même. « La lettre est signée par le directeur » est au présent (l''action serait actuelle). « La lettre était signée par le directeur » est à l''imparfait (action passée habituelle ou état).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000021', 'La lettre a signé par le directeur',            false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000021', 'La lettre est signée par le directeur',         false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000021', 'La lettre a été signée par le directeur',       true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000021', 'La lettre était signée par le directeur',       false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q22 (B2) : Hypothèse irréelle au passé (si + plus-que-parfait)
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_hypothese_irreelle_passe',
    'Complétez l''hypothèse irréelle au passé : Si nous ___ plus tôt, nous n''aurions pas raté le train.',
    'L''hypothèse irréelle au passé suit la structure « si + plus-que-parfait » → « conditionnel passé ». Avec « partir » : « si nous étions partis ». La réponse C est correcte. « Partions » est l''imparfait : utilisé pour l''hypothèse irréelle au présent (« si nous partions plus tôt, nous ne raterions pas »). « Étions parti » oublie l''accord pluriel sur « partis ». « Sommes partis » est le passé composé, jamais utilisé après « si » d''hypothèse.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000022', 'partions',         false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000022', 'étions parti',     false, 2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000022', 'étions partis',    true,  3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000022', 'sommes partis',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q23 (B2) : Connecteur logique de conséquence
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_connecteurs_logiques',
    'Complétez avec le connecteur logique qui convient : Il a beaucoup travaillé ; ___, il a réussi son concours haut la main.',
    'La deuxième proposition exprime la conséquence positive de la première. « Par conséquent » est le connecteur de conséquence le plus adapté à ce registre. La réponse B est correcte. « Cependant » exprime l''opposition : contraire au sens voulu. « En revanche » exprime aussi le contraste, incompatible. « Pour autant » introduit une nuance restrictive (« et pourtant »), opposée à la logique de la phrase. Le piège B2 : « par conséquent » et « en revanche » sont tous deux des connecteurs soutenus, mais expriment des relations opposées.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000023', 'cependant',         false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000023', 'par conséquent',    true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000023', 'en revanche',       false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000023', 'pour autant',       false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- Q24 (B2) : Subjonctif après opinion négative
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, is_active, created_at, updated_at
) VALUES (
    '55555555-0023-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_subjonctif_opinion_negative',
    'Complétez avec le mode correct : Je ne crois pas que cette solution ___ la meilleure pour résoudre le problème.',
    'Après un verbe d''opinion à la forme négative (« ne pas croire que »), on utilise le subjonctif. Le subjonctif présent de « être » à la 3e personne singulier est « soit ». La réponse B est correcte. « Est » est l''indicatif : utilisé uniquement après l''affirmation (« je crois que c''est la meilleure »). « Sera » est le futur de l''indicatif, incompatible avec le doute exprimé. « Serait » est le conditionnel, utilisé dans des constructions différentes. Ce point distingue le B2 du B1 : le subjonctif après doute/opinion négative.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000024', 'est',       false, 1),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000024', 'soit',      true,  2),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000024', 'sera',      false, 3),
    (gen_random_uuid(), '55555555-0023-0000-0000-000000000024', 'serait',    false, 4);
