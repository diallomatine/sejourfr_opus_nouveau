-- ============================================================
-- 10 exercices B2 - CO TCF - format "réponse à question implicite"
-- Dialogues de 3 à 4 tours (alternance Henri / Denise),
-- formulations indirectes (« qu'est-ce qui... », « à quoi tient... »,
-- « par quel biais... », « dans quel état d'esprit... »),
-- lexique soutenu, distinctions pragmatiques fines.
-- ============================================================

-- ----- Exercice 1 : Réaction émotionnelle (vs manière de présenter) / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as enfin osé demander à Mathieu une augmentation ?\n[Homme] Oui, je lui en ai parlé lundi matin.\n[Femme] Et au juste, comment a-t-il pris la chose ?\n[Homme] ...\n\nA. Avec une étonnante ouverture d''esprit.\nB. Au cours de notre point hebdomadaire.\nC. Parce que mes résultats parlent d''eux-mêmes.\nD. En soulignant fermement les enjeux pour l''équipe.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as enfin osé demander à Mathieu une augmentation ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je lui en ai parlé lundi matin.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et au juste, comment a-t-il pris la chose ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une étonnante ouverture d''esprit.<break time="700ms"/>B.<break time="300ms"/>Au cours de notre point hebdomadaire.<break time="700ms"/>C.<break time="300ms"/>Parce que mes résultats parlent d''eux-mêmes.<break time="700ms"/>D.<break time="300ms"/>En soulignant fermement les enjeux pour l''équipe.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (la demande d''augmentation a eu lieu) prépare une question sur **la réaction de Mathieu**. « Comment a-t-il pris la chose ? » porte sur la réaction émotionnelle/disposition du destinataire de la demande. Seule A « avec une étonnante ouverture d''esprit » décrit cette réaction. B donne le **cadre temporel** de la discussion (« lors de quel rendez-vous ? »). C donne la **cause / justification** de la demande (« pourquoi en as-tu fait la demande ? »). D donne **la manière dont l''homme a présenté sa demande** — piège B2 majeur : « en soulignant » est un gérondif de manière, mais le sujet implicite est le locuteur, pas Mathieu ; D répond à « comment as-tu présenté ta demande ? ».',
    '[
       {"label": "Avec une étonnante ouverture d''esprit.", "is_correct": true, "display_order": 1},
       {"label": "Au cours de notre point hebdomadaire.", "is_correct": false, "display_order": 2},
       {"label": "Parce que mes résultats parlent d''eux-mêmes.", "is_correct": false, "display_order": 3},
       {"label": "En soulignant fermement les enjeux pour l''équipe.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Finalité prioritaire (vs cause / condition / moment) / projet / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Vous avez réussi à boucler le dossier de subvention pour le projet ?\n[Homme] Oui, on a eu confirmation lundi.\n[Femme] Bravo. Et concrètement, à quoi va servir cet argent en priorité ?\n[Homme] ...\n\nA. À recruter deux profils techniques dès septembre.\nB. Grâce au soutien d''un partenaire allemand.\nC. Sous réserve d''une évaluation à mi-parcours.\nD. Au moment où les recrutements seront finalisés.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez réussi à boucler le dossier de subvention pour le projet ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on a eu confirmation lundi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bravo. Et concrètement, à quoi va servir cet argent en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À recruter deux profils techniques dès septembre.<break time="700ms"/>B.<break time="300ms"/>Grâce au soutien d''un partenaire allemand.<break time="700ms"/>C.<break time="300ms"/>Sous réserve d''une évaluation à mi-parcours.<break time="700ms"/>D.<break time="300ms"/>Au moment où les recrutements seront finalisés.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours valident l''obtention du financement. La question implicite « à quoi va servir cet argent en priorité ? » porte sur **la finalité, l''usage prioritaire**. Seule A « à recruter deux profils » (à + infinitif = finalité) y répond. B donne la **cause / le moyen de l''obtention** (« comment l''avez-vous obtenu ? »). C donne une **condition** sur l''usage (« sous quelles conditions est-il alloué ? ») — piège fin B2 : C est cohérente avec un budget mais ne désigne pas un usage. D donne un **moment** (« quand pourra-t-il être pleinement utilisé ? »).',
    '[
       {"label": "À recruter deux profils techniques dès septembre.", "is_correct": true, "display_order": 1},
       {"label": "Grâce au soutien d''un partenaire allemand.", "is_correct": false, "display_order": 2},
       {"label": "Sous réserve d''une évaluation à mi-parcours.", "is_correct": false, "display_order": 3},
       {"label": "Au moment où les recrutements seront finalisés.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Critère décisif (vs moment / lieu / réaction) / formation / 4 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu sais quoi, j''ai été prise dans la formation de Polytechnique !\n[Homme] Félicitations, c''est extraordinaire !\n[Femme] Oui, ils m''ont rappelée hier.\n[Homme] Mais à ton avis, qu''est-ce qui a fait pencher la balance ?\n[Femme] ...\n\nA. Mon parcours associatif, je pense.\nB. Dès la fin de l''été dernier, en réalité.\nC. Devant un jury de cinq personnes.\nD. Plutôt avec une certaine émotion, à vrai dire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais quoi, j''ai été prise dans la formation de Polytechnique !</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Félicitations, c''est extraordinaire !</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ils m''ont rappelée hier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais à ton avis, qu''est-ce qui a fait pencher la balance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Mon parcours associatif, je pense.<break time="700ms"/>B.<break time="300ms"/>Dès la fin de l''été dernier, en réalité.<break time="700ms"/>C.<break time="300ms"/>Devant un jury de cinq personnes.<break time="700ms"/>D.<break time="300ms"/>Plutôt avec une certaine émotion, à vrai dire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les trois premiers tours installent le contexte (admission obtenue, annonce récente). La question finale « qu''est-ce qui a fait pencher la balance ? » demande **le critère décisif, le facteur différenciant** dans la sélection. Seule A « mon parcours associatif » désigne ce critère. B donne un **moment** (« depuis quand est-ce engagé ? »). C donne le **cadre / les acteurs** de la sélection (« qui t''a auditionnée ? »). D donne la **réaction émotionnelle** à la nouvelle (« comment as-tu reçu la réponse ? ») — piège B2 récurrent : confondre la cause du choix et la réaction à son annonce.',
    '[
       {"label": "Mon parcours associatif, je pense.", "is_correct": true, "display_order": 1},
       {"label": "Dès la fin de l''été dernier, en réalité.", "is_correct": false, "display_order": 2},
       {"label": "Devant un jury de cinq personnes.", "is_correct": false, "display_order": 3},
       {"label": "Plutôt avec une certaine émotion, à vrai dire.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Méthode / moyen d'apprentissage (vs durée / but / accompagnant) / langues / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] J''ai vu que tu parles couramment japonais maintenant.\n[Femme] Pas couramment, mais je me débrouille très bien.\n[Homme] Comment tu t''y es prise pour atteindre ce niveau-là ?\n[Femme] ...\n\nA. En combinant cours du soir et applications mobiles.\nB. Au bout de presque cinq années de pratique.\nC. Pour pouvoir travailler à Tokyo un jour.\nD. Avec une professeure particulièrement exigeante.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai vu que tu parles couramment japonais maintenant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Pas couramment, mais je me débrouille très bien.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment tu t''y es prise pour atteindre ce niveau-là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En combinant cours du soir et applications mobiles.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque cinq années de pratique.<break time="700ms"/>C.<break time="300ms"/>Pour pouvoir travailler à Tokyo un jour.<break time="700ms"/>D.<break time="300ms"/>Avec une professeure particulièrement exigeante.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Le contexte (niveau actuel solide en japonais) pose le décor. La question « comment tu t''y es prise pour atteindre... » interroge **la méthode, les moyens employés**. Seule A « en combinant cours du soir et applications mobiles » (gérondif de moyen) désigne la démarche. B donne une **durée** (« combien de temps cela t''a-t-il pris ? »). C donne un **but** (« dans quel objectif l''as-tu appris ? »). D donne un **accompagnement / une personne ressource** (« avec qui as-tu appris ? ») — piège B2 fin : D semble répondre à « comment » mais désigne en réalité un compagnon d''apprentissage et non la méthode.',
    '[
       {"label": "En combinant cours du soir et applications mobiles.", "is_correct": true, "display_order": 1},
       {"label": "Au bout de presque cinq années de pratique.", "is_correct": false, "display_order": 2},
       {"label": "Pour pouvoir travailler à Tokyo un jour.", "is_correct": false, "display_order": 3},
       {"label": "Avec une professeure particulièrement exigeante.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Conséquence (vs cause antérieure) / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fini par quitter ton ancien poste, finalement ?\n[Homme] Oui, à la rentrée dernière.\n[Femme] Et qu''est-ce que ça a changé concrètement dans ton quotidien ?\n[Homme] ...\n\nA. Un bien meilleur équilibre entre vie pro et vie perso.\nB. Une lassitude profonde envers ma hiérarchie.\nC. Après une longue réflexion en famille, tout de même.\nD. À titre personnel, plus qu''à titre professionnel.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par quitter ton ancien poste, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, à la rentrée dernière.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et qu''est-ce que ça a changé concrètement dans ton quotidien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un bien meilleur équilibre entre vie pro et vie perso.<break time="700ms"/>B.<break time="300ms"/>Une lassitude profonde envers ma hiérarchie.<break time="700ms"/>C.<break time="300ms"/>Après une longue réflexion en famille, tout de même.<break time="700ms"/>D.<break time="300ms"/>À titre personnel, plus qu''à titre professionnel.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours établissent le fait (le départ a eu lieu). La question « qu''est-ce que ça a changé... ? » porte sur **la conséquence, l''effet observé après coup**. Seule A « un bien meilleur équilibre » décrit ce changement. B donne **la cause antérieure** du départ (« pourquoi es-tu parti ? ») — piège B2 majeur : cause et conséquence sont symétriques autour de l''événement, il faut entendre la temporalité de la question (« a changé » = après). C donne **le processus de décision** (« comment as-tu pris la décision ? »). D précise **le registre / le périmètre** du changement (« dans quel domaine est-ce surtout vrai ? »), pas le changement lui-même.',
    '[
       {"label": "Un bien meilleur équilibre entre vie pro et vie perso.", "is_correct": true, "display_order": 1},
       {"label": "Une lassitude profonde envers ma hiérarchie.", "is_correct": false, "display_order": 2},
       {"label": "Après une longue réflexion en famille, tout de même.", "is_correct": false, "display_order": 3},
       {"label": "À titre personnel, plus qu''à titre professionnel.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Facteur explicatif (« à quoi tient... ») / culturel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as l''air vraiment satisfaite de ta dernière exposition.\n[Femme] Oui, c''est sans doute la mieux reçue jusqu''à présent.\n[Homme] À quoi tient ce succès, selon toi ?\n[Femme] ...\n\nA. À la cohérence d''ensemble entre les œuvres présentées.\nB. Tout près du quai Branly, dans le septième arrondissement.\nC. Jusqu''à la toute fin du mois de mars.\nD. À l''occasion d''un long week-end férié, finalement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air vraiment satisfaite de ta dernière exposition.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est sans doute la mieux reçue jusqu''à présent.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quoi tient ce succès, selon toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la cohérence d''ensemble entre les œuvres présentées.<break time="700ms"/>B.<break time="300ms"/>Tout près du quai Branly, dans le septième arrondissement.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à la toute fin du mois de mars.<break time="700ms"/>D.<break time="300ms"/>À l''occasion d''un long week-end férié, finalement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours installent le constat (exposition très bien reçue). La formulation indirecte « à quoi tient... ? » demande **un facteur explicatif, ce qui cause / explique le succès**. Seule A « à la cohérence entre les œuvres » désigne ce facteur. B donne le **lieu** de l''exposition (« où se tient-elle ? »). C donne **la durée jusqu''à terme** (« jusqu''à quand est-elle ouverte ? »). D donne **le moment du vernissage** (« quand a-t-elle eu lieu ? ») — piège B2 fin : la préposition « à » se retrouve aussi dans D, ce qui peut tromper, mais « à l''occasion de » est temporel, pas explicatif.',
    '[
       {"label": "À la cohérence d''ensemble entre les œuvres présentées.", "is_correct": true, "display_order": 1},
       {"label": "Tout près du quai Branly, dans le septième arrondissement.", "is_correct": false, "display_order": 2},
       {"label": "Jusqu''à la toute fin du mois de mars.", "is_correct": false, "display_order": 3},
       {"label": "À l''occasion d''un long week-end férié, finalement.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Source indirecte (« par quel biais... ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as postulé chez Renault, finalement ?\n[Homme] Oui, je dois passer les entretiens la semaine prochaine.\n[Femme] Au fait, par quel biais tu as eu vent du poste ?\n[Homme] ...\n\nA. Par l''intermédiaire d''un ancien collègue à moi.\nB. Pour un salaire légèrement plus avantageux.\nC. Au bout de plusieurs mois d''attente, en fait.\nD. Avec un enthousiasme assez modéré, je dois dire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as postulé chez Renault, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je dois passer les entretiens la semaine prochaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Au fait, par quel biais tu as eu vent du poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par l''intermédiaire d''un ancien collègue à moi.<break time="700ms"/>B.<break time="300ms"/>Pour un salaire légèrement plus avantageux.<break time="700ms"/>C.<break time="300ms"/>Au bout de plusieurs mois d''attente, en fait.<break time="700ms"/>D.<break time="300ms"/>Avec un enthousiasme assez modéré, je dois dire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours valident le fait (candidature posée, entretiens à venir). « Par quel biais tu as eu vent du poste ? » est une formulation soutenue interrogeant **la source / l''intermédiaire qui t''a renseigné**. Seule A « par l''intermédiaire d''un ancien collègue » désigne cet intermédiaire. B donne une **motivation / avantage** (« pourquoi postules-tu ? »). C donne une **durée d''attente** (« depuis combien de temps cherches-tu ? »). D donne **l''état d''esprit** du candidat (« dans quelle disposition postules-tu ? ») — piège B2 : la préposition « par » de A et la préposition « avec » de D peuvent toutes deux suggérer une manière, mais seule A désigne une source.',
    '[
       {"label": "Par l''intermédiaire d''un ancien collègue à moi.", "is_correct": true, "display_order": 1},
       {"label": "Pour un salaire légèrement plus avantageux.", "is_correct": false, "display_order": 2},
       {"label": "Au bout de plusieurs mois d''attente, en fait.", "is_correct": false, "display_order": 3},
       {"label": "Avec un enthousiasme assez modéré, je dois dire.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Moyen financier (vs accompagnement / quantité / lieu) / familial / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez réussi à organiser ce mariage entièrement vous-mêmes ?\n[Femme] Avec quelques aides, mais oui, en grande partie.\n[Homme] Comment vous vous y êtes pris pour financer une réception pareille ?\n[Femme] ...\n\nA. En économisant patiemment pendant près de trois ans.\nB. Auprès de nos familles les plus proches, surtout.\nC. Plus de cent cinquante invités, je crois.\nD. Dans une jolie bâtisse au bord de la Loire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez réussi à organiser ce mariage entièrement vous-mêmes ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec quelques aides, mais oui, en grande partie.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment vous vous y êtes pris pour financer une réception pareille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En économisant patiemment pendant près de trois ans.<break time="700ms"/>B.<break time="300ms"/>Auprès de nos familles les plus proches, surtout.<break time="700ms"/>C.<break time="300ms"/>Plus de cent cinquante invités, je crois.<break time="700ms"/>D.<break time="300ms"/>Dans une jolie bâtisse au bord de la Loire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le sujet (organisation autonome du mariage, avec quelques aides). « Comment vous vous y êtes pris pour financer ? » porte sur **le moyen financier, la méthode pour réunir l''argent**. Seule A « en économisant patiemment » (gérondif de moyen) répond. B donne **l''origine des aides** (« auprès de qui ? ») — piège B2 majeur : le deuxième tour mentionne « quelques aides », ce qui rend B très tentante, mais B identifie un soutien, pas la méthode principale de financement. C donne **le nombre d''invités**. D donne **le lieu** de la réception.',
    '[
       {"label": "En économisant patiemment pendant près de trois ans.", "is_correct": true, "display_order": 1},
       {"label": "Auprès de nos familles les plus proches, surtout.", "is_correct": false, "display_order": 2},
       {"label": "Plus de cent cinquante invités, je crois.", "is_correct": false, "display_order": 3},
       {"label": "Dans une jolie bâtisse au bord de la Loire.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : État d'esprit (vs durée / accompagnant / but) / administratif / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu reviens tout juste de ton entretien à la mairie ?\n[Homme] Oui, je suis sorti il y a une heure environ.\n[Femme] Et dans quel état d''esprit tu en ressors ?\n[Homme] ...\n\nA. Plutôt confiant, je dois bien dire.\nB. Au bout de presque deux heures de discussion.\nC. Face à un panel de trois élus locaux.\nD. Pour un poste de chargé de mission culture.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens tout juste de ton entretien à la mairie ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis sorti il y a une heure environ.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et dans quel état d''esprit tu en ressors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt confiant, je dois bien dire.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque deux heures de discussion.<break time="700ms"/>C.<break time="300ms"/>Face à un panel de trois élus locaux.<break time="700ms"/>D.<break time="300ms"/>Pour un poste de chargé de mission culture.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent le décor (entretien terminé, très récent). « Dans quel état d''esprit tu en ressors ? » porte sur **la disposition intérieure, le ressenti subjectif après l''épreuve**. Seule A « plutôt confiant » décrit cette disposition. B donne **la durée de l''entretien** (« combien de temps a duré l''entretien ? »). C donne **les interlocuteurs** (« face à qui étais-tu ? »). D donne **le but / l''objet de la candidature** (« pour quel poste postules-tu ? ») — piège B2 fin : la préposition « dans » dans la question et la préposition « pour » dans D peuvent toutes deux évoquer un contexte, mais D ne décrit pas un état mental.',
    '[
       {"label": "Plutôt confiant, je dois bien dire.", "is_correct": true, "display_order": 1},
       {"label": "Au bout de presque deux heures de discussion.", "is_correct": false, "display_order": 2},
       {"label": "Face à un panel de trois élus locaux.", "is_correct": false, "display_order": 3},
       {"label": "Pour un poste de chargé de mission culture.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Dénouement (« qu'en est-il advenu ? ») / récit social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-1000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu te souviens de cette histoire d''héritage compliqué chez les Dubois ?\n[Femme] Oui, ça s''éternisait depuis des années.\n[Homme] Justement, je me demandais ce qu''il en était advenu, au final ?\n[Femme] ...\n\nA. Un accord à l''amiable, signé l''été dernier.\nB. À cause de différends entre frères et sœurs.\nC. Par l''intermédiaire d''un notaire de Bordeaux.\nD. Avec une amertume durable, paraît-il.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu te souviens de cette histoire d''héritage compliqué chez les Dubois ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça s''éternisait depuis des années.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, je me demandais ce qu''il en était advenu, au final ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un accord à l''amiable, signé l''été dernier.<break time="700ms"/>B.<break time="300ms"/>À cause de différends entre frères et sœurs.<break time="700ms"/>C.<break time="300ms"/>Par l''intermédiaire d''un notaire de Bordeaux.<break time="700ms"/>D.<break time="300ms"/>Avec une amertume durable, paraît-il.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Les deux premiers tours posent une affaire d''héritage qui traînait. La formulation indirecte « ce qu''il en était advenu, au final » demande **le dénouement, l''issue de l''affaire**. Seule A « un accord à l''amiable, signé l''été dernier » désigne ce dénouement. B donne **la cause originelle** du conflit (« pourquoi cela durait-il ? »). C donne **l''intermédiaire / l''acteur** qui a aidé (« par qui cela a-t-il été résolu ? ») — piège B2 fin : un notaire est lié à un règlement d''héritage, ce qui rend C plausible, mais elle ne dit pas comment l''affaire s''est terminée. D donne **le climat émotionnel** post-résolution (« dans quelle ambiance cela s''est-il fini ? »).',
    '[
       {"label": "Un accord à l''amiable, signé l''été dernier.", "is_correct": true, "display_order": 1},
       {"label": "À cause de différends entre frères et sœurs.", "is_correct": false, "display_order": 2},
       {"label": "Par l''intermédiaire d''un notaire de Bordeaux.", "is_correct": false, "display_order": 3},
       {"label": "Avec une amertume durable, paraît-il.", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
