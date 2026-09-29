-- ============================================================================
-- V844 — TCF CO B1 — lot 13 (thème : assurance)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, moyen de
-- remboursement, créneau retenu). Contenu 100 % original, déterministe,
-- rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b00d-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Tkachenko, j''ai deux formules pour assurer votre appartement de Strasbourg : la formule simple à douze euros par mois, ou la formule complète à dix-huit euros, qui couvre aussi le vol.
[Femme] J''habite au rez-de-chaussée, alors je préfère être protégée contre le vol, même si c''est plus cher.
[Homme] Très bien, je vous inscris à la formule complète.

Quelle formule la cliente choisit-elle ?

A. La formule simple à douze euros.
B. La formule complète, qui couvre le vol.
C. Une formule sans garantie contre le vol.
D. Aucune formule pour le moment.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Tkachenko, j''ai deux formules pour assurer votre appartement de Strasbourg : la formule simple à douze euros par mois, ou la formule complète à dix-huit euros, qui couvre aussi le vol.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''habite au rez-de-chaussée, alors je préfère être protégée contre le vol, même si c''est plus cher.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je vous inscris à la formule complète.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle formule la cliente choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La formule simple à douze euros.<break time="700ms"/>B.<break time="300ms"/>La formule complète, qui couvre le vol.<break time="700ms"/>C.<break time="300ms"/>Une formule sans garantie contre le vol.<break time="700ms"/>D.<break time="300ms"/>Aucune formule pour le moment.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple critère → décision** : il faut relier « j''habite au rez-de-chaussée » et « je préfère être protégée contre le vol » à la confirmation de l''assureur (« je vous inscris à la formule complète ») pour conclure que B est correct. A est la formule **mentionnée puis écartée** parce qu''elle ne couvre pas le vol — piège du premier prix entendu. C décrit exactement l''inverse du besoin exprimé par la cliente. D contredit l''inscription finale prononcée par l''assureur : un contrat est bien conclu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour monsieur Keita, bonne nouvelle : votre dossier pour le vélo volé est accepté. Nous vous remboursons deux cent quarante euros.
[Homme] Vous pouvez m''envoyer un chèque ?
[Femme] Nous ne faisons plus de chèques depuis janvier. Ce sera un virement sur votre compte, sous huit jours.
[Homme] D''accord, je vous transmets mon RIB tout de suite.

Comment l''assuré va-t-il être remboursé ?

A. En espèces à l''agence.
B. Par chèque.
C. En bons d''achat.
D. Par virement bancaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour monsieur Keita, bonne nouvelle : votre dossier pour le vélo volé est accepté. Nous vous remboursons deux cent quarante euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous pouvez m''envoyer un chèque ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Nous ne faisons plus de chèques depuis janvier. Ce sera un virement sur votre compte, sous huit jours.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, je vous transmets mon RIB tout de suite.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment l''assuré va-t-il être remboursé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En espèces à l''agence.<break time="700ms"/>B.<break time="300ms"/>Par chèque.<break time="700ms"/>C.<break time="300ms"/>En bons d''achat.<break time="700ms"/>D.<break time="300ms"/>Par virement bancaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de remboursement déduit par inférence simple** : le chèque demandé est refusé (« nous ne faisons plus de chèques ») et la gestionnaire annonce « ce sera un virement sur votre compte », ce que le client accepte en transmettant son RIB — D est correct. B est le moyen **demandé puis refusé** : piège de la première mention. A et C ne sont jamais évoqués dans le dialogue : ce sont des distracteurs thématiques plausibles dans un contexte de remboursement. Mécanisme B1 : relier le refus et l''alternative annoncée pour déduire le moyen final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour votre pare-brise fissuré, madame Rojas, vous avez deux solutions : notre garage partenaire, sans rien avancer, ou le garage de votre choix, mais vous payez d''abord et nous vous remboursons ensuite.
[Femme] Je ne veux pas avancer les frais. Je choisis votre garage partenaire.
[Homme] Parfait, il vous appellera demain pour fixer le rendez-vous.

Que décide la cliente ?

