-- ============================================================================
-- V836 — TCF CO B1 — lot 05 (thème : administration / mairie)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- 7 items format C (dialogue de service + question, co_document_question)
-- + 3 items format B (question + 4 réponses, co_question_reponse).
-- Compréhension explicite + inférence simple (décision finale, moyen retenu,
-- date choisie). Contenu 100 % original, déterministe, rejouable.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-b005-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Monsieur Haddad, votre dossier de carte d''identité est presque complet, mais il manque un justificatif de domicile de moins d''un an.
[Homme] Je peux vous l''envoyer par courriel cet après-midi ?
[Femme] Non, il nous faut l''original, ici, au guichet.
[Homme] D''accord, je repasse demain matin avec ma facture d''électricité.

Que va faire le client ?

A. Envoyer le justificatif par courriel.
B. Refaire entièrement son dossier.
C. Revenir le lendemain avec le document.
D. Déposer sa demande dans une autre mairie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Monsieur Haddad, votre dossier de carte d''identité est presque complet, mais il manque un justificatif de domicile de moins d''un an.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je peux vous l''envoyer par courriel cet après-midi ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Non, il nous faut l''original, ici, au guichet.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, je repasse demain matin avec ma facture d''électricité.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire le client ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Envoyer le justificatif par courriel.<break time="700ms"/>B.<break time="300ms"/>Refaire entièrement son dossier.<break time="700ms"/>C.<break time="300ms"/>Revenir le lendemain avec le document.<break time="700ms"/>D.<break time="300ms"/>Déposer sa demande dans une autre mairie.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple proposition refusée → solution de repli** : le courriel est écarté (« il nous faut l''original, ici, au guichet »), et le client conclut « je repasse demain matin avec ma facture d''électricité » — C est correct. A est le moyen **proposé puis refusé** par l''agente, piège de la première solution entendue. B exagère le problème : seul un justificatif manque, le dossier est « presque complet », rien n''est à refaire. D n''est jamais évoqué : le client revient au même guichet, pas dans une autre mairie.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour votre passeport, il faut un timbre fiscal de quatre-vingt-six euros, madame Wei. Nous ne le vendons pas ici.
[Femme] Et je peux l''acheter où ?
[Homme] Sur internet, ou dans un bureau de tabac.
[Femme] Mon téléphone est cassé en ce moment... j''irai au tabac d''à côté, alors.

Où la cliente va-t-elle acheter le timbre fiscal ?

A. Au guichet de la mairie.
B. Dans un bureau de tabac.
C. Sur internet.
D. À la préfecture.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour votre passeport, il faut un timbre fiscal de quatre-vingt-six euros, madame Wei. Nous ne le vendons pas ici.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Et je peux l''acheter où ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sur internet, ou dans un bureau de tabac.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Mon téléphone est cassé en ce moment... j''irai au tabac d''à côté, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Où la cliente va-t-elle acheter le timbre fiscal ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet de la mairie.<break time="700ms"/>B.<break time="300ms"/>Dans un bureau de tabac.<break time="700ms"/>C.<break time="300ms"/>Sur internet.<break time="700ms"/>D.<break time="300ms"/>À la préfecture.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix retenu** : deux options sont proposées (internet ou bureau de tabac) ; comme le téléphone de la cliente est cassé, elle élimine internet et conclut « j''irai au tabac d''à côté » — B est correct. A est explicitement exclu dès la première réplique : « nous ne le vendons pas ici ». C est l''option **écartée à cause de la contrainte** matérielle, piège pour qui ne relie pas les deux informations. D n''apparaît jamais dans le dialogue : distracteur thématique plausible (lieu administratif) mais hors document.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, il me faut une copie de mon acte de naissance : je dois compléter un dossier samedi.
[Homme] Par courrier, comptez une semaine, madame Fernandez. Mais vous pouvez le retirer ici dès jeudi.
[Femme] Jeudi, c''est parfait, je viendrai le chercher.

Comment la cliente va-t-elle obtenir son acte de naissance ?

