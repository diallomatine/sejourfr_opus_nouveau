-- ============================================================================
-- V868 — TCF CO B2 — lot 06 (thème : dispositif public expliqué)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue expositif long (~120-200 mots)
-- + question implicite (principe du dispositif, intention, idée principale,
-- rôle des acteurs, conséquence non dite). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, dispositifs publics inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c006-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je suis Wei Chen, conseiller à la Maison de l''habitat de Châteauroux. Je vais vous expliquer le fonctionnement du Pass Réparation, lancé en janvier dans tout le département. Le dispositif part d''un constat : quand un lave-linge tombe en panne, huit foyers sur dix le remplacent, alors qu''une réparation coûterait souvent deux fois moins cher. Résultat, des tonnes d''appareils encore réparables partent à la benne chaque année. Concrètement, vous apportez votre appareil chez l''un des quarante réparateurs labellisés, et une remise de vingt-cinq à soixante euros est déduite directement de la facture, sans aucun formulaire à remplir. La somme est ensuite remboursée au professionnel par un fonds alimenté par les fabricants d''électroménager. Attention, le pass ne finance ni l''achat d''un appareil neuf, ni les pannes encore couvertes par la garantie. Au fond, l''objectif dépasse l''économie réalisée : il s''agit d''installer un réflexe durable, réparer d''abord, jeter le moins possible.

Quel est l''objectif principal de ce dispositif ?

A. Aider les ménages à acheter des appareils électroménagers neufs.
B. Soutenir financièrement les artisans réparateurs du département.
C. Contrôler la qualité des réparations effectuées par les professionnels.
D. Encourager la réparation des appareils pour limiter les déchets.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je suis Wei Chen, conseiller à la Maison de l''habitat de Châteauroux. Je vais vous expliquer le fonctionnement du Pass Réparation, lancé en janvier dans tout le département. Le dispositif part d''un constat : quand un lave-linge tombe en panne, huit foyers sur dix le remplacent, alors qu''une réparation coûterait souvent deux fois moins cher. Résultat, des tonnes d''appareils encore réparables partent à la benne chaque année. Concrètement, vous apportez votre appareil chez l''un des quarante réparateurs labellisés, et une remise de vingt-cinq à soixante euros est déduite directement de la facture, sans aucun formulaire à remplir. La somme est ensuite remboursée au professionnel par un fonds alimenté par les fabricants d''électroménager. Attention, le pass ne finance ni l''achat d''un appareil neuf, ni les pannes encore couvertes par la garantie. Au fond, l''objectif dépasse l''économie réalisée : il s''agit d''installer un réflexe durable, réparer d''abord, jeter le moins possible.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est l''objectif principal de ce dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Aider les ménages à acheter des appareils électroménagers neufs.<break time="700ms"/>B.<break time="300ms"/>Soutenir financièrement les artisans réparateurs du département.<break time="700ms"/>C.<break time="300ms"/>Contrôler la qualité des réparations effectuées par les professionnels.<break time="700ms"/>D.<break time="300ms"/>Encourager la réparation des appareils pour limiter les déchets.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Wei décrit la remise comme un mécanisme, puis livre la clé finale : « l''objectif dépasse l''économie réalisée… réparer d''abord, jeter le moins possible ». Il faut **inférer la finalité derrière le mécanisme financier** — distinction B2 entre le moyen (la remise) et le but (réduire les déchets) : D est correcte. A contredit un point explicite : « le pass ne finance ni l''achat d''un appareil neuf » — contresens sur l''objet financé. B transforme un **effet secondaire plausible** (les réparateurs sont remboursés par le fonds) en objectif du dispositif. C élève un détail d''organisation (le label des quarante réparateurs) au rang de mission : aucun contrôle de qualité des réparations n''est évoqué.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonsoir à tous. Je m''appelle Mariam Koné et je suis chargée de mission logement à la ville de Lorient. Ce soir, je vous présente Toit Partagé, le dispositif de cohabitation intergénérationnelle que la municipalité a ouvert en septembre. Le principe est simple : d''un côté, des habitants de plus de soixante ans qui disposent d''une chambre libre ; de l''autre, des étudiants ou des apprentis qui ne trouvent pas à se loger. La ville organise la rencontre, vérifie le logement, puis fait signer une convention à chacun. Le jeune verse une participation plafonnée à cent vingt euros par mois, très en dessous des loyers du secteur. En échange, il s''engage non pas à faire le ménage ou les soins, mais à assurer une présence : dîner ensemble certains soirs, prévenir en cas d''absence, partager un peu de quotidien. Nos médiateurs suivent chaque binôme toute l''année et peuvent mettre fin à la cohabitation si l''équilibre n''est plus respecté.

