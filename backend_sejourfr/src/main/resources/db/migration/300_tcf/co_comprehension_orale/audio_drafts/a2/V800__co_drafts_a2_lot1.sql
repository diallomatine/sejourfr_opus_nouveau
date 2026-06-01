-- ============================================================================
-- V480 — TCF CO : drafts audio A2 (lot 1)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2). Table audio_question_draft.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-0022-1000-0000-000000000001', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Comment êtes-vous parvenu à finaliser le dossier aussi vite ?
[Femme] ...

A. Dès la semaine dernière.
B. En sollicitant toute l''équipe.
C. Parce que c''était urgent.
D. Avec beaucoup de satisfaction.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment êtes-vous parvenu à finaliser le dossier aussi vite ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dès la semaine dernière.<break time="700ms"/>B.<break time="300ms"/>En sollicitant toute l''équipe.<break time="700ms"/>C.<break time="300ms"/>Parce que c''était urgent.<break time="700ms"/>D.<break time="300ms"/>Avec beaucoup de satisfaction.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « comment êtes-vous parvenu à... » porte sur **la manière, le moyen utilisé**. Seule la réponse B « en sollicitant toute l''équipe » (gérondif de moyen) répond à cette question. A répond à « quand avez-vous commencé ? » (moment). C répond à « pourquoi êtes-vous allé si vite ? » (cause). D répond à « qu''avez-vous ressenti ? » (émotion). Le piège B2 : les quatre réponses sont parfaitement naturelles dans un échange professionnel, il faut identifier précisément la nature de la question.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/0945d767-bbd2-424f-b7f5-aec08abeef39.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:48:58.981957+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:23.720223+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000002', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] À quelles conditions accepteriez-vous de reprendre ce poste ?
[Homme] ...

A. Depuis bientôt trois ans.
B. Sans hésiter une seconde.
C. À condition d''obtenir plus d''autonomie.
D. Parce que j''en garde un bon souvenir.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À quelles conditions accepteriez-vous de reprendre ce poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis bientôt trois ans.<break time="700ms"/>B.<break time="300ms"/>Sans hésiter une seconde.<break time="700ms"/>C.<break time="300ms"/>À condition d''obtenir plus d''autonomie.<break time="700ms"/>D.<break time="300ms"/>Parce que j''en garde un bon souvenir.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « à quelles conditions... » exige une réponse exprimant **une condition, une exigence préalable**. Seule la réponse C « à condition d''obtenir plus d''autonomie » répond directement avec le marqueur de condition correspondant. A répond à « depuis combien de temps êtes-vous parti ? » (durée). B répond à « comment réagiriez-vous à une offre ? » (manière/attitude). D répond à « pourquoi y reviendriez-vous ? » (cause/motivation). Difficulté B2 : B et D sont très tentantes car positives, mais elles ne formulent aucune condition.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/396407a4-d082-4fdd-913b-d06d7e8e3021.mp3',
   '29', 'fr-FR-DeniseNeural', '2026-05-31 16:48:59.338122+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:24.804615+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000003', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu fréquentes cet endroit régulièrement ?
[Femme] ...

A. Pendant environ deux heures.
B. À peu près tous les quinze jours.
C. Depuis l''ouverture en 2019.
D. Plutôt en début de soirée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fréquentes cet endroit régulièrement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant environ deux heures.<break time="700ms"/>B.<break time="300ms"/>À peu près tous les quinze jours.<break time="700ms"/>C.<break time="300ms"/>Depuis l''ouverture en 2019.<break time="700ms"/>D.<break time="300ms"/>Plutôt en début de soirée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''adverbe « régulièrement » oriente la question vers **la fréquence** (à quel rythme). Seule la réponse B « tous les quinze jours » exprime une fréquence. A exprime une durée d''une visite (« pendant deux heures » répond à « combien de temps y restes-tu ? »). C exprime un point de départ dans le temps (« depuis quand y vas-tu ? »). D exprime un moment habituel (« à quel moment y vas-tu ? »). Toutes les réponses concernent le temps, c''est le type précis de référence temporelle qui les distingue.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/f2f84109-96e8-43b0-a8c0-30cbb6f7be1c.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:48:59.661672+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:21.571889+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000004', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Qu''est-ce qui t''a poussé à changer de carrière ?
[Homme] ...

A. Du coup, j''ai gagné en sérénité.
B. Une lassitude profonde envers mon ancien métier.
C. Pour me consacrer davantage à ma famille.
D. Au bout d''une longue réflexion.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui t''a poussé à changer de carrière ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du coup, j''ai gagné en sérénité.<break time="700ms"/>B.<break time="300ms"/>Une lassitude profonde envers mon ancien métier.<break time="700ms"/>C.<break time="300ms"/>Pour me consacrer davantage à ma famille.<break time="700ms"/>D.<break time="300ms"/>Au bout d''une longue réflexion.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''a poussé... » est une question sur **la cause, le facteur déclenchant** (ce qui a précédé et provoqué). B « une lassitude profonde » désigne précisément cette cause. A exprime une **conséquence** (« du coup » = donc), donc répond à « qu''est-ce que ça t''a apporté ? ». C exprime un **but** (« pour » = finalité), donc répond à « dans quel objectif l''as-tu fait ? ». D exprime un cadre temporel (« au bout de » = après combien de temps). Le piège B2 majeur : confondre cause et but est très fréquent — la cause est antérieure et subie, le but est postérieur et voulu.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/5a6e14b5-5578-4053-b5c6-40f12df8653f.mp3',
   '30', 'fr-FR-DeniseNeural', '2026-05-31 16:49:00.018874+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:19.468078+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000005', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Que penses-tu de la dernière exposition du musée ?
