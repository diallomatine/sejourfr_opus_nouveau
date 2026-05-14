-- ============================================================================
-- V9.1 : Lot pilote TCF — Compréhension écrite & Structure de la langue
-- ============================================================================
-- Version CORRIGÉE après audit rigoureux. Changements par rapport à V9 :
--   • Q2  : distracteurs renforcés (cohérence sémantique)
--   • Q5  : RÉÉCRITE — sujet masculin sans ambiguïté + distracteurs propres
--   • Q7  : RÉÉCRITE — pronom COD à la bonne position (avant le verbe)
--   • Q14 : correction du pléonasme « COD direct »
--   • Q22 : reformulation pour éviter ambiguïté d'accord du participe
--   • Q23 : explication clarifiée
--
-- 📋 24 questions (4 par cellule × 6 cellules) :
--    • CE A2 (4) • STRUCTURE A2 (4)
--    • CE B1 (4) • STRUCTURE B1 (4)
--    • CE B2 (4) • STRUCTURE B2 (4)
--
-- ⚙️  Cette migration :
--    1. Ajoute la colonne competence_code à la table questions
--    2. Insère les passages CE (texte support)
--    3. Insère les 24 questions et leurs 96 choix
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 🔧 1. ÉVOLUTION DE SCHÉMA
-- ----------------------------------------------------------------------------
ALTER TABLE questions ADD COLUMN IF NOT EXISTS competence_code VARCHAR(64);
CREATE INDEX IF NOT EXISTS idx_questions_competence_code
    ON questions(competence_code);


