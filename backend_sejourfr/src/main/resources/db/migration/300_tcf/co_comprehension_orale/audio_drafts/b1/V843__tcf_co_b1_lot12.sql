-- ============================================================================
-- V843 — TCF CO B1 — lot 12 (thème : déménagement)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, modalité de
-- paiement, choix retenu). Contenu 100 % original, déterministe, rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b00c-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour madame Romero, avez-vous réfléchi à notre devis de sept cent cinquante euros pour votre déménagement vers Toulouse ?
[Femme] Oui. Votre concurrent demande six cents euros, mais sans assurance pour les objets fragiles. Comme je déménage le piano de ma grand-mère, je signe avec vous.
[Homme] Très bien, je vous envoie le contrat aujourd''hui.

Pourquoi la cliente choisit-elle ce déménageur ?

A. Parce que son devis est le moins cher.
B. Parce qu''il peut venir plus tôt que le concurrent.
C. Parce que son assurance couvre les objets fragiles.
D. Parce que le concurrent n''a pas envoyé de devis.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour madame Romero, avez-vous réfléchi à notre devis de sept cent cinquante euros pour votre déménagement vers Toulouse ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui. Votre concurrent demande six cents euros, mais sans assurance pour les objets fragiles. Comme je déménage le piano de ma grand-mère, je signe avec vous.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je vous envoie le contrat aujourd''hui.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente choisit-elle ce déménageur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que son devis est le moins cher.<break time="700ms"/>B.<break time="300ms"/>Parce qu''il peut venir plus tôt que le concurrent.<break time="700ms"/>C.<break time="300ms"/>Parce que son assurance couvre les objets fragiles.<break time="700ms"/>D.<break time="300ms"/>Parce que le concurrent n''a pas envoyé de devis.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple prix contre garantie** : la cliente rappelle que le concurrent est moins cher « mais sans assurance pour les objets fragiles », puis conclut « comme je déménage le piano de ma grand-mère, je signe avec vous » — C est correct. A décrit le devis **du concurrent**, moins cher mais écarté : piège du premier chiffre entendu, il répondrait à « quel devis est le moins cher ? ». B n''est jamais évoqué : aucune date d''intervention n''est comparée dans le dialogue. D est contredit : le concurrent a bien remis un devis de six cents euros, il est simplement écarté pour son absence d''assurance.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Castillo, pour le règlement de votre déménagement, vous pouvez payer en trois fois sans frais, ou en une seule fois avec une remise de cinq pour cent.
[Homme] Cinq pour cent sur neuf cents euros, ça fait quarante-cinq euros d''économie. Je paie tout maintenant.
[Femme] Parfait, je note un paiement comptant.

Comment le client décide-t-il de payer ?

A. En une seule fois, pour profiter de la remise.
B. En trois fois sans frais.
C. Le jour du déménagement seulement.
D. En demandant un délai supplémentaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Castillo, pour le règlement de votre déménagement, vous pouvez payer en trois fois sans frais, ou en une seule fois avec une remise de cinq pour cent.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cinq pour cent sur neuf cents euros, ça fait quarante-cinq euros d''économie. Je paie tout maintenant.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, je note un paiement comptant.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client décide-t-il de payer ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En une seule fois, pour profiter de la remise.<break time="700ms"/>B.<break time="300ms"/>En trois fois sans frais.<break time="700ms"/>C.<break time="300ms"/>Le jour du déménagement seulement.<break time="700ms"/>D.<break time="300ms"/>En demandant un délai supplémentaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Modalité de paiement déduite par inférence simple** : il faut relier la remise de cinq pour cent offerte pour un paiement en une seule fois et le calcul du client (« quarante-cinq euros d''économie, je paie tout maintenant »), confirmé par « je note un paiement comptant » — A est correct. B est l''option **présentée puis écartée** : le paiement en trois fois ne donne pas droit à la remise. C contredit « je paie tout maintenant » : rien n''est reporté au jour du déménagement. D n''apparaît pas dans le dialogue : le client ne demande aucun délai, il accélère au contraire le règlement.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Nguyen, votre canapé d''angle ne passera jamais dans l''escalier : il est trop étroit au quatrième étage.
[Femme] Qu''est-ce qu''on peut faire, alors ?
[Homme] On peut le monter par la fenêtre du salon avec un monte-meubles. C''est quatre-vingts euros de plus.
[Femme] D''accord, je n''ai pas le choix, allons-y pour le monte-meubles.

Comment le canapé va-t-il entrer dans l''appartement ?