Quel est le principe de ce dispositif ?

A. Proposer aux étudiants des logements municipaux rénovés à loyer réduit.
B. Organiser une cohabitation entre seniors et jeunes, à loyer modéré contre une présence régulière.
C. Recruter des jeunes pour assurer le ménage et les soins chez les personnes âgées.
D. Financer la construction de résidences pour étudiants et apprentis.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonsoir à tous. Je m''appelle Mariam Koné et je suis chargée de mission logement à la ville de Lorient. Ce soir, je vous présente Toit Partagé, le dispositif de cohabitation intergénérationnelle que la municipalité a ouvert en septembre. Le principe est simple : d''un côté, des habitants de plus de soixante ans qui disposent d''une chambre libre ; de l''autre, des étudiants ou des apprentis qui ne trouvent pas à se loger. La ville organise la rencontre, vérifie le logement, puis fait signer une convention à chacun. Le jeune verse une participation plafonnée à cent vingt euros par mois, très en dessous des loyers du secteur. En échange, il s''engage non pas à faire le ménage ou les soins, mais à assurer une présence : dîner ensemble certains soirs, prévenir en cas d''absence, partager un peu de quotidien. Nos médiateurs suivent chaque binôme toute l''année et peuvent mettre fin à la cohabitation si l''équilibre n''est plus respecté.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le principe de ce dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Proposer aux étudiants des logements municipaux rénovés à loyer réduit.<break time="700ms"/>B.<break time="300ms"/>Organiser une cohabitation entre seniors et jeunes, à loyer modéré contre une présence régulière.<break time="700ms"/>C.<break time="300ms"/>Recruter des jeunes pour assurer le ménage et les soins chez les personnes âgées.<break time="700ms"/>D.<break time="300ms"/>Financer la construction de résidences pour étudiants et apprentis.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut **relier les deux volets du dispositif** — la participation plafonnée à cent vingt euros d''un côté, l''engagement de présence de l''autre — pour reconstruire le principe d''ensemble : une cohabitation seniors-jeunes encadrée, donc B. A est fausse sur deux points : les chambres se trouvent chez des particuliers (la ville « vérifie le logement », elle ne le possède ni ne le rénove). C contredit la **négation explicite** « non pas à faire le ménage ou les soins, mais à assurer une présence » — piège sur la nature de la contrepartie. D invente un volet immobilier absent du document : aucune construction n''est évoquée, seulement la mise en relation et la convention.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, Yusuf Demir, conseiller au point information jeunesse de Valence. Beaucoup d''entre vous m''interrogent sur la Bourse Permis, alors reprenons calmement. Ce dispositif s''adresse aux jeunes de dix-huit à vingt-cinq ans sans emploi stable. La ville prend en charge soixante-dix pour cent du coût du permis de conduire, versés directement à l''auto-école que vous choisissez parmi nos partenaires. Pourquoi cette aide ? Parce que dans notre agglomération, la majorité des offres d''intérim, de livraison ou d''aide à domicile exigent d''être motorisé, et que les zones d''activité restent mal desservies par les bus le soir et le week-end. Sans permis, beaucoup de candidatures s''arrêtent net. La contrepartie, maintenant : chaque bénéficiaire s''engage à effectuer quarante heures auprès d''une structure d''intérêt général, une maison de retraite, une recyclerie, un club sportif. Ce n''est pas une punition, c''est une manière de rendre à la collectivité ce qu''elle investit en vous. Les dossiers se déposent avant le quinze octobre.

Pourquoi la ville a-t-elle créé cette aide ?