-- ----------------------------------------------------------------------------
-- 📄 2. PASSAGES (table `passages`)
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── A2 — passages courts (e-mails simples) ──────────
(
    '44444444-0009-0000-0000-000000000001', 'TEXTE',
    E'Bonjour Madame Martin,\n\n' ||
    E'Je vous écris pour confirmer votre rendez-vous chez le docteur Lefèvre le mardi 19 mai à 14h30. Merci d''apporter votre carte Vitale et votre ordonnance.\n\n' ||
    E'Cordialement,\nSecrétariat médical',
    '22222222-0000-0000-0000-000000000002'
),
(
    '44444444-0009-0000-0000-000000000002', 'TEXTE',
    E'Cher client,\n\n' ||
    E'Votre colis n''a pas pu être livré ce matin. Vous pouvez le récupérer à votre bureau de poste à partir de demain, du lundi au samedi entre 9h et 18h. Pensez à vous munir d''une pièce d''identité.\n\n' ||
    E'Service livraison',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B1 — passages moyens (avis, e-mail formel) ──────────
(
    '44444444-0009-0000-0000-000000000003', 'TEXTE',
    E'J''ai testé ce restaurant samedi soir avec mon mari pour notre anniversaire de mariage. Le cadre est très joli et le personnel se montre vraiment attentif. En revanche, nous avons attendu près de quarante minutes entre l''entrée et le plat principal, ce qui est trop long pour un samedi. Les plats étaient corrects mais sans surprise. Je recommande pour le décor, mais peut-être pas pour une occasion spéciale.',
    '22222222-0000-0000-0000-000000000002'
),
(
    '44444444-0009-0000-0000-000000000004', 'TEXTE',
    E'Madame, Monsieur,\n\n' ||
    E'Suite à votre demande, je vous confirme que votre dossier de location a bien été reçu. Cependant, il manque encore votre dernier avis d''imposition ainsi qu''un justificatif de domicile de moins de trois mois. Sans ces documents, nous ne pourrons malheureusement pas étudier votre candidature avant la fin du mois.\n\n' ||
    E'Bien cordialement,\nAgence Habitat Plus',
    '22222222-0000-0000-0000-000000000002'
),
(
    '44444444-0009-0000-0000-000000000005', 'TEXTE',
    E'À partir du 1er juin, les habitants de la commune devront utiliser les nouveaux bacs de tri. Le bac jaune accueillera désormais tous les emballages plastiques, y compris les pots de yaourt et les barquettes, alors qu''ils étaient auparavant interdits. Le bac vert reste réservé au verre. Les contrevenants s''exposent à une amende de 35 euros.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── B2 — passages longs (article, tribune) ──────────
(
    '44444444-0009-0000-0000-000000000006', 'TEXTE',
    E'Depuis quelques années, les médecins généralistes tirent la sonnette d''alarme. Si les déserts médicaux étaient autrefois cantonnés aux zones rurales, ils gagnent désormais les périphéries urbaines, où des patients renoncent à des soins faute de praticien disponible dans un délai raisonnable. Les pouvoirs publics multiplient les incitations financières à l''installation, mais les jeunes médecins, eux, plébiscitent l''exercice en cabinet de groupe et refusent souvent les zones isolées. Une véritable réforme structurelle, plutôt que des primes ponctuelles, semble aujourd''hui nécessaire pour enrayer le phénomène.',
    '22222222-0000-0000-0000-000000000002'
),
(
    '44444444-0009-0000-0000-000000000007', 'TEXTE',
    E'L''engouement pour les voitures électriques marque le pas. Après plusieurs années de croissance soutenue, les ventes ont reculé de 12% au premier trimestre. Les explications sont multiples : suppression progressive des aides à l''achat, hausse du prix de l''électricité, mais aussi inquiétudes des automobilistes quant à l''autonomie réelle des véhicules. Pour autant, les constructeurs ne renoncent pas. Ils misent désormais sur des modèles à prix plus accessibles, en espérant relancer une dynamique qu''ils jugent indispensable face aux objectifs européens de réduction des émissions à l''horizon 2035.',
    '22222222-0000-0000-0000-000000000002'
),
(
    '44444444-0009-0000-0000-000000000008', 'TEXTE',
    E'Faut-il vraiment se réjouir du succès des plateformes de streaming ? Certes, elles ont démocratisé l''accès à un nombre considérable de films et de séries, et permis l''émergence de productions locales que les chaînes traditionnelles n''auraient jamais financées. Mais on aurait tort d''en conclure que tout est positif. L''algorithme nous enferme dans des recommandations toujours plus formatées, et la concurrence acharnée entre plateformes pousse à une production de masse souvent au détriment de la qualité. À force de tout regarder, ne risque-t-on pas, paradoxalement, de ne plus rien voir ?',
    '22222222-0000-0000-0000-000000000002'
)
    ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : CE A2 — Rendez-vous médical (repérage explicite)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000001', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_reperage_explicite',
             'À quelle heure est le rendez-vous de Madame Martin ?',
             'Le message indique précisément « le mardi 19 mai à 14h30 ». L''heure du rendez-vous est donc 14h30. Les autres horaires ne figurent pas dans le texte.',
             '44444444-0009-0000-0000-000000000001',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000001', '13h30', false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000001', '14h30', true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000001', '15h30', false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000001', '16h30', false, 4);

-- Q2 : CE A2 — Rendez-vous médical (détail spécifique) — DISTRACTEURS RENFORCÉS
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000002', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
             'Que doit apporter Madame Martin à son rendez-vous ?',
             'Le message demande explicitement d''apporter « votre carte Vitale et votre ordonnance ». La carte Vitale et l''ordonnance sont précisément les deux documents cités, à l''exclusion de tout autre.',
             '44444444-0009-0000-0000-000000000001',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000002', 'Sa carte d''identité et un chèque',         false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000002', 'Sa carte Vitale et son ordonnance',         true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000002', 'Sa carte Vitale et sa mutuelle',            false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000002', 'Son ordonnance et un justificatif de domicile', false, 4);

-- Q3 : CE A2 — Colis (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000003', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_idee_principale',
             'Pourquoi le client reçoit-il ce message ?',
             'Le message commence par « Votre colis n''a pas pu être livré » : il s''agit donc d''un avis de non-livraison. Le texte ne mentionne ni retard, ni changement d''adresse, ni perte du colis.',
             '44444444-0009-0000-0000-000000000002',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000003', 'Pour annoncer un retard de livraison',        false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000003', 'Pour informer d''une non-livraison du colis', true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000003', 'Pour confirmer un changement d''adresse',     false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000003', 'Pour signaler la perte du colis',             false, 4);

