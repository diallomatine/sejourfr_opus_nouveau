-- ============================================================================
-- V838 — TCF CO B1 — lot 07 (thème : restaurant / réservation)
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
  ('66666666-b007-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Restaurant Le Cèdre, bonjour.
[Femme] Bonjour, je voudrais réserver une table pour deux, vendredi à dix-neuf heures trente, au nom de Lucia Moreno.
[Homme] Vendredi à dix-neuf heures trente, c''est complet. Je peux vous proposer dix-huit heures ou vingt et une heures.
[Femme] Vingt et une heures, c''est trop tard pour nous. Va pour dix-huit heures, alors.

À quelle heure la cliente va-t-elle dîner au restaurant ?

A. À dix-neuf heures trente.
B. À dix-huit heures.
C. À vingt et une heures.
D. Elle ne réserve finalement pas.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Restaurant Le Cèdre, bonjour.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je voudrais réserver une table pour deux, vendredi à dix-neuf heures trente, au nom de Lucia Moreno.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vendredi à dix-neuf heures trente, c''est complet. Je peux vous proposer dix-huit heures ou vingt et une heures.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vingt et une heures, c''est trop tard pour nous. Va pour dix-huit heures, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">À quelle heure la cliente va-t-elle dîner au restaurant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À dix-neuf heures trente.<break time="700ms"/>B.<break time="300ms"/>À dix-huit heures.<break time="700ms"/>C.<break time="300ms"/>À vingt et une heures.<break time="700ms"/>D.<break time="300ms"/>Elle ne réserve finalement pas.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier le refus du créneau initial (« dix-neuf heures trente, c''est complet »), le rejet de vingt et une heures (« trop tard pour nous ») et la conclusion « va pour dix-huit heures » pour conclure que B est correct. A est l''horaire **demandé puis refusé** — piège de la première information entendue ; il répondrait à « quelle heure la cliente voulait-elle au départ ? ». C est l''option proposée mais écartée parce que trop tardive. D contredit la fin du dialogue : la cliente accepte un horaire, la réservation est bien confirmée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonsoir, monsieur Traoré. Vous préférez la terrasse ou la salle ?
[Homme] La terrasse a l''air agréable... mais je dîne avec un client pour discuter d''un contrat.
[Femme] Avec la musique du marché de nuit, la terrasse est bruyante ce soir.
[Homme] Vous avez raison, installez-nous plutôt à l''intérieur.

Pourquoi le client choisit-il une table à l''intérieur ?

A. Parce que la terrasse est complète.
B. Parce qu''il fait trop froid dehors.
C. Parce que la salle a une belle vue.
D. Parce qu''il a besoin de calme pour discuter.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonsoir, monsieur Traoré. Vous préférez la terrasse ou la salle ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La terrasse a l''air agréable... mais je dîne avec un client pour discuter d''un contrat.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Avec la musique du marché de nuit, la terrasse est bruyante ce soir.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez raison, installez-nous plutôt à l''intérieur.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le client choisit-il une table à l''intérieur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que la terrasse est complète.<break time="700ms"/>B.<break time="300ms"/>Parce qu''il fait trop froid dehors.<break time="700ms"/>C.<break time="300ms"/>Parce que la salle a une belle vue.<break time="700ms"/>D.<break time="300ms"/>Parce qu''il a besoin de calme pour discuter.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**. Il faut relier « je dîne avec un client pour discuter d''un contrat » et la remarque sur la terrasse **bruyante** pour déduire que le client s''installe à l''intérieur afin d''être au calme : D est correct — **inférence simple cause → choix**, la cause n''est jamais dite en un seul énoncé. A est faux : la terrasse est bruyante, pas complète — confusion entre deux inconvénients possibles. B invoque la météo, jamais évoquée dans le dialogue. C invente un agrément de la salle dont personne ne parle : distracteur thématique plausible mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] L''addition, s''il vous plaît. Vous acceptez les tickets-restaurant ?
[Femme] Seulement le midi, monsieur Haddad. Le soir, nous prenons la carte ou les espèces.
[Homme] Je n''ai presque rien en liquide... ce sera par carte, alors.

