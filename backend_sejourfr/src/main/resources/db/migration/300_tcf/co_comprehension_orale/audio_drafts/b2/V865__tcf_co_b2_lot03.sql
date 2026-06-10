-- ============================================================================
-- V865 — TCF CO B2 — lot 03 (thème : communiqué / annonce officielle)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : communiqué officiel lu par un porte-parole
-- (monologue ~120-200 mots) + question implicite (intention du locuteur, idée
-- principale, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, institutions et locuteurs inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c003-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Mesdames et messieurs, bonjour. Nadia Belkacem, adjointe au maire de Vesoul, chargée des équipements sportifs. La municipalité souhaite porter à la connaissance des habitants les informations suivantes. À compter du lundi trois novembre, la piscine municipale des Capucins fermera ses portes pour une durée de cinq mois, le temps d''une rénovation complète du bassin et des vestiaires, devenue indispensable après quarante ans de service. Nous mesurons la gêne occasionnée, c''est pourquoi plusieurs mesures d''accompagnement ont été décidées. Les abonnements en cours seront automatiquement prolongés de la durée des travaux. Les scolaires et les clubs seront accueillis à la piscine intercommunale de Noidans, et une navette gratuite circulera le mercredi et le samedi pour tous les usagers. Enfin, les maîtres-nageurs proposeront, pendant l''hiver, des séances d''aquagym à la salle des fêtes, transformée pour l''occasion. La réouverture est prévue début avril, avec un bassin chauffé par des panneaux solaires. Nous vous remercions de votre compréhension.

Pourquoi la municipalité diffuse-t-elle ce communiqué ?

A. Pour annoncer la fermeture définitive d''un équipement vétuste.
B. Pour annoncer des travaux et organiser la continuité du service pendant la fermeture.
C. Pour présenter le nouveau système de chauffage solaire de la piscine.
D. Pour justifier une augmentation du prix des abonnements.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mesdames et messieurs, bonjour. Nadia Belkacem, adjointe au maire de Vesoul, chargée des équipements sportifs. La municipalité souhaite porter à la connaissance des habitants les informations suivantes. À compter du lundi trois novembre, la piscine municipale des Capucins fermera ses portes pour une durée de cinq mois, le temps d''une rénovation complète du bassin et des vestiaires, devenue indispensable après quarante ans de service. Nous mesurons la gêne occasionnée, c''est pourquoi plusieurs mesures d''accompagnement ont été décidées. Les abonnements en cours seront automatiquement prolongés de la durée des travaux. Les scolaires et les clubs seront accueillis à la piscine intercommunale de Noidans, et une navette gratuite circulera le mercredi et le samedi pour tous les usagers. Enfin, les maîtres-nageurs proposeront, pendant l''hiver, des séances d''aquagym à la salle des fêtes, transformée pour l''occasion. La réouverture est prévue début avril, avec un bassin chauffé par des panneaux solaires. Nous vous remercions de votre compréhension.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la municipalité diffuse-t-elle ce communiqué ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour annoncer la fermeture définitive d''un équipement vétuste.<break time="700ms"/>B.<break time="300ms"/>Pour annoncer des travaux et organiser la continuité du service pendant la fermeture.<break time="700ms"/>C.<break time="300ms"/>Pour présenter le nouveau système de chauffage solaire de la piscine.<break time="700ms"/>D.<break time="300ms"/>Pour justifier une augmentation du prix des abonnements.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **l''intention de communication** du locuteur officiel : le communiqué articule une annonce (fermeture de cinq mois pour rénovation) et des mesures de continuité (abonnements prolongés, accueil à Noidans, navette, aquagym) — B reformule ce double mouvement. A est un **contresens sur la durée** : la fermeture est temporaire, la réouverture est annoncée pour début avril. C élève un **détail final** (les panneaux solaires) au rang d''objet du communiqué — piège classique entre information principale et détail secondaire. D déforme un point précis du texte : les abonnements sont prolongés gratuitement, jamais augmentés.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] La préfecture de l''Ariège communique. Je suis Tomasz Kowal, directeur de cabinet du préfet. En raison du transfert de nos services dans un bâtiment rénové, les guichets d''accueil du public situés rue Delcassé seront fermés du douze au trente janvier. Nous tenons à le dire clairement : cette fermeture ne signifie en aucun cas une interruption des démarches. Tous les rendez-vous déjà fixés sont maintenus à la date et à l''heure prévues ; ils se tiendront simplement dans nos locaux provisoires, avenue de Ferrières, où une signalétique et des agents d''orientation accueilleront les usagers. Le dépôt des dossiers reste également possible par voie postale et sur la plateforme en ligne, dont les délais de traitement demeurent inchangés. Les personnes convoquées recevront un message de rappel précisant la nouvelle adresse quarante-huit heures avant leur rendez-vous. Nous invitons chacun à vérifier ses messages et à prévoir quelques minutes supplémentaires pour le trajet. La préfecture remercie les usagers de leur patience pendant cette période de transition.

