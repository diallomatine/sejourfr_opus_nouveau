-- ============================================================================
-- V11 : Lot 3 TCF — Compréhension écrite & Structure de la langue
-- ============================================================================
-- 📋 24 questions supplémentaires (4 par cellule × 6 cellules)
--    Suite de V9.1 et V10 — nouveaux thèmes / points grammaticaux
--
-- 🎯 Couverture par rapport aux lots précédents :
--    CE A2  : logement (annonce voisinage) + consommation (publicité)
--    CE B1  : santé (prévention) + environnement (transition énergétique)
--    CE B2  : travail/inégalités + médias/désinformation
--    STR A2 : possessifs, présent irréguliers, prép. de temps, interrogation
--    STR B1 : conditionnel politesse, discours indirect présent, but, pronom y
--    STR B2 : subjonctif passé, voix passive impersonnelle, mise en relief,
--             avoir beau (concession)
--
-- ✅ Checklist appliquée :
--    1. Phrase grammaticalement correcte avec la bonne réponse insérée
--    2. Distracteurs strictement faux (raison précise pour chacun)
--    3. Explication sans pléonasme ni faute
--    4. Accents/caractères spéciaux vérifiés
--    5. Pas d'ambiguïté de genre/nombre du sujet
--    6. Consigne sans ambiguïté quand un point grammatical précis est visé
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES (table `passages`) — Plage V11 : 44444444-0011-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── A2 — passages courts ──────────
-- 🏠 Annonce voisinage (A2)
(
    '44444444-0011-0000-0000-000000000001', 'TEXTE',
    E'Avis aux résidents\n\n' ||
    E'Des travaux de peinture auront lieu dans les escaliers de l''immeuble du lundi 12 au vendredi 16 juin, entre 8h et 17h. Pendant cette période, merci de laisser l''ascenseur libre pour les ouvriers. L''entrée principale restera ouverte normalement.\n\n' ||
    E'Le syndic',
    '22222222-0000-0000-0000-000000000002'
),
-- 🛍️ Publicité supermarché (A2)
(
    '44444444-0011-0000-0000-000000000002', 'TEXTE',
    E'Grande promotion ce week-end !\n\n' ||
    E'Du vendredi au dimanche, profitez de 20% de réduction sur tous les fruits et légumes frais. Offre valable uniquement en magasin, sur présentation de votre carte de fidélité. Les produits surgelés et conserves ne sont pas concernés par cette offre.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B1 — passages moyens ──────────
-- 🩺 Campagne de prévention (B1)
(
    '44444444-0011-0000-0000-000000000003', 'TEXTE',
    E'Le ministère de la Santé lance ce mois-ci une nouvelle campagne pour encourager les adultes de plus de 50 ans à se faire dépister. Trop souvent diagnostiqués à un stade avancé, certains cancers pourraient être pris en charge bien plus tôt grâce à un test simple, gratuit et envoyé directement à domicile. Les médecins rappellent que le dépistage ne remplace pas un suivi médical régulier, mais qu''il en constitue un complément essentiel.',
    '22222222-0000-0000-0000-000000000002'
),
-- 🌱 Transition énergétique (B1)
(
    '44444444-0011-0000-0000-000000000004', 'TEXTE',
    E'De plus en plus de communes françaises s''engagent dans la transition énergétique. À Saint-Léonard, par exemple, le toit de l''école primaire a été équipé de panneaux solaires l''année dernière. Le bâtiment produit désormais une partie importante de son électricité, ce qui permet à la mairie d''économiser environ 4 000 euros par an. La municipalité envisage maintenant d''étendre l''installation à la salle des fêtes et au gymnase.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B2 — passages longs ──────────
-- 👔 Inégalités au travail (B2)
(
    '44444444-0011-0000-0000-000000000005', 'TEXTE',
    E'Malgré des décennies de discours volontaristes, l''écart salarial entre hommes et femmes peine à se résorber. Selon les dernières études, à poste et expérience équivalents, les femmes perçoivent encore en moyenne 9% de moins que leurs collègues masculins. Les explications sont multiples : autocensure dans la négociation, accès plus difficile aux postes à responsabilité, ou encore prise en charge majoritaire des contraintes familiales. Certaines entreprises pionnières expérimentent désormais la transparence salariale totale, mais cette pratique reste très minoritaire. Tant qu''elle ne se généralisera pas, il sera difficile d''espérer un véritable rattrapage.',
    '22222222-0000-0000-0000-000000000002'
),
-- 📰 Désinformation et réseaux sociaux (B2)
(
    '44444444-0011-0000-0000-000000000006', 'TEXTE',
    E'La diffusion massive de fausses informations sur les réseaux sociaux soulève des inquiétudes croissantes. Une étude récente montre qu''une rumeur fausse circule en moyenne six fois plus vite qu''une information vérifiée, en grande partie parce qu''elle suscite des réactions émotionnelles plus fortes. Les plateformes mettent en avant leurs outils de modération, mais celles-ci interviennent souvent après que les contenus ont atteint un large public. Renforcer l''éducation aux médias dès le plus jeune âge apparaît, aux yeux de nombreux spécialistes, comme une réponse plus durable que toute solution purement technique.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 2. QUESTIONS — Plage V11 : 55555555-0011-*
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : CE A2 — Voisinage (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Combien de temps dureront les travaux ?',
    'L''annonce dit « du lundi 12 au vendredi 16 juin », soit du lundi au vendredi inclus : cinq jours. Le texte ne mentionne ni un jour seul, ni le week-end, ni une durée d''un mois.',
    '44444444-0011-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000001', 'Une seule journée',          false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000001', 'Cinq jours, du lundi au vendredi', true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000001', 'Tout le week-end',           false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000001', 'Tout le mois de juin',       false, 4);

-- Q2 : CE A2 — Voisinage (reformulation)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reformulation',
    'Que demande le syndic aux résidents ?',
    'Le texte précise : « merci de laisser l''ascenseur libre pour les ouvriers ». La demande porte donc sur l''ascenseur. Le texte n''interdit pas l''accès à l''immeuble (l''entrée principale reste ouverte), ne demande pas de payer, et ne demande pas non plus d''aider les ouvriers.',
    '44444444-0011-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000002', 'De ne pas utiliser l''entrée principale',  false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000002', 'De laisser l''ascenseur libre',            true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000002', 'De payer une participation aux travaux',  false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000002', 'D''aider les ouvriers',                   false, 4);

-- Q3 : CE A2 — Publicité magasin (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Sur quels produits porte la promotion ?',
    'La publicité dit clairement : « 20% de réduction sur tous les fruits et légumes frais ». La promotion porte donc sur les fruits et légumes. Le texte précise même que « les produits surgelés et conserves ne sont pas concernés ».',
    '44444444-0011-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000003', 'Les produits surgelés',         false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000003', 'Les fruits et légumes frais',   true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000003', 'Les conserves',                 false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000003', 'Tous les produits du magasin',  false, 4);

-- Q4 : CE A2 — Publicité magasin (condition)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quelle condition est nécessaire pour bénéficier de la réduction ?',
    'La publicité précise : « Offre valable uniquement en magasin, sur présentation de votre carte de fidélité ». La carte de fidélité est donc obligatoire. Le texte ne demande ni un achat minimum, ni une commande en ligne, ni une inscription par téléphone.',
    '44444444-0011-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000004', 'Acheter pour plus de 50 euros',        false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000004', 'Présenter sa carte de fidélité',       true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000004', 'Commander en ligne',                   false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000004', 'S''inscrire par téléphone',            false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : STRUCT A2 — Pronom possessif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_pronom_possessif',
    'Complétez : « J''ai oublié mon livre à la maison. Tu peux me prêter ___ ? »',
    'Pour remplacer « ton livre » (un livre masculin singulier appartenant à « tu »), on utilise le pronom possessif « le tien ». « La tienne » s''emploie pour un nom féminin singulier (la tienne = ta chose). « Les tiens » s''emploie pour un masculin pluriel. « Le mien » désigne ce qui m''appartient (au locuteur), pas à l''interlocuteur.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000005', 'le tien',    true,  1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000005', 'la tienne',  false, 2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000005', 'les tiens',  false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000005', 'le mien',    false, 4);

-- Q6 : STRUCT A2 — Présent verbe irrégulier "venir"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_present_verbes_irreguliers',
    'Complétez : « Mes cousins ___ chez nous tous les dimanches. »',
    'Le verbe « venir » est irrégulier. À la 3e personne du pluriel du présent : « ils viennent ». « Venent » n''existe pas. « Viens » est la 1re ou 2e personne du singulier. « Venons » est la 1re personne du pluriel.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000006', 'venent',   false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000006', 'viens',    false, 2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000006', 'viennent', true,  3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000006', 'venons',   false, 4);

-- Q7 : STRUCT A2 — Préposition de temps "depuis"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_preposition_temps',
    'Complétez : « J''habite à Paris ___ trois ans. »',
    '« Depuis » indique un point de départ dans le passé d''une action qui dure encore au moment où l''on parle (j''ai commencé il y a 3 ans et j''y habite toujours). « Pendant » indique une durée terminée ou délimitée (j''ai habité à Paris pendant trois ans = je n''y habite plus). « Pour » indique une durée prévue à l''avance. « Il y a » indique un moment ponctuel dans le passé (je suis arrivé il y a trois ans).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000007', 'pendant', false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000007', 'depuis',  true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000007', 'pour',    false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000007', 'il y a',  false, 4);

-- Q8 : STRUCT A2 — Mot interrogatif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_mot_interrogatif',
    'Complétez : « ___ habitez-vous ? — À Lyon. »',
    'La réponse « À Lyon » désigne un lieu : on interroge donc sur le lieu avec « où ». « Quand » interroge sur le moment, « comment » sur la manière, « pourquoi » sur la cause.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000008', 'Quand',    false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000008', 'Où',       true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000008', 'Comment',  false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000008', 'Pourquoi', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : CE B1 — Campagne santé (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_idee_principale',
    'Quel est l''objectif principal de cette campagne ?',
    'Le texte dit que la campagne vise à « encourager les adultes de plus de 50 ans à se faire dépister ». Son but est donc d''inciter au dépistage. Le texte ne propose pas de nouveau médicament, ne dénonce pas les médecins, et ne s''adresse pas spécifiquement aux jeunes.',
    '44444444-0011-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000009', 'Promouvoir un nouveau médicament',                            false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000009', 'Inciter les plus de 50 ans à se faire dépister',              true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000009', 'Dénoncer le manque de suivi médical des Français',            false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000009', 'Informer les jeunes adultes sur les risques de santé',        false, 4);

-- Q10 : CE B1 — Campagne santé (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Selon le texte, quel est l''avantage principal du dépistage ?',
    'Le texte dit que les cancers sont « trop souvent diagnostiqués à un stade avancé » et « pourraient être pris en charge bien plus tôt ». L''avantage est donc une détection précoce. Le texte précise que le dépistage ne remplace pas le suivi médical, ne dit pas qu''il guérit, et n''évoque pas de réduction des coûts.',
    '44444444-0011-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000010', 'Il permet de détecter la maladie plus tôt',           true,  1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000010', 'Il remplace définitivement le suivi médical',         false, 2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000010', 'Il garantit la guérison des malades',                  false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000010', 'Il réduit les coûts pour la Sécurité sociale',         false, 4);

-- Q11 : CE B1 — Transition énergétique (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Combien la mairie de Saint-Léonard économise-t-elle grâce aux panneaux solaires ?',
    'Le texte indique : « ce qui permet à la mairie d''économiser environ 4 000 euros par an ». L''économie annuelle est donc de 4 000 euros. Les autres montants ne sont pas mentionnés.',
    '44444444-0011-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000011', '400 euros par an',     false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000011', '4 000 euros par an',   true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000011', '40 000 euros par an',  false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000011', 'Le texte ne précise pas le montant', false, 4);

-- Q12 : CE B1 — Transition énergétique (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Que prévoit ensuite la municipalité ?',
    'Le texte précise : « La municipalité envisage maintenant d''étendre l''installation à la salle des fêtes et au gymnase ». Elle prévoit donc d''équiper d''autres bâtiments. Le texte n''évoque ni la vente d''électricité, ni le retour à l''électricité classique, ni un nouveau référendum.',
    '44444444-0011-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000012', 'Vendre l''électricité produite aux habitants',             false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000012', 'Installer des panneaux sur d''autres bâtiments publics',  true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000012', 'Revenir à l''électricité classique',                       false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000012', 'Organiser un référendum sur le projet',                    false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : STRUCT B1 — Conditionnel de politesse
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_conditionnel_politesse',
    'Complétez avec une formule polie : « Bonjour, je ___ un café, s''il vous plaît. »',
    'Pour exprimer une demande polie, on utilise le conditionnel présent : « je voudrais ». « Veux » (présent) est correct grammaticalement mais peu poli dans un contexte formel. « Voulais » est un imparfait (action habituelle ou en cours dans le passé, inadapté ici). « Aurais voulu » est un conditionnel passé, qui exprime un regret, pas une demande actuelle.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000013', 'veux',         false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000013', 'voudrais',     true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000013', 'voulais',      false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000013', 'aurais voulu', false, 4);

-- Q14 : STRUCT B1 — Discours indirect au présent
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_discours_indirect_present',
    'Transformez au discours indirect : Elle me demande : « Est-ce que tu viens ? »',
    'Au discours indirect, on supprime les guillemets et on introduit la question par « si » (pour une question fermée totale, sans mot interrogatif). Les pronoms changent aussi : « tu viens » → « je viens » (du point de vue du locuteur rapporteur). « Que je viens » serait correct seulement pour une affirmation, pas pour une question. « Quand je viens » introduit une interrogation sur le moment, ce qui n''est pas le sens. « Pourquoi je viens » porte sur la cause.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000014', 'Elle me demande que je viens',      false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000014', 'Elle me demande si je viens',       true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000014', 'Elle me demande quand je viens',    false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000014', 'Elle me demande pourquoi je viens', false, 4);

-- Q15 : STRUCT B1 — Expression du but "pour que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_expression_but',
    'Complétez : « Je te prête mon livre ___ tu puisses le lire ce week-end. »',
    'Quand le sujet de la principale (« je ») est différent de celui de la subordonnée (« tu »), on utilise « pour que » + subjonctif (« puisses »). « Pour » s''emploie avec un infinitif, mais seulement quand les deux sujets sont identiques. « Afin de » s''emploie aussi avec un infinitif (même contrainte). « Parce que » introduit une cause, pas un but.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000015', 'pour',       false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000015', 'pour que',   true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000015', 'afin de',    false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000015', 'parce que',  false, 4);

-- Q16 : STRUCT B1 — Pronom "y"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_y',
    'Remplacez le complément : « Je vais à la piscine. → J''___ vais. »',
    '« À la piscine » est un complément de lieu introduit par « à ». Il se remplace par le pronom « y », qui reprend les compléments de lieu (où l''on est, où l''on va) ou les compléments introduits par « à ». « En » remplace un complément introduit par « de » ou un partitif. « Le » et « la » remplacent des compléments d''objet direct.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000016', 'en', false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000016', 'y',  true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000016', 'la', false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000016', 'le', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : CE B2 — Inégalités salariales (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle idée principale défend l''auteur de ce texte ?',
    'L''auteur conclut : « Tant qu''elle [la transparence salariale] ne se généralisera pas, il sera difficile d''espérer un véritable rattrapage. » Il défend donc l''idée que la transparence salariale est une condition nécessaire pour faire reculer les inégalités. Il ne nie pas le problème (il le documente), ne le réduit pas aux choix individuels, et ne dit pas que les écarts ont disparu.',
    '44444444-0011-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000017', 'Les écarts salariaux entre hommes et femmes ont presque disparu',           false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000017', 'La transparence salariale est une condition d''un vrai rattrapage',         true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000017', 'Les inégalités s''expliquent uniquement par les choix individuels',         false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000017', 'Les discours sur l''égalité ont été parfaitement suivis d''effets',         false, 4);

-- Q18 : CE B2 — Inégalités salariales (reformulation des causes)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Selon le texte, à quoi sont attribuées les inégalités salariales ?',
    'Le texte énumère plusieurs causes : « autocensure dans la négociation, accès plus difficile aux postes à responsabilité, ou encore prise en charge majoritaire des contraintes familiales ». Les causes sont donc multiples. Le texte ne dit pas que tout vient d''une discrimination volontaire des employeurs, ni que les femmes sont moins compétentes, ni qu''il s''agit d''un manque de qualification.',
    '44444444-0011-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000018', 'À la seule discrimination volontaire des employeurs',                                 false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000018', 'À plusieurs facteurs : autocensure, plafond de verre, charge familiale',              true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000018', 'À un manque de compétences des femmes par rapport aux hommes',                        false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000018', 'À un déficit de qualifications dans certains secteurs',                               false, 4);

-- Q19 : CE B2 — Désinformation (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_detail_specifique',
    'Pourquoi les fausses informations circulent-elles plus vite, selon le texte ?',
    'Le texte dit explicitement : « en grande partie parce qu''elle suscite des réactions émotionnelles plus fortes ». L''explication tient donc à la dimension émotionnelle. Le texte ne dit ni que les modérateurs les favorisent, ni que les utilisateurs ne savent pas lire, ni que les vraies informations sont volontairement bloquées.',
    '44444444-0011-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000019', 'Parce que les plateformes les favorisent volontairement',          false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000019', 'Parce qu''elles provoquent des réactions émotionnelles plus fortes', true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000019', 'Parce que les utilisateurs ne savent pas lire correctement',        false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000019', 'Parce que les vraies informations sont bloquées',                   false, 4);

-- Q20 : CE B2 — Désinformation (position de l'auteur)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle solution l''auteur juge-t-il la plus efficace à long terme ?',
    'Le texte conclut : « Renforcer l''éducation aux médias dès le plus jeune âge apparaît [...] comme une réponse plus durable que toute solution purement technique. » La priorité défendue est donc l''éducation aux médias. Les outils de modération sont jugés insuffisants (ils interviennent trop tard). L''interdiction des réseaux et la régulation pénale ne sont pas évoquées.',
    '44444444-0011-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000020', 'Le renforcement des outils techniques de modération',           false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000020', 'L''éducation aux médias dès le plus jeune âge',                 true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000020', 'L''interdiction pure et simple des réseaux sociaux',            false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000020', 'La création d''un tribunal spécial pour la désinformation',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : STRUCT B2 — Subjonctif passé
-- Sujet "il" non ambigu pour éviter tout problème d'accord du participe
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_subjonctif_passe',
    'Complétez : « Je suis content qu''il ___ à temps hier soir. »',
    'Le verbe principal exprime un sentiment (« je suis content que »), qui déclenche le subjonctif. L''action exprimée (« arriver à temps hier soir ») est antérieure au moment où l''on parle : il faut donc le subjonctif passé → « soit arrivé » (auxiliaire « être » au subjonctif présent + participe passé au masculin singulier accordé avec « il »). « Est arrivé » est l''indicatif. « Arrive » est un subjonctif présent (incorrect pour une action passée). « Serait arrivé » est un conditionnel passé.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000021', 'est arrivé',      false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000021', 'soit arrivé',     true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000021', 'arrive',          false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000021', 'serait arrivé',   false, 4);

-- Q22 : STRUCT B2 — Voix passive impersonnelle "il est interdit de"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_voix_passive_impersonnelle',
    'Complétez : « Il est interdit ___ téléphoner pendant les réunions. »',
    'Après une tournure impersonnelle comme « il est interdit », « il est nécessaire », « il est important », on utilise la préposition « de » suivie de l''infinitif. « À » s''emploie après certains verbes (commencer à, apprendre à) mais pas avec « il est interdit ». « Que » introduirait une subordonnée avec un verbe conjugué (« il est interdit que vous téléphoniez »), pas un infinitif. « Pour » exprime un but.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000022', 'à',   false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000022', 'de',  true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000022', 'que', false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000022', 'pour', false, 4);

-- Q23 : STRUCT B2 — Mise en relief "c'est ... que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_mise_en_relief',
    'Complétez : « C''est à Paris ___ j''ai rencontré mon meilleur ami. »',
    'Dans la structure de mise en relief « c''est ... que/qui », on utilise « que » quand l''élément mis en relief est un complément (de lieu, de temps, d''objet). « C''est qui » se réserve à un sujet (« c''est lui qui est venu »). « Quoi » et « où » ne s''emploient pas dans cette structure : on dit « c''est à Paris que », pas « c''est à Paris où ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000023', 'qui',  false, 1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000023', 'que',  true,  2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000023', 'quoi', false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000023', 'où',   false, 4);

-- Q24 : STRUCT B2 — Concession "avoir beau"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0011-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_avoir_beau',
    'Complétez : « Il ___ beau insister, je ne changerai pas d''avis. »',
    'L''expression idiomatique « avoir beau + infinitif » exprime une concession : faire un effort qui ne donne pas le résultat attendu. Elle se conjugue normalement, ici à la 3e personne du singulier du présent : « a ». « Est » et « va » sont des verbes inadaptés à cette expression figée. « Aurait » est un conditionnel (qui pourrait fonctionner dans d''autres contextes, mais pas pour une situation présente factuelle).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000024', 'a',       true,  1),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000024', 'est',     false, 2),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000024', 'va',      false, 3),
    (gen_random_uuid(), '55555555-0011-0000-0000-000000000024', 'aurait',  false, 4);