A. Faire réparer le pare-brise chez le garage partenaire.
B. Payer d''abord dans le garage de son choix.
C. Attendre avant de faire la réparation.
D. Annuler sa déclaration de sinistre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour votre pare-brise fissuré, madame Rojas, vous avez deux solutions : notre garage partenaire, sans rien avancer, ou le garage de votre choix, mais vous payez d''abord et nous vous remboursons ensuite.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je ne veux pas avancer les frais. Je choisis votre garage partenaire.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Parfait, il vous appellera demain pour fixer le rendez-vous.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide la cliente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Faire réparer le pare-brise chez le garage partenaire.<break time="700ms"/>B.<break time="300ms"/>Payer d''abord dans le garage de son choix.<break time="700ms"/>C.<break time="300ms"/>Attendre avant de faire la réparation.<break time="700ms"/>D.<break time="300ms"/>Annuler sa déclaration de sinistre.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : la cliente refuse d''avancer les frais, or seule l''option du garage partenaire le permet (« sans rien avancer ») ; elle conclut « je choisis votre garage partenaire » — A est correct. B est l''option **écartée** précisément parce qu''elle oblige à payer d''abord. C contredit la suite du dialogue : le rendez-vous est fixé dès le lendemain. D n''est jamais envisagé : le dossier de sinistre suit son cours normalement.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Wang, notre complémentaire santé existe en trois niveaux. Est-ce que vous portez des lunettes ?
[Homme] Oui, et je dois en changer presque chaque année.
[Femme] Alors le niveau deux ne suffira pas : seul le niveau trois rembourse bien l''optique.
[Homme] Dans ce cas, je prends le niveau trois.

Pourquoi le client choisit-il le niveau trois ?

A. Parce que c''est la formule la moins chère.
B. Parce qu''il couvre mieux les soins dentaires.
C. Parce qu''il rembourse mieux les lunettes.
D. Parce que son employeur l''impose.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Wang, notre complémentaire santé existe en trois niveaux. Est-ce que vous portez des lunettes ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, et je dois en changer presque chaque année.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors le niveau deux ne suffira pas : seul le niveau trois rembourse bien l''optique.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans ce cas, je prends le niveau trois.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le client choisit-il le niveau trois ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que c''est la formule la moins chère.<break time="700ms"/>B.<break time="300ms"/>Parce qu''il couvre mieux les soins dentaires.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il rembourse mieux les lunettes.<break time="700ms"/>D.<break time="300ms"/>Parce que son employeur l''impose.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple besoin → cause du choix** : il faut relier « je dois en changer presque chaque année » (les lunettes) et « seul le niveau trois rembourse bien l''optique » pour comprendre la raison du choix — C est correct. A n''est pas mentionné, et le niveau trois est logiquement le plus complet, donc pas le moins cher. B remplace l''optique par le **dentaire**, jamais évoqué : piège de substitution thématique. D invente une obligation extérieure absente du dialogue : la décision vient du besoin du client, pas de son employeur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, c''est Diego Marquez. Je vends ma moto la semaine prochaine, je veux donc arrêter mon assurance.
[Femme] C''est possible. Envoyez-nous une copie de l''acte de vente, et le contrat s''arrêtera le jour de la vente. Les mois déjà payés vous seront remboursés.
[Homme] Très bien, je vous l''envoie par courriel dès la signature.

Que doit faire le client pour résilier son contrat ?

