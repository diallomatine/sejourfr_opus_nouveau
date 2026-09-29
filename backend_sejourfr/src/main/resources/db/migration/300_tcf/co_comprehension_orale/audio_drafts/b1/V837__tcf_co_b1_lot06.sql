-- ============================================================================
-- V837 — TCF CO B1 — lot 06 (thème : agence de voyage)
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
  ('66666666-b006-1000-0000-000000000001', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Alors, monsieur Traoré, pour vos vacances de printemps, j''ai deux séjours d''une semaine au même prix : Lisbonne ou Marrakech.
[Homme] Pour Lisbonne, il y a une escale, non ?
[Femme] Oui, à Madrid. Pour Marrakech, le vol est direct.
[Homme] Alors je prends Marrakech, je déteste les escales.

Quelle destination le client choisit-il ?

A. Lisbonne, parce que le séjour est moins cher.
B. Madrid, où se trouve l''escale.
C. Marrakech, grâce au vol direct.
D. Aucune : il préfère attendre l''été.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors, monsieur Traoré, pour vos vacances de printemps, j''ai deux séjours d''une semaine au même prix : Lisbonne ou Marrakech.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour Lisbonne, il y a une escale, non ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, à Madrid. Pour Marrakech, le vol est direct.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors je prends Marrakech, je déteste les escales.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle destination le client choisit-il ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Lisbonne, parce que le séjour est moins cher.<break time="700ms"/>B.<break time="300ms"/>Madrid, où se trouve l''escale.<break time="700ms"/>C.<break time="300ms"/>Marrakech, grâce au vol direct.<break time="700ms"/>D.<break time="300ms"/>Aucune : il préfère attendre l''été.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple critère → choix** : il faut relier l''aversion du client (« je déteste les escales ») et l''information de l''agente (« pour Marrakech, le vol est direct ») pour conclure que C est correct. A est doublement fausse : les deux séjours sont **au même prix**, et Lisbonne est la destination écartée. B confond la destination avec **le lieu de l''escale**, simple détail de l''itinéraire vers Lisbonne. D contredit la décision explicite « je prends Marrakech » : un séjour est bien réservé pour le printemps.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000002', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Le circuit au Vietnam revient à mille huit cents euros, madame Fernandes.
[Femme] C''est beaucoup d''un coup. Je peux payer en plusieurs fois ?
[Homme] Oui : en trois fois par carte, sans frais, ou avec des chèques-vacances.
[Femme] Je n''ai pas de chèques-vacances. Va pour la carte en trois fois.

Comment la cliente va-t-elle régler son voyage ?

A. En une seule fois, par carte.
B. Par carte, en trois fois.
C. Avec des chèques-vacances.
D. En espèces, à l''agence.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le circuit au Vietnam revient à mille huit cents euros, madame Fernandes.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est beaucoup d''un coup. Je peux payer en plusieurs fois ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui : en trois fois par carte, sans frais, ou avec des chèques-vacances.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je n''ai pas de chèques-vacances. Va pour la carte en trois fois.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment la cliente va-t-elle régler son voyage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En une seule fois, par carte.<break time="700ms"/>B.<break time="300ms"/>Par carte, en trois fois.<break time="700ms"/>C.<break time="300ms"/>Avec des chèques-vacances.<break time="700ms"/>D.<break time="300ms"/>En espèces, à l''agence.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Moyen de paiement final déduit par inférence simple** : l''agent propose deux options (trois fois par carte ou chèques-vacances) ; comme la cliente n''a pas de chèques-vacances, elle conclut « va pour la carte en trois fois » — B est correct. A est précisément ce que la cliente veut **éviter** (« c''est beaucoup d''un coup »). C est l''option **éliminée par la contrainte** « je n''ai pas de chèques-vacances ». D n''est jamais évoqué : distracteur thématique plausible mais hors document. Mécanisme B1 : relier la contrainte et l''offre pour déduire le choix.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000003', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour le circuit en Grèce, madame Kovtun, le départ du quinze juin est complet. Il reste des places en mai et en septembre.
[Femme] En mai, impossible : je termine une formation à Lyon.
[Homme] Alors je vous inscris pour le départ de septembre ?
[Femme] Oui, parfait, faisons comme ça.

Quand la cliente partira-t-elle en Grèce ?

A. En mai, après sa formation.
B. Le quinze juin, comme prévu.
C. Elle annule son voyage.
D. En septembre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour le circuit en Grèce, madame Kovtun, le départ du quinze juin est complet. Il reste des places en mai et en septembre.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">En mai, impossible : je termine une formation à Lyon.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors je vous inscris pour le départ de septembre ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, parfait, faisons comme ça.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quand la cliente partira-t-elle en Grèce ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En mai, après sa formation.<break time="700ms"/>B.<break time="300ms"/>Le quinze juin, comme prévu.<break time="700ms"/>C.<break time="300ms"/>Elle annule son voyage.<break time="700ms"/>D.<break time="300ms"/>En septembre.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple par élimination** : juin est complet, mai est impossible à cause de la formation, il ne reste que septembre — et la cliente valide (« oui, parfait »). D est correct. A est contredit deux fois : la formation a lieu **pendant** mai, pas avant, et la cliente dit « en mai, impossible ». B reprend la date entendue en premier, mais ce départ est **complet** — piège de la première information. C contredit l''inscription confirmée à la fin du dialogue : le voyage est maintenu, seulement décalé.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000004', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je voudrais réserver une semaine de plage en août, sur l''île que vous m''aviez montrée la dernière fois.
[Femme] Je vous la déconseille en août, monsieur Garcia : c''est la saison des pluies là-bas. La côte sud, en revanche, est ensoleillée à cette période.
[Homme] D''accord, alors partons pour la côte sud.

Pourquoi le client change-t-il de destination ?

A. À cause de la saison des pluies sur l''île.
B. Parce que le séjour sur l''île est trop cher.
C. Parce qu''il n''y a plus de places d''avion.
D. Parce qu''il préfère la montagne à la plage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je voudrais réserver une semaine de plage en août, sur l''île que vous m''aviez montrée la dernière fois.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je vous la déconseille en août, monsieur Garcia : c''est la saison des pluies là-bas. La côte sud, en revanche, est ensoleillée à cette période.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">D''accord, alors partons pour la côte sud.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le client change-t-il de destination ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause de la saison des pluies sur l''île.<break time="700ms"/>B.<break time="300ms"/>Parce que le séjour sur l''île est trop cher.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il n''y a plus de places d''avion.<break time="700ms"/>D.<break time="300ms"/>Parce qu''il préfère la montagne à la plage.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « pourquoi ? » appelle **une cause**, donnée explicitement par l''agente : « je vous la déconseille en août : c''est la saison des pluies là-bas » — A est correct. Il faut relier ce conseil et l''acceptation du client (« d''accord, partons pour la côte sud ») : **inférence simple conseil → décision**. B et C sont des causes **plausibles dans une agence de voyage** (prix, disponibilité) mais jamais citées dans le dialogue. D contredit le document : le client garde un projet de plage, seule la zone change, pas le type de vacances.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000005', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Pour aller à Venise, monsieur Cheng, vous avez l''avion depuis Lyon ou le train de nuit direct.
[Homme] L''avion est plus rapide, mais je voyage avec mon vélo.
[Femme] Alors le train de nuit est plus pratique : le vélo est accepté sans supplément.
[Homme] Très bien, réservez-moi le train.

Comment le client va-t-il voyager jusqu''à Venise ?

A. En avion, au départ de Lyon.
B. En train de nuit.
C. En voiture, avec son vélo sur le toit.
D. En autocar direct.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pour aller à Venise, monsieur Cheng, vous avez l''avion depuis Lyon ou le train de nuit direct.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''avion est plus rapide, mais je voyage avec mon vélo.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors le train de nuit est plus pratique : le vélo est accepté sans supplément.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, réservez-moi le train.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Comment le client va-t-il voyager jusqu''à Venise ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En avion, au départ de Lyon.<break time="700ms"/>B.<break time="300ms"/>En train de nuit.<break time="700ms"/>C.<break time="300ms"/>En voiture, avec son vélo sur le toit.<break time="700ms"/>D.<break time="300ms"/>En autocar direct.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple contrainte → choix** : il faut relier « je voyage avec mon vélo » et l''argument de l''agente (« le vélo est accepté sans supplément » dans le train) pour comprendre la conclusion « réservez-moi le train ». B est correct. A est l''option reconnue **plus rapide mais écartée**, incompatible avec le vélo — piège du « mais » de concession. C recycle le mot « vélo » dans un scénario jamais évoqué : aucun trajet en voiture n''est proposé. D n''apparaît pas dans le dialogue ; « direct » y qualifie le train, pas un autocar.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000006', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour le Japon, madame Ndiaye, je peux vous proposer un voyage libre ou un circuit accompagné avec un guide francophone.
[Femme] C''est mon premier grand voyage et je ne parle pas japonais.
[Homme] Dans ce cas, le circuit avec guide est plus rassurant.
[Femme] Oui, je choisis celui-là.

Quelle formule la cliente choisit-elle ?

A. Le voyage libre, sans guide.
B. Un séjour linguistique pour apprendre le japonais.
C. Un circuit dans un pays francophone.
D. Le circuit accompagné par un guide.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour le Japon, madame Ndiaye, je peux vous proposer un voyage libre ou un circuit accompagné avec un guide francophone.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est mon premier grand voyage et je ne parle pas japonais.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Dans ce cas, le circuit avec guide est plus rassurant.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Oui, je choisis celui-là.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle formule la cliente choisit-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le voyage libre, sans guide.<break time="700ms"/>B.<break time="300ms"/>Un séjour linguistique pour apprendre le japonais.<break time="700ms"/>C.<break time="300ms"/>Un circuit dans un pays francophone.<break time="700ms"/>D.<break time="300ms"/>Le circuit accompagné par un guide.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple** : « je choisis celui-là » est une **reprise anaphorique** — il faut comprendre que « celui-là » renvoie au circuit avec guide, recommandé juste avant (« plus rassurant ») à cause du double argument « premier grand voyage » + « je ne parle pas japonais ». D est correct. A est l''option **écartée**, inadaptée à une voyageuse inexpérimentée. B détourne « je ne parle pas japonais » vers un projet d''apprentissage jamais évoqué. C joue sur « francophone », qui qualifie **le guide**, pas le pays de destination : le voyage reste au Japon.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000007', 'B1', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Pour votre journée dans le désert, madame Sharma, nous proposons deux excursions : la sortie en quad ou la balade à dos de chameau.
[Femme] Le quad, c''est possible avec mes enfants de cinq et sept ans ?
[Homme] Non, le quad est interdit aux moins de seize ans.
[Femme] Alors ce sera les chameaux, pour toute la famille.

Quelle excursion la famille va-t-elle faire ?

A. La balade à dos de chameau.
B. La sortie en quad.
C. Une visite guidée de la ville.
D. Aucune : les enfants sont trop jeunes.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pour votre journée dans le désert, madame Sharma, nous proposons deux excursions : la sortie en quad ou la balade à dos de chameau.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le quad, c''est possible avec mes enfants de cinq et sept ans ?</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Non, le quad est interdit aux moins de seize ans.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Alors ce sera les chameaux, pour toute la famille.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle excursion la famille va-t-elle faire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La balade à dos de chameau.<break time="700ms"/>B.<break time="300ms"/>La sortie en quad.<break time="700ms"/>C.<break time="300ms"/>Une visite guidée de la ville.<break time="700ms"/>D.<break time="300ms"/>Aucune : les enfants sont trop jeunes.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '**Inférence simple par élimination** : le quad est interdit aux moins de seize ans, or les enfants ont cinq et sept ans ; la mère conclut « ce sera les chameaux, pour toute la famille » — A est correct. B est l''option **bloquée par la limite d''âge**, piège pour qui ne relie pas l''interdiction à l''âge des enfants. C n''est jamais proposée : le dialogue porte sur une journée **dans le désert**, pas en ville. D applique l''interdiction à tort aux deux excursions : la balade à dos de chameau, elle, reste accessible à toute la famille.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000008', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Le vol pour Dakar décolle à quelle heure ?

A. Depuis le terminal deux de l''aéroport.
B. Avec une escale à Casablanca.
C. À six heures quarante du matin.
D. Environ cinq heures et demie de vol.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Le vol pour Dakar décolle à quelle heure ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le terminal deux de l''aéroport.<break time="700ms"/>B.<break time="300ms"/>Avec une escale à Casablanca.<break time="700ms"/>C.<break time="300ms"/>À six heures quarante du matin.<break time="700ms"/>D.<break time="300ms"/>Environ cinq heures et demie de vol.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quelle heure ? » demande **un horaire précis** : seule C « à six heures quarante du matin » situe le décollage dans la journée. A indique **le lieu de départ** et répondrait à « d''où part le vol ? ». B décrit **l''itinéraire** et répondrait à « le vol est-il direct ? ». D donne **une durée**, pas une heure, et répondrait à « combien de temps dure le vol ? » — piège classique entre heure et durée, toutes deux exprimées avec « heures ». Mécanisme B1 : identifier la nature exacte de l''information attendue par le mot interrogatif.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-000000000009', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi avez-vous choisi cette croisière ?

A. Parce que ma sœur me l''a recommandée.
B. Au départ de Marseille, le samedi.
C. Pendant les vacances de février.
D. Pour huit cent cinquante euros par personne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi avez-vous choisi cette croisière ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que ma sœur me l''a recommandée.<break time="700ms"/>B.<break time="300ms"/>Au départ de Marseille, le samedi.<break time="700ms"/>C.<break time="300ms"/>Pendant les vacances de février.<break time="700ms"/>D.<break time="300ms"/>Pour huit cent cinquante euros par personne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi ? » appelle **une cause** : seule A, introduite par « parce que », explique le choix (« ma sœur me l''a recommandée »). B donne **le lieu et le jour de départ** et répondrait à « d''où et quand part la croisière ? ». C donne **la période** et répondrait à « quand partez-vous ? ». D donne **le prix** et répondrait à « combien coûte la croisière ? » — attention, le « pour » de D introduit ici un montant, pas un but. Mécanisme B1 : repérer le connecteur de cause « parce que », seule marque qui réponde à « pourquoi », alors que les quatre réponses restent crédibles dans le contexte du voyage.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-b006-1000-0000-00000000000a', 'B1', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Vous avez droit à combien de bagages sur ce vol ?

A. La veille du départ, sur internet.
B. Deux valises de vingt kilos chacune.
C. Dans la soute de l''avion.
D. Pour éviter de payer un supplément.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez droit à combien de bagages sur ce vol ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La veille du départ, sur internet.<break time="700ms"/>B.<break time="300ms"/>Deux valises de vingt kilos chacune.<break time="700ms"/>C.<break time="300ms"/>Dans la soute de l''avion.<break time="700ms"/>D.<break time="300ms"/>Pour éviter de payer un supplément.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de bagages ? » demande **une quantité** : seule B « deux valises de vingt kilos chacune » donne un nombre. A indique **un moment et un moyen** (l''enregistrement en ligne) et répondrait à « quand et comment s''enregistrer ? ». C indique **un lieu** et répondrait à « où vont les bagages ? ». D, introduit par « pour », exprime **un but** et répondrait à « pourquoi limiter ses bagages ? ». Mécanisme B1 : « combien de » impose une réponse chiffrée — les quatre propositions parlent toutes de bagages, seule la nature de la question permet de trancher.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes 66666666-b006-1000-0000-000000000001 → 0a.
-- [x] Thème unique « agence de voyage », 10 situations toutes différentes :
--     choix entre 2 destinations (vol direct), paiement du circuit en 3 fois,
--     report du départ (juin complet), changement de destination (saison des
--     pluies), choix du moyen de transport (train de nuit + vélo), formule
--     circuit accompagné vs voyage libre, choix d'excursion (limite d'âge du
--     quad), horaire de décollage, raison du choix d'une croisière, franchise
--     de bagages.
-- [x] Répartition : 7 × format C (co_document_question, dialogues 3-4 répliques,
--     ~35-60 mots prononcés chacun, multi-voix Henri/Vivienne) + 3 × format B
--     (co_question_reponse, question Henri/Vivienne + propositions Denise).
-- [x] 4 propositions / exactement 1 correcte par item.
-- [x] Distribution des bonnes réponses : A=3 (items 4,7,9), B=3 (items 2,5,10),
--     C=2 (items 1,8), D=2 (items 3,6) — 4 lettres utilisées, max 3.
-- [x] Inférence simple B1 : critère → choix (1,5), moyen de paiement (2),
--     élimination (3,7), conseil → décision (4), reprise anaphorique (6) ;
--     format B explicite + distracteurs proches (8,9,10).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse ET chaque
--     distracteur, point clé en **gras**, mécanisme linguistique nommé
--     (inférence simple, heure vs durée, connecteur de cause, quantité).
-- [x] SSML : balises <voice>/<prosody> équilibrées, voix Denise 0.95 (narration)
--     / Henri & Vivienne 1.0 (dialogue), pauses 1500/1000/700/300 ms conformes.
-- [x] Prénoms et origines variés : Traoré, Fernandes, Kovtun, Garcia, Cheng,
--     Ndiaye, Sharma ; villes : Lisbonne, Marrakech, Lyon, Venise, Dakar,
--     Casablanca, Marseille.
-- [x] status='TEXT_VALIDATED', colonnes audio NULL, batch_id NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées (''), JSONB valide, aucun SVG requis (pas de
--     CO_IMAGE dans ce lot). Contenu 100 % original.
-- ============================================================================