[Femme] ...

A. À deux pas du centre-ville.
B. Avec une amie de longue date.
C. Plutôt décevante, à vrai dire.
D. Jusqu''à la fin du mois prochain.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Que penses-tu de la dernière exposition du musée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À deux pas du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Avec une amie de longue date.<break time="700ms"/>C.<break time="300ms"/>Plutôt décevante, à vrai dire.<break time="700ms"/>D.<break time="300ms"/>Jusqu''à la fin du mois prochain.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Que penses-tu de... » est une demande d''**opinion, de jugement de valeur**. Seule C « plutôt décevante » exprime une appréciation. A localise (« où se trouve le musée ? »). B précise un accompagnant (« avec qui y es-tu allée ? »). D indique une durée future (« jusqu''à quand est-elle visible ? »). Difficulté B2 : toutes les réponses sont cohérentes avec le thème « exposition », ce qui peut tromper un candidat qui se contenterait d''un lien thématique.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/428d9db4-553b-499b-8247-8121de4d10f9.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:49:00.398328+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:26.187294+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000006', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] À qui ce rapport est-il finalement destiné ?
[Homme] ...

A. À la direction générale exclusivement.
B. Par mes soins, dès demain matin.
C. Sur la base des données du trimestre.
D. En vue de la prochaine assemblée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À qui ce rapport est-il finalement destiné ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la direction générale exclusivement.<break time="700ms"/>B.<break time="300ms"/>Par mes soins, dès demain matin.<break time="700ms"/>C.<break time="300ms"/>Sur la base des données du trimestre.<break time="700ms"/>D.<break time="300ms"/>En vue de la prochaine assemblée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À qui est destiné... » interroge sur **le destinataire**. Seule A « à la direction générale » désigne un destinataire. B identifie l''auteur (« par qui sera-t-il rédigé ? »). C indique la source des données (« sur quoi se base-t-il ? »). D exprime la finalité (« dans quel but est-il produit ? »). Le piège B2 : D « en vue de la prochaine assemblée » évoque un public final et peut être confondue avec un destinataire, mais elle exprime un objectif, pas une personne destinataire directe.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/40a87e18-54c7-453b-8c03-0752c3798954.mp3',
   '29', 'fr-FR-DeniseNeural', '2026-05-31 16:49:00.690411+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:27.65158+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000007', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quelle proportion des salariés a finalement adhéré au dispositif ?
[Femme] ...

A. Près des trois quarts d''entre eux.
B. Notamment les cadres intermédiaires.
C. Dans un délai relativement court.
D. Grâce à une campagne d''information ciblée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle proportion des salariés a finalement adhéré au dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près des trois quarts d''entre eux.<break time="700ms"/>B.<break time="300ms"/>Notamment les cadres intermédiaires.<break time="700ms"/>C.<break time="300ms"/>Dans un délai relativement court.<break time="700ms"/>D.<break time="300ms"/>Grâce à une campagne d''information ciblée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle proportion... » appelle une **quantité chiffrée ou fractionnée**. Seule A « les trois quarts » exprime une proportion. B identifie une **catégorie concernée** (« lesquels ont adhéré ? »). C précise un délai (« en combien de temps ? »). D donne une cause/moyen (« comment ont-ils été convaincus ? »). Difficulté B2 : B est piégeuse car elle parle aussi des adhérents, mais elle répond à « qui ? » et non à « combien ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/39171280-3e2b-4a00-a688-0a5e051d3941.mp3',
   '30', 'fr-FR-HenriNeural', '2026-05-31 16:49:01.069182+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:28.186153+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000008', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu lui rends souvent visite, à ta grand-mère ?
[Homme] ...

A. Plutôt rarement, malheureusement.
B. Elle habite dans le Sud-Ouest.
C. Elle vient d''avoir quatre-vingt-cinq ans.
D. Toujours avec un grand plaisir.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lui rends souvent visite, à ta grand-mère ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt rarement, malheureusement.<break time="700ms"/>B.<break time="300ms"/>Elle habite dans le Sud-Ouest.<break time="700ms"/>C.<break time="300ms"/>Elle vient d''avoir quatre-vingt-cinq ans.<break time="700ms"/>D.<break time="300ms"/>Toujours avec un grand plaisir.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''adverbe « souvent » oriente la question sur **la fréquence**. A « rarement » répond directement, c''est l''antonyme attendu. B répond à « où vit-elle ? ». C répond à « quel âge a-t-elle ? ». D « toujours avec plaisir » est un piège majeur en B2 : « toujours » ressemble à un adverbe de fréquence, mais ici il signifie « à chaque fois » au sens d''accompagnement émotionnel ; la réponse porte sur la manière (le ressenti), pas sur le rythme des visites. Il faut écouter la question, pas le mot isolé.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/15664e92-c0fa-49e2-b577-8ebd4d591b78.mp3',
   '29', 'fr-FR-DeniseNeural', '2026-05-31 16:49:01.386188+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:20.591878+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000009', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Qu''est-ce qui distingue ce modèle de l''ancien ?
