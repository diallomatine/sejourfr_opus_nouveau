-- ============================================================
-- 20 exercices C2 (stockés en B2 faute d'enum C2) - CO TCF
-- Format "réponse à question implicite" - niveau RÉEL C2.
-- Traçabilité C2 : préfixe UUID 66666666-00c2-1000-...
-- + competence_code 'co_dialogue_c2_implicite'.
-- Dialogues 3 à 5 tours, alternance Henri / Denise,
-- ironie, litote, antiphrase, sous-entendus mondains,
-- mépris voilé, allusions, registres mélangés.
-- Labels A/B/C/D : contenu lu dans l'audio.
-- Position bonne réponse équilibrée : 5×A, 5×B, 5×C, 5×D.
-- Voix : 10 Henri / 10 Denise sur voice_recommended.
-- ============================================================

-- ----- Exercice 1 : Antiphrase à décoder / mondain / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000001', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Alors, ce dîner chez les Marchand, raconte-moi.\n[Homme] Une soirée d''une rare élévation intellectuelle, ma chère.\n[Femme] Tiens donc, à ce point ?\n[Homme] Oui, j''ai cru défaillir devant tant d''esprit.\n[Femme] Sois honnête : tu en as pensé quoi, vraiment ?\n[Homme] ...\n\nA. Que c''était d''une platitude consommée, en réalité.\nB. Qu''ils ont, malgré tout, beaucoup de mérite à recevoir.\nC. Que la conversation a culminé au moment du dessert.\nD. Qu''ils m''ont gentiment raccompagné jusqu''à la porte.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, ce dîner chez les Marchand, raconte-moi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Une soirée d''une rare élévation intellectuelle, ma chère.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tiens donc, à ce point ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai cru défaillir devant tant d''esprit.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sois honnête : tu en as pensé quoi, vraiment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que c''était d''une platitude consommée, en réalité.<break time="700ms"/>B.<break time="300ms"/>Qu''ils ont, malgré tout, beaucoup de mérite à recevoir.<break time="700ms"/>C.<break time="300ms"/>Que la conversation a culminé au moment du dessert.<break time="700ms"/>D.<break time="300ms"/>Qu''ils m''ont gentiment raccompagné jusqu''à la porte.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **antiphrase**. Henri loue avec emphase (« rare élévation », « défaillir devant tant d''esprit ») un dîner qu''il a en vérité trouvé ennuyeux ; la dernière question de Denise (« vraiment ? ») invite explicitement à dépasser l''ironie. Seule A « d''une platitude consommée » dit le jugement réel sous l''antiphrase. B propose une **lecture conciliante** (« malgré tout du mérite »), qui adoucit l''antiphrase au lieu de la décoder. C donne **un détail factuel** sur le déroulement du dîner. D donne **un détail mondain de courtoisie**. Une lecture littérale (le compliment) serait insuffisante car elle ignore la modulation ironique demandée par Denise.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Litote à interpréter / culturel / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000002', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Alors, cette nouvelle exposition au Grand Palais ?\n[Femme] Disons que je n''en suis pas ressortie indifférente.\n[Homme] Voilà une formule prudente. Cela t''a déplu, alors ?\n[Femme] Loin s''en faut, vraiment.\n[Homme] Sois plus claire : qu''as-tu réellement éprouvé ?\n[Femme] ...\n\nA. Que les salles étaient particulièrement bondées ce jour-là.\nB. Que j''ai été déçue, comme à mon habitude désormais.\nC. Que l''affiche promettait davantage qu''elle ne tenait.\nD. Que j''ai été littéralement bouleversée par l''ensemble.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors, cette nouvelle exposition au Grand Palais ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Disons que je n''en suis pas ressortie indifférente.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Voilà une formule prudente. Cela t''a déplu, alors ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Loin s''en faut, vraiment.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sois plus claire : qu''as-tu réellement éprouvé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que les salles étaient particulièrement bondées ce jour-là.<break time="700ms"/>B.<break time="300ms"/>Que j''ai été déçue, comme à mon habitude désormais.<break time="700ms"/>C.<break time="300ms"/>Que l''affiche promettait davantage qu''elle ne tenait.<break time="700ms"/>D.<break time="300ms"/>Que j''ai été littéralement bouleversée par l''ensemble.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **litote**. « Je n''en suis pas ressortie indifférente » et « loin s''en faut » sont deux atténuations par négation qui signifient un sentiment fort et positif ; Henri presse pour passer du dit (la prudence) au pensé (l''émotion réelle). Seule D « littéralement bouleversée » dit ce sentiment plein. A donne **un détail circonstanciel** (la foule). B propose **la lecture inverse** (déception), incompatible avec « loin s''en faut » qui repousse précisément l''idée d''un déplaisir. C propose **une critique modérée**, ce qui revient à manquer la force positive de la litote. Lire littéralement « pas indifférente » comme « tiède » serait précisément le contresens à éviter.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Ironie mordante / professionnel / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000003', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le nouveau directeur a tenu son grand discours stratégique, hier.\n[Homme] Ah, enfin un visionnaire à la barre.\n[Femme] Tu m''as l''air dubitatif, malgré le compliment.\n[Homme] Il a redécouvert l''eau tiède avec un aplomb remarquable.\n[Femme] Alors concrètement, quel jugement tu portes sur lui ?\n[Homme] ...\n\nA. Qu''il bénéficie d''un soutien indéfectible du comité.\nB. Qu''il enrobe des évidences avec une assurance déconcertante.\nC. Qu''il prend ses fonctions dans un contexte tendu.\nD. Qu''il a parlé près d''une heure devant l''ensemble du comité.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le nouveau directeur a tenu son grand discours stratégique, hier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, enfin un visionnaire à la barre.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as l''air dubitatif, malgré le compliment.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Il a redécouvert l''eau tiède avec un aplomb remarquable.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors concrètement, quel jugement tu portes sur lui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''il bénéficie d''un soutien indéfectible du comité.<break time="700ms"/>B.<break time="300ms"/>Qu''il enrobe des évidences avec une assurance déconcertante.<break time="700ms"/>C.<break time="300ms"/>Qu''il prend ses fonctions dans un contexte tendu.<break time="700ms"/>D.<break time="300ms"/>Qu''il a parlé près d''une heure devant l''ensemble du comité.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **ironie mordante** filée. « Visionnaire à la barre » est posé puis aussitôt sapé par « redécouvert l''eau tiède », expression idiomatique pour banaliser une découverte ; Denise demande explicitement le jugement réel. Seule B « il enrobe des évidences avec aplomb » paraphrase exactement la pique. A donne **un fait politique** (soutien hiérarchique), neutre. C donne **un cadre conjoncturel** sans porter de jugement. D donne **un fait factuel** (durée de l''intervention). Une lecture littérale du « visionnaire » ferait l''impasse sur la métaphore figée qui inverse l''éloge.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Compliment ambigu / professionnel / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000004', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as enfin lu le manuscrit de Romain ?\n[Homme] C''est un travail très appliqué, on le sent à chaque page.\n[Femme] Très appliqué… mais encore ?\n[Homme] Oh, il maîtrise vraiment toutes les règles qu''on lui a apprises.\n[Femme] Bref, ton compliment cache quoi, au juste ?\n[Homme] ...\n\nA. Que je n''ai pas eu le temps de tout lire jusqu''au bout.\nB. Qu''il a manifestement progressé depuis son premier roman.\nC. Qu''il manque cruellement de souffle et d''invention propre.\nD. Qu''il a travaillé près de deux ans sur ce manuscrit.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as enfin lu le manuscrit de Romain ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est un travail très appliqué, on le sent à chaque page.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Très appliqué… mais encore ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oh, il maîtrise vraiment toutes les règles qu''on lui a apprises.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bref, ton compliment cache quoi, au juste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que je n''ai pas eu le temps de tout lire jusqu''au bout.<break time="700ms"/>B.<break time="300ms"/>Qu''il a manifestement progressé depuis son premier roman.<break time="700ms"/>C.<break time="300ms"/>Qu''il manque cruellement de souffle et d''invention propre.<break time="700ms"/>D.<break time="300ms"/>Qu''il a travaillé près de deux ans sur ce manuscrit.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **compliment ambigu** (faux éloge). « Très appliqué » et « toutes les règles qu''on lui a apprises » sont des adjectifs scolaires qui signalent en creux l''absence d''originalité ; Denise demande explicitement ce que le compliment dissimule. Seule C « manque de souffle et d''invention propre » formule cette réserve cachée. A donne **une excuse personnelle** (lecture inachevée). B donne **une lecture bienveillante** (progrès), qui prend le compliment au pied de la lettre. D donne **un fait extérieur** (durée du travail). Une lecture littérale lirait C comme un éloge ; il faut entendre la sous-évaluation discrète.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Reproche déguisé en compliment / familial / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000005', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as encore réussi à filer avant la fin du repas de famille.\n[Homme] J''avais un dossier qui ne pouvait pas attendre, hélas.\n[Femme] Bien sûr. Quelle constance, vraiment, dans tes obligations.\n[Homme] Tu le dis sur un ton qui n''augure rien de bon.\n[Femme] Sois lucide : où se niche le reproche, en fait ?\n[Homme] ...\n\nA. Dans le fait que je m''éclipse systématiquement à chaque occasion.\nB. Dans la régularité dont tu reconnais, malgré tout, le mérite.\nC. Dans le ton sec sur lequel tu m''as accueilli hier soir.\nD. Dans l''heure tardive à laquelle j''avais fini de travailler.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as encore réussi à filer avant la fin du repas de famille.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''avais un dossier qui ne pouvait pas attendre, hélas.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bien sûr. Quelle constance, vraiment, dans tes obligations.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu le dis sur un ton qui n''augure rien de bon.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sois lucide : où se niche le reproche, en fait ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans le fait que je m''éclipse systématiquement à chaque occasion.<break time="700ms"/>B.<break time="300ms"/>Dans la régularité dont tu reconnais, malgré tout, le mérite.<break time="700ms"/>C.<break time="300ms"/>Dans le ton sec sur lequel tu m''as accueilli hier soir.<break time="700ms"/>D.<break time="300ms"/>Dans l''heure tardive à laquelle j''avais fini de travailler.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **reproche déguisé en compliment**. « Quelle constance, vraiment » loue en apparence une qualité (la régularité) mais vise en réalité la répétition d''une dérobade (« encore réussi à filer »). Henri doit reconnaître que le reproche porte sur la systématicité de ses fuites. Seule A « je m''éclipse systématiquement » identifie cela. B propose une **lecture naïve** qui prend le compliment au sérieux. C déplace **le grief sur le ton de l''autre**, hors propos. D **invoque une justification** (l''heure du travail), ce qui esquive la cible.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Sarcasme à reconnaître / professionnel / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000006', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] La direction a annoncé un nouveau plan de transformation.\n[Femme] Magnifique, le troisième en dix-huit mois, quel élan.\n[Homme] Tu as l''air positivement enthousiaste, dis-moi.\n[Femme] Comment ne pas l''être, devant tant de cohérence stratégique ?\n[Homme] Sérieusement, qu''est-ce que tu ressens, au fond ?\n[Femme] ...\n\nA. Une vraie reconnaissance pour le courage de la direction.\nB. Un découragement profond face à cette agitation perpétuelle.\nC. Une attente prudente avant de me prononcer définitivement.\nD. Un certain agacement contre la presse qui en parle.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La direction a annoncé un nouveau plan de transformation.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Magnifique, le troisième en dix-huit mois, quel élan.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air positivement enthousiaste, dis-moi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment ne pas l''être, devant tant de cohérence stratégique ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sérieusement, qu''est-ce que tu ressens, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une vraie reconnaissance pour le courage de la direction.<break time="700ms"/>B.<break time="300ms"/>Un découragement profond face à cette agitation perpétuelle.<break time="700ms"/>C.<break time="300ms"/>Une attente prudente avant de me prononcer définitivement.<break time="700ms"/>D.<break time="300ms"/>Un certain agacement contre la presse qui en parle.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **sarcasme**. L''accumulation « magnifique », « troisième en dix-huit mois », « tant de cohérence stratégique » avec le mot « stratégique » miné par la fréquence des plans, signale une amertume à peine voilée ; la question d''Henri demande le sentiment réel. Seule B « un découragement profond face à cette agitation perpétuelle » nomme ce sentiment. A propose **la lecture naïve** (vraie reconnaissance). C **adoucit en attentisme**, ce qui ne dit pas le sentiment réel. D **déplace la cible** vers la presse, ce qui n''est pas l''objet du sarcasme.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Allusion littéraire / culturel / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000007', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu disais que la posture de ce ministre te paraissait familière.\n[Homme] Oui, j''avais en tête une figure très précise, en l''écoutant.\n[Femme] Vraiment ?\n[Homme] Tartuffe, finalement, n''aurait pas mieux composé son visage.\n[Femme] À quoi tu fais allusion, au juste ?\n[Homme] ...\n\nA. À la longueur excessive de son intervention télévisée.\nB. À ses positions, qui ont varié au cours du dernier mois.\nC. À une hypocrisie soigneusement mise en scène par ses soins.\nD. À sa fébrilité visible lors de la séance de questions.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu disais que la posture de ce ministre te paraissait familière.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''avais en tête une figure très précise, en l''écoutant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vraiment ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tartuffe, finalement, n''aurait pas mieux composé son visage.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À quoi tu fais allusion, au juste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la longueur excessive de son intervention télévisée.<break time="700ms"/>B.<break time="300ms"/>À ses positions, qui ont varié au cours du dernier mois.<break time="700ms"/>C.<break time="300ms"/>À une hypocrisie soigneusement mise en scène par ses soins.<break time="700ms"/>D.<break time="300ms"/>À sa fébrilité visible lors de la séance de questions.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **allusion littéraire**. Tartuffe, archétype molièresque du faux dévot, désigne l''hypocrisie ostensible et étudiée ; « composer son visage » renforce l''image de la mascarade. Seule C « hypocrisie soigneusement mise en scène » décode la référence. A donne **un défaut de forme** (durée). B donne **un autre grief** (revirements), proche thématiquement mais distinct du procédé tartufien. D donne **un trait psychologique opposé** (fébrilité, alors que Tartuffe est maître de son visage). Lire « Tartuffe » seulement comme « personnage connu » sans en mobiliser le sens propre serait insuffisant.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Sous-entendu mondain / mondain / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000008', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as vu, on a placé Charlotte au bout de la table, près des enfants.\n[Homme] Tiens donc. Cela n''avait rien d''anodin, je présume.\n[Femme] Bien sûr que non. C''est un message en soi.\n[Homme] Et qu''est-ce qu''on a voulu lui signifier, au juste ?\n[Femme] ...\n\nA. Qu''elle s''entend particulièrement bien avec les plus jeunes.\nB. Qu''on souhaitait, par cette place, alléger le service à table.\nC. Qu''elle aurait préféré, à l''évidence, dîner ailleurs ce soir-là.\nD. Qu''elle n''est plus considérée comme tout à fait des nôtres.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as vu, on a placé Charlotte au bout de la table, près des enfants.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tiens donc. Cela n''avait rien d''anodin, je présume.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bien sûr que non. C''est un message en soi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''est-ce qu''on a voulu lui signifier, au juste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''elle s''entend particulièrement bien avec les plus jeunes.<break time="700ms"/>B.<break time="300ms"/>Qu''on souhaitait, par cette place, alléger le service à table.<break time="700ms"/>C.<break time="300ms"/>Qu''elle aurait préféré, à l''évidence, dîner ailleurs ce soir-là.<break time="700ms"/>D.<break time="300ms"/>Qu''elle n''est plus considérée comme tout à fait des nôtres.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **sous-entendu mondain (placement à table)**. Le « bout de la table, près des enfants » est, dans le code mondain, une marque symbolique de relégation ; Denise valide explicitement (« message en soi »). Seule D « plus considérée comme tout à fait des nôtres » dit la mise à distance signifiée. A propose **une lecture bienveillante** (affinité avec les enfants). B propose **une justification logistique**, qui nie le caractère intentionnel. C **déplace la question** sur le ressenti de Charlotte plutôt que sur le message envoyé.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Mépris voilé sous la politesse / professionnel / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000009', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Comment tu as trouvé l''intervention de notre confrère Dupuis ?\n[Femme] C''est, à n''en pas douter, un esprit méritant.\n[Homme] Méritant ? Le qualificatif est délicieusement choisi.\n[Femme] Disons que je salue son sérieux, à défaut d''autre chose.\n[Homme] Quel mépris perce sous tant de courtoisie ?\n[Femme] ...\n\nA. Que je le tiens, en somme, pour un esprit bien laborieux.\nB. Que je l''estime, finalement, plus que je ne le laisse paraître.\nC. Que je lui reconnais des qualités humaines indéniables.\nD. Que je le trouve très investi, mais un peu inexpérimenté.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment tu as trouvé l''intervention de notre confrère Dupuis ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est, à n''en pas douter, un esprit méritant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Méritant ? Le qualificatif est délicieusement choisi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Disons que je salue son sérieux, à défaut d''autre chose.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel mépris perce sous tant de courtoisie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que je le tiens, en somme, pour un esprit bien laborieux.<break time="700ms"/>B.<break time="300ms"/>Que je l''estime, finalement, plus que je ne le laisse paraître.<break time="700ms"/>C.<break time="300ms"/>Que je lui reconnais des qualités humaines indéniables.<break time="700ms"/>D.<break time="300ms"/>Que je le trouve très investi, mais un peu inexpérimenté.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **mépris voilé sous la politesse**. « Méritant », « sérieux à défaut d''autre chose » signalent une condescendance qui salue la peine mais nie le talent ; Henri demande explicitement ce que la politesse dissimule. Seule A « un esprit bien laborieux » nomme ce mépris à peine voilé. B propose **la lecture inverse** (estime cachée). C **prend la politesse pour argent comptant**. D **adoucit en concession bienveillante** (« investi mais inexpérimenté »), ce qui n''est pas du mépris.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Ironie sur soi-même / personnel / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000a', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as encore reporté ton projet de roman, à ce que je vois.\n[Homme] Oui, je peaufine ma procrastination jusqu''à un art véritable.\n[Femme] Élégante manière de te flageller, dis-moi.\n[Homme] Je me console comme je peux de ma propre paresse.\n[Femme] Au fond, comment te moques-tu de toi-même, là ?\n[Homme] ...\n\nA. Je trouve, malgré tout, mon courage assez remarquable.\nB. Je transforme un défaut bien réel en posture d''esthète.\nC. Je dénonce avant tout la pression sociale qui pèse sur moi.\nD. Je rends hommage à mes éditeurs, qui demeurent patients.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as encore reporté ton projet de roman, à ce que je vois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je peaufine ma procrastination jusqu''à un art véritable.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Élégante manière de te flageller, dis-moi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je me console comme je peux de ma propre paresse.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Au fond, comment te moques-tu de toi-même, là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Je trouve, malgré tout, mon courage assez remarquable.<break time="700ms"/>B.<break time="300ms"/>Je transforme un défaut bien réel en posture d''esthète.<break time="700ms"/>C.<break time="300ms"/>Je dénonce avant tout la pression sociale qui pèse sur moi.<break time="700ms"/>D.<break time="300ms"/>Je rends hommage à mes éditeurs, qui demeurent patients.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **auto-ironie**. « Je peaufine ma procrastination jusqu''à un art véritable » est une **hyperbole** qui esthétise un défaut (la paresse, reconnue au tour suivant). Seule B « je transforme un défaut bien réel en posture d''esthète » nomme exactement ce procédé d''auto-dénigrement valorisant. A propose **un éloge littéral** de soi, contradiction directe. C **déplace la critique sur autrui** (pression sociale). D introduit **un tiers** (les éditeurs) hors champ.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Concession ironique / politique / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000b', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu vas reconnaître que la réforme avance, tout de même.\n[Homme] Oh, je veux bien lui accorder le mérite d''exister, à défaut d''agir.\n[Femme] Voilà une concession à double tranchant, je trouve.\n[Homme] Disons que je consens à l''évidence, et rien de plus.\n[Femme] Qu''est-ce que tu concèdes vraiment, alors ?\n[Homme] ...\n\nA. Que cette réforme produira, à terme, des effets bénéfiques.\nB. Que ses promoteurs ont déployé une énergie remarquable.\nC. Strictement rien, sinon le fait qu''un texte ait été publié.\nD. Que le calendrier de mise en œuvre est globalement tenu.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vas reconnaître que la réforme avance, tout de même.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oh, je veux bien lui accorder le mérite d''exister, à défaut d''agir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Voilà une concession à double tranchant, je trouve.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Disons que je consens à l''évidence, et rien de plus.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce que tu concèdes vraiment, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que cette réforme produira, à terme, des effets bénéfiques.<break time="700ms"/>B.<break time="300ms"/>Que ses promoteurs ont déployé une énergie remarquable.<break time="700ms"/>C.<break time="300ms"/>Strictement rien, sinon le fait qu''un texte ait été publié.<break time="700ms"/>D.<break time="300ms"/>Que le calendrier de mise en œuvre est globalement tenu.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **concession ironique**. « Le mérite d''exister, à défaut d''agir » et « consens à l''évidence, et rien de plus » sont des concessions minimales qui vident la concession de toute substance ; Denise demande la teneur réelle. Seule C « strictement rien, sinon le fait qu''un texte ait été publié » dit la concession vide. A, B, D proposent **des concessions substantielles** (efficacité, énergie, calendrier), qui prennent la concession au pied de la lettre, alors qu''Henri refuse précisément d''accorder plus que l''existence du texte.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Décalage de registre / professionnel / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000c', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Comment s''est terminée ta réunion avec le comité d''éthique ?\n[Homme] On a essayé de leur ressortir le même baratin, et puis bon, ça a foiré.\n[Femme] Tu changes brutalement de registre, c''est frappant.\n[Homme] Disons que la situation appelait quelques mots crus.\n[Femme] Qu''est-ce qui détonne dans ton ton, à ton avis ?\n[Homme] ...\n\nA. Un vocabulaire technique inhabituellement précis pour le sujet.\nB. Une politesse glaciale qui trahit ma profonde colère intérieure.\nC. Un ton martial inattendu, vu mon caractère ordinaire.\nD. Un argot soudain dans un cadre que d''ordinaire je tiens feutré.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment s''est terminée ta réunion avec le comité d''éthique ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a essayé de leur ressortir le même baratin, et puis bon, ça a foiré.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu changes brutalement de registre, c''est frappant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Disons que la situation appelait quelques mots crus.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui détonne dans ton ton, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un vocabulaire technique inhabituellement précis pour le sujet.<break time="700ms"/>B.<break time="300ms"/>Une politesse glaciale qui trahit ma profonde colère intérieure.<break time="700ms"/>C.<break time="300ms"/>Un ton martial inattendu, vu mon caractère ordinaire.<break time="700ms"/>D.<break time="300ms"/>Un argot soudain dans un cadre que d''ordinaire je tiens feutré.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **décalage de registre**. « Baratin » et « ça a foiré » sont des termes familiers, presque argotiques, surgis dans un contexte feutré (comité d''éthique) ; Denise pointe explicitement le décalage. Seule D « un argot soudain dans un cadre feutré » nomme exactement ce décalage. A désigne **un autre registre opposé** (technique précis), pas du tout celui employé. B nomme **un registre opposé** (politesse glaciale). C nomme **un registre martial**, étranger au lexique entendu. La lecture première — juger le contenu seul — manquerait l''écart de niveau de langue qui fait le sel du tour.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Hommage déguisé sous la critique / culturel / 4 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000d', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu n''as pas été tendre avec le dernier film d''Anaïs Mercier.\n[Femme] Je lui reproche surtout d''être devenue insupportablement exigeante.\n[Homme] Voilà un reproche qui ressemble fort à un compliment.\n[Femme] Disons que personne ne se donne autant de mal pour me décevoir.\n[Homme] Quel hommage perce, en réalité, sous ta critique ?\n[Femme] ...\n\nA. Qu''elle place la barre si haut que toute baisse paraît un drame.\nB. Que ses films, désormais, ne valent plus la peine d''être vus.\nC. Qu''elle s''est égarée dans des sujets trop personnels pour elle.\nD. Que la critique a, dans l''ensemble, été bien trop indulgente.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu n''as pas été tendre avec le dernier film d''Anaïs Mercier.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je lui reproche surtout d''être devenue insupportablement exigeante.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Voilà un reproche qui ressemble fort à un compliment.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Disons que personne ne se donne autant de mal pour me décevoir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel hommage perce, en réalité, sous ta critique ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''elle place la barre si haut que toute baisse paraît un drame.<break time="700ms"/>B.<break time="300ms"/>Que ses films, désormais, ne valent plus la peine d''être vus.<break time="700ms"/>C.<break time="300ms"/>Qu''elle s''est égarée dans des sujets trop personnels pour elle.<break time="700ms"/>D.<break time="300ms"/>Que la critique a, dans l''ensemble, été bien trop indulgente.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **hommage déguisé en critique**. « Insupportablement exigeante » et « personne ne se donne autant de mal pour me décevoir » sont des reproches dont la forme suppose une attente d''excellence ; Henri explicite l''hommage caché. Seule A « elle place la barre si haut que toute baisse paraît un drame » formule l''éloge contenu dans le reproche. B propose **une critique pleine** (sans hommage). C donne **un autre grief artistique**. D **déplace la critique** sur les autres critiques.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Compliment empoisonné / mondain / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000e', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as croisé Béatrice, hier ? Comment l''as-tu trouvée ?\n[Homme] Elle est, pour son âge, étonnamment bien conservée.\n[Femme] Tiens, voilà un compliment qui pique un peu.\n[Homme] J''ai voulu être aimable, je crois avoir réussi.\n[Femme] Sois honnête : qu''est-ce qui est venimeux, là-dedans ?\n[Homme] ...\n\nA. Le fait d''avoir préféré la croiser plutôt que de l''appeler.\nB. La précision « pour son âge », qui aigrit tout l''éloge.\nC. Le verbe « trouver », un peu trop évaluateur pour la circonstance.\nD. Le tour passif « bien conservée », vaguement médical et neutre.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as croisé Béatrice, hier ? Comment l''as-tu trouvée ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Elle est, pour son âge, étonnamment bien conservée.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tiens, voilà un compliment qui pique un peu.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai voulu être aimable, je crois avoir réussi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sois honnête : qu''est-ce qui est venimeux, là-dedans ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le fait d''avoir préféré la croiser plutôt que de l''appeler.<break time="700ms"/>B.<break time="300ms"/>La précision « pour son âge », qui aigrit tout l''éloge.<break time="700ms"/>C.<break time="300ms"/>Le verbe « trouver », un peu trop évaluateur pour la circonstance.<break time="700ms"/>D.<break time="300ms"/>Le tour passif « bien conservée », vaguement médical et neutre.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **compliment empoisonné**. La restriction « pour son âge » introduit une comparaison défavorable implicite qui retire la portée à « étonnamment bien conservée » ; Denise pointe ce qui « pique ». Seule B nomme la clause restrictive comme foyer du venin. A déplace **sur un autre grief** (préférer croiser plutôt qu''appeler). C **incrimine un autre mot** (« trouver »), qui n''est pas le poison. D **désamorce** en présentant « bien conservée » comme « neutre », ce qui passe à côté du venin réel logé dans la restriction.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Question rhétorique / politique / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-00000000000f', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu crois vraiment que ce gouvernement va tenir jusqu''aux élections ?\n[Femme] A-t-on jamais vu une majorité aussi friable durer six mois ?\n[Homme] Ce n''est pas tout à fait une réponse, ça.\n[Femme] Le passé récent fournit, je crois, tous les éléments de réponse.\n[Homme] Quelle est, en clair, la vraie affirmation derrière ta question ?\n[Femme] ...\n\nA. Que tu sous-estimes la résilience des coalitions improvisées.\nB. Que beaucoup d''observateurs se trompent depuis quelques mois.\nC. Qu''aucune coalition aussi fragile n''a jamais tenu jusqu''au terme.\nD. Que ce gouvernement traverse une zone de turbulences passagère.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu crois vraiment que ce gouvernement va tenir jusqu''aux élections ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">A-t-on jamais vu une majorité aussi friable durer six mois ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ce n''est pas tout à fait une réponse, ça.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le passé récent fournit, je crois, tous les éléments de réponse.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle est, en clair, la vraie affirmation derrière ta question ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que tu sous-estimes la résilience des coalitions improvisées.<break time="700ms"/>B.<break time="300ms"/>Que beaucoup d''observateurs se trompent depuis quelques mois.<break time="700ms"/>C.<break time="300ms"/>Qu''aucune coalition aussi fragile n''a jamais tenu jusqu''au terme.<break time="700ms"/>D.<break time="300ms"/>Que ce gouvernement traverse une zone de turbulences passagère.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **question rhétorique**. « A-t-on jamais vu une majorité aussi friable durer six mois ? » attend la réponse « non » ; c''est donc une affirmation négative déguisée. Seule C « aucune coalition aussi fragile n''a jamais tenu jusqu''au terme » formule cette affirmation. A **renverse la perspective** (sur Henri). B **déplace la critique** sur d''autres observateurs. D propose **la lecture inverse** (gouvernement durable), qui contredit la question rhétorique.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Euphémisme à percer / professionnel / 4 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000010', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] On m''a annoncé ce matin un « repositionnement stratégique » de mon poste.\n[Homme] Ouh là. Ce sont des mots à manipuler avec précaution.\n[Femme] Le directeur a évoqué un « ajustement de périmètre temporaire ».\n[Homme] Voilà des formulations toutes prêtes à amortir un choc.\n[Femme] À ton avis, qu''est-ce que tout ce vocabulaire adoucit, vraiment ?\n[Homme] ...\n\nA. Une promotion latérale, somme toute assez flatteuse pour toi.\nB. Un simple changement de bureau, plus proche de la direction.\nC. Une réorganisation neutre, dictée par l''évolution des marchés.\nD. Un placard discret, où l''on te laisse sans réelle mission claire.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On m''a annoncé ce matin un « repositionnement stratégique » de mon poste.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ouh là. Ce sont des mots à manipuler avec précaution.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le directeur a évoqué un « ajustement de périmètre temporaire ».</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Voilà des formulations toutes prêtes à amortir un choc.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À ton avis, qu''est-ce que tout ce vocabulaire adoucit, vraiment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une promotion latérale, somme toute assez flatteuse pour toi.<break time="700ms"/>B.<break time="300ms"/>Un simple changement de bureau, plus proche de la direction.<break time="700ms"/>C.<break time="300ms"/>Une réorganisation neutre, dictée par l''évolution des marchés.<break time="700ms"/>D.<break time="300ms"/>Un placard discret, où l''on te laisse sans réelle mission claire.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **euphémisme à percer**. « Repositionnement stratégique » et « ajustement de périmètre temporaire » sont des formules feutrées du jargon RH qui adoucissent une mise à l''écart ; Henri en signale le caractère amortisseur. Seule D « un placard discret » nomme la réalité brute. A, B, C proposent **trois lectures littérales / bienveillantes** (promotion, changement anodin, contexte de marché) qui prennent l''euphémisme pour vérité au lieu de le percer.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Tonalité élégiaque / personnel / 5 tours / bonne réponse A -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000011', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu es retournée dans ton village d''enfance, finalement.\n[Femme] Oui, après tant d''années.\n[Homme] Tu m''en parles d''une voix curieuse, presque retenue.\n[Femme] Les pierres sont restées, mais ceux qui les habitaient s''en sont allés.\n[Homme] Quelle tonalité, exactement, traverse ce que tu me racontes ?\n[Femme] ...\n\nA. Une douceur mélancolique pour un monde irrémédiablement disparu.\nB. Une exaspération nette devant l''abandon du patrimoine local.\nC. Une joie franche d''avoir retrouvé un cadre intact, finalement.\nD. Une indifférence cultivée envers un lieu qui ne me dit plus rien.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu es retournée dans ton village d''enfance, finalement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, après tant d''années.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''en parles d''une voix curieuse, presque retenue.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Les pierres sont restées, mais ceux qui les habitaient s''en sont allés.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle tonalité, exactement, traverse ce que tu me racontes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une douceur mélancolique pour un monde irrémédiablement disparu.<break time="700ms"/>B.<break time="300ms"/>Une exaspération nette devant l''abandon du patrimoine local.<break time="700ms"/>C.<break time="300ms"/>Une joie franche d''avoir retrouvé un cadre intact, finalement.<break time="700ms"/>D.<break time="300ms"/>Une indifférence cultivée envers un lieu qui ne me dit plus rien.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **tonalité élégiaque**. La phrase « les pierres sont restées, mais ceux qui les habitaient s''en sont allés » oppose la permanence du décor à la disparition des êtres : c''est la structure typique de l''élégie, doux regret de ce qui n''est plus. Seule A « douceur mélancolique pour un monde disparu » nomme cette tonalité. B propose **la colère** (registre étranger à l''élégie). C propose **la joie**, contredite par « s''en sont allés ». D propose **l''indifférence**, contredite par la voix « retenue » et l''attention au détail.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Implicite de classe / mondain / 4 tours / bonne réponse B -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000012', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu sais que ma fille fréquente désormais ce jeune Hugo, dont nous parlions.\n[Homme] Ah, le fils Berger. Un garçon, m''a-t-on dit, plein d''avenir.\n[Femme] Plein d''avenir, certes, mais issu d''un milieu si différent du nôtre.\n[Homme] Quel implicite sur leur écart de monde tu glisses, là ?\n[Femme] ...\n\nA. Qu''il finira par s''adapter sans trop de difficultés à nos usages.\nB. Qu''il n''est pas vraiment des nôtres, et que cela finira par peser.\nC. Qu''il est, malgré tout, un parti tout à fait recommandable pour elle.\nD. Qu''il vient d''une famille modeste, mais courageuse et estimable.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais que ma fille fréquente désormais ce jeune Hugo, dont nous parlions.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ah, le fils Berger. Un garçon, m''a-t-on dit, plein d''avenir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Plein d''avenir, certes, mais issu d''un milieu si différent du nôtre.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel implicite sur leur écart de monde tu glisses, là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''il finira par s''adapter sans trop de difficultés à nos usages.<break time="700ms"/>B.<break time="300ms"/>Qu''il n''est pas vraiment des nôtres, et que cela finira par peser.<break time="700ms"/>C.<break time="300ms"/>Qu''il est, malgré tout, un parti tout à fait recommandable pour elle.<break time="700ms"/>D.<break time="300ms"/>Qu''il vient d''une famille modeste, mais courageuse et estimable.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **implicite de classe**. « Issu d''un milieu si différent du nôtre » est une formulation feutrée typique du discours mondain, qui pose une frontière de classe ; le « certes / mais » marque l''opposition entre l''éloge concédé et la réserve réelle. Seule B « il n''est pas vraiment des nôtres, et cela finira par peser » dit le pronostic implicite. A propose **un optimisme intégrateur** que la mère ne formule pas. C propose **un éloge net**, contredit par la concessive. D **adoucit** en éloge moral, sans nommer la distance de classe.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Périphrase à décoder / politique / 4 tours / bonne réponse C -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000013', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le dernier livre d''entretiens a fait jaser, dans les ministères.\n[Homme] Tu veux parler de celui où l''on évoque « l''ancien locataire de l''hôtel Matignon » ?\n[Femme] C''est bien ce volume-là.\n[Homme] Cette périphrase a, paraît-il, beaucoup amusé son destinataire.\n[Femme] Qui désigne au juste, en clair, cette belle périphrase ?\n[Homme] ...\n\nA. Le président de la République actuellement en exercice.\nB. Le ministre des Affaires étrangères du gouvernement précédent.\nC. Un ancien Premier ministre français récemment quitté de ses fonctions.\nD. Le porte-parole habituel du gouvernement encore en place aujourd''hui.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le dernier livre d''entretiens a fait jaser, dans les ministères.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu veux parler de celui où l''on évoque « l''ancien locataire de l''hôtel Matignon » ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est bien ce volume-là.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cette périphrase a, paraît-il, beaucoup amusé son destinataire.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qui désigne au juste, en clair, cette belle périphrase ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le président de la République actuellement en exercice.<break time="700ms"/>B.<break time="300ms"/>Le ministre des Affaires étrangères du gouvernement précédent.<break time="700ms"/>C.<break time="300ms"/>Un ancien Premier ministre français récemment quitté de ses fonctions.<break time="700ms"/>D.<break time="300ms"/>Le porte-parole habituel du gouvernement encore en place aujourd''hui.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **périphrase**. L''hôtel Matignon est la résidence officielle du Premier ministre français ; « ancien locataire » indique qu''il en est sorti. La combinaison désigne donc un ex-chef du gouvernement. Seule C « ancien Premier ministre récemment quitté de ses fonctions » décode correctement la périphrase. A confond Matignon (Premier ministre) avec **l''Élysée** (président). B désigne **un autre membre du gouvernement**. D désigne **une fonction qui ne loge pas à Matignon**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Posture rhétorique adoptée / professionnel / 5 tours / bonne réponse D -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00c2-1000-0000-000000000014', 'B2', 'co_dialogue_c2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu n''as cessé, hier, de répéter « moi, simple praticien, je m''en tiens aux faits ».\n[Homme] J''ai voulu ramener le débat à la mesure.\n[Femme] Mesure ou pose ? Tu maniais tes formules avec un certain art.\n[Homme] On peut être à la fois lucide sur sa rhétorique et sincère, je crois.\n[Femme] Quelle posture cherchais-tu, au juste, à incarner devant eux ?\n[Homme] ...\n\nA. Celle d''un orateur brillant, capable de tenir tête aux théoriciens.\nB. Celle d''un débatteur agressif, prêt à pousser ses contradicteurs.\nC. Celle d''un savant abstrait, soucieux de hauteur conceptuelle.\nD. Celle de l''homme de terrain modeste, refusant les grandes théories.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu n''as cessé, hier, de répéter « moi, simple praticien, je m''en tiens aux faits ».</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai voulu ramener le débat à la mesure.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mesure ou pose ? Tu maniais tes formules avec un certain art.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On peut être à la fois lucide sur sa rhétorique et sincère, je crois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle posture cherchais-tu, au juste, à incarner devant eux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Celle d''un orateur brillant, capable de tenir tête aux théoriciens.<break time="700ms"/>B.<break time="300ms"/>Celle d''un débatteur agressif, prêt à pousser ses contradicteurs.<break time="700ms"/>C.<break time="300ms"/>Celle d''un savant abstrait, soucieux de hauteur conceptuelle.<break time="700ms"/>D.<break time="300ms"/>Celle de l''homme de terrain modeste, refusant les grandes théories.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'Procédé : **posture rhétorique**. « Simple praticien », « je m''en tiens aux faits », « ramener à la mesure » construisent une figure d''humilité revendiquée qui s''oppose à la spéculation intellectuelle ; Denise relève l''art du procédé. Seule D « l''homme de terrain modeste, refusant les grandes théories » nomme cette posture. A propose **la posture inverse** (orateur brillant). B propose **une posture agressive**, démentie par « ramener à la mesure ». C propose **la posture spéculative**, précisément celle que Henri rejette.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
