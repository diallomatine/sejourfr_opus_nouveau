-- ============================================================
-- 10 exercices B1 - CO TCF - format "réponse à question implicite"
-- Dialogues de 2 à 3 tours (alternance Henri / Denise),
-- contextes variés (quotidien, administratif, familial,
-- commercial, voyage, social, sport, culturel) et 10 types
-- de question implicite différents.
-- ============================================================

-- ----- Exercice 1 : Manière (« comment ? ») / contexte quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000001', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as enfin réussi à monter ton étagère toute seule ?\n[Femme] Oui, hier après-midi.\n[Homme] Mais tu as fait comment ?\n[Femme] ...\n\nA. Pendant deux heures environ.\nB. En suivant la notice étape par étape.\nC. Parce que j''en avais vraiment besoin.\nD. Dans le salon, contre le mur.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as enfin réussi à monter ton étagère toute seule ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, hier après-midi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais tu as fait comment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux heures environ.<break time="700ms"/>B.<break time="300ms"/>En suivant la notice étape par étape.<break time="700ms"/>C.<break time="300ms"/>Parce que j''en avais vraiment besoin.<break time="700ms"/>D.<break time="300ms"/>Dans le salon, contre le mur.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours plantent le contexte (le montage est terminé). La question finale « tu as fait comment ? » porte sur **la manière, la méthode employée**. Seule B « en suivant la notice étape par étape » (gérondif de moyen) y répond. A indique une **durée** (« combien de temps cela t''a-t-il pris ? »). C indique une **cause / motivation** (« pourquoi l''as-tu montée ? »). D indique un **lieu** (« où l''as-tu installée ? »). Piège B1 : les quatre réponses parlent bien du montage, seule la nature de la question (« comment ») permet de trancher.',
    '[
       {"label": "Pendant deux heures environ.", "is_correct": false, "display_order": 1},
       {"label": "En suivant la notice étape par étape.", "is_correct": true, "display_order": 2},
       {"label": "Parce que j''en avais vraiment besoin.", "is_correct": false, "display_order": 3},
       {"label": "Dans le salon, contre le mur.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Moment précis (« quand ? ») / contexte administratif / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000002', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Ça y est, ton rendez-vous à la préfecture est confirmé.\n[Homme] Oui. Et c''est pour quand exactement ?\n[Femme] ...\n\nA. Au guichet numéro quatre.\nB. Pour renouveler mon titre de séjour.\nC. Mercredi prochain, à dix heures.\nD. Avec ma sœur qui m''accompagne.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ça y est, ton rendez-vous à la préfecture est confirmé.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui. Et c''est pour quand exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet numéro quatre.<break time="700ms"/>B.<break time="300ms"/>Pour renouveler mon titre de séjour.<break time="700ms"/>C.<break time="300ms"/>Mercredi prochain, à dix heures.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur qui m''accompagne.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le sujet (un rendez-vous à la préfecture, déjà confirmé) ; le second contient la question implicite « pour quand exactement ? » qui porte sur **un moment précis**. Seule C « mercredi prochain, à dix heures » donne un point dans le temps. A indique un **lieu** dans la préfecture (« à quel guichet ? »). B exprime un **but / motif** (« pour quoi faire ? »). D précise l''**accompagnant** (« avec qui y vas-tu ? »). Toutes les réponses restent dans le champ administratif, ce qui rend le piège B1 réaliste.',
    '[
       {"label": "Au guichet numéro quatre.", "is_correct": false, "display_order": 1},
       {"label": "Pour renouveler mon titre de séjour.", "is_correct": false, "display_order": 2},
       {"label": "Mercredi prochain, à dix heures.", "is_correct": true, "display_order": 3},
       {"label": "Avec ma sœur qui m''accompagne.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Cause (« pourquoi ? ») / contexte familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000003', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Léa a pleuré toute la soirée hier.\n[Homme] Vraiment ? Elle qui est si calme d''habitude.\n[Femme] Tu sais pourquoi ?\n[Homme] ...\n\nA. Pendant plus d''une heure, je crois.\nB. À cause d''une dispute avec sa sœur.\nC. Pour qu''on lui prête un peu d''attention.\nD. Dans sa chambre, toute seule.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Léa a pleuré toute la soirée hier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vraiment ? Elle qui est si calme d''habitude.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais pourquoi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant plus d''une heure, je crois.<break time="700ms"/>B.<break time="300ms"/>À cause d''une dispute avec sa sœur.<break time="700ms"/>C.<break time="300ms"/>Pour qu''on lui prête un peu d''attention.<break time="700ms"/>D.<break time="300ms"/>Dans sa chambre, toute seule.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours installent l''étonnement (Léa pleure alors qu''elle est calme d''habitude), le troisième pose la question implicite « pourquoi ? », qui porte sur **la cause, ce qui a déclenché les pleurs**. Seule B « à cause d''une dispute » donne une cause antérieure. A donne une **durée** (« combien de temps a-t-elle pleuré ? »). C donne un **but** (« dans quel objectif pleurait-elle ? ») — piège B1 classique : confusion cause / but. D donne un **lieu** (« où était-elle ? »).',
    '[
       {"label": "Pendant plus d''une heure, je crois.", "is_correct": false, "display_order": 1},
       {"label": "À cause d''une dispute avec sa sœur.", "is_correct": true, "display_order": 2},
       {"label": "Pour qu''on lui prête un peu d''attention.", "is_correct": false, "display_order": 3},
       {"label": "Dans sa chambre, toute seule.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Lieu (« où ? ») / contexte commercial / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000004', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai enfin trouvé une superbe robe pour le mariage de ma cousine !\n[Femme] Ah, génial. Tu l''as dénichée où ?\n[Homme] ...\n\nA. Avec ma mère, samedi dernier.\nB. Plutôt longue, avec des manches.\nC. Pour environ quatre-vingts euros.\nD. Dans une petite boutique du centre-ville.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai enfin trouvé une superbe robe pour le mariage de ma cousine !</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ah, génial. Tu l''as dénichée où ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec ma mère, samedi dernier.<break time="700ms"/>B.<break time="300ms"/>Plutôt longue, avec des manches.<break time="700ms"/>C.<break time="300ms"/>Pour environ quatre-vingts euros.<break time="700ms"/>D.<break time="300ms"/>Dans une petite boutique du centre-ville.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour fixe le sujet (une robe pour un mariage déjà trouvée) ; le second pose la question implicite « tu l''as dénichée où ? », qui porte sur **le lieu d''achat**. Seule D « dans une petite boutique du centre-ville » désigne un lieu. A donne un **accompagnant et un moment** (« avec qui et quand ? »). B donne une **description** de la robe (« comment est-elle ? »). C donne un **prix** (« combien l''as-tu payée ? »). Toutes les pistes restent crédibles dans un échange sur les achats.',
    '[
       {"label": "Avec ma mère, samedi dernier.", "is_correct": false, "display_order": 1},
       {"label": "Plutôt longue, avec des manches.", "is_correct": false, "display_order": 2},
       {"label": "Pour environ quatre-vingts euros.", "is_correct": false, "display_order": 3},
       {"label": "Dans une petite boutique du centre-ville.", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Quantité (« combien ? ») / contexte quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000005', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fait toutes les courses pour la fête de ce soir ?\n[Homme] Oui, je rentre tout juste du supermarché.\n[Femme] Et tu as pris combien de bouteilles de vin ?\n[Homme] ...\n\nA. Du rouge et un peu de blanc.\nB. Six, comme on s''était dit.\nC. Pour à peu près trente euros.\nD. Chez le caviste de la place.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fait toutes les courses pour la fête de ce soir ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je rentre tout juste du supermarché.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as pris combien de bouteilles de vin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du rouge et un peu de blanc.<break time="700ms"/>B.<break time="300ms"/>Six, comme on s''était dit.<break time="700ms"/>C.<break time="300ms"/>Pour à peu près trente euros.<break time="700ms"/>D.<break time="300ms"/>Chez le caviste de la place.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours fixent le contexte (les courses sont déjà faites). La question implicite « combien de bouteilles ? » porte sur **un nombre**. Seule B « six » donne une quantité. A renvoie au **type de vin** (« quel vin ? »). C renvoie au **prix total** (« combien as-tu dépensé ? »). D renvoie au **lieu d''achat** (« où les as-tu achetées ? ») — piège B1 : le contexte mentionne le supermarché, mais le caviste reste plausible. Seul B répond bien à « combien ».',
    '[
       {"label": "Du rouge et un peu de blanc.", "is_correct": false, "display_order": 1},
       {"label": "Six, comme on s''était dit.", "is_correct": true, "display_order": 2},
       {"label": "Pour à peu près trente euros.", "is_correct": false, "display_order": 3},
       {"label": "Chez le caviste de la place.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Durée (« combien de temps ? ») / contexte voyage / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000006', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu reviens tout juste d''Italie, c''est ça ?\n[Femme] Oui ! Et toi, tu y étais resté combien de temps déjà ?\n[Homme] ...\n\nA. Trois semaines, l''été dernier.\nB. À Rome surtout, puis à Florence.\nC. Avec deux amis de la fac.\nD. Pour voir tous les musées possibles.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens tout juste d''Italie, c''est ça ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui ! Et toi, tu y étais resté combien de temps déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois semaines, l''été dernier.<break time="700ms"/>B.<break time="300ms"/>À Rome surtout, puis à Florence.<break time="700ms"/>C.<break time="300ms"/>Avec deux amis de la fac.<break time="700ms"/>D.<break time="300ms"/>Pour voir tous les musées possibles.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le contexte (le retour d''Italie de l''interlocutrice) ; le second contient la question implicite « combien de temps ? », qui porte sur **la durée d''un séjour passé**. Seule A « trois semaines » exprime une durée. B donne le **lieu / les villes visitées** (« où es-tu allé ? »). C donne l''**accompagnant** (« avec qui ? »). D donne le **but du voyage** (« pourquoi y es-tu allé ? »). Piège B1 : A contient « l''été dernier » qui ressemble à un moment, mais la durée principale est bien « trois semaines ».',
    '[
       {"label": "Trois semaines, l''été dernier.", "is_correct": true, "display_order": 1},
       {"label": "À Rome surtout, puis à Florence.", "is_correct": false, "display_order": 2},
       {"label": "Avec deux amis de la fac.", "is_correct": false, "display_order": 3},
       {"label": "Pour voir tous les musées possibles.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Accompagnant (« avec qui ? ») / contexte social / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000007', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''étais à un concert génial hier soir.\n[Femme] Ah, super ! Tu y étais avec qui ?\n[Homme] ...\n\nA. À la salle Pleyel, à Paris.\nB. Avec ma sœur et son copain.\nC. Jusqu''à minuit, environ.\nD. Parce que j''adore ce groupe depuis longtemps.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''étais à un concert génial hier soir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ah, super ! Tu y étais avec qui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la salle Pleyel, à Paris.<break time="700ms"/>B.<break time="300ms"/>Avec ma sœur et son copain.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à minuit, environ.<break time="700ms"/>D.<break time="300ms"/>Parce que j''adore ce groupe depuis longtemps.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour mentionne le concert ; le second pose la question implicite « avec qui ? », qui porte sur **l''accompagnant**. Seule B « avec ma sœur et son copain » désigne des personnes. A donne le **lieu** (« où était-ce ? »). C donne un **moment / fin** (« jusqu''à quelle heure ? »). D donne la **cause** (« pourquoi y es-tu allé ? »). Toutes restent dans le champ « concert », ce qui en fait des distracteurs réalistes pour B1.',
    '[
       {"label": "À la salle Pleyel, à Paris.", "is_correct": false, "display_order": 1},
       {"label": "Avec ma sœur et son copain.", "is_correct": true, "display_order": 2},
       {"label": "Jusqu''à minuit, environ.", "is_correct": false, "display_order": 3},
       {"label": "Parce que j''adore ce groupe depuis longtemps.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Préférence (« lequel ? ») / contexte quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000008', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] J''hésite entre les deux paires de chaussures pour le mariage.\n[Homme] Montre-moi, voir.\n[Femme] Alors, tu préfères laquelle ?\n[Homme] ...\n\nA. La noire, sans hésiter, elle est plus chic.\nB. Chez un cordonnier près du métro.\nC. Environ soixante euros la paire.\nD. Plutôt pour aller travailler, en fait.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">J''hésite entre les deux paires de chaussures pour le mariage.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Montre-moi, voir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, tu préfères laquelle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La noire, sans hésiter, elle est plus chic.<break time="700ms"/>B.<break time="300ms"/>Chez un cordonnier près du métro.<break time="700ms"/>C.<break time="300ms"/>Environ soixante euros la paire.<break time="700ms"/>D.<break time="300ms"/>Plutôt pour aller travailler, en fait.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (hésitation entre deux paires, demande d''avis) prépare une question de **choix entre deux options proposées**. La question implicite « tu préfères laquelle ? » appelle l''identification d''une des deux. Seule A « la noire, sans hésiter » désigne un choix. B donne un **lieu d''achat possible** (« où en trouver ? »). C donne un **prix** (« combien coûtent-elles ? »). D donne un **usage** (« pour quoi faire ? »). Piège B1 : B, C, D restent crédibles dans une conversation sur des chaussures, mais aucune ne répond à « laquelle ».',
    '[
       {"label": "La noire, sans hésiter, elle est plus chic.", "is_correct": true, "display_order": 1},
       {"label": "Chez un cordonnier près du métro.", "is_correct": false, "display_order": 2},
       {"label": "Environ soixante euros la paire.", "is_correct": false, "display_order": 3},
       {"label": "Plutôt pour aller travailler, en fait.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Fréquence (« à quel rythme ? ») / contexte sport / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-000000000009', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai vu que tu t''étais inscrite à la piscine.\n[Femme] Oui, depuis le mois dernier. Et toi, tu y vas à quelle fréquence ?\n[Homme] ...\n\nA. Deux fois par semaine, en moyenne.\nB. Pendant une heure à chaque séance.\nC. Tout près de mon travail.\nD. Pour me remettre tranquillement en forme.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai vu que tu t''étais inscrite à la piscine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, depuis le mois dernier. Et toi, tu y vas à quelle fréquence ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Deux fois par semaine, en moyenne.<break time="700ms"/>B.<break time="300ms"/>Pendant une heure à chaque séance.<break time="700ms"/>C.<break time="300ms"/>Tout près de mon travail.<break time="700ms"/>D.<break time="300ms"/>Pour me remettre tranquillement en forme.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le sujet (la piscine), le second précise la durée d''inscription puis pose la question implicite « à quelle fréquence ? », qui porte sur **le rythme, la régularité**. Seule A « deux fois par semaine » exprime une fréquence. B exprime une **durée d''une séance** (« combien de temps restes-tu ? »). C exprime un **lieu** (« où se trouve la piscine ? »). D exprime un **but** (« pourquoi y vas-tu ? »). Piège B1 : A et B mélangent souvent dans l''oreille des candidats, car les deux donnent une indication temporelle.',
    '[
       {"label": "Deux fois par semaine, en moyenne.", "is_correct": true, "display_order": 1},
       {"label": "Pendant une heure à chaque séance.", "is_correct": false, "display_order": 2},
       {"label": "Tout près de mon travail.", "is_correct": false, "display_order": 3},
       {"label": "Pour me remettre tranquillement en forme.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Opinion (« qu''en penses-tu ? ») / contexte culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-1000-0000-00000000000a', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as fini de lire le roman que je t''avais prêté ?\n[Femme] Oui, hier soir.\n[Homme] Et alors, tu en as pensé quoi ?\n[Femme] ...\n\nA. Sur ma table de chevet, tranquillement.\nB. En deux semaines, à peu près.\nC. À ma grande surprise, beaucoup de bien.\nD. Surtout dans le métro, le matin.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as fini de lire le roman que je t''avais prêté ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, hier soir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et alors, tu en as pensé quoi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur ma table de chevet, tranquillement.<break time="700ms"/>B.<break time="300ms"/>En deux semaines, à peu près.<break time="700ms"/>C.<break time="300ms"/>À ma grande surprise, beaucoup de bien.<break time="700ms"/>D.<break time="300ms"/>Surtout dans le métro, le matin.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours fixent le contexte (lecture du roman terminée), le troisième pose la question implicite « tu en as pensé quoi ? », qui demande **une opinion, un jugement de valeur**. Seule C « beaucoup de bien » exprime une appréciation. A donne un **lieu de lecture** (« où l''as-tu lu ? »). B donne une **durée de lecture** (« en combien de temps l''as-tu lu ? »). D donne un **moment / contexte de lecture** (« quand le lisais-tu ? »). Piège B1 : trois distracteurs parlent de la lecture mais aucun ne livre un avis.',
    '[
       {"label": "Sur ma table de chevet, tranquillement.", "is_correct": false, "display_order": 1},
       {"label": "En deux semaines, à peu près.", "is_correct": false, "display_order": 2},
       {"label": "À ma grande surprise, beaucoup de bien.", "is_correct": true, "display_order": 3},
       {"label": "Surtout dans le métro, le matin.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