[Femme] ...

A. À partir de mille deux cents euros.
B. Une autonomie nettement supérieure.
C. Disponible dès la rentrée prochaine.
D. Conçu par une équipe française.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui distingue ce modèle de l''ancien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir de mille deux cents euros.<break time="700ms"/>B.<break time="300ms"/>Une autonomie nettement supérieure.<break time="700ms"/>C.<break time="300ms"/>Disponible dès la rentrée prochaine.<break time="700ms"/>D.<break time="300ms"/>Conçu par une équipe française.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui distingue X de Y » appelle un **élément différenciant, comparatif**. Seule B « une autonomie nettement supérieure » établit explicitement une comparaison (« supérieure » = comparatif). A donne un prix (« combien ça coûte ? »). C donne une date de disponibilité (« quand sera-t-il vendu ? »). D donne une origine (« où a-t-il été conçu ? »). Toutes ces caractéristiques sont vraies du modèle, mais aucune ne le **distingue** explicitement de l''ancien — seule B le fait par son comparatif.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/512264b0-bc71-4cbe-a2be-796acf2d0126.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:49:01.731396+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:23.095289+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-1000-0000-000000000010', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] D''où tiens-tu cette information, au juste ?
[Homme] ...

A. Depuis hier soir seulement.
B. D''un collègue bien renseigné.
C. Dans les moindres détails.
D. À ma plus grande surprise.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">D''où tiens-tu cette information, au juste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis hier soir seulement.<break time="700ms"/>B.<break time="300ms"/>D''un collègue bien renseigné.<break time="700ms"/>C.<break time="300ms"/>Dans les moindres détails.<break time="700ms"/>D.<break time="300ms"/>À ma plus grande surprise.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« D''où tiens-tu... » interroge sur **la source, l''origine d''une information** (qui te l''a dite). Seule B « d''un collègue » désigne une source humaine. A indique le moment de l''apprentissage (« depuis quand le sais-tu ? »). C porte sur le degré de précision (« à quel point en sais-tu sur le sujet ? »). D exprime une réaction émotionnelle (« qu''as-tu ressenti en l''apprenant ? »). Le piège B2 principal : A commence aussi par « depuis » et peut sembler répondre à « d''où » de façon temporelle, mais « d''où » porte ici sur la source, pas sur le point de départ temporel.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/f33da7dc-4139-42c1-bec8-ba839d953455.mp3',
   '27', 'fr-FR-DeniseNeural', '2026-05-31 16:49:01.99373+02', '6f2ff822-7ad9-4765-8f79-e7fbdf72cac9',
   '2026-05-27 17:40:30.291543+02', '2026-05-31 16:49:22.490493+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000001', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Où est ton sac à dos, finalement ?
[Femme] ...