A. Payer des frais de résiliation.
B. Envoyer une copie de l''acte de vente.
C. Attendre la date anniversaire du contrat.
D. Se déplacer à l''agence avec la moto.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, c''est Diego Marquez. Je vends ma moto la semaine prochaine, je veux donc arrêter mon assurance.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est possible. Envoyez-nous une copie de l''acte de vente, et le contrat s''arrêtera le jour de la vente. Les mois déjà payés vous seront remboursés.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, je vous l''envoie par courriel dès la signature.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que doit faire le client pour résilier son contrat ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Payer des frais de résiliation.<break time="700ms"/>B.<break time="300ms"/>Envoyer une copie de l''acte de vente.<break time="700ms"/>C.<break time="300ms"/>Attendre la date anniversaire du contrat.<break time="700ms"/>D.<break time="300ms"/>Se déplacer à l''agence avec la moto.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conseillère pose **une condition explicite** : « envoyez-nous une copie de l''acte de vente, et le contrat s''arrêtera », et le client accepte (« je vous l''envoie par courriel ») — B est correct. A n''est jamais mentionné ; au contraire, les mois déjà payés seront remboursés. C contredit « le contrat s''arrêtera le jour de la vente » : aucune attente n''est exigée. D confond le canal : l''envoi se fait **par courriel**, pas en agence. Mécanisme B1 : repérer la structure condition + conséquence (« envoyez-nous… et… s''arrêtera »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Sarr, pour votre dégât des eaux dans la cuisine, notre expert peut passer jeudi matin ou vendredi après-midi.
[Homme] Jeudi, je travaille toute la journée à Rennes. Mais le vendredi, je termine à midi.
[Femme] Alors notons vendredi à quinze heures.

Quand l''expert va-t-il passer ?

A. Jeudi matin.
B. Jeudi en fin de journée.
C. Vendredi à midi.
D. Vendredi à quinze heures.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Sarr, pour votre dégât des eaux dans la cuisine, notre expert peut passer jeudi matin ou vendredi après-midi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Jeudi, je travaille toute la journée à Rennes. Mais le vendredi, je termine à midi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors notons vendredi à quinze heures.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand l''expert va-t-il passer ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jeudi matin.<break time="700ms"/>B.<break time="300ms"/>Jeudi en fin de journée.<break time="700ms"/>C.<break time="300ms"/>Vendredi à midi.<break time="700ms"/>D.<break time="300ms"/>Vendredi à quinze heures.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple disponibilité → créneau** : jeudi est impossible (« je travaille toute la journée ») mais le client est libre vendredi après midi, donc la gestionnaire conclut « notons vendredi à quinze heures » — D est correct. A est le créneau **proposé puis éliminé** par l''emploi du temps du client. B n''est jamais proposé dans le dialogue. C confond l''heure de fin de travail du client (« je termine à midi ») avec l''heure du rendez-vous — piège du chiffre entendu. Mécanisme B1 : relier la contrainte et la proposition pour déduire le créneau final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je suis étudiante à Grenoble et l''université me demande une attestation de responsabilité civile avant lundi.
[Homme] Vous pouvez passer à l''agence mercredi prochain, ou la télécharger immédiatement depuis votre espace client en ligne.
[Femme] Mercredi, ce sera trop tard. Je vais la télécharger tout de suite, alors.

Comment l''étudiante va-t-elle obtenir son attestation ?

A. En la téléchargeant depuis son espace en ligne.
B. En passant à l''agence mercredi prochain.
C. En la recevant par courrier postal.
D. En la demandant directement à son université.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je suis étudiante à Grenoble et l''université me demande une attestation de responsabilité civile avant lundi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous pouvez passer à l''agence mercredi prochain, ou la télécharger immédiatement depuis votre espace client en ligne.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mercredi, ce sera trop tard. Je vais la télécharger tout de suite, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment l''étudiante va-t-elle obtenir son attestation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En la téléchargeant depuis son espace en ligne.<break time="700ms"/>B.<break time="300ms"/>En passant à l''agence mercredi prochain.<break time="700ms"/>C.<break time="300ms"/>En la recevant par courrier postal.<break time="700ms"/>D.<break time="300ms"/>En la demandant directement à son université.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple délai → solution** : l''attestation est exigée avant lundi, or l''agence ne peut la délivrer que mercredi (« ce sera trop tard ») ; l''étudiante choisit donc l''option immédiate : « je vais la télécharger tout de suite » — A est correct. B est l''option **écartée** parce qu''elle arrive après la date limite. C n''est jamais proposé dans le dialogue : distracteur thématique plausible mais hors document. D inverse les rôles : c''est l''université qui **réclame** le document, elle ne le délivre pas.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Votre contrat d''assurance habitation arrive à échéance à quelle date ?

A. À l''agence du centre-ville.
B. Par courrier recommandé.
C. Le trente et un octobre prochain.
D. Pour assurer mon nouveau studio.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Votre contrat d''assurance habitation arrive à échéance à quelle date ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''agence du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Par courrier recommandé.<break time="700ms"/>C.<break time="300ms"/>Le trente et un octobre prochain.<break time="700ms"/>D.<break time="300ms"/>Pour assurer mon nouveau studio.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Arrive à échéance **à quelle date** ? » appelle **une date précise** : seule C « le trente et un octobre prochain » situe la fin du contrat dans le temps. A donne **un lieu** et répondrait à « où avez-vous signé votre contrat ? ». B donne **un moyen** et répondrait à « comment faut-il résilier ? ». D, introduit par « pour », exprime **un but** et répondrait à « pourquoi prenez-vous une assurance ? ». Mécanisme B1 : identifier la nature de l''information demandée — les quatre réponses restent crédibles dans le contexte de l''assurance.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] En cas d''accident, la franchise s''élève à combien ?

