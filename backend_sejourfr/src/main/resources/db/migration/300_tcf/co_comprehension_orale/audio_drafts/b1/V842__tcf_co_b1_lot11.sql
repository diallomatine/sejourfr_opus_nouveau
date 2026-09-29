-- ============================================================================
-- V842 — TCF CO B1 — lot 11 (thème : location de voiture)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, moyen de
-- paiement, choix retenu). Contenu 100 % original, déterministe, rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b00b-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Traoré, nous avons deux véhicules disponibles : la citadine à trente-cinq euros par jour, ou le break à cinquante euros.
[Femme] Nous partons à cinq, avec trois grosses valises. La citadine sera trop petite.
[Homme] Le break, alors. Je prépare le contrat.

Quel véhicule la cliente choisit-elle ?

A. La citadine à trente-cinq euros.
B. Le break, plus spacieux.
C. Aucun des deux véhicules.
D. Un monospace à réserver plus tard.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Traoré, nous avons deux véhicules disponibles : la citadine à trente-cinq euros par jour, ou le break à cinquante euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Nous partons à cinq, avec trois grosses valises. La citadine sera trop petite.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le break, alors. Je prépare le contrat.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel véhicule la cliente choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La citadine à trente-cinq euros.<break time="700ms"/>B.<break time="300ms"/>Le break, plus spacieux.<break time="700ms"/>C.<break time="300ms"/>Aucun des deux véhicules.<break time="700ms"/>D.<break time="300ms"/>Un monospace à réserver plus tard.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier le besoin exprimé (« nous partons à cinq, avec trois grosses valises ») et la conclusion de l''agent (« le break, alors, je prépare le contrat ») pour identifier B. A reprend la citadine, **mentionnée puis écartée** parce que trop petite — elle répondrait à « quel véhicule est le moins cher ? ». C contredit la préparation du contrat, signe qu''une location est bien conclue. D invente un véhicule jamais proposé dans le dialogue : distracteur thématique plausible mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Pour la caution de mille euros, il nous faut une carte de crédit, monsieur Osei.
[Homme] Je n''ai qu''une carte de débit. Je peux laisser des espèces ?
[Femme] Non. Mais avec l''assurance tous risques, à quinze euros par jour, aucune caution n''est demandée.
[Homme] D''accord, je prends cette assurance.

Comment le client résout-il le problème de la caution ?

A. Il laisse des espèces à l''agence.
B. Il utilise sa carte de débit.
C. Il revient plus tard avec une carte de crédit.
D. Il prend l''assurance tous risques.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pour la caution de mille euros, il nous faut une carte de crédit, monsieur Osei.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je n''ai qu''une carte de débit. Je peux laisser des espèces ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Non. Mais avec l''assurance tous risques, à quinze euros par jour, aucune caution n''est demandée.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, je prends cette assurance.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client résout-il le problème de la caution ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il laisse des espèces à l''agence.<break time="700ms"/>B.<break time="300ms"/>Il utilise sa carte de débit.<break time="700ms"/>C.<break time="300ms"/>Il revient plus tard avec une carte de crédit.<break time="700ms"/>D.<break time="300ms"/>Il prend l''assurance tous risques.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de solution finale** : la carte de crédit manque, les espèces sont refusées, et l''agente précise qu''avec l''assurance tous risques « aucune caution n''est demandée » ; le client conclut « je prends cette assurance » — D est correct. A est le moyen **proposé puis refusé** par l''agence — piège de la première mention. B est éliminé d''emblée : seule une carte de crédit convient pour la caution. C n''est jamais envisagé : le client choisit une solution immédiate au lieu de revenir. Mécanisme B1 : relier la contrainte, le refus et l''alternative acceptée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Tkatchenko, le réservoir n''est pas plein. Soit vous payez notre forfait carburant de quarante euros, soit vous faites le plein à la station, à cinq cents mètres.
[Femme] Quarante euros, c''est cher. Je vais à la station et je reviens.
[Homme] Très bien, je vous attends pour terminer la restitution.

Que décide la cliente ?