A. Sous la table de l''entrée.
B. Pour mes affaires d''école.
C. Avec mes livres dedans.
D. Depuis ce matin, je crois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où est ton sac à dos, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sous la table de l''entrée.<break time="700ms"/>B.<break time="300ms"/>Pour mes affaires d''école.<break time="700ms"/>C.<break time="300ms"/>Avec mes livres dedans.<break time="700ms"/>D.<break time="300ms"/>Depuis ce matin, je crois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Où est ton sac ? » porte sur **le lieu**. Seule A « sous la table de l''entrée » indique un endroit. B donne **le but** (« pour quoi faire ? »). C donne **le contenu** (« avec quoi dedans ? »). D donne **un moment** (« depuis quand ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/558d550a-9f58-464c-85ae-89ddfb0ccc42.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:50:44.240442+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:53.687165+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000002', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quand est-ce que tu rentres ce soir ?
[Homme] ...

A. Au bureau, comme d''habitude.
B. Vers dix-neuf heures, je pense.
C. Avec mon collègue Pierre.
D. Pour finir un dossier urgent.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quand est-ce que tu rentres ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bureau, comme d''habitude.<break time="700ms"/>B.<break time="300ms"/>Vers dix-neuf heures, je pense.<break time="700ms"/>C.<break time="300ms"/>Avec mon collègue Pierre.<break time="700ms"/>D.<break time="300ms"/>Pour finir un dossier urgent.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quand est-ce que tu rentres ? » porte sur **le moment**. Seule B « vers dix-neuf heures » donne une heure. A donne **le lieu**. C donne **l''accompagnant**. D donne **la cause / le but**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/ff280b8a-8caf-4026-9627-f6163cd63560.mp3',
   '27', 'fr-FR-DeniseNeural', '2026-05-31 16:50:44.552661+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:54.303159+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000003', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as combien de chats à la maison ?
[Femme] ...

A. Très calmes, en général.
B. Pour me tenir compagnie.
C. Deux, un noir et un blanc.
D. Dans le salon, souvent.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as combien de chats à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Très calmes, en général.<break time="700ms"/>B.<break time="300ms"/>Pour me tenir compagnie.<break time="700ms"/>C.<break time="300ms"/>Deux, un noir et un blanc.<break time="700ms"/>D.<break time="300ms"/>Dans le salon, souvent.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de chats ? » porte sur **le nombre**. Seule C « deux » donne une quantité. A donne **le caractère** des animaux. B donne **le but / la raison** de les avoir. D donne **le lieu**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/a11047e6-1430-41ac-865d-7cf34f3abb1f.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:50:44.879221+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:57.498446+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000004', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Qui te garde ton fils ce soir ?
[Homme] ...

A. Jusqu''à minuit, environ.
B. Pour aller au cinéma.
C. Dans son appartement à elle.
D. Ma mère, comme souvent.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qui te garde ton fils ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à minuit, environ.<break time="700ms"/>B.<break time="300ms"/>Pour aller au cinéma.<break time="700ms"/>C.<break time="300ms"/>Dans son appartement à elle.<break time="700ms"/>D.<break time="300ms"/>Ma mère, comme souvent.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qui te garde ton fils ? » porte sur **l''identité de la personne qui garde**. Seule D « ma mère » désigne une personne. A donne **la durée** (« jusqu''à quand ? »). B donne **le but** (« pour quoi faire ? »). C donne **le lieu**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/2f586821-5b0b-4617-9434-72a198c0cd9a.mp3',
   '27', 'fr-FR-DeniseNeural', '2026-05-31 16:50:45.188503+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:58.871575+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000005', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu manges là ?
[Femme] ...

A. Un sandwich au poulet, tout simple.
B. Au coin de la rue, à la boulangerie.
C. Pour environ cinq euros, je crois.
D. Avec mes collègues du bureau.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu manges là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un sandwich au poulet, tout simple.<break time="700ms"/>B.<break time="300ms"/>Au coin de la rue, à la boulangerie.<break time="700ms"/>C.<break time="300ms"/>Pour environ cinq euros, je crois.<break time="700ms"/>D.<break time="300ms"/>Avec mes collègues du bureau.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que tu manges ? » porte sur **la nourriture**. Seule A « un sandwich au poulet » nomme un plat. B donne **le lieu d''achat**. C donne **le prix**. D donne **l''accompagnement**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/390ab77a-3760-481e-b7f4-cb278498ef95.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:50:45.556689+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:00.10262+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000006', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu prends quelle baguette aujourd''hui ?
[Homme] ...

A. À la boulangerie du coin de la rue.
B. La tradition, s''il vous plaît.
C. Pour le déjeuner de ce midi.
D. Avec un croissant en plus, peut-être.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu prends quelle baguette aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la boulangerie du coin de la rue.<break time="700ms"/>B.<break time="300ms"/>La tradition, s''il vous plaît.<break time="700ms"/>C.<break time="300ms"/>Pour le déjeuner de ce midi.<break time="700ms"/>D.<break time="300ms"/>Avec un croissant en plus, peut-être.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu prends quelle baguette ? » porte sur **le choix du type de pain**. Seule B « la tradition » désigne un type. A donne **le lieu d''achat**. C donne **le moment de consommation**. D donne **un produit additionnel**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/27e1a7c3-75c0-4962-9346-1c1fd8d5d3cc.mp3',
   '28', 'fr-FR-DeniseNeural', '2026-05-31 16:50:45.929787+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:54.952972+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000007', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] À quelle heure tu te lèves d''habitude ?
[Femme] ...

A. Avec mon réveil sur le téléphone.
B. Pour aller au sport très tôt.
C. À sept heures pile, en semaine.
D. Dans ma chambre, comme tout le monde.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure tu te lèves d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mon réveil sur le téléphone.<break time="700ms"/>B.<break time="300ms"/>Pour aller au sport très tôt.<break time="700ms"/>C.<break time="300ms"/>À sept heures pile, en semaine.<break time="700ms"/>D.<break time="300ms"/>Dans ma chambre, comme tout le monde.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quelle heure tu te lèves ? » porte sur **l''heure du réveil**. Seule C « à sept heures pile » donne une heure. A donne **le moyen** de se réveiller. B donne **le but**. D donne **le lieu**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/df9e7b8a-80dc-4ac1-b838-f88fd7c9afc0.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:50:46.243208+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:01.304053+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000008', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Comment tu vas au travail le matin ?
[Homme] ...

A. À la station Bastille, en général.
B. Pour environ trente minutes de trajet.
C. Pendant tout le mois de septembre.
D. En métro, ligne cinq.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment tu vas au travail le matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la station Bastille, en général.<break time="700ms"/>B.<break time="300ms"/>Pour environ trente minutes de trajet.<break time="700ms"/>C.<break time="300ms"/>Pendant tout le mois de septembre.<break time="700ms"/>D.<break time="300ms"/>En métro, ligne cinq.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment tu vas au travail ? » porte sur **le moyen de transport**. Seule D « en métro, ligne cinq » nomme le moyen. A donne **un lieu / une station**. B donne **la durée**. C donne **une période**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/11e8066b-9c5a-4d94-afd3-0ddeaee58365.mp3',
   '29', 'fr-FR-DeniseNeural', '2026-05-31 16:50:46.584417+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:02.90379+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000009', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Pourquoi tu es en retard, ce matin ?