A. Parce que l''absence de permis prive de nombreux jeunes d''un accès à l''emploi.
B. Parce que les auto-écoles partenaires manquaient d''élèves.
C. Parce que les associations locales manquaient de bénévoles.
D. Parce que la ville prévoit de réduire son réseau de bus.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, Yusuf Demir, conseiller au point information jeunesse de Valence. Beaucoup d''entre vous m''interrogent sur la Bourse Permis, alors reprenons calmement. Ce dispositif s''adresse aux jeunes de dix-huit à vingt-cinq ans sans emploi stable. La ville prend en charge soixante-dix pour cent du coût du permis de conduire, versés directement à l''auto-école que vous choisissez parmi nos partenaires. Pourquoi cette aide ? Parce que dans notre agglomération, la majorité des offres d''intérim, de livraison ou d''aide à domicile exigent d''être motorisé, et que les zones d''activité restent mal desservies par les bus le soir et le week-end. Sans permis, beaucoup de candidatures s''arrêtent net. La contrepartie, maintenant : chaque bénéficiaire s''engage à effectuer quarante heures auprès d''une structure d''intérêt général, une maison de retraite, une recyclerie, un club sportif. Ce n''est pas une punition, c''est une manière de rendre à la collectivité ce qu''elle investit en vous. Les dossiers se déposent avant le quinze octobre.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la ville a-t-elle créé cette aide ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que l''absence de permis prive de nombreux jeunes d''un accès à l''emploi.<break time="700ms"/>B.<break time="300ms"/>Parce que les auto-écoles partenaires manquaient d''élèves.<break time="700ms"/>C.<break time="300ms"/>Parce que les associations locales manquaient de bénévoles.<break time="700ms"/>D.<break time="300ms"/>Parce que la ville prévoit de réduire son réseau de bus.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Yusuf pose lui-même la question « Pourquoi cette aide ? » et y répond : offres d''emploi exigeant d''être motorisé, zones mal desservies, « sans permis, beaucoup de candidatures s''arrêtent net ». Le mécanisme B2 est l''**identification de la cause réelle du dispositif** parmi des éléments concurrents : A reformule cette justification. B inverse la logique : les auto-écoles partenaires sont le **canal de versement** de l''aide, pas sa raison d''être. C confond la **contrepartie** (les quarante heures d''engagement) avec la motivation du dispositif — le besoin des structures n''est jamais présenté comme le point de départ. D déforme un constat : les bus desservent mal certaines zones le soir, mais aucune réduction du réseau n''est annoncée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bienvenue à toutes et à tous. Je suis Linh Nguyen, je coordonne à Metz le dispositif Bouger sur Ordonnance, et je vais vous expliquer ce qui va se passer pour vous dans les prochains mois. Vous êtes ici parce que votre médecin traitant vous a prescrit, sur une ordonnance tout à fait classique, non pas un médicament, mais une activité physique adaptée. Diabète, hypertension, douleurs chroniques : pour ces maladies, les études sont formelles, le mouvement régulier agit aussi sûrement qu''un traitement, à condition d''être encadré. Concrètement, un éducateur spécialement formé vous reçoit, évalue vos capacités, puis construit un programme progressif : marche nordique, natation douce, gymnastique adaptée. La ville et l''assurance maladie financent l''essentiel des séances la première année, puis votre participation augmente doucement, le temps que l''habitude s''installe. Soyons clairs : il ne s''agit pas de faire de vous des sportifs, ni de remplacer vos médicaments du jour au lendemain. Il s''agit de soigner, autrement.

Quelle est l''intention de ce dispositif ?

