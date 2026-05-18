-- ============================================================
-- 10 exercices B2 - CO TCF - format "réponse à question implicite"
-- ============================================================

-- ----- Exercice 1 : Question sur la manière / le moyen -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000001', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Comment êtes-vous parvenu à finaliser le dossier aussi vite ?\n[Femme] ...\n\nA. Dès la semaine dernière.\nB. En sollicitant toute l''équipe.\nC. Parce que c''était urgent.\nD. Avec beaucoup de satisfaction.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment êtes-vous parvenu à finaliser le dossier aussi vite ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dès la semaine dernière.<break time="700ms"/>B.<break time="300ms"/>En sollicitant toute l''équipe.<break time="700ms"/>C.<break time="300ms"/>Parce que c''était urgent.<break time="700ms"/>D.<break time="300ms"/>Avec beaucoup de satisfaction.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'La question « comment êtes-vous parvenu à... » porte sur **la manière, le moyen utilisé**. Seule la réponse B « en sollicitant toute l''équipe » (gérondif de moyen) répond à cette question. A répond à « quand avez-vous commencé ? » (moment). C répond à « pourquoi êtes-vous allé si vite ? » (cause). D répond à « qu''avez-vous ressenti ? » (émotion). Le piège B2 : les quatre réponses sont parfaitement naturelles dans un échange professionnel, il faut identifier précisément la nature de la question.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": true, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-HenriNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 2 : Question sur la condition -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000002', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] À quelles conditions accepteriez-vous de reprendre ce poste ?\n[Homme] ...\n\nA. Depuis bientôt trois ans.\nB. Sans hésiter une seconde.\nC. À condition d''obtenir plus d''autonomie.\nD. Parce que j''en garde un bon souvenir.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À quelles conditions accepteriez-vous de reprendre ce poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis bientôt trois ans.<break time="700ms"/>B.<break time="300ms"/>Sans hésiter une seconde.<break time="700ms"/>C.<break time="300ms"/>À condition d''obtenir plus d''autonomie.<break time="700ms"/>D.<break time="300ms"/>Parce que j''en garde un bon souvenir.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'La question « à quelles conditions... » exige une réponse exprimant **une condition, une exigence préalable**. Seule la réponse C « à condition d''obtenir plus d''autonomie » répond directement avec le marqueur de condition correspondant. A répond à « depuis combien de temps êtes-vous parti ? » (durée). B répond à « comment réagiriez-vous à une offre ? » (manière/attitude). D répond à « pourquoi y reviendriez-vous ? » (cause/motivation). Difficulté B2 : B et D sont très tentantes car positives, mais elles ne formulent aucune condition.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": false, "display_order": 2},
               {"label": "C", "is_correct": true, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 3 : Question sur la durée vs fréquence -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000003', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu fréquentes cet endroit régulièrement ?\n[Femme] ...\n\nA. Pendant environ deux heures.\nB. À peu près tous les quinze jours.\nC. Depuis l''ouverture en 2019.\nD. Plutôt en début de soirée.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fréquentes cet endroit régulièrement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant environ deux heures.<break time="700ms"/>B.<break time="300ms"/>À peu près tous les quinze jours.<break time="700ms"/>C.<break time="300ms"/>Depuis l''ouverture en 2019.<break time="700ms"/>D.<break time="300ms"/>Plutôt en début de soirée.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'L''adverbe « régulièrement » oriente la question vers **la fréquence** (à quel rythme). Seule la réponse B « tous les quinze jours » exprime une fréquence. A exprime une durée d''une visite (« pendant deux heures » répond à « combien de temps y restes-tu ? »). C exprime un point de départ dans le temps (« depuis quand y vas-tu ? »). D exprime un moment habituel (« à quel moment y vas-tu ? »). Toutes les réponses concernent le temps, c''est le type précis de référence temporelle qui les distingue.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": true, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-HenriNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 4 : Question sur la cause (vs conséquence) -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000004', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Qu''est-ce qui t''a poussé à changer de carrière ?\n[Homme] ...\n\nA. Du coup, j''ai gagné en sérénité.\nB. Une lassitude profonde envers mon ancien métier.\nC. Pour me consacrer davantage à ma famille.\nD. Au bout d''une longue réflexion.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui t''a poussé à changer de carrière ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du coup, j''ai gagné en sérénité.<break time="700ms"/>B.<break time="300ms"/>Une lassitude profonde envers mon ancien métier.<break time="700ms"/>C.<break time="300ms"/>Pour me consacrer davantage à ma famille.<break time="700ms"/>D.<break time="300ms"/>Au bout d''une longue réflexion.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« Qu''est-ce qui t''a poussé... » est une question sur **la cause, le facteur déclenchant** (ce qui a précédé et provoqué). B « une lassitude profonde » désigne précisément cette cause. A exprime une **conséquence** (« du coup » = donc), donc répond à « qu''est-ce que ça t''a apporté ? ». C exprime un **but** (« pour » = finalité), donc répond à « dans quel objectif l''as-tu fait ? ». D exprime un cadre temporel (« au bout de » = après combien de temps). Le piège B2 majeur : confondre cause et but est très fréquent — la cause est antérieure et subie, le but est postérieur et voulu.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": true, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 5 : Question sur l'opinion / jugement -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000005', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Que penses-tu de la dernière exposition du musée ?\n[Femme] ...\n\nA. À deux pas du centre-ville.\nB. Avec une amie de longue date.\nC. Plutôt décevante, à vrai dire.\nD. Jusqu''à la fin du mois prochain.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Que penses-tu de la dernière exposition du musée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À deux pas du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Avec une amie de longue date.<break time="700ms"/>C.<break time="300ms"/>Plutôt décevante, à vrai dire.<break time="700ms"/>D.<break time="300ms"/>Jusqu''à la fin du mois prochain.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« Que penses-tu de... » est une demande d''**opinion, de jugement de valeur**. Seule C « plutôt décevante » exprime une appréciation. A localise (« où se trouve le musée ? »). B précise un accompagnant (« avec qui y es-tu allée ? »). D indique une durée future (« jusqu''à quand est-elle visible ? »). Difficulté B2 : toutes les réponses sont cohérentes avec le thème « exposition », ce qui peut tromper un candidat qui se contenterait d''un lien thématique.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": false, "display_order": 2},
               {"label": "C", "is_correct": true, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-HenriNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 6 : Question sur le destinataire / bénéficiaire -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000006', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] À qui ce rapport est-il finalement destiné ?\n[Homme] ...\n\nA. À la direction générale exclusivement.\nB. Par mes soins, dès demain matin.\nC. Sur la base des données du trimestre.\nD. En vue de la prochaine assemblée.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À qui ce rapport est-il finalement destiné ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la direction générale exclusivement.<break time="700ms"/>B.<break time="300ms"/>Par mes soins, dès demain matin.<break time="700ms"/>C.<break time="300ms"/>Sur la base des données du trimestre.<break time="700ms"/>D.<break time="300ms"/>En vue de la prochaine assemblée.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« À qui est destiné... » interroge sur **le destinataire**. Seule A « à la direction générale » désigne un destinataire. B identifie l''auteur (« par qui sera-t-il rédigé ? »). C indique la source des données (« sur quoi se base-t-il ? »). D exprime la finalité (« dans quel but est-il produit ? »). Le piège B2 : D « en vue de la prochaine assemblée » évoque un public final et peut être confondue avec un destinataire, mais elle exprime un objectif, pas une personne destinataire directe.',
             '[
               {"label": "A", "is_correct": true, "display_order": 1},
               {"label": "B", "is_correct": false, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 7 : Question sur la quantité / proportion -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000007', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quelle proportion des salariés a finalement adhéré au dispositif ?\n[Femme] ...\n\nA. Près des trois quarts d''entre eux.\nB. Notamment les cadres intermédiaires.\nC. Dans un délai relativement court.\nD. Grâce à une campagne d''information ciblée.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle proportion des salariés a finalement adhéré au dispositif ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près des trois quarts d''entre eux.<break time="700ms"/>B.<break time="300ms"/>Notamment les cadres intermédiaires.<break time="700ms"/>C.<break time="300ms"/>Dans un délai relativement court.<break time="700ms"/>D.<break time="300ms"/>Grâce à une campagne d''information ciblée.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« Quelle proportion... » appelle une **quantité chiffrée ou fractionnée**. Seule A « les trois quarts » exprime une proportion. B identifie une **catégorie concernée** (« lesquels ont adhéré ? »). C précise un délai (« en combien de temps ? »). D donne une cause/moyen (« comment ont-ils été convaincus ? »). Difficulté B2 : B est piégeuse car elle parle aussi des adhérents, mais elle répond à « qui ? » et non à « combien ? ».',
             '[
               {"label": "A", "is_correct": true, "display_order": 1},
               {"label": "B", "is_correct": false, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-HenriNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 8 : Question sur la fréquence (négative) -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000008', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu lui rends souvent visite, à ta grand-mère ?\n[Homme] ...\n\nA. Plutôt rarement, malheureusement.\nB. Elle habite dans le Sud-Ouest.\nC. Elle vient d''avoir quatre-vingt-cinq ans.\nD. Toujours avec un grand plaisir.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lui rends souvent visite, à ta grand-mère ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt rarement, malheureusement.<break time="700ms"/>B.<break time="300ms"/>Elle habite dans le Sud-Ouest.<break time="700ms"/>C.<break time="300ms"/>Elle vient d''avoir quatre-vingt-cinq ans.<break time="700ms"/>D.<break time="300ms"/>Toujours avec un grand plaisir.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'L''adverbe « souvent » oriente la question sur **la fréquence**. A « rarement » répond directement, c''est l''antonyme attendu. B répond à « où vit-elle ? ». C répond à « quel âge a-t-elle ? ». D « toujours avec plaisir » est un piège majeur en B2 : « toujours » ressemble à un adverbe de fréquence, mais ici il signifie « à chaque fois » au sens d''accompagnement émotionnel ; la réponse porte sur la manière (le ressenti), pas sur le rythme des visites. Il faut écouter la question, pas le mot isolé.',
             '[
               {"label": "A", "is_correct": true, "display_order": 1},
               {"label": "B", "is_correct": false, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 9 : Question sur la comparaison -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000009', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Qu''est-ce qui distingue ce modèle de l''ancien ?\n[Femme] ...\n\nA. À partir de mille deux cents euros.\nB. Une autonomie nettement supérieure.\nC. Disponible dès la rentrée prochaine.\nD. Conçu par une équipe française.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui distingue ce modèle de l''ancien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir de mille deux cents euros.<break time="700ms"/>B.<break time="300ms"/>Une autonomie nettement supérieure.<break time="700ms"/>C.<break time="300ms"/>Disponible dès la rentrée prochaine.<break time="700ms"/>D.<break time="300ms"/>Conçu par une équipe française.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« Qu''est-ce qui distingue X de Y » appelle un **élément différenciant, comparatif**. Seule B « une autonomie nettement supérieure » établit explicitement une comparaison (« supérieure » = comparatif). A donne un prix (« combien ça coûte ? »). C donne une date de disponibilité (« quand sera-t-il vendu ? »). D donne une origine (« où a-t-il été conçu ? »). Toutes ces caractéristiques sont vraies du modèle, mais aucune ne le **distingue** explicitement de l''ancien — seule B le fait par son comparatif.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": true, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-HenriNeural', 'TEXT_VALIDATED'
         );

-- ----- Exercice 10 : Question sur l'origine / la source -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
             '66666666-0022-1000-0000-000000000010', 'A2', 'co_dialogue_court_implicite',
             '22222222-0000-0000-0000-000000000001',
             E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] D''où tiens-tu cette information, au juste ?\n[Homme] ...\n\nA. Depuis hier soir seulement.\nB. D''un collègue bien renseigné.\nC. Dans les moindres détails.\nD. À ma plus grande surprise.',
             E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">D''où tiens-tu cette information, au juste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis hier soir seulement.<break time="700ms"/>B.<break time="300ms"/>D''un collègue bien renseigné.<break time="700ms"/>C.<break time="300ms"/>Dans les moindres détails.<break time="700ms"/>D.<break time="300ms"/>À ma plus grande surprise.</prosody></voice></speak>',
             E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
             E'« D''où tiens-tu... » interroge sur **la source, l''origine d''une information** (qui te l''a dite). Seule B « d''un collègue » désigne une source humaine. A indique le moment de l''apprentissage (« depuis quand le sais-tu ? »). C porte sur le degré de précision (« à quel point en sais-tu sur le sujet ? »). D exprime une réaction émotionnelle (« qu''as-tu ressenti en l''apprenant ? »). Le piège B2 principal : A commence aussi par « depuis » et peut sembler répondre à « d''où » de façon temporelle, mais « d''où » porte ici sur la source, pas sur le point de départ temporel.',
             '[
               {"label": "A", "is_correct": false, "display_order": 1},
               {"label": "B", "is_correct": true, "display_order": 2},
               {"label": "C", "is_correct": false, "display_order": 3},
               {"label": "D", "is_correct": false, "display_order": 4}
             ]'::jsonb,
             'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
         );