[Femme] ...

A. À cause d''une grève des transports.
B. Vers neuf heures et demie.
C. Avec mon manteau et mon écharpe.
D. Au bureau, comme d''habitude.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi tu es en retard, ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une grève des transports.<break time="700ms"/>B.<break time="300ms"/>Vers neuf heures et demie.<break time="700ms"/>C.<break time="300ms"/>Avec mon manteau et mon écharpe.<break time="700ms"/>D.<break time="300ms"/>Au bureau, comme d''habitude.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Pourquoi tu es en retard ? » porte sur **la cause du retard**. Seule A « à cause d''une grève » donne une cause. B donne **l''heure d''arrivée**. C donne **les habits portés**. D donne **le lieu d''arrivée**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/c53e7986-667e-4d82-b4b1-b84099880cf9.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:50:46.882183+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:56.0253+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Avec qui tu pars en vacances cet été ?
[Homme] ...

A. À Saint-Malo, en Bretagne.
B. Avec mes deux meilleurs amis.
C. Pour quinze jours pleins.
D. En camping, près de la plage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec qui tu pars en vacances cet été ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À Saint-Malo, en Bretagne.<break time="700ms"/>B.<break time="300ms"/>Avec mes deux meilleurs amis.<break time="700ms"/>C.<break time="300ms"/>Pour quinze jours pleins.<break time="700ms"/>D.<break time="300ms"/>En camping, près de la plage.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Avec qui tu pars ? » porte sur **les personnes qui t''accompagnent**. Seule B « avec mes deux meilleurs amis » désigne des personnes. A donne **le lieu**. C donne **la durée**. D donne **le mode d''hébergement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/f5838b75-4542-4ef0-9057-46bf5b1efc4b.mp3',
   '27', 'fr-FR-DeniseNeural', '2026-05-31 16:50:47.27274+02', '539ff641-5f3a-44d7-ac53-6c55b04f36f9',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:50:56.569999+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu travailles ici depuis combien de temps ?
[Femme] ...

A. Au bureau du troisième étage.
B. Pour la comptabilité, oui.
C. Depuis presque trois ans déjà.
D. Avec une dizaine de collègues.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu travailles ici depuis combien de temps ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bureau du troisième étage.<break time="700ms"/>B.<break time="300ms"/>Pour la comptabilité, oui.<break time="700ms"/>C.<break time="300ms"/>Depuis presque trois ans déjà.<break time="700ms"/>D.<break time="300ms"/>Avec une dizaine de collègues.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Depuis combien de temps tu travailles ici ? » porte sur **l''ancienneté**. Seule C « depuis presque trois ans » donne une durée écoulée. A donne **le lieu de travail**. B donne **le service / le poste**. D donne **les collègues**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/a32c8d9e-82ed-47bb-8cc8-d9324b60ad5d.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:51:05.751377+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:15.236309+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as dormi combien de temps cette nuit ?
[Homme] ...

A. Pour me reposer du week-end.
B. Dans la chambre du fond.
C. Avec un masque sur les yeux.
D. Sept bonnes heures, je crois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as dormi combien de temps cette nuit ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour me reposer du week-end.<break time="700ms"/>B.<break time="300ms"/>Dans la chambre du fond.<break time="700ms"/>C.<break time="300ms"/>Avec un masque sur les yeux.<break time="700ms"/>D.<break time="300ms"/>Sept bonnes heures, je crois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de temps tu as dormi ? » porte sur **la durée du sommeil**. Seule D « sept bonnes heures » donne une durée. A donne **le but**. B donne **le lieu**. C donne **un accessoire utilisé**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/2a58db58-5c33-449e-b902-87492cde670e.mp3',
   '27', 'fr-FR-DeniseNeural', '2026-05-31 16:51:06.137175+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:15.803618+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] De quelle couleur est ta nouvelle voiture ?
[Femme] ...

A. Gris métallisé, très élégant.
B. Chez le concessionnaire Peugeot.
C. Pour environ vingt mille euros.
D. Avec mon mari, samedi dernier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">De quelle couleur est ta nouvelle voiture ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Gris métallisé, très élégant.<break time="700ms"/>B.<break time="300ms"/>Chez le concessionnaire Peugeot.<break time="700ms"/>C.<break time="300ms"/>Pour environ vingt mille euros.<break time="700ms"/>D.<break time="300ms"/>Avec mon mari, samedi dernier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« De quelle couleur ? » porte sur **la couleur**. Seule A « gris métallisé » donne une couleur. B donne **le lieu d''achat**. C donne **le prix**. D donne **l''accompagnant et le moment**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/0538a8cb-f96f-4e77-974d-b764ff4995f1.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:51:06.518886+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:11.74471+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Ton petit-fils a quel âge maintenant ?
[Homme] ...

