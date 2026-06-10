-- ============================================================================
-- V863 — TCF CO B2 — lot 01 (thème : présentation d'un organisme ou d'un service)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue expositif long (~120-200 mots)
-- + question implicite (rôle/fonction de l'organisme, intention, idée principale).
-- Table audio_question_draft. status='TEXT_VALIDATED', colonnes audio NULL
-- (remplies par le batch admin Azure). Contenu 100% original, organismes inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c001-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à toutes et à tous. Je m''appelle Fatou Diallo et je coordonne La Passerelle des Aînés, une association créée il y a huit ans à Besançon. Beaucoup de gens croient que nous sommes un service informatique pour personnes âgées, parce que nos bénévoles aident souvent à utiliser une tablette ou à remplir un dossier en ligne. En réalité, l''écran n''est qu''un prétexte. Ce qui nous préoccupe, c''est la solitude. Dans notre ville, des centaines de retraités passent des semaines entières sans véritable conversation. Nos cent vingt bénévoles rendent visite chaque semaine aux mêmes personnes, partagent un café, accompagnent une démarche administrative quand c''est nécessaire, mais surtout installent une relation qui dure. Nous organisons aussi des repas de quartier et des sorties au marché. Si une visite révèle une difficulté médicale ou financière, nous alertons les services compétents, car ce n''est pas notre métier. Notre métier, c''est de recréer du lien, patiemment, semaine après semaine.

Quelle est la mission essentielle de cette association ?

A. Former les retraités à l''usage des outils numériques.
B. Détecter les difficultés médicales des personnes isolées.
C. Rompre l''isolement des personnes âgées grâce à des visites régulières.
D. Se substituer aux services sociaux auprès des retraités.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à toutes et à tous. Je m''appelle Fatou Diallo et je coordonne La Passerelle des Aînés, une association créée il y a huit ans à Besançon. Beaucoup de gens croient que nous sommes un service informatique pour personnes âgées, parce que nos bénévoles aident souvent à utiliser une tablette ou à remplir un dossier en ligne. En réalité, l''écran n''est qu''un prétexte. Ce qui nous préoccupe, c''est la solitude. Dans notre ville, des centaines de retraités passent des semaines entières sans véritable conversation. Nos cent vingt bénévoles rendent visite chaque semaine aux mêmes personnes, partagent un café, accompagnent une démarche administrative quand c''est nécessaire, mais surtout installent une relation qui dure. Nous organisons aussi des repas de quartier et des sorties au marché. Si une visite révèle une difficulté médicale ou financière, nous alertons les services compétents, car ce n''est pas notre métier. Notre métier, c''est de recréer du lien, patiemment, semaine après semaine.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la mission essentielle de cette association ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Former les retraités à l''usage des outils numériques.<break time="700ms"/>B.<break time="300ms"/>Détecter les difficultés médicales des personnes isolées.<break time="700ms"/>C.<break time="300ms"/>Rompre l''isolement des personnes âgées grâce à des visites régulières.<break time="700ms"/>D.<break time="300ms"/>Se substituer aux services sociaux auprès des retraités.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La locutrice oppose explicitement l''apparence (l''aide numérique, « un prétexte ») et le fond : « notre métier, c''est de recréer du lien ». La question demande **l''idée principale, pas le thème apparent** — mécanisme B2 de distinction entre thème et propos. C est donc correcte. A reprend le **thème de surface** (tablettes, dossiers en ligne) que Fatou présente elle-même comme un prétexte : elle répondrait à « que font concrètement les bénévoles ? ». B transforme un **détail secondaire** (l''alerte aux services compétents) en mission, alors que Fatou précise que « ce n''est pas notre métier ». D est un **contresens** : l''association alerte les services sociaux, elle ne les remplace pas — D décrirait une structure qui assumerait elle-même le suivi social.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je suis Diego Fernandez, fondateur de Cap Transmission, un cabinet installé à Clermont-Ferrand depuis douze ans. Chaque année en France, des milliers d''ateliers d''artisans ferment, non pas faute de clients, mais faute de repreneur. Un boulanger qui part à la retraite emporte avec lui un savoir-faire, des emplois, et parfois le dernier commerce d''un village. Notre cabinet intervient précisément à ce moment charnière. Concrètement, nous évaluons la valeur réelle de l''entreprise, nous préparons le cédant à raconter son activité autrement qu''avec des chiffres, puis nous recherchons des candidats sérieux, souvent des salariés du secteur qui rêvent de s''installer. Nous accompagnons ensuite les deux parties pendant la première année de transition, car c''est là que la plupart des reprises échouent. Nous ne vendons pas de solutions financières et nous ne sommes pas une agence immobilière : notre seul objet, c''est que l''activité survive au départ de son créateur.

Quel est le rôle de ce cabinet ?

A. Accompagner la transmission des entreprises artisanales à un repreneur.
B. Aider les artisans à élargir leur clientèle.
C. Financer l''installation des jeunes repreneurs.
D. Vendre les locaux commerciaux des artisans partis à la retraite.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis Diego Fernandez, fondateur de Cap Transmission, un cabinet installé à Clermont-Ferrand depuis douze ans. Chaque année en France, des milliers d''ateliers d''artisans ferment, non pas faute de clients, mais faute de repreneur. Un boulanger qui part à la retraite emporte avec lui un savoir-faire, des emplois, et parfois le dernier commerce d''un village. Notre cabinet intervient précisément à ce moment charnière. Concrètement, nous évaluons la valeur réelle de l''entreprise, nous préparons le cédant à raconter son activité autrement qu''avec des chiffres, puis nous recherchons des candidats sérieux, souvent des salariés du secteur qui rêvent de s''installer. Nous accompagnons ensuite les deux parties pendant la première année de transition, car c''est là que la plupart des reprises échouent. Nous ne vendons pas de solutions financières et nous ne sommes pas une agence immobilière : notre seul objet, c''est que l''activité survive au départ de son créateur.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le rôle de ce cabinet ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Accompagner la transmission des entreprises artisanales à un repreneur.<break time="700ms"/>B.<break time="300ms"/>Aider les artisans à élargir leur clientèle.<break time="700ms"/>C.<break time="300ms"/>Financer l''installation des jeunes repreneurs.<break time="700ms"/>D.<break time="300ms"/>Vendre les locaux commerciaux des artisans partis à la retraite.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tout le monologue converge vers la formule finale : « notre seul objet, c''est que l''activité survive au départ de son créateur ». Il faut **inférer la fonction globale** à partir des étapes décrites (évaluation, préparation du cédant, recherche de candidats, accompagnement de la transition) et la synthétiser : c''est A. B contredit un point explicite : les ateliers ferment « non pas faute de clients, mais faute de repreneur » — piège sur la **cause réelle vs cause supposée** du problème. C est exclue par « nous ne vendons pas de solutions financières » ; elle répondrait à « qui peut financer une reprise ? ». D confond le cabinet avec « une agence immobilière », comparaison que Diego rejette expressément.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Olena Kovalenko et je dirige Toit Commun, une plateforme lancée à Nantes il y a cinq ans. Quand un radiateur reste en panne tout l''hiver ou qu''une caution n''est pas restituée, la relation entre un locataire et son propriétaire se transforme vite en bras de fer. Or, la plupart de ces conflits finissent au tribunal pour des sommes dérisoires, après des mois d''attente et beaucoup de rancune. Notre plateforme propose une autre voie. Chaque dossier est confié à un médiateur indépendant qui écoute séparément les deux parties, reformule les positions de chacun, puis les réunit autour d''une proposition d''accord. Nous ne prenons jamais parti : un propriétaire de bonne foi mérite la même écoute qu''un locataire en difficulté. Huit dossiers sur dix se concluent chez nous par un accord signé en moins de six semaines. Le tribunal reste possible, évidemment, mais il redevient ce qu''il aurait toujours dû être : le dernier recours.

Quelle est la fonction principale de cette plateforme ?

A. Défendre les locataires devant les tribunaux.
B. Diffuser des annonces de logements entre particuliers.
C. Vérifier l''état des logements avant la signature du bail.
D. Aider locataires et propriétaires à régler leurs litiges à l''amiable.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Olena Kovalenko et je dirige Toit Commun, une plateforme lancée à Nantes il y a cinq ans. Quand un radiateur reste en panne tout l''hiver ou qu''une caution n''est pas restituée, la relation entre un locataire et son propriétaire se transforme vite en bras de fer. Or, la plupart de ces conflits finissent au tribunal pour des sommes dérisoires, après des mois d''attente et beaucoup de rancune. Notre plateforme propose une autre voie. Chaque dossier est confié à un médiateur indépendant qui écoute séparément les deux parties, reformule les positions de chacun, puis les réunit autour d''une proposition d''accord. Nous ne prenons jamais parti : un propriétaire de bonne foi mérite la même écoute qu''un locataire en difficulté. Huit dossiers sur dix se concluent chez nous par un accord signé en moins de six semaines. Le tribunal reste possible, évidemment, mais il redevient ce qu''il aurait toujours dû être : le dernier recours.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la fonction principale de cette plateforme ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Défendre les locataires devant les tribunaux.<break time="700ms"/>B.<break time="300ms"/>Diffuser des annonces de logements entre particuliers.<break time="700ms"/>C.<break time="300ms"/>Vérifier l''état des logements avant la signature du bail.<break time="700ms"/>D.<break time="300ms"/>Aider locataires et propriétaires à régler leurs litiges à l''amiable.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut **synthétiser l''idée principale** : un médiateur indépendant, l''écoute des deux parties, « huit dossiers sur dix » conclus « par un accord signé » — la fonction est la résolution amiable des conflits locatifs, donc D. A est un double contresens : la plateforme « ne prend jamais parti » (neutralité revendiquée) et vise précisément à éviter le tribunal, présenté comme « le dernier recours ». B confond avec une **plateforme d''annonces immobilières** — confusion typique entre le thème (le logement) et le propos (la médiation). C invente un service de contrôle jamais mentionné ; elle répondrait à une question sur un diagnostiqueur ou un état des lieux, pas sur Toit Commun.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, Rachid Benani, directeur de La Fabrique Associative, à Roubaix. Notre centre est né d''un constat simple : les petites associations débordent d''énergie, mais s''épuisent dans la paperasse. Un club de quartier sait organiser un tournoi ; il sait rarement rédiger des statuts, monter un dossier de subvention ou tenir une comptabilité conforme. Résultat, des projets utiles meurent pour des raisons purement administratives. La Fabrique met donc à disposition des bénévoles tout ce qui leur manque : des modèles de documents juridiques, des permanences avec une comptable et un juriste, une salle équipée pour les réunions, et des ateliers pratiques le samedi matin. Attention, nous ne faisons jamais à la place des gens : notre équipe transmet des méthodes, puis se retire. Nous ne finançons aucun projet non plus, ce n''est pas notre vocation. L''année dernière, cent trente associations ont franchi notre porte, et la plupart fonctionnent aujourd''hui sans nous. C''est exactement le but.

Quel est le rôle de ce centre ?

A. Financer les projets des associations du quartier.
B. Donner aux bénévoles les outils pour gérer eux-mêmes leur association.
C. Organiser des tournois et des animations dans les quartiers.
D. Tenir la comptabilité des associations à leur place.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, Rachid Benani, directeur de La Fabrique Associative, à Roubaix. Notre centre est né d''un constat simple : les petites associations débordent d''énergie, mais s''épuisent dans la paperasse. Un club de quartier sait organiser un tournoi ; il sait rarement rédiger des statuts, monter un dossier de subvention ou tenir une comptabilité conforme. Résultat, des projets utiles meurent pour des raisons purement administratives. La Fabrique met donc à disposition des bénévoles tout ce qui leur manque : des modèles de documents juridiques, des permanences avec une comptable et un juriste, une salle équipée pour les réunions, et des ateliers pratiques le samedi matin. Attention, nous ne faisons jamais à la place des gens : notre équipe transmet des méthodes, puis se retire. Nous ne finançons aucun projet non plus, ce n''est pas notre vocation. L''année dernière, cent trente associations ont franchi notre porte, et la plupart fonctionnent aujourd''hui sans nous. C''est exactement le but.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le rôle de ce centre ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Financer les projets des associations du quartier.<break time="700ms"/>B.<break time="300ms"/>Donner aux bénévoles les outils pour gérer eux-mêmes leur association.<break time="700ms"/>C.<break time="300ms"/>Organiser des tournois et des animations dans les quartiers.<break time="700ms"/>D.<break time="300ms"/>Tenir la comptabilité des associations à leur place.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le mécanisme attendu est l''**inférence de la fonction à partir d''exemples concrets** : modèles de documents, permanences juridiques et comptables, ateliers — éclairés par la clé « notre équipe transmet des méthodes, puis se retire » et « la plupart fonctionnent aujourd''hui sans nous ». B synthétise cette logique d''autonomisation. A est explicitement niée (« nous ne finançons aucun projet »). C attribue au centre **ce que font les associations aidées** (le club « sait organiser un tournoi ») — piège d''inversion des acteurs. D contredit « nous ne faisons jamais à la place des gens » : la comptable conseille lors des permanences, elle n''exécute pas la comptabilité.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je suis Priya Ramdane, responsable du service Allô Ma Rue à la mairie de Montluçon. Avant sa création, un habitant qui repérait un lampadaire en panne, un dépôt sauvage ou un nid-de-poule ne savait jamais à qui s''adresser : voirie, propreté, espaces verts, chacun avait son numéro, ses horaires, son formulaire. Beaucoup renonçaient, et les problèmes s''installaient. Désormais, un seul geste suffit : un appel, ou une photo envoyée depuis notre application. Notre équipe de cinq agents reçoit le signalement, identifie le service technique concerné, lui transmet le dossier et surtout suit son traitement jusqu''au bout. L''habitant reçoit un message quand l''intervention est programmée, puis quand elle est terminée. Nous n''effectuons aucune réparation nous-mêmes ; notre valeur, c''est la coordination. Depuis deux ans, le délai moyen de traitement est passé de trois semaines à six jours, et les signalements ont doublé, ce qui est plutôt bon signe : les gens savent enfin que leur message aboutit.

Quelle est la fonction de ce service municipal ?

A. Centraliser les signalements des habitants et coordonner leur traitement.
B. Réparer les équipements défectueux de la voirie.
C. Développer des applications numériques pour la commune.
D. Renforcer les effectifs des services techniques municipaux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je suis Priya Ramdane, responsable du service Allô Ma Rue à la mairie de Montluçon. Avant sa création, un habitant qui repérait un lampadaire en panne, un dépôt sauvage ou un nid-de-poule ne savait jamais à qui s''adresser : voirie, propreté, espaces verts, chacun avait son numéro, ses horaires, son formulaire. Beaucoup renonçaient, et les problèmes s''installaient. Désormais, un seul geste suffit : un appel, ou une photo envoyée depuis notre application. Notre équipe de cinq agents reçoit le signalement, identifie le service technique concerné, lui transmet le dossier et surtout suit son traitement jusqu''au bout. L''habitant reçoit un message quand l''intervention est programmée, puis quand elle est terminée. Nous n''effectuons aucune réparation nous-mêmes ; notre valeur, c''est la coordination. Depuis deux ans, le délai moyen de traitement est passé de trois semaines à six jours, et les signalements ont doublé, ce qui est plutôt bon signe : les gens savent enfin que leur message aboutit.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la fonction de ce service municipal ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Centraliser les signalements des habitants et coordonner leur traitement.<break time="700ms"/>B.<break time="300ms"/>Réparer les équipements défectueux de la voirie.<break time="700ms"/>C.<break time="300ms"/>Développer des applications numériques pour la commune.<break time="700ms"/>D.<break time="300ms"/>Renforcer les effectifs des services techniques municipaux.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Priya décrit un **guichet unique** : recevoir le signalement, identifier le bon service, transmettre, suivre « jusqu''au bout », et conclut « notre valeur, c''est la coordination » — A reformule exactement cette fonction. B contredit « nous n''effectuons aucune réparation nous-mêmes » ; elle répondrait à « que font les services techniques ? » — piège B2 entre **coordonner et exécuter**. C élève un **moyen secondaire** (la photo envoyée via l''application) au rang de mission : le service n''est pas un studio de développement. D n''est jamais évoquée : les cinq agents composent l''équipe du service lui-même, il ne s''agit pas de recruter pour la voirie.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Amadou Sow et je préside Étincelle Campus, une association née à Aurillac il y a six ans. Tout est parti d''une observation : à résultats scolaires égaux, un lycéen de zone rurale demande beaucoup moins souvent une grande école ou une licence sélective qu''un lycéen de métropole. Ce n''est pas une question de talent, c''est une question d''horizon. Quand personne autour de vous n''a fait d''études longues, on ne s''autorise pas à viser haut. Notre réponse, c''est le parrainage. Chaque lycéen volontaire est suivi pendant deux ans par un étudiant ou un jeune professionnel originaire, comme lui, d''un territoire rural. Le binôme échange chaque semaine en visioconférence, visite des campus pendant les vacances, prépare ensemble les dossiers de candidature et, surtout, parle de tout ce qu''on n''ose pas demander aux professeurs : le logement, le budget, la solitude des débuts. Nous ne donnons pas de cours, les lycées s''en chargent très bien. Nous élargissons le champ des possibles.

Quel est l''objectif de cette association ?

A. Donner des cours de soutien scolaire aux lycéens ruraux.
B. Aider les jeunes à trouver un logement étudiant.
C. Encourager les lycéens ruraux à viser des études ambitieuses grâce au parrainage.
D. Organiser des visites de campus pour les lycées de la région.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Amadou Sow et je préside Étincelle Campus, une association née à Aurillac il y a six ans. Tout est parti d''une observation : à résultats scolaires égaux, un lycéen de zone rurale demande beaucoup moins souvent une grande école ou une licence sélective qu''un lycéen de métropole. Ce n''est pas une question de talent, c''est une question d''horizon. Quand personne autour de vous n''a fait d''études longues, on ne s''autorise pas à viser haut. Notre réponse, c''est le parrainage. Chaque lycéen volontaire est suivi pendant deux ans par un étudiant ou un jeune professionnel originaire, comme lui, d''un territoire rural. Le binôme échange chaque semaine en visioconférence, visite des campus pendant les vacances, prépare ensemble les dossiers de candidature et, surtout, parle de tout ce qu''on n''ose pas demander aux professeurs : le logement, le budget, la solitude des débuts. Nous ne donnons pas de cours, les lycées s''en chargent très bien. Nous élargissons le champ des possibles.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est l''objectif de cette association ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Donner des cours de soutien scolaire aux lycéens ruraux.<break time="700ms"/>B.<break time="300ms"/>Aider les jeunes à trouver un logement étudiant.<break time="700ms"/>C.<break time="300ms"/>Encourager les lycéens ruraux à viser des études ambitieuses grâce au parrainage.<break time="700ms"/>D.<break time="300ms"/>Organiser des visites de campus pour les lycées de la région.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Amadou pose un problème (« une question d''horizon », l''autocensure des lycéens ruraux), donne sa réponse (« notre réponse, c''est le parrainage ») et conclut « nous élargissons le champ des possibles » : il faut **inférer l''intention globale** — lever l''autocensure par le parrainage — donc C. A est explicitement niée (« nous ne donnons pas de cours, les lycées s''en chargent très bien »). B transforme un simple **sujet de conversation du binôme** (le logement, le budget) en mission de l''association. D élève un **moyen ponctuel** (visiter des campus pendant les vacances) au rang d''objectif — piège classique entre détail secondaire et idée principale.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c001-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je suis Lucia Moreno, fondatrice de Pause Aidants, une plateforme créée à Mulhouse il y a quatre ans. En France, des millions de personnes s''occupent chaque jour d''un parent malade, d''un conjoint dépendant ou d''un enfant handicapé. On les appelle les aidants, et la plupart s''oublient complètement : ils annulent leurs rendez-vous médicaux, abandonnent leurs loisirs, s''isolent, jusqu''à l''épuisement. Pause Aidants existe pour eux, et uniquement pour eux. Concrètement, la plateforme met en relation chaque aidant avec un relayeur formé, qui vient prendre le relais à domicile quelques heures par semaine. Pendant ce temps, l''aidant souffle : il va nager, voit des amis, dort, peu importe. Nous proposons aussi des groupes de parole le jeudi soir et une ligne d''écoute tenue par des psychologues. Je précise que nous ne soignons pas les personnes malades, d''autres structures le font très bien. Notre raison d''être, c''est que celui qui aide tienne debout, durablement.

À quoi sert cette plateforme ?

A. Soigner à domicile les personnes malades ou dépendantes.
B. Offrir du répit et du soutien aux proches aidants.
C. Former des psychologues spécialisés dans la dépendance.
D. Proposer des activités de loisirs aux personnes âgées.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je suis Lucia Moreno, fondatrice de Pause Aidants, une plateforme créée à Mulhouse il y a quatre ans. En France, des millions de personnes s''occupent chaque jour d''un parent malade, d''un conjoint dépendant ou d''un enfant handicapé. On les appelle les aidants, et la plupart s''oublient complètement : ils annulent leurs rendez-vous médicaux, abandonnent leurs loisirs, s''isolent, jusqu''à l''épuisement. Pause Aidants existe pour eux, et uniquement pour eux. Concrètement, la plateforme met en relation chaque aidant avec un relayeur formé, qui vient prendre le relais à domicile quelques heures par semaine. Pendant ce temps, l''aidant souffle : il va nager, voit des amis, dort, peu importe. Nous proposons aussi des groupes de parole le jeudi soir et une ligne d''écoute tenue par des psychologues. Je précise que nous ne soignons pas les personnes malades, d''autres structures le font très bien. Notre raison d''être, c''est que celui qui aide tienne debout, durablement.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">À quoi sert cette plateforme ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Soigner à domicile les personnes malades ou dépendantes.<break time="700ms"/>B.<break time="300ms"/>Offrir du répit et du soutien aux proches aidants.<break time="700ms"/>C.<break time="300ms"/>Former des psychologues spécialisés dans la dépendance.<break time="700ms"/>D.<break time="300ms"/>Proposer des activités de loisirs aux personnes âgées.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La cible est martelée : « Pause Aidants existe pour eux, et uniquement pour eux » — les aidants, pas les personnes aidées. Relayage à domicile, groupes de parole, ligne d''écoute : B synthétise ce **soutien et ce répit destinés aux proches aidants**. A inverse le bénéficiaire et contredit « nous ne soignons pas les personnes malades » — piège B2 majeur sur **l''identification du destinataire du service**. C déforme un détail : la ligne d''écoute est « tenue par des psychologues », la plateforme ne les forme pas — confusion entre l''acteur d''un service et le bénéficiaire d''une formation. D attribue à la plateforme les loisirs (nager, voir des amis) que **l''aidant** s''offre lui-même pendant le temps libéré par le relayeur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c001-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), monologue expositif long :
--     longueurs comptées = 155 / 146 / 153 / 150 / 152 / 158 / 150 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] 7 organismes inventés, tous différents : association seniors (Besançon),
--     cabinet transmission artisanale (Clermont-Ferrand), médiation locative
--     (Nantes), centre de ressources associatif (Roubaix), service municipal
--     de signalements (Montluçon), parrainage lycéens ruraux (Aurillac),
--     plateforme proches aidants (Mulhouse). Prénoms variés : Fatou, Diego,
--     Olena, Rachid, Priya, Amadou, Lucia.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     pos1 (A) ×2, pos2 (B) ×2, pos3 (C) ×2, pos4 (D) ×1 — max 2 par position,
--     4 positions utilisées.
-- [x] Compréhension implicite B2 : rôle/fonction de l''organisme, intention,
--     idée principale ; distracteurs tous plausibles (thème vs propos, détail
--     secondaire vs idée principale, inversion des acteurs/bénéficiaires).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), voix Denise (0.95)
--     + Henri/Vivienne (1.0) en alternance, voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
