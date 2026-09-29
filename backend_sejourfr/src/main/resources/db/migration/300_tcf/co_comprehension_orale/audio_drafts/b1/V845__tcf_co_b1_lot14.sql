-- ============================================================================
-- V845 — TCF CO B1 — lot 14 (thème : livraison / colis)
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
  ('66666666-b00e-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, c''est le livreur. Je suis devant chez vous avec votre colis, madame Petrenko, mais personne ne répond.
[Femme] Ah, je suis au bureau jusqu''à dix-huit heures. Vous pouvez le laisser chez ma voisine ?
[Homme] Non, c''est un envoi contre signature. Je peux le déposer au point relais de la rue Carnot.
[Femme] D''accord, j''irai le chercher ce soir en sortant.

Où la cliente va-t-elle récupérer son colis ?

A. Chez sa voisine.
B. Devant sa porte.
C. Au point relais de la rue Carnot.
D. À son bureau.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, c''est le livreur. Je suis devant chez vous avec votre colis, madame Petrenko, mais personne ne répond.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ah, je suis au bureau jusqu''à dix-huit heures. Vous pouvez le laisser chez ma voisine ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, c''est un envoi contre signature. Je peux le déposer au point relais de la rue Carnot.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, j''irai le chercher ce soir en sortant.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Où la cliente va-t-elle récupérer son colis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Chez sa voisine.<break time="700ms"/>B.<break time="300ms"/>Devant sa porte.<break time="700ms"/>C.<break time="300ms"/>Au point relais de la rue Carnot.<break time="700ms"/>D.<break time="300ms"/>À son bureau.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier le refus du livreur (« non, c''est un envoi contre signature »), sa proposition (« je peux le déposer au point relais de la rue Carnot ») et l''accord de la cliente (« d''accord, j''irai le chercher ce soir ») : C est correct. A est la solution **proposée puis refusée** — piège de la première option entendue ; elle répondrait à « que demande d''abord la cliente ? ». B est impossible : un envoi contre signature ne peut pas être laissé devant la porte sans personne. D confond le lieu où se trouve la cliente pendant la tournée avec le lieu de retrait du colis.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, j''ai reçu mon aspirateur ce matin, mais le carton était écrasé et l''appareil ne s''allume plus.
[Homme] Je suis désolé, madame Haddad. Je peux vous rembourser, ou vous renvoyer le même modèle sous trois jours.
[Femme] J''en ai besoin rapidement pour la maison : renvoyez-le-moi.

Quelle solution la cliente choisit-elle ?

A. Le remboursement de sa commande.
B. L''envoi d''un nouvel appareil.
C. Une réparation de l''appareil cassé.
D. Un bon d''achat sur le site.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, j''ai reçu mon aspirateur ce matin, mais le carton était écrasé et l''appareil ne s''allume plus.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis désolé, madame Haddad. Je peux vous rembourser, ou vous renvoyer le même modèle sous trois jours.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''en ai besoin rapidement pour la maison : renvoyez-le-moi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle solution la cliente choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le remboursement de sa commande.<break time="700ms"/>B.<break time="300ms"/>L''envoi d''un nouvel appareil.<break time="700ms"/>C.<break time="300ms"/>Une réparation de l''appareil cassé.<break time="700ms"/>D.<break time="300ms"/>Un bon d''achat sur le site.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **le choix retenu** : il faut relier l''alternative offerte (« vous rembourser, ou vous renvoyer le même modèle ») et la décision finale « renvoyez-le-moi », motivée par le besoin rapide de l''appareil — **inférence simple** besoin → choix, B est correct. A est l''option **proposée puis écartée** : elle répondrait à « que propose d''abord le conseiller ? ». C n''est jamais évoquée : personne ne parle de réparer l''aspirateur endommagé. D est un geste commercial plausible dans ce contexte de colis abîmé, mais absent du dialogue — distracteur purement thématique.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour cette commande, madame Sarr, la livraison standard est gratuite : comptez cinq jours ouvrés.
[Femme] Et en express, c''est possible ?
[Homme] Oui, livraison demain avant treize heures, mais cela coûte sept euros.
[Femme] C''est pour l''anniversaire de ma fille samedi. Je prends l''express, tant pis pour le prix.

Pourquoi la cliente choisit-elle la livraison express ?

A. Parce qu''elle est moins chère que la standard.
B. Parce que la livraison standard n''est plus disponible.
C. Parce que le vendeur la lui a conseillée.
D. Parce qu''elle veut le colis avant samedi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour cette commande, madame Sarr, la livraison standard est gratuite : comptez cinq jours ouvrés.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Et en express, c''est possible ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, livraison demain avant treize heures, mais cela coûte sept euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est pour l''anniversaire de ma fille samedi. Je prends l''express, tant pis pour le prix.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente choisit-elle la livraison express ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''elle est moins chère que la standard.<break time="700ms"/>B.<break time="300ms"/>Parce que la livraison standard n''est plus disponible.<break time="700ms"/>C.<break time="300ms"/>Parce que le vendeur la lui a conseillée.<break time="700ms"/>D.<break time="300ms"/>Parce qu''elle veut le colis avant samedi.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple cause → décision** : il faut relier « c''est pour l''anniversaire de ma fille samedi » et « je prends l''express » pour comprendre que la cliente paie plus cher afin d''être livrée à temps — D est correct. A inverse les faits : l''express coûte **sept euros de plus**, et « tant pis pour le prix » prouve qu''elle accepte ce surcoût. B contredit le dialogue : la standard reste proposée, gratuite, simplement trop lente. C est faux : le vendeur présente les deux options de façon neutre, sans en recommander aucune. Mécanisme B1 : retrouver la cause réelle du choix, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, j''appelle pour la livraison de mon canapé. Vous proposez quels créneaux ?
[Homme] Mardi matin ou jeudi après-midi, madame Costa.
[Femme] Le matin, je travaille à l''hôpital. Jeudi, je suis en télétravail : c''est parfait.
[Homme] C''est noté, jeudi entre quatorze et dix-sept heures.

Quand le canapé sera-t-il livré ?

A. Jeudi après-midi.
B. Mardi matin.
C. Jeudi matin.
D. Mardi après-midi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, j''appelle pour la livraison de mon canapé. Vous proposez quels créneaux ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mardi matin ou jeudi après-midi, madame Costa.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le matin, je travaille à l''hôpital. Jeudi, je suis en télétravail : c''est parfait.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est noté, jeudi entre quatorze et dix-sept heures.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand le canapé sera-t-il livré ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jeudi après-midi.<break time="700ms"/>B.<break time="300ms"/>Mardi matin.<break time="700ms"/>C.<break time="300ms"/>Jeudi matin.<break time="700ms"/>D.<break time="300ms"/>Mardi après-midi.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « quand ? » appelle **un moment** : il faut relier la contrainte de la cliente (« le matin, je travaille à l''hôpital »), son accord (« jeudi… c''est parfait ») et la confirmation « jeudi entre quatorze et dix-sept heures » — A est correct par **inférence simple** contrainte + confirmation. B est le créneau **proposé puis écarté** à cause du travail du matin. C et D **recombinent** un jour et un moment réellement entendus (jeudi, mardi, matin, après-midi) en créneaux jamais proposés — piège de recombinaison classique quand on note les mots isolément sans relier jour et moment.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, ma commande est bloquée à l''étape « en transit » depuis douze jours. C''est une lampe de bureau.
[Homme] Je vérifie. En effet, madame Wei, le colis est considéré comme perdu. Et ce modèle n''est plus en stock, je ne peux donc pas vous le réexpédier.
[Femme] Alors remboursez-moi, s''il vous plaît.

Pourquoi la cliente ne peut-elle pas recevoir une nouvelle lampe ?

A. Parce que son adresse est incomplète.
B. Parce que le modèle n''est plus en stock.
C. Parce qu''elle a refusé la livraison.
D. Parce que le transporteur est en grève.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, ma commande est bloquée à l''étape en transit depuis douze jours. C''est une lampe de bureau.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je vérifie. En effet, madame Wei, le colis est considéré comme perdu. Et ce modèle n''est plus en stock, je ne peux donc pas vous le réexpédier.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors remboursez-moi, s''il vous plaît.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente ne peut-elle pas recevoir une nouvelle lampe ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que son adresse est incomplète.<break time="700ms"/>B.<break time="300ms"/>Parce que le modèle n''est plus en stock.<break time="700ms"/>C.<break time="300ms"/>Parce qu''elle a refusé la livraison.<break time="700ms"/>D.<break time="300ms"/>Parce que le transporteur est en grève.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, énoncée par le conseiller avec le connecteur logique « donc » : « ce modèle n''est plus en stock, je ne peux **donc** pas vous le réexpédier » — B est correct. Mécanisme B1 : repérer le lien cause → conséquence marqué par « donc ». A et D sont des causes **plausibles de colis perdu** (mauvaise adresse, grève) mais jamais citées dans le dialogue — distracteurs purement thématiques. C contredit la situation : la cliente attend toujours son colis et réclame, elle n''a rien refusé. Le remboursement final découle de cette rupture de stock.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je voudrais renvoyer ces baskets, elles sont trop petites. Il faut imprimer une étiquette de retour ?
[Homme] C''est une possibilité. Sinon, nous vous envoyons un code à présenter au bureau de poste : ils impriment l''étiquette pour vous.
[Femme] Je n''ai pas d''imprimante, je préfère le code.

Comment la cliente va-t-elle renvoyer ses baskets ?

A. En imprimant l''étiquette chez elle.
B. En demandant au livreur de reprendre le colis.
C. En rapportant les baskets au magasin.
D. Avec un code présenté au bureau de poste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je voudrais renvoyer ces baskets, elles sont trop petites. Il faut imprimer une étiquette de retour ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est une possibilité. Sinon, nous vous envoyons un code à présenter au bureau de poste : ils impriment l''étiquette pour vous.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je n''ai pas d''imprimante, je préfère le code.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle renvoyer ses baskets ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En imprimant l''étiquette chez elle.<break time="700ms"/>B.<break time="300ms"/>En demandant au livreur de reprendre le colis.<break time="700ms"/>C.<break time="300ms"/>En rapportant les baskets au magasin.<break time="700ms"/>D.<break time="300ms"/>Avec un code présenté au bureau de poste.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : il faut relier « je n''ai pas d''imprimante » et « je préfère le code » à la description du conseiller (« un code à présenter au bureau de poste ») pour conclure que D est correct. A est l''option **écartée par la contrainte matérielle** : sans imprimante, impossible d''imprimer l''étiquette chez soi — piège de la première solution évoquée. B et C sont deux modes de retour **plausibles dans le contexte du colis** (reprise par le livreur, dépôt en magasin) mais jamais proposés dans le dialogue : ce sont des distracteurs thématiques.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour madame Fernandes, j''ai votre colis, mais il reste neuf euros de frais de douane à régler à la réception.
[Femme] Je peux vous les donner en espèces ?
[Homme] Non, nous acceptons seulement la carte bancaire, ou le paiement en ligne avec le lien que je vous envoie.
[Femme] Mon téléphone est déchargé. Je vais chercher ma carte, alors.

Comment la cliente va-t-elle payer les frais de douane ?

A. En espèces.
B. Par paiement en ligne.
C. Par carte bancaire.
D. Par chèque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour madame Fernandes, j''ai votre colis, mais il reste neuf euros de frais de douane à régler à la réception.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je peux vous les donner en espèces ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, nous acceptons seulement la carte bancaire, ou le paiement en ligne avec le lien que je vous envoie.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mon téléphone est déchargé. Je vais chercher ma carte, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle payer les frais de douane ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En espèces.<break time="700ms"/>B.<break time="300ms"/>Par paiement en ligne.<break time="700ms"/>C.<break time="300ms"/>Par carte bancaire.<break time="700ms"/>D.<break time="300ms"/>Par chèque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par double élimination** : les espèces sont refusées, il reste carte ou paiement en ligne ; le téléphone déchargé élimine le lien en ligne, et la cliente conclut « je vais chercher ma carte » — C est correct. A est le moyen **proposé puis refusé** par le livreur, piège de la première mention. B est la deuxième option offerte, mais elle est rendue impossible par le téléphone déchargé : il faut relier ces deux informations (mécanisme B1 d''**inférence simple**). D n''est jamais évoqué dans le dialogue — distracteur thématique plausible mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Le facteur passe à quelle heure dans le quartier, d''habitude ?

A. Vers onze heures, en général.
B. Devant la boulangerie, souvent.
C. À vélo, la plupart du temps.
D. Pour déposer les lettres recommandées.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le facteur passe à quelle heure dans le quartier, d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers onze heures, en général.<break time="700ms"/>B.<break time="300ms"/>Devant la boulangerie, souvent.<break time="700ms"/>C.<break time="300ms"/>À vélo, la plupart du temps.<break time="700ms"/>D.<break time="300ms"/>Pour déposer les lettres recommandées.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quelle heure ? » appelle **un moment de la journée** : seule A « vers onze heures, en général » situe le passage du facteur dans le temps. B donne **un lieu** et répondrait à « où passe-t-il ? ». C donne **un moyen de déplacement** et répondrait à « comment se déplace-t-il ? ». D, introduite par « pour », exprime **un but** et répondrait à « pourquoi passe-t-il ? ». Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent toutes crédibles dans le contexte de la distribution du courrier.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Votre colis pèse combien, monsieur ?

A. Des livres pour mon neveu.
B. Avant la fin de la semaine, j''espère.
C. Un peu plus de deux kilos.
D. Jusqu''en Argentine, par avion.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Votre colis pèse combien, monsieur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Des livres pour mon neveu.<break time="700ms"/>B.<break time="300ms"/>Avant la fin de la semaine, j''espère.<break time="700ms"/>C.<break time="300ms"/>Un peu plus de deux kilos.<break time="700ms"/>D.<break time="300ms"/>Jusqu''en Argentine, par avion.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pèse combien ? » demande **un poids** : seule C « un peu plus de deux kilos » donne une mesure. A indique **le contenu** du colis et répondrait à « que contient-il ? ». B indique **un délai souhaité** et répondrait à « quand doit-il arriver ? ». D indique **la destination et le mode d''acheminement** et répondrait à « où part-il et comment ? ». Mécanisme B1 : la **rection** du verbe « peser » avec « combien » impose une réponse chiffrée en unité de masse ; toutes les propositions parlent pourtant du même envoi, seule la nature de la question permet de trancher.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b00e-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi mon paquet est-il revenu chez l''expéditeur ?

A. Au centre de tri de Lyon.
B. Parce que l''adresse était incomplète.
C. Il y a une dizaine de jours.
D. En camionnette, comme d''habitude.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi mon paquet est-il revenu chez l''expéditeur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au centre de tri de Lyon.<break time="700ms"/>B.<break time="300ms"/>Parce que l''adresse était incomplète.<break time="700ms"/>C.<break time="300ms"/>Il y a une dizaine de jours.<break time="700ms"/>D.<break time="300ms"/>En camionnette, comme d''habitude.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause**, et seule B, introduite par « parce que », en exprime une : l''adresse incomplète explique le retour du paquet. A donne **un lieu** et répondrait à « où le paquet a-t-il été bloqué ? ». C donne **un moment** et répondrait à « quand est-il revenu ? ». D donne **un moyen de transport** et répondrait à « comment a-t-il été renvoyé ? ». Mécanisme B1 : faire correspondre le mot interrogatif « pourquoi » au connecteur causal « parce que » — distinction cause / lieu / moment / manière, les quatre réponses restant liées au même paquet.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b00e-1000-0000-000000000001 → 0a.
-- [x] Thème unique « livraison / colis », 10 situations toutes différentes :
--     colis contre signature déposé en point relais, aspirateur endommagé
--     (renvoi vs remboursement), choix express vs standard pour un anniversaire,
--     créneau de livraison d'un canapé, colis perdu + rupture de stock, retour
--     de baskets avec code au bureau de poste, frais de douane à la réception,
--     heure de passage du facteur, poids d'un colis au guichet, paquet revenu
--     à l'expéditeur.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~40-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=2 (items 4,8), B=3 (items 2,5,10),
--     C=3 (items 1,7,9), D=2 (items 3,6) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision/choix final (1,2,6), cause du choix (3),
--     créneau retenu (4), moyen de paiement par double élimination (7) ;
--     explicite + distracteurs proches (5,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, recombinaison, rection interrogative).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, thèmes interdits évités.
-- ============================================================================