-- Q4 : CE A2 — Colis (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000004', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'A2', 'CE', 'ce_detail_specifique',
             'Quel jour le client peut-il aller récupérer son colis au plus tôt ?',
             'Le message dit « à partir de demain, du lundi au samedi ». Le client peut donc le récupérer dès le lendemain. « À partir de demain » exclut « aujourd''hui » et « après-demain ».',
             '44444444-0009-0000-0000-000000000002',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000004', 'Aujourd''hui',         false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000004', 'Demain',               true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000004', 'Après-demain',         false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000004', 'Dans une semaine',     false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟢 NIVEAU A2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : STRUCT A2 — Passé composé avec être — RÉÉCRITE
-- Sujet masculin SANS ambiguïté possible d'accord, distracteurs propres
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000005', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_passe_compose_etre',
             'Complétez : « Hier, Pierre ___ au cinéma avec ses amis. »',
             'Le verbe « aller » se conjugue avec l''auxiliaire « être » au passé composé. À la 3e personne du masculin singulier (« Pierre »), la forme correcte est « est allé ». « A allé » est incorrect car « aller » prend toujours « être » comme auxiliaire. « Va aller » est un futur proche (présent), pas un passé. « Est allée » avec un -e final est la forme féminine, qui ne s''accorde pas avec un sujet masculin.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000005', 'a allé',     false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000005', 'est allé',   true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000005', 'va aller',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000005', 'est allée',  false, 4);

-- Q6 : STRUCT A2 — Articles partitifs
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000006', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_articles_partitifs',
             'Complétez : « Pour le petit-déjeuner, je prends ___ café et ___ tartines. »',
             '« Café » est masculin singulier, désignant une quantité non précisée : on emploie le partitif « du ». « Tartines » est féminin pluriel : on emploie « des ». « De la » s''emploie devant un féminin singulier (ex. « de la confiture »). « Le » et « les » sont des articles définis (qui désignent quelque chose de précis), inadaptés ici. « Un / une » désignent une unité comptée.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000006', 'le / les',     false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000006', 'du / des',     true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000006', 'de la / des',  false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000006', 'un / une',     false, 4);

-- Q7 : STRUCT A2 — Pronom COD — RÉÉCRITE
-- Le pronom COD est placé AVANT le verbe (construction grammaticale correcte)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000007', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_pronom_cod',
             'Remplacez « les clés » par un pronom : « Je ___ prends avant de partir. »',
             '« Les clés » est un complément d''objet direct (COD) au féminin pluriel : il se remplace par le pronom « les », placé avant le verbe « prends ». « Leur » est un pronom indirect (COI) au pluriel (à eux/à elles). « Lui » est un COI singulier (à lui/à elle). « Y » est un pronom qui remplace un complément de lieu ou introduit par « à ».',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000007', 'leur', false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000007', 'les',  true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000007', 'lui',  false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000007', 'y',    false, 4);

-- Q8 : STRUCT A2 — Préposition avec pays
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000008', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'A2', 'STRUCTURE', 'struct_preposition_pays',
             'Complétez : « Mes parents habitent ___ Portugal depuis 2010. »',
             'Devant un nom de pays masculin commençant par une consonne (« le Portugal »), on emploie « au ». On utilise « en » pour les pays féminins (en France, en Italie) ou masculins commençant par une voyelle (en Iran). « À » s''emploie pour les villes (à Paris). « Aux » s''emploie pour les pluriels (aux États-Unis).',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000008', 'en',  false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000008', 'au',  true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000008', 'à',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000008', 'aux', false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : CE B1 — Avis restaurant (ton / opinion)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000009', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_ton_auteur',
             'Quelle est l''opinion globale de l''auteure sur ce restaurant ?',
             'L''auteure conclut : « Je recommande pour le décor, mais peut-être pas pour une occasion spéciale ». Elle reconnaît du positif (décor, personnel attentif) et pointe des défauts (attente longue, plats sans surprise). Son avis est donc mitigé, ni totalement enthousiaste, ni totalement négatif, ni indifférent.',
             '44444444-0009-0000-0000-000000000003',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000009', 'Elle est très enthousiaste',           false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000009', 'Son avis est mitigé',                   true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000009', 'Elle déconseille totalement le lieu',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000009', 'Elle est indifférente',                 false, 4);