Comment le client va-t-il payer son repas ?

A. Par carte bancaire.
B. Avec des tickets-restaurant.
C. En espèces.
D. Par chèque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''addition, s''il vous plaît. Vous acceptez les tickets-restaurant ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Seulement le midi, monsieur Haddad. Le soir, nous prenons la carte ou les espèces.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je n''ai presque rien en liquide... ce sera par carte, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client va-t-il payer son repas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par carte bancaire.<break time="700ms"/>B.<break time="300ms"/>Avec des tickets-restaurant.<break time="700ms"/>C.<break time="300ms"/>En espèces.<break time="700ms"/>D.<break time="300ms"/>Par chèque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : les tickets-restaurant ne sont acceptés que le midi, le client n''a « presque rien en liquide », il conclut « ce sera par carte ». A est correct. B est le moyen **demandé puis refusé** pour le soir — piège de la première mention. C est éliminé par le manque de liquide déclaré par le client. D n''est jamais évoqué dans le dialogue : distracteur purement thématique. Mécanisme B1 : relier le refus et la contrainte pour déduire le choix final.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Le plat du jour, c''était le filet de cabillaud, mais il n''y en a plus. Il reste les moules marinières ou le risotto aux légumes.
[Homme] Ah, je suis allergique aux fruits de mer.
[Femme] Alors le risotto est fait pour vous, monsieur Alvarez.
[Homme] Parfait, je prends ça.

Quel plat le client commande-t-il ?

A. Le filet de cabillaud.
B. Les moules marinières.
C. Le risotto aux légumes.
D. Une salade composée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le plat du jour, c''était le filet de cabillaud, mais il n''y en a plus. Il reste les moules marinières ou le risotto aux légumes.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, je suis allergique aux fruits de mer.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors le risotto est fait pour vous, monsieur Alvarez.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Parfait, je prends ça.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel plat le client commande-t-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le filet de cabillaud.<break time="700ms"/>B.<break time="300ms"/>Les moules marinières.<break time="700ms"/>C.<break time="300ms"/>Le risotto aux légumes.<break time="700ms"/>D.<break time="300ms"/>Une salade composée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **le plat finalement commandé**. Il faut relier trois informations : le plat du jour est épuisé, le client est **allergique aux fruits de mer** (ce qui élimine les moules), et il accepte la suggestion (« le risotto est fait pour vous » / « parfait, je prends ça ») : C est correct — **inférence simple par élimination**. A est le plat du jour, mentionné en premier mais épuisé — piège de la première information. B est exclu par l''allergie déclarée. D n''apparaît jamais dans le dialogue : distracteur thématique de restaurant, vraisemblable mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je voudrais réserver pour l''anniversaire de ma mère : nous serons douze, samedi midi. Je m''appelle Fatou Ndiaye.
[Homme] Pour douze personnes, je peux vous installer à une grande table dans la salle commune, ou vous réserver le petit salon privé, avec un menu unique à vingt-huit euros.
[Femme] Ma mère aime la tranquillité... nous prendrons le salon privé.

Qu''est-ce que la cliente réserve finalement ?

A. Une grande table dans la salle commune.
B. Le salon privé avec un menu unique.
C. Le restaurant tout entier.
D. Une table en terrasse.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je voudrais réserver pour l''anniversaire de ma mère : nous serons douze, samedi midi. Je m''appelle Fatou Ndiaye.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour douze personnes, je peux vous installer à une grande table dans la salle commune, ou vous réserver le petit salon privé, avec un menu unique à vingt-huit euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ma mère aime la tranquillité... nous prendrons le salon privé.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que la cliente réserve finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une grande table dans la salle commune.<break time="700ms"/>B.<break time="300ms"/>Le salon privé avec un menu unique.<break time="700ms"/>C.<break time="300ms"/>Le restaurant tout entier.<break time="700ms"/>D.<break time="300ms"/>Une table en terrasse.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier le critère de la cliente (« ma mère aime la tranquillité ») et sa conclusion « nous prendrons le salon privé » pour identifier B comme l''option retenue. A est l''option **proposée puis écartée** au profit du salon — piège de la première proposition entendue. C exagère la réservation : la cliente prend un salon pour douze personnes, pas l''établissement entier — confusion entre privatiser une pièce et privatiser le restaurant. D n''est jamais évoqué dans le dialogue : distracteur thématique hors document. Mécanisme B1 : la justification donnée confirme le choix énoncé juste après.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, j''ai une réservation au nom de Wei Zhang pour samedi soir, mais j''ai un empêchement. Ce serait possible vendredi à la place ?
[Femme] Vendredi soir, nous sommes complets. En revanche, dimanche midi, il reste de la place.
[Homme] Dimanche midi, ça marche. Merci de déplacer la réservation.