A. À l''école primaire, en CE2.
B. Huit ans, depuis le mois dernier.
C. Pour son anniversaire de septembre.
D. Avec ses deux grandes sœurs.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton petit-fils a quel âge maintenant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''école primaire, en CE2.<break time="700ms"/>B.<break time="300ms"/>Huit ans, depuis le mois dernier.<break time="700ms"/>C.<break time="300ms"/>Pour son anniversaire de septembre.<break time="700ms"/>D.<break time="300ms"/>Avec ses deux grandes sœurs.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel âge ? » porte sur **l''âge**. Seule B « huit ans » donne un âge. A donne **la classe scolaire** (niveau, pas âge). C donne **un moment**. D donne **la fratrie**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/ebb30a07-298c-4746-82be-c341d926f3f2.mp3',
   '28', 'fr-FR-DeniseNeural', '2026-05-31 16:51:06.899388+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:16.484958+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] C''est où, ton lieu de naissance ?
[Femme] ...

A. En mille neuf cent quatre-vingt-cinq exactement.
B. Avec mes parents et ma grande sœur.
C. À Lyon, dans le deuxième arrondissement.
D. Pour des raisons familiales, à l''époque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est où, ton lieu de naissance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En mille neuf cent quatre-vingt-cinq exactement.<break time="700ms"/>B.<break time="300ms"/>Avec mes parents et ma grande sœur.<break time="700ms"/>C.<break time="300ms"/>À Lyon, dans le deuxième arrondissement.<break time="700ms"/>D.<break time="300ms"/>Pour des raisons familiales, à l''époque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« C''est où, ton lieu de naissance ? » porte sur **la ville / le lieu de naissance**. Seule C « à Lyon » donne un lieu. A donne **l''année de naissance**. B donne **la famille présente**. D donne **la cause**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/d70934b8-aeb7-4f26-9059-242f4e96a1b0.mp3',
   '29', 'fr-FR-HenriNeural', '2026-05-31 16:51:07.204656+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:12.985998+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000010', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as ton cours de yoga quel jour ?
[Homme] ...

A. Au centre sportif, près du parc.
B. Avec une professeure très douce.
C. Pour me détendre après le travail.
D. Le mardi soir, de dix-huit à dix-neuf heures.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as ton cours de yoga quel jour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au centre sportif, près du parc.<break time="700ms"/>B.<break time="300ms"/>Avec une professeure très douce.<break time="700ms"/>C.<break time="300ms"/>Pour me détendre après le travail.<break time="700ms"/>D.<break time="300ms"/>Le mardi soir, de dix-huit à dix-neuf heures.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel jour ? » porte sur **le jour de la semaine**. Seule D « le mardi soir » nomme un jour. A donne **le lieu**. B donne **la personne qui enseigne**. C donne **le but / l''effet recherché**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/40622d1e-6287-43c7-b39b-c2b0df6d69c4.mp3',
   '29', 'fr-FR-DeniseNeural', '2026-05-31 16:51:07.568973+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:17.387115+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000011', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quel temps fait-il dehors, ce matin ?
[Femme] ...

A. Un grand soleil et plutôt chaud.
B. Vers le parc Monceau, en face.
C. Pour la promenade du chien.
D. Avec mon parapluie, au cas où.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel temps fait-il dehors, ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un grand soleil et plutôt chaud.<break time="700ms"/>B.<break time="300ms"/>Vers le parc Monceau, en face.<break time="700ms"/>C.<break time="300ms"/>Pour la promenade du chien.<break time="700ms"/>D.<break time="300ms"/>Avec mon parapluie, au cas où.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel temps fait-il ? » porte sur **la météo**. Seule A « un grand soleil et plutôt chaud » décrit le temps. B donne **un lieu**. C donne **un but**. D donne **un accessoire**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/5bffc7c7-4b0f-4f84-8180-d71410f1d7e5.mp3',
   '28', 'fr-FR-HenriNeural', '2026-05-31 16:51:07.835387+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:13.721722+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000012', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu trouves comment, cette nouvelle sauce ?
[Homme] ...

A. Pour accompagner les pâtes.
B. Plutôt épicée, mais délicieuse.
C. Avec les boulettes, à midi.
D. Au supermarché en bas de chez moi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu trouves comment, cette nouvelle sauce ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour accompagner les pâtes.<break time="700ms"/>B.<break time="300ms"/>Plutôt épicée, mais délicieuse.<break time="700ms"/>C.<break time="300ms"/>Avec les boulettes, à midi.<break time="700ms"/>D.<break time="300ms"/>Au supermarché en bas de chez moi.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu trouves comment ? » porte sur **le goût / l''appréciation**. Seule B « plutôt épicée, mais délicieuse » qualifie le goût. A donne **l''usage**. C donne **l''accompagnement et le moment**. D donne **le lieu d''achat**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/f63032c2-e226-4f15-803e-a3a261412258.mp3',
   '28', 'fr-FR-DeniseNeural', '2026-05-31 16:51:08.155205+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:17.996864+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000013', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Où tu habites maintenant, exactement ?
[Femme] ...