Quel est le message essentiel de ce communiqué ?

A. Les démarches administratives sont suspendues pendant trois semaines.
B. Les usagers doivent reprendre rendez-vous sur la plateforme en ligne.
C. La préfecture inaugure un nouveau bâtiment rénové.
D. Les services au public continuent malgré le déménagement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La préfecture de l''Ariège communique. Je suis Tomasz Kowal, directeur de cabinet du préfet. En raison du transfert de nos services dans un bâtiment rénové, les guichets d''accueil du public situés rue Delcassé seront fermés du douze au trente janvier. Nous tenons à le dire clairement : cette fermeture ne signifie en aucun cas une interruption des démarches. Tous les rendez-vous déjà fixés sont maintenus à la date et à l''heure prévues ; ils se tiendront simplement dans nos locaux provisoires, avenue de Ferrières, où une signalétique et des agents d''orientation accueilleront les usagers. Le dépôt des dossiers reste également possible par voie postale et sur la plateforme en ligne, dont les délais de traitement demeurent inchangés. Les personnes convoquées recevront un message de rappel précisant la nouvelle adresse quarante-huit heures avant leur rendez-vous. Nous invitons chacun à vérifier ses messages et à prévoir quelques minutes supplémentaires pour le trajet. La préfecture remercie les usagers de leur patience pendant cette période de transition.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le message essentiel de ce communiqué ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les démarches administratives sont suspendues pendant trois semaines.<break time="700ms"/>B.<break time="300ms"/>Les usagers doivent reprendre rendez-vous sur la plateforme en ligne.<break time="700ms"/>C.<break time="300ms"/>La préfecture inaugure un nouveau bâtiment rénové.<break time="700ms"/>D.<break time="300ms"/>Les services au public continuent malgré le déménagement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le communiqué est construit sur une **concession corrective** : « cette fermeture ne signifie en aucun cas une interruption des démarches » — l''idée principale est la continuité du service malgré le déménagement, donc D. A prend l''annonce de surface (guichets fermés trois semaines) pour le propos, alors que tout le texte la corrige — piège **thème vs propos**. B contredit le texte : les rendez-vous « sont maintenus », personne ne doit en reprendre ; la plateforme ne sert qu''au dépôt des dossiers. C transforme la **cause du déménagement** (un bâtiment rénové) en objet du message : rien n''est inauguré, on annonce une organisation provisoire.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, Awa Ndiaye, porte-parole du réseau de transports urbains de Brive. À la suite d''un préavis de grève déposé pour la journée du jeudi quinze mai, nous publions dès aujourd''hui les prévisions de circulation afin que chacun puisse s''organiser. Le service sera assuré en moyenne à quarante pour cent. Concrètement, les lignes une, trois et sept, qui desservent les hôpitaux, les lycées et la gare, fonctionneront toute la journée avec un bus toutes les vingt minutes. Les autres lignes ne circuleront qu''aux heures de pointe, entre sept heures et neuf heures, puis entre seize heures trente et dix-huit heures trente. Le transport des élèves vers les établissements scolaires est garanti le matin et le soir. Les horaires détaillés, ligne par ligne, sont déjà consultables sur notre site et seront affichés à chaque arrêt dès demain. Les abonnés recevront en outre une alerte personnalisée la veille. Nous présentons nos excuses aux voyageurs pour cette journée particulière et les remercions de leur compréhension.

Dans quel but ce communiqué est-il diffusé à l''avance ?