A. En venant le chercher au guichet jeudi.
B. En le recevant par courrier sous une semaine.
C. En le téléchargeant samedi sur internet.
D. En le demandant à la préfecture.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, il me faut une copie de mon acte de naissance : je dois compléter un dossier samedi.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Par courrier, comptez une semaine, madame Fernandez. Mais vous pouvez le retirer ici dès jeudi.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Jeudi, c''est parfait, je viendrai le chercher.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle obtenir son acte de naissance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En venant le chercher au guichet jeudi.<break time="700ms"/>B.<break time="300ms"/>En le recevant par courrier sous une semaine.<break time="700ms"/>C.<break time="300ms"/>En le téléchargeant samedi sur internet.<break time="700ms"/>D.<break time="300ms"/>En le demandant à la préfecture.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple délai → option compatible** : la cliente a besoin du document avant samedi ; le courrier prend une semaine (trop long), tandis que le retrait au guichet est possible « dès jeudi ». Sa réplique « jeudi, c''est parfait, je viendrai le chercher » confirme A. B est l''option **trop lente, donc écartée** — piège pour qui retient la première modalité citée. C invente un canal jamais proposé dans le dialogue, et samedi est la date limite du dossier, pas un jour de démarche. D confond les administrations : tout se passe à la mairie, la préfecture n''est pas mentionnée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, notre association de quartier voudrait réserver la salle des fêtes pour le samedi quinze mars.
[Femme] Le samedi quinze, elle est déjà prise, monsieur Morales. Le dimanche seize est libre, et le tarif est réduit pour les associations.
[Homme] Va pour le dimanche, alors.

Quelle date l''association retient-elle ?

A. Le samedi quinze mars.
B. Un samedi du mois suivant.
C. Elle renonce à la réservation.
D. Le dimanche seize mars.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, notre association de quartier voudrait réserver la salle des fêtes pour le samedi quinze mars.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le samedi quinze, elle est déjà prise, monsieur Morales. Le dimanche seize est libre, et le tarif est réduit pour les associations.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Va pour le dimanche, alors.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle date l''association retient-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le samedi quinze mars.<break time="700ms"/>B.<break time="300ms"/>Un samedi du mois suivant.<break time="700ms"/>C.<break time="300ms"/>Elle renonce à la réservation.<break time="700ms"/>D.<break time="300ms"/>Le dimanche seize mars.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple indisponibilité → date de repli acceptée** : le samedi quinze est pris, l''agente propose le dimanche seize, et la formule d''acceptation « va pour le dimanche » désigne D comme la date retenue. A est la date **demandée au départ mais indisponible** — piège classique de la première information entendue. B invente un report au mois suivant que personne ne propose : le repli se fait au lendemain, pas plus tard. C contredit l''accord final : la réservation est bien conclue, simplement décalée d''un jour.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je viens recenser mon fils : il a eu seize ans la semaine dernière.
[Homme] C''est lui qui doit faire la démarche, madame Bondarenko, avec sa carte d''identité et le livret de famille.
[Femme] Il finit les cours à seize heures... nous reviendrons ensemble mercredi après-midi.

Que va faire la mère ?

A. Recenser son fils elle-même aujourd''hui.
B. Revenir à la mairie avec son fils mercredi.
C. Envoyer le livret de famille par la poste.
D. Attendre les dix-huit ans de son fils.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je viens recenser mon fils : il a eu seize ans la semaine dernière.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est lui qui doit faire la démarche, madame Bondarenko, avec sa carte d''identité et le livret de famille.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Il finit les cours à seize heures... nous reviendrons ensemble mercredi après-midi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que va faire la mère ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Recenser son fils elle-même aujourd''hui.<break time="700ms"/>B.<break time="300ms"/>Revenir à la mairie avec son fils mercredi.<break time="700ms"/>C.<break time="300ms"/>Envoyer le livret de famille par la poste.<break time="700ms"/>D.<break time="300ms"/>Attendre les dix-huit ans de son fils.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple règle énoncée → nouvelle organisation** : l''agent pose la condition (« c''est lui qui doit faire la démarche ») et la mère s''y adapte : « nous reviendrons ensemble mercredi après-midi » — B est correct. A est précisément ce que la règle **interdit** : la mère ne peut pas recenser son fils à sa place, c''était pourtant son intention initiale. C invente un envoi postal jamais évoqué ; le livret de famille doit être présenté au guichet. D confond les âges : le recensement citoyen se fait à seize ans, pas à la majorité.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour un mariage le trois juillet, c''est trop juste : les bans doivent être publiés au moins dix jours avant, et votre dossier n''est pas encore complet.
[Femme] Si nous déposons toutes les pièces la semaine prochaine, quelle date est possible ?
[Homme] À partir du vingt-six juillet.
[Femme] Alors nous prendrons le dernier samedi de juillet.

