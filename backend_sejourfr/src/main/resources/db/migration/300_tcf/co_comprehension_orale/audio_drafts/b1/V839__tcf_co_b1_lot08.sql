-- ============================================================================
-- V839 — TCF CO B1 — lot 08 (thème : opérateur téléphonique)
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
  ('66666666-b008-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Sarr, nous avons deux forfaits : celui à douze euros avec vingt gigas, et celui à dix-sept euros avec cent gigas.
[Homme] Je regarde beaucoup de vidéos dans le tramway. Je prends celui à cent gigas, même s''il est plus cher.
[Femme] Très bien, je vous l''active tout de suite.

Quel forfait le client choisit-il ?

A. Le forfait à douze euros.
B. Le forfait avec cent gigas.
C. Un forfait sans internet.
D. Il garde son ancien forfait.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Sarr, nous avons deux forfaits : celui à douze euros avec vingt gigas, et celui à dix-sept euros avec cent gigas.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je regarde beaucoup de vidéos dans le tramway. Je prends celui à cent gigas, même s''il est plus cher.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je vous l''active tout de suite.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel forfait le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le forfait à douze euros.<break time="700ms"/>B.<break time="300ms"/>Le forfait avec cent gigas.<break time="700ms"/>C.<break time="300ms"/>Un forfait sans internet.<break time="700ms"/>D.<break time="300ms"/>Il garde son ancien forfait.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple besoin → choix** : il faut relier l''usage du client (« je regarde beaucoup de vidéos ») et sa décision « je prends celui à cent gigas », confirmée par la conseillère (« je vous l''active »). B est correct. A reprend le forfait **mentionné puis écarté** parce qu''il a moins de données — piège de la première offre entendue ; il répondrait à « quel forfait est le moins cher ? ». C n''existe pas dans le dialogue : les deux offres incluent internet. D contredit l''activation immédiate du nouveau forfait par la conseillère.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Le nouveau téléphone coûte deux cent quarante euros, madame Fernandes. Vous réglez comptant ?
[Femme] C''est beaucoup d''un coup. Vous proposez un paiement en plusieurs fois ?
[Homme] Oui, vingt euros par mois pendant douze mois, ajoutés à votre facture.
[Femme] Parfait, je choisis cette solution.

Comment la cliente va-t-elle payer son téléphone ?

A. En une seule fois, le jour de l''achat.
B. En espèces au magasin.
C. En douze mensualités sur sa facture.
D. Avec une carte cadeau de l''opérateur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le nouveau téléphone coûte deux cent quarante euros, madame Fernandes. Vous réglez comptant ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est beaucoup d''un coup. Vous proposez un paiement en plusieurs fois ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, vingt euros par mois pendant douze mois, ajoutés à votre facture.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, je choisis cette solution.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle payer son téléphone ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En une seule fois, le jour de l''achat.<break time="700ms"/>B.<break time="300ms"/>En espèces au magasin.<break time="700ms"/>C.<break time="300ms"/>En douze mensualités sur sa facture.<break time="700ms"/>D.<break time="300ms"/>Avec une carte cadeau de l''opérateur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : la cliente écarte le paiement comptant (« c''est beaucoup d''un coup »), le vendeur détaille l''alternative (« vingt euros par mois pendant douze mois, ajoutés à votre facture ») et elle conclut « je choisis cette solution ». C est correct. A est l''option **proposée puis refusée** — piège de la première mention. B n''est jamais évoqué : aucun mode de règlement en espèces n''apparaît dans le dialogue. D est un distracteur thématique plausible en boutique, mais absent du document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, c''est madame Lin. Chez moi, je n''ai presque pas de réseau : mes appels coupent tout le temps.
[Homme] Votre téléphone est récent, madame. Vous pouvez activer les appels par wifi dans les réglages, c''est gratuit.
[Femme] Ah, très bien, je vais activer ça dès ce soir.

Que va faire la cliente pour téléphoner chez elle ?

A. Activer les appels par wifi.
B. Acheter un téléphone plus récent.
C. Changer d''opérateur.
D. Installer une antenne sur son toit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, c''est madame Lin. Chez moi, je n''ai presque pas de réseau : mes appels coupent tout le temps.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Votre téléphone est récent, madame. Vous pouvez activer les appels par wifi dans les réglages, c''est gratuit.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ah, très bien, je vais activer ça dès ce soir.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire la cliente pour téléphoner chez elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Activer les appels par wifi.<break time="700ms"/>B.<break time="300ms"/>Acheter un téléphone plus récent.<break time="700ms"/>C.<break time="300ms"/>Changer d''opérateur.<break time="700ms"/>D.<break time="300ms"/>Installer une antenne sur son toit.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple solution proposée + accord** : le conseiller propose « activer les appels par wifi dans les réglages » et la cliente répond « je vais activer ça dès ce soir » — A est correct. B est contredit par le document : le conseiller précise justement que son téléphone **est récent**, donc compatible. C serait une réaction possible au problème de réseau, mais elle n''est **jamais envisagée** dans l''échange. D est une solution technique imaginaire, absente du dialogue — distracteur thématique lié au réseau. Mécanisme B1 : relier la proposition du conseiller et l''acceptation de la cliente.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je vous appelle pour résilier mon abonnement : il est devenu trop cher pour moi.
[Femme] Attendez, monsieur Benkacem : je peux baisser votre forfait de huit euros par mois pendant un an.
[Homme] À ce prix-là, c''est différent. D''accord, je reste chez vous.

Que décide finalement le client ?

A. Résilier son abonnement.
B. Passer à un forfait plus cher.
C. Réfléchir encore une semaine.
D. Garder son abonnement avec la remise.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je vous appelle pour résilier mon abonnement : il est devenu trop cher pour moi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Attendez, monsieur Benkacem : je peux baisser votre forfait de huit euros par mois pendant un an.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À ce prix-là, c''est différent. D''accord, je reste chez vous.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide finalement le client ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Résilier son abonnement.<break time="700ms"/>B.<break time="300ms"/>Passer à un forfait plus cher.<break time="700ms"/>C.<break time="300ms"/>Réfléchir encore une semaine.<break time="700ms"/>D.<break time="300ms"/>Garder son abonnement avec la remise.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier l''offre de la conseillère (une baisse de huit euros par mois pendant un an) et la conclusion du client « d''accord, je reste chez vous ». D est correct. A est l''intention **initiale, abandonnée** en fin de dialogue — piège classique de la première information entendue ; elle répondrait à « pourquoi le client appelle-t-il ? ». B inverse le sens de l''offre : le forfait devient **moins** cher, pas plus. C ne correspond à rien : le client tranche immédiatement, sans demander de délai.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je change d''opérateur le mois prochain, mais je veux absolument garder mon numéro de téléphone.
[Homme] C''est possible, madame Tkachenko. Appelez le 31 79 pour recevoir votre code RIO, puis donnez ce code au nouvel opérateur.
[Femme] Parfait, je fais la démarche dès cet après-midi.

Que doit faire la cliente pour garder son numéro ?

A. Acheter une nouvelle carte SIM en boutique.
B. Obtenir son code RIO et le donner au nouvel opérateur.
C. Résilier d''abord son ancien abonnement.
D. Remplir un formulaire papier à la poste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je change d''opérateur le mois prochain, mais je veux absolument garder mon numéro de téléphone.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est possible, madame Tkachenko. Appelez le 31 79 pour recevoir votre code RIO, puis donnez ce code au nouvel opérateur.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Parfait, je fais la démarche dès cet après-midi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que doit faire la cliente pour garder son numéro ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Acheter une nouvelle carte SIM en boutique.<break time="700ms"/>B.<break time="300ms"/>Obtenir son code RIO et le donner au nouvel opérateur.<break time="700ms"/>C.<break time="300ms"/>Résilier d''abord son ancien abonnement.<break time="700ms"/>D.<break time="300ms"/>Remplir un formulaire papier à la poste.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **la démarche à suivre**, énoncée explicitement par le conseiller : « appelez le 31 79 pour recevoir votre code RIO, puis donnez ce code au nouvel opérateur » — B est correct, en reliant les **deux étapes** de la procédure (inférence simple de chronologie : d''abord le code, ensuite le transfert). A confond conserver son numéro et changer de carte : aucune carte SIM n''est mentionnée. C est même contraire à la pratique évoquée : rien n''indique qu''il faut résilier avant, c''est le code RIO qui déclenche le transfert. D invente un canal (formulaire, poste) absent du dialogue.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je pars un mois à Montréal pour le travail. Mon forfait fonctionne là-bas ?
[Femme] Non, le Canada n''est pas inclus, monsieur Morales. Soit vous payez chaque appel hors forfait, c''est très cher, soit vous prenez l''option internationale à douze euros.
[Homme] Hors forfait, non merci ! Je prends l''option.

Comment le client va-t-il téléphoner au Canada ?

A. Avec son forfait habituel, sans rien changer.
B. En payant chaque appel hors forfait.
C. Avec l''option internationale à douze euros.
D. En achetant une carte SIM canadienne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je pars un mois à Montréal pour le travail. Mon forfait fonctionne là-bas ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Non, le Canada n''est pas inclus, monsieur Morales. Soit vous payez chaque appel hors forfait, c''est très cher, soit vous prenez l''option internationale à douze euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Hors forfait, non merci ! Je prends l''option.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client va-t-il téléphoner au Canada ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec son forfait habituel, sans rien changer.<break time="700ms"/>B.<break time="300ms"/>En payant chaque appel hors forfait.<break time="700ms"/>C.<break time="300ms"/>Avec l''option internationale à douze euros.<break time="700ms"/>D.<break time="300ms"/>En achetant une carte SIM canadienne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple sur une alternative « soit… soit… »** : la conseillère présente deux solutions, le client rejette la première (« hors forfait, non merci ! ») et conclut « je prends l''option » — C est correct. A est exclu d''emblée : « le Canada n''est pas inclus » dans son forfait actuel. B est l''option explicitement **refusée** parce que trop chère — piège de la solution citée en premier. D serait une solution réaliste pour un voyageur, mais elle n''apparaît **jamais** dans le dialogue : distracteur thématique hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Ma carte SIM est cassée et je pars en déplacement jeudi : il me faut une solution rapide.
[Homme] La nouvelle carte arrive par courrier sous cinq jours, madame Patel. Sinon, votre téléphone accepte la eSIM, activable en dix minutes.
[Femme] Jeudi, c''est dans deux jours… Je prends la eSIM.

Pourquoi la cliente choisit-elle la eSIM ?

A. Parce qu''elle est immédiate et qu''elle part dans deux jours.
B. Parce qu''elle coûte moins cher que la carte classique.
C. Parce que le courrier a perdu sa nouvelle carte.
D. Parce que son téléphone refuse les cartes SIM classiques.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ma carte SIM est cassée et je pars en déplacement jeudi : il me faut une solution rapide.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La nouvelle carte arrive par courrier sous cinq jours, madame Patel. Sinon, votre téléphone accepte la eSIM, activable en dix minutes.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Jeudi, c''est dans deux jours… Je prends la eSIM.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente choisit-elle la eSIM ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''elle est immédiate et qu''elle part dans deux jours.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle coûte moins cher que la carte classique.<break time="700ms"/>C.<break time="300ms"/>Parce que le courrier a perdu sa nouvelle carte.<break time="700ms"/>D.<break time="300ms"/>Parce que son téléphone refuse les cartes SIM classiques.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple cause → choix** : il faut comparer les délais — courrier « sous cinq jours » contre eSIM « activable en dix minutes » — et les relier au départ de jeudi (« c''est dans deux jours ») pour comprendre que la cliente choisit la rapidité. A est correct. B invente un critère de **prix** : aucun tarif n''est comparé dans le dialogue. C déforme les faits : la carte est **cassée**, pas perdue par le courrier. D contredit le conseiller, qui propose justement l''envoi d''une carte classique — le téléphone accepte les deux formats. Piège B1 : retenir la cause réellement déduite du calendrier, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi est-ce que je n''ai plus de réseau depuis ce matin ?

A. Dans tout le quartier nord de la ville.
B. Depuis huit heures, environ.
C. Pour vérifier l''état de votre ligne.
D. Parce qu''une antenne est en panne dans votre secteur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi est-ce que je n''ai plus de réseau depuis ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans tout le quartier nord de la ville.<break time="700ms"/>B.<break time="300ms"/>Depuis huit heures, environ.<break time="700ms"/>C.<break time="300ms"/>Pour vérifier l''état de votre ligne.<break time="700ms"/>D.<break time="300ms"/>Parce qu''une antenne est en panne dans votre secteur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause** : seule D, introduite par « parce que », explique la coupure (« une antenne est en panne »). A donne **un lieu** et répondrait à « où le réseau est-il coupé ? ». B donne **un moment** et répondrait à « depuis quand n''y a-t-il plus de réseau ? » — piège renforcé par le « depuis ce matin » de la question. C, introduit par « pour », exprime **un but** et répondrait à « pourquoi le technicien intervient-il ? ». Mécanisme B1 : distinguer cause (« parce que ») et but (« pour »), toutes les réponses restant liées à la panne de réseau.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Il vous reste combien de gigas d''internet sur votre forfait ce mois-ci ?

A. Jusqu''au trente du mois, normalement.
B. Environ deux gigas seulement.
C. Sur l''application de mon opérateur.
D. Parce que je regarde trop de vidéos.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Il vous reste combien de gigas d''internet sur votre forfait ce mois-ci ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''au trente du mois, normalement.<break time="700ms"/>B.<break time="300ms"/>Environ deux gigas seulement.<break time="700ms"/>C.<break time="300ms"/>Sur l''application de mon opérateur.<break time="700ms"/>D.<break time="300ms"/>Parce que je regarde trop de vidéos.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de gigas ? » demande **une quantité** : seule B donne un volume de données (« environ deux gigas seulement »). A indique **une échéance** et répondrait à « jusqu''à quand le forfait est-il valable ? ». C indique **l''endroit où consulter** sa consommation et répondrait à « où peut-on vérifier ce qu''il reste ? ». D, introduit par « parce que », donne **une cause** et répondrait à « pourquoi avez-vous consommé autant ? ». Piège B1 classique : toutes les réponses parlent du forfait internet, seule la nature de la question — un volume — permet de trancher.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b008-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Comment est-ce que je peux suivre ma consommation téléphonique ?

A. Une fois par semaine, c''est suffisant.
B. Avant la fin du mois, de préférence.
C. En téléchargeant l''application gratuite de votre opérateur.
D. À cause des mises à jour automatiques.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment est-ce que je peux suivre ma consommation téléphonique ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une fois par semaine, c''est suffisant.<break time="700ms"/>B.<break time="300ms"/>Avant la fin du mois, de préférence.<break time="700ms"/>C.<break time="300ms"/>En téléchargeant l''application gratuite de votre opérateur.<break time="700ms"/>D.<break time="300ms"/>À cause des mises à jour automatiques.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment ? » appelle **un moyen** : seule C, avec le **gérondif de moyen** « en téléchargeant l''application », explique la manière de suivre sa consommation. A donne **une fréquence** et répondrait à « tous les combien faut-il vérifier ? ». B donne **un moment limite** et répondrait à « quand faut-il vérifier sa consommation ? ». D, introduit par « à cause de », donne **une cause** et répondrait à « pourquoi votre consommation a-t-elle augmenté ? ». Mécanisme B1 : reconnaître que « comment » exige un moyen (gérondif), pas une fréquence, un moment ni une cause.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b008-1000-0000-000000000001 → 0a.
-- [x] Thème unique « opérateur téléphonique », 10 situations toutes différentes :
--     choix entre 2 forfaits mobiles, paiement du téléphone en mensualités,
--     appels par wifi faute de réseau, rétention après demande de résiliation,
--     portabilité du numéro (code RIO), option internationale pour le Canada,
--     remplacement de SIM cassée par eSIM, cause d'une panne de réseau,
--     gigas restants sur le forfait, moyen de suivre sa consommation.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 3,7), B=3 (items 1,5,9),
--     C=3 (items 2,6,10), D=2 (items 4,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,4,6), moyen de paiement (2),
--     solution retenue et sa cause (3,5,7) ; explicite + distracteurs proches
--     (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, gérondif de moyen, alternative soit…soit).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original. Prénoms/villes variés
--     (Sarr, Fernandes, Lin, Benkacem, Tkachenko, Morales, Patel ; Montréal).
-- ============================================================================