A. Permettre aux voyageurs d''anticiper et d''adapter leurs déplacements.
B. Expliquer les revendications des conducteurs en grève.
C. Annoncer la suppression totale du service le quinze mai.
D. Présenter les nouveaux horaires définitifs du réseau.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, Awa Ndiaye, porte-parole du réseau de transports urbains de Brive. À la suite d''un préavis de grève déposé pour la journée du jeudi quinze mai, nous publions dès aujourd''hui les prévisions de circulation afin que chacun puisse s''organiser. Le service sera assuré en moyenne à quarante pour cent. Concrètement, les lignes une, trois et sept, qui desservent les hôpitaux, les lycées et la gare, fonctionneront toute la journée avec un bus toutes les vingt minutes. Les autres lignes ne circuleront qu''aux heures de pointe, entre sept heures et neuf heures, puis entre seize heures trente et dix-huit heures trente. Le transport des élèves vers les établissements scolaires est garanti le matin et le soir. Les horaires détaillés, ligne par ligne, sont déjà consultables sur notre site et seront affichés à chaque arrêt dès demain. Les abonnés recevront en outre une alerte personnalisée la veille. Nous présentons nos excuses aux voyageurs pour cette journée particulière et les remercions de leur compréhension.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Dans quel but ce communiqué est-il diffusé à l''avance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Permettre aux voyageurs d''anticiper et d''adapter leurs déplacements.<break time="700ms"/>B.<break time="300ms"/>Expliquer les revendications des conducteurs en grève.<break time="700ms"/>C.<break time="300ms"/>Annoncer la suppression totale du service le quinze mai.<break time="700ms"/>D.<break time="300ms"/>Présenter les nouveaux horaires définitifs du réseau.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le but est donné dès la première phrase : publier les prévisions « afin que chacun puisse s''organiser » — il faut **inférer l''intention pragmatique** de l''annonce anticipée, donc A. B confond le communiqué avec un autre genre de discours : la porte-parole ne dit rien des revendications, elle gère les conséquences pour les voyageurs. C est un **contresens chiffré** : le service est « assuré en moyenne à quarante pour cent », pas supprimé. D transforme des mesures exceptionnelles d''une seule journée en **changement durable** : aucun horaire définitif n''est annoncé, les affichages ne valent que pour le quinze mai — piège entre mesure ponctuelle et réorganisation pérenne.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Le centre hospitalier de Dole communique. Bogdan Iliescu, directeur de l''établissement. Face à la progression rapide de l''épidémie de grippe dans le département, et après avis de notre comité d''hygiène, de nouvelles consignes s''appliquent dès ce samedi dans l''ensemble de nos services. Les visites restent autorisées, j''insiste sur ce point, mais elles sont désormais limitées à une personne par patient et par jour, entre quatorze heures et dix-huit heures. Le port du masque, disponible gratuitement à l''entrée, redevient obligatoire dans les couloirs et les chambres. Les enfants de moins de douze ans, plus souvent porteurs du virus sans symptômes, sont invités à différer leur visite. Enfin, toute personne présentant de la fièvre ou une toux doit renoncer à se déplacer ; des tablettes sont prêtées dans chaque service pour organiser des appels en vidéo. Ces mesures, temporaires, seront levées dès que la circulation du virus le permettra. Elles ont un seul objectif : que l''hôpital reste un lieu sûr pour ceux qui y sont soignés.

Quelle est l''intention de la direction à travers ces mesures ?

