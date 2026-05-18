-- ============================================================
-- 22 exercices A2 (lot 4) - CO TCF - format "réponse à question implicite"
-- Une seule réplique (question directe), alternance Henri / Denise (11/11).
-- 22 nouveaux types A2 (aucun doublon avec V400 ni V405) :
-- période journée, langue, place cinéma, quartier, loisir,
-- plat du jour, boisson au repas, surnom, jour anniversaire,
-- pièce maison, activité dimanche, sport télé, couleur murs,
-- numéro chambre, forme, matière, taille vêtement, marque voiture,
-- type vacances, heure repas, pointure, nombre de fois.
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 6×A, 6×B, 5×C, 5×D.
-- ============================================================

-- ----- Exercice 1 : Période de la journée -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000001', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu préfères courir le matin ou le soir ?\n[Femme] ...\n\nA. Plutôt le matin, vers sept heures.\nB. Au parc, près de chez moi.\nC. Pour garder la forme et dormir mieux.\nD. Avec une amie du quartier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu préfères courir le matin ou le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt le matin, vers sept heures.<break time="700ms"/>B.<break time="300ms"/>Au parc, près de chez moi.<break time="700ms"/>C.<break time="300ms"/>Pour garder la forme et dormir mieux.<break time="700ms"/>D.<break time="300ms"/>Avec une amie du quartier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Le matin ou le soir ? » porte sur **la période de la journée préférée**. Seule A « plutôt le matin » choisit une période. B donne **le lieu** (« où ? »). C donne **le but / la raison** (« pourquoi ? »). D donne **l''accompagnant** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Langue parlée -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000002', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quelle langue tu parles avec tes parents à la maison ?\n[Homme] ...\n\nA. Depuis tout petit, déjà.\nB. L''arabe, surtout avec ma mère.\nC. Pour ne pas oublier mes origines.\nD. Au téléphone, presque tous les jours.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle langue tu parles avec tes parents à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis tout petit, déjà.<break time="700ms"/>B.<break time="300ms"/>L''arabe, surtout avec ma mère.<break time="700ms"/>C.<break time="300ms"/>Pour ne pas oublier mes origines.<break time="700ms"/>D.<break time="300ms"/>Au téléphone, presque tous les jours.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle langue tu parles ? » porte sur **la langue utilisée**. Seule B « l''arabe » nomme une langue. A donne **depuis quand**. C donne **la raison / le but**. D donne **le canal et la fréquence**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Place au cinéma -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000003', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quel siège tu prends au cinéma, en général ?\n[Femme] ...\n\nA. Au cinéma Pathé du centre-ville.\nB. Pour mieux voir les sous-titres.\nC. Au milieu de la salle, rangée H.\nD. Avec un grand pop-corn salé.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel siège tu prends au cinéma, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cinéma Pathé du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Pour mieux voir les sous-titres.<break time="700ms"/>C.<break time="300ms"/>Au milieu de la salle, rangée H.<break time="700ms"/>D.<break time="300ms"/>Avec un grand pop-corn salé.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel siège ? » porte sur **la place dans la salle**. Seule C « au milieu de la salle, rangée H » localise un siège précis. A donne **le cinéma fréquenté**. B donne **la raison**. D donne **un accompagnement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Quartier d'habitation -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000004', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Dans quel quartier tu habites, maintenant ?\n[Homme] ...\n\nA. Depuis le mois de janvier.\nB. Pour être près de mes parents.\nC. Avec deux colocataires sympas.\nD. Dans le quartier de la Croix-Rousse.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Dans quel quartier tu habites, maintenant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le mois de janvier.<break time="700ms"/>B.<break time="300ms"/>Pour être près de mes parents.<break time="700ms"/>C.<break time="300ms"/>Avec deux colocataires sympas.<break time="700ms"/>D.<break time="300ms"/>Dans le quartier de la Croix-Rousse.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Dans quel quartier ? » porte sur **le nom du quartier**. Seule D « le quartier de la Croix-Rousse » nomme un quartier. A donne **depuis quand**. B donne **la raison du choix**. C donne **les colocataires**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Loisir préféré -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000005', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quel est ton loisir préféré, le week-end ?\n[Femme] ...\n\nA. Tous les samedis après-midi.\nB. La peinture à l''aquarelle, sans hésiter.\nC. Pour me détendre après la semaine.\nD. À la maison, dans mon atelier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel est ton loisir préféré, le week-end ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Tous les samedis après-midi.<break time="700ms"/>B.<break time="300ms"/>La peinture à l''aquarelle, sans hésiter.<break time="700ms"/>C.<break time="300ms"/>Pour me détendre après la semaine.<break time="700ms"/>D.<break time="300ms"/>À la maison, dans mon atelier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton loisir préféré ? » porte sur **l''activité choisie**. Seule B « la peinture à l''aquarelle » nomme un loisir. A donne **la fréquence**. C donne **le but / la raison**. D donne **le lieu de pratique**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Plat du jour au restaurant -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000006', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Qu''est-ce qu''il y a comme plat du jour aujourd''hui ?\n[Homme] ...\n\nA. Un blanquette de veau avec du riz.\nB. Pour douze euros cinquante, boisson comprise.\nC. Dans la salle du fond, à droite.\nD. Vers midi et demi, en général.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qu''il y a comme plat du jour aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un blanquette de veau avec du riz.<break time="700ms"/>B.<break time="300ms"/>Pour douze euros cinquante, boisson comprise.<break time="700ms"/>C.<break time="300ms"/>Dans la salle du fond, à droite.<break time="700ms"/>D.<break time="300ms"/>Vers midi et demi, en général.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qu''il y a comme plat du jour ? » porte sur **l''identité du plat servi**. Seule A « une blanquette de veau avec du riz » nomme un plat. B donne **le prix**. C donne **le lieu dans le restaurant**. D donne **l''heure du service**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Boisson au repas -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000007', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Qu''est-ce que tu bois à table, le soir ?\n[Femme] ...\n\nA. Pour bien digérer mon repas.\nB. Au verre, en général un seul.\nC. Avec mes enfants à table.\nD. Une carafe d''eau bien fraîche.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu bois à table, le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour bien digérer mon repas.<break time="700ms"/>B.<break time="300ms"/>Au verre, en général un seul.<break time="700ms"/>C.<break time="300ms"/>Avec mes enfants à table.<break time="700ms"/>D.<break time="300ms"/>Une carafe d''eau bien fraîche.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que tu bois à table ? » porte sur **la boisson consommée**. Seule D « une carafe d''eau bien fraîche » nomme une boisson. A donne **la raison**. B donne **le contenant et la quantité**. C donne **l''accompagnant**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Surnom -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000008', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel est ton surnom à la maison ?\n[Homme] ...\n\nA. Depuis que je suis tout petit.\nB. Par mes frères et sœurs, surtout.\nC. Loulou, c''est ma mère qui l''a choisi.\nD. Pour rire, en général.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton surnom à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis que je suis tout petit.<break time="700ms"/>B.<break time="300ms"/>Par mes frères et sœurs, surtout.<break time="700ms"/>C.<break time="300ms"/>Loulou, c''est ma mère qui l''a choisi.<break time="700ms"/>D.<break time="300ms"/>Pour rire, en général.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton surnom ? » porte sur **le surnom lui-même**. Seule C « Loulou » nomme un surnom. A donne **depuis quand**. B donne **par qui tu es appelé ainsi**. D donne **dans quel esprit**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Jour d'anniversaire -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000009', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quel jour tu fêtes ton anniversaire ?\n[Femme] ...\n\nA. Le quinze mai, chaque année.\nB. Avec toute ma famille réunie.\nC. Au restaurant, comme d''habitude.\nD. Pour mes trente ans, cette fois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel jour tu fêtes ton anniversaire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le quinze mai, chaque année.<break time="700ms"/>B.<break time="300ms"/>Avec toute ma famille réunie.<break time="700ms"/>C.<break time="300ms"/>Au restaurant, comme d''habitude.<break time="700ms"/>D.<break time="300ms"/>Pour mes trente ans, cette fois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel jour tu fêtes ton anniversaire ? » porte sur **la date**. Seule A « le quinze mai » donne une date. B donne **avec qui**. C donne **le lieu**. D donne **l''âge fêté / la raison spéciale**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Pièce de la maison -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Dans quelle pièce tu travailles à la maison ?\n[Homme] ...\n\nA. Pour être au calme, surtout.\nB. Pendant toute la matinée.\nC. Avec mon ordinateur portable.\nD. Dans le bureau du premier étage.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Dans quelle pièce tu travailles à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour être au calme, surtout.<break time="700ms"/>B.<break time="300ms"/>Pendant toute la matinée.<break time="700ms"/>C.<break time="300ms"/>Avec mon ordinateur portable.<break time="700ms"/>D.<break time="300ms"/>Dans le bureau du premier étage.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Dans quelle pièce ? » porte sur **la pièce de la maison utilisée**. Seule D « dans le bureau du premier étage » nomme une pièce. A donne **la raison**. B donne **la durée**. C donne **l''outil utilisé**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Activité du dimanche -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Qu''est-ce que tu fais le dimanche, en général ?\n[Femme] ...\n\nA. Au parc à côté de chez moi.\nB. Une grande balade en forêt.\nC. Pour profiter du grand air.\nD. Avec mon mari et les enfants.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu fais le dimanche, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au parc à côté de chez moi.<break time="700ms"/>B.<break time="300ms"/>Une grande balade en forêt.<break time="700ms"/>C.<break time="300ms"/>Pour profiter du grand air.<break time="700ms"/>D.<break time="300ms"/>Avec mon mari et les enfants.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que tu fais le dimanche ? » porte sur **l''activité pratiquée**. Seule B « une grande balade en forêt » nomme une activité. A donne **le lieu**. C donne **le but**. D donne **avec qui**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Sport favori à regarder à la télé -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel sport tu regardes le plus à la télé ?\n[Homme] ...\n\nA. Sur la chaîne sport, en direct.\nB. Avec mes copains, le samedi soir.\nC. Le rugby, surtout les matchs internationaux.\nD. Pour soutenir l''équipe de France.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel sport tu regardes le plus à la télé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la chaîne sport, en direct.<break time="700ms"/>B.<break time="300ms"/>Avec mes copains, le samedi soir.<break time="700ms"/>C.<break time="300ms"/>Le rugby, surtout les matchs internationaux.<break time="700ms"/>D.<break time="300ms"/>Pour soutenir l''équipe de France.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel sport tu regardes ? » porte sur **le sport regardé**. Seule C « le rugby » nomme un sport. A donne **la chaîne / le canal**. B donne **avec qui et quand**. D donne **la raison**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Couleur des murs d'une pièce -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] De quelle couleur sont les murs de ton salon ?\n[Femme] ...\n\nA. Pour donner une impression de lumière.\nB. Avec mon mari, en deux jours.\nC. Dans la grande pièce du fond.\nD. Beige clair, presque crème.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">De quelle couleur sont les murs de ton salon ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour donner une impression de lumière.<break time="700ms"/>B.<break time="300ms"/>Avec mon mari, en deux jours.<break time="700ms"/>C.<break time="300ms"/>Dans la grande pièce du fond.<break time="700ms"/>D.<break time="300ms"/>Beige clair, presque crème.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« De quelle couleur sont les murs ? » porte sur **la couleur de la peinture**. Seule D « beige clair, presque crème » donne une couleur. A donne **la raison du choix**. B donne **avec qui et en combien de temps tu as peint**. C donne **la pièce concernée**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Numéro de chambre d'hôtel -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quelle chambre on vous a donnée à l''hôtel ?\n[Homme] ...\n\nA. La deux cent quatorze, au deuxième étage.\nB. Pour deux nuits seulement.\nC. Avec une jolie vue sur la mer.\nD. À l''Hôtel des Voyageurs, près de la gare.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle chambre on vous a donnée à l''hôtel ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La deux cent quatorze, au deuxième étage.<break time="700ms"/>B.<break time="300ms"/>Pour deux nuits seulement.<break time="700ms"/>C.<break time="300ms"/>Avec une jolie vue sur la mer.<break time="700ms"/>D.<break time="300ms"/>À l''Hôtel des Voyageurs, près de la gare.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle chambre ? » porte sur **le numéro de la chambre**. Seule A « la deux cent quatorze » donne un numéro. B donne **la durée du séjour**. C donne **une caractéristique de la chambre**. D donne **le nom de l''hôtel et son lieu**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Forme d'un objet -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quelle forme a ta nouvelle table de salon ?\n[Femme] ...\n\nA. En bois clair, très naturel.\nB. Ronde, avec un pied central.\nC. Pour environ trois cents euros.\nD. Au magasin de meubles du centre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle forme a ta nouvelle table de salon ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En bois clair, très naturel.<break time="700ms"/>B.<break time="300ms"/>Ronde, avec un pied central.<break time="700ms"/>C.<break time="300ms"/>Pour environ trois cents euros.<break time="700ms"/>D.<break time="300ms"/>Au magasin de meubles du centre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle forme ? » porte sur **la forme géométrique**. Seule B « ronde » indique une forme. A donne **la matière**. C donne **le prix**. D donne **le lieu d''achat**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Matière d'un objet -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000010', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] En quelle matière est ton nouveau pull ?\n[Homme] ...\n\nA. Pour l''hiver, surtout.\nB. Dans une boutique en ligne.\nC. En laine douce, cent pour cent.\nD. Avec un col roulé, très chaud.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quelle matière est ton nouveau pull ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour l''hiver, surtout.<break time="700ms"/>B.<break time="300ms"/>Dans une boutique en ligne.<break time="700ms"/>C.<break time="300ms"/>En laine douce, cent pour cent.<break time="700ms"/>D.<break time="300ms"/>Avec un col roulé, très chaud.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« En quelle matière ? » porte sur **la matière textile**. Seule C « en laine douce, cent pour cent » donne une matière. A donne **la saison d''usage**. B donne **le lieu d''achat**. D donne **la coupe du vêtement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Taille d'un vêtement -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000011', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu fais quelle taille pour les chemises ?\n[Femme] ...\n\nA. Du trente-huit, en général.\nB. Dans la boutique du centre commercial.\nC. Pour aller au bureau, surtout.\nD. Avec un col bien classique.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fais quelle taille pour les chemises ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du trente-huit, en général.<break time="700ms"/>B.<break time="300ms"/>Dans la boutique du centre commercial.<break time="700ms"/>C.<break time="300ms"/>Pour aller au bureau, surtout.<break time="700ms"/>D.<break time="300ms"/>Avec un col bien classique.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle taille pour les chemises ? » porte sur **la taille vestimentaire**. Seule A « du trente-huit » donne une taille. B donne **le lieu d''achat**. C donne **l''usage**. D donne **un détail de coupe**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Marque d'une voiture -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000012', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quelle marque de voiture tu as achetée ?\n[Homme] ...\n\nA. Pour les longs trajets familiaux.\nB. Une Renault, le modèle Clio.\nC. Chez un concessionnaire en banlieue.\nD. Avec ma femme, samedi dernier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle marque de voiture tu as achetée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour les longs trajets familiaux.<break time="700ms"/>B.<break time="300ms"/>Une Renault, le modèle Clio.<break time="700ms"/>C.<break time="300ms"/>Chez un concessionnaire en banlieue.<break time="700ms"/>D.<break time="300ms"/>Avec ma femme, samedi dernier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle marque de voiture ? » porte sur **la marque du véhicule**. Seule B « une Renault, le modèle Clio » nomme une marque. A donne **l''usage prévu**. C donne **le lieu d''achat**. D donne **avec qui et quand**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Type de vacances -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000013', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quel genre de vacances tu préfères ?\n[Femme] ...\n\nA. En juillet, plutôt qu''en août.\nB. À la montagne, dans les Alpes.\nC. Avec mes deux enfants, toujours.\nD. Des vacances tranquilles à la mer.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel genre de vacances tu préfères ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En juillet, plutôt qu''en août.<break time="700ms"/>B.<break time="300ms"/>À la montagne, dans les Alpes.<break time="700ms"/>C.<break time="300ms"/>Avec mes deux enfants, toujours.<break time="700ms"/>D.<break time="300ms"/>Des vacances tranquilles à la mer.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel genre de vacances ? » porte sur **le type de séjour préféré**. Seule D « des vacances tranquilles à la mer » qualifie un genre. A donne **le mois**. B donne **un lieu géographique précis**. C donne **avec qui**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Heure du repas -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000014', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] À quelle heure on mange ce soir ?\n[Homme] ...\n\nA. Dans la cuisine, comme d''habitude.\nB. Vers vingt heures, je dirais.\nC. Avec les voisins du dessous.\nD. Pour terminer mon dossier avant.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À quelle heure on mange ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la cuisine, comme d''habitude.<break time="700ms"/>B.<break time="300ms"/>Vers vingt heures, je dirais.<break time="700ms"/>C.<break time="300ms"/>Avec les voisins du dessous.<break time="700ms"/>D.<break time="300ms"/>Pour terminer mon dossier avant.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quelle heure on mange ? » porte sur **l''heure du repas**. Seule B « vers vingt heures » donne une heure. A donne **le lieu**. C donne **avec qui**. D donne **la raison du retard / l''attente**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 21 : Pointure de chaussures -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000015', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu fais quelle pointure de chaussures ?\n[Femme] ...\n\nA. Dans le magasin à côté de la mairie.\nB. Pour aller marcher en forêt, surtout.\nC. Du quarante, parfois quarante et un.\nD. Avec des semelles confortables dedans.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fais quelle pointure de chaussures ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans le magasin à côté de la mairie.<break time="700ms"/>B.<break time="300ms"/>Pour aller marcher en forêt, surtout.<break time="700ms"/>C.<break time="300ms"/>Du quarante, parfois quarante et un.<break time="700ms"/>D.<break time="300ms"/>Avec des semelles confortables dedans.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle pointure ? » porte sur **la taille des pieds en chiffre**. Seule C « du quarante, parfois quarante et un » donne une pointure. A donne **le lieu d''achat**. B donne **l''usage prévu**. D donne **un accessoire complémentaire**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 22 : Nombre de fois (déjà fait quelque chose) -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-4000-0000-000000000016', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as vu ce film combien de fois déjà ?\n[Homme] ...\n\nA. Trois fois, je crois bien.\nB. Au cinéma, et deux fois à la télé.\nC. Avec mon frère, à chaque fois.\nD. Parce que j''adore l''acteur principal.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as vu ce film combien de fois déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois fois, je crois bien.<break time="700ms"/>B.<break time="300ms"/>Au cinéma, et deux fois à la télé.<break time="700ms"/>C.<break time="300ms"/>Avec mon frère, à chaque fois.<break time="700ms"/>D.<break time="300ms"/>Parce que j''adore l''acteur principal.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Combien de fois ? » porte sur **le nombre total de visionnages**. Seule A « trois fois » donne un nombre clair de répétitions. B donne **les lieux / supports de visionnage** (« où ? ») et mélange deux infos sans total clair. C donne **avec qui**. D donne **la raison** de l''aimer.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
