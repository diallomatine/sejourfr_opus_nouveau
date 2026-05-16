-- Flyway: niveau 3 thème 5 SOCIÉTÉ - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que signifie ''CDI'' dans un contrat de travail ?',
 'CDI = Contrat à durée indéterminée. C''est le contrat de travail standard en France, sans date de fin. Il ne peut être rompu que dans des conditions précises (démission, licenciement, rupture conventionnelle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Contrat à durée indéterminée', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Contrat à durée imposée', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Carte de droit international', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Compte de développement individuel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que signifie ''CDD'' dans un contrat de travail ?',
 'CDD = Contrat à durée déterminée. C''est un contrat de travail avec une date de fin précise. Il ne peut être utilisé que pour des motifs précis (remplacement, surcroît d''activité, saison).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Contrat à durée déterminée', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Carte de droit démocratique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Conseil d''aide à la décision', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Compte de domiciliation différée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que verse l''employeur en plus du salaire pour la Sécurité sociale ?',
 'L''employeur verse des cotisations sociales (patronales) en plus du salaire net. Le salarié cotise aussi (cotisations salariales). Ces cotisations financent la Sécurité sociale, le chômage, la retraite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Des cotisations sociales (patronales)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Un pourboire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Aucun montant supplémentaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quoi correspond le ''salaire brut'' ?',
 'Le salaire brut est le montant avant déduction des cotisations sociales salariales. Le salaire net (ce que le salarié touche) est obtenu après ces déductions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire avant cotisations sociales salariales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire après impôts', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire de l''employeur', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire le plus élevé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne l''URSSAF ?',
 'L''URSSAF collecte les cotisations sociales versées par les employeurs et les indépendants. Elle finance la Sécurité sociale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'L''organisme qui collecte les cotisations sociales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Une association sportive', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne le ''CESU'' ?',
 'Le CESU (Chèque emploi service universel) facilite l''emploi d''un salarié à domicile (garde d''enfant, ménage, soutien). Il simplifie les démarches administratives et offre des avantages fiscaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Chèque emploi service universel pour services à domicile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un chèque restaurant', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un chèque vacances', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la rupture conventionnelle ?',
 'La rupture conventionnelle est un accord entre l''employeur et le salarié pour mettre fin au CDI à l''amiable. Le salarié a droit à une indemnité et au chômage. Procédure encadrée.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Accord amiable pour rompre un CDI avec indemnités et droit chômage', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Une démission simple', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Un licenciement abusif', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Un contrat imposé', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que représente le ''préavis'' lors d''une démission ?',
 'Le préavis est la période pendant laquelle le salarié continue de travailler après avoir donné sa démission, pour permettre à l''employeur de s''organiser. La durée varie selon la convention collective.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'La période de travail après la démission avant le départ effectif', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Une lettre d''annonce uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Une amende', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Un licenciement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que fait l''inspection du travail ?',
 'L''inspection du travail veille au respect du Code du travail dans les entreprises. Elle peut être saisie par les salariés, contrôler les conditions de travail, sanctionner les employeurs en infraction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Contrôler le respect du Code du travail dans les entreprises', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Diriger les écoles', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Gérer les routes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel âge permet l''apprentissage en alternance en France ?',
 'L''apprentissage est ouvert aux jeunes dès 16 ans (parfois dès 15 ans en fin de 3e). L''âge limite a été porté à 29 ans révolus (avec exceptions). L''apprenti partage son temps entre entreprise et CFA.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', 'À partir de 16 ans (parfois 15)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', '12 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel certificat permet de devenir ''auto-entrepreneur'' ?',
 'Le régime de micro-entrepreneur (anciennement auto-entrepreneur) permet de démarrer une activité simplement, avec des formalités légères. Inscription en ligne sur le guichet unique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Une inscription simple au guichet unique des entreprises', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Un diplôme universitaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Une autorisation préfectorale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Un mariage civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quelle institution gère les retraites des salariés du privé ?',
 'L''assurance retraite (Cnav et caisses régionales) gère les retraites des salariés du privé (régime général). S''y ajoutent les retraites complémentaires (Agirc-Arrco).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'L''Assurance retraite (Cnav)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'La CAF', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'France Travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'L''Urssaf', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À quel âge peut-on prendre sa retraite en France ?',
 'L''âge légal de la retraite est de 64 ans depuis la réforme de 2023 (progressivement). Une retraite à taux plein peut être obtenue selon le nombre de trimestres cotisés (43 annuités à terme).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '64 ans (après la réforme de 2023)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '55 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '70 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '45 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne le ''compte personnel de formation'' (CPF) ?',
 'Le CPF est un compte attaché à chaque actif qui accumule des droits à la formation professionnelle (en euros). Il finance des formations qualifiantes, le permis de conduire, des bilans de compétences.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte de droits à la formation professionnelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte d''épargne immobilier', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte bancaire d''enfant', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte de fidélité', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un comité social et économique (CSE) ?',
 'Le CSE est l''instance représentative du personnel dans les entreprises de 11 salariés et plus. Il porte les préoccupations des salariés, gère les œuvres sociales, est consulté sur les grandes décisions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'L''instance représentative du personnel en entreprise', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Un comité des fêtes', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Un syndicat patronal', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Une association sportive', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la ''médecine du travail'' ?',
 'La médecine du travail organise les visites médicales obligatoires des salariés (à l''embauche, périodiques, de reprise après arrêt). Elle veille à la santé des salariés et conseille sur les conditions de travail.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'L''organisation des visites médicales et de la santé au travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'La médecine en hôpital', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'Le SAMU', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'Un syndicat de médecins', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un arrêt maladie en France ?',
 'L''arrêt maladie est prescrit par un médecin. Il faut transmettre l''arrêt à l''employeur (48h) et à l''Assurance maladie. Le salarié touche des indemnités journalières (Sécurité sociale + employeur selon convention).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Une suspension de travail prescrite par un médecin', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Un licenciement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Des vacances', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Un événement religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le congé maternité ?',
 'Le congé maternité est de 16 semaines pour un premier ou deuxième enfant (en général : 6 avant l''accouchement, 10 après). Plus pour les naissances multiples ou à partir du 3e enfant.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un congé légal autour de la naissance d''un enfant', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un congé religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un congé sabbatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un congé férié', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le congé paternité ?',
 'Le congé paternité est de 25 jours calendaires (35 pour naissances multiples) depuis juillet 2021. Le père ou la deuxième personne du couple parental peut en bénéficier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un congé légal de 25 jours pour le père/parent', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un congé interdit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un congé équivalent au maternité', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un congé religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la sécurité sociale en France ?',
 'La Sécurité sociale (créée en 1945) regroupe les régimes de protection sociale : maladie, vieillesse (retraite), famille (allocations), accidents du travail. Elle est financée par les cotisations sociales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'L''organisme de protection sociale (maladie, retraite, famille, AT)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Un service de police', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne le ''titre de séjour pluriannuel'' ?',
 'La carte de séjour pluriannuelle (CSP) est un titre de séjour valable jusqu''à 4 ans, délivré aux étrangers non européens après une première carte de séjour temporaire. Elle constitue une étape vers la carte de résident.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Une carte de séjour valable jusqu''à 4 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Un passeport diplomatique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Une carte de transport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne la ''carte de résident'' en France ?',
 'La carte de résident est un titre de séjour de 10 ans, renouvelable, délivré aux étrangers non européens établis en France de longue date. Elle confère une stabilité importante.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Une carte de séjour de 10 ans renouvelable', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Une carte courte', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Un passeport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Un permis de conduire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que l''OFII ?',
 'L''Office français de l''immigration et de l''intégration (OFII) accompagne les étrangers en France : visites médicales, contrat d''intégration républicaine (CIR), formations linguistiques et civiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'L''Office français de l''immigration et de l''intégration', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Un musée', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le contrat d''intégration républicaine (CIR) ?',
 'Le CIR est un contrat signé par les étrangers admis au séjour de longue durée en France. Il prévoit des formations civiques et linguistiques (selon niveau), pour faciliter l''intégration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat d''intégration avec formations civiques et linguistiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de travail', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de location', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de mariage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quels formations comprend le CIR ?',
 'Le CIR comprend une formation civique (4 jours sur les valeurs et institutions françaises) et, si nécessaire, une formation linguistique (jusqu''à 600h) pour atteindre le niveau A1 minimum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Formation civique et linguistique selon le niveau', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Uniquement militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Uniquement sportive', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Aucune formation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de français est exigé pour la carte de séjour pluriannuelle (CSP) ?',
 'Depuis 2026, le niveau A2 (utilisateur élémentaire avancé) est requis pour la CSP. Auparavant, c''était A1.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau A2 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau C2', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Aucun niveau de français', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau B2', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de français est exigé pour la carte de résident ?',
 'Depuis 2026, le niveau B1 (utilisateur indépendant) est requis pour la carte de résident. Auparavant, c''était A2.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau B1 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Aucun niveau requis', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau A2', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau C2', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de français est exigé pour la naturalisation ?',
 'Depuis 2026, le niveau B2 (utilisateur indépendant avancé) est requis pour la naturalisation française. Avant : B1.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau B2 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau A1', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Aucun niveau requis', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau C2 obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel diplôme obtient-on au lycée professionnel ?',
 'Le lycée professionnel prépare à un CAP (en 2 ans) puis à un baccalauréat professionnel (Bac pro, en 3 ans), donnant accès direct à l''emploi ou aux études supérieures.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Le CAP puis le baccalauréat professionnel', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Uniquement le brevet', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Uniquement le doctorat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Aucun diplôme', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne Parcoursup ?',
 'Parcoursup est la plateforme nationale d''orientation et d''inscription dans l''enseignement supérieur en France. Les lycéens y formulent leurs vœux pour les formations post-bac.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'La plateforme d''inscription dans l''enseignement supérieur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Un parti politique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne une ''CPGE'' en France ?',
 'Les Classes préparatoires aux grandes écoles (CPGE) sont une voie post-bac sélective, en 2 ans, qui prépare aux concours des grandes écoles (Polytechnique, HEC, ENS, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Classes préparatoires aux grandes écoles', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Un type de retraite', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Une compagnie aérienne', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Un syndicat étudiant', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne l''enseignement par alternance ?',
 'L''alternance combine études (en CFA ou école) et travail en entreprise (en apprentissage ou contrat de professionnalisation). L''élève est rémunéré.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Combiner études et travail en entreprise, avec rémunération', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Étudier en ligne uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Étudier le soir uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Étudier sans diplôme', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne la ''prime d''activité'' ?',
 'La prime d''activité est versée par la CAF aux travailleurs (salariés ou indépendants) aux faibles revenus, pour compléter leur rémunération et inciter au travail.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une aide aux travailleurs à faibles revenus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une prime pour faire du sport', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une cotisation patronale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Un impôt', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un dossier de surendettement ?',
 'Le dossier de surendettement, déposé à la Banque de France, est ouvert aux particuliers qui ne peuvent plus rembourser leurs dettes. Une commission examine et peut proposer un plan d''apurement ou un effacement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Une procédure auprès de la Banque de France pour les dettes excessives', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Une déclaration aux impôts', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Un mariage civil', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''une convention collective ?',
 'Une convention collective est un accord conclu entre syndicats de salariés et organisations patronales d''un secteur. Elle complète le Code du travail (salaires minimaux, congés, primes...).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Un accord syndical-patronal complétant le Code du travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Une loi parlementaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Une norme européenne', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Un décret présidentiel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e4', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'À qui s''adresse un demandeur d''asile en France ?',
 'Le demandeur d''asile doit s''adresser à la GUDA (guichet unique demandeur d''asile) puis à l''OFPRA, qui examine la demande de protection internationale (statut de réfugié, protection subsidiaire).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'À l''OFPRA via la GUDA', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'À la mairie uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'Au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel âge permet l''émancipation d''un mineur en France ?',
 'L''émancipation est possible dès 16 ans, prononcée par le juge des tutelles à la demande des parents ou du mineur. Le mineur émancipé devient juridiquement majeur (sauf droits politiques).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '16 ans, sur décision du juge des tutelles', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '14 ans automatiquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '12 ans par les parents', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', 'Impossible avant 18 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne la ''tutelle'' juridique ?',
 'La tutelle est une mesure de protection pour les personnes (majeures ou mineures) incapables de protéger leurs intérêts. Un tuteur (désigné par le juge) prend les décisions importantes pour la personne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une mesure de protection pour personnes vulnérables', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le ''service civique'' en France ?',
 'Le service civique est un engagement volontaire de 6 à 12 mois (jeunes 16-25 ans, 30 ans pour personnes en situation de handicap) pour une mission d''intérêt général. Indemnisé par l''État. Différents domaines : solidarité, environnement, culture.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un engagement volontaire des jeunes pour l''intérêt général', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Le service militaire obligatoire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un stage obligatoire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un mariage civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que désigne la ''caution'' dans la location d''un logement ?',
 'La caution (dépôt de garantie) est une somme versée au propriétaire au début du bail. Elle est restituée au départ, déduction faite des réparations locatives éventuelles. Maximum : 1 mois de loyer hors charges (vide).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Un dépôt de garantie restitué au départ, sauf réparations', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Un cadeau au propriétaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Une assurance auto', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je suis salarié et je veux changer d''emploi. Comment procéder ?',
 'On peut chercher en cours d''emploi (sans le dire), envoyer son CV, postuler. Une fois trouvé, on peut démissionner avec préavis. Possibilité de rupture conventionnelle. Bilan de compétences possible via le CPF.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Chercher, postuler, démissionner avec préavis ou rupture conventionnelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Quitter sans prévenir', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Refuser tout changement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je dois renouveler mon titre de séjour. Quand m''y prendre ?',
 'Le renouvellement doit être demandé 2 à 4 mois avant l''expiration du titre, en préfecture (souvent en ligne). Il faut justifier des conditions (revenus, intégration, situation familiale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', '2 à 4 mois avant l''expiration, en préfecture', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Après l''expiration', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Aucune démarche', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Demander au commissariat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Mon enfant doit changer d''école après notre déménagement. Comment faire ?',
 'Contacter l''ancienne école pour le certificat de radiation, puis inscrire l''enfant à la mairie de la nouvelle commune avec justificatif de domicile et livret de famille.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Certificat de radiation + inscription à la mairie de la nouvelle commune', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Pas besoin d''inscription', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Inscrire au commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Attendre l''année prochaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je ne parle pas bien français. Comment améliorer mon niveau pour ma carte de séjour ?',
 'Beaucoup d''options : formations OFII (CIR), associations (FLE), cours en médiathèque, plateformes en ligne. Les Greta et CFA proposent aussi des cours diplômants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Formations OFII, associations FLE, médiathèques, Greta', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Aucune solution', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Rester dans ma langue maternelle', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux accéder à un logement social rapidement. Quels recours ?',
 'Déposer le dossier en mairie ou auprès d''un bailleur social. Si attente trop longue, possibilité de saisir une commission DALO (droit au logement opposable) si on est prioritaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Demande mairie + recours DALO si attente excessive', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Aucune voie possible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Occuper un logement vide', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Dormir dans la rue', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je suis enceinte et salariée. Quels droits ai-je ?',
 'Informer l''employeur. Bénéficier de 16 semaines de congé maternité minimum, d''examens médicaux rémunérés pendant le travail, et de la protection contre le licenciement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Congé maternité 16 semaines, examens, protection licenciement', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Aucun droit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Licenciement automatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Renoncer à la grossesse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Mon employeur me doit du salaire en retard. Que faire ?',
 'Réclamer par écrit (lettre recommandée). En cas de refus, saisir l''inspection du travail puis les prud''hommes. On peut aussi faire un signalement à l''URSSAF si la situation se prolonge.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Réclamer par écrit puis prud''hommes / inspection du travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Ne rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Quitter sans rien dire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Voler la caisse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux comprendre la mutuelle d''entreprise. Est-elle obligatoire ?',
 'Depuis 2016, l''employeur du privé doit proposer une complémentaire santé (mutuelle) à tous ses salariés et prendre en charge au moins 50% de la cotisation. Le salarié peut parfois en être dispensé.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Obligatoire depuis 2016, 50% pris en charge par l''employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Strictement interdite', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Choisie librement par le salarié', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Toujours payée 100% par le salarié', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux scolariser mon enfant en milieu d''année. Est-ce possible ?',
 'Oui. Une scolarisation en cours d''année est possible (déménagement, arrivée en France). Il faut s''adresser à la mairie. L''enfant est accueilli à l''école de secteur. Des dispositifs UPE2A existent pour les non francophones.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Oui, inscription en mairie à tout moment', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Non, impossible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Uniquement en septembre', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Uniquement pour les Français', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux savoir comment fonctionne le RSA. Qui peut en bénéficier ?',
 'Le RSA est ouvert aux personnes de 25 ans et plus (ou 18-24 ans sous conditions) qui résident en France de manière stable, avec des revenus en dessous d''un certain plafond. La CAF l''examine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Personnes à faibles revenus, en général dès 25 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les retraités', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les Français', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les enfants', FALSE, 3);