A. Par l''escalier, après avoir été démonté.
B. Il restera au rez-de-chaussée de l''immeuble.
C. Par l''ascenseur de l''immeuble.
D. Par la fenêtre, grâce à un monte-meubles.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Nguyen, votre canapé d''angle ne passera jamais dans l''escalier : il est trop étroit au quatrième étage.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Qu''est-ce qu''on peut faire, alors ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On peut le monter par la fenêtre du salon avec un monte-meubles. C''est quatre-vingts euros de plus.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, je n''ai pas le choix, allons-y pour le monte-meubles.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le canapé va-t-il entrer dans l''appartement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par l''escalier, après avoir été démonté.<break time="700ms"/>B.<break time="300ms"/>Il restera au rez-de-chaussée de l''immeuble.<break time="700ms"/>C.<break time="300ms"/>Par l''ascenseur de l''immeuble.<break time="700ms"/>D.<break time="300ms"/>Par la fenêtre, grâce à un monte-meubles.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **le moyen** de faire entrer le canapé. Le déménageur propose « on peut le monter par la fenêtre du salon avec un monte-meubles » et la cliente accepte (« allons-y pour le monte-meubles ») : D est correct — **inférence simple** proposition + accord. A reprend la voie **déclarée impossible** : l''escalier est trop étroit au quatrième étage, et personne ne parle de démonter le meuble. B contredit l''accord final : une solution payante est trouvée, le canapé montera bien. C n''est jamais mentionné — distracteur plausible dans un immeuble, mais absent du document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour madame, je déménage la semaine prochaine. Je voudrais réserver l''ascenseur de l''immeuble pour samedi matin.
[Femme] Ah, samedi matin, il est déjà réservé par les nouveaux voisins du cinquième. Il reste samedi après-midi ou dimanche.
[Homme] Dimanche, les amis qui m''aident ne sont pas libres. Va pour samedi après-midi, alors.

Quand le résident va-t-il utiliser l''ascenseur pour son déménagement ?

A. Samedi matin.
B. Samedi après-midi.
C. Dimanche.
D. La semaine suivante.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour madame, je déménage la semaine prochaine. Je voudrais réserver l''ascenseur de l''immeuble pour samedi matin.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ah, samedi matin, il est déjà réservé par les nouveaux voisins du cinquième. Il reste samedi après-midi ou dimanche.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dimanche, les amis qui m''aident ne sont pas libres. Va pour samedi après-midi, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand le résident va-t-il utiliser l''ascenseur pour son déménagement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Samedi matin.<break time="700ms"/>B.<break time="300ms"/>Samedi après-midi.<break time="700ms"/>C.<break time="300ms"/>Dimanche.<break time="700ms"/>D.<break time="300ms"/>La semaine suivante.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple par élimination** : samedi matin est déjà réservé et le dimanche est exclu (« les amis qui m''aident ne sont pas libres »), donc le résident conclut « va pour samedi après-midi » — B est correct. A est le créneau **demandé au départ mais indisponible** : piège de la première information entendue. C est l''option proposée par la gardienne puis écartée à cause de l''indisponibilité des amis. D n''est pas cohérent : le déménagement a lieu « la semaine prochaine », aucun report n''est envisagé. Mécanisme B1 : suivre l''élimination successive des créneaux pour retenir le choix final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je quitte mon appartement de Rennes le trente juin, mais mon nouveau logement à Dijon ne sera libre que le quinze juillet.
[Homme] Dans ce cas, nous avons un box de dix mètres carrés à soixante-dix euros pour ces deux semaines, madame Petrova.
[Femme] Très bien, je le prends pour stocker mes meubles en attendant.

Pourquoi la cliente loue-t-elle un garde-meuble ?