Quand le client viendra-t-il finalement au restaurant ?

A. Samedi soir.
B. Vendredi soir.
C. Dimanche midi.
D. Il annule sa réservation.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, j''ai une réservation au nom de Wei Zhang pour samedi soir, mais j''ai un empêchement. Ce serait possible vendredi à la place ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vendredi soir, nous sommes complets. En revanche, dimanche midi, il reste de la place.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dimanche midi, ça marche. Merci de déplacer la réservation.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand le client viendra-t-il finalement au restaurant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Samedi soir.<break time="700ms"/>B.<break time="300ms"/>Vendredi soir.<break time="700ms"/>C.<break time="300ms"/>Dimanche midi.<break time="700ms"/>D.<break time="300ms"/>Il annule sa réservation.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « quand ? » porte sur **le moment finalement retenu**. **Inférence simple en trois étapes** : samedi est abandonné (empêchement), vendredi est refusé (« nous sommes complets »), et le client accepte la seule possibilité restante : « dimanche midi, ça marche ». C est correct. A est la réservation **initiale**, justement annulée par l''empêchement — piège de la première date entendue. B est le souhait du client, impossible faute de place. D contredit la fin du dialogue : la réservation est déplacée, pas annulée (« merci de déplacer la réservation »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Excusez-moi, il y a une erreur sur l''addition : vous avez compté trois desserts, nous n''en avons pris que deux.
[Homme] Vous avez raison, madame Kovtun, je suis désolé. Je corrige tout de suite, et je vous offre les cafés pour m''excuser.
[Femme] C''est gentil, merci beaucoup.

Que fait le serveur pour s''excuser de son erreur ?

A. Il offre les cafés.
B. Il offre un dessert.
C. Il fait une réduction sur tout le repas.
D. Il rembourse le repas complet.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Excusez-moi, il y a une erreur sur l''addition : vous avez compté trois desserts, nous n''en avons pris que deux.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez raison, madame Kovtun, je suis désolé. Je corrige tout de suite, et je vous offre les cafés pour m''excuser.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est gentil, merci beaucoup.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que fait le serveur pour s''excuser de son erreur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il offre les cafés.<break time="700ms"/>B.<break time="300ms"/>Il offre un dessert.<break time="700ms"/>C.<break time="300ms"/>Il fait une réduction sur tout le repas.<break time="700ms"/>D.<break time="300ms"/>Il rembourse le repas complet.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question demande **le geste fait pour s''excuser**. Le serveur annonce deux actions distinctes : corriger l''addition et « je vous offre les cafés pour m''excuser » — seule la seconde, introduite par **« pour » (but)**, répond à la question : A est correct. B confond avec l''objet de l''erreur : les **desserts** sont comptés en trop sur l''addition, ils ne sont pas offerts — piège de l''association lexicale. C et D amplifient le geste commercial : ni réduction globale ni remboursement ne sont proposés dans le dialogue. Mécanisme B1 : distinguer la correction de l''erreur du geste qui l''accompagne.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Vous serez combien de personnes pour la réservation de ce soir ?

A. Vers vingt heures, je pense.
B. Au fond de la salle, si possible.
C. Pour fêter une promotion.
D. Six adultes et deux enfants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous serez combien de personnes pour la réservation de ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers vingt heures, je pense.<break time="700ms"/>B.<break time="300ms"/>Au fond de la salle, si possible.<break time="700ms"/>C.<break time="300ms"/>Pour fêter une promotion.<break time="700ms"/>D.<break time="300ms"/>Six adultes et deux enfants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Vous serez combien de personnes ? » appelle **un nombre de convives** : seule D « six adultes et deux enfants » donne un effectif. A indique **un moment** et répondrait à « à quelle heure arriverez-vous ? ». B indique **un emplacement** dans la salle et répondrait à « où souhaitez-vous être installés ? ». C, introduit par « pour », exprime **un but** et répondrait à « quelle est l''occasion ? ». Mécanisme B1 : identifier la nature de l''information demandée par « combien » — les quatre réponses restent crédibles dans le contexte d''une réservation au restaurant.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Jusqu''à quelle heure servez-vous le soir ?

A. Depuis une quinzaine d''années.
B. Jusqu''à vingt-deux heures trente.
C. Tous les jours, sauf le lundi.
D. Juste derrière la mairie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Jusqu''à quelle heure servez-vous le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis une quinzaine d''années.<break time="700ms"/>B.<break time="300ms"/>Jusqu''à vingt-deux heures trente.<break time="700ms"/>C.<break time="300ms"/>Tous les jours, sauf le lundi.<break time="700ms"/>D.<break time="300ms"/>Juste derrière la mairie.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Jusqu''à quelle heure servez-vous ? » appelle **une limite horaire**, marquée par « jusqu''à » : seule B « jusqu''à vingt-deux heures trente » convient. A, introduit par « depuis », exprime **une durée écoulée** et répondrait à « depuis quand le restaurant existe-t-il ? » — piège des prépositions de temps. C exprime **une fréquence d''ouverture** et répondrait à « quels jours êtes-vous ouverts ? ». D donne **un lieu** et répondrait à « où se trouve le restaurant ? ». Mécanisme B1 : la **rection** de « jusqu''à quelle heure » impose une réponse en heure limite, pas en durée, fréquence ni lieu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b007-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Comment est-ce que je peux réserver une table pour samedi ?

A. Parce que c''est complet le week-end.
B. Vers midi et demi, de préférence.
C. Par téléphone ou sur notre site internet.
D. Une table pour quatre personnes.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Comment est-ce que je peux réserver une table pour samedi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que c''est complet le week-end.<break time="700ms"/>B.<break time="300ms"/>Vers midi et demi, de préférence.<break time="700ms"/>C.<break time="300ms"/>Par téléphone ou sur notre site internet.<break time="700ms"/>D.<break time="300ms"/>Une table pour quatre personnes.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment puis-je réserver ? » appelle **un moyen, une manière de procéder** : seule C « par téléphone ou sur notre site internet » indique comment effectuer la réservation. A, introduit par « parce que », donne **une cause** et répondrait à « pourquoi faut-il réserver ? » — confusion cause/moyen classique. B donne **un moment** et répondrait à « à quelle heure voulez-vous venir ? ». D précise **la taille de la table** et répondrait à « pour combien de personnes ? ». Mécanisme B1 : le mot interrogatif « comment » impose une réponse en moyen, pas en cause, moment ni quantité.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b007-1000-0000-000000000001 → 0a.
-- [x] Thème unique « restaurant / réservation », 10 situations toutes
--     différentes : choix d'un créneau de réservation, choix terrasse vs
--     salle, moyen de paiement de l'addition, plat de remplacement (allergie),
--     réservation de groupe en salon privé, déplacement d'une réservation,
--     erreur sur l'addition et geste commercial, nombre de convives, heure
--     limite de service, moyen de réserver une table.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4
--     répliques, ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne)
--     + 3 × format B (co_question_reponse, question Henri/Vivienne +
--     propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 3,7), B=3 (items 1,5,9),
--     C=3 (items 4,6,10), D=2 (items 2,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,5,6), moyen de paiement (3),
--     choix par élimination (4), cause du choix (2), geste vs correction (7) ;
--     explicite + distracteurs proches (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but vs moyen, prépositions de temps,
--     rection interrogative).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95
--     (narration) / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300
--     ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original. Thèmes interdits du bon
--     de commande non utilisés.
-- ============================================================================
