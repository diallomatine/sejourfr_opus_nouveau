-- ============================================================
-- 20 exercices B1 (lot 2) - CO TCF - format "réponse à question implicite"
-- Dialogues de 2 à 3 tours (alternance Henri / Denise),
-- 20 types de question implicite différents de V401.
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 5×A, 5×B, 5×C, 5×D.
-- ============================================================

-- ----- Exercice 1 : Type d'objet (« de quoi tu parles ? ») / quotidien / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000001', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu peux me passer ça, sur la table de la cuisine ?\n[Homme] Tu parles de quoi, exactement ?\n[Femme] ...\n\nA. Sur la grande table, juste là.\nB. Pour préparer le repas de ce soir.\nC. Le grand bol bleu, à droite.\nD. Avec le couvercle en verre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu peux me passer ça, sur la table de la cuisine ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu parles de quoi, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la grande table, juste là.<break time="700ms"/>B.<break time="300ms"/>Pour préparer le repas de ce soir.<break time="700ms"/>C.<break time="300ms"/>Le grand bol bleu, à droite.<break time="700ms"/>D.<break time="300ms"/>Avec le couvercle en verre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question « tu parles de quoi ? » demande **l''identification de l''objet** désigné par « ça ». Seule C « le grand bol bleu » nomme un objet. A donne le **lieu** où il se trouve. B donne le **but** de la demande. D donne un **accessoire** qui l''accompagne.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Couleur / commercial / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000002', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] J''ai vu sur ta photo ton nouveau vélo. Il est de quelle couleur en vrai ?\n[Homme] ...\n\nA. Un vélo électrique tout neuf.\nB. Bleu foncé avec des liserés blancs.\nC. Pour mes trajets au travail.\nD. Chez un magasin de la Bastille.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">J''ai vu sur ta photo ton nouveau vélo. Il est de quelle couleur en vrai ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un vélo électrique tout neuf.<break time="700ms"/>B.<break time="300ms"/>Bleu foncé avec des liserés blancs.<break time="700ms"/>C.<break time="300ms"/>Pour mes trajets au travail.<break time="700ms"/>D.<break time="300ms"/>Chez un magasin de la Bastille.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question porte sur **la couleur du vélo**. Seule B « bleu foncé avec des liserés blancs » donne une couleur. A donne **le type de vélo** (« quel type ? »). C donne **l''usage** (« pour quoi faire ? »). D donne **le lieu d''achat** (« où l''as-tu acheté ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Moyen de transport / quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000003', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu pars travailler tôt, dis-moi.\n[Homme] Oui, j''ai presque une heure de trajet.\n[Femme] Tu y vas comment, en général ?\n[Homme] ...\n\nA. À six heures et quart précises.\nB. Pour une bonne heure environ.\nC. À cause des bouchons constants en voiture.\nD. En train, puis à pied jusqu''au bureau.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu pars travailler tôt, dis-moi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai presque une heure de trajet.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu y vas comment, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À six heures et quart précises.<break time="700ms"/>B.<break time="300ms"/>Pour une bonne heure environ.<break time="700ms"/>C.<break time="300ms"/>À cause des bouchons constants en voiture.<break time="700ms"/>D.<break time="300ms"/>En train, puis à pied jusqu''au bureau.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu y vas comment, en général ? » porte sur **le moyen de transport habituel**. Seule D « en train, puis à pied » nomme les moyens utilisés. A donne **l''heure de départ**. B donne **la durée du trajet**. C donne **une cause expliquant un autre choix** (« pourquoi pas en voiture ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Heure précise / rendez-vous médical / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000004', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu pars chez le médecin tout à l''heure ?\n[Femme] Oui, c''est confirmé.\n[Homme] Et à quelle heure exactement ?\n[Femme] ...\n\nA. À seize heures trente, normalement.\nB. Pour un simple contrôle annuel.\nC. Près de la place du marché.\nD. Avec mon nouveau généraliste.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu pars chez le médecin tout à l''heure ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est confirmé.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et à quelle heure exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À seize heures trente, normalement.<break time="700ms"/>B.<break time="300ms"/>Pour un simple contrôle annuel.<break time="700ms"/>C.<break time="300ms"/>Près de la place du marché.<break time="700ms"/>D.<break time="300ms"/>Avec mon nouveau généraliste.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quelle heure exactement ? » porte sur **l''heure précise du rendez-vous**. Seule A « à seize heures trente » donne une heure. B donne **le motif de la consultation**. C donne **le lieu** du cabinet. D donne **l''interlocuteur médical**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Nombre d'invités / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000005', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as donné ton dîner d''anniversaire hier soir, c''est ça ?\n[Homme] Oui, à la maison.\n[Femme] Vous étiez combien, finalement ?\n[Homme] ...\n\nA. Avec un menu très convivial.\nB. Une douzaine, en comptant les enfants.\nC. Jusqu''à minuit, environ.\nD. Dans le jardin, sous la tonnelle.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as donné ton dîner d''anniversaire hier soir, c''est ça ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, à la maison.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous étiez combien, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un menu très convivial.<break time="700ms"/>B.<break time="300ms"/>Une douzaine, en comptant les enfants.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à minuit, environ.<break time="700ms"/>D.<break time="300ms"/>Dans le jardin, sous la tonnelle.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Vous étiez combien ? » porte sur **le nombre de convives**. Seule B « une douzaine » donne un nombre. A donne **la qualité du repas** (« comment était le menu ? »). C donne **l''heure de fin** (« jusqu''à quand ? »). D donne **le lieu** (« où dîniez-vous ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Plat préparé / culinaire / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000006', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''avais dit que tu cuisinais tout le repas toi-même.\n[Femme] Oui, j''ai passé l''après-midi en cuisine.\n[Homme] Et tu as préparé quoi, alors ?\n[Femme] ...\n\nA. Pendant presque quatre bonnes heures.\nB. Pour une douzaine d''invités, je l''ai dit.\nC. Un tajine d''agneau aux pruneaux.\nD. Avec ma mère qui m''a aidée pour le dessert.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''avais dit que tu cuisinais tout le repas toi-même.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai passé l''après-midi en cuisine.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu as préparé quoi, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant presque quatre bonnes heures.<break time="700ms"/>B.<break time="300ms"/>Pour une douzaine d''invités, je l''ai dit.<break time="700ms"/>C.<break time="300ms"/>Un tajine d''agneau aux pruneaux.<break time="700ms"/>D.<break time="300ms"/>Avec ma mère qui m''a aidée pour le dessert.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as préparé quoi ? » porte sur **le plat cuisiné**. Seule C « un tajine d''agneau aux pruneaux » nomme un plat. A donne **la durée** passée en cuisine. B donne **le nombre de convives**. D donne **l''aide reçue** (« avec qui as-tu cuisiné ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Style musical / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000007', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu écoutes de la musique au travail ?\n[Homme] Tout le temps, ça m''aide à me concentrer.\n[Femme] Et quel style, plutôt ?\n[Homme] ...\n\nA. Avec un casque sans fil très pratique.\nB. Pendant toute la journée, sans discontinuer.\nC. Pour rester bien concentré, justement.\nD. Du jazz instrumental, surtout.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu écoutes de la musique au travail ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tout le temps, ça m''aide à me concentrer.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel style, plutôt ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un casque sans fil très pratique.<break time="700ms"/>B.<break time="300ms"/>Pendant toute la journée, sans discontinuer.<break time="700ms"/>C.<break time="300ms"/>Pour rester bien concentré, justement.<break time="700ms"/>D.<break time="300ms"/>Du jazz instrumental, surtout.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel style, plutôt ? » porte sur **le genre musical écouté**. Seule D « du jazz instrumental » désigne un style. A donne **le matériel utilisé** (« avec quoi écoutes-tu ? »). B donne **la durée d''écoute**. C donne **le but** (« pourquoi en écoutes-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Sentiment ressenti / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000008', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as appris la nouvelle pour la promotion de ton frère ?\n[Femme] Oui, il m''a appelée hier.\n[Homme] Tu as ressenti quoi, en l''apprenant ?\n[Femme] ...\n\nA. Une vraie fierté pour lui, à vrai dire.\nB. À cause de tous ses efforts, je crois.\nC. Pendant un long appel téléphonique.\nD. Avec ma sœur qui était présente.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as appris la nouvelle pour la promotion de ton frère ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, il m''a appelée hier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as ressenti quoi, en l''apprenant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une vraie fierté pour lui, à vrai dire.<break time="700ms"/>B.<break time="300ms"/>À cause de tous ses efforts, je crois.<break time="700ms"/>C.<break time="300ms"/>Pendant un long appel téléphonique.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur qui était présente.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as ressenti quoi ? » porte sur **l''émotion personnelle** éprouvée. Seule A « une vraie fierté pour lui » nomme un sentiment. B donne **la cause de la promotion** du frère (« pourquoi a-t-il été promu ? »). C donne **la durée de l''appel**. D donne **l''accompagnante**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Cadeau offert / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000009', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fini par trouver un cadeau d''anniversaire pour ta nièce ?\n[Homme] Oui, j''ai eu de la chance.\n[Femme] Tu lui as offert quoi, finalement ?\n[Homme] ...\n\nA. Pour ses huit ans, comme prévu.\nB. Une jolie raquette de tennis.\nC. Dans un magasin de sport de la galerie.\nD. Avec ma femme, samedi après-midi.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par trouver un cadeau d''anniversaire pour ta nièce ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai eu de la chance.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lui as offert quoi, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour ses huit ans, comme prévu.<break time="700ms"/>B.<break time="300ms"/>Une jolie raquette de tennis.<break time="700ms"/>C.<break time="300ms"/>Dans un magasin de sport de la galerie.<break time="700ms"/>D.<break time="300ms"/>Avec ma femme, samedi après-midi.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu lui as offert quoi ? » porte sur **la nature de l''objet offert**. Seule B « une jolie raquette de tennis » nomme un cadeau. A donne **l''occasion** (« pour quel motif ? »). C donne **le lieu d''achat**. D donne **l''accompagnement et le moment** de l''achat.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Élément surprenant / social-voyage / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000a', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu reviens de ton week-end à la campagne ?\n[Femme] Oui, et franchement, je suis sous le charme.\n[Homme] Qu''est-ce qui t''a le plus surprise, là-bas ?\n[Femme] ...\n\nA. Pendant deux nuits seulement.\nB. Avec mon mari et nos enfants.\nC. Le calme absolu de la nuit.\nD. Près de Chartres, en Eure-et-Loir.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens de ton week-end à la campagne ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, et franchement, je suis sous le charme.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus surprise, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux nuits seulement.<break time="700ms"/>B.<break time="300ms"/>Avec mon mari et nos enfants.<break time="700ms"/>C.<break time="300ms"/>Le calme absolu de la nuit.<break time="700ms"/>D.<break time="300ms"/>Près de Chartres, en Eure-et-Loir.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''a le plus surprise ? » porte sur **l''élément qui a marqué / étonné**. Seule C « le calme absolu de la nuit » désigne un tel élément. A donne **la durée du séjour**. B donne **les accompagnants**. D donne **le lieu**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Programme du week-end / social / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000b', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Alors, tes plans pour le week-end qui arrive ?\n[Femme] Rien d''extraordinaire, tu sais. Et toi, tu fais quoi ?\n[Homme] ...\n\nA. À cause du beau temps annoncé.\nB. Avec ma cousine en visite à Paris.\nC. Pour me reposer un peu, surtout.\nD. Du rangement et un peu de lecture.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors, tes plans pour le week-end qui arrive ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Rien d''extraordinaire, tu sais. Et toi, tu fais quoi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause du beau temps annoncé.<break time="700ms"/>B.<break time="300ms"/>Avec ma cousine en visite à Paris.<break time="700ms"/>C.<break time="300ms"/>Pour me reposer un peu, surtout.<break time="700ms"/>D.<break time="300ms"/>Du rangement et un peu de lecture.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question retournée « et toi, tu fais quoi ? » porte sur **les activités prévues**. Seule D « du rangement et un peu de lecture » liste des activités. A donne **une cause / motif** (« pourquoi sortir ? »). B donne **l''accompagnante**. C donne **le but général** (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Coût total / financier / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000c', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu reviens du garage avec ta voiture ?\n[Femme] Oui, ils m''ont fait toute la révision.\n[Homme] Et ça t''a coûté combien en tout ?\n[Femme] ...\n\nA. Près de quatre cents euros, finalement.\nB. Pendant presque deux heures de travail.\nC. Avec le changement des freins inclus.\nD. Chez un garagiste vraiment de confiance.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens du garage avec ta voiture ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ils m''ont fait toute la révision.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et ça t''a coûté combien en tout ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près de quatre cents euros, finalement.<break time="700ms"/>B.<break time="300ms"/>Pendant presque deux heures de travail.<break time="700ms"/>C.<break time="300ms"/>Avec le changement des freins inclus.<break time="700ms"/>D.<break time="300ms"/>Chez un garagiste vraiment de confiance.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Ça t''a coûté combien en tout ? » porte sur **le prix total payé**. Seule A « près de quatre cents euros » donne un montant. B donne **la durée de l''intervention**. C donne **les prestations incluses**. D donne **le lieu / la qualité du garage**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Profession / social / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000d', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] J''ai croisé ton nouveau voisin hier matin. Il a l''air sympa. Il fait quoi dans la vie ?\n[Homme] ...\n\nA. Depuis quelques mois seulement chez nous.\nB. Architecte dans une petite agence parisienne.\nC. Au troisième étage, juste au-dessus.\nD. Avec sa famille au grand complet.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">J''ai croisé ton nouveau voisin hier matin. Il a l''air sympa. Il fait quoi dans la vie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis quelques mois seulement chez nous.<break time="700ms"/>B.<break time="300ms"/>Architecte dans une petite agence parisienne.<break time="700ms"/>C.<break time="300ms"/>Au troisième étage, juste au-dessus.<break time="700ms"/>D.<break time="300ms"/>Avec sa famille au grand complet.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Il fait quoi dans la vie ? » porte sur **la profession du voisin**. Seule B « architecte dans une petite agence » nomme un métier. A donne **depuis quand il habite là**. C donne **son étage**. D donne **sa composition familiale**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Date / administratif / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000e', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''as parlé d''un rendez-vous important à venir.\n[Femme] Oui, un entretien d''embauche très attendu.\n[Homme] C''est prévu pour quelle date ?\n[Femme] ...\n\nA. Pour un poste de chef de projet.\nB. Au siège de l''entreprise à La Défense.\nC. Le quinze du mois prochain.\nD. Avec deux responsables des ressources humaines.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as parlé d''un rendez-vous important à venir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, un entretien d''embauche très attendu.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est prévu pour quelle date ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour un poste de chef de projet.<break time="700ms"/>B.<break time="300ms"/>Au siège de l''entreprise à La Défense.<break time="700ms"/>C.<break time="300ms"/>Le quinze du mois prochain.<break time="700ms"/>D.<break time="300ms"/>Avec deux responsables des ressources humaines.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« C''est prévu pour quelle date ? » porte sur **la date du rendez-vous**. Seule C « le quinze du mois prochain » donne une date. A donne **le poste visé**. B donne **le lieu de l''entretien**. D donne **les interlocuteurs**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Météo pendant un séjour / voyage / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-00000000000f', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu reviens tout juste de Normandie, je crois ?\n[Homme] Oui, trois jours formidables.\n[Femme] Vous avez eu quel temps, là-bas ?\n[Homme] ...\n\nA. Avec une amie d''enfance et son fils.\nB. Pendant le week-end de Pâques exactement.\nC. À côté de Deauville, sur la côte.\nD. Du soleil presque tout le séjour.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens tout juste de Normandie, je crois ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, trois jours formidables.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez eu quel temps, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une amie d''enfance et son fils.<break time="700ms"/>B.<break time="300ms"/>Pendant le week-end de Pâques exactement.<break time="700ms"/>C.<break time="300ms"/>À côté de Deauville, sur la côte.<break time="700ms"/>D.<break time="300ms"/>Du soleil presque tout le séjour.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Vous avez eu quel temps ? » porte sur **la météo** pendant le séjour. Seule D « du soleil presque tout le séjour » décrit le temps. A donne **les accompagnants**. B donne **la période** du séjour. C donne **le lieu précis**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Distance / géographique / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000010', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu vas souvent voir ta famille en province ?\n[Femme] Plusieurs fois par an, oui.\n[Homme] C''est à quelle distance, déjà ?\n[Femme] ...\n\nA. À environ trois cent cinquante kilomètres.\nB. Toutes les six semaines à peu près.\nC. En train direct, sans correspondance.\nD. Pour passer toutes les fêtes ensemble.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu vas souvent voir ta famille en province ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Plusieurs fois par an, oui.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est à quelle distance, déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À environ trois cent cinquante kilomètres.<break time="700ms"/>B.<break time="300ms"/>Toutes les six semaines à peu près.<break time="700ms"/>C.<break time="300ms"/>En train direct, sans correspondance.<break time="700ms"/>D.<break time="300ms"/>Pour passer toutes les fêtes ensemble.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« C''est à quelle distance ? » porte sur **la distance géographique**. Seule A « à environ trois cent cinquante kilomètres » donne une distance. B donne **la fréquence des visites**. C donne **le moyen de transport**. D donne **le but / l''occasion**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Recommandation de restaurant / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000011', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu connais bien le quartier, tu m''as dit.\n[Homme] J''y vis depuis dix ans, oui.\n[Femme] Tu me recommanderais quel restaurant pour ce soir ?\n[Homme] ...\n\nA. Pour environ trente euros la personne.\nB. Le petit italien au coin de la rue.\nC. À deux pas de la station de métro.\nD. Plutôt vers vingt heures, pour bien dîner.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu connais bien le quartier, tu m''as dit.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''y vis depuis dix ans, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu me recommanderais quel restaurant pour ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour environ trente euros la personne.<break time="700ms"/>B.<break time="300ms"/>Le petit italien au coin de la rue.<break time="700ms"/>C.<break time="300ms"/>À deux pas de la station de métro.<break time="700ms"/>D.<break time="300ms"/>Plutôt vers vingt heures, pour bien dîner.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu me recommanderais quel restaurant ? » appelle **le nom / la désignation d''un restaurant**. Seule B « le petit italien au coin de la rue » identifie un établissement. A donne **le prix moyen**. C donne **la localisation**. D donne **l''heure conseillée**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Disponibilité / social / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000012', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On se voit cette semaine pour le café qu''on s''était promis ?\n[Femme] Oui, avec plaisir ! Tu es libre quand ?\n[Homme] ...\n\nA. Pour rattraper le temps perdu, vraiment.\nB. Avec ma collègue Catherine, aussi.\nC. Mercredi après-midi, sans souci.\nD. Dans un café près de Bastille.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On se voit cette semaine pour le café qu''on s''était promis ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, avec plaisir ! Tu es libre quand ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour rattraper le temps perdu, vraiment.<break time="700ms"/>B.<break time="300ms"/>Avec ma collègue Catherine, aussi.<break time="700ms"/>C.<break time="300ms"/>Mercredi après-midi, sans souci.<break time="700ms"/>D.<break time="300ms"/>Dans un café près de Bastille.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu es libre quand ? » porte sur **un créneau de disponibilité**. Seule C « mercredi après-midi » donne un créneau précis. A donne **un but / motif**. B donne **un accompagnement potentiel**. D donne **un lieu**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Plat préféré parmi plusieurs / culinaire / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000013', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as bien aimé le repas chez les Dupont, hier ?\n[Homme] C''était excellent, vraiment.\n[Femme] Tu as préféré quoi, dans tout ce qu''elle a servi ?\n[Homme] ...\n\nA. Pour environ une dizaine d''invités.\nB. Jusqu''à très tard dans la nuit.\nC. Avec les voisins du dessus, aussi.\nD. Le tiramisu fait maison, sans hésiter.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as bien aimé le repas chez les Dupont, hier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''était excellent, vraiment.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as préféré quoi, dans tout ce qu''elle a servi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour environ une dizaine d''invités.<break time="700ms"/>B.<break time="300ms"/>Jusqu''à très tard dans la nuit.<break time="700ms"/>C.<break time="300ms"/>Avec les voisins du dessus, aussi.<break time="700ms"/>D.<break time="300ms"/>Le tiramisu fait maison, sans hésiter.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as préféré quoi, dans tout ce qu''elle a servi ? » porte sur **le plat favori du repas**. Seule D « le tiramisu fait maison » désigne un plat. A donne **le nombre d''invités**. B donne **la durée de la soirée**. C donne **les autres convives**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Identité du voisin (« qui ? ») / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-2000-0000-000000000014', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as l''air de bien connaître les habitants de cet immeuble.\n[Femme] Oui, j''y vis depuis longtemps.\n[Homme] Et qui habite juste en face de toi ?\n[Femme] ...\n\nA. Une famille avec deux jeunes enfants.\nB. Au troisième étage gauche, comme moi.\nC. Depuis bientôt cinq ans, je crois.\nD. Pour un loyer relativement modéré.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air de bien connaître les habitants de cet immeuble.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''y vis depuis longtemps.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qui habite juste en face de toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une famille avec deux jeunes enfants.<break time="700ms"/>B.<break time="300ms"/>Au troisième étage gauche, comme moi.<break time="700ms"/>C.<break time="300ms"/>Depuis bientôt cinq ans, je crois.<break time="700ms"/>D.<break time="300ms"/>Pour un loyer relativement modéré.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qui habite juste en face de toi ? » porte sur **l''identité / la composition du foyer voisin**. Seule A « une famille avec deux jeunes enfants » désigne les occupants. B donne **l''étage** (« où ? »). C donne **depuis quand**. D donne **le loyer** (« combien ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
