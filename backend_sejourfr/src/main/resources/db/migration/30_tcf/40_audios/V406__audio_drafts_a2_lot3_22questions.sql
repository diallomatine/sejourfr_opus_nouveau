-- ============================================================
-- 22 exercices A2 (lot 3) - CO TCF - format "réponse à question implicite"
-- Une seule réplique (question directe), alternance Henri / Denise (11/11).
-- 22 nouveaux types de question (non couverts en V400 ni V405) :
-- boisson, style de vêtements, nationalité, sport, animal de compagnie,
-- saison préférée, mois de naissance, numéro de téléphone, marque,
-- genre de film, activité du soir, profession d'un parent, nombre
-- d'enfants, nombre de pièces, étage, prix d'un billet, distance courte,
-- pays d'origine, type de logement, heure de fin, position dans la file,
-- niveau scolaire.
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 6×A, 6×B, 5×C, 5×D.
-- ============================================================

-- ----- Exercice 1 : Type de boisson (« quelle boisson ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000001', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quelle boisson tu prends, au petit-déjeuner ?\n[Femme] ...\n\nA. Un grand café au lait, sans sucre.\nB. Vers sept heures du matin.\nC. Dans la cuisine, debout.\nD. Pour bien commencer la journée.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle boisson tu prends, au petit-déjeuner ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un grand café au lait, sans sucre.<break time="700ms"/>B.<break time="300ms"/>Vers sept heures du matin.<break time="700ms"/>C.<break time="300ms"/>Dans la cuisine, debout.<break time="700ms"/>D.<break time="300ms"/>Pour bien commencer la journée.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle boisson tu prends ? » porte sur **le type de boisson**. Seule A « un grand café au lait » nomme une boisson. B donne **l''heure** (« à quelle heure ? »). C donne **le lieu**. D donne **la raison / le but**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Style de vêtements (« quel style ? ») / commercial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000002', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel style de vêtements tu aimes porter ?\n[Homme] ...\n\nA. Au centre commercial, en général.\nB. Plutôt décontracté, jean et tee-shirt.\nC. Pour aller travailler au bureau.\nD. Avec ma sœur, qui me conseille.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel style de vêtements tu aimes porter ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au centre commercial, en général.<break time="700ms"/>B.<break time="300ms"/>Plutôt décontracté, jean et tee-shirt.<break time="700ms"/>C.<break time="300ms"/>Pour aller travailler au bureau.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur, qui me conseille.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel style de vêtements ? » porte sur **le type / le style vestimentaire**. Seule B « décontracté, jean et tee-shirt » décrit un style. A donne **le lieu d''achat**. C donne **le contexte d''usage**. D donne **l''accompagnant pour faire les courses**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Nationalité (« de quelle nationalité ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000003', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Ton nouveau voisin, il est de quelle nationalité ?\n[Femme] ...\n\nA. À l''appartement juste au-dessus.\nB. Pour son travail à Paris.\nC. Italien, de la région de Milan.\nD. Depuis le mois dernier, je crois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ton nouveau voisin, il est de quelle nationalité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''appartement juste au-dessus.<break time="700ms"/>B.<break time="300ms"/>Pour son travail à Paris.<break time="700ms"/>C.<break time="300ms"/>Italien, de la région de Milan.<break time="700ms"/>D.<break time="300ms"/>Depuis le mois dernier, je crois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« De quelle nationalité ? » porte sur **la nationalité**. Seule C « italien, de la région de Milan » donne une nationalité. A donne **le lieu** d''habitation. B donne **la raison** de sa venue. D donne **depuis quand** il est là.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Sport pratiqué (« quel sport ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000004', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel sport tu fais en ce moment ?\n[Homme] ...\n\nA. Avec deux amis du quartier.\nB. Pour rester en bonne forme.\nC. Au gymnase de l''école, le samedi.\nD. Du basket-ball, deux fois par semaine.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel sport tu fais en ce moment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux amis du quartier.<break time="700ms"/>B.<break time="300ms"/>Pour rester en bonne forme.<break time="700ms"/>C.<break time="300ms"/>Au gymnase de l''école, le samedi.<break time="700ms"/>D.<break time="300ms"/>Du basket-ball, deux fois par semaine.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel sport tu fais ? » porte sur **la discipline sportive**. Seule D « du basket-ball » nomme un sport. A donne **les partenaires**. B donne **le but / la raison**. C donne **le lieu et le jour**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Animal de compagnie (« quel animal ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000005', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as quel animal à la maison ?\n[Femme] ...\n\nA. Un petit lapin nain, très mignon.\nB. Depuis presque deux ans déjà.\nC. Avec ma fille, qui s''en occupe.\nD. Dans une grande cage du salon.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as quel animal à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un petit lapin nain, très mignon.<break time="700ms"/>B.<break time="300ms"/>Depuis presque deux ans déjà.<break time="700ms"/>C.<break time="300ms"/>Avec ma fille, qui s''en occupe.<break time="700ms"/>D.<break time="300ms"/>Dans une grande cage du salon.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel animal ? » porte sur **l''espèce de l''animal de compagnie**. Seule A « un petit lapin nain » nomme un animal. B donne **depuis quand**. C donne **avec qui** on s''en occupe. D donne **le lieu** où il vit.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Saison préférée (« quelle saison ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000006', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quelle est ta saison préférée, finalement ?\n[Homme] ...\n\nA. À la montagne, presque toujours.\nB. Le printemps, pour les fleurs et la douceur.\nC. Avec toute ma petite famille.\nD. Pour faire de longues balades à pied.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle est ta saison préférée, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la montagne, presque toujours.<break time="700ms"/>B.<break time="300ms"/>Le printemps, pour les fleurs et la douceur.<break time="700ms"/>C.<break time="300ms"/>Avec toute ma petite famille.<break time="700ms"/>D.<break time="300ms"/>Pour faire de longues balades à pied.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle est ta saison préférée ? » porte sur **le choix d''une saison**. Seule B « le printemps » nomme une saison. A donne **le lieu** des vacances. C donne **l''accompagnant**. D donne **une activité préférée**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Mois de naissance (« en quel mois ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000007', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] En quel mois tu es née, déjà ?\n[Femme] ...\n\nA. Avec mes deux frères jumeaux.\nB. À l''hôpital de Bordeaux.\nC. En octobre, juste avant Halloween.\nD. Depuis bientôt trente-deux ans.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">En quel mois tu es née, déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mes deux frères jumeaux.<break time="700ms"/>B.<break time="300ms"/>À l''hôpital de Bordeaux.<break time="700ms"/>C.<break time="300ms"/>En octobre, juste avant Halloween.<break time="700ms"/>D.<break time="300ms"/>Depuis bientôt trente-deux ans.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« En quel mois tu es née ? » porte sur **le mois de naissance**. Seule C « en octobre » nomme un mois. A donne **la fratrie présente**. B donne **le lieu** de naissance. D donne **l''âge** approximatif.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Numéro de téléphone (« quel numéro ? ») / administratif -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000008', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel est ton numéro de téléphone, s''il te plaît ?\n[Homme] ...\n\nA. Chez l''opérateur Orange, depuis longtemps.\nB. Pour te joindre plus facilement.\nC. Avec un forfait sans engagement.\nD. Le zéro six, douze, trente-quatre, cinquante-six, soixante-dix-huit.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton numéro de téléphone, s''il te plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Chez l''opérateur Orange, depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour te joindre plus facilement.<break time="700ms"/>C.<break time="300ms"/>Avec un forfait sans engagement.<break time="700ms"/>D.<break time="300ms"/>Le zéro six, douze, trente-quatre, cinquante-six, soixante-dix-huit.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton numéro de téléphone ? » porte sur **la suite de chiffres**. Seule D énonce un numéro complet. A donne **l''opérateur**. B donne **le but** de la demande. C donne **le type de forfait**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Marque (« quelle marque ? ») / commercial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000009', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Quelle marque de chaussures tu achètes d''habitude ?\n[Femme] ...\n\nA. Toujours la marque Bensimon, je les adore.\nB. Au magasin de la rue Saint-Antoine.\nC. Pour le sport et la marche en ville.\nD. Environ tous les six mois, en général.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle marque de chaussures tu achètes d''habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Toujours la marque Bensimon, je les adore.<break time="700ms"/>B.<break time="300ms"/>Au magasin de la rue Saint-Antoine.<break time="700ms"/>C.<break time="300ms"/>Pour le sport et la marche en ville.<break time="700ms"/>D.<break time="300ms"/>Environ tous les six mois, en général.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle marque tu achètes ? » porte sur **le nom de marque**. Seule A « Bensimon » désigne une marque. B donne **le lieu d''achat**. C donne **l''usage** des chaussures. D donne **la fréquence** d''achat.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Genre de film (« quel genre de film ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Quel genre de films tu aimes regarder ?\n[Homme] ...\n\nA. Au cinéma du centre-ville, souvent.\nB. Surtout les comédies romantiques.\nC. Avec ma copine, le vendredi soir.\nD. Pour me détendre après le travail.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel genre de films tu aimes regarder ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cinéma du centre-ville, souvent.<break time="700ms"/>B.<break time="300ms"/>Surtout les comédies romantiques.<break time="700ms"/>C.<break time="300ms"/>Avec ma copine, le vendredi soir.<break time="700ms"/>D.<break time="300ms"/>Pour me détendre après le travail.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel genre de films ? » porte sur **la catégorie / le type de film**. Seule B « les comédies romantiques » désigne un genre. A donne **le lieu** où on les voit. C donne **avec qui et quand**. D donne **le but / la raison**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Activité du soir (« qu'est-ce que tu fais ce soir ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Qu''est-ce que tu fais, ce soir ?\n[Femme] ...\n\nA. Avec deux copines du lycée.\nB. Pour mon anniversaire de demain.\nC. Je vais au restaurant japonais.\nD. Au quartier Bastille, sûrement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu fais, ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux copines du lycée.<break time="700ms"/>B.<break time="300ms"/>Pour mon anniversaire de demain.<break time="700ms"/>C.<break time="300ms"/>Je vais au restaurant japonais.<break time="700ms"/>D.<break time="300ms"/>Au quartier Bastille, sûrement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que tu fais ce soir ? » porte sur **l''activité prévue**. Seule C « je vais au restaurant japonais » décrit une activité. A donne **les accompagnantes**. B donne **la raison / l''occasion**. D donne **le lieu / le quartier**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Profession d'un parent (« il fait quoi, ton père ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Il fait quoi dans la vie, ton père ?\n[Homme] ...\n\nA. Dans une grande entreprise du nord.\nB. Depuis bientôt vingt-cinq ans.\nC. Avec une équipe d''une dizaine de personnes.\nD. Il est ingénieur en informatique.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Il fait quoi dans la vie, ton père ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans une grande entreprise du nord.<break time="700ms"/>B.<break time="300ms"/>Depuis bientôt vingt-cinq ans.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe d''une dizaine de personnes.<break time="700ms"/>D.<break time="300ms"/>Il est ingénieur en informatique.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Il fait quoi dans la vie ? » porte sur **le métier / la profession**. Seule D « il est ingénieur en informatique » nomme un métier. A donne **le lieu de travail**. B donne **l''ancienneté**. C donne **les collègues / l''équipe**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Nombre d'enfants (« combien d'enfants ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez combien d''enfants, finalement ?\n[Femme] ...\n\nA. Trois, deux filles et un garçon.\nB. À l''école primaire du quartier.\nC. Avec une grande différence d''âge.\nD. Pour agrandir la famille bientôt.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez combien d''enfants, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois, deux filles et un garçon.<break time="700ms"/>B.<break time="300ms"/>À l''école primaire du quartier.<break time="700ms"/>C.<break time="300ms"/>Avec une grande différence d''âge.<break time="700ms"/>D.<break time="300ms"/>Pour agrandir la famille bientôt.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Combien d''enfants ? » porte sur **le nombre**. Seule A « trois » donne une quantité. B donne **le lieu** où ils sont scolarisés. C donne **un trait** descriptif (l''écart d''âge). D donne **un projet futur**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Nombre de pièces (« combien de pièces ? ») / administratif -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Ton appartement fait combien de pièces ?\n[Homme] ...\n\nA. Au quatrième étage avec ascenseur.\nB. Quatre pièces, plus la cuisine.\nC. Pour environ neuf cents euros par mois.\nD. Avec mon frère qui partage le loyer.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton appartement fait combien de pièces ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au quatrième étage avec ascenseur.<break time="700ms"/>B.<break time="300ms"/>Quatre pièces, plus la cuisine.<break time="700ms"/>C.<break time="300ms"/>Pour environ neuf cents euros par mois.<break time="700ms"/>D.<break time="300ms"/>Avec mon frère qui partage le loyer.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Combien de pièces ? » porte sur **le nombre de pièces**. Seule B « quatre pièces » donne une quantité de pièces. A donne **l''étage**. C donne **le prix du loyer**. D donne **le colocataire**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Étage (« à quel étage ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] À quel étage tu habites, dans l''immeuble ?\n[Femme] ...\n\nA. Avec une belle vue sur la cour.\nB. Pour profiter du calme du dernier étage.\nC. Au cinquième, juste sous les toits.\nD. Depuis le mois de janvier dernier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quel étage tu habites, dans l''immeuble ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une belle vue sur la cour.<break time="700ms"/>B.<break time="300ms"/>Pour profiter du calme du dernier étage.<break time="700ms"/>C.<break time="300ms"/>Au cinquième, juste sous les toits.<break time="700ms"/>D.<break time="300ms"/>Depuis le mois de janvier dernier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quel étage ? » porte sur **le numéro d''étage**. Seule C « au cinquième » donne un étage précis. A donne **un élément descriptif** (la vue). B donne **la raison du choix**. D donne **depuis quand**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Prix d'un billet (« combien coûte ? ») / commercial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000010', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le billet de train pour Lyon, ça coûte combien ?\n[Homme] ...\n\nA. Au guichet de la gare de Lyon.\nB. Pour partir vendredi prochain.\nC. Avec une réduction étudiante incluse.\nD. Soixante-cinq euros, en seconde classe.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le billet de train pour Lyon, ça coûte combien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet de la gare de Lyon.<break time="700ms"/>B.<break time="300ms"/>Pour partir vendredi prochain.<break time="700ms"/>C.<break time="300ms"/>Avec une réduction étudiante incluse.<break time="700ms"/>D.<break time="300ms"/>Soixante-cinq euros, en seconde classe.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Ça coûte combien ? » porte sur **le prix**. Seule D « soixante-cinq euros » donne un montant. A donne **le lieu d''achat**. B donne **la date du voyage**. C donne **un avantage tarifaire** (réduction), mais pas le prix lui-même.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Distance courte (« c'est loin ? ») / quotidien -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000011', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La boulangerie, c''est loin d''ici ?\n[Femme] ...\n\nA. À deux cents mètres, pas plus.\nB. Avec un grand choix de pains.\nC. Pour acheter une baguette tradition.\nD. Du lundi au samedi, toute la journée.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La boulangerie, c''est loin d''ici ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À deux cents mètres, pas plus.<break time="700ms"/>B.<break time="300ms"/>Avec un grand choix de pains.<break time="700ms"/>C.<break time="300ms"/>Pour acheter une baguette tradition.<break time="700ms"/>D.<break time="300ms"/>Du lundi au samedi, toute la journée.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« C''est loin ? » porte sur **la distance**. Seule A « à deux cents mètres » donne une distance. B donne **un atout** du magasin. C donne **le but** de la visite. D donne **les horaires d''ouverture**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Pays d'origine (« de quel pays ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000012', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu viens de quel pays, à l''origine ?\n[Homme] ...\n\nA. Depuis bientôt douze ans à Paris.\nB. Du Sénégal, plus précisément de Dakar.\nC. Pour mes études supérieures.\nD. Avec toute ma famille, à l''époque.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu viens de quel pays, à l''origine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis bientôt douze ans à Paris.<break time="700ms"/>B.<break time="300ms"/>Du Sénégal, plus précisément de Dakar.<break time="700ms"/>C.<break time="300ms"/>Pour mes études supérieures.<break time="700ms"/>D.<break time="300ms"/>Avec toute ma famille, à l''époque.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« De quel pays tu viens ? » porte sur **le pays d''origine**. Seule B « du Sénégal » nomme un pays. A donne **depuis quand** la personne vit en France. C donne **la raison de la venue**. D donne **l''accompagnement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Type de logement (« quel type de logement ? ») / administratif -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000013', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu loges dans quel type de logement, là-bas ?\n[Femme] ...\n\nA. Avec deux autres étudiantes en colocation.\nB. Pour environ six cents euros mensuels.\nC. Un petit studio meublé, très pratique.\nD. À côté de la gare centrale.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu loges dans quel type de logement, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux autres étudiantes en colocation.<break time="700ms"/>B.<break time="300ms"/>Pour environ six cents euros mensuels.<break time="700ms"/>C.<break time="300ms"/>Un petit studio meublé, très pratique.<break time="700ms"/>D.<break time="300ms"/>À côté de la gare centrale.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel type de logement ? » porte sur **la nature du logement**. Seule C « un petit studio meublé » nomme un type de logement. A donne **les colocataires**. B donne **le prix mensuel**. D donne **le lieu / la proximité**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Heure de fin (« ça finit à quelle heure ? ») / social -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000014', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le concert, ça finit à quelle heure, ce soir ?\n[Homme] ...\n\nA. À la salle Pleyel, dans le huitième.\nB. Pour deux heures de musique environ.\nC. Avec un groupe que j''adore.\nD. Vers vingt-trois heures trente, normalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le concert, ça finit à quelle heure, ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la salle Pleyel, dans le huitième.<break time="700ms"/>B.<break time="300ms"/>Pour deux heures de musique environ.<break time="700ms"/>C.<break time="300ms"/>Avec un groupe que j''adore.<break time="700ms"/>D.<break time="300ms"/>Vers vingt-trois heures trente, normalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Ça finit à quelle heure ? » porte sur **l''heure de fin** précise. Seule D « vers vingt-trois heures trente » donne une heure. A donne **le lieu** du concert. B donne **la durée** totale (« combien de temps ? »). C donne **l''accompagnant**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 21 : Position dans la file (« le combientième ? ») / administratif -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000015', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu es le combientième dans la file d''attente ?\n[Femme] ...\n\nA. Le septième, juste après cette dame.\nB. Pour un rendez-vous à la préfecture.\nC. Depuis presque une heure déjà.\nD. Avec mon dossier de naturalisation.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu es le combientième dans la file d''attente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le septième, juste après cette dame.<break time="700ms"/>B.<break time="300ms"/>Pour un rendez-vous à la préfecture.<break time="700ms"/>C.<break time="300ms"/>Depuis presque une heure déjà.<break time="700ms"/>D.<break time="300ms"/>Avec mon dossier de naturalisation.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu es le combientième ? » porte sur **la position / le rang dans la file**. Seule A « le septième » donne un rang ordinal. B donne **le motif de la venue**. C donne **la durée d''attente**. D donne **un objet apporté**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 22 : Niveau scolaire (« en quelle classe ? ») / familial -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0022-3000-0000-000000000016', 'A2', 'co_dialogue_court_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu es en quelle classe, cette année ?\n[Homme] ...\n\nA. Au lycée Voltaire, dans le onzième.\nB. En classe de seconde générale.\nC. Pour préparer le bac dans deux ans.\nD. Avec une trentaine d''élèves au total.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu es en quelle classe, cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lycée Voltaire, dans le onzième.<break time="700ms"/>B.<break time="300ms"/>En classe de seconde générale.<break time="700ms"/>C.<break time="300ms"/>Pour préparer le bac dans deux ans.<break time="700ms"/>D.<break time="300ms"/>Avec une trentaine d''élèves au total.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« En quelle classe ? » porte sur **le niveau scolaire**. Seule B « en classe de seconde générale » nomme un niveau. A donne **l''établissement / le lieu**. C donne **l''objectif futur**. D donne **le nombre de camarades**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
