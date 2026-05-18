-- ============================================================
-- 20 exercices A2 (lot 2) - CO TCF - format "réponse à question implicite"
-- Une seule réplique (question directe), alternance Henri / Denise.
-- 20 types de question simples : où, quand, combien, qui, quoi,
-- quel choix, à quelle heure, comment, pourquoi, avec qui,
-- depuis quand, durée, couleur, âge, lieu géographique, jour,
-- météo, goût, adresse, préférence.
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 5×A, 5×B, 5×C, 5×D.
-- ============================================================

-- ----- Exercice 1 : Lieu (« où ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000001', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Où est ton sac à dos, finalement ?\n[Femme] ...\n\nA. Sous la table de l''entrée.\nB. Pour mes affaires d''école.\nC. Avec mes livres dedans.\nD. Depuis ce matin, je crois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où est ton sac à dos, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sous la table de l''entrée.<break time="700ms"/>B.<break time="300ms"/>Pour mes affaires d''école.<break time="700ms"/>C.<break time="300ms"/>Avec mes livres dedans.<break time="700ms"/>D.<break time="300ms"/>Depuis ce matin, je crois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Où est ton sac ? » porte sur **le lieu**. Seule A « sous la table de l''entrée » indique un endroit. B donne **le but** (« pour quoi faire ? »). C donne **le contenu** (« avec quoi dedans ? »). D donne **un moment** (« depuis quand ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Moment (« quand ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000002', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quand est-ce que tu rentres ce soir ?\n[Homme] ...\n\nA. Au bureau, comme d''habitude.\nB. Vers dix-neuf heures, je pense.\nC. Avec mon collègue Pierre.\nD. Pour finir un dossier urgent.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quand est-ce que tu rentres ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bureau, comme d''habitude.<break time="700ms"/>B.<break time="300ms"/>Vers dix-neuf heures, je pense.<break time="700ms"/>C.<break time="300ms"/>Avec mon collègue Pierre.<break time="700ms"/>D.<break time="300ms"/>Pour finir un dossier urgent.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quand est-ce que tu rentres ? » porte sur **le moment**. Seule B « vers dix-neuf heures » donne une heure. A donne **le lieu**. C donne **l''accompagnant**. D donne **la cause / le but**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Nombre (« combien ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000003', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as combien de chats à la maison ?\n[Femme] ...\n\nA. Très calmes, en général.\nB. Pour me tenir compagnie.\nC. Deux, un noir et un blanc.\nD. Dans le salon, souvent.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as combien de chats à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Très calmes, en général.<break time="700ms"/>B.<break time="300ms"/>Pour me tenir compagnie.<break time="700ms"/>C.<break time="300ms"/>Deux, un noir et un blanc.<break time="700ms"/>D.<break time="300ms"/>Dans le salon, souvent.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Combien de chats ? » porte sur **le nombre**. Seule C « deux » donne une quantité. A donne **le caractère** des animaux. B donne **le but / la raison** de les avoir. D donne **le lieu**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Identité (« qui ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000004', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Qui te garde ton fils ce soir ?\n[Homme] ...\n\nA. Jusqu''à minuit, environ.\nB. Pour aller au cinéma.\nC. Dans son appartement à elle.\nD. Ma mère, comme souvent.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qui te garde ton fils ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à minuit, environ.<break time="700ms"/>B.<break time="300ms"/>Pour aller au cinéma.<break time="700ms"/>C.<break time="300ms"/>Dans son appartement à elle.<break time="700ms"/>D.<break time="300ms"/>Ma mère, comme souvent.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qui te garde ton fils ? » porte sur **l''identité de la personne qui garde**. Seule D « ma mère » désigne une personne. A donne **la durée** (« jusqu''à quand ? »). B donne **le but** (« pour quoi faire ? »). C donne **le lieu**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Objet (« qu'est-ce que tu manges ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000005', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Qu''est-ce que tu manges là ?\n[Femme] ...\n\nA. Un sandwich au poulet, tout simple.\nB. Au coin de la rue, à la boulangerie.\nC. Pour environ cinq euros, je crois.\nD. Avec mes collègues du bureau.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu manges là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un sandwich au poulet, tout simple.<break time="700ms"/>B.<break time="300ms"/>Au coin de la rue, à la boulangerie.<break time="700ms"/>C.<break time="300ms"/>Pour environ cinq euros, je crois.<break time="700ms"/>D.<break time="300ms"/>Avec mes collègues du bureau.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que tu manges ? » porte sur **la nourriture**. Seule A « un sandwich au poulet » nomme un plat. B donne **le lieu d''achat**. C donne **le prix**. D donne **l''accompagnement**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Choix simple (« quelle ? ») / commercial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000006', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu prends quelle baguette aujourd''hui ?\n[Homme] ...\n\nA. À la boulangerie du coin de la rue.\nB. La tradition, s''il vous plaît.\nC. Pour le déjeuner de ce midi.\nD. Avec un croissant en plus, peut-être.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu prends quelle baguette aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la boulangerie du coin de la rue.<break time="700ms"/>B.<break time="300ms"/>La tradition, s''il vous plaît.<break time="700ms"/>C.<break time="300ms"/>Pour le déjeuner de ce midi.<break time="700ms"/>D.<break time="300ms"/>Avec un croissant en plus, peut-être.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu prends quelle baguette ? » porte sur **le choix du type de pain**. Seule B « la tradition » désigne un type. A donne **le lieu d''achat**. C donne **le moment de consommation**. D donne **un produit additionnel**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Heure (« à quelle heure ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000007', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] À quelle heure tu te lèves d''habitude ?\n[Femme] ...\n\nA. Avec mon réveil sur le téléphone.\nB. Pour aller au sport très tôt.\nC. À sept heures pile, en semaine.\nD. Dans ma chambre, comme tout le monde.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure tu te lèves d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mon réveil sur le téléphone.<break time="700ms"/>B.<break time="300ms"/>Pour aller au sport très tôt.<break time="700ms"/>C.<break time="300ms"/>À sept heures pile, en semaine.<break time="700ms"/>D.<break time="300ms"/>Dans ma chambre, comme tout le monde.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quelle heure tu te lèves ? » porte sur **l''heure du réveil**. Seule C « à sept heures pile » donne une heure. A donne **le moyen** de se réveiller. B donne **le but**. D donne **le lieu**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Moyen de transport (« comment ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000008', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Comment tu vas au travail le matin ?\n[Homme] ...\n\nA. À la station Bastille, en général.\nB. Pour environ trente minutes de trajet.\nC. Pendant tout le mois de septembre.\nD. En métro, ligne cinq.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment tu vas au travail le matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la station Bastille, en général.<break time="700ms"/>B.<break time="300ms"/>Pour environ trente minutes de trajet.<break time="700ms"/>C.<break time="300ms"/>Pendant tout le mois de septembre.<break time="700ms"/>D.<break time="300ms"/>En métro, ligne cinq.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Comment tu vas au travail ? » porte sur **le moyen de transport**. Seule D « en métro, ligne cinq » nomme le moyen. A donne **un lieu / une station**. B donne **la durée**. C donne **une période**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Cause (« pourquoi ? ») / scolaire-professionnel -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000009', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Pourquoi tu es en retard, ce matin ?\n[Femme] ...\n\nA. À cause d''une grève des transports.\nB. Vers neuf heures et demie.\nC. Avec mon manteau et mon écharpe.\nD. Au bureau, comme d''habitude.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi tu es en retard, ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une grève des transports.<break time="700ms"/>B.<break time="300ms"/>Vers neuf heures et demie.<break time="700ms"/>C.<break time="300ms"/>Avec mon manteau et mon écharpe.<break time="700ms"/>D.<break time="300ms"/>Au bureau, comme d''habitude.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Pourquoi tu es en retard ? » porte sur **la cause du retard**. Seule A « à cause d''une grève » donne une cause. B donne **l''heure d''arrivée**. C donne **les habits portés**. D donne **le lieu d''arrivée**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Accompagnant (« avec qui ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Avec qui tu pars en vacances cet été ?\n[Homme] ...\n\nA. À Saint-Malo, en Bretagne.\nB. Avec mes deux meilleurs amis.\nC. Pour quinze jours pleins.\nD. En camping, près de la plage.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec qui tu pars en vacances cet été ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À Saint-Malo, en Bretagne.<break time="700ms"/>B.<break time="300ms"/>Avec mes deux meilleurs amis.<break time="700ms"/>C.<break time="300ms"/>Pour quinze jours pleins.<break time="700ms"/>D.<break time="300ms"/>En camping, près de la plage.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Avec qui tu pars ? » porte sur **les personnes qui t''accompagnent**. Seule B « avec mes deux meilleurs amis » désigne des personnes. A donne **le lieu**. C donne **la durée**. D donne **le mode d''hébergement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Depuis quand (« depuis combien de temps ? ») / professionnel -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu travailles ici depuis combien de temps ?\n[Femme] ...\n\nA. Au bureau du troisième étage.\nB. Pour la comptabilité, oui.\nC. Depuis presque trois ans déjà.\nD. Avec une dizaine de collègues.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu travailles ici depuis combien de temps ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bureau du troisième étage.<break time="700ms"/>B.<break time="300ms"/>Pour la comptabilité, oui.<break time="700ms"/>C.<break time="300ms"/>Depuis presque trois ans déjà.<break time="700ms"/>D.<break time="300ms"/>Avec une dizaine de collègues.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Depuis combien de temps tu travailles ici ? » porte sur **l''ancienneté**. Seule C « depuis presque trois ans » donne une durée écoulée. A donne **le lieu de travail**. B donne **le service / le poste**. D donne **les collègues**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Durée (« combien de temps ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as dormi combien de temps cette nuit ?\n[Homme] ...\n\nA. Pour me reposer du week-end.\nB. Dans la chambre du fond.\nC. Avec un masque sur les yeux.\nD. Sept bonnes heures, je crois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as dormi combien de temps cette nuit ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour me reposer du week-end.<break time="700ms"/>B.<break time="300ms"/>Dans la chambre du fond.<break time="700ms"/>C.<break time="300ms"/>Avec un masque sur les yeux.<break time="700ms"/>D.<break time="300ms"/>Sept bonnes heures, je crois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Combien de temps tu as dormi ? » porte sur **la durée du sommeil**. Seule D « sept bonnes heures » donne une durée. A donne **le but**. B donne **le lieu**. C donne **un accessoire utilisé**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Couleur (« de quelle couleur ? ») / commercial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] De quelle couleur est ta nouvelle voiture ?\n[Femme] ...\n\nA. Gris métallisé, très élégant.\nB. Chez le concessionnaire Peugeot.\nC. Pour environ vingt mille euros.\nD. Avec mon mari, samedi dernier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">De quelle couleur est ta nouvelle voiture ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Gris métallisé, très élégant.<break time="700ms"/>B.<break time="300ms"/>Chez le concessionnaire Peugeot.<break time="700ms"/>C.<break time="300ms"/>Pour environ vingt mille euros.<break time="700ms"/>D.<break time="300ms"/>Avec mon mari, samedi dernier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« De quelle couleur ? » porte sur **la couleur**. Seule A « gris métallisé » donne une couleur. B donne **le lieu d''achat**. C donne **le prix**. D donne **l''accompagnant et le moment**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Âge (« quel âge ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Ton petit-fils a quel âge maintenant ?\n[Homme] ...\n\nA. À l''école primaire, en CE2.\nB. Huit ans, depuis le mois dernier.\nC. Pour son anniversaire de septembre.\nD. Avec ses deux grandes sœurs.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton petit-fils a quel âge maintenant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''école primaire, en CE2.<break time="700ms"/>B.<break time="300ms"/>Huit ans, depuis le mois dernier.<break time="700ms"/>C.<break time="300ms"/>Pour son anniversaire de septembre.<break time="700ms"/>D.<break time="300ms"/>Avec ses deux grandes sœurs.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel âge ? » porte sur **l''âge**. Seule B « huit ans » donne un âge. A donne **la classe scolaire** (niveau, pas âge). C donne **un moment**. D donne **la fratrie**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Lieu géographique (« c'est où ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] C''est où, ton lieu de naissance ?\n[Femme] ...\n\nA. En mille neuf cent quatre-vingt-cinq exactement.\nB. Avec mes parents et ma grande sœur.\nC. À Lyon, dans le deuxième arrondissement.\nD. Pour des raisons familiales, à l''époque.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est où, ton lieu de naissance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En mille neuf cent quatre-vingt-cinq exactement.<break time="700ms"/>B.<break time="300ms"/>Avec mes parents et ma grande sœur.<break time="700ms"/>C.<break time="300ms"/>À Lyon, dans le deuxième arrondissement.<break time="700ms"/>D.<break time="300ms"/>Pour des raisons familiales, à l''époque.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« C''est où, ton lieu de naissance ? » porte sur **la ville / le lieu de naissance**. Seule C « à Lyon » donne un lieu. A donne **l''année de naissance**. B donne **la famille présente**. D donne **la cause**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Jour de la semaine (« quel jour ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000010', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as ton cours de yoga quel jour ?\n[Homme] ...\n\nA. Au centre sportif, près du parc.\nB. Avec une professeure très douce.\nC. Pour me détendre après le travail.\nD. Le mardi soir, de dix-huit à dix-neuf heures.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as ton cours de yoga quel jour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au centre sportif, près du parc.<break time="700ms"/>B.<break time="300ms"/>Avec une professeure très douce.<break time="700ms"/>C.<break time="300ms"/>Pour me détendre après le travail.<break time="700ms"/>D.<break time="300ms"/>Le mardi soir, de dix-huit à dix-neuf heures.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel jour ? » porte sur **le jour de la semaine**. Seule D « le mardi soir » nomme un jour. A donne **le lieu**. B donne **la personne qui enseigne**. C donne **le but / l''effet recherché**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Météo (« quel temps ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000011', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quel temps fait-il dehors, ce matin ?\n[Femme] ...\n\nA. Un grand soleil et plutôt chaud.\nB. Vers le parc Monceau, en face.\nC. Pour la promenade du chien.\nD. Avec mon parapluie, au cas où.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel temps fait-il dehors, ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un grand soleil et plutôt chaud.<break time="700ms"/>B.<break time="300ms"/>Vers le parc Monceau, en face.<break time="700ms"/>C.<break time="300ms"/>Pour la promenade du chien.<break time="700ms"/>D.<break time="300ms"/>Avec mon parapluie, au cas où.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel temps fait-il ? » porte sur **la météo**. Seule A « un grand soleil et plutôt chaud » décrit le temps. B donne **un lieu**. C donne **un but**. D donne **un accessoire**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Goût (« comment tu trouves ? ») / culinaire -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000012', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu trouves comment, cette nouvelle sauce ?\n[Homme] ...\n\nA. Pour accompagner les pâtes.\nB. Plutôt épicée, mais délicieuse.\nC. Avec les boulettes, à midi.\nD. Au supermarché en bas de chez moi.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu trouves comment, cette nouvelle sauce ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour accompagner les pâtes.<break time="700ms"/>B.<break time="300ms"/>Plutôt épicée, mais délicieuse.<break time="700ms"/>C.<break time="300ms"/>Avec les boulettes, à midi.<break time="700ms"/>D.<break time="300ms"/>Au supermarché en bas de chez moi.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu trouves comment ? » porte sur **le goût / l''appréciation**. Seule B « plutôt épicée, mais délicieuse » qualifie le goût. A donne **l''usage**. C donne **l''accompagnement et le moment**. D donne **le lieu d''achat**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Adresse (« où tu habites ? ») / administratif -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000013', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Où tu habites maintenant, exactement ?\n[Femme] ...\n\nA. Depuis trois mois seulement.\nB. Avec ma sœur et son chat.\nC. Rue de la Pompe, à Paris seizième.\nD. Pour me rapprocher du travail.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où tu habites maintenant, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis trois mois seulement.<break time="700ms"/>B.<break time="300ms"/>Avec ma sœur et son chat.<break time="700ms"/>C.<break time="300ms"/>Rue de la Pompe, à Paris seizième.<break time="700ms"/>D.<break time="300ms"/>Pour me rapprocher du travail.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Où tu habites ? » porte sur **l''adresse / le lieu d''habitation**. Seule C « rue de la Pompe, à Paris seizième » donne une adresse. A donne **depuis quand**. B donne **avec qui**. D donne **la raison du choix**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Préférence (« quel est ton... préféré ? ») / culinaire -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-2000-0000-000000000014', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel est ton fruit préféré ?\n[Homme] ...\n\nA. Au marché du dimanche matin.\nB. Pour la salade de fruits du dimanche.\nC. Avec un peu de sucre dessus.\nD. La fraise, sans hésiter une seconde.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton fruit préféré ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au marché du dimanche matin.<break time="700ms"/>B.<break time="300ms"/>Pour la salade de fruits du dimanche.<break time="700ms"/>C.<break time="300ms"/>Avec un peu de sucre dessus.<break time="700ms"/>D.<break time="300ms"/>La fraise, sans hésiter une seconde.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton fruit préféré ? » porte sur **le choix d''un fruit**. Seule D « la fraise, sans hésiter » nomme un fruit. A donne **le lieu d''achat**. B donne **l''usage culinaire**. C donne **un accompagnement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