A. Aller faire le plein elle-même.
B. Payer le forfait carburant de quarante euros.
C. Rendre la voiture sans faire le plein.
D. Prolonger sa location d''une journée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Tkatchenko, le réservoir n''est pas plein. Soit vous payez notre forfait carburant de quarante euros, soit vous faites le plein à la station, à cinq cents mètres.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quarante euros, c''est cher. Je vais à la station et je reviens.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je vous attends pour terminer la restitution.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide la cliente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Aller faire le plein elle-même.<break time="700ms"/>B.<break time="300ms"/>Payer le forfait carburant de quarante euros.<break time="700ms"/>C.<break time="300ms"/>Rendre la voiture sans faire le plein.<break time="700ms"/>D.<break time="300ms"/>Prolonger sa location d''une journée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **la décision de la cliente**. Elle juge le forfait trop cher (« quarante euros, c''est cher ») et annonce « je vais à la station et je reviens » : A est correct — **inférence simple** comparaison de coût → choix. B est l''option **écartée** précisément à cause de son prix : c''est le piège de l''alternative entendue en premier. C contredit le dialogue : elle part justement faire le plein avant de rendre la voiture. D n''est jamais évoqué ; l''agent l''attend pour terminer la restitution le jour même.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Mon train arrive à Annecy à vingt-deux heures, et votre agence du centre-ville ferme à dix-neuf heures.
[Homme] Notre agence de la gare est ouverte jusqu''à minuit, madame Sharma. Je peux y transférer votre réservation.
[Femme] Parfait, je récupérerai la voiture à la gare.

Où la cliente va-t-elle récupérer le véhicule ?

A. À l''agence du centre-ville, avant dix-neuf heures.
B. À l''aéroport d''Annecy.
C. À l''agence de la gare.
D. À son hôtel, par livraison.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mon train arrive à Annecy à vingt-deux heures, et votre agence du centre-ville ferme à dix-neuf heures.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Notre agence de la gare est ouverte jusqu''à minuit, madame Sharma. Je peux y transférer votre réservation.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, je récupérerai la voiture à la gare.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Où la cliente va-t-elle récupérer le véhicule ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''agence du centre-ville, avant dix-neuf heures.<break time="700ms"/>B.<break time="300ms"/>À l''aéroport d''Annecy.<break time="700ms"/>C.<break time="300ms"/>À l''agence de la gare.<break time="700ms"/>D.<break time="300ms"/>À son hôtel, par livraison.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence horaire → lieu** : l''agence du centre-ville ferme à dix-neuf heures alors que le train arrive à vingt-deux heures ; l''agent transfère donc la réservation à l''agence de la gare, ouverte jusqu''à minuit, et la cliente confirme « je récupérerai la voiture à la gare ». C est correct. A est impossible : elle arrive trois heures après la fermeture du centre-ville. B confond gare et aéroport — aucun aéroport n''est mentionné dans le dialogue. D invente une livraison à l''hôtel jamais proposée. Mécanisme B1 : croiser deux horaires pour déduire le lieu retenu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je vais de Strasbourg à Biarritz, soit plus de deux mille kilomètres aller-retour.
[Femme] Le forfait de base inclut mille kilomètres, puis chaque kilomètre coûte trente centimes. Pour douze euros de plus par jour, vous avez le kilométrage illimité.
[Homme] Avec un si long trajet, je prends l''illimité.

Quelle formule le client choisit-il ?

A. Le forfait de base de mille kilomètres.
B. Le kilométrage illimité.
C. Un forfait de deux mille kilomètres.
D. Il renonce à louer pour ce trajet.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je vais de Strasbourg à Biarritz, soit plus de deux mille kilomètres aller-retour.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le forfait de base inclut mille kilomètres, puis chaque kilomètre coûte trente centimes. Pour douze euros de plus par jour, vous avez le kilométrage illimité.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec un si long trajet, je prends l''illimité.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle formule le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le forfait de base de mille kilomètres.<break time="700ms"/>B.<break time="300ms"/>Le kilométrage illimité.<break time="700ms"/>C.<break time="300ms"/>Un forfait de deux mille kilomètres.<break time="700ms"/>D.<break time="300ms"/>Il renonce à louer pour ce trajet.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence chiffrée** : le trajet dépasse deux mille kilomètres alors que le forfait de base n''en inclut que mille ; le client conclut « avec un si long trajet, je prends l''illimité » — B est correct. A est la formule **insuffisante**, écartée parce que chaque kilomètre au-delà coûterait trente centimes. C n''existe pas dans l''offre : aucun forfait de deux mille kilomètres n''est proposé, le distracteur recycle le chiffre du trajet. D contredit la décision d''achat clairement exprimée à la fin. Mécanisme B1 : comparer une distance et un plafond pour déduire l''option choisie.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je voudrais louer la berline automatique pour le week-end.
[Femme] Vous avez votre permis depuis moins de trois ans, monsieur Morales : cette catégorie ne vous est pas accessible. Mais je peux vous proposer la compacte.
[Homme] Tant pis pour la berline, je prendrai la compacte.