Que décident les futurs mariés ?

A. Maintenir le mariage au trois juillet.
B. Se marier dans une autre commune.
C. Renoncer à la publication des bans.
D. Reporter la cérémonie à la fin du mois de juillet.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour un mariage le trois juillet, c''est trop juste : les bans doivent être publiés au moins dix jours avant, et votre dossier n''est pas encore complet.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Si nous déposons toutes les pièces la semaine prochaine, quelle date est possible ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À partir du vingt-six juillet.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors nous prendrons le dernier samedi de juillet.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que décident les futurs mariés ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Maintenir le mariage au trois juillet.<break time="700ms"/>B.<break time="300ms"/>Se marier dans une autre commune.<break time="700ms"/>C.<break time="300ms"/>Renoncer à la publication des bans.<break time="700ms"/>D.<break time="300ms"/>Reporter la cérémonie à la fin du mois de juillet.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte de délai → décision finale** : il faut relier la règle (« les bans doivent être publiés au moins dix jours avant »), la date possible donnée par l''agent (« à partir du vingt-six juillet ») et la conclusion « nous prendrons le dernier samedi de juillet » pour choisir D. A est la date **initiale, déclarée impossible** dès la première réplique — piège de l''information de départ. B n''est jamais envisagé : le couple reste dans la même mairie et y dépose son dossier. C est absurde juridiquement et contredit le dialogue : les bans seront publiés, c''est la date qui change.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, je n''ai pas reçu ma carte électorale. Pourtant, je n''ai déménagé que de deux rues, en janvier.
[Homme] Justement, il faut déclarer votre nouvelle adresse, madame Ndiaye : au guichet, ou en ligne sur le site de la commune.
[Femme] Je le ferai sur le site ce soir, c''est plus rapide.

Comment la dame va-t-elle déclarer sa nouvelle adresse ?

A. Sur le site internet de la commune.
B. Au guichet de la mairie.
C. Par téléphone.
D. Par courrier postal.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, je n''ai pas reçu ma carte électorale. Pourtant, je n''ai déménagé que de deux rues, en janvier.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, il faut déclarer votre nouvelle adresse, madame Ndiaye : au guichet, ou en ligne sur le site de la commune.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je le ferai sur le site ce soir, c''est plus rapide.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la dame va-t-elle déclarer sa nouvelle adresse ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur le site internet de la commune.<break time="700ms"/>B.<break time="300ms"/>Au guichet de la mairie.<break time="700ms"/>C.<break time="300ms"/>Par téléphone.<break time="700ms"/>D.<break time="300ms"/>Par courrier postal.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple deux options → choix motivé** : l''agent propose le guichet ou le site de la commune ; la dame tranche avec « je le ferai sur le site ce soir, c''est plus rapide » — A est correct, le critère de rapidité justifiant le choix. B est l''option **proposée mais non retenue** : piège pour qui s''arrête à la liste des possibilités sans écouter la décision. C et D ne figurent pas dans le dialogue : ce sont des canaux administratifs vraisemblables (téléphone, courrier) mais jamais mentionnés — distracteurs purement thématiques.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Le service de l''état civil ouvre à quelle heure le samedi ?

A. Au premier étage de la mairie.
B. Pour retirer un acte de mariage.
C. À neuf heures, jusqu''à midi.
D. Auprès de l''agent d''accueil.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le service de l''état civil ouvre à quelle heure le samedi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au premier étage de la mairie.<break time="700ms"/>B.<break time="300ms"/>Pour retirer un acte de mariage.<break time="700ms"/>C.<break time="300ms"/>À neuf heures, jusqu''à midi.<break time="700ms"/>D.<break time="300ms"/>Auprès de l''agent d''accueil.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Ouvre à quelle heure ? » demande **un horaire** : seule C « à neuf heures, jusqu''à midi » situe l''ouverture dans le temps. A donne **un lieu** et répondrait à « où se trouve le service ? ». B, introduit par « pour », exprime **un but** et répondrait à « pourquoi venir à l''état civil ? ». D désigne **une personne** et répondrait à « à qui faut-il s''adresser ? ». Mécanisme B1 : identifier la nature de l''information attendue par le mot interrogatif — les quatre réponses restent crédibles dans le contexte de la mairie.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Le remplacement d''une carte d''identité perdue coûte combien ?