A. Désengorger les cabinets des médecins traitants de la ville.
B. Promouvoir la pratique sportive auprès du grand public.
C. Faire de l''activité physique encadrée un véritable outil de soin.
D. Remplacer les traitements médicamenteux par le sport.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bienvenue à toutes et à tous. Je suis Linh Nguyen, je coordonne à Metz le dispositif Bouger sur Ordonnance, et je vais vous expliquer ce qui va se passer pour vous dans les prochains mois. Vous êtes ici parce que votre médecin traitant vous a prescrit, sur une ordonnance tout à fait classique, non pas un médicament, mais une activité physique adaptée. Diabète, hypertension, douleurs chroniques : pour ces maladies, les études sont formelles, le mouvement régulier agit aussi sûrement qu''un traitement, à condition d''être encadré. Concrètement, un éducateur spécialement formé vous reçoit, évalue vos capacités, puis construit un programme progressif : marche nordique, natation douce, gymnastique adaptée. La ville et l''assurance maladie financent l''essentiel des séances la première année, puis votre participation augmente doucement, le temps que l''habitude s''installe. Soyons clairs : il ne s''agit pas de faire de vous des sportifs, ni de remplacer vos médicaments du jour au lendemain. Il s''agit de soigner, autrement.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention de ce dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Désengorger les cabinets des médecins traitants de la ville.<break time="700ms"/>B.<break time="300ms"/>Promouvoir la pratique sportive auprès du grand public.<break time="700ms"/>C.<break time="300ms"/>Faire de l''activité physique encadrée un véritable outil de soin.<break time="700ms"/>D.<break time="300ms"/>Remplacer les traitements médicamenteux par le sport.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''intention est condensée dans la chute : « il s''agit de soigner, autrement », éclairée par « le mouvement régulier agit aussi sûrement qu''un traitement, à condition d''être encadré » — C reformule cette **inférence d''intention**. A est plausible dans l''absolu mais ne s''appuie sur aucun élément du document : rien n''évoque la charge des cabinets médicaux. B confond le **thème apparent** (le sport) et le propos (le soin) : le dispositif vise des patients atteints de maladies chroniques, sur prescription, pas le grand public. D est un **contresens explicitement écarté** : « il ne s''agit pas… de remplacer vos médicaments du jour au lendemain » — l''activité complète le traitement, elle ne s''y substitue pas.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, Bogdan Melnyk, je travaille à la régie des eaux d''Angoulême, où je suis chargé du programme Eau Essentielle. Laissez-moi vous expliquer comment fonctionne cette aide, car elle ne ressemble pas aux dispositifs que vous connaissez. D''habitude, pour obtenir un soutien, il faut le demander : retirer un dossier, fournir des justificatifs, attendre une commission. Et l''on sait ce qui se produit : près d''une personne éligible sur deux ne fait jamais la démarche, par ignorance, par découragement, parfois par honte. Nous avons donc inversé la logique. Chaque année, la régie croise ses fichiers d''abonnés avec ceux de la caisse d''allocations familiales, dans un cadre strictement contrôlé. Les foyers dont les ressources passent sous un certain seuil voient leur facture d''eau réduite de trente à cent vingt euros, sans avoir rien rempli, rien réclamé, parfois même sans le savoir à l''avance. L''aide ne couvre jamais la totalité de la facture, et elle disparaît dès que la situation s''améliore.

Qu''est-ce qui distingue cette aide des dispositifs habituels ?

A. Elle est réservée aux familles nombreuses.
B. Elle est attribuée automatiquement, sans démarche du bénéficiaire.
C. Elle couvre l''intégralité des factures d''eau des foyers modestes.
D. Elle est versée directement par la caisse d''allocations familiales.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, Bogdan Melnyk, je travaille à la régie des eaux d''Angoulême, où je suis chargé du programme Eau Essentielle. Laissez-moi vous expliquer comment fonctionne cette aide, car elle ne ressemble pas aux dispositifs que vous connaissez. D''habitude, pour obtenir un soutien, il faut le demander : retirer un dossier, fournir des justificatifs, attendre une commission. Et l''on sait ce qui se produit : près d''une personne éligible sur deux ne fait jamais la démarche, par ignorance, par découragement, parfois par honte. Nous avons donc inversé la logique. Chaque année, la régie croise ses fichiers d''abonnés avec ceux de la caisse d''allocations familiales, dans un cadre strictement contrôlé. Les foyers dont les ressources passent sous un certain seuil voient leur facture d''eau réduite de trente à cent vingt euros, sans avoir rien rempli, rien réclamé, parfois même sans le savoir à l''avance. L''aide ne couvre jamais la totalité de la facture, et elle disparaît dès que la situation s''améliore.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce qui distingue cette aide des dispositifs habituels ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle est réservée aux familles nombreuses.<break time="700ms"/>B.<break time="300ms"/>Elle est attribuée automatiquement, sans démarche du bénéficiaire.<break time="700ms"/>C.<break time="300ms"/>Elle couvre l''intégralité des factures d''eau des foyers modestes.<break time="700ms"/>D.<break time="300ms"/>Elle est versée directement par la caisse d''allocations familiales.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Bogdan construit une **opposition logique** : les aides habituelles supposent une demande (dossier, justificatifs), ce qui crée du non-recours ; « nous avons donc inversé la logique » → réduction appliquée « sans avoir rien rempli, rien réclamé ». B reformule cette automaticité, qui est précisément ce qui « ne ressemble pas aux dispositifs que vous connaissez ». A invente un critère : la condition est un **seuil de ressources**, pas la composition de la famille. C est explicitement niée : « l''aide ne couvre jamais la totalité de la facture ». D confond les **rôles des acteurs** : la caisse d''allocations familiales fournit les données croisées, mais c''est la régie des eaux qui réduit la facture.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à tous, Carmen Ribeiro, du centre communal d''action sociale de Chambéry. Avant l''été, je viens vous présenter le registre Veille Canicule, un dispositif gratuit, fondé sur le volontariat. De quoi s''agit-il ? Toute personne âgée, isolée ou en situation de handicap peut demander son inscription, pour elle-même ou pour un proche, avec son accord. Le registre dort la plupart du temps. Mais dès que la préfecture déclenche une alerte chaleur, il se réveille : nos agents appellent chaque inscrit, tous les deux jours, pour vérifier que tout va bien, rappeler les bons gestes et repérer les signes inquiétants. Si quelqu''un ne répond pas à deux appels consécutifs, un binôme se déplace au domicile. Je veux être claire : nous ne sommes pas des soignants, et l''inscription ne remplace ni le médecin ni la famille. Ce que le registre garantit, c''est qu''au cœur d''une vague de chaleur, personne d''inscrit ne traverse l''épreuve sans qu''on prenne de ses nouvelles.

