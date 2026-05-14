-- Flyway: niveau 3 theme 5 SOCIETE - 50 CR (40 CONN + 10 MS) - is_active=FALSE

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que signifie ''CDI'' dans un contrat de travail ?',
 'CDI = Contrat a duree indeterminee. C''est le contrat de travail standard en France, sans date de fin. Il ne peut etre rompu que dans des conditions precises (demission, licenciement, rupture conventionnelle).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Contrat a duree indeterminee', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Contrat a duree imposee', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Carte de droit international', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000033', 'Compte de developpement individuel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que signifie ''CDD'' dans un contrat de travail ?',
 'CDD = Contrat a duree determinee. C''est un contrat de travail avec une date de fin precise. Il ne peut etre utilise que pour des motifs precis (remplacement, surcroit d''activite, saison).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Contrat a duree determinee', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Carte de droit democratique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Conseil d''aide a la decision', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000034', 'Compte de domiciliation differee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que verse l''employeur en plus du salaire pour la Securite sociale ?',
 'L''employeur verse des cotisations sociales (patronales) en plus du salaire net. Le salarie cotise aussi (cotisations salariales). Ces cotisations financent la Securite sociale, le chomage, la retraite.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Des cotisations sociales (patronales)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Un pourboire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000035', 'Aucun montant supplementaire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quoi correspond le ''salaire brut'' ?',
 'Le salaire brut est le montant avant deduction des cotisations sociales salariales. Le salaire net (ce que le salarie touche) est obtenu apres ces deductions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire avant cotisations sociales salariales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire apres impots', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire de l''employeur', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000036', 'Le salaire le plus eleve', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe l''URSSAF ?',
 'L''URSSAF collecte les cotisations sociales versees par les employeurs et les independants. Elle finance la Securite sociale.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'L''organisme qui collecte les cotisations sociales', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Un parti politique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000037', 'Une association sportive', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe le ''CESU'' ?',
 'Le CESU (Cheque emploi service universel) facilite l''emploi d''un salarie a domicile (garde d''enfant, menage, soutien). Il simplifie les demarches administratives et offre des avantages fiscaux.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Cheque emploi service universel pour services a domicile', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un cheque restaurant', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un cheque vacances', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000038', 'Un syndicat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la rupture conventionnelle ?',
 'La rupture conventionnelle est un accord entre l''employeur et le salarie pour mettre fin au CDI a l''amiable. Le salarie a droit a une indemnite et au chomage. Procedure encadree.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Accord amiable pour rompre un CDI avec indemnites et droit chomage', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Une demission simple', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Un licenciement abusif', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000039', 'Un contrat impose', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que represente le ''preavis'' lors d''une demission ?',
 'Le preavis est la periode pendant laquelle le salarie continue de travailler apres avoir donne sa demission, pour permettre a l''employeur de s''organiser. La duree varie selon la convention collective.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'La periode de travail apres la demission avant le depart effectif', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Une lettre d''annonce uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Une amende', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003a', 'Un licenciement', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que fait l''inspection du travail ?',
 'L''inspection du travail veille au respect du Code du travail dans les entreprises. Elle peut etre saisie par les salaries, controler les conditions de travail, sanctionner les employeurs en infraction.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Controler le respect du Code du travail dans les entreprises', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Voter les lois', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Diriger les ecoles', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003b', 'Gerer les routes', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel age permet l''apprentissage en alternance en France ?',
 'L''apprentissage est ouvert aux jeunes des 16 ans (parfois des 15 ans en fin de 3e). L''age limite a ete porte a 29 ans revolus (avec exceptions). L''apprenti partage son temps entre entreprise et CFA.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', 'A partir de 16 ans (parfois 15)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', '12 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', '21 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003c', 'Aucune limite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel certificat permet de devenir ''auto-entrepreneur'' ?',
 'Le regime de micro-entrepreneur (anciennement auto-entrepreneur) permet de demarrer une activite simplement, avec des formalites legeres. Inscription en ligne sur le guichet unique.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Une inscription simple au guichet unique des entreprises', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Un diplome universitaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Une autorisation prefectorale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003d', 'Un mariage civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quelle institution gere les retraites des salaries du prive ?',
 'L''assurance retraite (Cnav et caisses regionales) gere les retraites des salaries du prive (regime general). S''y ajoutent les retraites complementaires (Agirc-Arrco).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'L''Assurance retraite (Cnav)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'La CAF', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'France Travail', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003e', 'L''Urssaf', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A quel age peut-on prendre sa retraite en France ?',
 'L''age legal de la retraite est de 64 ans depuis la reforme de 2023 (progressivement). Une retraite a taux plein peut etre obtenue selon le nombre de trimestres cotises (43 annuites a terme).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '64 ans (apres la reforme de 2023)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '55 ans', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '70 ans', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000003f', '45 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe le ''compte personnel de formation'' (CPF) ?',
 'Le CPF est un compte attache a chaque actif qui accumule des droits a la formation professionnelle (en euros). Il finance des formations qualifiantes, le permis de conduire, des bilans de competences.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte de droits a la formation professionnelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte d''epargne immobilier', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte bancaire d''enfant', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000040', 'Un compte de fidelite', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un comite social et economique (CSE) ?',
 'Le CSE est l''instance representative du personnel dans les entreprises de 11 salaries et plus. Il porte les preoccupations des salaries, gere les oeuvres sociales, est consulte sur les grandes decisions.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'L''instance representative du personnel en entreprise', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Un comite des fetes', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Un syndicat patronal', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000041', 'Une association sportive', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la ''medecine du travail'' ?',
 'La medecine du travail organise les visites medicales obligatoires des salaries (a l''embauche, periodiques, de reprise apres arret). Elle veille a la sante des salaries et conseille sur les conditions de travail.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'L''organisation des visites medicales et de la sante au travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'La medecine en hopital', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'Le SAMU', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000042', 'Un syndicat de medecins', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un arret maladie en France ?',
 'L''arret maladie est prescrit par un medecin. Il faut transmettre l''arret a l''employeur (48h) et a l''Assurance maladie. Le salarie touche des indemnites journalieres (Securite sociale + employeur selon convention).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Une suspension de travail prescrite par un medecin', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Un licenciement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Des vacances', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000043', 'Un evenement religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le conge maternite ?',
 'Le conge maternite est de 16 semaines pour un premier ou deuxieme enfant (en general : 6 avant l''accouchement, 10 apres). Plus pour les naissances multiples ou a partir du 3e enfant.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un conge legal autour de la naissance d''un enfant', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un conge religieux', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un conge sabbatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000044', 'Un conge ferie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le conge paternite ?',
 'Le conge paternite est de 25 jours calendaires (35 pour naissances multiples) depuis juillet 2021. Le pere ou la deuxieme personne du couple parental peut en beneficier.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un conge legal de 25 jours pour le pere/parent', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un conge interdit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un conge equivalent au maternite', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000045', 'Un conge religieux', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que la securite sociale en France ?',
 'La Securite sociale (creee en 1945) regroupe les regimes de protection sociale : maladie, vieillesse (retraite), famille (allocations), accidents du travail. Elle est financee par les cotisations sociales.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'L''organisme de protection sociale (maladie, retraite, famille, AT)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Un service de police', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000046', 'Un parti politique', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe le ''titre de sejour pluriannuel'' ?',
 'La carte de sejour pluriannuelle (CSP) est un titre de sejour valable jusqu''a 4 ans, delivre aux etrangers non europeens apres une premiere carte de sejour temporaire. Elle constitue une etape vers la carte de resident.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Une carte de sejour valable jusqu''a 4 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Un passeport diplomatique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Une carte de transport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000047', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe la ''carte de resident'' en France ?',
 'La carte de resident est un titre de sejour de 10 ans, renouvelable, delivre aux etrangers non europeens etablis en France de longue date. Elle confere une stabilite importante.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Une carte de sejour de 10 ans renouvelable', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Une carte courte', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Un passeport', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000048', 'Un permis de conduire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que l''OFII ?',
 'L''Office francais de l''immigration et de l''integration (OFII) accompagne les etrangers en France : visites medicales, contrat d''integration republicaine (CIR), formations linguistiques et civiques.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'L''Office francais de l''immigration et de l''integration', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Un syndicat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000049', 'Un musee', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le contrat d''integration republicaine (CIR) ?',
 'Le CIR est un contrat signe par les etrangers admis au sejour de longue duree en France. Il prevoit des formations civiques et linguistiques (selon niveau), pour faciliter l''integration.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat d''integration avec formations civiques et linguistiques', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de travail', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de location', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004a', 'Un contrat de mariage', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quels formations comprend le CIR ?',
 'Le CIR comprend une formation civique (4 jours sur les valeurs et institutions francaises) et, si necessaire, une formation linguistique (jusqu''a 600h) pour atteindre le niveau A1 minimum.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Formation civique et linguistique selon le niveau', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Uniquement militaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Uniquement sportive', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004b', 'Aucune formation', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de francais est exige pour la carte de sejour pluriannuelle (CSP) ?',
 'Depuis 2026, le niveau A2 (utilisateur elementaire avance) est requis pour la CSP. Auparavant, c''etait A1.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau A2 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau C2', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Aucun niveau de francais', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004c', 'Le niveau B2', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de francais est exige pour la carte de resident ?',
 'Depuis 2026, le niveau B1 (utilisateur independant) est requis pour la carte de resident. Auparavant, c''etait A2.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau B1 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Aucun niveau requis', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau A2', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004d', 'Le niveau C2', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel niveau de francais est exige pour la naturalisation ?',
 'Depuis 2026, le niveau B2 (utilisateur independant avance) est requis pour la naturalisation francaise. Avant : B1.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau B2 (depuis 2026)', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau A1', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Aucun niveau requis', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004e', 'Le niveau C2 obligatoire', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel diplome obtient-on au lycee professionnel ?',
 'Le lycee professionnel prepare a un CAP (en 2 ans) puis a un baccalaureat professionnel (Bac pro, en 3 ans), donnant acces direct a l''emploi ou aux etudes superieures.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Le CAP puis le baccalaureat professionnel', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Uniquement le brevet', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Uniquement le doctorat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000004f', 'Aucun diplome', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe Parcoursup ?',
 'Parcoursup est la plateforme nationale d''orientation et d''inscription dans l''enseignement superieur en France. Les lyceens y formulent leurs voeux pour les formations post-bac.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'La plateforme d''inscription dans l''enseignement superieur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Un parti politique', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Une banque', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000050', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe une ''CPGE'' en France ?',
 'Les Classes preparatoires aux grandes ecoles (CPGE) sont une voie post-bac selective, en 2 ans, qui prepare aux concours des grandes ecoles (Polytechnique, HEC, ENS, etc.).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Classes preparatoires aux grandes ecoles', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Un type de retraite', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Une compagnie aerienne', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000051', 'Un syndicat etudiant', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe l''enseignement par alternance ?',
 'L''alternance combine etudes (en CFA ou ecole) et travail en entreprise (en apprentissage ou contrat de professionnalisation). L''eleve est remunere.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Combiner etudes et travail en entreprise, avec remuneration', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Etudier en ligne uniquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Etudier le soir uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000052', 'Etudier sans diplome', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e1', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe la ''prime d''activite'' ?',
 'La prime d''activite est versee par la CAF aux travailleurs (salaries ou independants) aux faibles revenus, pour completer leur remuneration et inciter au travail.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une aide aux travailleurs a faibles revenus', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une prime pour faire du sport', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Une cotisation patronale', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e1', 'Un impot', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e2', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''un dossier de surendettement ?',
 'Le dossier de surendettement, depose a la Banque de France, est ouvert aux particuliers qui ne peuvent plus rembourser leurs dettes. Une commission examine et peut proposer un plan d''apurement ou un effacement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Une procedure aupres de la Banque de France pour les dettes excessives', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Une declaration aux impots', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Un mariage civil', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e2', 'Un permis de chasse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e3', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce qu''une convention collective ?',
 'Une convention collective est un accord conclu entre syndicats de salaries et organisations patronales d''un secteur. Elle complete le Code du travail (salaires minimaux, conges, primes...).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Un accord syndical-patronal completant le Code du travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Une loi parlementaire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Une norme europeenne', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e3', 'Un decret presidentiel', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e4', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'A qui s''adresse un demandeur d''asile en France ?',
 'Le demandeur d''asile doit s''adresser a la GUDA (guichet unique demandeur d''asile) puis a l''OFPRA, qui examine la demande de protection internationale (statut de refugie, protection subsidiaire).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'A l''OFPRA via la GUDA', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'Au commissariat', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'A la mairie uniquement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e4', 'Au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e5', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Quel age permet l''emancipation d''un mineur en France ?',
 'L''emancipation est possible des 16 ans, prononcee par le juge des tutelles a la demande des parents ou du mineur. Le mineur emancipe devient juridiquement majeur (sauf droits politiques).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '16 ans, sur decision du juge des tutelles', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '14 ans automatiquement', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', '12 ans par les parents', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e5', 'Impossible avant 18 ans', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e6', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe la ''tutelle'' juridique ?',
 'La tutelle est une mesure de protection pour les personnes (majeures ou mineures) incapables de proteger leurs interets. Un tuteur (designe par le juge) prend les decisions importantes pour la personne.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une mesure de protection pour personnes vulnerables', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Un syndicat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e6', 'Une assurance', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e7', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Qu''est-ce que le ''service civique'' en France ?',
 'Le service civique est un engagement volontaire de 6 a 12 mois (jeunes 16-25 ans, 30 ans pour handicapes) pour une mission d''interet general. Indemnise par l''Etat. Differents domaines : solidarite, environnement, culture.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un engagement volontaire des jeunes pour l''interet general', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Le service militaire obligatoire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un stage obligatoire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e7', 'Un mariage civil', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-0000000000e8', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'CONNAISSANCE',
 'Que designe la ''caution'' dans la location d''un logement ?',
 'La caution (depot de garantie) est une somme versee au proprietaire au debut du bail. Elle est restituee au depart, deduction faite des reparations locatives eventuelles. Maximum : 1 mois de loyer hors charges (vide).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Un depot de garantie restitue au depart, sauf reparations', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Une amende', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Un cadeau au proprietaire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-0000000000e8', 'Une assurance auto', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je suis salarie et je veux changer d''emploi. Comment proceder ?',
 'On peut chercher en cours d''emploi (sans le dire), envoyer son CV, postuler. Une fois trouve, on peut demissionner avec preavis. Possibilite de rupture conventionnelle. Bilan de competences possible via le CPF.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Chercher, postuler, demissionner avec preavis ou rupture conventionnelle', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Quitter sans prevenir', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Refuser tout changement', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000053', 'Demander au pape', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je dois renouveler mon titre de sejour. Quand m''y prendre ?',
 'Le renouvellement doit etre demande 2 a 4 mois avant l''expiration du titre, en prefecture (souvent en ligne). Il faut justifier des conditions (revenus, integration, situation familiale).',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', '2 a 4 mois avant l''expiration, en prefecture', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Apres l''expiration', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Aucune demarche', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000054', 'Demander au commissariat', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Mon enfant doit changer d''ecole apres notre demenagement. Comment faire ?',
 'Contacter l''ancienne ecole pour le certificat de radiation, puis inscrire l''enfant a la mairie de la nouvelle commune avec justificatif de domicile et livret de famille.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Certificat de radiation + inscription a la mairie de la nouvelle commune', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Pas besoin d''inscription', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Inscrire au commissariat', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000055', 'Attendre l''annee prochaine', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je ne parle pas bien francais. Comment ameliorer mon niveau pour ma carte de sejour ?',
 'Beaucoup d''options : formations OFII (CIR), associations (FLE), cours en mediatheque, plateformes en ligne. Les Greta et CFA proposent aussi des cours diplomants.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Formations OFII, associations FLE, mediatheques, Greta', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Aucune solution', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Rester dans ma langue maternelle', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000056', 'Quitter la France', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux acceder a un logement social rapidement. Quels recours ?',
 'Deposer le dossier en mairie ou aupres d''un bailleur social. Si attente trop longue, possibilite de saisir une commission DALO (droit au logement opposable) si on est prioritaire.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Demande mairie + recours DALO si attente excessive', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Aucune voie possible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Occuper un logement vide', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000057', 'Dormir dans la rue', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je suis enceinte et salariee. Quels droits ai-je ?',
 'Informer l''employeur. Beneficier de 16 semaines de conge maternite minimum, d''examens medicaux remuneres pendant le travail, et de la protection contre le licenciement.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Conge maternite 16 semaines, examens, protection licenciement', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Aucun droit', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Licenciement automatique', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000058', 'Renoncer a la grossesse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-000000000059', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Mon employeur me doit du salaire en retard. Que faire ?',
 'Reclamer par ecrit (lettre recommandee). En cas de refus, saisir l''inspection du travail puis les prud''hommes. On peut aussi faire un signalement a l''URSSAF si la situation se prolonge.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Reclamer par ecrit puis prud''hommes / inspection du travail', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Ne rien faire', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Quitter sans rien dire', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-000000000059', 'Voler la caisse', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux comprendre la mutuelle d''entreprise. Est-elle obligatoire ?',
 'Depuis 2016, l''employeur du prive doit proposer une complementaire sante (mutuelle) a tous ses salaries et prendre en charge au moins 50% de la cotisation. Le salarie peut parfois en etre dispense.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Obligatoire depuis 2016, 50% pris en charge par l''employeur', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Strictement interdite', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Choisie librement par le salarie', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005a', 'Toujours payee 100% par le salarie', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux scolariser mon enfant en milieu d''annee. Est-ce possible ?',
 'Oui. Une scolarisation en cours d''annee est possible (demenagement, arrivee en France). Il faut s''adresser a la mairie. L''enfant est accueilli a l''ecole de secteur. Des dispositifs UPE2A existent pour les non francophones.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Oui, inscription en mairie a tout moment', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Non, impossible', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Uniquement en septembre', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005b', 'Uniquement pour les Francais', FALSE, 3);

INSERT INTO questions (id, module, theme_id, difficulty, question_type, statement, explanation, is_active) VALUES
('f5000002-0000-0000-0000-00000000005c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', 'CR', 'MISE_SITUATION',
 'Je veux savoir comment fonctionne le RSA. Qui peut en beneficier ?',
 'Le RSA est ouvert aux personnes de 25 ans et plus (ou 18-24 ans sous conditions) qui resident en France de maniere stable, avec des revenus en dessous d''un certain plafond. La CAF l''examine.',
 FALSE);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Personnes a faibles revenus, en general des 25 ans', TRUE, 0),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les retraites', FALSE, 1),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les Francais', FALSE, 2),
(gen_random_uuid(), 'f5000002-0000-0000-0000-00000000005c', 'Uniquement les enfants', FALSE, 3);