A. Interdire provisoirement toute visite aux patients hospitalisés.
B. Dépister la grippe chez les visiteurs à l''entrée de l''hôpital.
C. Protéger les patients tout en maintenant le lien avec leurs proches.
D. Encourager les familles à remplacer définitivement les visites par la vidéo.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le centre hospitalier de Dole communique. Bogdan Iliescu, directeur de l''établissement. Face à la progression rapide de l''épidémie de grippe dans le département, et après avis de notre comité d''hygiène, de nouvelles consignes s''appliquent dès ce samedi dans l''ensemble de nos services. Les visites restent autorisées, j''insiste sur ce point, mais elles sont désormais limitées à une personne par patient et par jour, entre quatorze heures et dix-huit heures. Le port du masque, disponible gratuitement à l''entrée, redevient obligatoire dans les couloirs et les chambres. Les enfants de moins de douze ans, plus souvent porteurs du virus sans symptômes, sont invités à différer leur visite. Enfin, toute personne présentant de la fièvre ou une toux doit renoncer à se déplacer ; des tablettes sont prêtées dans chaque service pour organiser des appels en vidéo. Ces mesures, temporaires, seront levées dès que la circulation du virus le permettra. Elles ont un seul objectif : que l''hôpital reste un lieu sûr pour ceux qui y sont soignés.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention de la direction à travers ces mesures ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Interdire provisoirement toute visite aux patients hospitalisés.<break time="700ms"/>B.<break time="300ms"/>Dépister la grippe chez les visiteurs à l''entrée de l''hôpital.<break time="700ms"/>C.<break time="300ms"/>Protéger les patients tout en maintenant le lien avec leurs proches.<break time="700ms"/>D.<break time="300ms"/>Encourager les familles à remplacer définitivement les visites par la vidéo.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''intention se lit dans la clôture — « un seul objectif : que l''hôpital reste un lieu sûr pour ceux qui y sont soignés » — combinée à l''insistance « les visites restent autorisées » : C capture cet **équilibre entre protection et maintien du lien**, inférence d''intention typique du B2. A est un contresens direct de la **concession** « les visites restent autorisées, j''insiste sur ce point » : on limite, on n''interdit pas. B surinterprète deux détails (masques gratuits à l''entrée, consigne en cas de fièvre) : aucun dépistage n''est organisé, on demande aux malades de rester chez eux. D transforme une **solution de repli temporaire** (tablettes pour les visiteurs empêchés) en remplacement définitif, alors que les mesures « seront levées » dès que possible.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Communiqué de l''université de Pau. Je suis Anh Nguyen, directrice du service des examens. Un important dégât des eaux a rendu inutilisable le gymnase universitaire où devaient se tenir, la semaine prochaine, les épreuves écrites de fin de semestre. Je veux d''abord rassurer les huit cents étudiants concernés : aucune épreuve n''est annulée ni reportée. Le calendrier publié en novembre reste valable, dates et horaires compris. Seul le lieu change : les écrits se dérouleront au parc des expositions, hall B, situé à quinze minutes du campus. Pour faciliter ce déplacement, des navettes gratuites partiront du campus toutes les dix minutes, à partir d''une heure avant chaque épreuve. Les convocations mises à jour seront envoyées ce soir sur les adresses électroniques étudiantes ; il n''est pas nécessaire d''en demander une nouvelle. Les aménagements prévus pour les candidats en situation de handicap sont naturellement reconduits dans les nouvelles salles. En cas de question, le service des examens répond au numéro habituel, du lundi au vendredi.

Quelle est l''information principale de ce communiqué ?

A. Les épreuves sont reportées à une date ultérieure.
B. Les examens auront lieu comme prévu, mais dans un autre lieu.
C. Les étudiants doivent demander une nouvelle convocation.
D. L''université ferme son gymnase pour le rénover.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Communiqué de l''université de Pau. Je suis Anh Nguyen, directrice du service des examens. Un important dégât des eaux a rendu inutilisable le gymnase universitaire où devaient se tenir, la semaine prochaine, les épreuves écrites de fin de semestre. Je veux d''abord rassurer les huit cents étudiants concernés : aucune épreuve n''est annulée ni reportée. Le calendrier publié en novembre reste valable, dates et horaires compris. Seul le lieu change : les écrits se dérouleront au parc des expositions, hall B, situé à quinze minutes du campus. Pour faciliter ce déplacement, des navettes gratuites partiront du campus toutes les dix minutes, à partir d''une heure avant chaque épreuve. Les convocations mises à jour seront envoyées ce soir sur les adresses électroniques étudiantes ; il n''est pas nécessaire d''en demander une nouvelle. Les aménagements prévus pour les candidats en situation de handicap sont naturellement reconduits dans les nouvelles salles. En cas de question, le service des examens répond au numéro habituel, du lundi au vendredi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''information principale de ce communiqué ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les épreuves sont reportées à une date ultérieure.<break time="700ms"/>B.<break time="300ms"/>Les examens auront lieu comme prévu, mais dans un autre lieu.<break time="700ms"/>C.<break time="300ms"/>Les étudiants doivent demander une nouvelle convocation.<break time="700ms"/>D.<break time="300ms"/>L''université ferme son gymnase pour le rénover.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le communiqué hiérarchise l''information autour d''une opposition explicite : « aucune épreuve n''est annulée ni reportée […] seul le lieu change » — B restitue cette **idée principale**. A contredit frontalement cette phrase clé : confondre **changement de lieu et report** est précisément le piège visé. C inverse un détail : les convocations mises à jour sont envoyées automatiquement, « il n''est pas nécessaire d''en demander une nouvelle » — piège sur la **portée d''une négation**. D confond la **cause ponctuelle** (un dégât des eaux qui rend le gymnase inutilisable) avec une décision de rénovation jamais annoncée : mécanisme classique de confusion entre la cause de l''événement et l''objet du message.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] La régie municipale des eaux de Lons-le-Saunier communique. Yacine Bouzid, directeur technique. Dans la nuit du mardi neuf au mercredi dix septembre, entre vingt-deux heures et cinq heures du matin, la distribution d''eau potable sera interrompue dans les quartiers de la Marjorie, des Mouillères et du centre ancien. Cette coupure permettra de raccorder le nouveau réservoir des Chauvins, un chantier préparé depuis deux ans qui sécurisera l''alimentation de toute la ville pour les décennies à venir. Nous avons choisi un créneau nocturne précisément pour réduire la gêne, mais chacun comprendra qu''une nuit sans eau ne s''improvise pas : pensez aux usages essentiels avant vingt-deux heures. Au rétablissement, l''eau pourra présenter une coloration blanchâtre ou un léger goût pendant quelques heures ; il suffira de laisser couler le robinet deux ou trois minutes, ce phénomène est sans danger. Les établissements de santé et les personnes sous assistance médicale à domicile, déjà contactés individuellement, bénéficieront d''une alimentation provisoire. Nous remercions les habitants de leur compréhension.

