-- ============================================================
-- 20 exercices B2 (lot 2) - CO TCF - format "réponse à question implicite"
-- Dialogues de 3 à 4 tours (alternance Henri / Denise),
-- formulations indirectes / soutenues, 20 nouveaux types
-- de question implicite (différents de V402).
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- ============================================================

-- ----- Exercice 1 : Motivation profonde / quotidien sportif / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu te lèves vraiment à six heures tous les matins pour courir ?\n[Femme] Oui, ça fait deux mois maintenant.\n[Homme] Mais qu''est-ce qui te motive autant à tenir, dans la durée ?\n[Femme] ...\n\nA. Au lever du jour, dans le parc en bas.\nB. La sensation d''énergie qui rythme toute ma journée.\nC. Sur les conseils insistants de ma médecin.\nD. Pendant trois bons quarts d''heure environ.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu te lèves vraiment à six heures tous les matins pour courir ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça fait deux mois maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui te motive autant à tenir, dans la durée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lever du jour, dans le parc en bas.<break time="700ms"/>B.<break time="300ms"/>La sensation d''énergie qui rythme toute ma journée.<break time="700ms"/>C.<break time="300ms"/>Sur les conseils insistants de ma médecin.<break time="700ms"/>D.<break time="300ms"/>Pendant trois bons quarts d''heure environ.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (assiduité depuis deux mois) prépare une question sur **la motivation intérieure**. « Qu''est-ce qui te motive à tenir, dans la durée ? » appelle un ressort intrinsèque. Seule B « la sensation d''énergie qui rythme ma journée » décrit ce ressort. A donne **le moment et le lieu** de la pratique. C donne **l''origine extérieure** de la décision (« qui te l''a recommandé ? ») — piège B2 : C est une cause initiale, pas la motivation qui fait tenir au quotidien. D donne **la durée d''une sortie**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Réserves / limites (« quelles réserves ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu vas accepter le poste de directeur qu''on te propose ?\n[Homme] Sans doute, mais avec quelques réserves quand même.\n[Femme] Justement, quelles sont tes réserves principales ?\n[Homme] ...\n\nA. Une équipe d''environ vingt personnes à encadrer.\nB. La charge horaire trop importante annoncée.\nC. À partir du début du trimestre prochain.\nD. Pour relever un vrai défi de carrière.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vas accepter le poste de directeur qu''on te propose ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sans doute, mais avec quelques réserves quand même.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Justement, quelles sont tes réserves principales ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une équipe d''environ vingt personnes à encadrer.<break time="700ms"/>B.<break time="300ms"/>La charge horaire trop importante annoncée.<break time="700ms"/>C.<break time="300ms"/>À partir du début du trimestre prochain.<break time="700ms"/>D.<break time="300ms"/>Pour relever un vrai défi de carrière.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (acceptation probable, mais avec réserves) cadre la question. « Quelles sont tes réserves principales ? » appelle **un point négatif, une limite, un frein**. Seule B « la charge horaire trop importante » formule une réserve. A donne un **fait neutre** sur le poste (taille de l''équipe). C donne le **moment de prise de fonction**. D donne la **motivation à accepter** (« pourquoi acceptes-tu ? ») — piège B2 : D est le contraire d''une réserve.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Public visé (« à qui s'adresse ? ») / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous publiez un nouvel ouvrage le mois prochain, c''est cela ?\n[Femme] Oui, sur les enjeux du numérique en santé.\n[Homme] À qui s''adresse-t-il prioritairement, selon vous ?\n[Femme] ...\n\nA. Aux professionnels de la santé en exercice.\nB. Sur la base d''une longue enquête de terrain.\nC. Aux éditions du Seuil, comme toujours.\nD. Pour éclairer un débat encore confus.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous publiez un nouvel ouvrage le mois prochain, c''est cela ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, sur les enjeux du numérique en santé.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À qui s''adresse-t-il prioritairement, selon vous ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Aux professionnels de la santé en exercice.<break time="700ms"/>B.<break time="300ms"/>Sur la base d''une longue enquête de terrain.<break time="700ms"/>C.<break time="300ms"/>Aux éditions du Seuil, comme toujours.<break time="700ms"/>D.<break time="300ms"/>Pour éclairer un débat encore confus.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À qui s''adresse-t-il prioritairement ? » porte sur **le public cible, les destinataires-lecteurs**. Seule A « aux professionnels de la santé » désigne ce public. B donne **la méthode / la source** de l''ouvrage. C donne **l''éditeur** (« qui publie ? ») — piège B2 majeur : C utilise « aux » comme A, ce qui mime la structure de la question, mais l''éditeur n''est pas le destinataire. D donne **le but** de l''ouvrage.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Justification d'un choix / professionnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu te souviens du recrutement de notre nouveau directeur, l''an dernier ?\n[Homme] Bien sûr, ça avait fait beaucoup parler.\n[Femme] Surtout que la concurrence interne était particulièrement rude.\n[Homme] C''est vrai. Et avec le recul, qu''est-ce qui a justifié ce choix ?\n[Femme] ...\n\nA. Au terme de trois rounds d''entretiens approfondis.\nB. Son expérience internationale, vraiment unique en son genre.\nC. Devant un comité de sélection paritaire.\nD. Pour un démarrage effectif en septembre suivant.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu te souviens du recrutement de notre nouveau directeur, l''an dernier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bien sûr, ça avait fait beaucoup parler.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Surtout que la concurrence interne était particulièrement rude.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est vrai. Et avec le recul, qu''est-ce qui a justifié ce choix ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au terme de trois rounds d''entretiens approfondis.<break time="700ms"/>B.<break time="300ms"/>Son expérience internationale, vraiment unique en son genre.<break time="700ms"/>C.<break time="300ms"/>Devant un comité de sélection paritaire.<break time="700ms"/>D.<break time="300ms"/>Pour un démarrage effectif en septembre suivant.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les trois premiers tours établissent l''enjeu (recrutement disputé, concurrence interne forte). « Qu''est-ce qui a justifié ce choix ? » porte sur **le critère / l''atout qui a fait pencher la décision**. Seule B « son expérience internationale unique » désigne cet atout différenciant. A donne **la durée et l''ampleur de la procédure**. C donne **les acteurs de la décision** (« qui a choisi ? »). D donne **le moment de prise de fonction**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Spécificité gustative (« en quoi est-ce différent ? ») / quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai goûté ton nouveau yaourt fermenté, c''est étonnant.\n[Femme] Oui, ça change vraiment des yaourts classiques.\n[Homme] En quoi est-ce différent au goût, exactement ?\n[Femme] ...\n\nA. Une légère acidité, vraiment originale en bouche.\nB. Depuis presque six mois que j''en achète.\nC. Chez un producteur installé près du marché.\nD. Pour environ trois euros le pot, tout de même.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai goûté ton nouveau yaourt fermenté, c''est étonnant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça change vraiment des yaourts classiques.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">En quoi est-ce différent au goût, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une légère acidité, vraiment originale en bouche.<break time="700ms"/>B.<break time="300ms"/>Depuis presque six mois que j''en achète.<break time="700ms"/>C.<break time="300ms"/>Chez un producteur installé près du marché.<break time="700ms"/>D.<break time="300ms"/>Pour environ trois euros le pot, tout de même.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« En quoi est-ce différent au goût ? » demande **un trait gustatif distinctif**. Seule A « une légère acidité, originale » qualifie le goût. B donne la **durée de la pratique d''achat**. C donne le **lieu d''achat**. D donne le **prix unitaire**. Piège B2 : C et D restent dans le champ thématique du produit alimentaire, mais aucune ne porte sur le goût.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Difficulté principale / social-humanitaire / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu reviens tout juste de ta mission humanitaire au Mali ?\n[Homme] Oui, je suis rentré il y a tout juste une semaine.\n[Femme] Quelle a été la principale difficulté sur place ?\n[Homme] ...\n\nA. L''accès à l''eau potable, malgré tous nos efforts.\nB. Pendant près de quatre mois consécutifs.\nC. Avec une équipe internationale très soudée.\nD. À l''invitation d''une ONG locale réputée.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens tout juste de ta mission humanitaire au Mali ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis rentré il y a tout juste une semaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle a été la principale difficulté sur place ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''accès à l''eau potable, malgré tous nos efforts.<break time="700ms"/>B.<break time="300ms"/>Pendant près de quatre mois consécutifs.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe internationale très soudée.<break time="700ms"/>D.<break time="300ms"/>À l''invitation d''une ONG locale réputée.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question porte sur **l''obstacle majeur rencontré pendant la mission**. Seule A « l''accès à l''eau potable » désigne un obstacle. B donne **la durée** de la mission. C donne **les coéquipiers** (note : « soudée » est positif, donc clairement pas une difficulté). D donne **l''origine de l''invitation** (« par qui es-tu venu ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Préparation à un examen / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu passes ton oral d''agrégation dans deux semaines, c''est ça ?\n[Femme] Oui, ça approche à grands pas.\n[Homme] Comment tu te prépares concrètement à l''exercice ?\n[Femme] ...\n\nA. À cause d''un programme particulièrement dense cette année.\nB. Pour devenir titulaire dans le secondaire enfin.\nC. Au bout de deux ans de préparation très intensive.\nD. En enchaînant des oraux blancs devant un jury simulé.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu passes ton oral d''agrégation dans deux semaines, c''est ça ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça approche à grands pas.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment tu te prépares concrètement à l''exercice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''un programme particulièrement dense cette année.<break time="700ms"/>B.<break time="300ms"/>Pour devenir titulaire dans le secondaire enfin.<break time="700ms"/>C.<break time="300ms"/>Au bout de deux ans de préparation très intensive.<break time="700ms"/>D.<break time="300ms"/>En enchaînant des oraux blancs devant un jury simulé.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Comment tu te prépares concrètement ? » porte sur **la méthode de préparation actuelle**. Seule D « en enchaînant des oraux blancs » (gérondif de moyen) décrit la méthode. A donne **une cause externe** (« pourquoi est-ce dur ? »). B donne **le but ultime** (« pourquoi passes-tu l''oral ? »). C donne **la durée totale de préparation**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Solution adoptée (« par quel moyen ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Vous avez eu un gros problème de plomberie au bureau, non ?\n[Homme] Oui, une fuite énorme la semaine dernière.\n[Femme] Et par quel moyen avez-vous résolu cela rapidement ?\n[Homme] ...\n\nA. En faisant appel à un plombier d''urgence le soir même.\nB. Dans la salle de réunion du deuxième étage.\nC. À la suite d''une canalisation vraiment vétuste.\nD. Avec des dégâts plutôt limités, finalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez eu un gros problème de plomberie au bureau, non ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, une fuite énorme la semaine dernière.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et par quel moyen avez-vous résolu cela rapidement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En faisant appel à un plombier d''urgence le soir même.<break time="700ms"/>B.<break time="300ms"/>Dans la salle de réunion du deuxième étage.<break time="700ms"/>C.<break time="300ms"/>À la suite d''une canalisation vraiment vétuste.<break time="700ms"/>D.<break time="300ms"/>Avec des dégâts plutôt limités, finalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Par quel moyen avez-vous résolu... » porte sur **la solution mise en œuvre**. Seule A « en faisant appel à un plombier » décrit l''action concrète de résolution. B donne **le lieu** du problème. C donne **la cause** de la fuite (« pourquoi cela est-il arrivé ? »). D donne **les conséquences atténuées** (« quel bilan ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Origine d'une habitude (« ça remonte à quand ? ») / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu joues encore tous les dimanches aux échecs avec ton père ?\n[Femme] Oui, c''est devenu un vrai rituel entre nous.\n[Homme] Et ça remonte à quand, cette habitude ?\n[Femme] ...\n\nA. Sur un échiquier en bois qu''il m''avait offert.\nB. Plutôt avec des parties relativement courtes.\nC. À mes premières années de lycée, je dirais.\nD. Pour qu''on reste connectés malgré tout.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu joues encore tous les dimanches aux échecs avec ton père ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est devenu un vrai rituel entre nous.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et ça remonte à quand, cette habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur un échiquier en bois qu''il m''avait offert.<break time="700ms"/>B.<break time="300ms"/>Plutôt avec des parties relativement courtes.<break time="700ms"/>C.<break time="300ms"/>À mes premières années de lycée, je dirais.<break time="700ms"/>D.<break time="300ms"/>Pour qu''on reste connectés malgré tout.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Ça remonte à quand ? » porte sur **l''origine temporelle d''une habitude**. Seule C « à mes premières années de lycée » fixe un point d''origine. A donne **l''objet utilisé** (« avec quoi ? »). B donne **la durée d''une partie** (« combien de temps ? »). D donne **le but / l''intention** du rituel (« pourquoi ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Conditions cumulées (« à quelles conditions ? ») / commercial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as décidé d''accepter cette offre de prêt, finalement ?\n[Homme] Pas encore, j''attends de voir.\n[Femme] Tu l''accepterais à quelles conditions, précisément ?\n[Homme] ...\n\nA. Pour financer l''achat de notre future maison.\nB. Si le taux baisse et que les frais sont supprimés.\nC. Auprès de cette banque en ligne assez récente.\nD. Au plus tard à la fin du mois prochain.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as décidé d''accepter cette offre de prêt, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pas encore, j''attends de voir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu l''accepterais à quelles conditions, précisément ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour financer l''achat de notre future maison.<break time="700ms"/>B.<break time="300ms"/>Si le taux baisse et que les frais sont supprimés.<break time="700ms"/>C.<break time="300ms"/>Auprès de cette banque en ligne assez récente.<break time="700ms"/>D.<break time="300ms"/>Au plus tard à la fin du mois prochain.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quelles conditions ? » appelle **des exigences préalables**. Seule B « si le taux baisse et que les frais sont supprimés » (subordonnées conditionnelles cumulées) répond. A donne **le but** du prêt. C donne **l''interlocuteur bancaire**. D donne une **échéance**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Étape suivante / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez bouclé la phase de tests de votre application ?\n[Femme] Oui, tout est validé depuis vendredi.\n[Homme] Quelle est la prochaine étape, du coup ?\n[Femme] ...\n\nA. Le déploiement en production, sans plus attendre.\nB. Grâce à une équipe particulièrement réactive.\nC. Pendant près de six mois de développement.\nD. Avec un budget assez serré, je l''avoue.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez bouclé la phase de tests de votre application ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, tout est validé depuis vendredi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle est la prochaine étape, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le déploiement en production, sans plus attendre.<break time="700ms"/>B.<break time="300ms"/>Grâce à une équipe particulièrement réactive.<break time="700ms"/>C.<break time="300ms"/>Pendant près de six mois de développement.<break time="700ms"/>D.<break time="300ms"/>Avec un budget assez serré, je l''avoue.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle est la prochaine étape ? » porte sur **l''action ou la phase qui suit immédiatement**. Seule A « le déploiement en production » désigne cette étape suivante. B donne **la cause du succès passé**. C donne **la durée déjà écoulée**. D donne **une contrainte rétrospective**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Compromis trouvé / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que tes enfants se disputaient sur les vacances ?\n[Homme] Oui, c''était un vrai casse-tête à la maison.\n[Femme] Vous avez fini par trouver quel compromis, du coup ?\n[Homme] ...\n\nA. À cause de leurs goûts vraiment opposés.\nB. Après plusieurs soirées de discussion animée.\nC. Avec l''aide précieuse de leur grand-mère.\nD. Une semaine à la mer, puis une semaine à la montagne.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tes enfants se disputaient sur les vacances ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''était un vrai casse-tête à la maison.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez fini par trouver quel compromis, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause de leurs goûts vraiment opposés.<break time="700ms"/>B.<break time="300ms"/>Après plusieurs soirées de discussion animée.<break time="700ms"/>C.<break time="300ms"/>Avec l''aide précieuse de leur grand-mère.<break time="700ms"/>D.<break time="300ms"/>Une semaine à la mer, puis une semaine à la montagne.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel compromis ? » porte sur **la solution médiane retenue**. Seule D « une semaine à la mer, puis une semaine à la montagne » formule la solution équilibrée. A donne **la cause initiale du conflit**. B donne **la durée et la manière du processus**. C donne **l''aide reçue**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Garantie / preuve (« qu'est-ce qui te garantit ? ») / commercial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as l''air vraiment convaincu par cette voiture d''occasion.\n[Femme] Oui, elle paraît en parfait état.\n[Homme] Mais qu''est-ce qui te garantit que ce n''est pas une arnaque ?\n[Femme] ...\n\nA. Auprès d''un concessionnaire de la région, je précise.\nB. Un rapport d''expert indépendant, fourni par écrit.\nC. Pour environ dix mille euros, négociation comprise.\nD. À la suite de longues recherches en ligne.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air vraiment convaincu par cette voiture d''occasion.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, elle paraît en parfait état.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui te garantit que ce n''est pas une arnaque ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès d''un concessionnaire de la région, je précise.<break time="700ms"/>B.<break time="300ms"/>Un rapport d''expert indépendant, fourni par écrit.<break time="700ms"/>C.<break time="300ms"/>Pour environ dix mille euros, négociation comprise.<break time="700ms"/>D.<break time="300ms"/>À la suite de longues recherches en ligne.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui te garantit... ? » porte sur **un élément de preuve / une caution objective**. Seule B « un rapport d''expert indépendant, fourni par écrit » désigne une garantie tangible. A donne **le vendeur / le canal d''achat**. C donne **le prix**. D donne **le processus préalable** (« comment t''es-tu renseigné ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Spécificité d'approche (« en quoi te distingues-tu ? ») / pédagogique / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu enseignes l''histoire dans un lycée parisien, c''est cela ?\n[Homme] Oui, depuis bientôt huit ans déjà.\n[Femme] En quoi ton approche se distingue-t-elle de tes collègues ?\n[Homme] ...\n\nA. Par un usage très régulier d''archives sonores.\nB. Auprès d''élèves majoritairement issus de la banlieue.\nC. Pour environ vingt heures hebdomadaires en classe.\nD. Grâce à un master en didactique de l''histoire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu enseignes l''histoire dans un lycée parisien, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, depuis bientôt huit ans déjà.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quoi ton approche se distingue-t-elle de tes collègues ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par un usage très régulier d''archives sonores.<break time="700ms"/>B.<break time="300ms"/>Auprès d''élèves majoritairement issus de la banlieue.<break time="700ms"/>C.<break time="300ms"/>Pour environ vingt heures hebdomadaires en classe.<break time="700ms"/>D.<break time="300ms"/>Grâce à un master en didactique de l''histoire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« En quoi ton approche se distingue-t-elle ? » porte sur **un trait pédagogique distinctif**. Seule A « par un usage régulier d''archives sonores » désigne un trait spécifique. B donne **le public** d''élèves. C donne **la charge horaire**. D donne **la formation initiale** (« comment t''es-tu formé ? ») — piège B2 : D peut sembler expliquer la spécificité, mais une formation partagée par d''autres collègues n''est pas en soi distinctive.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Délai prévisible (« sous quel délai ? ») / administratif / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as déposé ta demande de naturalisation il y a longtemps ?\n[Femme] Oui, ça fait presque un an déjà.\n[Homme] Sous quel délai peux-tu espérer une réponse, normalement ?\n[Femme] ...\n\nA. À la préfecture de Bobigny, en l''occurrence.\nB. Pour pouvoir voter aux prochaines élections.\nC. Entre douze et dix-huit mois, en moyenne.\nD. Avec l''aide d''une avocate spécialisée.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as déposé ta demande de naturalisation il y a longtemps ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça fait presque un an déjà.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sous quel délai peux-tu espérer une réponse, normalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la préfecture de Bobigny, en l''occurrence.<break time="700ms"/>B.<break time="300ms"/>Pour pouvoir voter aux prochaines élections.<break time="700ms"/>C.<break time="300ms"/>Entre douze et dix-huit mois, en moyenne.<break time="700ms"/>D.<break time="300ms"/>Avec l''aide d''une avocate spécialisée.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Sous quel délai peux-tu espérer une réponse ? » porte sur **un délai d''attente prévisible**. Seule C « entre douze et dix-huit mois » fournit un délai. A donne **le lieu** du dépôt. B donne **le but final** de la démarche. D donne **l''accompagnement** dans la procédure.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Risque encouru (« qu'est-ce que cela risque de te coûter ? ») / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu envisages de quitter ton entreprise pour monter ta propre boîte ?\n[Homme] J''y pense très sérieusement, oui.\n[Femme] Mais qu''est-ce que ça risque de te coûter, concrètement ?\n[Homme] ...\n\nA. La sécurité financière des trois premières années.\nB. À cause d''une opportunité commerciale qui se présente.\nC. Pour devenir enfin maître de mes choix.\nD. Avec le soutien total de ma compagne, heureusement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu envisages de quitter ton entreprise pour monter ta propre boîte ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''y pense très sérieusement, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais qu''est-ce que ça risque de te coûter, concrètement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La sécurité financière des trois premières années.<break time="700ms"/>B.<break time="300ms"/>À cause d''une opportunité commerciale qui se présente.<break time="700ms"/>C.<break time="300ms"/>Pour devenir enfin maître de mes choix.<break time="700ms"/>D.<break time="300ms"/>Avec le soutien total de ma compagne, heureusement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que ça risque de te coûter ? » porte sur **un coût futur, une conséquence négative redoutée**. Seule A « la sécurité financière des trois premières années » désigne ce coût. B donne **la cause / opportunité déclenchante**. C donne **le bénéfice attendu** (l''opposé d''un coût). D donne **un soutien** (un atout, pas un coût).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Aspect le plus marquant / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu reviens enfin du festival d''Avignon ?\n[Femme] Oui, dix jours assez intenses.\n[Homme] Qu''est-ce qui t''a le plus marquée, sur place ?\n[Femme] ...\n\nA. Pendant à peu près une dizaine de jours.\nB. Avec une amie costumière de l''Opéra.\nC. Sous une chaleur parfois écrasante en journée.\nD. Une mise en scène d''Hamlet vraiment inoubliable.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens enfin du festival d''Avignon ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, dix jours assez intenses.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus marquée, sur place ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant à peu près une dizaine de jours.<break time="700ms"/>B.<break time="300ms"/>Avec une amie costumière de l''Opéra.<break time="700ms"/>C.<break time="300ms"/>Sous une chaleur parfois écrasante en journée.<break time="700ms"/>D.<break time="300ms"/>Une mise en scène d''Hamlet vraiment inoubliable.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''a le plus marquée ? » porte sur **un souvenir saillant, le moment fort retenu**. Seule D « une mise en scène d''Hamlet vraiment inoubliable » désigne ce moment fort. A donne **la durée** du séjour. B donne **l''accompagnante**. C donne **les conditions climatiques** — piège B2 : « écrasante » est marqué émotionnellement mais reste une description du contexte, pas du moment culturel marquant.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Inconvénient principal / quotidien-logement / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu vis dans ton nouvel appartement depuis combien de temps ?\n[Homme] Trois mois pleins, maintenant.\n[Femme] Et quel en est le principal inconvénient, finalement ?\n[Homme] ...\n\nA. Un bruit constant venant de la rue.\nB. Près du parc de Belleville, au cinquième étage.\nC. Pour un loyer plutôt raisonnable, c''est vrai.\nD. À la suite d''un déménagement franchement éprouvant.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vis dans ton nouvel appartement depuis combien de temps ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Trois mois pleins, maintenant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel en est le principal inconvénient, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un bruit constant venant de la rue.<break time="700ms"/>B.<break time="300ms"/>Près du parc de Belleville, au cinquième étage.<break time="700ms"/>C.<break time="300ms"/>Pour un loyer plutôt raisonnable, c''est vrai.<break time="700ms"/>D.<break time="300ms"/>À la suite d''un déménagement franchement éprouvant.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est le principal inconvénient ? » porte sur **un défaut, un point négatif du logement actuel**. Seule A « un bruit constant venant de la rue » désigne un inconvénient. B donne la **localisation**. C donne un **avantage** (loyer raisonnable) — piège B2 : C est le contraire d''un inconvénient. D donne un **désagrément antérieur lié au déménagement**, pas un défaut du logement lui-même.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Action proactive mise en place / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous aviez un fort taux d''absentéisme, m''as-tu dit ?\n[Femme] Oui, c''était devenu très préoccupant chez nous.\n[Homme] Qu''as-tu concrètement mis en place pour y remédier ?\n[Femme] ...\n\nA. À cause d''un management trop pyramidal au départ.\nB. Des entretiens individuels mensuels avec chaque salarié.\nC. Auprès de ma direction, qui a soutenu la démarche.\nD. Pour retrouver une dynamique d''équipe positive.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous aviez un fort taux d''absentéisme, m''as-tu dit ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''était devenu très préoccupant chez nous.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''as-tu concrètement mis en place pour y remédier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''un management trop pyramidal au départ.<break time="700ms"/>B.<break time="300ms"/>Des entretiens individuels mensuels avec chaque salarié.<break time="700ms"/>C.<break time="300ms"/>Auprès de ma direction, qui a soutenu la démarche.<break time="700ms"/>D.<break time="300ms"/>Pour retrouver une dynamique d''équipe positive.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''as-tu mis en place pour y remédier ? » porte sur **l''action / le dispositif concret installé**. Seule B « des entretiens individuels mensuels » désigne cette action. A donne **la cause du problème initial**. C donne **le soutien hiérarchique obtenu** (« auprès de qui as-tu obtenu un appui ? »). D donne **l''objectif visé** par les actions, pas les actions elles-mêmes.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Évolution récente (« qu'est-ce qui a évolué chez lui ? ») / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-2000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que ton fils avait beaucoup changé dernièrement.\n[Homme] Oui, on le retrouve presque méconnaissable.\n[Femme] Qu''est-ce qui a évolué chez lui, précisément ?\n[Homme] ...\n\nA. Depuis son entrée en classe de seconde.\nB. Grâce à un professeur particulier remarquable.\nC. Une autonomie nouvelle dans tous ses choix.\nD. Avec parfois encore quelques moments de doute.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que ton fils avait beaucoup changé dernièrement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on le retrouve presque méconnaissable.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui a évolué chez lui, précisément ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis son entrée en classe de seconde.<break time="700ms"/>B.<break time="300ms"/>Grâce à un professeur particulier remarquable.<break time="700ms"/>C.<break time="300ms"/>Une autonomie nouvelle dans tous ses choix.<break time="700ms"/>D.<break time="300ms"/>Avec parfois encore quelques moments de doute.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui a évolué chez lui ? » porte sur **la nature du changement observé**. Seule C « une autonomie nouvelle dans tous ses choix » nomme ce changement. A donne **le moment d''origine** du changement (« depuis quand ? »). B donne **le facteur explicatif / la cause** (« grâce à quoi ? »). D donne **une nuance / réserve** sur le changement, pas le changement lui-même.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
