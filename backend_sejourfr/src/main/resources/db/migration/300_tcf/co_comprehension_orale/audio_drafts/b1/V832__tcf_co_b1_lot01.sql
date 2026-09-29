-- ============================================================================
-- V832 — TCF CO B1 — lot 01 (thème : location de logement)
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
  ('66666666-b001-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Alors, monsieur Diallo, vous avez visité les deux appartements. Celui de la rue des Lilas est moins cher.
[Homme] Oui, mais il est sombre. Je préfère celui avec le balcon, même à quarante euros de plus par mois.
[Femme] Très bien, je prépare le bail pour celui-là.

Quel appartement le client choisit-il ?

A. L''appartement le moins cher de la rue des Lilas.
B. L''appartement avec le balcon.
C. Aucun des deux appartements.
D. Un appartement qu''il doit encore visiter.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors, monsieur Diallo, vous avez visité les deux appartements. Celui de la rue des Lilas est moins cher.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, mais il est sombre. Je préfère celui avec le balcon, même à quarante euros de plus par mois.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, je prépare le bail pour celui-là.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel appartement le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''appartement le moins cher de la rue des Lilas.<break time="700ms"/>B.<break time="300ms"/>L''appartement avec le balcon.<break time="700ms"/>C.<break time="300ms"/>Aucun des deux appartements.<break time="700ms"/>D.<break time="300ms"/>Un appartement qu''il doit encore visiter.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier la préférence du client (« je préfère celui avec le balcon ») et la confirmation de l''agente (« je prépare le bail pour celui-là ») pour conclure que B est correct. A reprend l''appartement **mentionné puis écarté** — piège de la première information entendue ; il répondrait à « quel appartement est le moins cher ? ». C contredit la préparation du bail, preuve qu''une location est bien conclue. D contredit le dialogue : les deux visites ont déjà eu lieu, aucune autre n''est prévue.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour le dépôt de garantie, il nous faut huit cents euros à la signature, madame Kovalenko.
[Femme] Je peux vous régler en espèces ?
[Homme] Non, nous n''acceptons que le chèque ou le virement.
[Femme] Je n''ai pas de chéquier. Je ferai un virement ce soir, alors.

Comment la locataire va-t-elle payer le dépôt de garantie ?

A. En espèces.
B. Par chèque.
C. Par virement.
D. Par carte bancaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour le dépôt de garantie, il nous faut huit cents euros à la signature, madame Kovalenko.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je peux vous régler en espèces ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, nous n''acceptons que le chèque ou le virement.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je n''ai pas de chéquier. Je ferai un virement ce soir, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la locataire va-t-elle payer le dépôt de garantie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En espèces.<break time="700ms"/>B.<break time="300ms"/>Par chèque.<break time="700ms"/>C.<break time="300ms"/>Par virement.<break time="700ms"/>D.<break time="300ms"/>Par carte bancaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : les espèces sont refusées, il reste chèque ou virement ; comme la locataire n''a pas de chéquier, elle conclut « je ferai un virement ce soir ». C est donc correct. A est le moyen **proposé puis refusé** par l''agent — piège de la première mention. B est éliminé par « je n''ai pas de chéquier ». D n''est jamais évoqué dans le dialogue : c''est un distracteur thématique plausible mais hors document. Mécanisme B1 : relier le refus et la contrainte pour déduire le choix final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Benali, pour l''état des lieux de sortie, tout est correct, sauf ce trou dans le mur du salon.
[Homme] Je peux le reboucher moi-même avant samedi, si vous voulez.
[Femme] D''accord. Dans ce cas, je vous rendrai la caution en entier.

Que va faire le locataire ?

A. Réparer le mur lui-même.
B. Payer un peintre professionnel.
C. Laisser la propriétaire garder la caution.
D. Contester l''état des lieux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Benali, pour l''état des lieux de sortie, tout est correct, sauf ce trou dans le mur du salon.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je peux le reboucher moi-même avant samedi, si vous voulez.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord. Dans ce cas, je vous rendrai la caution en entier.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire le locataire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Réparer le mur lui-même.<break time="700ms"/>B.<break time="300ms"/>Payer un peintre professionnel.<break time="700ms"/>C.<break time="300ms"/>Laisser la propriétaire garder la caution.<break time="700ms"/>D.<break time="300ms"/>Contester l''état des lieux.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **la décision du locataire**. Il propose « je peux le reboucher moi-même avant samedi » et la propriétaire accepte (« d''accord ») : A est correct — **inférence simple** proposition + accord. B déforme la solution : aucun professionnel n''est évoqué, c''est le locataire qui répare. C est précisément le scénario **évité** grâce à la réparation, puisque la caution sera rendue en entier. D contredit le ton de l''échange : le locataire reconnaît le défaut au lieu de le contester.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bienvenue dans la colocation, Priya. Il reste deux chambres : la grande donne sur la rue, la petite sur la cour.
[Femme] Je travaille de nuit à l''hôpital, je dors le jour.
[Homme] Alors la rue, avec le bruit du marché, ce n''est pas l''idéal.
[Femme] Oui, je prends la petite, côté cour.

Pourquoi la jeune femme choisit-elle la chambre côté cour ?

A. Parce qu''elle est plus grande.
B. Parce qu''elle est plus calme pour dormir le jour.
C. Parce que le loyer est moins élevé.
D. Parce qu''elle a une belle vue sur le marché.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bienvenue dans la colocation, Priya. Il reste deux chambres : la grande donne sur la rue, la petite sur la cour.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je travaille de nuit à l''hôpital, je dors le jour.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors la rue, avec le bruit du marché, ce n''est pas l''idéal.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, je prends la petite, côté cour.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la jeune femme choisit-elle la chambre côté cour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''elle est plus grande.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle est plus calme pour dormir le jour.<break time="700ms"/>C.<break time="300ms"/>Parce que le loyer est moins élevé.<break time="700ms"/>D.<break time="300ms"/>Parce qu''elle a une belle vue sur le marché.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple cause → choix** : il faut relier « je travaille de nuit, je dors le jour » et « la rue, avec le bruit du marché, ce n''est pas l''idéal » pour comprendre que la chambre côté cour est choisie pour son **calme**. B est correct. A est contredit par le document : la chambre côté cour est la **petite**. C n''est pas mentionné : aucune différence de loyer entre les chambres n''est évoquée. D décrit l''autre chambre (côté rue, sur le marché) et transforme l''inconvénient sonore en agrément — piège d''inversion.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, c''est madame Sow, du troisième étage. J''appelle au sujet de mes charges : elles passent de soixante à quatre-vingts euros. Pourquoi ?
[Homme] Le prix du chauffage collectif a beaucoup augmenté cet hiver, madame.
[Femme] D''accord, donc ce n''est pas une erreur.

Pourquoi les charges de la locataire augmentent-elles ?

A. À cause du chauffage collectif.
B. Pour payer un nouveau gardien.
C. Parce que l''eau coûte plus cher.
D. À cause de travaux dans l''ascenseur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, c''est madame Sow, du troisième étage. J''appelle au sujet de mes charges : elles passent de soixante à quatre-vingts euros. Pourquoi ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le prix du chauffage collectif a beaucoup augmenté cet hiver, madame.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, donc ce n''est pas une erreur.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi les charges de la locataire augmentent-elles ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause du chauffage collectif.<break time="700ms"/>B.<break time="300ms"/>Pour payer un nouveau gardien.<break time="700ms"/>C.<break time="300ms"/>Parce que l''eau coûte plus cher.<break time="700ms"/>D.<break time="300ms"/>À cause de travaux dans l''ascenseur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, et le gestionnaire l''énonce explicitement : « le prix du chauffage collectif a beaucoup augmenté » — A est correct. B, C et D sont trois causes **plausibles d''augmentation de charges** dans un immeuble (gardien, eau, ascenseur), mais aucune n''est citée dans le dialogue : ce sont des distracteurs purement thématiques. B utilise en plus « pour » (**but**, pas cause), nuance grammaticale à repérer. Piège B1 : retenir la cause réellement donnée, pas une cause vraisemblable.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Le problème, c''est que j''arrive de Shanghai le mois prochain : je n''ai aucun meuble.
[Femme] Celui-ci est vide, en effet. Mais un studio meublé se libère dans trois semaines, au même prix.
[Homme] Alors je préfère attendre le studio, c''est plus simple pour moi.

Que décide finalement le client ?

A. Louer l''appartement vide tout de suite.
B. Acheter des meubles d''occasion.
C. Attendre le studio meublé.
D. Chercher dans une autre agence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le problème, c''est que j''arrive de Shanghai le mois prochain : je n''ai aucun meuble.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Celui-ci est vide, en effet. Mais un studio meublé se libère dans trois semaines, au même prix.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors je préfère attendre le studio, c''est plus simple pour moi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décide finalement le client ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Louer l''appartement vide tout de suite.<break time="700ms"/>B.<break time="300ms"/>Acheter des meubles d''occasion.<break time="700ms"/>C.<break time="300ms"/>Attendre le studio meublé.<break time="700ms"/>D.<break time="300ms"/>Chercher dans une autre agence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence de décision finale** : il faut relier le problème du client (« je n''ai aucun meuble »), la proposition de l''agente (un studio meublé libre dans trois semaines, au même prix) et sa conclusion « je préfère attendre le studio ». C est correct. A contredit ce refus implicite de l''appartement vide. B serait une autre solution au problème de meubles, mais elle n''est **jamais envisagée** dans le dialogue. D est contredit par le fait qu''il accepte une offre de cette même agence : il n''a aucune raison d''aller ailleurs.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je suis étudiante à Nantes et mes parents vivent à l''étranger : je n''ai pas de garant en France.
[Homme] Dans ce cas, vous pouvez payer une caution bancaire, ou demander la garantie de l''État, qui est gratuite.
[Femme] Gratuite ? Alors je vais faire la demande en ligne dès ce soir.

Quelle solution la future locataire choisit-elle ?

A. Demander à ses parents d''être garants.
B. Payer une caution bancaire.
C. Renoncer à la location.
D. Demander la garantie gratuite de l''État.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je suis étudiante à Nantes et mes parents vivent à l''étranger : je n''ai pas de garant en France.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans ce cas, vous pouvez payer une caution bancaire, ou demander la garantie de l''État, qui est gratuite.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Gratuite ? Alors je vais faire la demande en ligne dès ce soir.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle solution la future locataire choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Demander à ses parents d''être garants.<break time="700ms"/>B.<break time="300ms"/>Payer une caution bancaire.<break time="700ms"/>C.<break time="300ms"/>Renoncer à la location.<break time="700ms"/>D.<break time="300ms"/>Demander la garantie gratuite de l''État.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut relier **« la garantie de l''État, qui est gratuite »** et la réaction « gratuite ? alors je vais faire la demande en ligne dès ce soir » : **inférence simple** fondée sur le critère du prix, qui désigne D comme la solution retenue. A est impossible : ses parents vivent à l''étranger, c''est justement le problème posé au départ. B est l''option **écartée** parce qu''elle est payante, contrairement à la garantie choisie. C contredit la démarche active de l''étudiante, qui lance sa demande le soir même.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] L''état des lieux d''entrée, c''est quand exactement ?

