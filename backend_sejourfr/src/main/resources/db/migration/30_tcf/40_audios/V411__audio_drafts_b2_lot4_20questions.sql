-- ============================================================
-- 20 exercices B2 (lot 4) - CO TCF - format "réponse à question implicite"
-- Dialogues de 3 tours (alternance Henri / Denise),
-- formulations indirectes / soutenues, 20 types de question
-- implicite distincts de V402 / V403 / V410.
-- Labels A/B/C/D : contenu des propositions lu dans l'audio.
-- Position de la bonne réponse équilibrée : 5×A, 5×B, 5×C, 5×D.
-- Voix : 10 Henri / 10 Denise sur voice_recommended.
-- ============================================================

-- ----- Exercice 1 : Hypothèse explicative (« qu'est-ce qui expliquerait ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu sais que les ventes ont chuté de quinze pour cent ce mois-ci ?\n[Homme] Oui, c''est préoccupant.\n[Femme] Qu''est-ce qui expliquerait ce recul, à ton avis ?\n[Homme] ...\n\nA. L''arrivée brutale d''un concurrent agressif sur le marché.\nB. Pendant trois semaines consécutives, surtout.\nC. Avec une baisse plus marquée chez les indépendants.\nD. Pour relancer notre stratégie de marque ensuite.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais que les ventes ont chuté de quinze pour cent ce mois-ci ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est préoccupant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui expliquerait ce recul, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''arrivée brutale d''un concurrent agressif sur le marché.<break time="700ms"/>B.<break time="300ms"/>Pendant trois semaines consécutives, surtout.<break time="700ms"/>C.<break time="300ms"/>Avec une baisse plus marquée chez les indépendants.<break time="700ms"/>D.<break time="300ms"/>Pour relancer notre stratégie de marque ensuite.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui expliquerait ce recul ? » appelle **une hypothèse explicative, une cause vraisemblable**. Seule A « l''arrivée d''un concurrent agressif » formule une hypothèse causale. B donne la **période** du recul. C donne **le segment le plus touché**. D donne **une action future** (« pour relancer » = but post-constat), pas une explication.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 2 : Marge de manœuvre (« quelle marge ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu vas devoir négocier avec ton fournisseur principal ?\n[Femme] Oui, lundi matin sans faute.\n[Homme] Quelle marge de manœuvre tu te donnes, exactement ?\n[Femme] ...\n\nA. Au bout de deux mois de tensions accumulées.\nB. Une réduction de cinq à huit pour cent, pas davantage.\nC. Pour préserver notre relation à long terme.\nD. Avec mon directeur financier en soutien.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu vas devoir négocier avec ton fournisseur principal ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, lundi matin sans faute.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle marge de manœuvre tu te donnes, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de deux mois de tensions accumulées.<break time="700ms"/>B.<break time="300ms"/>Une réduction de cinq à huit pour cent, pas davantage.<break time="700ms"/>C.<break time="300ms"/>Pour préserver notre relation à long terme.<break time="700ms"/>D.<break time="300ms"/>Avec mon directeur financier en soutien.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle marge de manœuvre tu te donnes ? » porte sur **les bornes chiffrées / l''amplitude de négociation envisagée**. Seule B « une réduction de cinq à huit pour cent » donne cette marge. A donne **le contexte temporel préalable**. C donne **le but supérieur** de la négociation. D donne **l''accompagnement**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 3 : Levier d'action (« sur quoi peux-tu agir ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Notre taux de désabonnement augmente régulièrement.\n[Homme] C''est inquiétant pour le trimestre.\n[Femme] Et concrètement, sur quoi peux-tu agir en priorité ?\n[Homme] ...\n\nA. À cause d''une concurrence devenue plus agressive.\nB. Auprès de la direction commerciale uniquement.\nC. Sur l''expérience d''onboarding, principalement.\nD. Pour ramener le taux sous les cinq pour cent.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Notre taux de désabonnement augmente régulièrement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est inquiétant pour le trimestre.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et concrètement, sur quoi peux-tu agir en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une concurrence devenue plus agressive.<break time="700ms"/>B.<break time="300ms"/>Auprès de la direction commerciale uniquement.<break time="700ms"/>C.<break time="300ms"/>Sur l''expérience d''onboarding, principalement.<break time="700ms"/>D.<break time="300ms"/>Pour ramener le taux sous les cinq pour cent.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Sur quoi peux-tu agir en priorité ? » porte sur **le levier opérationnel mobilisable**. Seule C « sur l''expérience d''onboarding » désigne un levier concret. A donne **la cause du problème**. B donne **les interlocuteurs / les acteurs auprès desquels agir** (« auprès de qui ? »). D donne **l''objectif chiffré visé**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 4 : Indice révélateur (« qu'est-ce qui te fait penser ça ? ») / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Je crois que Sophie ne se sent pas à l''aise dans son nouveau poste.\n[Femme] Vraiment ? Elle n''en a pourtant rien dit.\n[Homme] Justement. Qu''est-ce qui te fait penser ça, alors ?\n[Femme] ...\n\nA. Au bout d''un mois et demi de prise de fonction.\nB. Pour pouvoir l''aider à se réorienter, peut-être.\nC. Avec son ancien chef, qui me l''a confié récemment.\nD. Une fatigue inhabituelle et des silences répétés.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je crois que Sophie ne se sent pas à l''aise dans son nouveau poste.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vraiment ? Elle n''en a pourtant rien dit.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement. Qu''est-ce qui te fait penser ça, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout d''un mois et demi de prise de fonction.<break time="700ms"/>B.<break time="300ms"/>Pour pouvoir l''aider à se réorienter, peut-être.<break time="700ms"/>C.<break time="300ms"/>Avec son ancien chef, qui me l''a confié récemment.<break time="700ms"/>D.<break time="300ms"/>Une fatigue inhabituelle et des silences répétés.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui te fait penser ça ? » porte sur **les indices observés qui fondent l''intuition**. Seule D « une fatigue inhabituelle et des silences répétés » liste ces indices. A donne **la durée écoulée dans le poste**. B donne **le but** de l''interrogation. C donne **la source d''une information rapportée** — piège B2 fin : C est une source possible (le « par qui je le sais »), mais la question demande les indices propres, pas l''origine d''une rumeur.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 5 : Argument décisif (« quel argument t'a convaincu ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fini par accepter de passer au télétravail intégral ?\n[Homme] Oui, après bien des hésitations.\n[Femme] Quel argument t''a finalement convaincu ?\n[Homme] ...\n\nA. La perspective de récupérer deux heures de trajet par jour.\nB. Pour une période d''essai de six mois seulement.\nC. À condition de garder un bureau partagé en backup.\nD. Avec l''accord express de mon manager direct.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par accepter de passer au télétravail intégral ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après bien des hésitations.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel argument t''a finalement convaincu ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La perspective de récupérer deux heures de trajet par jour.<break time="700ms"/>B.<break time="300ms"/>Pour une période d''essai de six mois seulement.<break time="700ms"/>C.<break time="300ms"/>À condition de garder un bureau partagé en backup.<break time="700ms"/>D.<break time="300ms"/>Avec l''accord express de mon manager direct.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel argument t''a convaincu ? » porte sur **le bénéfice perçu qui a emporté la décision**. Seule A « la perspective de récupérer deux heures de trajet » désigne cet argument. B donne **la durée d''essai** (modalité, pas argument). C donne **une condition d''acceptation** (« sous quelles réserves ? »). D donne **une validation hiérarchique** (« qui a dû dire oui ? »).',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 6 : Manque ressenti (« qu'est-ce qui te manque ? ») / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu vis seule dans cette nouvelle ville, je crois.\n[Femme] Oui, depuis presque six mois maintenant.\n[Homme] Qu''est-ce qui te manque le plus, finalement ?\n[Femme] ...\n\nA. À cause d''une mutation un peu brutale.\nB. Les longues soirées partagées avec mes vieux amis.\nC. Pour me rapprocher d''un projet professionnel.\nD. Avec mes parents qui sont restés à Lyon.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu vis seule dans cette nouvelle ville, je crois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, depuis presque six mois maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui te manque le plus, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une mutation un peu brutale.<break time="700ms"/>B.<break time="300ms"/>Les longues soirées partagées avec mes vieux amis.<break time="700ms"/>C.<break time="300ms"/>Pour me rapprocher d''un projet professionnel.<break time="700ms"/>D.<break time="300ms"/>Avec mes parents qui sont restés à Lyon.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui te manque le plus ? » porte sur **l''objet du manque, ce qui fait défaut au quotidien**. Seule B « les longues soirées partagées avec mes vieux amis » nomme ce manque. A donne **la cause du déménagement**. C donne **le but** du changement. D donne **les proches restés en arrière** — piège B2 : D évoque la famille éloignée, donc thématiquement proche du manque, mais ne nomme pas un manque vécu actuellement.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 7 : Atout principal (« quel est ton atout ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu vas postuler à ce poste de directrice d''agence ?\n[Homme] Oui, c''est une opportunité rare.\n[Femme] Et selon toi, quel est ton principal atout face aux autres candidats ?\n[Homme] ...\n\nA. Pendant les six prochaines semaines d''évaluation.\nB. Auprès d''un jury composé exclusivement de cadres seniors.\nC. Une expérience de terrain peu commune dans ce secteur.\nD. À l''approche d''un changement complet de carrière.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vas postuler à ce poste de directrice d''agence ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est une opportunité rare.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et selon toi, quel est ton principal atout face aux autres candidats ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les six prochaines semaines d''évaluation.<break time="700ms"/>B.<break time="300ms"/>Auprès d''un jury composé exclusivement de cadres seniors.<break time="700ms"/>C.<break time="300ms"/>Une expérience de terrain peu commune dans ce secteur.<break time="700ms"/>D.<break time="300ms"/>À l''approche d''un changement complet de carrière.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel est ton principal atout ? » porte sur **la qualité différenciante valorisée**. Seule C « une expérience de terrain peu commune » nomme un atout. A donne **la période d''évaluation**. B donne **les évaluateurs**. D donne **le contexte personnel** de la candidature.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 8 : Faiblesse identifiée (« quelle faiblesse ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as fait ton bilan de mi-année avec ton manager ?\n[Femme] Oui, ce matin, c''était plutôt constructif.\n[Homme] Quelle faiblesse il a identifiée chez toi, principalement ?\n[Femme] ...\n\nA. Au cours d''un entretien d''une heure et demie.\nB. Pour viser une promotion à plus long terme.\nC. Avec beaucoup de bienveillance, je dois dire.\nD. Un manque de leadership dans les réunions élargies.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as fait ton bilan de mi-année avec ton manager ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ce matin, c''était plutôt constructif.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle faiblesse il a identifiée chez toi, principalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cours d''un entretien d''une heure et demie.<break time="700ms"/>B.<break time="300ms"/>Pour viser une promotion à plus long terme.<break time="700ms"/>C.<break time="300ms"/>Avec beaucoup de bienveillance, je dois dire.<break time="700ms"/>D.<break time="300ms"/>Un manque de leadership dans les réunions élargies.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quelle faiblesse a-t-il identifiée ? » porte sur **le point faible précis pointé du doigt**. Seule D « un manque de leadership dans les réunions élargies » nomme cette faiblesse. A donne **la durée de l''entretien**. B donne **l''objectif** du bilan. C donne **la manière** dont la critique a été formulée.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 9 : Évolution prévisible (« comment cela va-t-il évoluer ? ») / sectoriel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Le marché du livre numérique stagne, m''as-tu dit ?\n[Homme] Oui, depuis deux ans environ.\n[Femme] Comment cela va-t-il évoluer, selon les analystes ?\n[Homme] ...\n\nA. Une lente reprise tirée par les abonnements illimités.\nB. À cause d''une saturation progressive du marché.\nC. Pour relancer la lecture chez les jeunes adultes.\nD. Auprès des éditeurs indépendants surtout.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le marché du livre numérique stagne, m''as-tu dit ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, depuis deux ans environ.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment cela va-t-il évoluer, selon les analystes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une lente reprise tirée par les abonnements illimités.<break time="700ms"/>B.<break time="300ms"/>À cause d''une saturation progressive du marché.<break time="700ms"/>C.<break time="300ms"/>Pour relancer la lecture chez les jeunes adultes.<break time="700ms"/>D.<break time="300ms"/>Auprès des éditeurs indépendants surtout.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Comment cela va-t-il évoluer ? » appelle **une projection / tendance future**. Seule A « une lente reprise tirée par les abonnements illimités » décrit cette évolution. B donne **la cause de la stagnation actuelle**. C donne **un but de relance**. D donne **un segment d''acteurs concernés**.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 10 : Acteur clé (« qui a joué le rôle clé ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez réussi à boucler ce dossier complexe ?\n[Femme] Oui, mais ça n''a pas été sans mal.\n[Homme] Qui a joué le rôle clé dans la résolution, finalement ?\n[Femme] ...\n\nA. Au bout de trois mois de négociations difficiles.\nB. Notre juriste interne, vraiment décisive.\nC. Pour éviter un contentieux long et coûteux.\nD. Avec un budget largement dépassé, malheureusement.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez réussi à boucler ce dossier complexe ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, mais ça n''a pas été sans mal.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui a joué le rôle clé dans la résolution, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de trois mois de négociations difficiles.<break time="700ms"/>B.<break time="300ms"/>Notre juriste interne, vraiment décisive.<break time="700ms"/>C.<break time="300ms"/>Pour éviter un contentieux long et coûteux.<break time="700ms"/>D.<break time="300ms"/>Avec un budget largement dépassé, malheureusement.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qui a joué le rôle clé ? » porte sur **l''acteur décisif**. Seule B « notre juriste interne » désigne cette personne. A donne **la durée du processus**. C donne **le but / l''enjeu évité**. D donne **une conséquence budgétaire**.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 11 : Tournant biographique (« quel tournant ? ») / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que ta vie professionnelle avait basculé un jour précis.\n[Homme] Oui, c''est lié à une rencontre, en fait.\n[Femme] Quel a été ce tournant, exactement ?\n[Homme] ...\n\nA. À cause d''une frustration accumulée depuis longtemps.\nB. Pour mieux concilier vie pro et vie privée, finalement.\nC. Une proposition de mission à l''étranger, totalement inattendue.\nD. Avec mon ancienne associée, dont je me suis séparée.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que ta vie professionnelle avait basculé un jour précis.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est lié à une rencontre, en fait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel a été ce tournant, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une frustration accumulée depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour mieux concilier vie pro et vie privée, finalement.<break time="700ms"/>C.<break time="300ms"/>Une proposition de mission à l''étranger, totalement inattendue.<break time="700ms"/>D.<break time="300ms"/>Avec mon ancienne associée, dont je me suis séparée.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel a été ce tournant ? » porte sur **l''événement précis qui a marqué la bascule**. Seule C « une proposition de mission à l''étranger » désigne cet événement. A donne **la cause préalable** (l''insatisfaction). B donne **le but général** de la vie post-tournant. D donne **une autre transformation parallèle** (séparation), pas le tournant principal évoqué.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 12 : Risque sous-estimé (« quel risque négligé ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez lancé le produit en juin, comme prévu ?\n[Femme] Oui, dans un calendrier impeccable.\n[Homme] Et avec le recul, quel risque aviez-vous sous-estimé ?\n[Femme] ...\n\nA. Pour une cible un peu plus large que prévu initialement.\nB. Au cours de réunions hebdomadaires pourtant rigoureuses.\nC. La capacité de notre support à absorber la demande.\nD. Avec un investissement très conséquent, pourtant.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez lancé le produit en juin, comme prévu ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, dans un calendrier impeccable.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et avec le recul, quel risque aviez-vous sous-estimé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour une cible un peu plus large que prévu initialement.<break time="700ms"/>B.<break time="300ms"/>Au cours de réunions hebdomadaires pourtant rigoureuses.<break time="700ms"/>C.<break time="300ms"/>La capacité de notre support à absorber la demande.<break time="700ms"/>D.<break time="300ms"/>Avec un investissement très conséquent, pourtant.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Quel risque aviez-vous sous-estimé ? » porte sur **un point précis mal évalué à l''avance**. Seule C « la capacité de notre support à absorber la demande » désigne ce risque. A donne **une modification de cible**. B donne **le cadre de préparation** (« où en avez-vous parlé ? »). D donne **l''effort financier déployé**, pas un risque.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 13 : Regret (« qu'est-ce que tu regrettes ? ») / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as terminé ta thèse il y a un an, je crois.\n[Homme] Oui, ça paraît loin déjà.\n[Femme] Avec le recul, qu''est-ce que tu regrettes le plus dans ce parcours ?\n[Homme] ...\n\nA. De ne pas avoir pris davantage de pauses véritables.\nB. À la suite d''une soutenance brillante, pourtant.\nC. Pour me consacrer enfin à un projet personnel.\nD. Avec une directrice de thèse extrêmement présente.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as terminé ta thèse il y a un an, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, ça paraît loin déjà.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec le recul, qu''est-ce que tu regrettes le plus dans ce parcours ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>De ne pas avoir pris davantage de pauses véritables.<break time="700ms"/>B.<break time="300ms"/>À la suite d''une soutenance brillante, pourtant.<break time="700ms"/>C.<break time="300ms"/>Pour me consacrer enfin à un projet personnel.<break time="700ms"/>D.<break time="300ms"/>Avec une directrice de thèse extrêmement présente.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce que tu regrettes le plus ? » porte sur **un manquement / une chose qu''on aurait voulu faire autrement**. Seule A « de ne pas avoir pris davantage de pauses » formule ce regret (négation utile). B donne **un fait positif** (la soutenance réussie) qui contredit toute idée de regret. C donne **un but post-thèse**. D donne **un atout** du parcours, pas un regret.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 14 : Surprise rétrospective (« qu'est-ce qui t'a surpris après coup ? ») / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Vous avez vendu la maison de famille, finalement ?\n[Femme] Oui, l''été dernier, ça a été un déchirement.\n[Homme] Et qu''est-ce qui t''a le plus surprise, après coup ?\n[Femme] ...\n\nA. Au bout de trois mois de négociations avec les acquéreurs.\nB. Le soulagement immédiat ressenti, en réalité.\nC. Pour pouvoir investir dans un nouveau projet collectif.\nD. Avec mes frères et sœurs, dans la concorde.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez vendu la maison de famille, finalement ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, l''été dernier, ça a été un déchirement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''est-ce qui t''a le plus surprise, après coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de trois mois de négociations avec les acquéreurs.<break time="700ms"/>B.<break time="300ms"/>Le soulagement immédiat ressenti, en réalité.<break time="700ms"/>C.<break time="300ms"/>Pour pouvoir investir dans un nouveau projet collectif.<break time="700ms"/>D.<break time="300ms"/>Avec mes frères et sœurs, dans la concorde.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''a le plus surprise après coup ? » porte sur **un effet inattendu vécu a posteriori**. Seule B « le soulagement immédiat ressenti » désigne cet effet contre-intuitif (par contraste avec « déchirement » du tour précédent). A donne **la durée du processus**. C donne **le but** de la vente. D donne **l''entente familiale** durant la vente, pas une surprise rétrospective.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 15 : Point encore ouvert (« qu'est-ce qui reste à éclaircir ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as bouclé l''audit du département financier ?\n[Homme] Globalement oui, mais pas totalement.\n[Femme] Qu''est-ce qui reste à éclaircir, à ce stade ?\n[Homme] ...\n\nA. Pendant deux semaines supplémentaires si nécessaire.\nB. Avec l''aide d''un consultant indépendant.\nC. Le mode de calcul des bonus de l''an dernier.\nD. Pour rassurer pleinement le comité de direction.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as bouclé l''audit du département financier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Globalement oui, mais pas totalement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui reste à éclaircir, à ce stade ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux semaines supplémentaires si nécessaire.<break time="700ms"/>B.<break time="300ms"/>Avec l''aide d''un consultant indépendant.<break time="700ms"/>C.<break time="300ms"/>Le mode de calcul des bonus de l''an dernier.<break time="700ms"/>D.<break time="300ms"/>Pour rassurer pleinement le comité de direction.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui reste à éclaircir ? » porte sur **le point précis encore en suspens**. Seule C « le mode de calcul des bonus de l''an dernier » identifie cette zone d''ombre. A donne **le délai restant**. B donne **l''aide envisagée pour avancer**. D donne **le but final** de l''éclaircissement.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 16 : Limite éthique (« où places-tu la limite ? ») / social / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu m''as dit que tu interrogeais la frontière entre persuasion et manipulation, dans ton travail.\n[Femme] Oui, c''est un sujet qui me tient à cœur.\n[Homme] Et concrètement, où places-tu la limite, toi ?\n[Femme] ...\n\nA. À partir du moment où l''autre n''a plus le choix réel.\nB. Au cours de mes formations en management.\nC. Avec une équipe particulièrement réceptive au sujet.\nD. Pour préserver une culture de confiance durable.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que tu interrogeais la frontière entre persuasion et manipulation, dans ton travail.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est un sujet qui me tient à cœur.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et concrètement, où places-tu la limite, toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir du moment où l''autre n''a plus le choix réel.<break time="700ms"/>B.<break time="300ms"/>Au cours de mes formations en management.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe particulièrement réceptive au sujet.<break time="700ms"/>D.<break time="300ms"/>Pour préserver une culture de confiance durable.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Où places-tu la limite ? » porte sur **le critère qui sépare l''acceptable de l''inacceptable**. Seule A « à partir du moment où l''autre n''a plus le choix réel » formule ce critère. B donne **le cadre où s''exprime la réflexion**. C donne **l''auditoire de cette réflexion**. D donne **l''objectif** qui motive de poser une limite.',
    '[
       {"label": "A", "is_correct": true, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 17 : Difficulté inattendue (« qu'est-ce qui t'a freiné de manière inattendue ? ») / projet / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu as fini par créer ton entreprise il y a six mois ?\n[Homme] Oui, et le démarrage a été plus rude que prévu.\n[Femme] Qu''est-ce qui t''a le plus freiné, de manière inattendue ?\n[Homme] ...\n\nA. Au début du printemps, en pleine optimisme.\nB. Pour me prouver à moi-même que j''en étais capable.\nC. Avec une associée que je connais depuis vingt ans.\nD. La lenteur des démarches administratives, vraiment.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par créer ton entreprise il y a six mois ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, et le démarrage a été plus rude que prévu.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus freiné, de manière inattendue ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au début du printemps, en pleine optimisme.<break time="700ms"/>B.<break time="300ms"/>Pour me prouver à moi-même que j''en étais capable.<break time="700ms"/>C.<break time="300ms"/>Avec une associée que je connais depuis vingt ans.<break time="700ms"/>D.<break time="300ms"/>La lenteur des démarches administratives, vraiment.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''a freiné de manière inattendue ? » porte sur **un obstacle non anticipé**. Seule D « la lenteur des démarches administratives » désigne cet obstacle. A donne **le moment du démarrage**. B donne **la motivation initiale**. C donne **l''accompagnement** par l''associée.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 18 : Apprentissage involontaire (« qu'as-tu appris sans le vouloir ? ») / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Cette mission à l''étranger t''a beaucoup transformée, on dirait.\n[Femme] Plus que je ne l''avais imaginé, oui.\n[Homme] Et qu''as-tu appris, presque sans le vouloir ?\n[Femme] ...\n\nA. À cause d''une équipe particulièrement exigeante.\nB. Une humilité nouvelle face à la complexité culturelle.\nC. Au cœur de l''Asie du Sud-Est, comme tu sais.\nD. Pour me préparer à un poste de direction, plus tard.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cette mission à l''étranger t''a beaucoup transformée, on dirait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Plus que je ne l''avais imaginé, oui.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''as-tu appris, presque sans le vouloir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une équipe particulièrement exigeante.<break time="700ms"/>B.<break time="300ms"/>Une humilité nouvelle face à la complexité culturelle.<break time="700ms"/>C.<break time="300ms"/>Au cœur de l''Asie du Sud-Est, comme tu sais.<break time="700ms"/>D.<break time="300ms"/>Pour me préparer à un poste de direction, plus tard.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''as-tu appris presque sans le vouloir ? » porte sur **l''acquis non planifié, le résultat humain de l''expérience**. Seule B « une humilité nouvelle face à la complexité culturelle » nomme cet apprentissage. A donne **la cause de la transformation**. C donne **le lieu** de la mission. D donne **le but** de la mission (carrière), pas un apprentissage involontaire.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": true, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 19 : Circonstances d'une rencontre (« comment vous êtes-vous rencontrés ? ») / personnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Femme] Tu m''as dit que tu connaissais Mathilde depuis des années.\n[Homme] Oui, presque quinze ans en fait.\n[Femme] Et comment vous vous êtes rencontrés, à l''époque ?\n[Homme] ...\n\nA. Pour collaborer sur un projet d''écriture, à l''origine.\nB. Avec beaucoup d''enthousiasme dès le premier soir.\nC. À l''occasion d''une résidence d''écriture en Bretagne.\nD. Auprès d''un éditeur parisien qui nous a tous deux publiés.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu connaissais Mathilde depuis des années.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, presque quinze ans en fait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et comment vous vous êtes rencontrés, à l''époque ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour collaborer sur un projet d''écriture, à l''origine.<break time="700ms"/>B.<break time="300ms"/>Avec beaucoup d''enthousiasme dès le premier soir.<break time="700ms"/>C.<break time="300ms"/>À l''occasion d''une résidence d''écriture en Bretagne.<break time="700ms"/>D.<break time="300ms"/>Auprès d''un éditeur parisien qui nous a tous deux publiés.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Comment vous vous êtes rencontrés ? » porte sur **les circonstances / l''occasion de la rencontre**. Seule C « à l''occasion d''une résidence d''écriture en Bretagne » désigne ces circonstances. A donne **un but / une finalité** ultérieure. B donne **la manière** dont la relation a démarré sur le plan affectif (pas le contexte factuel). D donne **un intermédiaire / cadre professionnel** lié, mais ce n''est pas l''occasion de la première rencontre.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": true, "display_order": 3},
       {"label": "D", "is_correct": false, "display_order": 4}
     ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);

-- ----- Exercice 20 : Condition de retour (« qu'est-ce qui t'amènerait à revenir ? ») / professionnel / 3 tours -----
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-00b2-4000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite',
    '22222222-0000-0000-0000-000000000001',
    E'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.\n\n[Homme] Tu as quitté ton ancien employeur en très bons termes ?\n[Femme] Oui, complètement.\n[Homme] Et qu''est-ce qui t''amènerait à y revenir, un jour ?\n[Femme] ...\n\nA. Au bout de plusieurs années d''expérience ailleurs.\nB. Pour retrouver une équipe que j''appréciais beaucoup.\nC. Avec l''accord express de mon employeur actuel.\nD. La création d''un poste vraiment stratégique pour moi.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as quitté ton ancien employeur en très bons termes ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, complètement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''est-ce qui t''amènerait à y revenir, un jour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de plusieurs années d''expérience ailleurs.<break time="700ms"/>B.<break time="300ms"/>Pour retrouver une équipe que j''appréciais beaucoup.<break time="700ms"/>C.<break time="300ms"/>Avec l''accord express de mon employeur actuel.<break time="700ms"/>D.<break time="300ms"/>La création d''un poste vraiment stratégique pour moi.</prosody></voice></speak>',
    E'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
    E'« Qu''est-ce qui t''amènerait à y revenir ? » porte sur **la condition / l''événement déclencheur d''un retour**. Seule D « la création d''un poste vraiment stratégique pour moi » désigne cette condition concrète. A donne **un délai préalable nécessaire**. B donne **une motivation affective générale** (« pourquoi y reviendrais-tu sentimentalement ? »), pas un événement déclencheur. C donne **une validation pratique** (accord employeur actuel), modalité et non déclencheur.',
    '[
       {"label": "A", "is_correct": false, "display_order": 1},
       {"label": "B", "is_correct": false, "display_order": 2},
       {"label": "C", "is_correct": false, "display_order": 3},
       {"label": "D", "is_correct": true, "display_order": 4}
     ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);