A. Parce que son nouveau logement n''est pas encore disponible.
B. Parce qu''elle veut vendre ses meubles.
C. Parce que son appartement de Rennes est trop petit.
D. Parce que les déménageurs ont pris du retard.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je quitte mon appartement de Rennes le trente juin, mais mon nouveau logement à Dijon ne sera libre que le quinze juillet.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans ce cas, nous avons un box de dix mètres carrés à soixante-dix euros pour ces deux semaines, madame Petrova.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je le prends pour stocker mes meubles en attendant.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente loue-t-elle un garde-meuble ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que son nouveau logement n''est pas encore disponible.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle veut vendre ses meubles.<break time="700ms"/>C.<break time="300ms"/>Parce que son appartement de Rennes est trop petit.<break time="700ms"/>D.<break time="300ms"/>Parce que les déménageurs ont pris du retard.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, à déduire du décalage des dates : la cliente part de Rennes le trente juin mais son logement de Dijon « ne sera libre que le quinze juillet », d''où le stockage « en attendant » — A est correct (**inférence simple** : relier les deux dates). B est contredit par « pour stocker mes meubles » : elle les garde, elle ne les vend pas. C invente une cause plausible mais absente : la taille de l''appartement n''est jamais évoquée. D également : aucun retard des déménageurs n''est mentionné. Piège B1 : retenir la cause réellement déductible du document, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Il me faut une trentaine de cartons pour mon déménagement. Au magasin de bricolage, ils coûtent deux euros pièce.
[Femme] Soixante euros pour des cartons, Wei ? J''ai gardé tous les miens depuis mon déménagement, je te les donne.
[Homme] C''est gentil, Fatou ! Je passe les prendre chez toi ce soir avec ma voiture.

Comment Wei va-t-il obtenir ses cartons ?

A. Il va les acheter au magasin de bricolage.
B. Il va les commander sur Internet.
C. Il va récupérer gratuitement ceux de sa collègue.
D. Il va les demander à un supermarché.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Il me faut une trentaine de cartons pour mon déménagement. Au magasin de bricolage, ils coûtent deux euros pièce.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Soixante euros pour des cartons, Wei ? J''ai gardé tous les miens depuis mon déménagement, je te les donne.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est gentil, Fatou ! Je passe les prendre chez toi ce soir avec ma voiture.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment Wei va-t-il obtenir ses cartons ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il va les acheter au magasin de bricolage.<break time="700ms"/>B.<break time="300ms"/>Il va les commander sur Internet.<break time="700ms"/>C.<break time="300ms"/>Il va récupérer gratuitement ceux de sa collègue.<break time="700ms"/>D.<break time="300ms"/>Il va les demander à un supermarché.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple coût → solution gratuite** : Fatou s''étonne du prix (« soixante euros pour des cartons ? »), propose les siens (« je te les donne ») et Wei accepte (« je passe les prendre chez toi ce soir ») — C est correct. A est l''option **chiffrée puis abandonnée** : le magasin de bricolage ne servait que de point de comparaison, son prix est précisément ce qui est évité. B n''apparaît nulle part dans le dialogue : aucune commande en ligne n''est envisagée. D est un moyen courant et crédible d''obtenir des cartons, donc thématiquement proche, mais aucun supermarché n''est évoqué ici.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je déménage de Marseille à la fin du mois. Je voudrais faire suivre mon courrier à ma nouvelle adresse.
[Femme] Bien sûr, monsieur Bensaïd. La réexpédition existe en deux formules : six mois à trente-trois euros, ou douze mois à cinquante-cinq euros.
[Homme] J''aurai prévenu tous les organismes avant l''automne. Six mois suffiront.

Quelle formule le client choisit-il ?

A. La réexpédition de douze mois.
B. La réexpédition de six mois.
C. Il garde son ancienne adresse.
D. Il viendra chercher son courrier lui-même.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je déménage de Marseille à la fin du mois. Je voudrais faire suivre mon courrier à ma nouvelle adresse.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bien sûr, monsieur Bensaïd. La réexpédition existe en deux formules : six mois à trente-trois euros, ou douze mois à cinquante-cinq euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''aurai prévenu tous les organismes avant l''automne. Six mois suffiront.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle formule le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La réexpédition de douze mois.<break time="700ms"/>B.<break time="300ms"/>La réexpédition de six mois.<break time="700ms"/>C.<break time="300ms"/>Il garde son ancienne adresse.<break time="700ms"/>D.<break time="300ms"/>Il viendra chercher son courrier lui-même.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple durée du besoin → formule** : le client estime « j''aurai prévenu tous les organismes avant l''automne », donc la formule courte couvre son besoin et il conclut « six mois suffiront » — B est correct. A est l''autre formule présentée, plus longue et plus chère, **écartée** parce qu''inutile au-delà de l''automne. C contredit l''objet même de sa démarche : il vient justement faire suivre son courrier vers la nouvelle adresse. D n''est jamais proposé : aucun retrait du courrier sur place n''est évoqué au guichet. Mécanisme B1 : relier l''échéance annoncée et la durée de la formule choisie.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Qui va vous aider à porter les meubles ?