A. À cent cinquante euros par sinistre.
B. Sous quinze jours, en général.
C. Directement au garagiste.
D. Parce que le contrat est récent.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">En cas d''accident, la franchise s''élève à combien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cent cinquante euros par sinistre.<break time="700ms"/>B.<break time="300ms"/>Sous quinze jours, en général.<break time="700ms"/>C.<break time="300ms"/>Directement au garagiste.<break time="700ms"/>D.<break time="300ms"/>Parce que le contrat est récent.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« S''élève à combien ? » demande **un montant** : seule A donne une somme (« cent cinquante euros par sinistre »). B indique **un délai** et répondrait à « en combien de temps êtes-vous remboursé ? ». C indique **un destinataire** et répondrait à « à qui la franchise est-elle versée ? ». D, introduit par « parce que », donne **une cause** et répondrait à « pourquoi y a-t-il une franchise ? ». Piège B1 classique : les quatre réponses parlent de la franchise, seule la nature de la question — une somme d''argent — permet de trancher.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00d-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi souhaitez-vous changer de compagnie d''assurance ?

A. Depuis le mois de janvier.
B. Auprès d''un courtier en ligne.
C. Parce que mes cotisations ont beaucoup augmenté.
D. Dès la semaine prochaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi souhaitez-vous changer de compagnie d''assurance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le mois de janvier.<break time="700ms"/>B.<break time="300ms"/>Auprès d''un courtier en ligne.<break time="700ms"/>C.<break time="300ms"/>Parce que mes cotisations ont beaucoup augmenté.<break time="700ms"/>D.<break time="300ms"/>Dès la semaine prochaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause** : seule C, introduite par « parce que », explique la décision (« mes cotisations ont beaucoup augmenté »). A exprime **une durée écoulée** avec « depuis » et répondrait à « depuis quand y pensez-vous ? ». B indique **un intermédiaire** et répondrait à « auprès de qui allez-vous souscrire ? ». D donne **un moment futur** et répondrait à « quand allez-vous changer ? ». Mécanisme B1 : faire correspondre le mot interrogatif « pourquoi » au connecteur de cause, sans se laisser distraire par des réponses thématiquement cohérentes.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b00d-1000-0000-000000000001 → 0a.
-- [x] Thème unique « assurance », 10 situations toutes différentes :
--     choix de formule habitation, remboursement d'un vélo volé, réparation
--     de pare-brise (assurance auto), choix de complémentaire santé,
--     résiliation après vente d'une moto, passage de l'expert (dégât des
--     eaux), attestation de responsabilité civile, date d'échéance du
--     contrat, montant de la franchise, motif de changement d'assureur.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 2-4
--     répliques, ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne)
--     + 3 × format B (co_question_reponse, question Henri/Vivienne +
--     propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 3,7,9), B=2 (items 1,5),
--     C=3 (items 4,8,10), D=2 (items 2,6) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,3,5), moyen de remboursement
--     (2), cause du choix (4), créneau déduit (6), solution selon le délai
--     (7) ; explicite + distracteurs proches (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, condition + conséquence, cause vs but, nature de
--     l'information demandée).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95
--     (narration) / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/
--     300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original.
-- ============================================================================