A. Depuis trois mois seulement.
B. Avec ma sœur et son chat.
C. Rue de la Pompe, à Paris seizième.
D. Pour me rapprocher du travail.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où tu habites maintenant, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis trois mois seulement.<break time="700ms"/>B.<break time="300ms"/>Avec ma sœur et son chat.<break time="700ms"/>C.<break time="300ms"/>Rue de la Pompe, à Paris seizième.<break time="700ms"/>D.<break time="300ms"/>Pour me rapprocher du travail.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Où tu habites ? » porte sur **l''adresse / le lieu d''habitation**. Seule C « rue de la Pompe, à Paris seizième » donne une adresse. A donne **depuis quand**. B donne **avec qui**. D donne **la raison du choix**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/93538deb-f352-4fbf-aeba-5a875f50e07b.mp3',
   '27', 'fr-FR-HenriNeural', '2026-05-31 16:51:08.473316+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:14.337302+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-2000-0000-000000000014', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel est ton fruit préféré ?
[Homme] ...

A. Au marché du dimanche matin.
B. Pour la salade de fruits du dimanche.
C. Avec un peu de sucre dessus.
D. La fraise, sans hésiter une seconde.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton fruit préféré ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au marché du dimanche matin.<break time="700ms"/>B.<break time="300ms"/>Pour la salade de fruits du dimanche.<break time="700ms"/>C.<break time="300ms"/>Avec un peu de sucre dessus.<break time="700ms"/>D.<break time="300ms"/>La fraise, sans hésiter une seconde.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton fruit préféré ? » porte sur **le choix d''un fruit**. Seule D « la fraise, sans hésiter » nomme un fruit. A donne **le lieu d''achat**. B donne **l''usage culinaire**. C donne **un accompagnement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/a68049c2-0d01-486f-8e96-1ca8dc6fd4b0.mp3',
   '28', 'fr-FR-DeniseNeural', '2026-05-31 16:51:08.761333+02', 'a0640d15-33c5-4164-89e7-128bf60cd6a3',
   '2026-05-27 17:40:30.340062+02', '2026-05-31 16:51:19.601882+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-0022-3000-0000-000000000001', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quelle boisson tu prends, au petit-déjeuner ?
[Femme] ...

A. Un grand café au lait, sans sucre.
B. Vers sept heures du matin.
C. Dans la cuisine, debout.
D. Pour bien commencer la journée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle boisson tu prends, au petit-déjeuner ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un grand café au lait, sans sucre.<break time="700ms"/>B.<break time="300ms"/>Vers sept heures du matin.<break time="700ms"/>C.<break time="300ms"/>Dans la cuisine, debout.<break time="700ms"/>D.<break time="300ms"/>Pour bien commencer la journée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle boisson tu prends ? » porte sur **le type de boisson**. Seule A « un grand café au lait » nomme une boisson. B donne **l''heure** (« à quelle heure ? »). C donne **le lieu**. D donne **la raison / le but**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000002', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel style de vêtements tu aimes porter ?
[Homme] ...

A. Au centre commercial, en général.
B. Plutôt décontracté, jean et tee-shirt.
C. Pour aller travailler au bureau.
D. Avec ma sœur, qui me conseille.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel style de vêtements tu aimes porter ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au centre commercial, en général.<break time="700ms"/>B.<break time="300ms"/>Plutôt décontracté, jean et tee-shirt.<break time="700ms"/>C.<break time="300ms"/>Pour aller travailler au bureau.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur, qui me conseille.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel style de vêtements ? » porte sur **le type / le style vestimentaire**. Seule B « décontracté, jean et tee-shirt » décrit un style. A donne **le lieu d''achat**. C donne **le contexte d''usage**. D donne **l''accompagnant pour faire les courses**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000003', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Ton nouveau voisin, il est de quelle nationalité ?
[Femme] ...

A. À l''appartement juste au-dessus.
B. Pour son travail à Paris.
C. Italien, de la région de Milan.
D. Depuis le mois dernier, je crois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ton nouveau voisin, il est de quelle nationalité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''appartement juste au-dessus.<break time="700ms"/>B.<break time="300ms"/>Pour son travail à Paris.<break time="700ms"/>C.<break time="300ms"/>Italien, de la région de Milan.<break time="700ms"/>D.<break time="300ms"/>Depuis le mois dernier, je crois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« De quelle nationalité ? » porte sur **la nationalité**. Seule C « italien, de la région de Milan » donne une nationalité. A donne **le lieu** d''habitation. B donne **la raison** de sa venue. D donne **depuis quand** il est là.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000004', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel sport tu fais en ce moment ?
[Homme] ...

A. Avec deux amis du quartier.
B. Pour rester en bonne forme.
C. Au gymnase de l''école, le samedi.
D. Du basket-ball, deux fois par semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel sport tu fais en ce moment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux amis du quartier.<break time="700ms"/>B.<break time="300ms"/>Pour rester en bonne forme.<break time="700ms"/>C.<break time="300ms"/>Au gymnase de l''école, le samedi.<break time="700ms"/>D.<break time="300ms"/>Du basket-ball, deux fois par semaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel sport tu fais ? » porte sur **la discipline sportive**. Seule D « du basket-ball » nomme un sport. A donne **les partenaires**. B donne **le but / la raison**. C donne **le lieu et le jour**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000005', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as quel animal à la maison ?
[Femme] ...

