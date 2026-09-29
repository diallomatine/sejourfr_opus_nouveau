-- ============================================================================
-- V835 — TCF CO B1 — lot 04 (thème : banque)
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
  ('66666666-b004-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Melnyk, pour votre nouveau compte, vous avez deux cartes possibles : la carte classique, gratuite, ou la carte internationale, à trois euros par mois.
[Femme] Je voyage très souvent en Pologne pour mon travail.
[Homme] Alors la carte internationale est plus intéressante : aucun frais à l''étranger.
[Femme] D''accord, je prends celle-là.

Quelle carte la cliente choisit-elle ?

A. La carte classique gratuite.
B. La carte internationale.
C. Aucune carte pour le moment.
D. Une carte d''une autre banque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Melnyk, pour votre nouveau compte, vous avez deux cartes possibles : la carte classique, gratuite, ou la carte internationale, à trois euros par mois.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je voyage très souvent en Pologne pour mon travail.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors la carte internationale est plus intéressante : aucun frais à l''étranger.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">D''accord, je prends celle-là.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle carte la cliente choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La carte classique gratuite.<break time="700ms"/>B.<break time="300ms"/>La carte internationale.<break time="700ms"/>C.<break time="300ms"/>Aucune carte pour le moment.<break time="700ms"/>D.<break time="300ms"/>Une carte d''une autre banque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : il faut relier le besoin de la cliente (« je voyage très souvent en Pologne »), le conseil du banquier (« la carte internationale est plus intéressante : aucun frais à l''étranger ») et l''accord final « je prends celle-là » — le pronom **celle-là** renvoie à la dernière carte citée, l''internationale : B est correct. A est l''option **mentionnée en premier puis écartée** malgré sa gratuité — piège du prix. C contredit « je prends celle-là », qui marque une décision d''achat. D n''est jamais évoquée : tout le dialogue se passe dans la même banque.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Traoré, votre carte volée est maintenant annulée. La nouvelle peut être envoyée chez vous sous huit jours, ou retirée ici, en agence, dès mercredi.
[Homme] Je déménage la semaine prochaine, c''est compliqué pour le courrier. Je viendrai la chercher.
[Femme] Très bien, elle vous attendra à l''accueil mercredi matin.

Comment le client va-t-il récupérer sa nouvelle carte ?

A. Par courrier, à son adresse actuelle.
B. Par courrier, à sa nouvelle adresse.
C. Dans une autre agence de la banque.
D. En venant la chercher à l''agence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Traoré, votre carte volée est maintenant annulée. La nouvelle peut être envoyée chez vous sous huit jours, ou retirée ici, en agence, dès mercredi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je déménage la semaine prochaine, c''est compliqué pour le courrier. Je viendrai la chercher.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Très bien, elle vous attendra à l''accueil mercredi matin.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client va-t-il récupérer sa nouvelle carte ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par courrier, à son adresse actuelle.<break time="700ms"/>B.<break time="300ms"/>Par courrier, à sa nouvelle adresse.<break time="700ms"/>C.<break time="300ms"/>Dans une autre agence de la banque.<break time="700ms"/>D.<break time="300ms"/>En venant la chercher à l''agence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : il faut relier le déménagement (« c''est compliqué pour le courrier ») et la décision « je viendrai la chercher », confirmée par « elle vous attendra à l''accueil mercredi matin » — D est correct. A est l''option d''envoi postal **proposée puis écartée** à cause du déménagement — piège de la première mention. B n''est jamais proposée : aucun envoi à la nouvelle adresse n''est évoqué. C déforme le lieu : la conseillère dit « ici, en agence », c''est donc la même agence, pas une autre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour mon prêt auto de dix mille euros, qu''est-ce que vous me proposez, madame ?
[Femme] Sur quatre ans, la mensualité est de deux cent vingt euros ; sur cinq ans, elle descend à cent quatre-vingts euros.
[Homme] Mon loyer est déjà élevé... Je préfère la mensualité la plus basse.
[Femme] Alors je prépare le dossier sur cinq ans, monsieur Vargas.

Quelle durée de remboursement le client choisit-il ?

A. Cinq ans.
B. Quatre ans.
C. Il hésite encore entre les deux durées.
D. Il renonce finalement au prêt.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour mon prêt auto de dix mille euros, qu''est-ce que vous me proposez, madame ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Sur quatre ans, la mensualité est de deux cent vingt euros ; sur cinq ans, elle descend à cent quatre-vingts euros.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mon loyer est déjà élevé... Je préfère la mensualité la plus basse.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors je prépare le dossier sur cinq ans, monsieur Vargas.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle durée de remboursement le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Cinq ans.<break time="700ms"/>B.<break time="300ms"/>Quatre ans.<break time="700ms"/>C.<break time="300ms"/>Il hésite encore entre les deux durées.<break time="700ms"/>D.<break time="300ms"/>Il renonce finalement au prêt.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple par mise en relation de deux chiffres** : « la mensualité la plus basse » est cent quatre-vingts euros, qui correspond à la durée de **cinq ans** ; la conseillère confirme « je prépare le dossier sur cinq ans » — A est correct. B correspond à la mensualité la plus élevée (deux cent vingt euros), exactement l''inverse du critère du client — piège d''inversion. C est contredit par la confirmation du dossier : la décision est prise. D contredit aussi la préparation du dossier, preuve que le prêt est bien accepté.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je voudrais envoyer deux cents euros à ma sœur, à Dakar.
[Homme] Au guichet, le virement international coûte douze euros de frais. Sur notre application, il est gratuit, madame Ndiaye.
[Femme] Je ne savais pas ! Je vais le faire sur l''application, alors.

Comment la cliente va-t-elle envoyer l''argent ?

A. Au guichet de l''agence.
B. Par mandat postal.
C. Par virement depuis l''application.
D. En espèces, par une amie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je voudrais envoyer deux cents euros à ma sœur, à Dakar.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au guichet, le virement international coûte douze euros de frais. Sur notre application, il est gratuit, madame Ndiaye.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je ne savais pas ! Je vais le faire sur l''application, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle envoyer l''argent ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet de l''agence.<break time="700ms"/>B.<break time="300ms"/>Par mandat postal.<break time="700ms"/>C.<break time="300ms"/>Par virement depuis l''application.<break time="700ms"/>D.<break time="300ms"/>En espèces, par une amie.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen d''envoi final déduit par inférence simple** : il faut relier la comparaison des frais (douze euros au guichet contre gratuit sur l''application) et la conclusion « je vais le faire sur l''application, alors » — C est correct ; le connecteur **alors** marque la décision tirée de l''information sur la gratuité. A est l''option **écartée à cause des frais** — piège de la première solution citée. B et D sont des moyens d''envoyer de l''argent plausibles dans le contexte, mais ils ne sont **jamais mentionnés** dans le dialogue : distracteurs purement thématiques.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Wei, pour placer vos trois mille euros, deux solutions : le livret, disponible à tout moment, ou le compte à terme, mieux rémunéré mais bloqué pendant deux ans.
[Femme] J''aurai peut-être des travaux dans mon salon de coiffure cette année.
[Homme] Alors mieux vaut garder votre argent disponible.
[Femme] Oui, je choisis le livret.

Pourquoi la cliente choisit-elle le livret ?

A. Parce qu''il rapporte plus que le compte à terme.
B. Parce qu''elle pourra retirer son argent à tout moment.
C. Parce que le compte à terme est réservé aux entreprises.
D. Parce que sa banque ne propose aucun autre placement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Wei, pour placer vos trois mille euros, deux solutions : le livret, disponible à tout moment, ou le compte à terme, mieux rémunéré mais bloqué pendant deux ans.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">J''aurai peut-être des travaux dans mon salon de coiffure cette année.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors mieux vaut garder votre argent disponible.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, je choisis le livret.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi la cliente choisit-elle le livret ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce qu''il rapporte plus que le compte à terme.<break time="700ms"/>B.<break time="300ms"/>Parce qu''elle pourra retirer son argent à tout moment.<break time="700ms"/>C.<break time="300ms"/>Parce que le compte à terme est réservé aux entreprises.<break time="700ms"/>D.<break time="300ms"/>Parce que sa banque ne propose aucun autre placement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple cause → choix** : il faut relier les travaux possibles dans le salon de coiffure et le conseil « mieux vaut garder votre argent disponible » pour comprendre que le livret est choisi pour sa **disponibilité** — B est correct. A inverse les caractéristiques annoncées : c''est le compte à terme qui est « mieux rémunéré », pas le livret — piège d''inversion des attributs. C invente une restriction jamais énoncée : le compte à terme est bloqué deux ans, pas réservé aux entreprises. D contredit le dialogue, qui présente justement **deux** solutions de placement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, j''ai un problème : la cotisation de ma carte, vingt-cinq euros, a été prélevée deux fois ce mois-ci.
[Femme] Vous avez raison, monsieur Bensaïd, je le vois sur votre compte. C''est une erreur informatique : je vous rembourse le second prélèvement aujourd''hui même.
[Homme] Merci beaucoup, je vérifierai demain.

Que va faire la conseillère ?

A. Rembourser la somme prélevée en trop.
B. Commander une nouvelle carte bancaire.
C. Offrir la cotisation de l''année prochaine.
D. Vérifier le compte du client demain.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, j''ai un problème : la cotisation de ma carte, vingt-cinq euros, a été prélevée deux fois ce mois-ci.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous avez raison, monsieur Bensaïd, je le vois sur votre compte. C''est une erreur informatique : je vous rembourse le second prélèvement aujourd''hui même.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Merci beaucoup, je vérifierai demain.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire la conseillère ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Rembourser la somme prélevée en trop.<break time="700ms"/>B.<break time="300ms"/>Commander une nouvelle carte bancaire.<break time="700ms"/>C.<break time="300ms"/>Offrir la cotisation de l''année prochaine.<break time="700ms"/>D.<break time="300ms"/>Vérifier le compte du client demain.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **l''action de la conseillère** : elle annonce explicitement « je vous rembourse le second prélèvement aujourd''hui même » — A est correct. B est un geste bancaire plausible après un problème de carte, mais le problème ici est un **double prélèvement**, pas une carte défectueuse : rien n''est dit sur une nouvelle carte. C est un geste commercial jamais proposé dans le dialogue. D est le **piège d''attribution** : c''est le client qui dit « je vérifierai demain », pas la conseillère — il faut bien identifier qui fait quoi dans l''échange.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Pour activer votre application bancaire, monsieur Almeida, nous vous envoyons un code, par SMS ou par courrier, au choix.
[Homme] Je change de numéro de téléphone vendredi prochain.
[Femme] Dans ce cas, le courrier est plus sûr : vous recevrez le code sous cinq jours.
[Homme] Parfait, faisons comme ça.

Comment le client va-t-il recevoir son code d''activation ?

A. Par SMS, sur son nouveau numéro.
B. Par e-mail sécurisé.
C. Par courrier, à son domicile.
D. Au guichet, immédiatement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pour activer votre application bancaire, monsieur Almeida, nous vous envoyons un code, par SMS ou par courrier, au choix.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je change de numéro de téléphone vendredi prochain.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Dans ce cas, le courrier est plus sûr : vous recevrez le code sous cinq jours.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Parfait, faisons comme ça.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client va-t-il recevoir son code d''activation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par SMS, sur son nouveau numéro.<break time="700ms"/>B.<break time="300ms"/>Par e-mail sécurisé.<break time="700ms"/>C.<break time="300ms"/>Par courrier, à son domicile.<break time="700ms"/>D.<break time="300ms"/>Au guichet, immédiatement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → solution** : il faut relier le changement de numéro de téléphone et la recommandation « dans ce cas, le courrier est plus sûr », validée par « parfait, faisons comme ça » — C est correct ; **faisons comme ça** renvoie à la dernière solution proposée. A est l''option **rendue peu fiable** par le changement de numéro, donc écartée — piège de la première mention. B n''est jamais proposé : seuls le SMS et le courrier sont au choix. D contredit le délai annoncé (« sous cinq jours ») : aucune remise immédiate au guichet n''est évoquée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Votre rendez-vous avec la conseillère bancaire, c''est à quelle heure ?

A. Au sujet d''un crédit immobilier.
B. À l''agence du centre-ville.
C. Avec madame Morel, je crois.
D. À quatorze heures trente, précisément.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Votre rendez-vous avec la conseillère bancaire, c''est à quelle heure ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au sujet d''un crédit immobilier.<break time="700ms"/>B.<break time="300ms"/>À l''agence du centre-ville.<break time="700ms"/>C.<break time="300ms"/>Avec madame Morel, je crois.<break time="700ms"/>D.<break time="300ms"/>À quatorze heures trente, précisément.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« C''est à quelle heure ? » demande **un horaire** : seule D « à quatorze heures trente, précisément » situe le rendez-vous dans la journée. A donne **l''objet** du rendez-vous et répondrait à « c''est à quel sujet ? ». B donne **le lieu** et répondrait à « où a-t-il lieu ? ». C donne **la personne** et répondrait à « avec qui avez-vous rendez-vous ? ». Mécanisme B1 : identifier la nature de l''information attendue par le mot interrogatif — les quatre réponses commencent par « à » ou « avec » et restent crédibles dans le contexte bancaire, seul le sens tranche.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Vous souhaitez retirer combien, aujourd''hui ?

A. Trois cents euros, s''il vous plaît.
B. Avant la fermeture de l''agence.
C. Au distributeur, à l''extérieur.
D. Pour payer le loyer de mon studio.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous souhaitez retirer combien, aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois cents euros, s''il vous plaît.<break time="700ms"/>B.<break time="300ms"/>Avant la fermeture de l''agence.<break time="700ms"/>C.<break time="300ms"/>Au distributeur, à l''extérieur.<break time="700ms"/>D.<break time="300ms"/>Pour payer le loyer de mon studio.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Retirer combien ? » appelle **un montant d''argent** : seule A « trois cents euros » donne une somme. B indique **un moment limite** et répondrait à « quand voulez-vous retirer ? ». C indique **le lieu du retrait** et répondrait à « où allez-vous retirer ? ». D, introduit par « pour », exprime **un but** et répondrait à « pourquoi retirez-vous cet argent ? » — distinction but/cause typique du B1. Piège classique : toutes les réponses parlent d''un retrait d''argent, seule la nature de l''information demandée — une quantité — permet de trancher.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b004-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi voulez-vous fermer votre compte courant ?

A. Dès la fin du mois, si possible.
B. À l''agence où je l''ai ouvert.
C. Parce que je pars vivre au Canada.
D. En remplissant un simple formulaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi voulez-vous fermer votre compte courant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dès la fin du mois, si possible.<break time="700ms"/>B.<break time="300ms"/>À l''agence où je l''ai ouvert.<break time="700ms"/>C.<break time="300ms"/>Parce que je pars vivre au Canada.<break time="700ms"/>D.<break time="300ms"/>En remplissant un simple formulaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause** : seule C, introduite par « parce que », explique la fermeture du compte (« je pars vivre au Canada »). A donne **un moment** et répondrait à « quand voulez-vous le fermer ? ». B donne **un lieu** et répondrait à « où peut-on le fermer ? ». D, au **gérondif de moyen** (« en remplissant »), répondrait à « comment ferme-t-on un compte ? ». Mécanisme B1 : repérer le marqueur de cause « parce que » face aux marqueurs de temps, de lieu et de manière — les quatre réponses restent crédibles dans une conversation de clôture de compte.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b004-1000-0000-000000000001 → 0a.
-- [x] Thème unique « banque », 10 situations toutes différentes :
--     choix d'une carte bancaire à l'ouverture de compte, récupération d'une
--     carte après vol, durée de remboursement d'un prêt auto, envoi d'argent
--     à l'étranger (guichet vs application), choix d'un placement (livret vs
--     compte à terme), double prélèvement remboursé, réception du code
--     d'activation de l'application, heure d'un rendez-vous conseiller,
--     montant d'un retrait, motif de clôture de compte.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 2-4 répliques,
--     ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 3,6,9), B=2 (items 1,5),
--     C=3 (items 4,7,10), D=2 (items 2,8) — 4 positions utilisées, max 3.
-- [x] Inférence simple B1 : choix final via pronom/anaphore (1,7), contrainte
--     → décision (2,5), mise en relation de deux chiffres (3), gratuité →
--     moyen d'envoi (4) ; explicite + distracteurs proches (6,8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, anaphore, piège d'attribution, but vs cause,
--     gérondif de moyen, rection interrogative).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original, prénoms/villes variés
--     (Melnyk, Traoré, Vargas, Ndiaye, Wei, Bensaïd, Almeida, Morel ; Pologne,
--     Dakar, Canada).
-- ============================================================================
