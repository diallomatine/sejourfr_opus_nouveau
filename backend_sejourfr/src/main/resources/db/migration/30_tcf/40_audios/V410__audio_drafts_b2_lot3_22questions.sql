-- ============================================================
-- 22 exercices B2 (lot 3) - CO TCF - format "réponse à question implicite"
-- Dialogues de 3 à 4 tours (alternance Henri / Denise),
-- formulations indirectes / soutenues, 22 nouveaux types
-- de question implicite (différents de V402 et V403).
-- Labels A/B/C/D : le contenu des propositions est lu dans l'audio.
-- ============================================================

-- ----- Exercice 1 : Distinction entre deux concepts proches (« en quoi cela diffère ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu travailles désormais comme consultant indépendant, c''est cela ?\n[Homme] Oui, j''ai quitté mon statut de salarié l''an dernier.\n[Femme] En quoi cela diffère-t-il vraiment du portage salarial, finalement ?\n[Homme] ...\n\nA. À partir du début de l''année civile dernière, en réalité.\nB. Par une autonomie de gestion bien plus large, fondamentalement.\nC. Pour développer des missions à plus forte valeur ajoutée.\nD. Avec un soulagement assez net, je dois l''avouer.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu travailles désormais comme consultant indépendant, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai quitté mon statut de salarié l''an dernier.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quoi cela diffère-t-il vraiment du portage salarial, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir du début de l''année civile dernière, en réalité.<break time="700ms"/>B.<break time="300ms"/>Par une autonomie de gestion bien plus large, fondamentalement.<break time="700ms"/>C.<break time="300ms"/>Pour développer des missions à plus forte valeur ajoutée.<break time="700ms"/>D.<break time="300ms"/>Avec un soulagement assez net, je dois l''avouer.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours établissent le statut actuel (consultant indépendant). « En quoi cela diffère-t-il du portage salarial ? » demande **le trait distinctif entre deux statuts proches**. Seule B « par une autonomie de gestion bien plus large » désigne cette spécificité comparative. A donne le **moment du basculement** (« depuis quand ? »). C donne le **but visé** par le changement (« pour quoi faire ? »). D donne **l''état d''esprit** ressenti (« comment te sens-tu ? ») — piège B2 fin : la préposition « par » de B suggère un moyen, mais sert ici à désigner le critère différenciant.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Bilan global d'une expérience (« quel bilan tires-tu ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu rentres tout juste de ton année d''échange en Argentine ?\n[Femme] Oui, je suis arrivée à Paris la semaine dernière.\n[Homme] Avec un peu de recul, quel bilan tires-tu de cette expérience ?\n[Femme] ...\n\nA. Globalement très enrichissante, malgré quelques difficultés.\nB. À Buenos Aires, surtout dans le quartier de Palermo.\nC. Grâce à une bourse Erasmus mundus, en réalité.\nD. Pendant douze mois pleins, sans aucune interruption.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu rentres tout juste de ton année d''échange en Argentine ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je suis arrivée à Paris la semaine dernière.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec un peu de recul, quel bilan tires-tu de cette expérience ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Globalement très enrichissante, malgré quelques difficultés.<break time="700ms"/>B.<break time="300ms"/>À Buenos Aires, surtout dans le quartier de Palermo.<break time="700ms"/>C.<break time="300ms"/>Grâce à une bourse Erasmus mundus, en réalité.<break time="700ms"/>D.<break time="300ms"/>Pendant douze mois pleins, sans aucune interruption.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel bilan tires-tu ? » porte sur **une évaluation globale et nuancée d''une expérience révolue**. Seule A « globalement très enrichissante, malgré quelques difficultés » formule un jugement d''ensemble équilibré (positif/nuance). B donne le **lieu** du séjour (« où étais-tu ? »). C donne le **moyen de financement** (« comment as-tu financé ? »). D donne la **durée totale** (« combien de temps ? ») — piège B2 fin : « avec un peu de recul » dans la question peut évoquer un temps écoulé, mais le recul est posture d''évaluation, pas durée mesurée.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Apport d'une rencontre / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as parlé d''un échange marquant avec cette philosophe l''an dernier ?\n[Homme] Oui, à l''occasion d''un séminaire à Lyon.\n[Femme] Et qu''est-ce que cette rencontre t''a vraiment apporté ?\n[Homme] ...\n\nA. Au sein d''un petit séminaire d''une vingtaine de chercheurs.\nB. Au cours d''un long dîner après sa conférence, plutôt.\nC. Une autre manière d''aborder mes propres recherches.\nD. Par l''intermédiaire d''un ami commun, en fait.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as parlé d''un échange marquant avec cette philosophe l''an dernier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, à l''occasion d''un séminaire à Lyon.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et qu''est-ce que cette rencontre t''a vraiment apporté ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au sein d''un petit séminaire d''une vingtaine de chercheurs.<break time="700ms"/>B.<break time="300ms"/>Au cours d''un long dîner après sa conférence, plutôt.<break time="700ms"/>C.<break time="300ms"/>Une autre manière d''aborder mes propres recherches.<break time="700ms"/>D.<break time="300ms"/>Par l''intermédiaire d''un ami commun, en fait.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que cette rencontre t''a apporté ? » porte sur **le gain intellectuel ou personnel retiré**. Seule C « une autre manière d''aborder mes recherches » désigne un apport transformateur. A donne le **cadre** de l''événement (« où, dans quel contexte ? »). B donne le **moment précis** de l''échange (« à quel moment ? »). D donne **l''entremetteur** de la rencontre (« par qui as-tu été mis en contact ? ») — piège B2 : A et B sont déjà saturées par le 2e tour qui mentionne Lyon, ce qui doit pousser le candidat à chercher autre chose dans la réponse.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Élément déclencheur d'une prise de conscience / personnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai entendu que tu avais radicalement changé tes habitudes alimentaires ?\n[Femme] Oui, je suis devenue presque entièrement végétale.\n[Homme] C''est un sacré virage, tout de même.\n[Femme] Oui, je l''assume pleinement aujourd''hui.\n[Homme] Mais qu''est-ce qui a vraiment déclenché cette prise de conscience ?\n[Femme] ...\n\nA. Au moment de mes trente ans, plus précisément.\nB. Avec un peu d''appréhension au début, je l''avoue.\nC. Pour préserver durablement ma santé cardiovasculaire.\nD. Un documentaire saisissant sur l''élevage industriel.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai entendu que tu avais radicalement changé tes habitudes alimentaires ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je suis devenue presque entièrement végétale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est un sacré virage, tout de même.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je l''assume pleinement aujourd''hui.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui a vraiment déclenché cette prise de conscience ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au moment de mes trente ans, plus précisément.<break time="700ms"/>B.<break time="300ms"/>Avec un peu d''appréhension au début, je l''avoue.<break time="700ms"/>C.<break time="300ms"/>Pour préserver durablement ma santé cardiovasculaire.<break time="700ms"/>D.<break time="300ms"/>Un documentaire saisissant sur l''élevage industriel.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue installe un changement assumé. « Qu''est-ce qui a déclenché cette prise de conscience ? » porte sur **l''événement déclencheur, l''élément précis qui a provoqué le basculement**. Seule D « un documentaire saisissant sur l''élevage industriel » désigne ce déclencheur ponctuel. A donne le **moment** du basculement (« quand ? »). B donne **l''état d''esprit initial** (« comment l''as-tu vécu au début ? »). C donne la **finalité poursuivie** (« pour quel objectif ? ») — piège B2 majeur : la cause-déclencheur et le but cible sont souvent confondus, mais le déclencheur précède la décision tandis que le but la justifie après.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Sentiment majoritaire ressenti / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu viens de quitter l''entreprise où tu étais depuis quinze ans ?\n[Homme] Oui, mon dernier jour, c''était vendredi.\n[Femme] Et là, qu''est-ce qui domine, comme sentiment ?\n[Homme] ...\n\nA. Un mélange étrange de soulagement et de nostalgie.\nB. À cause d''un climat devenu vraiment pesant.\nC. Vers une petite structure beaucoup plus humaine.\nD. Au bout de plus de quinze années de service.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu viens de quitter l''entreprise où tu étais depuis quinze ans ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, mon dernier jour, c''était vendredi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et là, qu''est-ce qui domine, comme sentiment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un mélange étrange de soulagement et de nostalgie.<break time="700ms"/>B.<break time="300ms"/>À cause d''un climat devenu vraiment pesant.<break time="700ms"/>C.<break time="300ms"/>Vers une petite structure beaucoup plus humaine.<break time="700ms"/>D.<break time="300ms"/>Au bout de plus de quinze années de service.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui domine, comme sentiment ? » porte sur **l''émotion principale ressentie maintenant**. Seule A « un mélange de soulagement et de nostalgie » nomme un état affectif. B donne **la cause du départ** (« pourquoi es-tu parti ? »). C donne **la destination professionnelle** (« vers où ? »). D donne **la durée passée dans l''entreprise** (« depuis combien de temps ? ») — piège B2 fin : le 1er tour évoque déjà « quinze ans », ce qui rend D redondante par rapport au contexte.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Décision finale prise (« qu'as-tu fini par décider ? ») / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu hésitais entre rester à Lyon et partir t''installer à Berlin ?\n[Femme] Oui, j''ai retourné la question dans tous les sens.\n[Homme] Alors, qu''as-tu fini par décider, au bout du compte ?\n[Femme] ...\n\nA. Après plus de six mois de tergiversations, tout de même.\nB. De partir à Berlin, dès le mois d''octobre prochain.\nC. À cause d''une offre d''emploi vraiment exceptionnelle.\nD. Avec une vraie peur de tout quitter, je l''avoue.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu hésitais entre rester à Lyon et partir t''installer à Berlin ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai retourné la question dans tous les sens.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors, qu''as-tu fini par décider, au bout du compte ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Après plus de six mois de tergiversations, tout de même.<break time="700ms"/>B.<break time="300ms"/>De partir à Berlin, dès le mois d''octobre prochain.<break time="700ms"/>C.<break time="300ms"/>À cause d''une offre d''emploi vraiment exceptionnelle.<break time="700ms"/>D.<break time="300ms"/>Avec une vraie peur de tout quitter, je l''avoue.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (hésitation longue entre deux villes) prépare une question sur **le contenu de la décision finale**. « Qu''as-tu fini par décider ? » appelle l''énoncé du choix retenu. Seule B « de partir à Berlin » formule la décision elle-même. A donne **la durée du processus** de décision (« combien de temps as-tu hésité ? »). C donne **la cause du choix** (« pourquoi ce choix ? ») — piège B2 majeur : la cause justifie la décision mais n''est pas la décision. D donne **l''état d''esprit** accompagnant le choix (« comment le vis-tu ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Stratégie globale adoptée / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Votre entreprise a vraiment redressé la barre cette année ?\n[Homme] Oui, on a renoué avec les bénéfices au troisième trimestre.\n[Femme] Quelle stratégie avez-vous adoptée, fondamentalement ?\n[Homme] ...\n\nA. À l''échelle de l''ensemble du groupe européen, en réalité.\nB. Pour rassurer durablement nos actionnaires historiques.\nC. Un recentrage assumé sur nos métiers les plus rentables.\nD. Avec une confiance grandissante au fil des mois.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Votre entreprise a vraiment redressé la barre cette année ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on a renoué avec les bénéfices au troisième trimestre.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle stratégie avez-vous adoptée, fondamentalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''échelle de l''ensemble du groupe européen, en réalité.<break time="700ms"/>B.<break time="300ms"/>Pour rassurer durablement nos actionnaires historiques.<break time="700ms"/>C.<break time="300ms"/>Un recentrage assumé sur nos métiers les plus rentables.<break time="700ms"/>D.<break time="300ms"/>Avec une confiance grandissante au fil des mois.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle stratégie avez-vous adoptée ? » porte sur **l''axe directeur, l''orientation choisie**. Seule C « un recentrage assumé sur nos métiers les plus rentables » nomme une stratégie. A donne le **périmètre** d''application (« à quel niveau ? »). B donne le **but visé** (« dans quel objectif ? »). D donne **l''état d''esprit** des dirigeants (« dans quelle disposition ? ») — piège B2 fin : B et C sont proches (une stratégie a un but), mais B nomme la finalité alors que C nomme la méthode.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Influence majeure d'une personne / personnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as eu un professeur de mathématiques marquant au lycée ?\n[Femme] Oui, monsieur Lefèvre, en classe de terminale.\n[Homme] Tu en parles souvent, je trouve.\n[Femme] C''est vrai, il a beaucoup compté.\n[Homme] Mais concrètement, en quoi t''a-t-il vraiment influencée ?\n[Femme] ...\n\nA. Au lycée Henri-IV, à Paris, dans le cinquième.\nB. Pendant deux années consécutives, en première et terminale.\nC. À cause d''une approche très exigeante des démonstrations.\nD. Dans ma façon de raisonner, encore aujourd''hui.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as eu un professeur de mathématiques marquant au lycée ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, monsieur Lefèvre, en classe de terminale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu en parles souvent, je trouve.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est vrai, il a beaucoup compté.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais concrètement, en quoi t''a-t-il vraiment influencée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lycée Henri-IV, à Paris, dans le cinquième.<break time="700ms"/>B.<break time="300ms"/>Pendant deux années consécutives, en première et terminale.<break time="700ms"/>C.<break time="300ms"/>À cause d''une approche très exigeante des démonstrations.<break time="700ms"/>D.<break time="300ms"/>Dans ma façon de raisonner, encore aujourd''hui.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue insiste sur l''importance d''un enseignant. « En quoi t''a-t-il vraiment influencée ? » porte sur **le domaine concret de l''influence durable**. Seule D « dans ma façon de raisonner, encore aujourd''hui » désigne ce domaine. A donne le **lieu** d''enseignement. B donne la **durée** de la relation pédagogique. C donne la **cause** de son charisme (« pourquoi t''a-t-il marquée ? ») — piège B2 majeur : cause de l''influence et nature de l''influence sont distinctes, l''une explique l''autre.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Souvenir le plus précieux / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as passé toute ton enfance chez tes grands-parents à la campagne ?\n[Homme] Oui, presque chaque vacances scolaires.\n[Femme] De cette époque, quel souvenir tu chéris le plus ?\n[Homme] ...\n\nA. Les longues parties de cartes du dimanche soir.\nB. Dans une vieille ferme normande, à dire vrai.\nC. Au tout début des années quatre-vingt-dix, surtout.\nD. À cause de parents très souvent en déplacement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as passé toute ton enfance chez tes grands-parents à la campagne ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, presque chaque vacances scolaires.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">De cette époque, quel souvenir tu chéris le plus ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les longues parties de cartes du dimanche soir.<break time="700ms"/>B.<break time="300ms"/>Dans une vieille ferme normande, à dire vrai.<break time="700ms"/>C.<break time="300ms"/>Au tout début des années quatre-vingt-dix, surtout.<break time="700ms"/>D.<break time="300ms"/>À cause de parents très souvent en déplacement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel souvenir tu chéris le plus ? » porte sur **un souvenir précis, une image affectivement chargée**. Seule A « les longues parties de cartes du dimanche soir » nomme un souvenir concret. B donne le **lieu** (« où était-ce ? »). C donne **l''époque** (« quand ? »). D donne **la cause** du séjour chez les grands-parents (« pourquoi y étais-tu ? ») — piège B2 fin : D paraît cohérente avec le contexte familial mais ne désigne pas un souvenir.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Difficulté à surmonter / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as fini par réussir ce marathon que tu visais depuis trois ans ?\n[Femme] Oui, j''ai franchi la ligne à Berlin en septembre.\n[Homme] Quelle difficulté a-t-il fallu surmonter en priorité ?\n[Femme] ...\n\nA. Au prix d''un entraînement vraiment quotidien sur la fin.\nB. La douleur tenace au genou droit, en seconde moitié de course.\nC. Avec une fierté immense en franchissant la ligne, c''est sûr.\nD. À l''occasion du marathon de Berlin de septembre dernier.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as fini par réussir ce marathon que tu visais depuis trois ans ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai franchi la ligne à Berlin en septembre.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle difficulté a-t-il fallu surmonter en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au prix d''un entraînement vraiment quotidien sur la fin.<break time="700ms"/>B.<break time="300ms"/>La douleur tenace au genou droit, en seconde moitié de course.<break time="700ms"/>C.<break time="300ms"/>Avec une fierté immense en franchissant la ligne, c''est sûr.<break time="700ms"/>D.<break time="300ms"/>À l''occasion du marathon de Berlin de septembre dernier.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle difficulté a-t-il fallu surmonter ? » porte sur **l''obstacle majeur rencontré dans l''épreuve elle-même**. Seule B « la douleur tenace au genou droit » nomme un obstacle vécu. A donne **le sacrifice consenti** (« à quel prix ? ») — piège B2 majeur : sacrifice et difficulté sont voisins mais l''un est volontaire, l''autre subi. C donne **l''émotion finale** (« qu''as-tu ressenti ? »). D donne **le lieu et le moment** de l''épreuve.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Source d'un désaccord / professionnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] La réunion de ce matin avec l''équipe marketing s''est mal passée ?\n[Homme] Vraiment très mal, oui.\n[Femme] Tu m''avais pourtant dit que tout était calé d''avance.\n[Homme] Je le pensais sincèrement.\n[Femme] Alors, d''où vient réellement le désaccord ?\n[Homme] ...\n\nA. Vers la fin de la réunion, juste avant la pause.\nB. Au sein d''une équipe pourtant très compétente.\nC. D''une divergence profonde sur le ciblage des clients.\nD. Avec une amertume qui risque de durer un moment.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La réunion de ce matin avec l''équipe marketing s''est mal passée ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vraiment très mal, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''avais pourtant dit que tout était calé d''avance.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je le pensais sincèrement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, d''où vient réellement le désaccord ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers la fin de la réunion, juste avant la pause.<break time="700ms"/>B.<break time="300ms"/>Au sein d''une équipe pourtant très compétente.<break time="700ms"/>C.<break time="300ms"/>D''une divergence profonde sur le ciblage des clients.<break time="700ms"/>D.<break time="300ms"/>Avec une amertume qui risque de durer un moment.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue insiste sur la surprise du conflit (tout semblait calé). « D''où vient réellement le désaccord ? » porte sur **l''origine substantielle du désaccord, son objet de fond**. Seule C « d''une divergence profonde sur le ciblage des clients » identifie cette source. A donne **le moment** où le désaccord est apparu dans la réunion (« quand ? »). B donne **le cadre humain** (« dans quelle équipe ? »). D donne **les conséquences émotionnelles** (« avec quelles séquelles ? ») — piège B2 fin : la préposition « de » au début de C reprend exactement la formulation « d''où vient », alors que la préposition « avec » de D suggère une simple circonstance.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Point de bascule / récit / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La négociation avec le syndicat semblait vraiment dans l''impasse, non ?\n[Femme] On l''a pourtant débloquée jeudi en fin de soirée.\n[Homme] Qu''est-ce qui a fait basculer la situation, alors ?\n[Femme] ...\n\nA. Vers vingt-trois heures, après des heures de discussion serrée.\nB. Avec une satisfaction très partagée des deux côtés.\nC. Au siège social, dans la grande salle du conseil.\nD. L''arrivée inattendue du directeur général en personne.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La négociation avec le syndicat semblait vraiment dans l''impasse, non ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On l''a pourtant débloquée jeudi en fin de soirée.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui a fait basculer la situation, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers vingt-trois heures, après des heures de discussion serrée.<break time="700ms"/>B.<break time="300ms"/>Avec une satisfaction très partagée des deux côtés.<break time="700ms"/>C.<break time="300ms"/>Au siège social, dans la grande salle du conseil.<break time="700ms"/>D.<break time="300ms"/>L''arrivée inattendue du directeur général en personne.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui a fait basculer la situation ? » porte sur **l''élément précis qui a débloqué une impasse**. Seule D « l''arrivée inattendue du directeur général » identifie ce facteur de bascule. A donne **l''heure** du déblocage (« à quelle heure ? »). B donne **le climat** post-accord (« avec quel ressenti ? »). C donne **le lieu** de la négociation (« où ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Doute principal / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu envisages sérieusement de te lancer dans cette reconversion en pâtisserie ?\n[Homme] Oui, je n''attends presque plus que le bon moment.\n[Femme] Quel est ton principal doute, alors, aujourd''hui ?\n[Homme] ...\n\nA. La viabilité économique à moyen terme, avant tout.\nB. Pour vivre enfin d''une activité qui me passionne vraiment.\nC. À l''école Ferrandi, dès septembre prochain, idéalement.\nD. Avec un enthousiasme presque enfantin, je dois dire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu envisages sérieusement de te lancer dans cette reconversion en pâtisserie ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je n''attends presque plus que le bon moment.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton principal doute, alors, aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La viabilité économique à moyen terme, avant tout.<break time="700ms"/>B.<break time="300ms"/>Pour vivre enfin d''une activité qui me passionne vraiment.<break time="700ms"/>C.<break time="300ms"/>À l''école Ferrandi, dès septembre prochain, idéalement.<break time="700ms"/>D.<break time="300ms"/>Avec un enthousiasme presque enfantin, je dois dire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton principal doute ? » porte sur **l''inquiétude majeure, le point d''incertitude qui retient encore**. Seule A « la viabilité économique à moyen terme » formule un doute concret. B donne **la motivation** profonde (« pourquoi te lances-tu ? ») — piège B2 majeur : motivation et doute sont symétriques, l''un pousse, l''autre retient. C donne **le lieu et le moment** d''une éventuelle formation. D donne **l''état d''esprit positif** (« comment l''abordes-tu ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Conseil reçu transformant / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as vraiment changé de méthode de travail depuis cette formation ?\n[Femme] Du tout au tout, on dirait une autre personne.\n[Homme] Quel conseil a tout changé, finalement ?\n[Femme] ...\n\nA. Par l''intermédiaire d''une coach que je consulte depuis.\nB. De toujours commencer par la tâche la plus ingrate.\nC. Pour me sentir enfin pleinement maîtresse de mon temps.\nD. Au tout début du printemps de l''année dernière, déjà.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as vraiment changé de méthode de travail depuis cette formation ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Du tout au tout, on dirait une autre personne.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel conseil a tout changé, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par l''intermédiaire d''une coach que je consulte depuis.<break time="700ms"/>B.<break time="300ms"/>De toujours commencer par la tâche la plus ingrate.<break time="700ms"/>C.<break time="300ms"/>Pour me sentir enfin pleinement maîtresse de mon temps.<break time="700ms"/>D.<break time="300ms"/>Au tout début du printemps de l''année dernière, déjà.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel conseil a tout changé ? » porte sur **le contenu du conseil reçu, sa formulation pratique**. Seule B « de toujours commencer par la tâche la plus ingrate » formule le conseil lui-même. A donne **la source** du conseil (« par qui ? ») — piège B2 majeur : on confond souvent le messager et le message. C donne **l''effet recherché** par l''application du conseil (« pour quel ressenti ? »). D donne **le moment** où le conseil a été reçu (« quand ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Engagement personnel pris / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as adhéré à une association de protection du littoral récemment ?\n[Homme] Oui, je viens à peine de signer ma carte.\n[Femme] Et à quoi t''es-tu concrètement engagé, vis-à-vis d''eux ?\n[Homme] ...\n\nA. Auprès d''une association implantée depuis vingt ans en Bretagne.\nB. À cause d''un attachement très ancien à la côte sud.\nC. À donner deux week-ends par mois, pour aller sur le terrain.\nD. Avec une conviction profonde de l''urgence climatique.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as adhéré à une association de protection du littoral récemment ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je viens à peine de signer ma carte.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et à quoi t''es-tu concrètement engagé, vis-à-vis d''eux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès d''une association implantée depuis vingt ans en Bretagne.<break time="700ms"/>B.<break time="300ms"/>À cause d''un attachement très ancien à la côte sud.<break time="700ms"/>C.<break time="300ms"/>À donner deux week-ends par mois, pour aller sur le terrain.<break time="700ms"/>D.<break time="300ms"/>Avec une conviction profonde de l''urgence climatique.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quoi t''es-tu engagé ? » porte sur **le contenu concret de l''engagement pris**. Seule C « à donner deux week-ends par mois » (préposition « à » + infinitif = objet de l''engagement) formule cet engagement. A donne **l''interlocuteur** (« auprès de qui ? »). B donne **la cause profonde** de l''adhésion (« pourquoi cette cause ? »). D donne **l''état d''esprit** (« dans quelle conviction ? ») — piège B2 fin : la préposition « à » de C reprend exactement celle de la question, alors que les autres options changent de structure.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Mission qu'on s'est donnée / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu viens de prendre la direction de ce nouveau laboratoire, c''est cela ?\n[Femme] Oui, j''ai officiellement pris mes fonctions lundi dernier.\n[Homme] Quelle mission tu te fixes, eu égard à ce poste ?\n[Femme] ...\n\nA. Avec une vingtaine de doctorants à mes côtés, environ.\nB. À l''Inserm, sur le campus de Villejuif, désormais.\nC. Grâce à un financement européen récemment renouvelé.\nD. Faire émerger une équipe de référence en cardiologie cellulaire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu viens de prendre la direction de ce nouveau laboratoire, c''est cela ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai officiellement pris mes fonctions lundi dernier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle mission tu te fixes, eu égard à ce poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une vingtaine de doctorants à mes côtés, environ.<break time="700ms"/>B.<break time="300ms"/>À l''Inserm, sur le campus de Villejuif, désormais.<break time="700ms"/>C.<break time="300ms"/>Grâce à un financement européen récemment renouvelé.<break time="700ms"/>D.<break time="300ms"/>Faire émerger une équipe de référence en cardiologie cellulaire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle mission tu te fixes ? » porte sur **l''objectif structurant que la personne s''assigne**. Seule D « faire émerger une équipe de référence » formule cette mission ambitieuse. A donne **les effectifs** disponibles (« avec qui ? »). B donne **le lieu** d''exercice (« où ? »). C donne **les moyens financiers** (« grâce à quoi ? ») — piège B2 fin : les moyens permettent la mission mais ne la définissent pas.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Trace qu'on souhaite laisser / personnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu prends ta retraite à la fin de l''année scolaire, c''est cela ?\n[Homme] Oui, après quarante ans dans l''enseignement, c''est l''heure.\n[Femme] Tu dois être un peu nostalgique, malgré tout.\n[Homme] Énormément, oui.\n[Femme] Et quelle trace tu aimerais laisser, au fond ?\n[Homme] ...\n\nA. Le souvenir d''un professeur qui croyait en chacun de ses élèves.\nB. Au lycée Voltaire, où j''ai passé l''essentiel de ma carrière.\nC. Dès la rentrée prochaine, pour mes premiers mois de retraite.\nD. Avec une infinie reconnaissance envers mes collègues, surtout.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu prends ta retraite à la fin de l''année scolaire, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après quarante ans dans l''enseignement, c''est l''heure.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu dois être un peu nostalgique, malgré tout.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Énormément, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle trace tu aimerais laisser, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le souvenir d''un professeur qui croyait en chacun de ses élèves.<break time="700ms"/>B.<break time="300ms"/>Au lycée Voltaire, où j''ai passé l''essentiel de ma carrière.<break time="700ms"/>C.<break time="300ms"/>Dès la rentrée prochaine, pour mes premiers mois de retraite.<break time="700ms"/>D.<break time="300ms"/>Avec une infinie reconnaissance envers mes collègues, surtout.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue installe une fin de carrière chargée d''affect. « Quelle trace tu aimerais laisser ? » porte sur **l''empreinte symbolique souhaitée, le souvenir qu''on veut laisser de soi**. Seule A « le souvenir d''un professeur qui croyait en chacun » formule cette empreinte. B donne **le lieu** d''exercice (« où ? »). C donne **un moment** futur (« quand ? »). D donne **un sentiment personnel** de gratitude (« que ressens-tu envers eux ? ») — piège B2 majeur : D semble pertinente émotionnellement mais désigne la posture du locuteur, pas la trace laissée aux autres.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Image qui reste marquante / récit / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu rentres tout juste d''un reportage de plusieurs semaines en Mongolie ?\n[Femme] Oui, j''ai retrouvé Paris hier dans la nuit.\n[Homme] Quelle image te reste, par-dessus tout, de ce voyage ?\n[Femme] ...\n\nA. Ces troupeaux immenses se découpant à l''horizon, au crépuscule.\nB. À cause d''un visa obtenu à la dernière minute, en juin.\nC. Pour un magazine de reportages géopolitiques européen.\nD. Avec une fatigue assez intense, je dois bien l''admettre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu rentres tout juste d''un reportage de plusieurs semaines en Mongolie ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai retrouvé Paris hier dans la nuit.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle image te reste, par-dessus tout, de ce voyage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ces troupeaux immenses se découpant à l''horizon, au crépuscule.<break time="700ms"/>B.<break time="300ms"/>À cause d''un visa obtenu à la dernière minute, en juin.<break time="700ms"/>C.<break time="300ms"/>Pour un magazine de reportages géopolitiques européen.<break time="700ms"/>D.<break time="300ms"/>Avec une fatigue assez intense, je dois bien l''admettre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle image te reste ? » porte sur **un souvenir visuel précis, sensoriel, qui marque durablement**. Seule A « ces troupeaux immenses se découpant à l''horizon » décrit une image. B donne **les conditions de départ** (« comment as-tu pu partir ? »). C donne **le commanditaire** du reportage (« pour qui ? »). D donne **l''état physique** au retour (« comment te sens-tu ? ») — piège B2 fin : C et D ressortent du même champ professionnel du reportage mais aucune ne décrit une image.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Renoncement nécessaire / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as accepté ce poste très prenant à la direction internationale ?\n[Homme] Oui, après mûre réflexion en famille.\n[Femme] Et à quoi as-tu dû renoncer, en contrepartie ?\n[Homme] ...\n\nA. Au profit d''une rémunération nettement plus confortable.\nB. Avec une joie mêlée d''appréhension, je l''avoue.\nC. À mes soirées libres et à beaucoup de mes week-ends.\nD. Pour assumer plus tôt mes responsabilités familiales.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as accepté ce poste très prenant à la direction internationale ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après mûre réflexion en famille.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et à quoi as-tu dû renoncer, en contrepartie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au profit d''une rémunération nettement plus confortable.<break time="700ms"/>B.<break time="300ms"/>Avec une joie mêlée d''appréhension, je l''avoue.<break time="700ms"/>C.<break time="300ms"/>À mes soirées libres et à beaucoup de mes week-ends.<break time="700ms"/>D.<break time="300ms"/>Pour assumer plus tôt mes responsabilités familiales.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« À quoi as-tu dû renoncer ? » porte sur **ce qui a été perdu, sacrifié**. Seule C « à mes soirées libres et à beaucoup de mes week-ends » (préposition « à » = objet du renoncement) désigne le sacrifice. A donne **la contrepartie obtenue** (« en échange de quoi ? ») — piège B2 majeur : la préposition « au profit de » dans A peut sembler proche d''un renoncement, mais elle nomme le gain, pas la perte. B donne **l''état émotionnel** lors de la décision. D donne **la motivation** d''acceptation (« pour quoi faire ? »).',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Compromis acceptable / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez du mal à vous mettre d''accord pour les vacances d''été ?\n[Femme] On vise des choses très différentes, mon mari et moi.\n[Homme] Quel compromis serait acceptable, à tes yeux ?\n[Femme] ...\n\nA. Auprès de mes beaux-parents, en Provence, comme souvent.\nB. À cause d''une fatigue accumulée toute l''année par tous les deux.\nC. Au mois d''août, dès la fermeture annuelle du cabinet.\nD. Dix jours à la mer, suivis d''une semaine en montagne.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez du mal à vous mettre d''accord pour les vacances d''été ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On vise des choses très différentes, mon mari et moi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel compromis serait acceptable, à tes yeux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès de mes beaux-parents, en Provence, comme souvent.<break time="700ms"/>B.<break time="300ms"/>À cause d''une fatigue accumulée toute l''année par tous les deux.<break time="700ms"/>C.<break time="300ms"/>Au mois d''août, dès la fermeture annuelle du cabinet.<break time="700ms"/>D.<break time="300ms"/>Dix jours à la mer, suivis d''une semaine en montagne.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (envies divergentes dans le couple) cadre la question. « Quel compromis serait acceptable ? » porte sur **une solution intermédiaire combinant les attentes des deux parties**. Seule D « dix jours à la mer, suivis d''une semaine en montagne » formule un vrai compromis (deux univers combinés). A donne **le lieu** habituel d''hébergement. B donne **la cause** du besoin de vacances. C donne **le moment** du départ.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 21 : Promesse tenue / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000015', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu reviens enfin d''Australie après cinq mois d''absence ?\n[Homme] Oui, je suis rentré dimanche dernier, épuisé mais heureux.\n[Femme] Et quelle promesse as-tu tenue, là-bas, finalement ?\n[Homme] ...\n\nA. D''aller me recueillir sur la tombe de mon grand-père, à Sydney.\nB. Au bout de presque cinq mois loin de la maison, c''est long.\nC. Avec une émotion qui m''a vraiment surpris sur place.\nD. À cause d''un héritage familial qui me tenait à cœur.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens enfin d''Australie après cinq mois d''absence ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis rentré dimanche dernier, épuisé mais heureux.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle promesse as-tu tenue, là-bas, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>D''aller me recueillir sur la tombe de mon grand-père, à Sydney.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque cinq mois loin de la maison, c''est long.<break time="700ms"/>C.<break time="300ms"/>Avec une émotion qui m''a vraiment surpris sur place.<break time="700ms"/>D.<break time="300ms"/>À cause d''un héritage familial qui me tenait à cœur.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle promesse as-tu tenue ? » porte sur **le contenu concret de l''engagement honoré**. Seule A « d''aller me recueillir sur la tombe de mon grand-père » formule la promesse elle-même (« promesse de + infinitif »). B donne **la durée** du séjour. C donne **l''état émotionnel** vécu sur place. D donne **la motivation profonde** du voyage (« pourquoi y es-tu allé ? ») — piège B2 majeur : motivation et promesse sont liées (on s''engage parce qu''on est motivé), mais l''une nomme la cause intérieure, l''autre l''acte verbal d''engagement.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 22 : Aspect le plus complexe à gérer / professionnel / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-3000-0000-000000000016', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu pilotes un projet à cheval sur trois pays, désormais ?\n[Femme] Oui, depuis le début de l''année fiscale.\n[Homme] Cela doit ajouter pas mal de coordination.\n[Femme] Énormément, et pas toujours de la plus simple.\n[Homme] Mais qu''est-ce qui est le plus complexe à gérer, au fond ?\n[Femme] ...\n\nA. À l''échelle de trois pays européens, oui, c''est cela.\nB. La conciliation des fuseaux horaires, en réalité, plus que tout.\nC. Pendant près de douze mois consécutifs, sans interruption.\nD. Avec une équipe internationale d''une trentaine de personnes.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu pilotes un projet à cheval sur trois pays, désormais ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, depuis le début de l''année fiscale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cela doit ajouter pas mal de coordination.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Énormément, et pas toujours de la plus simple.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui est le plus complexe à gérer, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''échelle de trois pays européens, oui, c''est cela.<break time="700ms"/>B.<break time="300ms"/>La conciliation des fuseaux horaires, en réalité, plus que tout.<break time="700ms"/>C.<break time="300ms"/>Pendant près de douze mois consécutifs, sans interruption.<break time="700ms"/>D.<break time="300ms"/>Avec une équipe internationale d''une trentaine de personnes.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le dialogue cadre la complexité d''un projet multi-pays. « Qu''est-ce qui est le plus complexe à gérer ? » porte sur **la difficulté opérationnelle la plus aiguë**. Seule B « la conciliation des fuseaux horaires » identifie un problème concret de gestion. A donne le **périmètre géographique** (déjà mentionné dans le premier tour, donc redondant). C donne **la durée** prévue. D donne la **composition** de l''équipe — piège B2 fin : A, C, D décrivent toutes des caractéristiques du projet, mais seule B nomme une difficulté à gérer au quotidien.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