-- Q10 : CE B1 — Dossier de location (inférence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000010', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
             'Que doit faire le destinataire après avoir lu ce message ?',
             'L''agence dit que « sans ces documents, nous ne pourrons pas étudier votre candidature » et précise qu''il manque « votre dernier avis d''imposition ainsi qu''un justificatif de domicile ». Le destinataire doit donc envoyer les pièces manquantes. Le dossier n''est pas complet, n''est pas refusé, et il n''est pas question de payer une caution.',
             '44444444-0009-0000-0000-000000000004',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000010', 'Attendre, son dossier est complet',         false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000010', 'Envoyer les documents manquants',           true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000010', 'Recommencer son dossier depuis le début',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000010', 'Payer une caution supplémentaire',          false, 4);

-- Q11 : CE B1 — Tri sélectif (détail spécifique)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000011', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
             'Qu''est-ce qui change dans le tri à partir du 1er juin ?',
             'Le texte précise : « Le bac jaune accueillera désormais tous les emballages plastiques, y compris les pots de yaourt et les barquettes, alors qu''ils étaient auparavant interdits ». C''est donc une extension de ce qu''on peut mettre dans le bac jaune. Le bac vert n''est pas modifié, le tri n''est pas supprimé, et le texte n''indique pas que seuls les pots seraient triés.',
             '44444444-0009-0000-0000-000000000005',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000011', 'Le tri sélectif est supprimé',                                                false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000011', 'On peut désormais mettre plus d''emballages plastiques dans le bac jaune',   true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000011', 'Le bac vert accueille maintenant le plastique',                              false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000011', 'Seuls les pots de yaourt peuvent être triés',                                false, 4);

-- Q12 : CE B1 — Tri sélectif (reformulation / conséquence)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000012', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
             'Que risque un habitant qui ne respecte pas les nouvelles règles ?',
             'Le texte indique : « Les contrevenants s''exposent à une amende de 35 euros. » Le risque est donc financier (une amende). Le texte n''évoque ni peine de prison, ni suspension du ramassage, ni convocation au tribunal.',
             '44444444-0009-0000-0000-000000000005',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000012', 'Une peine de prison',                  false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000012', 'Une amende de 35 euros',               true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000012', 'La suspension du ramassage',           false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000012', 'Une convocation au tribunal',          false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🟡 NIVEAU B1 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : STRUCT B1 — Imparfait vs passé composé
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000013', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_imparfait_vs_passe_compose',
             'Complétez : « Quand je suis arrivé chez lui, il ___ déjà la télévision. »',
             'On a deux actions au passé : une action ponctuelle terminée (« je suis arrivé », passé composé) et une action en cours à ce moment-là (« regardait », imparfait pour décrire un arrière-plan, une situation déjà installée). « A regardé » exprimerait une action ponctuelle. « Regardera » est au futur. « Regarderait » est au conditionnel.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000013', 'a regardé',    false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000013', 'regardait',    true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000013', 'regardera',    false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000013', 'regarderait',  false, 4);

-- Q14 : STRUCT B1 — Pronom relatif "dont" — PLÉONASME CORRIGÉ
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000014', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_relatif_dont',
             'Complétez : « C''est un film ___ tout le monde parle en ce moment. »',
             'Le verbe « parler » se construit avec la préposition « de » : on parle DE quelque chose. Le pronom relatif qui remplace un complément introduit par « de » est « dont ». « Que » remplace un complément d''objet direct (sans préposition). « Qui » remplace un sujet. « Où » remplace un complément de lieu ou de temps.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000014', 'que',  false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000014', 'qui',  false, 2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000014', 'dont', true,  3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000014', 'où',   false, 4);