Qu''est-ce que les habitants sont implicitement invités à faire ?

A. Faire bouillir l''eau pendant plusieurs jours après les travaux.
B. Quitter leur logement pendant la nuit de la coupure.
C. Signaler à la régie toute coloration de l''eau au rétablissement.
D. Prévoir avant la coupure l''eau nécessaire pour la nuit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La régie municipale des eaux de Lons-le-Saunier communique. Yacine Bouzid, directeur technique. Dans la nuit du mardi neuf au mercredi dix septembre, entre vingt-deux heures et cinq heures du matin, la distribution d''eau potable sera interrompue dans les quartiers de la Marjorie, des Mouillères et du centre ancien. Cette coupure permettra de raccorder le nouveau réservoir des Chauvins, un chantier préparé depuis deux ans qui sécurisera l''alimentation de toute la ville pour les décennies à venir. Nous avons choisi un créneau nocturne précisément pour réduire la gêne, mais chacun comprendra qu''une nuit sans eau ne s''improvise pas : pensez aux usages essentiels avant vingt-deux heures. Au rétablissement, l''eau pourra présenter une coloration blanchâtre ou un léger goût pendant quelques heures ; il suffira de laisser couler le robinet deux ou trois minutes, ce phénomène est sans danger. Les établissements de santé et les personnes sous assistance médicale à domicile, déjà contactés individuellement, bénéficieront d''une alimentation provisoire. Nous remercions les habitants de leur compréhension.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que les habitants sont implicitement invités à faire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Faire bouillir l''eau pendant plusieurs jours après les travaux.<break time="700ms"/>B.<break time="300ms"/>Quitter leur logement pendant la nuit de la coupure.<break time="700ms"/>C.<break time="300ms"/>Signaler à la régie toute coloration de l''eau au rétablissement.<break time="700ms"/>D.<break time="300ms"/>Prévoir avant la coupure l''eau nécessaire pour la nuit.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question vise une **conséquence non dite explicitement** : « une nuit sans eau ne s''improvise pas : pensez aux usages essentiels avant vingt-deux heures » invite, sans le formuler mot à mot, à constituer une réserve d''eau avant la coupure — D explicite cette **inférence pragmatique** (de la mise en garde à l''action attendue). A déforme la consigne réellement donnée : il suffit de « laisser couler le robinet deux ou trois minutes », jamais de faire bouillir l''eau, et quelques heures seulement, pas plusieurs jours. B est une réaction disproportionnée qu''aucun élément ne suggère : la coupure est nocturne et limitée à sept heures. C contredit le texte : la coloration est annoncée comme « sans danger » et passagère, il n''y a donc rien à signaler.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c003-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Communiqué officiel de l''Étoile Sportive de Lannion. Je suis Imane Berrada, secrétaire générale du club. À la suite des fortes pluies de ces derniers jours, la commission de sécurité, réunie ce matin avec l''arbitre délégué, a constaté que la pelouse du stade de Kervano était impraticable et dangereuse pour les joueurs. La rencontre de samedi contre Plouzané est donc reportée au mercredi vingt-sept mars, à vingt heures, sur le même terrain. Nous savons que ce report contrarie de nombreuses familles, et nous tenons à être clairs sur un point : tous les billets achetés restent valables pour la nouvelle date, sans aucune démarche à effectuer. Les spectateurs qui ne pourraient pas se libérer un soir de semaine obtiendront le remboursement intégral, sur simple demande à la billetterie, en ligne ou au guichet, jusqu''au quinze avril. Les abonnés, eux, n''ont rien à faire. Cette décision, jamais agréable, protège avant tout la santé des joueurs et la qualité du spectacle. Merci de votre fidélité.