A. Un petit lapin nain, très mignon.
B. Depuis presque deux ans déjà.
C. Avec ma fille, qui s''en occupe.
D. Dans une grande cage du salon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as quel animal à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un petit lapin nain, très mignon.<break time="700ms"/>B.<break time="300ms"/>Depuis presque deux ans déjà.<break time="700ms"/>C.<break time="300ms"/>Avec ma fille, qui s''en occupe.<break time="700ms"/>D.<break time="300ms"/>Dans une grande cage du salon.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel animal ? » porte sur **l''espèce de l''animal de compagnie**. Seule A « un petit lapin nain » nomme un animal. B donne **depuis quand**. C donne **avec qui** on s''en occupe. D donne **le lieu** où il vit.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000006', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quelle est ta saison préférée, finalement ?
[Homme] ...

A. À la montagne, presque toujours.
B. Le printemps, pour les fleurs et la douceur.
C. Avec toute ma petite famille.
D. Pour faire de longues balades à pied.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle est ta saison préférée, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la montagne, presque toujours.<break time="700ms"/>B.<break time="300ms"/>Le printemps, pour les fleurs et la douceur.<break time="700ms"/>C.<break time="300ms"/>Avec toute ma petite famille.<break time="700ms"/>D.<break time="300ms"/>Pour faire de longues balades à pied.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle est ta saison préférée ? » porte sur **le choix d''une saison**. Seule B « le printemps » nomme une saison. A donne **le lieu** des vacances. C donne **l''accompagnant**. D donne **une activité préférée**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000007', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] En quel mois tu es née, déjà ?
[Femme] ...

A. Avec mes deux frères jumeaux.
B. À l''hôpital de Bordeaux.
C. En octobre, juste avant Halloween.
D. Depuis bientôt trente-deux ans.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">En quel mois tu es née, déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mes deux frères jumeaux.<break time="700ms"/>B.<break time="300ms"/>À l''hôpital de Bordeaux.<break time="700ms"/>C.<break time="300ms"/>En octobre, juste avant Halloween.<break time="700ms"/>D.<break time="300ms"/>Depuis bientôt trente-deux ans.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« En quel mois tu es née ? » porte sur **le mois de naissance**. Seule C « en octobre » nomme un mois. A donne **la fratrie présente**. B donne **le lieu** de naissance. D donne **l''âge** approximatif.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000008', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel est ton numéro de téléphone, s''il te plaît ?
[Homme] ...

A. Chez l''opérateur Orange, depuis longtemps.
B. Pour te joindre plus facilement.
C. Avec un forfait sans engagement.
D. Le zéro six, douze, trente-quatre, cinquante-six, soixante-dix-huit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton numéro de téléphone, s''il te plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Chez l''opérateur Orange, depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour te joindre plus facilement.<break time="700ms"/>C.<break time="300ms"/>Avec un forfait sans engagement.<break time="700ms"/>D.<break time="300ms"/>Le zéro six, douze, trente-quatre, cinquante-six, soixante-dix-huit.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton numéro de téléphone ? » porte sur **la suite de chiffres**. Seule D énonce un numéro complet. A donne **l''opérateur**. B donne **le but** de la demande. C donne **le type de forfait**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000009', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quelle marque de chaussures tu achètes d''habitude ?
[Femme] ...

A. Toujours la marque Bensimon, je les adore.
B. Au magasin de la rue Saint-Antoine.
C. Pour le sport et la marche en ville.
D. Environ tous les six mois, en général.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle marque de chaussures tu achètes d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Toujours la marque Bensimon, je les adore.<break time="700ms"/>B.<break time="300ms"/>Au magasin de la rue Saint-Antoine.<break time="700ms"/>C.<break time="300ms"/>Pour le sport et la marche en ville.<break time="700ms"/>D.<break time="300ms"/>Environ tous les six mois, en général.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle marque tu achètes ? » porte sur **le nom de marque**. Seule A « Bensimon » désigne une marque. B donne **le lieu d''achat**. C donne **l''usage** des chaussures. D donne **la fréquence** d''achat.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel genre de films tu aimes regarder ?
[Homme] ...

A. Au cinéma du centre-ville, souvent.
B. Surtout les comédies romantiques.
C. Avec ma copine, le vendredi soir.
D. Pour me détendre après le travail.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel genre de films tu aimes regarder ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cinéma du centre-ville, souvent.<break time="700ms"/>B.<break time="300ms"/>Surtout les comédies romantiques.<break time="700ms"/>C.<break time="300ms"/>Avec ma copine, le vendredi soir.<break time="700ms"/>D.<break time="300ms"/>Pour me détendre après le travail.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel genre de films ? » porte sur **la catégorie / le type de film**. Seule B « les comédies romantiques » désigne un genre. A donne **le lieu** où on les voit. C donne **avec qui et quand**. D donne **le but / la raison**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL);
