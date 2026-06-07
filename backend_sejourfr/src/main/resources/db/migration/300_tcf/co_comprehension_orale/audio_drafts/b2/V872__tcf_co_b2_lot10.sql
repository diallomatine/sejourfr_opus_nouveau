-- ============================================================================
-- V872 — TCF CO B2 — lot 10 (thème : présentation d'une formation)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue expositif long (~120-200 mots)
-- + question implicite (objectif/public de la formation, intention du locuteur,
-- idée principale, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, formations et locuteurs inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00a-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je m''appelle Tomás Oliveira et je dirige le Fournil École, à Tours, qui prépare des adultes en reconversion au métier de boulanger en dix mois. Chez nous, oubliez les salles de classe : dès la première semaine, les stagiaires pétrissent, façonnent et enfournent dans un vrai fournil, ouvert à la clientèle du quartier chaque matin. Les clients achètent leurs baguettes, jugent les croissants, et ce regard extérieur vaut tous les examens blancs. Bien sûr, il y a des cours de technologie, d''hygiène et de gestion, mais ils occupent à peine un cinquième du temps et répondent toujours à un problème rencontré la veille devant le pétrin. Nos quatorze stagiaires de cette année ont entre vingt-huit et cinquante-trois ans ; beaucoup viennent du bureau, certains de l''usine. Ce que nous leur promettons, ce n''est pas un diplôme au rabais, c''est d''être opérationnels le premier jour de leur installation.

Quelle est la principale particularité de cette formation ?

A. Elle est réservée aux anciens employés de bureau.
B. Elle repose sur la pratique en conditions réelles de vente.
C. Elle privilégie les cours de technologie et de gestion.
D. Elle permet d''obtenir un diplôme en quelques semaines.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je m''appelle Tomás Oliveira et je dirige le Fournil École, à Tours, qui prépare des adultes en reconversion au métier de boulanger en dix mois. Chez nous, oubliez les salles de classe : dès la première semaine, les stagiaires pétrissent, façonnent et enfournent dans un vrai fournil, ouvert à la clientèle du quartier chaque matin. Les clients achètent leurs baguettes, jugent les croissants, et ce regard extérieur vaut tous les examens blancs. Bien sûr, il y a des cours de technologie, d''hygiène et de gestion, mais ils occupent à peine un cinquième du temps et répondent toujours à un problème rencontré la veille devant le pétrin. Nos quatorze stagiaires de cette année ont entre vingt-huit et cinquante-trois ans ; beaucoup viennent du bureau, certains de l''usine. Ce que nous leur promettons, ce n''est pas un diplôme au rabais, c''est d''être opérationnels le premier jour de leur installation.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la principale particularité de cette formation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle est réservée aux anciens employés de bureau.<break time="700ms"/>B.<break time="300ms"/>Elle repose sur la pratique en conditions réelles de vente.<break time="700ms"/>C.<break time="300ms"/>Elle privilégie les cours de technologie et de gestion.<break time="700ms"/>D.<break time="300ms"/>Elle permet d''obtenir un diplôme en quelques semaines.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tout le discours met en avant le fournil « ouvert à la clientèle du quartier », où les clients « achètent leurs baguettes, jugent les croissants » : la spécificité revendiquée est **l''apprentissage en conditions réelles de vente**, donc B — mécanisme B2 d''identification de l''idée principale. A transforme un **détail secondaire** en règle : « beaucoup viennent du bureau, certains de l''usine » décrit la diversité des profils, pas un critère d''admission. C inverse la hiérarchie annoncée : les cours théoriques occupent « à peine un cinquième du temps » et restent au service de la pratique. D contredit deux éléments : la formation dure dix mois, et Tomás refuse justement l''image du « diplôme au rabais » obtenu vite.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à tous, Aïcha Keïta, formatrice à l''institut Mains Ouvertes, à Rennes. Je viens vous présenter notre module de langue des signes destiné aux professionnels de l''accueil : agents de mairie, hôtesses de gare, personnels d''hôpital ou de banque. Soyons clairs dès le départ : en soixante heures, personne ne devient interprète ; il faut des années pour cela, et ce n''est pas notre ambition. Notre objectif est plus modeste et, je crois, plus urgent : qu''une personne sourde qui se présente à votre guichet puisse être saluée, comprise dans sa demande de base et orientée vers le bon service, sans devoir griffonner sur un papier ou venir accompagnée. Les séances alternent mises en situation filmées et vocabulaire ciblé sur votre métier ; chaque stagiaire repart avec les deux cents signes les plus utiles à son poste. Une rencontre mensuelle avec des usagers sourds complète le dispositif, parce que rien ne remplace l''échange réel.

Quel est l''objectif de cette formation ?

A. Former des interprètes professionnels en langue des signes.
B. Apprendre aux personnes sourdes à formuler leurs demandes au guichet.
C. Filmer les situations d''accueil pour évaluer la qualité des services.
D. Permettre aux agents d''accueil de communiquer simplement avec les usagers sourds.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à tous, Aïcha Keïta, formatrice à l''institut Mains Ouvertes, à Rennes. Je viens vous présenter notre module de langue des signes destiné aux professionnels de l''accueil : agents de mairie, hôtesses de gare, personnels d''hôpital ou de banque. Soyons clairs dès le départ : en soixante heures, personne ne devient interprète ; il faut des années pour cela, et ce n''est pas notre ambition. Notre objectif est plus modeste et, je crois, plus urgent : qu''une personne sourde qui se présente à votre guichet puisse être saluée, comprise dans sa demande de base et orientée vers le bon service, sans devoir griffonner sur un papier ou venir accompagnée. Les séances alternent mises en situation filmées et vocabulaire ciblé sur votre métier ; chaque stagiaire repart avec les deux cents signes les plus utiles à son poste. Une rencontre mensuelle avec des usagers sourds complète le dispositif, parce que rien ne remplace l''échange réel.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est l''objectif de cette formation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Former des interprètes professionnels en langue des signes.<break time="700ms"/>B.<break time="300ms"/>Apprendre aux personnes sourdes à formuler leurs demandes au guichet.<break time="700ms"/>C.<break time="300ms"/>Filmer les situations d''accueil pour évaluer la qualité des services.<break time="700ms"/>D.<break time="300ms"/>Permettre aux agents d''accueil de communiquer simplement avec les usagers sourds.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Aïcha définit elle-même la cible : que la personne sourde au guichet « puisse être saluée, comprise dans sa demande de base et orientée » — D reformule cet **objectif de communication élémentaire côté agents d''accueil**. Le mécanisme B2 est la distinction entre l''ambition niée et l''ambition réelle. A reprend exactement ce que la formatrice écarte d''entrée : « personne ne devient interprète… ce n''est pas notre ambition ». B inverse le **bénéficiaire de l''apprentissage** : ce sont les professionnels qui apprennent à signer, pas les usagers sourds qui sont formés. C élève un **moyen pédagogique** (les mises en situation filmées) au rang d''objectif, alors que rien n''évoque une évaluation des services.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je suis Karim Haddad, responsable du centre Cap Routier, à Saint-Étienne, et je vais être direct : si vous êtes ici ce soir, c''est peut-être que vous cherchez un métier stable sans savoir par où commencer. Notre formation de conducteur d''autocar dure trois mois et demi, elle est entièrement financée et même rémunérée, et elle ne demande aucun diplôme, simplement le permis voiture depuis deux ans. Je sais ce que certains pensent : pas d''études, donc pas d''avenir. C''est exactement l''idée que je veux combattre ce soir. Nos transporteurs partenaires cherchent quarante conducteurs d''ici septembre ; les douze derniers stagiaires ont tous signé un contrat avant même l''examen final. Conduire un autocar, c''est de la responsabilité, de la ponctualité, du contact avec les passagers, des compétences que beaucoup d''entre vous possèdent déjà sans le savoir. Alors avant de partir, prenez cinq minutes pour remplir le dossier de candidature : il n''engage à rien, et il peut tout changer.

Quelle est l''intention du locuteur ?

A. Convaincre les personnes présentes de poser leur candidature.
B. Présenter les difficultés quotidiennes du métier de conducteur.
C. Annoncer le recrutement de formateurs pour son centre.
D. Démontrer que les études longues garantissent un emploi stable.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis Karim Haddad, responsable du centre Cap Routier, à Saint-Étienne, et je vais être direct : si vous êtes ici ce soir, c''est peut-être que vous cherchez un métier stable sans savoir par où commencer. Notre formation de conducteur d''autocar dure trois mois et demi, elle est entièrement financée et même rémunérée, et elle ne demande aucun diplôme, simplement le permis voiture depuis deux ans. Je sais ce que certains pensent : pas d''études, donc pas d''avenir. C''est exactement l''idée que je veux combattre ce soir. Nos transporteurs partenaires cherchent quarante conducteurs d''ici septembre ; les douze derniers stagiaires ont tous signé un contrat avant même l''examen final. Conduire un autocar, c''est de la responsabilité, de la ponctualité, du contact avec les passagers, des compétences que beaucoup d''entre vous possèdent déjà sans le savoir. Alors avant de partir, prenez cinq minutes pour remplir le dossier de candidature : il n''engage à rien, et il peut tout changer.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention du locuteur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Convaincre les personnes présentes de poser leur candidature.<break time="700ms"/>B.<break time="300ms"/>Présenter les difficultés quotidiennes du métier de conducteur.<break time="700ms"/>C.<break time="300ms"/>Annoncer le recrutement de formateurs pour son centre.<break time="700ms"/>D.<break time="300ms"/>Démontrer que les études longues garantissent un emploi stable.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tous les arguments (formation financée et rémunérée, aucun diplôme exigé, quarante postes à pourvoir, contrats signés avant l''examen) convergent vers l''appel final : « remplir le dossier de candidature ». L''**inférence d''intention** — mécanisme B2 typique — donne A : Karim cherche à recruter des stagiaires. B confond la **valorisation** du métier (responsabilité, ponctualité, contact) avec un exposé de ses difficultés, jamais évoquées. C déplace l''objet du recrutement : ce sont les transporteurs qui cherchent des conducteurs, pas le centre qui cherche des formateurs. D est un **contresens** : « pas d''études, donc pas d''avenir » est précisément « l''idée que je veux combattre », pas la thèse défendue.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je m''appelle Linh Nguyen et je coordonne la formation Soigner en Français, créée à Lyon pour les infirmiers et aides-soignants diplômés à l''étranger. Beaucoup d''entre eux maîtrisent parfaitement les gestes techniques, mais se trouvent désarmés devant une famille inquiète ou des consignes de transmission orales rapides. Notre parcours en ligne ne ressemble donc à aucun cours de français classique : pas de listes de conjugaison, pas de textes littéraires. Chaque module part d''une situation d''hôpital enregistrée avec de vrais soignants : annoncer un soin à un patient âgé qui entend mal, reformuler la question d''un médecin pressé, rédiger une transmission en quelques lignes claires. Les participants s''entraînent par visioconférence en petits groupes, deux soirs par semaine, et reçoivent les commentaires d''un formateur double profil, enseignant de français et ancien cadre de santé. La grammaire n''est jamais absente, mais elle arrive toujours après le besoin, jamais avant.

Qu''est-ce qui distingue cette formation d''un cours de français classique ?

A. Elle s''adresse exclusivement aux médecins venus de l''étranger.
B. Elle supprime totalement l''enseignement de la grammaire.
C. Elle s''appuie sur des situations réelles de communication à l''hôpital.
D. Elle se déroule directement dans les services hospitaliers.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je m''appelle Linh Nguyen et je coordonne la formation Soigner en Français, créée à Lyon pour les infirmiers et aides-soignants diplômés à l''étranger. Beaucoup d''entre eux maîtrisent parfaitement les gestes techniques, mais se trouvent désarmés devant une famille inquiète ou des consignes de transmission orales rapides. Notre parcours en ligne ne ressemble donc à aucun cours de français classique : pas de listes de conjugaison, pas de textes littéraires. Chaque module part d''une situation d''hôpital enregistrée avec de vrais soignants : annoncer un soin à un patient âgé qui entend mal, reformuler la question d''un médecin pressé, rédiger une transmission en quelques lignes claires. Les participants s''entraînent par visioconférence en petits groupes, deux soirs par semaine, et reçoivent les commentaires d''un formateur double profil, enseignant de français et ancien cadre de santé. La grammaire n''est jamais absente, mais elle arrive toujours après le besoin, jamais avant.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce qui distingue cette formation d''un cours de français classique ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle s''adresse exclusivement aux médecins venus de l''étranger.<break time="700ms"/>B.<break time="300ms"/>Elle supprime totalement l''enseignement de la grammaire.<break time="700ms"/>C.<break time="300ms"/>Elle s''appuie sur des situations réelles de communication à l''hôpital.<break time="700ms"/>D.<break time="300ms"/>Elle se déroule directement dans les services hospitaliers.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La rupture annoncée (« ne ressemble à aucun cours de français classique ») est illustrée par le principe central : « chaque module part d''une situation d''hôpital enregistrée avec de vrais soignants » — C reformule cette **pédagogie ancrée dans la communication réelle**, l''idée principale du document. A déforme le **public** : la formation vise les infirmiers et aides-soignants ; le médecin n''apparaît que comme interlocuteur dans un exercice. B pousse à l''extrême l''absence de « listes de conjugaison » alors que Linh nuance : « la grammaire n''est jamais absente », elle vient simplement après le besoin — piège sur la **concession**. D confond le contenu (situations d''hôpital enregistrées) et le lieu : le parcours est en ligne, par visioconférence.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Bogdan Petrescu, maître couvreur, et je présente ce soir la formation Toits d''Hier, que nous lançons à Dijon en janvier. Pendant quatorze mois, huit compagnons apprendront la couverture traditionnelle : tuiles vernissées de Bourgogne, ardoise clouée, zinguerie d''ornement, toutes ces techniques qu''on ne trouve plus dans les manuels récents. Pourquoi cette formation ? Regardez autour de vous : les hôtels particuliers, les églises, les halles anciennes ont besoin d''entretien permanent, et les trois derniers artisans de la région capables de restaurer une toiture classée ont tous dépassé soixante ans. Aucun n''a trouvé d''apprenti à qui transmettre. De leur côté, les architectes des bâtiments de France repoussent des chantiers faute de bras qualifiés ; certains monuments attendent leur restauration depuis cinq ans. La formation alterne chantiers réels encadrés et ateliers de taille, et chaque stagiaire sera suivi par l''un de ces trois maîtres. Je vous laisse mesurer ce que cela signifie pour ceux qui s''engageront.

Que peut-on déduire de cette présentation ?

A. Les stagiaires devront patienter plusieurs années avant d''exercer leur métier.
B. Les futurs diplômés n''auront aucune difficulté à trouver du travail.
C. La formation a pour but premier de restaurer les monuments les plus urgents.
D. Les manuels récents décrivent précisément les techniques traditionnelles.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Bogdan Petrescu, maître couvreur, et je présente ce soir la formation Toits d''Hier, que nous lançons à Dijon en janvier. Pendant quatorze mois, huit compagnons apprendront la couverture traditionnelle : tuiles vernissées de Bourgogne, ardoise clouée, zinguerie d''ornement, toutes ces techniques qu''on ne trouve plus dans les manuels récents. Pourquoi cette formation ? Regardez autour de vous : les hôtels particuliers, les églises, les halles anciennes ont besoin d''entretien permanent, et les trois derniers artisans de la région capables de restaurer une toiture classée ont tous dépassé soixante ans. Aucun n''a trouvé d''apprenti à qui transmettre. De leur côté, les architectes des bâtiments de France repoussent des chantiers faute de bras qualifiés ; certains monuments attendent leur restauration depuis cinq ans. La formation alterne chantiers réels encadrés et ateliers de taille, et chaque stagiaire sera suivi par l''un de ces trois maîtres. Je vous laisse mesurer ce que cela signifie pour ceux qui s''engageront.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que peut-on déduire de cette présentation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les stagiaires devront patienter plusieurs années avant d''exercer leur métier.<break time="700ms"/>B.<break time="300ms"/>Les futurs diplômés n''auront aucune difficulté à trouver du travail.<break time="700ms"/>C.<break time="300ms"/>La formation a pour but premier de restaurer les monuments les plus urgents.<break time="700ms"/>D.<break time="300ms"/>Les manuels récents décrivent précisément les techniques traditionnelles.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conclusion « je vous laisse mesurer ce que cela signifie » invite à une **inférence de conséquence non dite** : trois artisans qualifiés tous sexagénaires, sans apprenti, des chantiers repoussés « faute de bras qualifiés », des monuments en attente — donc huit diplômés arriveront sur un marché en pénurie : B est la déduction attendue. A détourne un **détail chiffré** : les « cinq ans » d''attente concernent les monuments, pas l''entrée des stagiaires dans le métier (la formation dure quatorze mois). C confond le **moyen pédagogique** (les chantiers réels encadrés) et le but, qui est de transmettre un savoir-faire menacé. D contredit littéralement « ces techniques qu''on ne trouve plus dans les manuels récents ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je suis Wei Lin, directrice de l''Atelier des Mécanismes, à Annemasse, et je vous présente notre certificat d''horlogerie en cours du soir. L''idée est née d''un paradoxe : les manufactures de la région recrutent, des dizaines de salariés rêvent de changer de voie, mais presque aucun ne peut se permettre d''abandonner dix-huit mois de salaire pour retourner à l''école. Notre réponse tient en une organisation : les cours ont lieu le mardi et le jeudi de dix-huit à vingt et une heures, plus un samedi sur deux, pendant deux ans. Le programme reste exigeant : démontage et remontage de mouvements mécaniques, réglage, polissage, et un examen final identique à celui de la filière classique, devant le même jury. Soyons honnêtes : il faut de la discipline, et nous demandons un entretien préalable pour vérifier la motivation. Mais nos trente-deux premiers certifiés sont la preuve qu''on peut devenir horloger sans démissionner, et c''est exactement le public que nous visons.

À qui cette formation s''adresse-t-elle en priorité ?

A. Aux jeunes diplômés des écoles d''horlogerie classiques.
B. Aux manufactures qui souhaitent organiser leurs propres examens.
C. Aux personnes sans emploi disposant de leurs journées.
D. Aux salariés qui veulent se reconvertir sans quitter leur poste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je suis Wei Lin, directrice de l''Atelier des Mécanismes, à Annemasse, et je vous présente notre certificat d''horlogerie en cours du soir. L''idée est née d''un paradoxe : les manufactures de la région recrutent, des dizaines de salariés rêvent de changer de voie, mais presque aucun ne peut se permettre d''abandonner dix-huit mois de salaire pour retourner à l''école. Notre réponse tient en une organisation : les cours ont lieu le mardi et le jeudi de dix-huit à vingt et une heures, plus un samedi sur deux, pendant deux ans. Le programme reste exigeant : démontage et remontage de mouvements mécaniques, réglage, polissage, et un examen final identique à celui de la filière classique, devant le même jury. Soyons honnêtes : il faut de la discipline, et nous demandons un entretien préalable pour vérifier la motivation. Mais nos trente-deux premiers certifiés sont la preuve qu''on peut devenir horloger sans démissionner, et c''est exactement le public que nous visons.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">À qui cette formation s''adresse-t-elle en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Aux jeunes diplômés des écoles d''horlogerie classiques.<break time="700ms"/>B.<break time="300ms"/>Aux manufactures qui souhaitent organiser leurs propres examens.<break time="700ms"/>C.<break time="300ms"/>Aux personnes sans emploi disposant de leurs journées.<break time="700ms"/>D.<break time="300ms"/>Aux salariés qui veulent se reconvertir sans quitter leur poste.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le public visé doit être **inféré du dispositif** : des salariés qui « rêvent de changer de voie » sans pouvoir « abandonner dix-huit mois de salaire », des cours du soir et un samedi sur deux, et la conclusion explicite « devenir horloger sans démissionner… c''est exactement le public que nous visons » — donc D. A inverse la logique : la « filière classique » n''est citée que comme référence du même examen final, pas comme vivier de candidats. B déforme un détail : le « même jury » garantit la valeur du certificat, les manufacturiers ne sont que des recruteurs potentiels. C est le **contre-public** exact : tout le montage horaire existe précisément parce que les candidats travaillent en journée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00a-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Mesdames et messieurs, bonjour. Mateo Rossi, chef et formateur du programme Légume Capital, qui s''installe à Bordeaux ce printemps. Pendant cinq jours intensifs, j''apprends aux restaurateurs à construire une carte végétale qui rapporte. Je dis bien : qui rapporte. Car j''entends partout la même plainte : la clientèle réclame des plats sans viande, et les chefs improvisent un risotto triste, vendu à perte, par obligation. Notre formation prend le problème à l''envers. Le matin, technique pure : cuissons des légumineuses, fermentations, sauces profondes sans fond de viande. L''après-midi, chiffres : coût matière, fixation des prix, construction du menu. Un plat végétal bien conçu coûte deux fois moins cher en matière première qu''un plat carné et peut se vendre presque au même prix ; les restaurateurs qui l''ont compris dégagent enfin des marges. Je ne suis pas là pour convertir qui que ce soit au végétarisme : je suis là pour que votre carte végétale cesse d''être une corvée et devienne un atout commercial.

Quelle est l''idée principale défendue par le formateur ?

A. La cuisine végétale peut devenir une source de profit pour les restaurateurs.
B. Les chefs doivent se convertir au végétarisme pour rester crédibles.
C. Les plats végétaux doivent être vendus moins cher que les plats carnés.
D. Les restaurateurs improvisent trop souvent la composition de leurs menus.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mesdames et messieurs, bonjour. Mateo Rossi, chef et formateur du programme Légume Capital, qui s''installe à Bordeaux ce printemps. Pendant cinq jours intensifs, j''apprends aux restaurateurs à construire une carte végétale qui rapporte. Je dis bien : qui rapporte. Car j''entends partout la même plainte : la clientèle réclame des plats sans viande, et les chefs improvisent un risotto triste, vendu à perte, par obligation. Notre formation prend le problème à l''envers. Le matin, technique pure : cuissons des légumineuses, fermentations, sauces profondes sans fond de viande. L''après-midi, chiffres : coût matière, fixation des prix, construction du menu. Un plat végétal bien conçu coûte deux fois moins cher en matière première qu''un plat carné et peut se vendre presque au même prix ; les restaurateurs qui l''ont compris dégagent enfin des marges. Je ne suis pas là pour convertir qui que ce soit au végétarisme : je suis là pour que votre carte végétale cesse d''être une corvée et devienne un atout commercial.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale défendue par le formateur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La cuisine végétale peut devenir une source de profit pour les restaurateurs.<break time="700ms"/>B.<break time="300ms"/>Les chefs doivent se convertir au végétarisme pour rester crédibles.<break time="700ms"/>C.<break time="300ms"/>Les plats végétaux doivent être vendus moins cher que les plats carnés.<break time="700ms"/>D.<break time="300ms"/>Les restaurateurs improvisent trop souvent la composition de leurs menus.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le fil conducteur est martelé : « une carte végétale qui rapporte », les après-midis consacrés aux chiffres, les marges dégagées, et la chute « devienne un atout commercial » — A synthétise cette **thèse économique**, idée principale du discours. B reprend exactement ce que Mateo écarte : « je ne suis pas là pour convertir qui que ce soit au végétarisme » — piège sur l''**intention niée**. C déforme l''argument chiffré : le plat végétal coûte moins cher en matière première mais « peut se vendre presque au même prix » ; c''est l''écart coût/prix qui crée la marge, pas une baisse des tarifs. D élève un **constat introductif** (le « risotto triste » improvisé) au rang de thèse, alors qu''il ne sert qu''à poser le problème.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c00a-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), monologue expositif long :
--     longueurs comptées = 146 / 149 / 154 / 145 / 152 / 155 / 157 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « présentation d''une formation », 7 formations inventées,
--     toutes différentes : CAP boulanger adultes en fournil-école (Tours),
--     module LSF pour professionnels de l''accueil (Rennes), formation de
--     conducteur d''autocar financée (Saint-Étienne), français professionnel en
--     ligne pour soignants étrangers (Lyon), couverture traditionnelle du
--     patrimoine (Dijon), certificat d''horlogerie en cours du soir (Annemasse),
--     cuisine végétale rentable pour restaurateurs (Bordeaux). Prénoms variés :
--     Tomás, Aïcha, Karim, Linh, Bogdan, Wei, Mateo.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     pos1 (A) ×2, pos2 (B) ×2, pos3 (C) ×1, pos4 (D) ×2 — max 2 par position,
--     4 positions utilisées.
-- [x] Compréhension implicite B2 : particularité/objectif de la formation,
--     public visé, intention du locuteur, idée principale, conséquence non
--     dite ; distracteurs tous plausibles (thème vs propos, détail secondaire
--     vs idée principale, inversion cause/effet, intention niée, inversion du
--     bénéficiaire).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), voix Denise (0.95)
--     + Henri/Vivienne (1.0) en alternance, voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
