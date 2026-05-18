-- ============================================================
-- 22 exercices B1 (lot 3) - CO TCF - format "réponse à question implicite"
-- Dialogues de 2 ou 3 tours (alternance Henri / Denise),
-- 22 nouveaux types de question implicite (différents de V401 / V404 / V409).
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 6×A, 6×B, 5×C, 5×D.
-- voice_recommended : 11 Henri / 11 Denise (dernier locuteur du dialogue).
-- ============================================================

-- ----- Exercice 1 : Préparation d'un évènement (« comment as-tu préparé… ») / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000001', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tout le monde a adoré la fête de retraite de papa.\n[Homme] Oui, c''était une vraie réussite.\n[Femme] Mais dis-moi, comment tu as préparé tout ça ?\n[Homme] ...\n\nA. En m''y prenant trois semaines à l''avance, étape par étape.\nB. Avec ma sœur et le mari de Camille, surtout.\nC. Dans la grande salle de l''ancienne mairie.\nD. Pour lui faire vraiment plaisir, tout simplement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tout le monde a adoré la fête de retraite de papa.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''était une vraie réussite.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais dis-moi, comment tu as préparé tout ça ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En m''y prenant trois semaines à l''avance, étape par étape.<break time="700ms"/>B.<break time="300ms"/>Avec ma sœur et le mari de Camille, surtout.<break time="700ms"/>C.<break time="300ms"/>Dans la grande salle de l''ancienne mairie.<break time="700ms"/>D.<break time="300ms"/>Pour lui faire vraiment plaisir, tout simplement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours valident le succès de la fête ; la question finale « comment tu as préparé tout ça ? » porte sur **la méthode d''organisation**. Seule A « en m''y prenant trois semaines à l''avance, étape par étape » décrit une démarche d''organisation. B donne **l''aide reçue** (« avec qui ? »). C donne **le lieu** de la fête (« où ? »). D donne **le but / motif** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Recommandation de film / culturel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000002', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''aimerais bien aller au cinéma ce week-end, mais je ne sais pas quoi voir.\n[Femme] Tu me recommandes quel film, alors ?\n[Homme] ...\n\nA. Vers vingt heures, en séance du soir.\nB. La dernière comédie de Klapisch, sans hésiter.\nC. Au cinéma du quartier des Halles, c''est sympa.\nD. Avec ta sœur, elle adore ce genre de chose.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''aimerais bien aller au cinéma ce week-end, mais je ne sais pas quoi voir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu me recommandes quel film, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers vingt heures, en séance du soir.<break time="700ms"/>B.<break time="300ms"/>La dernière comédie de Klapisch, sans hésiter.<break time="700ms"/>C.<break time="300ms"/>Au cinéma du quartier des Halles, c''est sympa.<break time="700ms"/>D.<break time="300ms"/>Avec ta sœur, elle adore ce genre de chose.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour expose l''embarras (quoi voir ?) ; la question « tu me recommandes quel film ? » appelle **le titre / la désignation d''un film**. Seule B « la dernière comédie de Klapisch » désigne un film. A donne **l''heure de séance**. C donne **le cinéma conseillé** (« où aller ? »). D donne **un accompagnant suggéré** (« avec qui y aller ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Réaction d'un proche à une nouvelle / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000003', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai annoncé à ma mère que je partais m''installer à Lyon.\n[Femme] Ah, enfin ! Tu lui as dit hier ?\n[Homme] Oui, au téléphone. Et toi, tu sais comment elle a réagi ?\n[Femme] ...\n\nA. Pendant un long appel, jusqu''à minuit.\nB. À cause du nouveau travail qui t''attend là-bas.\nC. Avec beaucoup d''émotion, mais sans s''opposer.\nD. Chez ma tante, où on était toutes les deux.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai annoncé à ma mère que je partais m''installer à Lyon.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ah, enfin ! Tu lui as dit hier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, au téléphone. Et toi, tu sais comment elle a réagi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant un long appel, jusqu''à minuit.<break time="700ms"/>B.<break time="300ms"/>À cause du nouveau travail qui t''attend là-bas.<break time="700ms"/>C.<break time="300ms"/>Avec beaucoup d''émotion, mais sans s''opposer.<break time="700ms"/>D.<break time="300ms"/>Chez ma tante, où on était toutes les deux.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent l''annonce (départ à Lyon) ; la question « comment elle a réagi ? » porte sur **la nature de la réaction**. Seule C « avec beaucoup d''émotion, mais sans s''opposer » décrit une réaction. A donne **la durée de l''appel** (« combien de temps avez-vous parlé ? »). B donne **la cause du départ** (« pourquoi pars-tu ? »). D donne **le lieu où la nouvelle a été apprise** (« où l''as-tu apprise ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Conseil à donner / quotidien / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000004', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Je dors très mal depuis deux semaines, j''en peux plus.\n[Homme] Qu''est-ce que tu me conseilles, toi qui as eu le même problème ?\n[Femme] ...\n\nA. Depuis bientôt un mois, dans mon cas.\nB. À cause du stress, sans doute, comme moi.\nC. Pour retrouver enfin une vraie qualité de sommeil.\nD. D''essayer la tisane et de ranger ton téléphone le soir.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je dors très mal depuis deux semaines, j''en peux plus.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu me conseilles, toi qui as eu le même problème ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis bientôt un mois, dans mon cas.<break time="700ms"/>B.<break time="300ms"/>À cause du stress, sans doute, comme moi.<break time="700ms"/>C.<break time="300ms"/>Pour retrouver enfin une vraie qualité de sommeil.<break time="700ms"/>D.<break time="300ms"/>D''essayer la tisane et de ranger ton téléphone le soir.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le problème (mauvais sommeil) ; la question « qu''est-ce que tu me conseilles ? » appelle **une recommandation concrète d''action**. Seule D « d''essayer la tisane et de ranger ton téléphone » formule un conseil. A donne **la durée du problème** chez le locuteur (« depuis combien de temps ? »). B donne **la cause supposée** (« pourquoi tu dors mal ? »). C donne **le but visé** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Lieu visité préféré pendant un séjour / voyage / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000005', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Alors, ton voyage en Andalousie, raconte un peu !\n[Homme] On a vraiment beaucoup vu, c''était dense.\n[Femme] Et tu as préféré quel endroit, finalement ?\n[Homme] ...\n\nA. L''Alhambra de Grenade, sans aucune hésitation.\nB. Pendant dix jours pleins, du nord au sud.\nC. À cause de la lumière incroyable là-bas.\nD. Avec un petit groupe d''amis très soudés.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, ton voyage en Andalousie, raconte un peu !</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a vraiment beaucoup vu, c''était dense.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as préféré quel endroit, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''Alhambra de Grenade, sans aucune hésitation.<break time="700ms"/>B.<break time="300ms"/>Pendant dix jours pleins, du nord au sud.<break time="700ms"/>C.<break time="300ms"/>À cause de la lumière incroyable là-bas.<break time="700ms"/>D.<break time="300ms"/>Avec un petit groupe d''amis très soudés.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours installent le bilan d''un voyage dense ; la question « tu as préféré quel endroit ? » porte sur **un lieu précis parmi ceux visités**. Seule A « l''Alhambra de Grenade » désigne un endroit. B donne **la durée du séjour** (« combien de temps ? »). C donne **une cause / un motif d''appréciation** (« pourquoi as-tu aimé ? »). D donne **les accompagnants** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Souvenir d'enfance / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000006', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''as dit que tu passais tous tes étés chez tes grands-parents.\n[Femme] Oui, dans leur petite maison près de la mer.\n[Homme] Et tu te rappelles surtout de quoi, de ces vacances ?\n[Femme] ...\n\nA. À côté de Saint-Malo, en Bretagne.\nB. Des longues parties de pêche avec mon grand-père.\nC. Pendant tout le mois de juillet, chaque année.\nD. Avec ma cousine Émilie, à chaque fois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que tu passais tous tes étés chez tes grands-parents.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, dans leur petite maison près de la mer.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu te rappelles surtout de quoi, de ces vacances ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À côté de Saint-Malo, en Bretagne.<break time="700ms"/>B.<break time="300ms"/>Des longues parties de pêche avec mon grand-père.<break time="700ms"/>C.<break time="300ms"/>Pendant tout le mois de juillet, chaque année.<break time="700ms"/>D.<break time="300ms"/>Avec ma cousine Émilie, à chaque fois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le décor (étés chez les grands-parents) ; la question « tu te rappelles surtout de quoi ? » porte sur **le contenu mémorisé, le souvenir saillant**. Seule B « des longues parties de pêche avec mon grand-père » nomme un souvenir précis. A donne **la localisation précise** (« où exactement ? »). C donne **la période / durée** (« quand / combien de temps ? »). D donne **les accompagnants** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Réalisation personnelle / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000007', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as l''air vraiment fière de toi, en ce moment.\n[Femme] Oui ! Et toi, qu''est-ce que tu as réussi à faire dernièrement ?\n[Homme] ...\n\nA. Pendant presque six mois de préparation intense.\nB. Pour me prouver que j''en étais capable, surtout.\nC. À courir un semi-marathon sans m''arrêter.\nD. À cause d''un défi lancé par un collègue.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air vraiment fière de toi, en ce moment.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui ! Et toi, qu''est-ce que tu as réussi à faire dernièrement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant presque six mois de préparation intense.<break time="700ms"/>B.<break time="300ms"/>Pour me prouver que j''en étais capable, surtout.<break time="700ms"/>C.<break time="300ms"/>À courir un semi-marathon sans m''arrêter.<break time="700ms"/>D.<break time="300ms"/>À cause d''un défi lancé par un collègue.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question « qu''est-ce que tu as réussi à faire dernièrement ? » porte sur **la nature de la réalisation accomplie**. Seule C « à courir un semi-marathon sans m''arrêter » nomme l''exploit accompli. A donne **la durée de la préparation** (« combien de temps ? »). B donne **le but visé** (« pour quoi faire ? »). D donne **la cause / l''origine** (« pourquoi t''y es-tu mis ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Difficulté rencontrée / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000008', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as enfin bouclé le dossier pour le client, je crois ?\n[Homme] Oui, hier soir, juste avant la deadline.\n[Femme] Bravo. Et qu''est-ce qui a été le plus dur, finalement ?\n[Homme] ...\n\nA. Avec deux collègues qui m''ont aidé sur la fin.\nB. Pendant trois soirées de suite, jusqu''à minuit.\nC. Pour que tout soit prêt à temps, vraiment à temps.\nD. De rassembler toutes les données chiffrées en si peu de jours.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as enfin bouclé le dossier pour le client, je crois ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, hier soir, juste avant la deadline.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bravo. Et qu''est-ce qui a été le plus dur, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux collègues qui m''ont aidé sur la fin.<break time="700ms"/>B.<break time="300ms"/>Pendant trois soirées de suite, jusqu''à minuit.<break time="700ms"/>C.<break time="300ms"/>Pour que tout soit prêt à temps, vraiment à temps.<break time="700ms"/>D.<break time="300ms"/>De rassembler toutes les données chiffrées en si peu de jours.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent la fin du dossier ; la question « qu''est-ce qui a été le plus dur ? » porte sur **la nature de la difficulté principale**. Seule D « de rassembler toutes les données chiffrées en si peu de jours » nomme une difficulté. A donne **les aides reçues** (« avec qui ? »). B donne **la durée de l''effort** (« combien de temps ? »). C donne **le but visé** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Réussite récente / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000009', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu rayonnes, depuis quelques jours, on dirait. Tu as accompli quoi de beau, récemment ?\n[Homme] ...\n\nA. Le passage de mon permis de conduire, du premier coup.\nB. Pendant des mois entiers de leçons régulières.\nC. À cause d''un examen blanc raté il y a deux semaines.\nD. Avec une monitrice vraiment patiente et pédagogue.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu rayonnes, depuis quelques jours, on dirait. Tu as accompli quoi de beau, récemment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le passage de mon permis de conduire, du premier coup.<break time="700ms"/>B.<break time="300ms"/>Pendant des mois entiers de leçons régulières.<break time="700ms"/>C.<break time="300ms"/>À cause d''un examen blanc raté il y a deux semaines.<break time="700ms"/>D.<break time="300ms"/>Avec une monitrice vraiment patiente et pédagogue.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question « tu as accompli quoi de beau, récemment ? » porte sur **la nature d''un accomplissement personnel**. Seule A « le passage de mon permis de conduire, du premier coup » nomme une réussite. B donne **la durée de la préparation** (« combien de temps ? »). C donne **un évènement antérieur, une cause de motivation** (« pourquoi ? »). D donne **une aide reçue** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Projet à venir / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000a', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''as dit que tu allais bientôt changer pas mal de choses dans ta vie.\n[Femme] Oui, j''ai vraiment besoin de bouger un peu.\n[Homme] Tu prévois quoi, exactement ?\n[Femme] ...\n\nA. Pour me sentir plus utile au quotidien.\nB. De reprendre des études en alternance dès septembre.\nC. À cause d''un travail devenu trop routinier.\nD. Avec un nouveau projet professionnel en tête.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que tu allais bientôt changer pas mal de choses dans ta vie.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai vraiment besoin de bouger un peu.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu prévois quoi, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour me sentir plus utile au quotidien.<break time="700ms"/>B.<break time="300ms"/>De reprendre des études en alternance dès septembre.<break time="700ms"/>C.<break time="300ms"/>À cause d''un travail devenu trop routinier.<break time="700ms"/>D.<break time="300ms"/>Avec un nouveau projet professionnel en tête.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours installent un besoin de changement ; la question « tu prévois quoi, exactement ? » porte sur **le contenu concret du projet futur**. Seule B « de reprendre des études en alternance dès septembre » détaille un projet précis. A donne **le but** (« pour quoi faire ? »). C donne **la cause du changement** (« pourquoi changer ? »). D donne **un cadre vague d''accompagnement mental**, pas un projet précis (« avec quoi ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Recette préférée à préparer / culinaire / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000b', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] On m''a dit que tu cuisinais beaucoup le week-end.\n[Homme] Oui, c''est mon vrai moment de détente.\n[Femme] Et tu aimes préparer quelle recette par-dessus tout ?\n[Homme] ...\n\nA. Pendant deux bonnes heures à chaque fois.\nB. Avec ma fille aînée, qui adore m''aider.\nC. Un bœuf bourguignon mijoté tout l''après-midi.\nD. Pour me changer complètement les idées.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On m''a dit que tu cuisinais beaucoup le week-end.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est mon vrai moment de détente.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu aimes préparer quelle recette par-dessus tout ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux bonnes heures à chaque fois.<break time="700ms"/>B.<break time="300ms"/>Avec ma fille aînée, qui adore m''aider.<break time="700ms"/>C.<break time="300ms"/>Un bœuf bourguignon mijoté tout l''après-midi.<break time="700ms"/>D.<break time="300ms"/>Pour me changer complètement les idées.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent l''habitude (cuisine = détente du week-end) ; la question « tu aimes préparer quelle recette par-dessus tout ? » porte sur **l''identification d''une recette précise**. Seule C « un bœuf bourguignon mijoté tout l''après-midi » nomme une recette. A donne **la durée habituelle** (« combien de temps ? »). B donne **l''accompagnant** (« avec qui ? »). D donne **le but / bénéfice** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Endroit pour vacances futures / voyage / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000c', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On a enfin posé nos congés d''été cette année.\n[Femme] Super ! Vous partez où, du coup ?\n[Homme] ...\n\nA. Pendant trois semaines complètes, en août.\nB. Avec les enfants et les grands-parents.\nC. Pour vraiment couper du quotidien parisien.\nD. Sur une petite île de la côte croate.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a enfin posé nos congés d''été cette année.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Super ! Vous partez où, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant trois semaines complètes, en août.<break time="700ms"/>B.<break time="300ms"/>Avec les enfants et les grands-parents.<break time="700ms"/>C.<break time="300ms"/>Pour vraiment couper du quotidien parisien.<break time="700ms"/>D.<break time="300ms"/>Sur une petite île de la côte croate.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le contexte (congés d''été posés) ; la question « vous partez où ? » porte sur **la destination des vacances**. Seule D « sur une petite île de la côte croate » désigne un lieu. A donne **la durée et le moment** (« combien de temps, quand ? »). B donne **les accompagnants** (« avec qui ? »). C donne **le but du voyage** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Origine d'une décision / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000d', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as donné ta démission la semaine dernière, c''est sûr ?\n[Homme] Oui, j''ai posé ma lettre lundi matin.\n[Femme] Mais qu''est-ce qui t''a vraiment décidé, à la fin ?\n[Homme] ...\n\nA. Une discussion très franche avec ma compagne, un soir.\nB. Pour me lancer enfin dans mon propre projet.\nC. Après plusieurs mois d''hésitation, quand même.\nD. Avec mon manager, juste avant les vacances.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as donné ta démission la semaine dernière, c''est sûr ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai posé ma lettre lundi matin.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais qu''est-ce qui t''a vraiment décidé, à la fin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une discussion très franche avec ma compagne, un soir.<break time="700ms"/>B.<break time="300ms"/>Pour me lancer enfin dans mon propre projet.<break time="700ms"/>C.<break time="300ms"/>Après plusieurs mois d''hésitation, quand même.<break time="700ms"/>D.<break time="300ms"/>Avec mon manager, juste avant les vacances.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours confirment la démission ; la question « qu''est-ce qui t''a vraiment décidé ? » porte sur **l''élément déclencheur de la décision**. Seule A « une discussion très franche avec ma compagne » identifie un élément déclencheur. B donne **le but visé** (« pour quoi faire ? »). C donne **la durée d''hésitation** (« depuis combien de temps ? »). D donne **un interlocuteur et un moment** (« avec qui, quand ? »), pas la cause du choix.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Personne admirée / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000e', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On parlait des grandes figures qu''on aime. Toi, tu admires vraiment qui, dans ta famille ?\n[Femme] ...\n\nA. Pour son courage face à la maladie, surtout.\nB. Ma tante Hélène, sans la moindre hésitation.\nC. Depuis que je suis toute petite, je crois.\nD. Avec mon oncle, on parle souvent d''elle.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On parlait des grandes figures qu''on aime. Toi, tu admires vraiment qui, dans ta famille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour son courage face à la maladie, surtout.<break time="700ms"/>B.<break time="300ms"/>Ma tante Hélène, sans la moindre hésitation.<break time="700ms"/>C.<break time="300ms"/>Depuis que je suis toute petite, je crois.<break time="700ms"/>D.<break time="300ms"/>Avec mon oncle, on parle souvent d''elle.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question « tu admires vraiment qui, dans ta famille ? » porte sur **l''identité de la personne admirée**. Seule B « ma tante Hélène » désigne une personne. A donne **la raison de l''admiration** (« pourquoi ? »). C donne **la durée du sentiment** (« depuis quand ? »). D donne **un interlocuteur** avec qui on en parle (« avec qui en parles-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Apprentissage récent / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-00000000000f', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu suis bien des cours du soir depuis la rentrée ?\n[Femme] Oui, deux fois par semaine, le mardi et le jeudi.\n[Homme] Et tu as appris quoi de concret, jusqu''à présent ?\n[Femme] ...\n\nA. Avec un petit groupe de huit adultes motivés.\nB. Pendant deux heures à chaque séance.\nC. À tenir une conversation simple en espagnol.\nD. Pour pouvoir voyager seule en Amérique latine.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu suis bien des cours du soir depuis la rentrée ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, deux fois par semaine, le mardi et le jeudi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu as appris quoi de concret, jusqu''à présent ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un petit groupe de huit adultes motivés.<break time="700ms"/>B.<break time="300ms"/>Pendant deux heures à chaque séance.<break time="700ms"/>C.<break time="300ms"/>À tenir une conversation simple en espagnol.<break time="700ms"/>D.<break time="300ms"/>Pour pouvoir voyager seule en Amérique latine.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le cadre (cours du soir, deux fois par semaine) ; la question « tu as appris quoi de concret ? » porte sur **le contenu réellement acquis**. Seule C « à tenir une conversation simple en espagnol » nomme un acquis concret. A donne **la composition du groupe** (« avec qui ? »). B donne **la durée d''une séance** (« combien de temps ? »). D donne **le but de l''apprentissage** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Habitude prise récemment / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000010', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as l''air bien plus serein qu''avant, je trouve.\n[Homme] Oui, je crois que j''ai vraiment changé quelque chose dans mes journées.\n[Femme] Tu as commencé quoi, comme nouvelle habitude ?\n[Homme] ...\n\nA. Avec un ami qui fait pareil, pour se motiver.\nB. Pour mieux gérer le stress du bureau, surtout.\nC. Depuis environ deux mois, sans trop de mal.\nD. Une petite méditation tous les matins, au réveil.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air bien plus serein qu''avant, je trouve.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je crois que j''ai vraiment changé quelque chose dans mes journées.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as commencé quoi, comme nouvelle habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un ami qui fait pareil, pour se motiver.<break time="700ms"/>B.<break time="300ms"/>Pour mieux gérer le stress du bureau, surtout.<break time="700ms"/>C.<break time="300ms"/>Depuis environ deux mois, sans trop de mal.<break time="700ms"/>D.<break time="300ms"/>Une petite méditation tous les matins, au réveil.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours mettent en avant un changement positif ; la question « tu as commencé quoi, comme nouvelle habitude ? » porte sur **la nature de l''habitude prise**. Seule D « une petite méditation tous les matins, au réveil » nomme l''habitude. A donne **un partenaire de pratique** (« avec qui ? »). B donne **le but / motif** (« pour quoi faire ? »). C donne **la durée depuis le début** (« depuis quand ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Habitude abandonnée récemment / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000011', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as l''air en pleine forme, ces derniers temps !\n[Homme] Oui, j''ai laissé tomber une mauvaise habitude. Et toi, qu''est-ce que tu as arrêté récemment ?\n[Femme] ...\n\nA. Le café après quatorze heures, et je dors mille fois mieux.\nB. Depuis bientôt trois semaines, sans rechute.\nC. Pour retrouver enfin un vrai sommeil réparateur.\nD. À cause des conseils de ma médecin traitante.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air en pleine forme, ces derniers temps !</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai laissé tomber une mauvaise habitude. Et toi, qu''est-ce que tu as arrêté récemment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le café après quatorze heures, et je dors mille fois mieux.<break time="700ms"/>B.<break time="300ms"/>Depuis bientôt trois semaines, sans rechute.<break time="700ms"/>C.<break time="300ms"/>Pour retrouver enfin un vrai sommeil réparateur.<break time="700ms"/>D.<break time="300ms"/>À cause des conseils de ma médecin traitante.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question retournée « qu''est-ce que tu as arrêté récemment ? » porte sur **la nature de l''habitude abandonnée**. Seule A « le café après quatorze heures » identifie l''habitude arrêtée. B donne **la durée depuis l''arrêt** (« depuis quand ? »). C donne **le but visé** (« pour quoi faire ? »). D donne **la cause / déclencheur** (« pourquoi ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Changement de rythme / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000012', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Depuis ton passage au temps partiel, ton quotidien doit être très différent.\n[Femme] Oh oui, complètement.\n[Homme] Concrètement, qu''est-ce qui a changé pour toi ?\n[Femme] ...\n\nA. Pour passer plus de temps avec mes enfants.\nB. J''ai désormais tous mes mercredis libres, et c''est précieux.\nC. À cause d''un trajet devenu trop fatigant.\nD. Avec l''accord de mon manager, qui a été compréhensif.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Depuis ton passage au temps partiel, ton quotidien doit être très différent.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oh oui, complètement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Concrètement, qu''est-ce qui a changé pour toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour passer plus de temps avec mes enfants.<break time="700ms"/>B.<break time="300ms"/>J''ai désormais tous mes mercredis libres, et c''est précieux.<break time="700ms"/>C.<break time="300ms"/>À cause d''un trajet devenu trop fatigant.<break time="700ms"/>D.<break time="300ms"/>Avec l''accord de mon manager, qui a été compréhensif.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le changement (passage au temps partiel) ; la question « qu''est-ce qui a changé pour toi ? » porte sur **la nature concrète du changement de rythme**. Seule B « j''ai désormais tous mes mercredis libres » décrit un changement concret. A donne **le but du passage au temps partiel** (« pour quoi faire ? »). C donne **la cause** (« pourquoi ce changement ? »). D donne **les conditions / accord obtenu** (« avec qui as-tu négocié ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Manière de fêter un anniversaire / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000013', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Ton fils va avoir dix ans la semaine prochaine, non ?\n[Homme] Oui, samedi exactement.\n[Femme] Vous allez fêter ça comment, vous deux ?\n[Homme] ...\n\nA. Pour qu''il garde un souvenir vraiment unique.\nB. Avec une douzaine de ses petits copains, surtout.\nC. En passant la journée entière au parc d''attractions.\nD. Chez nous, dans le jardin du fond.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton fils va avoir dix ans la semaine prochaine, non ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, samedi exactement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous allez fêter ça comment, vous deux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour qu''il garde un souvenir vraiment unique.<break time="700ms"/>B.<break time="300ms"/>Avec une douzaine de ses petits copains, surtout.<break time="700ms"/>C.<break time="300ms"/>En passant la journée entière au parc d''attractions.<break time="700ms"/>D.<break time="300ms"/>Chez nous, dans le jardin du fond.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent l''occasion (10 ans du fils samedi) ; la question « vous allez fêter ça comment ? » porte sur **la manière de célébrer**. Seule C « en passant la journée entière au parc d''attractions » (gérondif décrivant le mode) décrit comment. A donne **le but** (« pour quoi faire ? »). B donne **les invités** (« avec qui ? »). D donne **le lieu** (« où ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Comparaison entre saisons / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000014', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Moi, l''hiver, je le supporte vraiment de moins en moins.\n[Femme] Et toi, du coup, tu préfères quelle saison et pourquoi ?\n[Homme] ...\n\nA. Pendant à peu près trois mois dans l''année.\nB. Au bord de la mer, surtout en septembre.\nC. Avec ma famille du sud, qui aime la chaleur.\nD. L''automne, pour ses couleurs et sa douceur.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Moi, l''hiver, je le supporte vraiment de moins en moins.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et toi, du coup, tu préfères quelle saison et pourquoi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant à peu près trois mois dans l''année.<break time="700ms"/>B.<break time="300ms"/>Au bord de la mer, surtout en septembre.<break time="700ms"/>C.<break time="300ms"/>Avec ma famille du sud, qui aime la chaleur.<break time="700ms"/>D.<break time="300ms"/>L''automne, pour ses couleurs et sa douceur.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le rejet de l''hiver ; la question « tu préfères quelle saison et pourquoi ? » attend **une saison nommée avec sa raison**. Seule D « l''automne, pour ses couleurs et sa douceur » répond aux deux volets. A donne **une durée de saison** (« combien de temps dure-t-elle ? »). B donne **un lieu et un moment** (« où, quand ? »). C donne **un accompagnement** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 21 : Préférence entre 2 villes / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000015', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as vécu à Lyon comme à Bordeaux, finalement.\n[Homme] Oui, plusieurs années dans chacune.\n[Femme] Alors, tu préfères laquelle, entre les deux ?\n[Homme] ...\n\nA. Bordeaux, sans hésiter, je m''y suis senti chez moi.\nB. À cause du climat océanique, plus doux.\nC. Pendant quatre années passionnantes là-bas.\nD. Avec mes deux meilleurs amis de l''époque.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as vécu à Lyon comme à Bordeaux, finalement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, plusieurs années dans chacune.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, tu préfères laquelle, entre les deux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Bordeaux, sans hésiter, je m''y suis senti chez moi.<break time="700ms"/>B.<break time="300ms"/>À cause du climat océanique, plus doux.<break time="700ms"/>C.<break time="300ms"/>Pendant quatre années passionnantes là-bas.<break time="700ms"/>D.<break time="300ms"/>Avec mes deux meilleurs amis de l''époque.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le choix binaire (Lyon vs Bordeaux) ; la question « tu préfères laquelle, entre les deux ? » attend **la désignation explicite d''une des deux villes**. Seule A « Bordeaux, sans hésiter » nomme la ville choisie. B donne **une raison possible** (« pourquoi ? ») mais ne désigne pas la ville. C donne **la durée passée dans une ville** (« combien de temps ? »). D donne **des accompagnants de l''époque** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 22 : Lieu d'une cérémonie / célébration / familial / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-3000-0000-000000000016', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez enfin fixé tous les détails du baptême de la petite ?\n[Femme] Oui ! Et toi, tu sais où aura lieu la cérémonie ?\n[Homme] ...\n\nA. Avec une centaine d''invités de toute la famille.\nB. Dans la petite chapelle du village de ses grands-parents.\nC. Pour célébrer ses six mois en famille élargie.\nD. Le dernier samedi de juin, normalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez enfin fixé tous les détails du baptême de la petite ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui ! Et toi, tu sais où aura lieu la cérémonie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une centaine d''invités de toute la famille.<break time="700ms"/>B.<break time="300ms"/>Dans la petite chapelle du village de ses grands-parents.<break time="700ms"/>C.<break time="300ms"/>Pour célébrer ses six mois en famille élargie.<break time="700ms"/>D.<break time="300ms"/>Le dernier samedi de juin, normalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le premier tour pose le contexte (baptême en préparation) ; la question retournée « tu sais où aura lieu la cérémonie ? » porte sur **le lieu de la cérémonie**. Seule B « dans la petite chapelle du village de ses grands-parents » désigne un lieu. A donne **le nombre d''invités** (« combien ? »). C donne **le motif / but** (« pour quoi faire ? »). D donne **la date** (« quand ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