A. Avec la gardienne de l''immeuble.
B. Dans l''appartement, bien sûr.
C. Pour vérifier l''état des murs.
D. Lundi prochain, à neuf heures.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''état des lieux d''entrée, c''est quand exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec la gardienne de l''immeuble.<break time="700ms"/>B.<break time="300ms"/>Dans l''appartement, bien sûr.<break time="700ms"/>C.<break time="300ms"/>Pour vérifier l''état des murs.<break time="700ms"/>D.<break time="300ms"/>Lundi prochain, à neuf heures.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « c''est quand exactement ? » porte sur **le moment précis** : seule D « lundi prochain, à neuf heures » situe l''état des lieux dans le temps. A répondrait à « avec qui se fait-il ? » (**accompagnant**). B répondrait à « où a-t-il lieu ? » (**lieu**). C, introduit par « pour », répondrait à « à quoi sert-il ? » (**but**). Mécanisme B1 : identifier le mot interrogatif et la nature de l''information attendue — les quatre réponses restent crédibles dans le contexte de la location.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Les charges de l''appartement s''élèvent à combien chaque mois ?

A. À soixante-quinze euros, eau comprise.
B. Tous les cinq du mois.
C. Par prélèvement automatique.
D. Parce que l''immeuble a un ascenseur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Les charges de l''appartement s''élèvent à combien chaque mois ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À soixante-quinze euros, eau comprise.<break time="700ms"/>B.<break time="300ms"/>Tous les cinq du mois.<break time="700ms"/>C.<break time="300ms"/>Par prélèvement automatique.<break time="700ms"/>D.<break time="300ms"/>Parce que l''immeuble a un ascenseur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« S''élèvent à combien ? » demande **un montant** : seule A donne une somme (« soixante-quinze euros, eau comprise »). B indique **un moment de paiement** et répondrait à « quand paie-t-on les charges ? ». C indique **le mode de paiement** et répondrait à « comment les paie-t-on ? ». D, introduit par « parce que », donne **une cause** et répondrait à « pourquoi y a-t-il des charges ? ». Piège B1 classique : toutes les réponses parlent des charges, seule la nature de la question — une quantité d''argent — permet de trancher.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b001-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous cherchez une colocation depuis combien de temps ?

