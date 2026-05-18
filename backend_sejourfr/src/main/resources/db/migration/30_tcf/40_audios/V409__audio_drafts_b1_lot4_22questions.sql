-- ============================================================
-- 22 exercices B1 (lot 4) - CO TCF - format "réponse à question implicite"
-- Dialogues de 2 à 3 tours (alternance Henri / Denise),
-- 22 types de question implicite différents des lots V401/V404/V408.
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- Position de la bonne réponse équilibrée : 6×A, 6×B, 5×C, 5×D.
-- Voix : 11×Henri, 11×Denise.
-- ============================================================

-- ----- Exercice 1 : Plus grosse surprise / voyage / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000001', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu reviens enfin de ton premier voyage au Japon !\n[Femme] Oui, c''était absolument incroyable.\n[Homme] Qu''est-ce qui t''a le plus étonnée, là-bas ?\n[Femme] ...\n\nA. La propreté impeccable des rues, partout.\nB. Pendant deux semaines pleines de découvertes.\nC. Avec une amie passionnée de culture nippone.\nD. À Tokyo et à Kyoto principalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens enfin de ton premier voyage au Japon !</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''était absolument incroyable.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus étonnée, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La propreté impeccable des rues, partout.<break time="700ms"/>B.<break time="300ms"/>Pendant deux semaines pleines de découvertes.<break time="700ms"/>C.<break time="300ms"/>Avec une amie passionnée de culture nippone.<break time="700ms"/>D.<break time="300ms"/>À Tokyo et à Kyoto principalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''a le plus étonnée ? » porte sur **l''élément précis qui a provoqué l''étonnement** durant le voyage. Seule A « la propreté impeccable des rues » désigne un tel élément. B donne **la durée du séjour** (« combien de temps ? »). C donne **l''accompagnante** (« avec qui es-tu partie ? »). D donne **les lieux visités** (« où es-tu allée ? »). Piège B1 : tous les distracteurs restent cohérents avec un voyage au Japon mais aucun n''identifie ce qui a surpris.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Activité par temps de pluie / quotidien / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000002', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On annonce de la pluie tout le week-end. Tu fais quoi quand il pleut comme ça ?\n[Femme] ...\n\nA. Plutôt mal, je dois l''avouer.\nB. Je regarde des films sous un plaid.\nC. Pendant des heures, parfois.\nD. Avec mes enfants si possible.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On annonce de la pluie tout le week-end. Tu fais quoi quand il pleut comme ça ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt mal, je dois l''avouer.<break time="700ms"/>B.<break time="300ms"/>Je regarde des films sous un plaid.<break time="700ms"/>C.<break time="300ms"/>Pendant des heures, parfois.<break time="700ms"/>D.<break time="300ms"/>Avec mes enfants si possible.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu fais quoi quand il pleut ? » porte sur **l''activité menée par temps de pluie**. Seule B « je regarde des films sous un plaid » nomme une activité concrète. A donne **une appréciation / un ressenti** (« comment supportes-tu la pluie ? »). C donne **une durée** (« combien de temps ? »). D donne **un accompagnement** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Réaction à une nouvelle reçue / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000003', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Ton patron t''a annoncé que tu partais à l''étranger pour six mois.\n[Homme] Oui, hier en fin de journée.\n[Femme] Et tu as réagi comment, sur le moment ?\n[Homme] ...\n\nA. Vers dix-sept heures, environ.\nB. À cause d''un nouveau gros contrat.\nC. Avec un mélange d''excitation et d''angoisse.\nD. Dans son bureau, en tête-à-tête.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton patron t''a annoncé que tu partais à l''étranger pour six mois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, hier en fin de journée.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as réagi comment, sur le moment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers dix-sept heures, environ.<break time="700ms"/>B.<break time="300ms"/>À cause d''un nouveau gros contrat.<break time="700ms"/>C.<break time="300ms"/>Avec un mélange d''excitation et d''angoisse.<break time="700ms"/>D.<break time="300ms"/>Dans son bureau, en tête-à-tête.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as réagi comment, sur le moment ? » porte sur **la réaction émotionnelle** à la nouvelle. Seule C « avec un mélange d''excitation et d''angoisse » décrit un état émotionnel. A donne **le moment précis** (« à quelle heure ? »). B donne **la cause de la mission** (« pourquoi ce départ ? »). D donne **le lieu de l''annonce** (« où te l''a-t-il dit ? »). Piège B1 : la confusion classique entre réaction et cause de la décision.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Plat régional préféré / culinaire / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000004', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''as dit que ta région avait une cuisine très riche.\n[Femme] Oui, et j''en suis très fière.\n[Homme] Et quel plat de chez toi tu préfères ?\n[Femme] ...\n\nA. Près de Lyon, dans le Beaujolais.\nB. Pour les fêtes de famille, surtout.\nC. Avec beaucoup d''herbes fraîches du jardin.\nD. La quenelle de brochet, sans hésiter.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que ta région avait une cuisine très riche.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, et j''en suis très fière.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et quel plat de chez toi tu préfères ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près de Lyon, dans le Beaujolais.<break time="700ms"/>B.<break time="300ms"/>Pour les fêtes de famille, surtout.<break time="700ms"/>C.<break time="300ms"/>Avec beaucoup d''herbes fraîches du jardin.<break time="700ms"/>D.<break time="300ms"/>La quenelle de brochet, sans hésiter.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel plat de chez toi tu préfères ? » porte sur **l''identification du plat favori**. Seule D « la quenelle de brochet » nomme un plat précis. A donne **la localisation de la région** (« où est-ce ? »). B donne **l''occasion de consommation** (« quand le mange-t-on ? »). C donne **un ingrédient / mode de préparation** (« avec quoi est-il fait ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Découverte récente / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000005', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as l''air enthousiaste ces derniers temps. Qu''as-tu découvert récemment ?\n[Homme] ...\n\nA. Un petit café littéraire dans mon quartier.\nB. Plutôt par hasard, en me promenant.\nC. Pendant ma pause déjeuner, souvent.\nD. Avec un collègue qui m''a accompagné.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air enthousiaste ces derniers temps. Qu''as-tu découvert récemment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un petit café littéraire dans mon quartier.<break time="700ms"/>B.<break time="300ms"/>Plutôt par hasard, en me promenant.<break time="700ms"/>C.<break time="300ms"/>Pendant ma pause déjeuner, souvent.<break time="700ms"/>D.<break time="300ms"/>Avec un collègue qui m''a accompagné.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''as-tu découvert récemment ? » porte sur **la nature de la découverte**, l''objet ou le lieu trouvé. Seule A « un petit café littéraire dans mon quartier » identifie ce qui a été découvert. B donne **la manière** (« comment l''as-tu trouvé ? »). C donne **le moment habituel** d''y aller (« quand ? »). D donne **l''accompagnant** (« avec qui ? »). Piège B1 : sans la voix Denise dernière, attention à la cohérence — ici, c''est bien Denise qui pose la seule question du dialogue.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Personne qui inspire / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000006', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On a beaucoup parlé de modèles ce soir, dans notre groupe.\n[Femme] Oui, le débat était passionnant.\n[Homme] Et toi, qui t''inspire vraiment, au fond ?\n[Femme] ...\n\nA. Pour son courage et sa persévérance.\nB. Ma grand-mère, sans aucune hésitation.\nC. Dès que j''ai des décisions difficiles à prendre.\nD. Pendant toute mon enfance, déjà.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a beaucoup parlé de modèles ce soir, dans notre groupe.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, le débat était passionnant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et toi, qui t''inspire vraiment, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour son courage et sa persévérance.<break time="700ms"/>B.<break time="300ms"/>Ma grand-mère, sans aucune hésitation.<break time="700ms"/>C.<break time="300ms"/>Dès que j''ai des décisions difficiles à prendre.<break time="700ms"/>D.<break time="300ms"/>Pendant toute mon enfance, déjà.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qui t''inspire vraiment ? » porte sur **l''identité de la personne** inspirante. Seule B « ma grand-mère » désigne une personne. A donne **la raison de l''inspiration** (« pourquoi t''inspire-t-elle ? »). C donne **le moment où l''on pense à elle** (« quand penses-tu à elle ? »). D donne **la période où l''inspiration a commencé** (« depuis quand ? »). Piège B1 : A est très tentant car il prolonge l''idée mais ne nomme personne.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Activité après le travail / quotidien / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000007', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tes journées au bureau ont l''air bien remplies.\n[Homme] Oui, je ne vois pas le temps passer.\n[Femme] Et tu fais quoi en sortant du travail, en général ?\n[Homme] ...\n\nA. À cause de la fatigue accumulée.\nB. Vers dix-neuf heures, le plus souvent.\nC. Je passe à la salle de sport.\nD. Avec deux collègues du même service.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tes journées au bureau ont l''air bien remplies.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je ne vois pas le temps passer.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu fais quoi en sortant du travail, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause de la fatigue accumulée.<break time="700ms"/>B.<break time="300ms"/>Vers dix-neuf heures, le plus souvent.<break time="700ms"/>C.<break time="300ms"/>Je passe à la salle de sport.<break time="700ms"/>D.<break time="300ms"/>Avec deux collègues du même service.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu fais quoi en sortant du travail ? » porte sur **l''activité post-bureau habituelle**. Seule C « je passe à la salle de sport » nomme une activité. A donne **une cause / motif** (« pourquoi rentrer ? »). B donne **l''heure de sortie** (« à quelle heure ? »). D donne **les accompagnants** (« avec qui ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Manière de gérer le stress / personnel / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000008', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Avec tout ce que tu portes en ce moment au boulot, tu gères ton stress comment ?\n[Femme] ...\n\nA. Pendant les périodes vraiment intenses.\nB. À cause des délais toujours plus serrés.\nC. Avec mon mari qui me soutient beaucoup.\nD. En faisant de la méditation tous les matins.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec tout ce que tu portes en ce moment au boulot, tu gères ton stress comment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les périodes vraiment intenses.<break time="700ms"/>B.<break time="300ms"/>À cause des délais toujours plus serrés.<break time="700ms"/>C.<break time="300ms"/>Avec mon mari qui me soutient beaucoup.<break time="700ms"/>D.<break time="300ms"/>En faisant de la méditation tous les matins.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu gères ton stress comment ? » porte sur **la méthode employée** pour gérer le stress. Seule D « en faisant de la méditation tous les matins » (gérondif de moyen) décrit une méthode. A donne **le moment où le stress apparaît** (« quand est-il fort ? »). B donne **la cause du stress** (« pourquoi es-tu stressée ? »). C donne **le soutien reçu** (« avec qui en parles-tu ? »). Piège B1 : C est crédible (« qui aide ? ») mais ne décrit pas une technique de gestion.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Source d'information préférée / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000009', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu es toujours au courant de l''actualité, c''est impressionnant.\n[Femme] Je suis assez curieuse, c''est vrai.\n[Homme] Et tu t''informes où, en général ?\n[Femme] ...\n\nA. Sur le site du journal Le Monde, surtout.\nB. Pendant ma pause de midi, généralement.\nC. Pour rester active dans les débats.\nD. Avec ma sœur qui adore en discuter.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu es toujours au courant de l''actualité, c''est impressionnant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je suis assez curieuse, c''est vrai.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu t''informes où, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur le site du journal Le Monde, surtout.<break time="700ms"/>B.<break time="300ms"/>Pendant ma pause de midi, généralement.<break time="700ms"/>C.<break time="300ms"/>Pour rester active dans les débats.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur qui adore en discuter.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu t''informes où ? » porte sur **la source d''information consultée**. Seule A « sur le site du journal Le Monde » désigne une source. B donne **le moment** (« quand t''informes-tu ? »). C donne **le but** (« pourquoi t''informer ? »). D donne **l''accompagnant pour discuter** (« avec qui en parles-tu ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Type de musée préféré / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000a', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que tu visitais beaucoup de musées en voyage.\n[Homme] Au moins deux par séjour, oui.\n[Femme] Et tu préfères quel type de musée ?\n[Homme] ...\n\nA. Pour deux heures de visite à chaque fois.\nB. Les musées d''histoire naturelle, de loin.\nC. Avec un audioguide, c''est plus riche.\nD. Surtout les samedis matin, peu fréquentés.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu visitais beaucoup de musées en voyage.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins deux par séjour, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu préfères quel type de musée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour deux heures de visite à chaque fois.<break time="700ms"/>B.<break time="300ms"/>Les musées d''histoire naturelle, de loin.<break time="700ms"/>C.<break time="300ms"/>Avec un audioguide, c''est plus riche.<break time="700ms"/>D.<break time="300ms"/>Surtout les samedis matin, peu fréquentés.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu préfères quel type de musée ? » porte sur **la catégorie de musée privilégiée**. Seule B « les musées d''histoire naturelle » nomme un type. A donne **la durée de visite** (« combien de temps ? »). C donne **la manière de visiter** (« comment ? »). D donne **le moment habituel** (« quand ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Sortie favorite / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000b', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu sors souvent le soir avec tes amis ?\n[Homme] Deux ou trois fois par semaine.\n[Femme] Et quelle est ta sortie préférée ?\n[Homme] ...\n\nA. Plutôt vers vingt-deux heures, en général.\nB. Avec mes amis d''enfance, fidèlement.\nC. Le concert dans une petite salle intimiste.\nD. Pour décompresser après une longue semaine.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sors souvent le soir avec tes amis ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Deux ou trois fois par semaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle est ta sortie préférée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt vers vingt-deux heures, en général.<break time="700ms"/>B.<break time="300ms"/>Avec mes amis d''enfance, fidèlement.<break time="700ms"/>C.<break time="300ms"/>Le concert dans une petite salle intimiste.<break time="700ms"/>D.<break time="300ms"/>Pour décompresser après une longue semaine.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle est ta sortie préférée ? » porte sur **le type de sortie favorite**. Seule C « le concert dans une petite salle intimiste » nomme un type d''activité de sortie. A donne **l''heure habituelle** (« à quelle heure sors-tu ? »). B donne **les accompagnants** (« avec qui ? »). D donne **le but** (« pourquoi sors-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Cadeau idéal à recevoir / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000c', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Ton anniversaire approche à grands pas, dis-moi.\n[Femme] Oui, à la fin du mois.\n[Homme] Quel cadeau te ferait vraiment plaisir, cette année ?\n[Femme] ...\n\nA. Pendant le grand week-end de mai.\nB. Avec toute la famille réunie chez moi.\nC. À la campagne, dans un endroit calme.\nD. Un beau carnet de voyage en cuir.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ton anniversaire approche à grands pas, dis-moi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, à la fin du mois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel cadeau te ferait vraiment plaisir, cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant le grand week-end de mai.<break time="700ms"/>B.<break time="300ms"/>Avec toute la famille réunie chez moi.<break time="700ms"/>C.<break time="300ms"/>À la campagne, dans un endroit calme.<break time="700ms"/>D.<break time="300ms"/>Un beau carnet de voyage en cuir.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel cadeau te ferait vraiment plaisir ? » porte sur **la nature du cadeau souhaité**. Seule D « un beau carnet de voyage en cuir » nomme un objet. A donne **le moment de la fête** (« quand fêteras-tu ? »). B donne **les invités** (« avec qui ? »). C donne **le lieu** (« où fêteras-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Voyage rêvé / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000d', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu lisais encore un guide de voyage, hier soir.\n[Homme] J''adore préparer mes prochaines escapades.\n[Femme] Quel voyage tu rêverais vraiment de faire ?\n[Homme] ...\n\nA. Une grande traversée de l''Amérique du Sud.\nB. Pendant au moins trois bons mois.\nC. Avec un sac à dos très léger.\nD. Pour me sentir libre et déconnecté.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lisais encore un guide de voyage, hier soir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''adore préparer mes prochaines escapades.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel voyage tu rêverais vraiment de faire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une grande traversée de l''Amérique du Sud.<break time="700ms"/>B.<break time="300ms"/>Pendant au moins trois bons mois.<break time="700ms"/>C.<break time="300ms"/>Avec un sac à dos très léger.<break time="700ms"/>D.<break time="300ms"/>Pour me sentir libre et déconnecté.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel voyage tu rêverais de faire ? » porte sur **la nature / la destination du voyage rêvé**. Seule A « une grande traversée de l''Amérique du Sud » décrit un voyage précis. B donne **la durée envisagée** (« combien de temps ? »). C donne **les bagages** (« avec quoi voyagerais-tu ? »). D donne **le but / la motivation** (« pourquoi rêver de ce voyage ? »). Piège B1 : la voix Denise pose la question — c''est son tour final qui appelle la destination.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Stratégie quotidienne pour gagner du temps / quotidien / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000e', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu sembles toujours bien organisée le matin. Tu as quelle astuce pour gagner du temps ?\n[Femme] ...\n\nA. Pendant les jours d''école, surtout.\nB. Je prépare tout la veille au soir.\nC. Pour être à l''heure au bureau.\nD. Avec mes deux enfants, c''est nécessaire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu sembles toujours bien organisée le matin. Tu as quelle astuce pour gagner du temps ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les jours d''école, surtout.<break time="700ms"/>B.<break time="300ms"/>Je prépare tout la veille au soir.<break time="700ms"/>C.<break time="300ms"/>Pour être à l''heure au bureau.<break time="700ms"/>D.<break time="300ms"/>Avec mes deux enfants, c''est nécessaire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as quelle astuce pour gagner du temps ? » porte sur **la stratégie concrète employée**. Seule B « je prépare tout la veille au soir » décrit une stratégie. A donne **le moment d''application** (« quand cela sert-il ? »). C donne **le but** (« pourquoi gagner du temps ? »). D donne **le contexte familial** (« avec qui dois-tu t''organiser ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Conseil reçu qui a marqué / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-00000000000f', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as eu beaucoup de mentors dans ton parcours.\n[Homme] Oui, et chacun m''a apporté quelque chose.\n[Femme] Mais quel conseil tu retiens vraiment, parmi tous ?\n[Homme] ...\n\nA. Pendant mes années de stage, principalement.\nB. Par mon premier maître de stage, à l''hôpital.\nC. De toujours rester humble face à l''inconnu.\nD. Avec une réelle bienveillance, à chaque fois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as eu beaucoup de mentors dans ton parcours.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, et chacun m''a apporté quelque chose.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais quel conseil tu retiens vraiment, parmi tous ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant mes années de stage, principalement.<break time="700ms"/>B.<break time="300ms"/>Par mon premier maître de stage, à l''hôpital.<break time="700ms"/>C.<break time="300ms"/>De toujours rester humble face à l''inconnu.<break time="700ms"/>D.<break time="300ms"/>Avec une réelle bienveillance, à chaque fois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel conseil tu retiens vraiment ? » porte sur **le contenu du conseil retenu**. Seule C « de toujours rester humble face à l''inconnu » formule un conseil. A donne **la période** où le conseil a été reçu (« quand ? »). B donne **l''auteur du conseil** (« par qui ? »). D donne **la manière dont les conseils étaient donnés** (« comment ? »). Piège B1 : confusion classique entre l''auteur d''un conseil (B) et le conseil lui-même (C).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Astuce de cuisine / culinaire / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000010', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tes gâteaux sont toujours moelleux à la perfection. Tu as une astuce pour réussir tes pâtes ?\n[Femme] ...\n\nA. Pendant les anniversaires, surtout.\nB. Avec une vieille recette de ma mère.\nC. Pour faire plaisir à tous mes invités.\nD. J''ajoute toujours un yaourt nature.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tes gâteaux sont toujours moelleux à la perfection. Tu as une astuce pour réussir tes pâtes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les anniversaires, surtout.<break time="700ms"/>B.<break time="300ms"/>Avec une vieille recette de ma mère.<break time="700ms"/>C.<break time="300ms"/>Pour faire plaisir à tous mes invités.<break time="700ms"/>D.<break time="300ms"/>J''ajoute toujours un yaourt nature.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as une astuce pour réussir tes pâtes ? » porte sur **le truc concret utilisé**. Seule D « j''ajoute toujours un yaourt nature » décrit une astuce. A donne **l''occasion de cuisiner** (« quand cuisines-tu ? »). B donne **l''origine de la recette** (« d''où vient ta recette ? »). C donne **le but** (« pourquoi cuisiner ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Sport en équipe ou individuel / sport / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000011', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu fais beaucoup de sport, je crois.\n[Homme] Plusieurs fois par semaine, oui.\n[Femme] Tu préfères les sports en équipe ou plutôt individuels ?\n[Homme] ...\n\nA. Plutôt individuels, pour mon propre rythme.\nB. Dans le club au bout de la rue.\nC. Pour évacuer mon stress du bureau.\nD. Avec quelques amis fidèles, parfois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu fais beaucoup de sport, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Plusieurs fois par semaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu préfères les sports en équipe ou plutôt individuels ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt individuels, pour mon propre rythme.<break time="700ms"/>B.<break time="300ms"/>Dans le club au bout de la rue.<break time="700ms"/>C.<break time="300ms"/>Pour évacuer mon stress du bureau.<break time="700ms"/>D.<break time="300ms"/>Avec quelques amis fidèles, parfois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'La question oppose deux catégories et appelle **un choix entre les deux**, avec sa justification. Seule A « plutôt individuels, pour mon propre rythme » désigne une des deux options et la motive. B donne **le lieu de pratique** (« où ? »). C donne **le but général du sport** (« pourquoi en faire ? »). D donne **les partenaires occasionnels** (« avec qui ? »). Piège B1 : D évoque des « amis », ce qui pourrait tromper sur un sport collectif, mais la question demande la préférence du locuteur.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Type de livre préféré / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000012', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que tu lisais énormément.\n[Homme] Au moins un livre par semaine, oui.\n[Femme] Et quel type de livre tu lis, en général ?\n[Homme] ...\n\nA. Pendant mes trajets en métro, surtout.\nB. Des romans policiers contemporains.\nC. À la médiathèque de mon quartier.\nD. Pour m''évader un peu du quotidien.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu lisais énormément.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins un livre par semaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel type de livre tu lis, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant mes trajets en métro, surtout.<break time="700ms"/>B.<break time="300ms"/>Des romans policiers contemporains.<break time="700ms"/>C.<break time="300ms"/>À la médiathèque de mon quartier.<break time="700ms"/>D.<break time="300ms"/>Pour m''évader un peu du quotidien.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel type de livre tu lis ? » porte sur **le genre littéraire**. Seule B « des romans policiers contemporains » nomme un genre. A donne **le moment de lecture** (« quand lis-tu ? »). C donne **le lieu où trouver les livres** (« où les empruntes-tu ? »). D donne **le but de la lecture** (« pourquoi lis-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Auteur favori / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000013', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu lis beaucoup de littérature étrangère, on dirait.\n[Homme] J''aime beaucoup voyager par les livres.\n[Femme] Et quel auteur tu préfères, dans tout ça ?\n[Homme] ...\n\nA. Pour la beauté de son écriture, sincèrement.\nB. Toujours en version originale anglaise.\nC. Haruki Murakami, depuis des années.\nD. Avec un grand café, le dimanche matin.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lis beaucoup de littérature étrangère, on dirait.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''aime beaucoup voyager par les livres.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel auteur tu préfères, dans tout ça ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour la beauté de son écriture, sincèrement.<break time="700ms"/>B.<break time="300ms"/>Toujours en version originale anglaise.<break time="700ms"/>C.<break time="300ms"/>Haruki Murakami, depuis des années.<break time="700ms"/>D.<break time="300ms"/>Avec un grand café, le dimanche matin.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel auteur tu préfères ? » porte sur **l''identité de l''écrivain favori**. Seule C « Haruki Murakami » nomme un auteur. A donne **la raison de la préférence** (« pourquoi l''aimes-tu ? »). B donne **la langue de lecture** (« comment le lis-tu ? »). D donne **les conditions de lecture** (« quand et avec quoi ? »). Piège B1 : A est très tentant car il prolonge l''idée mais ne nomme aucun auteur.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Style de décoration / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000014', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as enfin terminé d''aménager ton nouvel appartement ?\n[Femme] Oui, après des mois de travaux.\n[Homme] Tu as choisi quel style de déco, finalement ?\n[Femme] ...\n\nA. Pendant tout le printemps dernier.\nB. Avec l''aide d''une décoratrice professionnelle.\nC. À Paris, dans un quartier très calme.\nD. Un style scandinave, épuré et lumineux.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as enfin terminé d''aménager ton nouvel appartement ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, après des mois de travaux.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as choisi quel style de déco, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant tout le printemps dernier.<break time="700ms"/>B.<break time="300ms"/>Avec l''aide d''une décoratrice professionnelle.<break time="700ms"/>C.<break time="300ms"/>À Paris, dans un quartier très calme.<break time="700ms"/>D.<break time="300ms"/>Un style scandinave, épuré et lumineux.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Tu as choisi quel style de déco ? » porte sur **le style décoratif retenu**. Seule D « un style scandinave, épuré et lumineux » désigne un style. A donne **la période des travaux** (« quand ? »). B donne **l''aide reçue** (« avec qui ? »). C donne **la localisation du logement** (« où ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 21 : Pays à visiter en priorité / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000015', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as une longue liste de pays sur ta carte murale.\n[Homme] Au moins une trentaine, oui.\n[Femme] Mais quel pays tu voudrais visiter en priorité ?\n[Homme] ...\n\nA. L''Islande, vraiment depuis longtemps.\nB. Pour découvrir des paysages extrêmes.\nC. Pendant deux ou trois semaines pleines.\nD. Avec un guide local, idéalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as une longue liste de pays sur ta carte murale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins une trentaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais quel pays tu voudrais visiter en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''Islande, vraiment depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour découvrir des paysages extrêmes.<break time="700ms"/>C.<break time="300ms"/>Pendant deux ou trois semaines pleines.<break time="700ms"/>D.<break time="300ms"/>Avec un guide local, idéalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel pays tu voudrais visiter en priorité ? » porte sur **l''identification du pays prioritaire**. Seule A « l''Islande » nomme un pays. B donne **la motivation** (« pourquoi y aller ? »). C donne **la durée envisagée** (« combien de temps ? »). D donne **les conditions de visite** (« avec qui ? »). Piège B1 : B est souvent confondu avec A car il explique le choix mais ne le nomme pas.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 22 : Outil indispensable au quotidien / quotidien / 2 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b1-4000-0000-000000000016', 'B1', 'co_dialogue_b1_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] On parlait des objets dont on ne pourrait plus se passer. Et toi, quel objet t''est vraiment indispensable au quotidien ?\n[Femme] ...\n\nA. Pendant toute la journée, sans exception.\nB. Mon petit carnet à spirale, toujours sur moi.\nC. Avec mes proches, surtout en déplacement.\nD. Pour ne rien oublier d''important.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On parlait des objets dont on ne pourrait plus se passer. Et toi, quel objet t''est vraiment indispensable au quotidien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant toute la journée, sans exception.<break time="700ms"/>B.<break time="300ms"/>Mon petit carnet à spirale, toujours sur moi.<break time="700ms"/>C.<break time="300ms"/>Avec mes proches, surtout en déplacement.<break time="700ms"/>D.<break time="300ms"/>Pour ne rien oublier d''important.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel objet t''est indispensable au quotidien ? » porte sur **l''identification d''un objet précis**. Seule B « mon petit carnet à spirale » nomme un objet. A donne **la durée d''usage** (« quand l''utilises-tu ? »). C donne **les personnes associées** (« avec qui ? »). D donne **la fonction / le but** de l''objet (« pourquoi en as-tu besoin ? »). Piège B1 : D décrit l''utilité d''un tel objet sans le nommer, ce qui le rend crédible.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