Pourquoi le client ne peut-il pas louer la berline ?

A. Parce qu''il a son permis depuis moins de trois ans.
B. Parce que la berline est déjà réservée.
C. Parce qu''il n''a pas le droit de conduire en France.
D. Parce que la berline coûte trop cher pour lui.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je voudrais louer la berline automatique pour le week-end.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous avez votre permis depuis moins de trois ans, monsieur Morales : cette catégorie ne vous est pas accessible. Mais je peux vous proposer la compacte.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tant pis pour la berline, je prendrai la compacte.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le client ne peut-il pas louer la berline ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''il a son permis depuis moins de trois ans.<break time="700ms"/>B.<break time="300ms"/>Parce que la berline est déjà réservée.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il n''a pas le droit de conduire en France.<break time="700ms"/>D.<break time="300ms"/>Parce que la berline coûte trop cher pour lui.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, énoncée explicitement par l''agente : « vous avez votre permis depuis moins de trois ans, cette catégorie ne vous est pas accessible » — A est correct. B est une cause **plausible mais jamais citée** : rien n''indique que la berline soit réservée. C déforme l''information : le client a bien le droit de conduire, c''est l''**ancienneté du permis** qui bloque l''accès à cette catégorie, pas le permis lui-même. D parle de prix, jamais évoqué dans l''échange. Piège B1 : retenir la cause réellement donnée, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] En vérifiant le véhicule, monsieur Sarr, je vois une rayure sur la portière arrière.
[Homme] Elle était déjà là au départ ! Regardez l''état des lieux : elle est notée sur le contrat.
[Femme] Vous avez raison, c''est bien indiqué. Vous n''aurez donc rien à payer.

Comment se termine la restitution du véhicule ?

A. Le client paie la réparation de la portière.
B. Le client perd une partie de sa caution.
C. Le client ne paie rien, la rayure était déjà notée.
D. Le client doit revenir avec un devis de garagiste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">En vérifiant le véhicule, monsieur Sarr, je vois une rayure sur la portière arrière.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Elle était déjà là au départ ! Regardez l''état des lieux : elle est notée sur le contrat.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous avez raison, c''est bien indiqué. Vous n''aurez donc rien à payer.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment se termine la restitution du véhicule ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le client paie la réparation de la portière.<break time="700ms"/>B.<break time="300ms"/>Le client perd une partie de sa caution.<break time="700ms"/>C.<break time="300ms"/>Le client ne paie rien, la rayure était déjà notée.<break time="700ms"/>D.<break time="300ms"/>Le client doit revenir avec un devis de garagiste.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier la protestation du client (« elle était déjà là au départ, elle est notée sur le contrat ») et la vérification de l''agente (« c''est bien indiqué, vous n''aurez donc rien à payer ») pour conclure que C est correct. A décrit le scénario **évité** grâce à l''état des lieux de départ. B est contredit : aucune retenue sur la caution n''est annoncée. D invente une démarche jamais demandée dans le dialogue. Point clé linguistique : le connecteur **« donc »** marque la conséquence — rayure déjà notée, donc aucun frais.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous devez rendre la voiture de location à quelle heure, demain ?