A. Près de la gare, de préférence.
B. Avec deux autres étudiants.
C. Depuis trois mois, environ.
D. Pour réduire mes dépenses.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous cherchez une colocation depuis combien de temps ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près de la gare, de préférence.<break time="700ms"/>B.<break time="300ms"/>Avec deux autres étudiants.<break time="700ms"/>C.<break time="300ms"/>Depuis trois mois, environ.<break time="700ms"/>D.<break time="300ms"/>Pour réduire mes dépenses.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Depuis combien de temps ? » appelle **une durée écoulée**, marquée par « depuis » : seule C « depuis trois mois, environ » convient. A donne **un lieu recherché** et répondrait à « où cherchez-vous ? ». B donne **les futurs colocataires** et répondrait à « avec qui voulez-vous vivre ? ». D, introduit par « pour », donne **un but** et répondrait à « pourquoi choisir la colocation ? ». Mécanisme B1 : la **rection** de « depuis combien de temps » impose une réponse en durée, pas en lieu, en personne ni en but.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b001-1000-0000-000000000001 → 0a.
-- [x] Thème unique « location de logement », 10 situations toutes différentes :
--     choix entre 2 appartements, paiement du dépôt de garantie, état des lieux
--     de sortie, choix de chambre en colocation, hausse des charges, attente
--     d'un studio meublé, solution de garant, date d'état des lieux d'entrée,
--     montant des charges, durée de recherche de colocation.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 2-4 répliques,
--     ~35-60 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 3,5,9), B=2 (items 1,4),
--     C=3 (items 2,6,10), D=2 (items 7,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : décision finale (1,3,6), moyen de paiement (2),
--     choix retenu et sa cause (4,7) ; explicite + distracteurs proches (5,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, rection interrogative).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original.
-- ============================================================================