À quoi sert ce registre ?

A. À organiser des soins infirmiers à domicile pendant l''été.
B. À recenser les logements les plus exposés à la chaleur.
C. À informer la préfecture du nombre de personnes fragiles.
D. À maintenir un contact régulier avec les personnes fragiles pendant les alertes chaleur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à tous, Carmen Ribeiro, du centre communal d''action sociale de Chambéry. Avant l''été, je viens vous présenter le registre Veille Canicule, un dispositif gratuit, fondé sur le volontariat. De quoi s''agit-il ? Toute personne âgée, isolée ou en situation de handicap peut demander son inscription, pour elle-même ou pour un proche, avec son accord. Le registre dort la plupart du temps. Mais dès que la préfecture déclenche une alerte chaleur, il se réveille : nos agents appellent chaque inscrit, tous les deux jours, pour vérifier que tout va bien, rappeler les bons gestes et repérer les signes inquiétants. Si quelqu''un ne répond pas à deux appels consécutifs, un binôme se déplace au domicile. Je veux être claire : nous ne sommes pas des soignants, et l''inscription ne remplace ni le médecin ni la famille. Ce que le registre garantit, c''est qu''au cœur d''une vague de chaleur, personne d''inscrit ne traverse l''épreuve sans qu''on prenne de ses nouvelles.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">À quoi sert ce registre ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À organiser des soins infirmiers à domicile pendant l''été.<break time="700ms"/>B.<break time="300ms"/>À recenser les logements les plus exposés à la chaleur.<break time="700ms"/>C.<break time="300ms"/>À informer la préfecture du nombre de personnes fragiles.<break time="700ms"/>D.<break time="300ms"/>À maintenir un contact régulier avec les personnes fragiles pendant les alertes chaleur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut **synthétiser la fonction** à partir du fonctionnement décrit (appels tous les deux jours, visite si deux appels restent sans réponse) et de la formule finale : « personne d''inscrit ne traverse l''épreuve sans qu''on prenne de ses nouvelles » — D reformule cette veille relationnelle. A contredit la mise au point explicite « nous ne sommes pas des soignants » — piège entre **veiller et soigner**. B confond le **thème** (la chaleur) et le **propos** (la veille sur les personnes) : on inscrit des personnes, pas des logements. C inverse le **circuit de l''information** : c''est la préfecture qui déclenche l''alerte et active le registre, jamais le registre qui la renseigne.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c006-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir, Sékou Traoré, de la direction de la citoyenneté de Perpignan. Ce soir, je vous explique le budget participatif, car j''entends encore beaucoup de confusions à son sujet. Le principe : chaque année, la ville réserve cinq pour cent de son budget d''investissement, soit deux millions d''euros, à des projets imaginés par vous, les habitants. Concrètement, de janvier à mars, toute personne résidant à Perpignan, dès seize ans, peut déposer une idée : végétaliser une cour d''école, créer une piste cyclable, installer des bancs ombragés. Nos services vérifient seulement deux choses : que le projet est techniquement réalisable, et qu''il relève bien des compétences municipales. Puis vient l''étape décisive : au mois de juin, tous les habitants votent, et le classement s''impose à la mairie. Je dis bien s''impose : ce n''est pas une consultation pour la forme, les projets arrivés en tête seront construits, par nos équipes, dans les deux ans. Votre rôle s''arrête au choix ; la réalisation, c''est notre affaire.

