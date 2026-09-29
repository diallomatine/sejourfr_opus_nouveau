-- ============================================================================
-- V283 — Civique : Vivre en société (lot 3)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000005 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f5000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que doit-on faire en cas de perte de papiers d''identité ?',
   'Il faut signaler la perte au commissariat (déclaration de perte). Pour le renouvellement, on demande une nouvelle carte d''identité ou un passeport en mairie.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel numéro européen aide en cas de disparition d''enfant ?',
   'Le 116 000 est le numéro européen pour signaler une disparition d''enfant. Il est gratuit et fonctionne dans tous les pays de l''UE.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000029', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je viens d''avoir un enfant. Quelles démarches dois-je faire ?',
   'Déclarer la naissance à la mairie dans les 5 jours, prévenir la CAF, l''Assurance Maladie (carte Vitale), l''employeur (congés paternité/maternité), la mutuelle, l''école/crèche si nécessaire.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je perds mon emploi. Que dois-je faire en premier ?',
   'S''inscrire à France Travail (anciennement Pôle emploi) dans les meilleurs délais : c''est la condition pour percevoir des indemnités chômage (selon droits cotisés) et bénéficier d''un accompagnement.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'J''ai mal et je dois consulter un médecin. Quelles options ?',
   'Si non urgent, prendre rendez-vous avec son médecin traitant (en ligne, par téléphone). Sinon, SOS Médecins, maison de garde, télémédecine. En urgence vitale : 15 ou 112.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je n''arrive plus à payer mon loyer. À qui demander de l''aide ?',
   'Contacter la CAF (peut être une APL), le CCAS (centre communal d''action sociale) de la mairie, des associations (Restos du cœur, Secours populaire). Éviter d''accumuler les impayés.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Mon enfant a besoin de soutien scolaire. Quels recours sont disponibles ?',
   'Demander de l''aide à l''enseignant et au directeur d''école, profiter du soutien scolaire proposé en classe, recourir au CNED, demander un PPRE (plan d''aide), s''inscrire à des associations d''aide aux devoirs.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux inscrire mon enfant à l''école publique. Quelle démarche ?',
   'L''inscription se fait à la mairie (avec justificatifs : livret de famille, justificatif de domicile). Ensuite, l''admission est confirmée à l''école de secteur. La scolarité est gratuite.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000002f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux accéder à l''aide médicale en cas de difficulté financière. Quelles options ?',
   'Demander la PUMA (Protection universelle maladie). Si revenus très bas, demander la Complémentaire santé solidaire (C2S) qui prend en charge les frais de mutuelle. Les PASS (permanence d''accès aux soins de santé) dans les hôpitaux accueillent aussi.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000030', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je veux ouvrir un compte bancaire en France. Que faut-il ?',
   'Justificatif d''identité et de domicile, parfois preuve de revenus. En cas de refus par toutes les banques, on peut exercer le ''droit au compte'' auprès de la Banque de France.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000031', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Je suis témoin de violences conjugales chez un voisin. Quel comportement ?',
   'Appeler le 17 (police) si la situation est immédiate. Sinon, signaler au 3919 (violences conjugales), au 119 (enfance en danger si enfants). Ne pas intervenir physiquement seul.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000032', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Mon enfant subit du harcèlement à l''école. Que faire ?',
   'Alerter l''enseignant et le directeur. Si pas de réponse, l''inspection académique. Appeler le 3018 (numéro national contre le harcèlement scolaire). Une plainte est possible : le harcèlement est un délit.',
   'true', '2026-05-27 17:40:30.089544+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000033', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que signifie ''CDI'' dans un contrat de travail ?',
   'CDI = Contrat à durée indéterminée. C''est le contrat de travail standard en France, sans date de fin. Il ne peut être rompu que dans des conditions précises (démission, licenciement, rupture conventionnelle).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000034', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que signifie ''CDD'' dans un contrat de travail ?',
   'CDD = Contrat à durée déterminée. C''est un contrat de travail avec une date de fin précise. Il ne peut être utilisé que pour des motifs précis (remplacement, surcroît d''activité, saison).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000035', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que verse l''employeur en plus du salaire pour la Sécurité sociale ?',
   'L''employeur verse des cotisations sociales (patronales) en plus du salaire net. Le salarié cotise aussi (cotisations salariales). Ces cotisations financent la Sécurité sociale, le chômage, la retraite.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000036', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quoi correspond le ''salaire brut'' ?',
   'Le salaire brut est le montant avant déduction des cotisations sociales salariales. Le salaire net (ce que le salarié touche) est obtenu après ces déductions.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000037', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne l''URSSAF ?',
   'L''URSSAF collecte les cotisations sociales versées par les employeurs et les indépendants. Elle finance la Sécurité sociale.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000038', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne le ''CESU'' ?',
   'Le CESU (Chèque emploi service universel) facilite l''emploi d''un salarié à domicile (garde d''enfant, ménage, soutien). Il simplifie les démarches administratives et offre des avantages fiscaux.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000039', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la rupture conventionnelle ?',
   'La rupture conventionnelle est un accord entre l''employeur et le salarié pour mettre fin au CDI à l''amiable. Le salarié a droit à une indemnité et au chômage. Procédure encadrée.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que représente le ''préavis'' lors d''une démission ?',
   'Le préavis est la période pendant laquelle le salarié continue de travailler après avoir donné sa démission, pour permettre à l''employeur de s''organiser. La durée varie selon la convention collective.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que fait l''inspection du travail ?',
   'L''inspection du travail veille au respect du Code du travail dans les entreprises. Elle peut être saisie par les salariés, contrôler les conditions de travail, sanctionner les employeurs en infraction.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel âge permet l''apprentissage en alternance en France ?',
   'L''apprentissage est ouvert aux jeunes dès 16 ans (parfois dès 15 ans en fin de 3e). L''âge limite a été porté à 29 ans révolus (avec exceptions). L''apprenti partage son temps entre entreprise et CFA.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel certificat permet de devenir ''auto-entrepreneur'' ?',
   'Le régime de micro-entrepreneur (anciennement auto-entrepreneur) permet de démarrer une activité simplement, avec des formalités légères. Inscription en ligne sur le guichet unique.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle institution gère les retraites des salariés du privé ?',
   'L''assurance retraite (Cnav et caisses régionales) gère les retraites des salariés du privé (régime général). S''y ajoutent les retraites complémentaires (Agirc-Arrco).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000003f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'À quel âge peut-on prendre sa retraite en France ?',
   'L''âge légal de la retraite est de 64 ans depuis la réforme de 2023 (progressivement). Une retraite à taux plein peut être obtenue selon le nombre de trimestres cotisés (43 annuités à terme).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000040', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne le ''compte personnel de formation'' (CPF) ?',
   'Le CPF est un compte attaché à chaque actif qui accumule des droits à la formation professionnelle (en euros). Il finance des formations qualifiantes, le permis de conduire, des bilans de compétences.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000041', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce qu''un comité social et économique (CSE) ?',
   'Le CSE est l''instance représentative du personnel dans les entreprises de 11 salariés et plus. Il porte les préoccupations des salariés, gère les œuvres sociales, est consulté sur les grandes décisions.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000042', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la ''médecine du travail'' ?',
   'La médecine du travail organise les visites médicales obligatoires des salariés (à l''embauche, périodiques, de reprise après arrêt). Elle veille à la santé des salariés et conseille sur les conditions de travail.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000043', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce qu''un arrêt maladie en France ?',
   'L''arrêt maladie est prescrit par un médecin. Il faut transmettre l''arrêt à l''employeur (48h) et à l''Assurance maladie. Le salarié touche des indemnités journalières (Sécurité sociale + employeur selon convention).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000044', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le congé maternité ?',
   'Le congé maternité est de 16 semaines pour un premier ou deuxième enfant (en général : 6 avant l''accouchement, 10 après). Plus pour les naissances multiples ou à partir du 3e enfant.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000045', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le congé paternité ?',
   'Le congé paternité est de 25 jours calendaires (35 pour naissances multiples) depuis juillet 2021. Le père ou la deuxième personne du couple parental peut en bénéficier.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000046', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que la sécurité sociale en France ?',
   'La Sécurité sociale (créée en 1945) regroupe les régimes de protection sociale : maladie, vieillesse (retraite), famille (allocations), accidents du travail. Elle est financée par les cotisations sociales.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000047', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne le ''titre de séjour pluriannuel'' ?',
   'La carte de séjour pluriannuelle (CSP) est un titre de séjour valable jusqu''à 4 ans, délivré aux étrangers non européens après une première carte de séjour temporaire. Elle constitue une étape vers la carte de résident.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000048', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne la ''carte de résident'' en France ?',
   'La carte de résident est un titre de séjour de 10 ans, renouvelable, délivré aux étrangers non européens établis en France de longue date. Elle confère une stabilité importante.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000049', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que l''OFII ?',
   'L''Office français de l''immigration et de l''intégration (OFII) accompagne les étrangers en France : visites médicales, contrat d''intégration républicaine (CIR), formations linguistiques et civiques.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004a', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Qu''est-ce que le contrat d''intégration républicaine (CIR) ?',
   'Le CIR est un contrat signé par les étrangers admis au séjour de longue durée en France. Il prévoit des formations civiques et linguistiques (selon niveau), pour faciliter l''intégration.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004b', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels formations comprend le CIR ?',
   'Le CIR comprend une formation civique (4 jours sur les valeurs et institutions françaises) et, si nécessaire, une formation linguistique (jusqu''à 600h) pour atteindre le niveau A1 minimum.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004c', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel niveau de français est exigé pour la carte de séjour pluriannuelle (CSP) ?',
   'Depuis 2026, le niveau A2 (utilisateur élémentaire avancé) est requis pour la CSP. Auparavant, c''était A1.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004d', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel niveau de français est exigé pour la carte de résident ?',
   'Depuis 2026, le niveau B1 (utilisateur indépendant) est requis pour la carte de résident. Auparavant, c''était A2.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004e', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel niveau de français est exigé pour la naturalisation ?',
   'Depuis 2026, le niveau B2 (utilisateur indépendant avancé) est requis pour la naturalisation française. Avant : B1.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-00000000004f', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel diplôme obtient-on au lycée professionnel ?',
   'Le lycée professionnel prépare à un CAP (en 2 ans) puis à un baccalauréat professionnel (Bac pro, en 3 ans), donnant accès direct à l''emploi ou aux études supérieures.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000050', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne Parcoursup ?',
   'Parcoursup est la plateforme nationale d''orientation et d''inscription dans l''enseignement supérieur en France. Les lycéens y formulent leurs vœux pour les formations post-bac.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000051', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne une ''CPGE'' en France ?',
   'Les Classes préparatoires aux grandes écoles (CPGE) sont une voie post-bac sélective, en 2 ans, qui prépare aux concours des grandes écoles (Polytechnique, HEC, ENS, etc.).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000052', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne l''enseignement par alternance ?',
   'L''alternance combine études (en CFA ou école) et travail en entreprise (en apprentissage ou contrat de professionnalisation). L''élève est rémunéré.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000053', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je suis salarié et je veux changer d''emploi. Comment procéder ?',
   'On peut chercher en cours d''emploi (sans le dire), envoyer son CV, postuler. Une fois trouvé, on peut démissionner avec préavis. Possibilité de rupture conventionnelle. Bilan de compétences possible via le CPF.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000054', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je dois renouveler mon titre de séjour. Quand m''y prendre ?',
   'Le renouvellement doit être demandé 2 à 4 mois avant l''expiration du titre, en préfecture (souvent en ligne). Il faut justifier des conditions (revenus, intégration, situation familiale).',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000055', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Mon enfant doit changer d''école après notre déménagement. Comment faire ?',
   'Contacter l''ancienne école pour le certificat de radiation, puis inscrire l''enfant à la mairie de la nouvelle commune avec justificatif de domicile et livret de famille.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000056', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je ne parle pas bien français. Comment améliorer mon niveau pour ma carte de séjour ?',
   'Beaucoup d''options : formations OFII (CIR), associations (FLE), cours en médiathèque, plateformes en ligne. Les Greta et CFA proposent aussi des cours diplômants.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000057', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je veux accéder à un logement social rapidement. Quels recours ?',
   'Déposer le dossier en mairie ou auprès d''un bailleur social. Si attente trop longue, possibilité de saisir une commission DALO (droit au logement opposable) si on est prioritaire.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f5000002-0000-0000-0000-000000000058', 'CIVIQUE', '11111111-0000-0000-0000-000000000005', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Je suis enceinte et salariée. Quels droits ai-je ?',
   'Informer l''employeur. Bénéficier de 16 semaines de congé maternité minimum, d''examens médicaux rémunérés pendant le travail, et de la protection contre le licenciement.',
   'true', '2026-05-27 17:40:30.108699+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('3c27727a-4316-461c-a1ae-5e968e3b5b0a', 'f5000002-0000-0000-0000-000000000027',
   'Déclarer la perte au commissariat puis demander un renouvellement',
   'true', '0'),

  ('5cd6d9a2-dab2-4ce5-9f25-828b1b7e0b9f', 'f5000002-0000-0000-0000-000000000027',
   'Ne rien faire',
   'false', '1'),

  ('093e2454-55b1-4ac8-bde9-7c10c3d29b8e', 'f5000002-0000-0000-0000-000000000027',
   'Mentir sur son identité',
   'false', '2'),

  ('1f803dad-4de0-475e-b004-f69b1ddceb04', 'f5000002-0000-0000-0000-000000000027',
   'Quitter la France',
   'false', '3'),

  ('0fbae14d-5b81-446d-9062-4c701ae9c26c', 'f5000002-0000-0000-0000-000000000028',
   'Le 116 000',
   'true', '0'),

  ('c305d24d-c125-42e4-a57a-01074212e50a', 'f5000002-0000-0000-0000-000000000028',
   'Le 15',
   'false', '1'),

  ('3c8012fb-5063-490d-8ecc-d3f6a56429c8', 'f5000002-0000-0000-0000-000000000028',
   'Le 17',
   'false', '2'),

  ('7546c2a3-60c4-4641-a9a2-a68d394c1d89', 'f5000002-0000-0000-0000-000000000028',
   'Le 911',
   'false', '3'),

  ('d2033cf6-f8a6-4bb5-bb49-9a5c71e425f7', 'f5000002-0000-0000-0000-000000000029',
   'Mairie, CAF, Assurance Maladie, employeur, mutuelle',
   'true', '0'),

  ('43ed819b-a452-4ba8-9d6d-2915becd9152', 'f5000002-0000-0000-0000-000000000029',
   'Aucune démarche',
   'false', '1'),

  ('75855f68-45b7-4cfb-b2c0-7caf1feb47f2', 'f5000002-0000-0000-0000-000000000029',
   'Uniquement l''école',
   'false', '2'),

  ('be38f87c-4ddb-4fff-83a9-45f58746e98b', 'f5000002-0000-0000-0000-000000000029',
   'Uniquement le pape',
   'false', '3'),

  ('ca47250a-294d-4746-9023-8291f79e7609', 'f5000002-0000-0000-0000-00000000002a',
   'S''inscrire à France Travail rapidement',
   'true', '0'),

  ('6bdc6316-9f8d-432d-a688-472fd986584e', 'f5000002-0000-0000-0000-00000000002a',
   'Ne rien faire',
   'false', '1'),

  ('f4e0afaa-8589-4f9e-90b4-28ab1b3e4d5a', 'f5000002-0000-0000-0000-00000000002a',
   'Quitter la France',
   'false', '2'),

  ('e155cfc6-41b5-40a3-8884-6be12ab21d32', 'f5000002-0000-0000-0000-00000000002a',
   'Demander à la mairie un travail',
   'false', '3'),

  ('e0b36eab-1e33-43db-ad7f-625291feadb0', 'f5000002-0000-0000-0000-00000000002b',
   'Médecin traitant en général, urgences en cas grave',
   'true', '0'),

  ('ca5f6454-cc7e-447b-ac24-8670d6a7b41f', 'f5000002-0000-0000-0000-00000000002b',
   'Aller directement aux urgences quoi qu''il arrive',
   'false', '1'),

  ('f46c72af-2211-4ef0-bf1c-d2a88bcf047b', 'f5000002-0000-0000-0000-00000000002b',
   'Attendre que ça passe',
   'false', '2'),

  ('aa704260-398b-429a-b117-e0f56510e6e4', 'f5000002-0000-0000-0000-00000000002b',
   'Demander à un voisin',
   'false', '3'),

  ('b9c46165-3a08-4461-b00a-42f0d37a2e10', 'f5000002-0000-0000-0000-00000000002c',
   'CAF, CCAS de la mairie, associations sociales',
   'true', '0'),

  ('703bc9af-8f91-4b72-9eaf-31e13bfc58d2', 'f5000002-0000-0000-0000-00000000002c',
   'Aucune aide n''existe',
   'false', '1'),

  ('4cfbdf0e-44b7-49cb-9692-af31171685ac', 'f5000002-0000-0000-0000-00000000002c',
   'Quitter le logement sans rien dire',
   'false', '2'),

  ('cc840532-fd27-4518-8fbc-3b7c52e37739', 'f5000002-0000-0000-0000-00000000002c',
   'Insulter le propriétaire',
   'false', '3'),

  ('0a4487d5-b395-4f65-b357-59b43d987ebb', 'f5000002-0000-0000-0000-00000000002d',
   'Soutien scolaire école, aide aux devoirs en associations',
   'true', '0'),

  ('34723236-f4d8-4ec1-9989-d63ce7ae91dd', 'f5000002-0000-0000-0000-00000000002d',
   'Ne rien faire',
   'false', '1'),

  ('f004365f-d1d0-418a-bc3b-e7d13ef62805', 'f5000002-0000-0000-0000-00000000002d',
   'Changer d''école sans concertation',
   'false', '2'),

  ('d85893fd-7d6c-46b8-a459-b561aaa62402', 'f5000002-0000-0000-0000-00000000002d',
   'Renvoyer l''enfant à la maison',
   'false', '3'),

  ('7d479f6b-7087-4d7c-8b4f-935595b0dab2', 'f5000002-0000-0000-0000-00000000002e',
   'Inscription à la mairie de la commune de résidence',
   'true', '0'),

  ('44b56558-6764-4133-b228-387e9cab64f3', 'f5000002-0000-0000-0000-00000000002e',
   'Inscription à la préfecture',
   'false', '1'),

  ('430426d9-a9c6-4f96-af58-5be2fd167bdc', 'f5000002-0000-0000-0000-00000000002e',
   'Inscription au commissariat',
   'false', '2'),

  ('cb4d49b0-5991-4d8b-98f4-42de41556320', 'f5000002-0000-0000-0000-00000000002e',
   'Aucune inscription nécessaire',
   'false', '3'),

  ('d1eb6ad0-5d98-4892-8063-fd27aadc9f53', 'f5000002-0000-0000-0000-00000000002f',
   'PUMA + Complémentaire santé solidaire (C2S) + PASS hospitaliers',
   'true', '0'),

  ('d58a9ca8-36ed-421b-9a6e-5c2890a55839', 'f5000002-0000-0000-0000-00000000002f',
   'Renoncer aux soins',
   'false', '1'),

  ('b187e94a-3539-46a6-ae7a-f71f7949cb16', 'f5000002-0000-0000-0000-00000000002f',
   'Payer intégralement',
   'false', '2'),

  ('3aff2a5d-945d-4fdb-89ce-4ffaadc66a07', 'f5000002-0000-0000-0000-00000000002f',
   'Aller chez un guérisseur',
   'false', '3'),

  ('51738c2b-fead-4b4b-a4b2-ce3e79e2d1c8', 'f5000002-0000-0000-0000-000000000030',
   'Pièces d''identité et de domicile ; droit au compte en cas de refus',
   'true', '0'),

  ('061c0bcc-01ec-4a0a-9797-6a7981d2b5b9', 'f5000002-0000-0000-0000-000000000030',
   'Rien n''est nécessaire',
   'false', '1'),

  ('3a839298-8294-4d70-8e5d-4803a1e47d18', 'f5000002-0000-0000-0000-000000000030',
   'Une recommandation du maire',
   'false', '2'),

  ('704bd95c-f069-456d-a367-bcd6759c662f', 'f5000002-0000-0000-0000-000000000030',
   'Un parrainage de 10 personnes',
   'false', '3'),

  ('d354eed4-c94a-441d-a777-931d5776a266', 'f5000002-0000-0000-0000-000000000031',
   'Appeler le 17, signaler au 3919 ou 119',
   'true', '0'),

  ('028f981c-1d0d-47a0-8fef-82bb3be1f5b5', 'f5000002-0000-0000-0000-000000000031',
   'Ne rien faire',
   'false', '1'),

  ('583db205-f5b4-479c-a6ad-6e6d364b7f5a', 'f5000002-0000-0000-0000-000000000031',
   'Intervenir physiquement seul',
   'false', '2'),

  ('b442f4b2-22b1-4f38-bdef-1906ffc652b0', 'f5000002-0000-0000-0000-000000000031',
   'Quitter le quartier',
   'false', '3'),

  ('53b242f6-3201-4d48-9eb7-d3f063575ba3', 'f5000002-0000-0000-0000-000000000032',
   'Alerter l''école, l''inspection, appeler le 3018, plainte si nécessaire',
   'true', '0'),

  ('27c053a0-9124-4362-8003-a75d55ea3924', 'f5000002-0000-0000-0000-000000000032',
   'Ne rien faire',
   'false', '1'),

  ('271f6949-e49c-4256-8ff0-2f08e538d848', 'f5000002-0000-0000-0000-000000000032',
   'Punir l''enfant victime',
   'false', '2'),

  ('25c378a6-4856-48c8-a47b-2316fe1f6b4d', 'f5000002-0000-0000-0000-000000000032',
   'Changer de pays',
   'false', '3'),

  ('3829f3e8-61e1-41da-b4d2-778ad76c47b7', 'f5000002-0000-0000-0000-000000000033',
   'Contrat à durée indéterminée',
   'true', '0'),

  ('042250f9-5907-4d67-92e9-75ebf80036bb', 'f5000002-0000-0000-0000-000000000033',
   'Contrat à durée imposée',
   'false', '1'),

  ('00aba1d5-29ec-446c-a463-de3221622015', 'f5000002-0000-0000-0000-000000000033',
   'Carte de droit international',
   'false', '2'),

  ('b58e740c-2d2c-4afa-a48f-3f2ccc3ddb6d', 'f5000002-0000-0000-0000-000000000033',
   'Compte de développement individuel',
   'false', '3'),

  ('e63f48c7-5a90-4a48-925e-aa8966308495', 'f5000002-0000-0000-0000-000000000034',
   'Contrat à durée déterminée',
   'true', '0'),

  ('237527c9-c342-4950-9126-69f842197dce', 'f5000002-0000-0000-0000-000000000034',
   'Carte de droit démocratique',
   'false', '1'),

  ('492c7ace-ca38-4446-a2e1-d85749a4a553', 'f5000002-0000-0000-0000-000000000034',
   'Conseil d''aide à la décision',
   'false', '2'),

  ('36e4f397-2ae0-45fb-a5bc-e6e87bd48f17', 'f5000002-0000-0000-0000-000000000034',
   'Compte de domiciliation différée',
   'false', '3'),

  ('93e7e702-f398-4125-be77-2fc74d726cf5', 'f5000002-0000-0000-0000-000000000035',
   'Des cotisations sociales (patronales)',
   'true', '0'),

  ('a1c358c4-870b-4487-b2ce-3d914dddad6d', 'f5000002-0000-0000-0000-000000000035',
   'Une amende',
   'false', '1'),

  ('d1003b40-abb9-426a-98c1-71ae763dd1c9', 'f5000002-0000-0000-0000-000000000035',
   'Un pourboire',
   'false', '2'),

  ('c6b03dc3-b856-47b4-8e71-156deb76bb81', 'f5000002-0000-0000-0000-000000000035',
   'Aucun montant supplémentaire',
   'false', '3'),

  ('de05bd2b-8e20-439c-b6b6-872894205b90', 'f5000002-0000-0000-0000-000000000036',
   'Le salaire avant cotisations sociales salariales',
   'true', '0'),

  ('0f3b566a-d5fc-4b7c-a757-5db19ced40d8', 'f5000002-0000-0000-0000-000000000036',
   'Le salaire après impôts',
   'false', '1'),

  ('089ce322-fc80-433b-aba1-142f1905b7fc', 'f5000002-0000-0000-0000-000000000036',
   'Le salaire de l''employeur',
   'false', '2'),

  ('e4cb0be9-84a2-41f1-9023-734a0fed56ad', 'f5000002-0000-0000-0000-000000000036',
   'Le salaire le plus élevé',
   'false', '3'),

  ('cd62c32e-1869-4af5-86e0-749dec204e94', 'f5000002-0000-0000-0000-000000000037',
   'L''organisme qui collecte les cotisations sociales',
   'true', '0'),

  ('765095a0-28df-4c3f-abd3-d84830716a85', 'f5000002-0000-0000-0000-000000000037',
   'Un syndicat',
   'false', '1'),

  ('f3ec7ac1-29a5-4e15-98cf-6e0497e634ac', 'f5000002-0000-0000-0000-000000000037',
   'Un parti politique',
   'false', '2'),

  ('4d3fbd1c-08cc-44df-8ddc-9e800ba6119e', 'f5000002-0000-0000-0000-000000000037',
   'Une association sportive',
   'false', '3'),

  ('94f6aa92-3d98-4280-920f-6fee76744479', 'f5000002-0000-0000-0000-000000000038',
   'Chèque emploi service universel pour services à domicile',
   'true', '0'),

  ('75e0bbb4-f113-44f9-b740-9eaac186de55', 'f5000002-0000-0000-0000-000000000038',
   'Un chèque restaurant',
   'false', '1'),

  ('f11d375b-4a83-4f76-9297-2dc9741bc91f', 'f5000002-0000-0000-0000-000000000038',
   'Un chèque vacances',
   'false', '2'),

  ('4c7e53c0-ee89-4e41-914c-4fe3112b2357', 'f5000002-0000-0000-0000-000000000038',
   'Un syndicat',
   'false', '3'),

  ('8ed3905a-f6f8-44cb-96e0-89345b777746', 'f5000002-0000-0000-0000-000000000039',
   'Accord amiable pour rompre un CDI avec indemnités et droit chômage',
   'true', '0'),

  ('e25b8538-ef68-44d8-88b0-c319efe19079', 'f5000002-0000-0000-0000-000000000039',
   'Une démission simple',
   'false', '1'),

  ('2594165d-8da8-4a10-83d1-d6bacb23be4d', 'f5000002-0000-0000-0000-000000000039',
   'Un licenciement abusif',
   'false', '2'),

  ('e5a82f2c-a149-4e2b-a080-ec051a4fccce', 'f5000002-0000-0000-0000-000000000039',
   'Un contrat imposé',
   'false', '3'),

  ('18dc7f1a-930b-4f8b-813a-527d84ed7165', 'f5000002-0000-0000-0000-00000000003a',
   'La période de travail après la démission avant le départ effectif',
   'true', '0'),

  ('7e781fc3-59c8-4b17-8de5-30a396bb9006', 'f5000002-0000-0000-0000-00000000003a',
   'Une lettre d''annonce uniquement',
   'false', '1'),

  ('19a6cc46-8816-4384-a0da-aefa5f366710', 'f5000002-0000-0000-0000-00000000003a',
   'Une amende',
   'false', '2'),

  ('e48fa1e2-77ee-464d-af62-1255d31c26e1', 'f5000002-0000-0000-0000-00000000003a',
   'Un licenciement',
   'false', '3'),

  ('e97e7e0e-9f54-4cdd-a204-1d5026a1ee34', 'f5000002-0000-0000-0000-00000000003b',
   'Contrôler le respect du Code du travail dans les entreprises',
   'true', '0'),

  ('830e3094-79e7-4494-bbe1-c56ed7a8970e', 'f5000002-0000-0000-0000-00000000003b',
   'Voter les lois',
   'false', '1'),

  ('9d857c60-edc8-4915-93bf-8b8441c69814', 'f5000002-0000-0000-0000-00000000003b',
   'Diriger les écoles',
   'false', '2'),

  ('b33c97c7-2ff3-465a-97f3-5f637c7a46f7', 'f5000002-0000-0000-0000-00000000003b',
   'Gérer les routes',
   'false', '3'),

  ('60427848-058c-4ad9-90c2-5277acc95dcd', 'f5000002-0000-0000-0000-00000000003c',
   'À partir de 16 ans (parfois 15)',
   'true', '0'),

  ('db3fc467-381c-4d81-a4d2-1ce973bfb0ac', 'f5000002-0000-0000-0000-00000000003c',
   '12 ans',
   'false', '1'),

  ('7692cab9-78e3-4d10-abf1-782eabfd35df', 'f5000002-0000-0000-0000-00000000003c',
   '21 ans',
   'false', '2'),

  ('90c9baa1-ba94-40cb-9715-83255f9577c0', 'f5000002-0000-0000-0000-00000000003c',
   'Aucune limite',
   'false', '3'),

  ('1cc0bf3f-0986-4180-8394-fda448966cdd', 'f5000002-0000-0000-0000-00000000003d',
   'Une inscription simple au guichet unique des entreprises',
   'true', '0'),

  ('ee7af2f3-fc18-4b91-8ffb-b2964c6e0816', 'f5000002-0000-0000-0000-00000000003d',
   'Un diplôme universitaire',
   'false', '1'),

  ('944804a1-ec21-4af2-a5a8-3d95705014af', 'f5000002-0000-0000-0000-00000000003d',
   'Une autorisation préfectorale',
   'false', '2'),

  ('c5e5a028-3681-4d8a-9d1a-bc8fdae6ec44', 'f5000002-0000-0000-0000-00000000003d',
   'Un mariage civil',
   'false', '3'),

  ('4fdb7716-4ade-4dfd-9a22-83ea46c90547', 'f5000002-0000-0000-0000-00000000003e',
   'L''Assurance retraite (Cnav)',
   'true', '0'),

  ('5b4e7962-1fd2-42e4-a49c-3d3044aad2f2', 'f5000002-0000-0000-0000-00000000003e',
   'La CAF',
   'false', '1'),

  ('71997e47-77a8-4695-bf2b-134d03f1f213', 'f5000002-0000-0000-0000-00000000003e',
   'France Travail',
   'false', '2'),

  ('5320088b-1102-4b2f-8f36-ef86bda3cbcd', 'f5000002-0000-0000-0000-00000000003e',
   'L''Urssaf',
   'false', '3'),

  ('4ed41a68-0771-49b9-ab4f-611a789f8ca8', 'f5000002-0000-0000-0000-00000000003f',
   '64 ans (après la réforme de 2023)',
   'true', '0'),

  ('cfd7c7e3-3eb4-4cdb-ae5e-e54368b4979d', 'f5000002-0000-0000-0000-00000000003f',
   '55 ans',
   'false', '1'),

  ('ea7511c0-6349-4cb0-aace-0de6f9cc5fdd', 'f5000002-0000-0000-0000-00000000003f',
   '70 ans',
   'false', '2'),

  ('5e52726f-a578-4977-a70b-39cdb853356c', 'f5000002-0000-0000-0000-00000000003f',
   '45 ans',
   'false', '3'),

  ('c7d87bd7-872b-485a-beab-3ea9b68f360e', 'f5000002-0000-0000-0000-000000000040',
   'Un compte de droits à la formation professionnelle',
   'true', '0'),

  ('e74dbc37-3422-46b6-9ed6-4474b77796a9', 'f5000002-0000-0000-0000-000000000040',
   'Un compte d''épargne immobilier',
   'false', '1'),

  ('06aca439-dfeb-4879-a54d-5f2857c14611', 'f5000002-0000-0000-0000-000000000040',
   'Un compte bancaire d''enfant',
   'false', '2'),

  ('5a0600a7-db8c-4d22-ae7a-42b8deba7f84', 'f5000002-0000-0000-0000-000000000040',
   'Un compte de fidélité',
   'false', '3'),

  ('7664601f-ec8f-4aa0-8396-fd201519413c', 'f5000002-0000-0000-0000-000000000041',
   'L''instance représentative du personnel en entreprise',
   'true', '0'),

  ('b3bc6a1f-03fa-42c2-901b-73a60493ce56', 'f5000002-0000-0000-0000-000000000041',
   'Un comité des fêtes',
   'false', '1'),

  ('82c31652-eb25-4c22-b3a5-09eae09efc50', 'f5000002-0000-0000-0000-000000000041',
   'Un syndicat patronal',
   'false', '2'),

  ('53d811d9-8d6b-4730-b206-21d2cd71ee5e', 'f5000002-0000-0000-0000-000000000041',
   'Une association sportive',
   'false', '3'),

  ('a98f6068-40b5-4e38-b113-b59dca589c77', 'f5000002-0000-0000-0000-000000000042',
   'L''organisation des visites médicales et de la santé au travail',
   'true', '0'),

  ('0109f464-ea16-413f-ade9-eadb3bb2c8a2', 'f5000002-0000-0000-0000-000000000042',
   'La médecine en hôpital',
   'false', '1'),

  ('454f37bc-bed7-41d9-937d-aed4d0f39789', 'f5000002-0000-0000-0000-000000000042',
   'Le SAMU',
   'false', '2'),

  ('c0251913-18dc-45dc-bbbb-58c33492f1b3', 'f5000002-0000-0000-0000-000000000042',
   'Un syndicat de médecins',
   'false', '3'),

  ('40d72996-6c70-48ed-81e4-bc81af4d4af2', 'f5000002-0000-0000-0000-000000000043',
   'Une suspension de travail prescrite par un médecin',
   'true', '0'),

  ('b068ee95-b8d7-4acf-b4f3-aa607efe742a', 'f5000002-0000-0000-0000-000000000043',
   'Un licenciement',
   'false', '1'),

  ('4f7b70a3-9f23-4074-a035-a9d3a20a1aee', 'f5000002-0000-0000-0000-000000000043',
   'Des vacances',
   'false', '2'),

  ('28ab45ad-a259-486a-bc95-cd9dd043fc6d', 'f5000002-0000-0000-0000-000000000043',
   'Un événement religieux',
   'false', '3'),

  ('c855f686-0f88-444a-9896-edb8c8db7316', 'f5000002-0000-0000-0000-000000000044',
   'Un congé légal autour de la naissance d''un enfant',
   'true', '0'),

  ('623d0927-2170-496e-b0f7-a69327587a59', 'f5000002-0000-0000-0000-000000000044',
   'Un congé religieux',
   'false', '1'),

  ('55cca0b5-b7a6-4ce0-92c3-9f8479d7b81d', 'f5000002-0000-0000-0000-000000000044',
   'Un congé sabbatique',
   'false', '2'),

  ('c68ab5a5-f8a6-46d8-9e50-64ec769860fe', 'f5000002-0000-0000-0000-000000000044',
   'Un congé férié',
   'false', '3'),

  ('9d87890f-269e-4ef9-8249-6d7d4f2d964c', 'f5000002-0000-0000-0000-000000000045',
   'Un congé légal de 25 jours pour le père/parent',
   'true', '0'),

  ('9a237b73-7b6e-482b-9d02-8fc6554c1128', 'f5000002-0000-0000-0000-000000000045',
   'Un congé interdit',
   'false', '1'),

  ('1708acbc-0dc2-4bcc-a32b-3a98a87d4a78', 'f5000002-0000-0000-0000-000000000045',
   'Un congé équivalent au maternité',
   'false', '2'),

  ('414d2cb2-d9a0-41bc-a3ce-9eb75d264c5e', 'f5000002-0000-0000-0000-000000000045',
   'Un congé religieux',
   'false', '3'),

  ('be121fa3-8c95-4629-8d63-9964e82c177b', 'f5000002-0000-0000-0000-000000000046',
   'L''organisme de protection sociale (maladie, retraite, famille, AT)',
   'true', '0'),

  ('2bc644c1-3331-4ff6-8bc5-7c34869cf732', 'f5000002-0000-0000-0000-000000000046',
   'Un service de police',
   'false', '1'),

  ('30367e4e-3097-4886-aa52-0bb1cf9e81dc', 'f5000002-0000-0000-0000-000000000046',
   'Une banque',
   'false', '2'),

  ('399fc8b0-0347-4df5-9269-012bc4ce2b18', 'f5000002-0000-0000-0000-000000000046',
   'Un parti politique',
   'false', '3'),

  ('3d7b329a-4beb-452c-9bef-103ab361d270', 'f5000002-0000-0000-0000-000000000047',
   'Une carte de séjour valable jusqu''à 4 ans',
   'true', '0'),

  ('4bdfe473-f904-44bf-a42e-e30df50fce25', 'f5000002-0000-0000-0000-000000000047',
   'Un passeport diplomatique',
   'false', '1'),

  ('8a77e1d8-2757-44c0-8357-921e9dfed1a0', 'f5000002-0000-0000-0000-000000000047',
   'Une carte de transport',
   'false', '2'),

  ('17b976ee-b129-4f99-ba27-7de70c1c39d0', 'f5000002-0000-0000-0000-000000000047',
   'Un permis de chasse',
   'false', '3'),

  ('1d49fdec-7450-44b5-ba84-f4abe9211673', 'f5000002-0000-0000-0000-000000000048',
   'Une carte de séjour de 10 ans renouvelable',
   'true', '0'),

  ('92141bcd-0958-4e7e-a4a1-a7347274f0df', 'f5000002-0000-0000-0000-000000000048',
   'Une carte courte',
   'false', '1'),

  ('f8700036-73d1-4ef7-897c-be504e0c269c', 'f5000002-0000-0000-0000-000000000048',
   'Un passeport',
   'false', '2'),

  ('5d0d0985-f62c-4773-bd62-f116b12fcbc6', 'f5000002-0000-0000-0000-000000000048',
   'Un permis de conduire',
   'false', '3'),

  ('7f03e703-4876-474e-9467-ecc0aa8ada99', 'f5000002-0000-0000-0000-000000000049',
   'L''Office français de l''immigration et de l''intégration',
   'true', '0'),

  ('6fba47d2-db76-40a5-b925-43a4446535b4', 'f5000002-0000-0000-0000-000000000049',
   'Un syndicat',
   'false', '1'),

  ('118f1f5b-f0f3-4c13-b5a2-b2da03c4c685', 'f5000002-0000-0000-0000-000000000049',
   'Une banque',
   'false', '2'),

  ('493371bf-21dc-405e-8bea-c67afab84253', 'f5000002-0000-0000-0000-000000000049',
   'Un musée',
   'false', '3'),

  ('b256421e-7ff1-4900-a2dc-37847a7eab56', 'f5000002-0000-0000-0000-00000000004a',
   'Un contrat d''intégration avec formations civiques et linguistiques',
   'true', '0'),

  ('2cd4e913-c098-4a0f-b7d2-37bb7e8dbdfb', 'f5000002-0000-0000-0000-00000000004a',
   'Un contrat de travail',
   'false', '1'),

  ('621d2f02-d491-4bf7-a335-7d04638c8b43', 'f5000002-0000-0000-0000-00000000004a',
   'Un contrat de location',
   'false', '2'),

  ('eac5be8c-7fb3-4ad3-97e2-b9cf64723d19', 'f5000002-0000-0000-0000-00000000004a',
   'Un contrat de mariage',
   'false', '3'),

  ('f1be6c60-0de5-4a17-aa8e-b26e222ff073', 'f5000002-0000-0000-0000-00000000004b',
   'Formation civique et linguistique selon le niveau',
   'true', '0'),

  ('9872e382-25f1-4ec7-93b4-abf9e0a9ab88', 'f5000002-0000-0000-0000-00000000004b',
   'Uniquement militaire',
   'false', '1'),

  ('3c72f0cb-232a-4089-b240-71a450b4a675', 'f5000002-0000-0000-0000-00000000004b',
   'Uniquement sportive',
   'false', '2'),

  ('7717ecdd-afd1-4bbb-8bcf-9f0b7aa6b8e8', 'f5000002-0000-0000-0000-00000000004b',
   'Aucune formation',
   'false', '3'),

  ('b09965e1-8200-4cf4-a1fe-eb88d20a56b8', 'f5000002-0000-0000-0000-00000000004c',
   'Le niveau A2 (depuis 2026)',
   'true', '0'),

  ('29c627a1-7799-420a-addb-4604e97dc573', 'f5000002-0000-0000-0000-00000000004c',
   'Le niveau C2',
   'false', '1'),

  ('03ff912c-f84f-4f19-b99c-003374163a9e', 'f5000002-0000-0000-0000-00000000004c',
   'Aucun niveau de français',
   'false', '2'),

  ('4769b768-c705-4247-80ca-ae35125f0ebe', 'f5000002-0000-0000-0000-00000000004c',
   'Le niveau B2',
   'false', '3'),

  ('43d1e319-c380-4aef-a084-88e329b9da1c', 'f5000002-0000-0000-0000-00000000004d',
   'Le niveau B1 (depuis 2026)',
   'true', '0'),

  ('f7af48ea-b961-4f04-9eea-c00895d27812', 'f5000002-0000-0000-0000-00000000004d',
   'Aucun niveau requis',
   'false', '1'),

  ('d6736551-5a89-4090-822d-0f19a7ce70d3', 'f5000002-0000-0000-0000-00000000004d',
   'Le niveau A2',
   'false', '2'),

  ('c830611d-9db5-4c15-be45-0becc37c262e', 'f5000002-0000-0000-0000-00000000004d',
   'Le niveau C2',
   'false', '3'),

  ('4d26dff2-b4d6-49de-a7c3-10c91dc448d0', 'f5000002-0000-0000-0000-00000000004e',
   'Le niveau B2 (depuis 2026)',
   'true', '0'),

  ('25042d32-91b4-4dad-9c66-1c6db06090cc', 'f5000002-0000-0000-0000-00000000004e',
   'Le niveau A1',
   'false', '1'),

  ('81c1c759-49a2-4f4b-a41c-2282066d052b', 'f5000002-0000-0000-0000-00000000004e',
   'Aucun niveau requis',
   'false', '2'),

  ('92293e80-9b65-4505-8a62-a8c880e61818', 'f5000002-0000-0000-0000-00000000004e',
   'Le niveau C2 obligatoire',
   'false', '3'),

  ('374cccfe-ecb4-4e16-80db-50b29585da90', 'f5000002-0000-0000-0000-00000000004f',
   'Le CAP puis le baccalauréat professionnel',
   'true', '0'),

  ('db8996ad-a1cb-4097-96ff-766e497b270c', 'f5000002-0000-0000-0000-00000000004f',
   'Uniquement le brevet',
   'false', '1'),

  ('4f5ec801-7bdf-4df2-b0a3-f139bb1dd8c2', 'f5000002-0000-0000-0000-00000000004f',
   'Uniquement le doctorat',
   'false', '2'),

  ('b6f7e5d9-c6bf-41b0-9184-712a83f567c9', 'f5000002-0000-0000-0000-00000000004f',
   'Aucun diplôme',
   'false', '3'),

  ('085c479f-cc78-4e75-a213-d52a1963d9fe', 'f5000002-0000-0000-0000-000000000050',
   'La plateforme d''inscription dans l''enseignement supérieur',
   'true', '0'),

  ('81dd3d84-6550-411a-8863-a84211d5064b', 'f5000002-0000-0000-0000-000000000050',
   'Un parti politique',
   'false', '1'),

  ('0685288b-58ae-4c4f-bfc0-9a5cfc032f9c', 'f5000002-0000-0000-0000-000000000050',
   'Une banque',
   'false', '2'),

  ('31a1dbb2-b860-458c-9620-bb24692e14dc', 'f5000002-0000-0000-0000-000000000050',
   'Une assurance',
   'false', '3'),

  ('e10ce88f-bc65-49b3-9666-d5ffbc2892d1', 'f5000002-0000-0000-0000-000000000051',
   'Classes préparatoires aux grandes écoles',
   'true', '0'),

  ('f0498a59-33d0-45b3-bd2b-fda13f72154e', 'f5000002-0000-0000-0000-000000000051',
   'Un type de retraite',
   'false', '1'),

  ('1a002ebc-3b48-499d-95f1-c8948cf220b6', 'f5000002-0000-0000-0000-000000000051',
   'Une compagnie aérienne',
   'false', '2'),

  ('885b196e-f1e4-4ce0-8b91-2cee1cd8c5c6', 'f5000002-0000-0000-0000-000000000051',
   'Un syndicat étudiant',
   'false', '3'),

  ('034ca110-0709-4e5e-be65-dc68a420e5a0', 'f5000002-0000-0000-0000-000000000052',
   'Combiner études et travail en entreprise, avec rémunération',
   'true', '0'),

  ('496df780-bd5f-4532-a153-32cdfe98751e', 'f5000002-0000-0000-0000-000000000052',
   'Étudier en ligne uniquement',
   'false', '1'),

  ('f3c4d57b-4302-42bc-867c-fa9dc74e1340', 'f5000002-0000-0000-0000-000000000052',
   'Étudier le soir uniquement',
   'false', '2'),

  ('40ec43d7-4672-4dc4-9914-9b9ec79e43f7', 'f5000002-0000-0000-0000-000000000052',
   'Étudier sans diplôme',
   'false', '3'),

  ('1a254e8f-4c00-4f2e-993e-cda440aac5ca', 'f5000002-0000-0000-0000-000000000053',
   'Chercher, postuler, démissionner avec préavis ou rupture conventionnelle',
   'true', '0'),

  ('55cec96c-3581-452d-9190-c7a0b786df98', 'f5000002-0000-0000-0000-000000000053',
   'Quitter sans prévenir',
   'false', '1'),

  ('76eb76f3-3f21-4fd0-91c3-07a3081fae05', 'f5000002-0000-0000-0000-000000000053',
   'Refuser tout changement',
   'false', '2'),

  ('94f97dd2-32e9-4b5d-94ce-db33af903d9c', 'f5000002-0000-0000-0000-000000000053',
   'Demander au pape',
   'false', '3'),

  ('4f5ce6b0-7b46-434f-a474-a4f215cc2926', 'f5000002-0000-0000-0000-000000000054',
   '2 à 4 mois avant l''expiration, en préfecture',
   'true', '0'),

  ('8f59b484-6e9a-4f18-9d71-38b9ca70998f', 'f5000002-0000-0000-0000-000000000054',
   'Après l''expiration',
   'false', '1'),

  ('79cc5aba-42c8-4596-9603-c4cd4b1fbbc9', 'f5000002-0000-0000-0000-000000000054',
   'Aucune démarche',
   'false', '2'),

  ('1b7be1bf-3c00-46b4-8d6f-aa112cae5ab2', 'f5000002-0000-0000-0000-000000000054',
   'Demander au commissariat',
   'false', '3'),

  ('3b1a3ced-787f-44c1-8bdd-ba6dadcf22d6', 'f5000002-0000-0000-0000-000000000055',
   'Certificat de radiation + inscription à la mairie de la nouvelle commune',
   'true', '0'),

  ('92f58ef5-5514-4ec4-98d7-c3c9354b0106', 'f5000002-0000-0000-0000-000000000055',
   'Pas besoin d''inscription',
   'false', '1'),

  ('3ef1a52b-dfd2-4508-8f80-d309d991381c', 'f5000002-0000-0000-0000-000000000055',
   'Inscrire au commissariat',
   'false', '2'),

  ('a572103e-a6bb-4b67-bc25-06165714d079', 'f5000002-0000-0000-0000-000000000055',
   'Attendre l''année prochaine',
   'false', '3'),

  ('3318f3f6-256a-4256-ab62-326a611ffd31', 'f5000002-0000-0000-0000-000000000056',
   'Formations OFII, associations FLE, médiathèques, Greta',
   'true', '0'),

  ('6ad2e62b-5247-48f7-8bf7-ae284ed008fa', 'f5000002-0000-0000-0000-000000000056',
   'Aucune solution',
   'false', '1'),

  ('60f268f5-2d0b-49b7-85d9-a7158398d715', 'f5000002-0000-0000-0000-000000000056',
   'Rester dans ma langue maternelle',
   'false', '2'),

  ('4291f475-2b6d-4f9a-b5ea-24665398ce8a', 'f5000002-0000-0000-0000-000000000056',
   'Quitter la France',
   'false', '3'),

  ('697f3bff-5224-4464-9e45-39445c476a81', 'f5000002-0000-0000-0000-000000000057',
   'Demande mairie + recours DALO si attente excessive',
   'true', '0'),

  ('b7405f44-f1ed-4893-9ae8-acb7472f6f91', 'f5000002-0000-0000-0000-000000000057',
   'Aucune voie possible',
   'false', '1'),

  ('c400e816-bd49-4241-8615-a008d16c560f', 'f5000002-0000-0000-0000-000000000057',
   'Occuper un logement vide',
   'false', '2'),

  ('6dc24d62-217a-4623-bded-808da3474a19', 'f5000002-0000-0000-0000-000000000057',
   'Dormir dans la rue',
   'false', '3'),

  ('4b1aca86-9273-4465-981f-c2b738d4cb67', 'f5000002-0000-0000-0000-000000000058',
   'Congé maternité 16 semaines, examens, protection licenciement',
   'true', '0'),

  ('7f3e08ce-28f6-497a-b526-3cf6ace8b379', 'f5000002-0000-0000-0000-000000000058',
   'Aucun droit',
   'false', '1'),

  ('0955a0bb-208e-4767-97cc-3be9bf46081e', 'f5000002-0000-0000-0000-000000000058',
   'Licenciement automatique',
   'false', '2'),

  ('84cb9b8f-2af6-422f-a611-2819965da6eb', 'f5000002-0000-0000-0000-000000000058',
   'Renoncer à la grossesse',
   'false', '3');