-- Q15 : STRUCT B1 — Hypothèse si + imparfait
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000015', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_hypothese_si_imparfait',
             'Complétez : « Si vous aviez plus de temps, vous ___ apprendre une nouvelle langue. »',
             'La structure « Si + imparfait » dans la subordonnée appelle un conditionnel présent dans la principale → « pourriez ». « Pouvez » est un présent (incompatible avec une hypothèse irréelle). « Pouviez » est un imparfait (placé dans la principale, c''est incorrect). « Pourrez » est un futur (compatible seulement avec « si + présent »).',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000015', 'pouvez',   false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000015', 'pouviez',  false, 2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000015', 'pourriez', true,  3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000015', 'pourrez',  false, 4);

-- Q16 : STRUCT B1 — Pronom "en"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000016', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B1', 'STRUCTURE', 'struct_pronom_en',
             'Remplacez le complément : « — Tu veux du café ? — Oui, j''___ veux bien. »',
             '« Du café » est un complément introduit par l''article partitif « du » : il se remplace par le pronom « en », qui reprend toute quantité indéterminée. « Le » et « la » remplacent des compléments définis (le café = ce café précis, pas une quantité non précisée). « Y » remplace un complément de lieu ou un complément introduit par la préposition « à ».',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000016', 'le', false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000016', 'la', false, 2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000016', 'en', true,  3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000016', 'y',  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Compréhension Écrite (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : CE B2 — Déserts médicaux (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000017', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
             'Quelle est l''idée principale défendue par l''auteur ?',
             'L''auteur conclut explicitement : « Une véritable réforme structurelle, plutôt que des primes ponctuelles, semble aujourd''hui nécessaire ». Il défend donc une réforme de fond. Il ne nie pas le problème (il l''étend même aux périphéries urbaines), juge les primes insuffisantes, et n''affirme pas que les jeunes médecins refusent d''exercer en France (seulement qu''ils refusent les zones isolées).',
             '44444444-0009-0000-0000-000000000006',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000017', 'Les déserts médicaux n''existent que dans les campagnes',                  false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000017', 'Les primes financières suffisent à résoudre le problème',                   false, 2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000017', 'Une réforme de fond est nécessaire, au-delà des incitations financières',   true,  3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000017', 'Les jeunes médecins refusent désormais d''exercer en France',               false, 4);

-- Q18 : CE B2 — Déserts médicaux (inférence sur les médecins)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000018', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
             'Que peut-on déduire du comportement des jeunes médecins selon le texte ?',
             'Le texte dit qu''ils « plébiscitent l''exercice en cabinet de groupe et refusent souvent les zones isolées ». On en déduit qu''ils préfèrent travailler à plusieurs et dans des zones plus peuplées. Le texte ne dit pas qu''ils acceptent les zones isolées (même avec des primes), ni qu''ils quittent la profession, ni qu''ils privilégient les hôpitaux publics.',
             '44444444-0009-0000-0000-000000000006',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000018', 'Ils acceptent volontiers les postes en zones isolées si les primes sont élevées', false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000018', 'Ils préfèrent travailler en équipe dans des zones suffisamment peuplées',         true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000018', 'Ils quittent en masse la profession médicale',                                    false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000018', 'Ils s''installent uniquement dans les hôpitaux publics',                          false, 4);

-- Q19 : CE B2 — Voitures électriques (causes)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000019', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
             'Selon le texte, à quoi est attribué le recul des ventes de voitures électriques ?',
             'Le texte énumère trois causes : « suppression progressive des aides à l''achat, hausse du prix de l''électricité, mais aussi inquiétudes des automobilistes quant à l''autonomie réelle ». Le texte ne mentionne ni interdiction gouvernementale, ni absence de modèles disponibles, ni rejet de l''écologie.',
             '44444444-0009-0000-0000-000000000007',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000019', 'À une interdiction gouvernementale temporaire',                         false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000019', 'À plusieurs facteurs : aides, prix de l''électricité, autonomie réelle', true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000019', 'À l''absence totale de modèles disponibles',                            false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000019', 'Au rejet de l''écologie par les conducteurs',                           false, 4);