Quel rôle les habitants jouent-ils dans ce dispositif ?

A. Ils choisissent les projets, que la mairie réalise ensuite.
B. Ils financent eux-mêmes les aménagements de leur quartier.
C. Ils construisent les projets aux côtés des équipes municipales.
D. Ils donnent un avis consultatif que la mairie reste libre de suivre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir, Sékou Traoré, de la direction de la citoyenneté de Perpignan. Ce soir, je vous explique le budget participatif, car j''entends encore beaucoup de confusions à son sujet. Le principe : chaque année, la ville réserve cinq pour cent de son budget d''investissement, soit deux millions d''euros, à des projets imaginés par vous, les habitants. Concrètement, de janvier à mars, toute personne résidant à Perpignan, dès seize ans, peut déposer une idée : végétaliser une cour d''école, créer une piste cyclable, installer des bancs ombragés. Nos services vérifient seulement deux choses : que le projet est techniquement réalisable, et qu''il relève bien des compétences municipales. Puis vient l''étape décisive : au mois de juin, tous les habitants votent, et le classement s''impose à la mairie. Je dis bien s''impose : ce n''est pas une consultation pour la forme, les projets arrivés en tête seront construits, par nos équipes, dans les deux ans. Votre rôle s''arrête au choix ; la réalisation, c''est notre affaire.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel rôle les habitants jouent-ils dans ce dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils choisissent les projets, que la mairie réalise ensuite.<break time="700ms"/>B.<break time="300ms"/>Ils financent eux-mêmes les aménagements de leur quartier.<break time="700ms"/>C.<break time="300ms"/>Ils construisent les projets aux côtés des équipes municipales.<break time="700ms"/>D.<break time="300ms"/>Ils donnent un avis consultatif que la mairie reste libre de suivre.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le document répartit explicitement les rôles et la dernière phrase tranche : « votre rôle s''arrête au choix ; la réalisation, c''est notre affaire » — A restitue cette **répartition des rôles** (les habitants proposent et votent, la mairie construit). B est un **contresens lexical** sur « budget participatif » : l''argent provient du budget d''investissement de la ville, les habitants ne paient rien. C contredit la conclusion : les projets « seront construits, par nos équipes », pas par les habitants. D minore la portée du vote, expressément écartée par l''insistance de Sékou : « le classement s''impose à la mairie… ce n''est pas une consultation pour la forme ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c006-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), monologue expositif long :
--     longueurs comptées = 148 / 154 / 153 / 154 / 156 / 155 / 157 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « dispositif public expliqué », 7 dispositifs inventés et
--     tous différents : pass réparation électroménager (Châteauroux),
--     cohabitation intergénérationnelle (Lorient), bourse au permis contre
--     engagement citoyen (Valence), activité physique sur ordonnance (Metz),
--     aide automatique sur la facture d''eau (Angoulême), registre canicule
--     (Chambéry), budget participatif (Perpignan). Aucun thème interdit
--     (pas de présentation d''organisme, communiqué, témoignage, chronique…).
--     Prénoms variés : Wei, Mariam, Yusuf, Linh, Bogdan, Carmen, Sékou.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     A ×2 (items 3, 7), B ×2 (items 2, 5), C ×1 (item 4), D ×2 (items 1, 6)
--     — max 2 par lettre, 4 lettres utilisées.
-- [x] Compréhension implicite B2 : finalité derrière le mécanisme, principe
--     d''ensemble, cause réelle, intention, originalité du dispositif, fonction,
--     répartition des rôles ; distracteurs tous plausibles (thème vs propos,
--     détail secondaire vs idée principale, inversion cause/effet et des rôles,
--     contresens explicitement nié dans le document).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise (0.95) pour
--     intro/question/propositions, Henri/Vivienne (1.0) en alternance pour le
--     document, voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