A. Vingt-cinq euros, en timbre fiscal.
B. Sous trois semaines, environ.
C. Au service des titres d''identité.
D. Parce qu''elle a été perdue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le remplacement d''une carte d''identité perdue coûte combien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vingt-cinq euros, en timbre fiscal.<break time="700ms"/>B.<break time="300ms"/>Sous trois semaines, environ.<break time="700ms"/>C.<break time="300ms"/>Au service des titres d''identité.<break time="700ms"/>D.<break time="300ms"/>Parce qu''elle a été perdue.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Coûte combien ? » appelle **un montant d''argent** : seule A « vingt-cinq euros, en timbre fiscal » donne une somme. B indique **un délai** et répondrait à « en combien de temps la recevrai-je ? » — piège du « combien » qui peut aussi mesurer une durée. C donne **un lieu** et répondrait à « où faire la demande ? ». D, introduit par « parce que », exprime **une cause** et répondrait à « pourquoi faut-il payer ? ». Mécanisme B1 : distinguer « combien » de prix et « combien » de temps, toutes les réponses restant dans le champ administratif.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b005-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi la mairie est-elle fermée ce jeudi ?

A. Jusqu''à lundi matin seulement.
B. Parce que c''est un jour férié.
C. À l''annexe du centre-ville.
D. Depuis huit heures, ce matin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi la mairie est-elle fermée ce jeudi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à lundi matin seulement.<break time="700ms"/>B.<break time="300ms"/>Parce que c''est un jour férié.<break time="700ms"/>C.<break time="300ms"/>À l''annexe du centre-ville.<break time="700ms"/>D.<break time="300ms"/>Depuis huit heures, ce matin.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause** : seule B, introduite par « parce que », explique la fermeture (« c''est un jour férié »). A, avec « jusqu''à », indique **la fin de la fermeture** et répondrait à « jusqu''à quand est-elle fermée ? ». C donne **un lieu** et répondrait à « où aller pendant la fermeture ? ». D, avec « depuis », marque **le début de la fermeture** et répondrait à « depuis quand est-elle fermée ? ». Mécanisme B1 : repérer le connecteur de cause « parce que » face aux marqueurs temporels « jusqu''à » et « depuis », tous plausibles dans le contexte.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b005-1000-0000-000000000001 → 0a.
-- [x] Thème unique « administration / mairie », 10 situations toutes
--     différentes : justificatif manquant pour la carte d'identité, achat du
--     timbre fiscal du passeport, retrait d'un acte de naissance, réservation
--     de la salle des fêtes, recensement citoyen à seize ans, report d'une
--     date de mariage (publication des bans), déclaration de changement
--     d'adresse électorale, horaires de l'état civil, coût du remplacement
--     d'une carte d'identité perdue, cause de fermeture de la mairie.
--     Aucun thème interdit (logement, SAV, médical, banque, voyage,
--     restaurant, téléphonie, école, travail, voiture, déménagement comme
--     thème central, assurance, colis, hôtel, pharmacie).
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4
--     répliques, ~35-65 mots prononcés chacun, multi-voix Henri/Vivienne)
--     + 3 × format B (co_question_reponse, question Henri/Vivienne +
--     propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 3,7,9), B=3 (items 2,5,10),
--     C=2 (items 1,8), D=2 (items 4,6) — 4 lettres utilisées, max 3.
-- [x] Inférence simple B1 : solution de repli (1), choix sous contrainte
--     matérielle (2), option compatible avec le délai (3), date de repli (4),
--     adaptation à une règle (5), report déduit du délai légal (6), choix
--     motivé entre deux canaux (7) ; format B explicite à distracteurs
--     proches (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, cause vs but, combien prix vs durée, connecteurs
--     « parce que » / « jusqu'à » / « depuis »).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95
--     (narration) / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300
--     ms conformes.
-- [x] Prénoms et origines variés : Haddad, Wei, Fernandez, Morales,
--     Bondarenko, Ndiaye — chiffres, dates et lieux originaux.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original.
-- ============================================================================