Quel est le message principal que le club veut faire passer ?

A. Le match est reporté et les billets restent valables sans démarche.
B. Le match est annulé et tous les spectateurs seront remboursés.
C. Le stade de Kervano fermera jusqu''à la fin de la saison.
D. Les abonnés doivent confirmer leur présence pour la nouvelle date.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Communiqué officiel de l''Étoile Sportive de Lannion. Je suis Imane Berrada, secrétaire générale du club. À la suite des fortes pluies de ces derniers jours, la commission de sécurité, réunie ce matin avec l''arbitre délégué, a constaté que la pelouse du stade de Kervano était impraticable et dangereuse pour les joueurs. La rencontre de samedi contre Plouzané est donc reportée au mercredi vingt-sept mars, à vingt heures, sur le même terrain. Nous savons que ce report contrarie de nombreuses familles, et nous tenons à être clairs sur un point : tous les billets achetés restent valables pour la nouvelle date, sans aucune démarche à effectuer. Les spectateurs qui ne pourraient pas se libérer un soir de semaine obtiendront le remboursement intégral, sur simple demande à la billetterie, en ligne ou au guichet, jusqu''au quinze avril. Les abonnés, eux, n''ont rien à faire. Cette décision, jamais agréable, protège avant tout la santé des joueurs et la qualité du spectacle. Merci de votre fidélité.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le message principal que le club veut faire passer ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le match est reporté et les billets restent valables sans démarche.<break time="700ms"/>B.<break time="300ms"/>Le match est annulé et tous les spectateurs seront remboursés.<break time="700ms"/>C.<break time="300ms"/>Le stade de Kervano fermera jusqu''à la fin de la saison.<break time="700ms"/>D.<break time="300ms"/>Les abonnés doivent confirmer leur présence pour la nouvelle date.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le communiqué met lui-même son message en relief : « nous tenons à être clairs sur un point : tous les billets achetés restent valables […] sans aucune démarche » — A combine les deux informations essentielles (report au vingt-sept mars + validité des billets), c''est l''**idée principale**. B confond **report et annulation** : le match est reprogrammé, et le remboursement n''est qu''une option offerte aux spectateurs empêchés, pas une mesure générale — piège sur la portée d''une mesure conditionnelle. C extrapole un constat ponctuel : seule la pelouse est jugée impraticable pour cette rencontre, et le match reporté se jouera « sur le même terrain », preuve qu''aucune fermeture n''est décidée. D inverse un détail explicite : « les abonnés, eux, n''ont rien à faire » — piège B2 sur la **négation d''une démarche**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c003-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), thème unique « communiqué /
--     annonce officielle » : monologue officiel long, longueurs comptées =
--     153 / 161 / 161 / 163 / 161 / 161 / 161 mots (fourchette 120-200 B2).
-- [x] 7 situations officielles inventées, toutes différentes : mairie —
--     fermeture de piscine pour travaux (Vesoul), préfecture — déménagement
--     des guichets (Ariège), réseau de bus — plan de circulation un jour de
--     grève (Brive), hôpital — restrictions de visites en période d''épidémie
--     (Dole), université — changement de lieu d''examens (Pau), régie des
--     eaux — coupure nocturne programmée (Lons-le-Saunier), club sportif —
--     report de match (Lannion). Locuteurs variés : Nadia, Tomasz, Awa,
--     Bogdan, Anh, Yacine, Imane.
-- [x] Aucun thème interdit repris (pas de présentation d''organisme, pas de
--     bulletin d''information, pas de dispositif public expliqué, etc.) :
--     chaque document est un communiqué émis par l''institution elle-même.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes
--     réponses : B, D, A, C, B, D, A → A ×2, B ×2, C ×1, D ×2 — max 2 par
--     lettre, 4 lettres utilisées.
-- [x] Compréhension implicite B2 : intention de communication (items 1, 3,
--     4), idée principale / message essentiel (items 2, 5, 7), conséquence
--     non dite (item 6) ; distracteurs tous plausibles (thème vs propos,
--     détail secondaire vs idée principale, contresens temporaire/définitif,
--     report vs annulation, portée d''une négation).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé
--     (concession corrective, inférence pragmatique, portée de la négation…).
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par
--     item), pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise
--     (0.95) en narratrice + Henri/Vivienne (1.0) en alternance stricte,
--     voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