A. Samedi prochain, vers huit heures.
B. Avec un grand camion de location.
C. Au deuxième étage, sans ascenseur.
D. Mes deux frères et un collègue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Qui va vous aider à porter les meubles ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Samedi prochain, vers huit heures.<break time="700ms"/>B.<break time="300ms"/>Avec un grand camion de location.<break time="700ms"/>C.<break time="300ms"/>Au deuxième étage, sans ascenseur.<break time="700ms"/>D.<break time="300ms"/>Mes deux frères et un collègue.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « qui va vous aider ? » porte sur **des personnes** : seule D « mes deux frères et un collègue » désigne des aides humaines. A donne **un moment** et répondrait à « quand déménagez-vous ? ». B donne **un moyen de transport** et répondrait à « comment transportez-vous vos affaires ? ». C donne **un lieu** et répondrait à « où se trouve le nouvel appartement ? ». Mécanisme B1 : identifier le pronom interrogatif « qui » et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte d''un déménagement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Comment allez-vous descendre le réfrigérateur ?

A. Avec un diable et des sangles.
B. Dès demain matin, très tôt.
C. Parce qu''il est trop vieux.
D. Dans la cuisine du nouvel appartement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment allez-vous descendre le réfrigérateur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un diable et des sangles.<break time="700ms"/>B.<break time="300ms"/>Dès demain matin, très tôt.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il est trop vieux.<break time="700ms"/>D.<break time="300ms"/>Dans la cuisine du nouvel appartement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment allez-vous descendre... ? » demande **un moyen, une manière** : seule A « avec un diable et des sangles » décrit la méthode employée. B indique **un moment** et répondrait à « quand le descendrez-vous ? ». C, introduite par « parce que », donne **une cause** et répondrait à « pourquoi changez-vous de réfrigérateur ? ». D donne **un lieu de destination** et répondrait à « où ira le réfrigérateur ? ». Piège B1 : toutes les propositions parlent du même appareil, seul l''adverbe interrogatif « comment » impose une réponse en manière, pas en moment, en cause ni en lieu.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00c-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Vous emménagez où, finalement ?

A. Le premier août, normalement.
B. Pour me rapprocher de mon travail.
C. À Strasbourg, près du grand parc.
D. Avec l''aide de mes voisins.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous emménagez où, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le premier août, normalement.<break time="700ms"/>B.<break time="300ms"/>Pour me rapprocher de mon travail.<break time="700ms"/>C.<break time="300ms"/>À Strasbourg, près du grand parc.<break time="700ms"/>D.<break time="300ms"/>Avec l''aide de mes voisins.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Vous emménagez où ? » appelle **un lieu** : seule C « à Strasbourg, près du grand parc » localise le nouveau logement. A donne **une date** et répondrait à « quand emménagez-vous ? ». B, introduite par « pour », exprime **un but** et répondrait à « pourquoi déménagez-vous ? ». D désigne **des personnes** et répondrait à « avec qui allez-vous déménager ? ». Mécanisme B1 : l''adverbe interrogatif « où » impose une réponse de localisation, pas de moment, de but ni d''accompagnement — les quatre réponses restent pourtant toutes crédibles dans une conversation de déménagement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b00c-1000-0000-000000000001 → 0a.
-- [x] Thème unique « déménagement », 10 situations toutes différentes :
--     choix entre deux devis de déménageurs, modalité de paiement (comptant
--     avec remise), passage du canapé par monte-meubles, réservation de
--     l'ascenseur auprès de la gardienne, location d'un garde-meuble entre
--     deux logements, cartons gratuits d'une collègue, réexpédition du
--     courrier, personnes qui aident à porter, moyen de descendre le
--     réfrigérateur, lieu du nouvel emménagement.
-- [x] Aucun thème interdit (pas de location de logement, SAV, médecin, banque,
--     mairie, voyage, restaurant, téléphonie, école, travail, location de
--     voiture, assurance, livraison/colis, hôtel, pharmacie).
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~40-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 2,5,9), B=2 (items 4,7),
--     C=3 (items 1,6,10), D=2 (items 3,8) — 4 lettres utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,4,7), modalité de paiement (2),
--     solution/choix retenu (3,6), cause à déduire de deux dates (5) ;
--     explicite + distracteurs proches (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, élimination, cause vs but, adverbe/pronom interrogatif).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms et villes variés
--     (Romero, Castillo, Nguyen, Petrova, Wei, Fatou, Bensaïd — Toulouse,
--     Rennes, Dijon, Marseille, Strasbourg).
-- ============================================================================
