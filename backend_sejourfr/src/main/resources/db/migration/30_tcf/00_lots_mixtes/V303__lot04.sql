-- ============================================================================
-- V12 : Lot 4 TCF — Compréhension écrite & Structure de la langue
-- ============================================================================
-- 📋 24 questions supplémentaires (4 par cellule × 6 cellules)
--    Suite de V9.1, V10 et V11 — nouveaux thèmes / nouveaux points
--
-- 🎯 Couverture par rapport aux lots précédents :
--    CE A2  : santé (pharmacie) + banque (carte bloquée)
--    CE B1  : travail (formation) + loisirs (réservation)
--    CE B2  : éducation (numérique à l''école) + mobilité urbaine
--    STR A2 : avoir présent, démonstratifs, fréquence, pluriel des noms
--    STR B1 : qui/que, depuis/il y a/pendant, si + présent → futur, COI
--    STR B2 : accord PP avec avoir + COD antéposé, double pronom,
--             registre soutenu, opposition (alors que)
--
-- ✅ Checklist appliquée :
--    1. Phrase grammaticalement correcte avec la bonne réponse insérée
--    2. Distracteurs strictement faux (raison précise pour chacun)
--    3. Explication sans pléonasme ni faute
--    4. Accents/caractères spéciaux vérifiés
--    5. Pas d'ambiguïté de genre/nombre du sujet
--    6. Consigne sans ambiguïté quand un point précis est visé
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES (table `passages`) — Plage V12 : 44444444-0012-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── A2 — passages courts ──────────
-- 💊 SMS pharmacie (A2)
(
    '44444444-0012-0000-0000-000000000001', 'TEXTE',
    E'Pharmacie du Centre\n\n' ||
    E'Bonjour, votre commande de médicaments est arrivée. Vous pouvez venir la retirer à partir de lundi, du lundi au samedi de 9h à 19h30. N''oubliez pas votre ordonnance et votre carte Vitale.\n\n' ||
    E'Merci et bonne journée.',
    '22222222-0000-0000-0000-000000000002'
),
-- 💳 E-mail banque (A2)
(
    '44444444-0012-0000-0000-000000000002', 'TEXTE',
    E'Cher client,\n\n' ||
    E'Nous vous informons que votre carte bancaire a été bloquée après trois tentatives de code incorrect. Pour la débloquer, merci de vous présenter à votre agence avec une pièce d''identité. Vous pouvez également nous appeler au numéro indiqué au dos de votre carte.\n\n' ||
    E'Service client',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B1 — passages moyens ──────────
-- 💼 Offre de formation (B1)
(
    '44444444-0012-0000-0000-000000000003', 'TEXTE',
    E'Le centre de formation Avenir propose, à partir de septembre, une nouvelle formation gratuite en développement web destinée aux personnes en reconversion professionnelle. D''une durée de six mois, elle alterne cours théoriques et projets pratiques en entreprise. Aucun diplôme préalable n''est exigé, mais une bonne motivation est indispensable. Les places étant limitées, les candidats sont sélectionnés sur entretien.',
    '22222222-0000-0000-0000-000000000002'
),
-- 🎭 Réservation événement (B1)
(
    '44444444-0012-0000-0000-000000000004', 'TEXTE',
    E'Madame, Monsieur,\n\n' ||
    E'Nous vous confirmons votre réservation pour le concert du samedi 18 octobre à 20h30, salle Pleyel. Deux places sont enregistrées à votre nom, au tarif réduit étudiant. Vos billets électroniques vous seront envoyés par courriel 48 heures avant l''événement. En cas d''empêchement, le remboursement est possible jusqu''à dix jours avant la date.\n\n' ||
    E'Cordialement,\nLe service billetterie',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B2 — passages longs ──────────
-- 📱 Numérique à l'école (B2)
(
    '44444444-0012-0000-0000-000000000005', 'TEXTE',
    E'L''introduction du numérique dans les écoles divise toujours autant. D''un côté, ses partisans soulignent les bénéfices d''un apprentissage personnalisé, capable de s''adapter au rythme de chaque élève, et l''accès facilité à des ressources variées. De l''autre, des enseignants et des spécialistes s''inquiètent d''une baisse de la concentration, d''un appauvrissement de l''écriture manuscrite et d''une dépendance précoce aux écrans. Les études disponibles peinent à trancher : tout dépendrait, en réalité, des usages que l''on en fait et de l''accompagnement proposé. Plutôt qu''un débat caricatural pour ou contre, sans doute faudrait-il s''interroger sur les conditions concrètes d''une intégration réfléchie.',
    '22222222-0000-0000-0000-000000000002'
),
-- 🚲 Mobilité urbaine (B2)
(
    '44444444-0012-0000-0000-000000000006', 'TEXTE',
    E'Les grandes villes françaises repensent progressivement leur mobilité. Pistes cyclables élargies, zones limitées à 30 km/h, fermeture de certaines artères aux voitures : autant de mesures qui visent à réduire la pollution et à apaiser l''espace public. Si les habitants semblent globalement favorables à ces évolutions, certaines catégories, en particulier les commerçants et les automobilistes pendulaires, expriment des réserves. Les premiers redoutent une baisse de leur clientèle, les seconds une complexification de leurs trajets quotidiens. Pour les municipalités, le défi consiste désormais à montrer, chiffres à l''appui, que ces craintes ne se vérifient pas toujours, et à accompagner les usagers les plus fragiles dans la transition.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 2. QUESTIONS — Plage V12 : 55555555-0012-*
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : CE A2 — Pharmacie (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_idee_principale',
    'Pourquoi la pharmacie envoie-t-elle ce message ?',
    'Le SMS commence par « votre commande de médicaments est arrivée. Vous pouvez venir la retirer » : il s''agit donc d''informer le client que ses médicaments sont disponibles. Le message ne propose pas de livraison, ne rappelle pas un rendez-vous et ne signale aucun problème de stock.',
    '44444444-0012-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000001', 'Pour proposer une livraison à domicile',          false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000001', 'Pour informer que les médicaments sont prêts',    true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000001', 'Pour rappeler un rendez-vous médical',             false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000001', 'Pour signaler une rupture de stock',               false, 4);

-- Q2 : CE A2 — Pharmacie (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Que doit apporter le client à la pharmacie ?',
    'Le SMS dit explicitement : « N''oubliez pas votre ordonnance et votre carte Vitale ». Les deux documents demandés sont donc l''ordonnance et la carte Vitale. Le message ne mentionne ni passeport, ni chèque, ni autres documents.',
    '44444444-0012-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000002', 'Son ordonnance et sa carte Vitale',         true,  1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000002', 'Son passeport et un chèque',                 false, 2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000002', 'Sa carte bancaire et un justificatif',       false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000002', 'Une lettre du médecin uniquement',           false, 4);

-- Q3 : CE A2 — Banque (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_idee_principale',
    'Que s''est-il passé pour la carte du client ?',
    'L''e-mail dit clairement : « votre carte bancaire a été bloquée après trois tentatives de code incorrect ». La carte est donc bloquée à cause du code. Elle n''a pas été volée, l''e-mail ne parle pas de péremption et pas non plus de découvert.',
    '44444444-0012-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000003', 'Elle a été volée',                                    false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000003', 'Elle a été bloquée à cause d''un mauvais code',        true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000003', 'Elle est arrivée à sa date d''expiration',             false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000003', 'Elle a été refusée pour découvert bancaire',           false, 4);

-- Q4 : CE A2 — Banque (reformulation)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reformulation',
    'Que peut faire le client pour débloquer sa carte ?',
    'L''e-mail propose deux options : « merci de vous présenter à votre agence avec une pièce d''identité. Vous pouvez également nous appeler au numéro indiqué au dos de votre carte. » Le client peut donc se rendre à l''agence ou appeler. Il n''est pas question de commander une nouvelle carte, ni d''envoyer un courrier, ni d''attendre passivement.',
    '44444444-0012-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000004', 'Commander immédiatement une nouvelle carte',      false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000004', 'Aller à son agence ou téléphoner à la banque',     true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000004', 'Envoyer un courrier postal au siège',              false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000004', 'Attendre que la carte se débloque toute seule',    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : STRUCT A2 — Verbe "avoir" au présent (3e pers. pluriel)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_present_avoir',
    'Complétez : « Mes amis ___ deux enfants. »',
    'Le verbe « avoir » est irrégulier au présent. À la 3e personne du pluriel (« ils/elles ») : « ils ont ». « Avent » n''existe pas. « Ai » est la 1re personne du singulier (j''ai). « Avez » est la 2e personne du pluriel (vous avez).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000005', 'avent', false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000005', 'ont',   true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000005', 'ai',    false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000005', 'avez',  false, 4);

-- Q6 : STRUCT A2 — Adjectif démonstratif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_adjectif_demonstratif',
    'Complétez : « Je vais acheter ___ chaussures, elles sont en solde. »',
    '« Chaussures » est un nom féminin pluriel. L''adjectif démonstratif au pluriel (masculin ou féminin) est « ces ». « Ce » s''emploie devant un masculin singulier (ce livre). « Cette » devant un féminin singulier (cette table). « Cet » devant un masculin singulier commençant par une voyelle ou un h muet (cet homme).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000006', 'ce',    false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000006', 'cette', false, 2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000006', 'ces',   true,  3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000006', 'cet',   false, 4);

-- Q7 : STRUCT A2 — Adverbe de fréquence
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_adverbe_frequence',
    'Complétez : « Je fais du sport ___ par semaine, le mardi et le jeudi. »',
    'La phrase précise que la personne fait du sport « le mardi et le jeudi », soit deux jours par semaine. La fréquence correcte est donc « deux fois ». « Toujours » signifie tout le temps (incompatible avec une fréquence chiffrée précise). « Jamais » est une négation. « Souvent » est vague et ne correspond pas à la précision « le mardi et le jeudi ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000007', 'toujours',   false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000007', 'deux fois',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000007', 'jamais',     false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000007', 'souvent',    false, 4);

-- Q8 : STRUCT A2 — Pluriel des noms (cas spécial -al)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_pluriel_noms',
    'Quel est le pluriel de « cheval » dans : « Dans cette ferme, il y a plusieurs ___. »',
    'Les noms masculins se terminant par « -al » forment généralement leur pluriel en « -aux ». « Cheval » → « chevaux ». « Chevals » ne respecte pas cette règle (forme inexistante). « Chevales » n''existe pas non plus. « Cheveux » est le pluriel de « cheveu » (poils sur la tête), pas de « cheval ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000008', 'chevals',  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000008', 'chevaux',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000008', 'chevales', false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000008', 'cheveux',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : CE B1 — Formation (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quelle est la durée de la formation ?',
    'Le texte indique : « D''une durée de six mois ». La formation dure donc six mois. Les autres durées (trois mois, un an, deux ans) ne sont pas mentionnées.',
    '44444444-0012-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000009', 'Trois mois',  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000009', 'Six mois',    true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000009', 'Un an',       false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000009', 'Deux ans',    false, 4);

-- Q10 : CE B1 — Formation (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Qui peut s''inscrire à cette formation ?',
    'Le texte précise que la formation est « destinée aux personnes en reconversion professionnelle » et que « aucun diplôme préalable n''est exigé ». Elle est donc ouverte aux personnes en reconversion, sans condition de diplôme. Elle n''est pas réservée aux jeunes, ni aux ingénieurs, et ne demande pas un master.',
    '44444444-0012-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000010', 'Uniquement les jeunes de moins de 25 ans',                       false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000010', 'Les personnes en reconversion, sans condition de diplôme',       true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000010', 'Seulement les ingénieurs déjà diplômés',                          false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000010', 'Les candidats ayant au moins un master',                          false, 4);

-- Q11 : CE B1 — Réservation (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Comment le destinataire recevra-t-il ses billets ?',
    'Le message indique : « Vos billets électroniques vous seront envoyés par courriel 48 heures avant l''événement. » Les billets sont donc envoyés par e-mail (courriel), et 48h avant. Ils ne sont ni envoyés par la poste, ni à retirer sur place, ni dans une enveloppe physique.',
    '44444444-0012-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000011', 'Par voie postale, une semaine avant',           false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000011', 'Par e-mail, 48 heures avant le concert',         true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000011', 'À retirer sur place le jour du concert',         false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000011', 'Dans une enveloppe à l''entrée de la salle',     false, 4);

-- Q12 : CE B1 — Réservation (reformulation)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
    'Jusqu''à quand le remboursement est-il possible ?',
    'Le message précise : « En cas d''empêchement, le remboursement est possible jusqu''à dix jours avant la date. » La limite est donc dix jours avant le concert. Le texte n''évoque ni un remboursement le jour même, ni 48 heures avant, ni une interdiction totale.',
    '44444444-0012-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000012', 'Le jour du concert',                  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000012', '48 heures avant l''événement',         false, 2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000012', 'Au plus tard dix jours avant',         true,  3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000012', 'Aucun remboursement n''est possible',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : STRUCT B1 — Pronom relatif "qui" (sujet) vs "que" (COD)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_relatif_qui_que',
    'Complétez : « Le livre ___ tu m''as offert est passionnant. »',
    'Dans la subordonnée relative, « tu » est sujet et « le livre » est COD du verbe « as offert » (tu as offert quoi ? le livre). Le pronom relatif qui remplace un COD est « que ». « Qui » remplacerait un sujet (le livre qui est sur la table). « Dont » remplace un complément introduit par « de ». « Où » remplace un complément de lieu ou de temps.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000013', 'qui',  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000013', 'que',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000013', 'dont', false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000013', 'où',   false, 4);

-- Q14 : STRUCT B1 — Distinction "depuis" / "il y a" / "pendant"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_depuis_il_y_a_pendant',
    'Complétez : « J''ai rencontré Marie ___ trois ans, dans un café. »',
    'L''action est ponctuelle et terminée (« j''ai rencontré ») : on situe le moment dans le passé avec « il y a ». « Depuis » indique une durée qui continue jusqu''au présent (incompatible avec une action ponctuelle au passé composé). « Pendant » indique une durée délimitée d''une action. « Pour » indique une durée prévue à l''avance.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000014', 'depuis',  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000014', 'il y a',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000014', 'pendant', false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000014', 'pour',    false, 4);

-- Q15 : STRUCT B1 — Hypothèse "si + présent → futur"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_hypothese_si_present',
    'Complétez : « Si tu travailles bien cette année, tu ___ ton examen sans difficulté. »',
    'La structure « si + présent » dans la subordonnée appelle un futur simple dans la principale → « auras ». « As » est un présent (incompatible avec une projection dans l''avenir). « Aurais » est un conditionnel (compatible avec « si + imparfait », pas « si + présent »). « Avais » est un imparfait.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000015', 'as',     false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000015', 'auras',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000015', 'aurais', false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000015', 'avais',  false, 4);

-- Q16 : STRUCT B1 — Pronom COI
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_coi',
    'Remplacez le complément : « Je téléphone à ma mère. → Je ___ téléphone. »',
    'Le verbe « téléphoner » se construit avec « à » : on téléphone À quelqu''un. « À ma mère » est donc un COI (complément d''objet indirect). Le pronom COI de la 3e personne du singulier (masculin ou féminin) est « lui ». « La » est un COD féminin singulier (je la vois). « Elle » est un pronom tonique (sujet ou complément après préposition). « Leur » est COI pluriel (à eux/à elles).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000016', 'la',    false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000016', 'lui',   true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000016', 'elle',  false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000016', 'leur',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : CE B2 — Numérique à l'école (position de l'auteur)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle position adopte l''auteur sur le numérique à l''école ?',
    'L''auteur conclut : « Plutôt qu''un débat caricatural pour ou contre, sans doute faudrait-il s''interroger sur les conditions concrètes d''une intégration réfléchie ». Il refuse donc le débat binaire et défend une approche pragmatique, attentive aux conditions d''usage. Il ne défend ni l''adoption massive, ni l''interdiction, ni l''idée que les études ont déjà tranché.',
    '44444444-0012-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000017', 'Il défend une adoption massive et immédiate',                       false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000017', 'Il appelle à dépasser le débat pour/contre et à penser les usages', true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000017', 'Il plaide pour une interdiction totale du numérique à l''école',    false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000017', 'Il considère que les études ont définitivement tranché la question', false, 4);

-- Q18 : CE B2 — Numérique à l'école (reformulation des critiques)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Quels inconvénients du numérique le texte évoque-t-il ?',
    'Le texte cite trois inquiétudes : « une baisse de la concentration, un appauvrissement de l''écriture manuscrite et une dépendance précoce aux écrans ». Le texte n''évoque ni l''absence d''équipement, ni un coût financier excessif, ni un problème de formation des enseignants comme tel.',
    '44444444-0012-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000018', 'Le manque d''équipement dans les écoles',                               false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000018', 'La concentration, l''écriture manuscrite et la dépendance aux écrans',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000018', 'Le coût financier prohibitif pour les familles',                         false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000018', 'L''insuffisance de la formation des enseignants',                        false, 4);

-- Q19 : CE B2 — Mobilité urbaine (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle est l''idée principale développée dans ce texte ?',
    'Le texte décrit les nouvelles politiques de mobilité urbaine, leur accueil globalement favorable, mais aussi les réserves de certaines catégories. Sa conclusion appelle les municipalités à « montrer, chiffres à l''appui, que ces craintes ne se vérifient pas toujours, et à accompagner les usagers les plus fragiles ». Le texte décrit donc une transformation en cours qui suscite des tensions à résoudre. Il ne dit ni qu''il y a un consensus, ni que les politiques échouent, ni que la voiture reste indispensable.',
    '44444444-0012-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000019', 'Les nouvelles politiques font l''unanimité dans la population',          false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000019', 'Une transformation en cours, qui crée des tensions à gérer',             true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000019', 'L''échec patent des politiques de mobilité durable',                     false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000019', 'La voiture individuelle reste irremplaçable en ville',                   false, 4);

-- Q20 : CE B2 — Mobilité urbaine (inférence sur les acteurs)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Que craignent les commerçants face à ces nouvelles mesures ?',
    'Le texte dit : « Les premiers [les commerçants] redoutent une baisse de leur clientèle ». Leur crainte porte donc sur leur activité économique. Le texte n''évoque ni la hausse de leurs charges, ni une concurrence en ligne, ni des problèmes de livraison.',
    '44444444-0012-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000020', 'Une hausse de leurs charges locatives',          false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000020', 'Une baisse de leur clientèle',                   true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000020', 'Une concurrence accrue des sites en ligne',       false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000020', 'Des difficultés croissantes pour se faire livrer', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : STRUCT B2 — Accord du participe passé avec "avoir" + COD antéposé
-- Sujet "je" + COD féminin singulier non ambigu (la lettre)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_accord_pp_avoir',
    'Complétez : « La lettre que j''ai ___ hier est arrivée ce matin. »',
    'Avec l''auxiliaire « avoir », le participe passé s''accorde avec le COD si celui-ci est placé avant le verbe. Ici, le COD « la lettre » (féminin singulier) est antéposé via le pronom relatif « que » : il faut donc accorder → « écrite ». « Écrit » serait correct si le COD était placé après le verbe ou s''il était masculin singulier. « Écrits » est un masculin pluriel, « écrites » un féminin pluriel : ni l''un ni l''autre ne correspond à « la lettre » (féminin singulier).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000021', 'écrit',    false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000021', 'écrite',   true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000021', 'écrits',   false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000021', 'écrites',  false, 4);

-- Q22 : STRUCT B2 — Double pronominalisation (le lui)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_double_pronom',
    'Remplacez : « Je donne le livre à mon frère. → Je ___ donne. »',
    'On remplace deux compléments : « le livre » (COD masculin singulier) → « le », et « à mon frère » (COI singulier) → « lui ». L''ordre est COD avant COI à la 3e personne : « le lui ». « Lui le » inverse cet ordre (incorrect). « Le leur » serait pour un COI pluriel (à eux). « La lui » mettrait un COD féminin (incorrect ici, le livre est masculin).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000022', 'lui le',  false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000022', 'le lui',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000022', 'le leur', false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000022', 'la lui',  false, 4);

-- Q23 : STRUCT B2 — Nuance lexicale (paronymes : éminent / imminent)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_paronymes',
    'Complétez : « La décision est ___ : le tribunal rendra son verdict dans les prochaines heures. »',
    'Le contexte (« dans les prochaines heures ») indique un événement très proche dans le temps : l''adjectif attendu est « imminente » (qui va arriver très bientôt). « Éminente » signifie remarquable, de haut rang (un professeur éminent), pas proche dans le temps. « Évidente » signifie claire, sans doute possible. « Permanente » signifie continue, durable.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000023', 'éminente',   false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000023', 'imminente',  true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000023', 'évidente',   false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000023', 'permanente', false, 4);

-- Q24 : STRUCT B2 — Opposition "alors que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0012-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_opposition_alors_que',
    'Complétez : « Mon frère adore la montagne, ___ moi, je préfère la mer. »',
    '« Alors que » introduit une opposition entre deux faits coexistants (deux préférences différentes). « Pour que » introduit un but (avec subjonctif). « Parce que » introduit une cause (la cause de quoi ?). « Si bien que » introduit une conséquence.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000024', 'pour que',    false, 1),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000024', 'alors que',   true,  2),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000024', 'parce que',   false, 3),
    (gen_random_uuid(), '55555555-0012-0000-0000-000000000024', 'si bien que', false, 4);
