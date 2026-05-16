-- ============================================================================
-- V10 : Lot 2 TCF — Compréhension écrite & Structure de la langue
-- ============================================================================
-- 📋 24 questions supplémentaires (4 par cellule × 6 cellules)
--    Suite du pilote V9.1 — nouveaux thèmes CE / nouveaux points grammaticaux
--
-- 🎯 Couverture par rapport à V9.1 :
--    CE A2  : transports + travail (nouveau)
--    CE B1  : numérique + consommation (nouveau)
--    CE B2  : télétravail + alimentation/société (nouveau)
--    STR A2 : négation, futur proche, comparatif, accord adjectif (nouveau)
--    STR B1 : plus-que-parfait, connecteurs, subjonctif il faut que,
--             voix passive (nouveau)
--    STR B2 : gérondif vs participe, concordance des temps, modalisation,
--             cause avancée (nouveau)
--
-- ✅ Checklist appliquée à chaque question :
--    1. Phrase grammaticalement correcte avec la bonne réponse insérée
--    2. Distracteurs strictement faux (raison précise pour chacun)
--    3. Explication sans faute ni pléonasme
--    4. Accents/caractères spéciaux vérifiés
--    5. Pas d'ambiguïté de genre/nombre du sujet
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES (table `passages`) — Plage V10 : 44444444-0010-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── A2 — passages courts ──────────
-- 🚌 Annonce transports (A2)
(
    '44444444-0010-0000-0000-000000000001', 'TEXTE',
    E'Information voyageurs\n\n' ||
    E'En raison de travaux sur la ligne 7, les trains ne circuleront pas entre les stations Centre-Ville et Université ce week-end, samedi et dimanche. Un service de bus de remplacement est mis en place toutes les 15 minutes. Pensez à prévoir 20 minutes de trajet supplémentaires.\n\n' ||
    E'Merci de votre compréhension.',
    '22222222-0000-0000-0000-000000000002'
),
-- 💼 Mémo de service (A2)
(
    '44444444-0010-0000-0000-000000000002', 'TEXTE',
    E'À tous les employés,\n\n' ||
    E'La réunion d''équipe prévue jeudi à 10h est déplacée à vendredi à 9h, en salle B. Merci de préparer votre bilan du mois et de venir avec votre ordinateur portable.\n\n' ||
    E'Le service Ressources humaines',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B1 — passages moyens ──────────
-- 🔒 Article cybersécurité (B1)
(
    '44444444-0010-0000-0000-000000000003', 'TEXTE',
    E'Les escroqueries par message se multiplient ces derniers mois. Les fraudeurs envoient un SMS qui imite parfaitement une banque ou un service de livraison, et invitent à cliquer sur un lien. La victime est ensuite dirigée vers un faux site, où elle saisit ses identifiants bancaires. Pour se protéger, il est conseillé de ne jamais cliquer sur un lien reçu par SMS, et de contacter directement son conseiller en cas de doute.',
    '22222222-0000-0000-0000-000000000002'
),
-- 🛒 Avis sur un service (B1)
(
    '44444444-0010-0000-0000-000000000004', 'TEXTE',
    E'J''ai commandé un canapé sur ce site il y a trois semaines. La livraison était annoncée sous dix jours, mais j''ai dû attendre près d''un mois. Le canapé est arrivé en bon état et correspond à la description, ce qui est un bon point. En revanche, le service client était injoignable pendant toute la durée de l''attente. Je recommanderais le produit, mais pas forcément ce vendeur.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B2 — passages longs ──────────
-- 💼 Tribune télétravail (B2) — différent de celle du V8
(
    '44444444-0010-0000-0000-000000000005', 'TEXTE',
    E'On nous avait promis, avec le télétravail généralisé, une révolution du rapport au travail. Cinq ans après les premiers grands confinements, le bilan est plus nuancé. Si nombre de salariés louent le gain de temps et la flexibilité, les responsables d''équipe, eux, s''inquiètent d''une perte progressive de la culture commune et d''une difficulté à intégrer les nouveaux arrivants. Plusieurs grandes entreprises ont d''ailleurs récemment imposé un retour partiel au bureau, suscitant la grogne d''une partie de leurs salariés. La question n''est sans doute plus de savoir si le télétravail doit perdurer, mais à quelles conditions il peut bénéficier à toutes les parties.',
    '22222222-0000-0000-0000-000000000002'
),
-- 🍽️ Alimentation et société (B2)
(
    '44444444-0010-0000-0000-000000000006', 'TEXTE',
    E'L''essor des produits ultra-transformés inquiète de plus en plus les autorités sanitaires. Riches en sucres, en sel et en additifs, ces aliments représenteraient aujourd''hui près d''un tiers de l''apport calorique moyen en France. Certains chercheurs établissent un lien direct entre leur consommation et la progression de l''obésité, voire de certains cancers. Pourtant, ces produits restent attractifs : peu chers, prêts à consommer, et massivement présents dans les linéaires. Sans une politique publique ambitieuse, qui pourrait inclure une taxation différenciée ou un étiquetage plus explicite, il est difficile de croire que les habitudes changeront d''elles-mêmes.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 2. QUESTIONS — Plage V10 : 55555555-0010-*
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : CE A2 — Transports (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand les trains de la ligne 7 ne circuleront-ils pas ?',
    'Le message dit explicitement « les trains ne circuleront pas entre les stations Centre-Ville et Université ce week-end, samedi et dimanche ». L''interruption concerne donc tout le week-end. Le texte n''évoque ni jeudi, ni lundi, ni une suppression définitive.',
    '44444444-0010-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000001', 'Jeudi et vendredi',                false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000001', 'Samedi et dimanche',               true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000001', 'Lundi matin uniquement',           false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000001', 'Toute la semaine prochaine',       false, 4);

-- Q2 : CE A2 — Transports (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_idee_principale',
    'Que conseille le message aux voyageurs ?',
    'Le message dit « Pensez à prévoir 20 minutes de trajet supplémentaires ». Le conseil est donc de prévoir plus de temps. Le texte ne demande pas de changer de ligne, ni de prendre un taxi, ni d''éviter de voyager.',
    '44444444-0010-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000002', 'De prévoir plus de temps pour leur trajet', true,  1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000002', 'De changer de ligne de métro',              false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000002', 'De prendre un taxi',                        false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000002', 'D''éviter de voyager ce week-end',          false, 4);

-- Q3 : CE A2 — Mémo travail (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
    'Quand a maintenant lieu la réunion ?',
    'Le mémo dit que la réunion « est déplacée à vendredi à 9h ». La nouvelle date et la nouvelle heure sont donc vendredi 9h. Le jeudi 10h correspond à l''ancien horaire.',
    '44444444-0010-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000003', 'Jeudi à 10h',  false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000003', 'Vendredi à 9h', true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000003', 'Vendredi à 10h', false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000003', 'Lundi à 9h',   false, 4);

-- Q4 : CE A2 — Mémo travail (reformulation)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reformulation',
    'Que doivent apporter les employés à la réunion ?',
    'Le mémo précise : « Merci de préparer votre bilan du mois et de venir avec votre ordinateur portable. » Les deux éléments demandés sont donc le bilan et l''ordinateur portable. Le texte ne mentionne ni casque, ni dossier client, ni café.',
    '44444444-0010-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000004', 'Leur bilan et leur ordinateur portable', true,  1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000004', 'Un casque et leur téléphone',            false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000004', 'Un dossier client et un stylo',          false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000004', 'Du café et des viennoiseries',           false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : STRUCT A2 — Négation "ne ... rien"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_negation_ne_rien',
    'Mettez à la forme négative : « Je vois quelque chose. »',
    'Pour nier « quelque chose », on utilise la négation « ne ... rien », qui encadre le verbe : « Je ne vois rien ». « Ne ... personne » nie une personne (« je ne vois personne »). « Ne ... jamais » nie un moment. « Ne ... pas » est une négation générale qui ne remplace pas « quelque chose ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000005', 'Je ne vois pas quelque chose', false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000005', 'Je ne vois rien',              true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000005', 'Je ne vois personne',          false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000005', 'Je ne vois jamais',            false, 4);

-- Q6 : STRUCT A2 — Futur proche
-- Tous les distracteurs sont grammaticalement faux pour exprimer un futur immédiat avec "aller"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_futur_proche',
    'Complétez avec le futur proche : « Demain matin, nous ___ le musée du Louvre. »',
    'Le futur proche se forme avec le verbe « aller » au présent + infinitif. À la 1re personne du pluriel : « allons visiter ». « Avons visité » est un passé composé (action passée). « Visitons » est un présent. « Visiterons » est un futur simple, qui n''est pas le futur proche demandé par la consigne.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000006', 'avons visité',   false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000006', 'allons visiter', true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000006', 'visitons',       false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000006', 'visiterons',     false, 4);

-- Q7 : STRUCT A2 — Comparatif d'adjectif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_comparatif',
    'Complétez : « Mon frère est ___ grand que moi : il mesure dix centimètres de plus. »',
    'Pour exprimer la supériorité avec un adjectif, on utilise « plus ... que » : « plus grand que moi ». « Aussi ... que » exprime l''égalité (même taille), « moins ... que » exprime l''infériorité (il serait plus petit), « autant que » s''emploie avec un verbe ou un nom, pas avec un adjectif.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000007', 'plus',   true,  1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000007', 'aussi',  false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000007', 'moins',  false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000007', 'autant', false, 4);

-- Q8 : STRUCT A2 — Accord adjectif (féminin pluriel)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_accord_adjectif',
    'Complétez : « Ces fleurs sont vraiment ___. »',
    'L''adjectif s''accorde en genre et en nombre avec le nom qu''il qualifie. « Fleurs » est féminin pluriel : l''adjectif prend la forme féminine pluriel « belles » (le -e marque le féminin, le -s marque le pluriel). « Beau » est masculin singulier, « belle » féminin singulier, « beaux » masculin pluriel.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000008', 'beau',   false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000008', 'belle',  false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000008', 'beaux',  false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000008', 'belles', true,  4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : CE B1 — Cybersécurité (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_idee_principale',
    'Quel est le but principal de cet article ?',
    'L''article décrit une arnaque par SMS puis conclut par des conseils de protection : « il est conseillé de ne jamais cliquer sur un lien reçu par SMS, et de contacter directement son conseiller en cas de doute ». Son objectif est donc d''informer et de mettre en garde. Il ne fait ni la promotion d''un service, ni la critique des banques, ni un témoignage personnel.',
    '44444444-0010-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000009', 'Faire la promotion d''un nouveau service bancaire',  false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000009', 'Mettre en garde contre les escroqueries par SMS',     true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000009', 'Critiquer les banques pour leur manque de sécurité',  false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000009', 'Raconter une histoire personnelle de fraude',         false, 4);

-- Q10 : CE B1 — Cybersécurité (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Que doit faire un client qui reçoit un SMS suspect de sa banque ?',
    'L''article conseille de « contacter directement son conseiller en cas de doute ». Le bon réflexe est donc de joindre sa banque par un canal direct (et non par le SMS suspect). Cliquer sur le lien est précisément ce que le texte déconseille. Communiquer ses identifiants ou supprimer son compte ne sont pas recommandés.',
    '44444444-0010-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000010', 'Cliquer sur le lien pour vérifier',          false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000010', 'Contacter directement son conseiller',        true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000010', 'Communiquer ses identifiants par retour de SMS', false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000010', 'Supprimer son compte bancaire',               false, 4);

-- Q11 : CE B1 — Avis sur un service (ton)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_ton_auteur',
    'Quelle est la position globale de l''auteur sur ce vendeur ?',
    'L''auteur conclut : « Je recommanderais le produit, mais pas forcément ce vendeur. » Il sépare clairement le produit (positif) du service client (négatif). Sa position est donc partagée. Il n''est ni entièrement satisfait, ni totalement insatisfait, et ne reste pas neutre.',
    '44444444-0010-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000011', 'Il est entièrement satisfait',                            false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000011', 'Son avis est partagé : produit correct, vendeur décevant', true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000011', 'Il est complètement déçu par sa commande',                false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000011', 'Il ne donne pas vraiment son opinion',                     false, 4);

-- Q12 : CE B1 — Avis sur un service (détail)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quel principal reproche l''auteur fait-il au vendeur ?',
    'Le texte dit : « le service client était injoignable pendant toute la durée de l''attente ». Le reproche porte donc sur le service client. Le canapé est arrivé en bon état et correspond à la description (donc pas de défaut produit), et le texte ne mentionne ni prix excessif, ni absence de garantie.',
    '44444444-0010-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000012', 'Le canapé est arrivé endommagé',                       false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000012', 'Le service client était injoignable',                   true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000012', 'Le prix était beaucoup trop élevé',                     false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000012', 'Le produit ne correspondait pas à la description',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : STRUCT B1 — Plus-que-parfait
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_plus_que_parfait',
    'Complétez : « Quand je suis arrivé à la gare, le train ___ déjà parti depuis dix minutes. »',
    'Pour exprimer une action antérieure à une autre action passée, on utilise le plus-que-parfait : « était parti » (auxiliaire « être » à l''imparfait + participe passé). « A parti » est incorrect (le verbe « partir » prend l''auxiliaire « être », pas « avoir »). « Partait » est un imparfait simple (action en cours, pas antérieure). « Est parti » est un passé composé.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000013', 'a parti',     false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000013', 'partait',     false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000013', 'était parti', true,  3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000013', 'est parti',   false, 4);

-- Q14 : STRUCT B1 — Connecteur logique de conséquence
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_connecteur_consequence',
    'Complétez : « Il pleut beaucoup ce matin, ___ je vais prendre mon parapluie. »',
    'On exprime ici une conséquence (action qui découle de la cause « il pleut »). « Donc » est un connecteur de conséquence, qui convient parfaitement. « Parce que » introduit une cause, pas une conséquence. « Mais » introduit une opposition. « Pourtant » introduit une concession (idée contraire à l''attente).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000014', 'parce que', false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000014', 'donc',      true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000014', 'mais',      false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000014', 'pourtant',  false, 4);

-- Q15 : STRUCT B1 — Subjonctif après "il faut que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_subjonctif_il_faut_que',
    'Complétez : « Il faut que tu ___ ton dossier avant vendredi. »',
    'L''expression « il faut que » exprime l''obligation et est toujours suivie du subjonctif. À la 2e personne du singulier du verbe « finir » au subjonctif présent : « finisses ». « Finis » est l''indicatif présent (ou impératif). « Finiras » est un futur. « Finirais » est un conditionnel. Aucun de ces temps ne s''emploie après « il faut que ».',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000015', 'finis',     false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000015', 'finisses',  true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000015', 'finiras',   false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000015', 'finirais',  false, 4);

-- Q16 : STRUCT B1 — Voix passive
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_voix_passive',
    'Mettez à la voix passive : « Le maire inaugure la nouvelle école. »',
    'À la voix passive, le complément d''objet direct (« la nouvelle école ») devient sujet, et le sujet (« le maire ») devient complément d''agent introduit par « par ». Le verbe se conjugue avec « être » au même temps que le verbe actif (présent) → « est inaugurée » (accord au féminin singulier avec « école »). « Sera inaugurée » est un futur passif, « a été inaugurée » un passé composé passif, « est inauguré » manque l''accord au féminin.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000016', 'La nouvelle école sera inaugurée par le maire',     false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000016', 'La nouvelle école est inaugurée par le maire',       true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000016', 'La nouvelle école a été inaugurée par le maire',    false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000016', 'La nouvelle école est inauguré par le maire',        false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : CE B2 — Télétravail (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle est l''idée principale de cette tribune ?',
    'L''auteur conclut : « La question n''est sans doute plus de savoir si le télétravail doit perdurer, mais à quelles conditions il peut bénéficier à toutes les parties ». Il défend donc l''idée que le télétravail doit être encadré ou aménagé. Il ne le condamne pas, ne le glorifie pas, et ne se contente pas de rapporter ce que font les entreprises.',
    '44444444-0010-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000017', 'Le télétravail doit être totalement supprimé',                              false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000017', 'La question est désormais de savoir comment l''aménager équitablement',     true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000017', 'Le télétravail est un succès unanimement célébré',                          false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000017', 'Les entreprises ont raison de forcer le retour au bureau',                  false, 4);

-- Q18 : CE B2 — Télétravail (inférence sur les managers)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Que reprochent les responsables d''équipe au télétravail, selon le texte ?',
    'Le texte indique que les responsables « s''inquiètent d''une perte progressive de la culture commune et d''une difficulté à intégrer les nouveaux arrivants ». Leurs préoccupations sont donc collectives (cohésion, intégration), pas individuelles. Le texte ne dit ni qu''ils craignent une baisse de productivité, ni qu''ils dénoncent les abus, ni qu''ils s''opposent à un retour au bureau.',
    '44444444-0010-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000018', 'Une baisse mesurable de la productivité individuelle',                       false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000018', 'L''affaiblissement de la culture d''équipe et de l''intégration des nouveaux', true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000018', 'La multiplication des abus et des fraudes',                                  false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000018', 'Le refus des salariés de revenir au bureau',                                  false, 4);

-- Q19 : CE B2 — Alimentation (reformulation des risques)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Selon le texte, à quoi est lié le succès des produits ultra-transformés ?',
    'Le texte précise : « Pourtant, ces produits restent attractifs : peu chers, prêts à consommer, et massivement présents dans les linéaires ». Le succès s''explique donc par leur prix, leur côté pratique et leur disponibilité. Le texte n''évoque pas leurs qualités nutritionnelles (au contraire), ni la publicité ou la mode comme cause explicite.',
    '44444444-0010-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000019', 'À leurs qualités nutritionnelles supérieures',                            false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000019', 'À leur prix bas, leur côté pratique et leur omniprésence',                true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000019', 'À une intense campagne publicitaire récente',                              false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000019', 'À un effet de mode passager',                                              false, 4);

-- Q20 : CE B2 — Alimentation (position de l'auteur)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle position adopte l''auteur sur les politiques publiques à mener ?',
    'L''auteur écrit : « Sans une politique publique ambitieuse, qui pourrait inclure une taxation différenciée ou un étiquetage plus explicite, il est difficile de croire que les habitudes changeront d''elles-mêmes ». Il appelle donc à une action publique forte, en avançant des pistes concrètes. Il ne prône pas le laisser-faire, ne se contente pas de constater, et n''accuse pas directement les consommateurs.',
    '44444444-0010-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000020', 'Il fait confiance au libre choix des consommateurs',                     false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000020', 'Il plaide pour une intervention publique ambitieuse et concrète',         true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000020', 'Il se contente d''un constat sans prendre position',                     false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000020', 'Il rend les consommateurs seuls responsables du problème',                false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : STRUCT B2 — Gérondif vs participe présent
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_gerondif_vs_participe',
    'Complétez : « ___ la nouvelle, elle a immédiatement appelé sa famille. »',
    'Pour exprimer la simultanéité ou la cause d''une action effectuée par le même sujet, on utilise le gérondif (« en » + participe présent) → « En apprenant ». Le participe présent seul (« apprenant ») marquerait davantage une cause antérieure, mais sans le « en », il devient ambigu. « Apprenu » n''existe pas (le participe passé de « apprendre » est « appris »). « Pour apprendre » exprimerait un but, ce qui n''a pas de sens ici.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000021', 'En apprenant',  true,  1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000021', 'Apprenant',     false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000021', 'Apprenu',       false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000021', 'Pour apprendre', false, 4);

-- Q22 : STRUCT B2 — Concordance des temps au discours indirect
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_concordance_temps',
    'Complétez : « Il m''a dit qu''il ___ le lendemain. »',
    'Quand le verbe introducteur (« a dit ») est au passé, le futur du discours direct devient un conditionnel présent au discours indirect : « il viendrait ». « Vient » est un présent (compatible seulement avec un verbe introducteur au présent : « il dit qu''il vient »). « Viendra » est un futur (compatible avec un présent introducteur). « Est venu » est un passé composé, qui ne traduit pas une action future par rapport au moment où il a parlé.',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000022', 'vient',     false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000022', 'viendra',   false, 2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000022', 'viendrait', true,  3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000022', 'est venu',  false, 4);

-- Q23 : STRUCT B2 — Modalisation "il se peut que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_modalisation_il_se_peut',
    'Complétez : « Il se peut qu''il ___ en retard à cause des embouteillages. »',
    'L''expression « il se peut que » exprime une éventualité et entraîne obligatoirement le subjonctif. À la 3e personne du singulier du verbe « être » au subjonctif présent : « soit ». « Est » et « sera » sont des indicatifs (incompatibles), « serait » est un conditionnel (également incompatible avec « il se peut que »).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000023', 'est',    false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000023', 'soit',   true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000023', 'sera',   false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000023', 'serait', false, 4);

-- Q24 : STRUCT B2 — Cause avancée "étant donné que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0010-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_cause_avancee',
    'Complétez : « ___ les délais sont très courts, nous devons commencer immédiatement. »',
    '« Étant donné que » est une conjonction qui introduit une cause connue ou admise, suivie d''un verbe à l''indicatif. C''est la forme correcte ici. « Bien que » introduit une concession, suivie du subjonctif (contraire au sens et au mode). « Pour que » introduit un but, suivi du subjonctif. « Afin de » introduit un but, suivi d''un infinitif (pas d''un verbe conjugué).',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000024', 'Bien que',         false, 1),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000024', 'Étant donné que',  true,  2),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000024', 'Pour que',         false, 3),
    (gen_random_uuid(), '55555555-0010-0000-0000-000000000024', 'Afin de',          false, 4);