A. Devant l''agence de Toulouse.
B. Avec le réservoir plein, comme prévu.
C. Parce que je reprends la route vers Lille.
D. Avant onze heures du matin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous devez rendre la voiture de location à quelle heure, demain ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Devant l''agence de Toulouse.<break time="700ms"/>B.<break time="300ms"/>Avec le réservoir plein, comme prévu.<break time="700ms"/>C.<break time="300ms"/>Parce que je reprends la route vers Lille.<break time="700ms"/>D.<break time="300ms"/>Avant onze heures du matin.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « à quelle heure ? » porte sur **le moment précis** : seule D « avant onze heures du matin » situe la restitution dans le temps. A répondrait à « où devez-vous rendre la voiture ? » (**lieu**). B répondrait à « dans quel état faut-il la rendre ? » (**condition de restitution**). C, introduit par « parce que », répondrait à « pourquoi la rendez-vous demain ? » (**cause**). Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte de la location de voiture.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] La location du monospace vous revient à combien pour la semaine ?

A. À trois cent vingt euros, assurance comprise.
B. Dans une agence près du port de Brest.
C. Depuis lundi dernier, seulement.
D. Pour partir en vacances avec mes enfants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">La location du monospace vous revient à combien pour la semaine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À trois cent vingt euros, assurance comprise.<break time="700ms"/>B.<break time="300ms"/>Dans une agence près du port de Brest.<break time="700ms"/>C.<break time="300ms"/>Depuis lundi dernier, seulement.<break time="700ms"/>D.<break time="300ms"/>Pour partir en vacances avec mes enfants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Revient à combien ? » demande **un montant** : seule A donne une somme (« trois cent vingt euros, assurance comprise »). B indique **un lieu** et répondrait à « où avez-vous loué le monospace ? ». C, introduit par « depuis », marque **un point de départ dans le temps** et répondrait à « depuis quand l''avez-vous ? ». D, introduit par « pour », exprime **un but** et répondrait à « pourquoi avez-vous loué ce véhicule ? ». Piège B1 : toutes les réponses parlent de la même location, seule la nature de la question — un prix — permet de trancher.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00b-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où devez-vous restituer le véhicule à la fin de votre séjour ?

A. Dimanche soir, avant la fermeture.
B. En réglant le solde par carte bancaire.
C. Au parking de l''aéroport de Marseille.
D. Parce que mon contrat de location se termine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où devez-vous restituer le véhicule à la fin de votre séjour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dimanche soir, avant la fermeture.<break time="700ms"/>B.<break time="300ms"/>En réglant le solde par carte bancaire.<break time="700ms"/>C.<break time="300ms"/>Au parking de l''aéroport de Marseille.<break time="700ms"/>D.<break time="300ms"/>Parce que mon contrat de location se termine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Où ? » appelle **un lieu** : seule C « au parking de l''aéroport de Marseille » localise la restitution. A donne **un moment** et répondrait à « quand devez-vous rendre le véhicule ? ». B, au **gérondif de manière** (« en réglant »), répondrait à « comment se passe la restitution ? ». D, introduit par « parce que », donne **une cause** et répondrait à « pourquoi devez-vous le restituer ? ». Mécanisme B1 : la rection du mot interrogatif « où » impose une réponse spatiale, pas temporelle, modale ni causale.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b00b-1000-0000-000000000001 → 0a.
-- [x] Thème unique « location de voiture », 10 situations toutes différentes :
--     choix entre citadine et break, caution remplacée par l'assurance tous
--     risques, plein de carburant à la restitution, agence de retrait selon
--     les horaires, formule de kilométrage, refus jeune permis (catégorie de
--     véhicule), rayure déjà notée à l'état des lieux, heure de restitution,
--     prix de la location à la semaine, lieu de restitution.
-- [x] Aucun thème interdit (logement, SAV, médical, banque, mairie, agence de
--     voyage, restaurant, téléphonie, école, travail, déménagement, assurance
--     habitation, livraison, hôtel, pharmacie).
-- [x] Répartition : 7 × format C (co_document_question, dialogues 2-4 répliques,
--     ~40-55 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 3,6,9), B=2 (items 1,5),
--     C=3 (items 4,7,10), D=2 (items 2,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,3,5), solution de caution (2),
--     lieu déduit d'horaires (4), conséquence « donc » (7) ; explicite +
--     distracteurs proches (6,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, gérondif de manière, rection
--     interrogative, connecteur de conséquence).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms et villes variés
--     (Traoré, Osei, Tkatchenko, Sharma, Morales, Sarr — Annecy, Strasbourg,
--     Biarritz, Toulouse, Brest, Marseille, Lille).
-- ============================================================================