-- Q20 : CE B2 — Streaming (ton / position de l'auteur)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000020', 'TCF',
             '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
             'Quelle est la position de l''auteur sur le succès des plateformes de streaming ?',
             'L''auteur reconnaît les avantages (« certes, elles ont démocratisé l''accès… », « productions locales… ») puis introduit ses réserves (« mais on aurait tort d''en conclure que tout est positif »). Sa conclusion interrogative (« ne risque-t-on pas… ») renforce la prudence. Sa position est donc nuancée et critique, ni totalement favorable, ni hostile au point d''appeler à interdire, ni neutre.',
             '44444444-0009-0000-0000-000000000008',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000020', 'Il s''en réjouit pleinement',                              false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000020', 'Il reconnaît les apports mais émet des réserves critiques', true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000020', 'Il appelle à interdire ces plateformes',                    false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000020', 'Il n''exprime aucune opinion personnelle',                  false, 4);


-- ──────────────────────────────────────────────────────────────────────────
-- 🔴 NIVEAU B2 — Structure de la langue (4 questions)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : STRUCT B2 — Subjonctif après "bien que"
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000021', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_subjonctif_bien_que',
             'Complétez : « Bien qu''elle ___ très occupée, elle a accepté de nous recevoir. »',
             'La conjonction « bien que » est toujours suivie du subjonctif. À la 3e personne du singulier du verbe « être » au subjonctif présent, la forme est « soit ». « Est » et « était » sont des indicatifs (incompatibles avec « bien que »). « Serait » est un conditionnel (incompatible également).',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000021', 'est',     false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000021', 'soit',    true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000021', 'était',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000021', 'serait',  false, 4);

-- Q22 : STRUCT B2 — Hypothèse irréelle du passé — REFORMULÉE (sans participe accordé)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000022', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_hypothese_irreelle_passe',
             'Complétez : « Si tu avais étudié davantage, tu ___ ton examen sans difficulté. »',
             'Avec « si + plus-que-parfait » dans la subordonnée (« avais étudié »), la principale prend obligatoirement le conditionnel passé pour exprimer une hypothèse non réalisée dans le passé → « aurais réussi ». « Réussirais » est un conditionnel présent (compatible avec « si + imparfait », pas avec « si + plus-que-parfait »). « As réussi » est un passé composé. « Réussiras » est un futur.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000022', 'réussirais',    false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000022', 'aurais réussi', true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000022', 'as réussi',     false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000022', 'réussiras',     false, 4);

-- Q23 : STRUCT B2 — Pronom relatif composé "auquel" — EXPLICATION CLARIFIÉE
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000023', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_pronom_relatif_compose',
             'Complétez : « Le projet ___ je travaille depuis six mois sera bientôt terminé. »',
             'Le verbe « travailler » se construit avec la préposition « à » (travailler à quelque chose). Pour reprendre un complément masculin singulier introduit par « à », on emploie le pronom relatif composé « auquel » (contraction de « à + lequel »). « Que » remplace un complément d''objet direct, sans préposition. « Dont » remplace un complément introduit par « de ». « Lequel », sans la contraction avec « à », ne convient pas pour reprendre un complément introduit par « à ».',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000023', 'que',     false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000023', 'dont',    false, 2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000023', 'auquel',  true,  3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000023', 'lequel',  false, 4);

-- Q24 : STRUCT B2 — Connecteur concessif
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation,
    is_active, created_at, updated_at
) VALUES (
             '55555555-0009-0000-0000-000000000024', 'TCF',
             '22222222-0000-0000-0000-000000000003', 'B2', 'STRUCTURE', 'struct_connecteur_concessif',
             'Complétez : « ___ une légère hausse des prix, la fréquentation du musée reste stable. »',
             '« Malgré » est une préposition concessive qui se construit directement avec un nom ou un groupe nominal (« malgré une hausse »). « Bien que » et « quoique » sont des conjonctions qui se construisent avec un verbe au subjonctif, pas avec un nom. « Cependant » est un adverbe de liaison, qui relie deux propositions ; il ne peut pas introduire directement un groupe nominal.',
             true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         );
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000024', 'Bien que',  false, 1),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000024', 'Malgré',    true,  2),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000024', 'Quoique',   false, 3),
                                                                            (gen_random_uuid(), '55555555-0009-0000-0000-000000000024', 'Cependant', false, 4);