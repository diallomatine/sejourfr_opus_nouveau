-- ============================================================================
-- LOT PILOTE — 10 questions audio A2 (drafts)
-- ============================================================================
-- 📋 Insertion dans la table audio_question_draft (migration V30+ de Claude Code)
--
-- 🎯 Caractéristiques :
--    - Niveau : A2 (10/10)
--    - Module : TCF, type CO (Compréhension Orale)
--    - Format audio : court (30-60 secondes), 1 voix principale
--    - Distracteurs A2 : 1 piégeux sur 3 (nombre proche, lieu mal attribué,
--      mot du transcript hors contexte)
--    - Voix : Denise (féminin) / Henri (masculin) selon le contexte
--
-- 📊 10 thèmes différents :
--    1. Transport  2. Commerce  3. Santé  4. Restauration  5. Logement
--    6. Travail    7. École     8. Loisirs 9. Voyage      10. Vie quotidienne
--
-- ⚠️ Cette migration suppose que la table audio_question_draft existe
--    (créée par la tâche Claude Code en cours).
-- ============================================================================


-- ============================================================================
-- Q1 : TRANSPORT — Annonce de gare (retard de train)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0001-0000-0000-000000000001', 'A2', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Votre attention s''il vous plaît. Le train numéro 8425, à destination de Marseille, prévu à 14 heures 30, aura un retard d''environ 20 minutes. Le départ est maintenant prévu à 14 heures 50, voie B. Nous vous remercions de votre patience.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Votre attention s''il vous plaît.<break time="500ms"/> Le train numéro 8425, à destination de Marseille, prévu à 14 heures 30, aura un retard d''environ 20 minutes.<break time="400ms"/> Le départ est maintenant prévu à 14 heures 50, voie B.<break time="400ms"/> Nous vous remercions de votre patience.</prosody></voice></speak>',
    E'À quelle heure le train va-t-il partir ?',
    E'L''annonce précise clairement : « Le départ est maintenant prévu à 14 heures 50 ». La réponse B est correcte. La réponse A reprend l''heure initiale (14h30), avant le retard — piège classique pour qui n''écoute pas l''ajustement. La réponse C est plausible mais inventée. La réponse D mélange les chiffres (20 minutes est la durée du retard, pas une heure).',
    '[
      {"label": "À 14h30", "is_correct": false, "display_order": 1},
      {"label": "À 14h50", "is_correct": true, "display_order": 2},
      {"label": "À 15h00", "is_correct": false, "display_order": 3},
      {"label": "À 14h20", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q2 : COMMERCE — Dialogue magasin (achat de vêtements)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0002-0000-0000-000000000002', 'A2', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Bonjour madame, je cherche un pull pour mon mari, en taille L.\n— Bonjour ! Nous avons ce pull en bleu marine à 45 euros, et celui-ci en gris à 38 euros.\n— Le gris est joli. Je le prends.\n— Très bien, ça fait 38 euros. Vous payez par carte ?\n— Oui, par carte s''il vous plaît.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bonjour madame, je cherche un pull pour mon mari, en taille L.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour !<break time="300ms"/> Nous avons ce pull en bleu marine à 45 euros, et celui-ci en gris à 38 euros.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le gris est joli.<break time="200ms"/> Je le prends.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien, ça fait 38 euros.<break time="300ms"/> Vous payez par carte ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, par carte s''il vous plaît.</prosody></voice></speak>',
    E'Combien la cliente va-t-elle payer ?',
    E'La cliente choisit le pull gris à 38 euros. La réponse C est correcte. La réponse A (45 €) correspond au pull bleu marine, qu''elle n''a pas pris — piège classique. La réponse B est une somme plausible mais non mentionnée. La réponse D mélange deux chiffres entendus dans le dialogue.',
    '[
      {"label": "45 euros", "is_correct": false, "display_order": 1},
      {"label": "40 euros", "is_correct": false, "display_order": 2},
      {"label": "38 euros", "is_correct": true, "display_order": 3},
      {"label": "83 euros", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q3 : SANTÉ — Message répondeur médecin (confirmation RDV)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0003-0000-0000-000000000003', 'A2', 'co_comprendre_message',
    '22222222-0000-0000-0000-000000000001',
    E'Bonjour, c''est le cabinet du docteur Bernard. Je vous appelle pour confirmer votre rendez-vous de jeudi 14 mars à 10 heures 15. Merci d''apporter votre carte vitale et votre ordonnance. À jeudi !',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Bonjour, c''est le cabinet du docteur Bernard.<break time="400ms"/> Je vous appelle pour confirmer votre rendez-vous de jeudi 14 mars à 10 heures 15.<break time="500ms"/> Merci d''apporter votre carte vitale et votre ordonnance.<break time="400ms"/> À jeudi !</prosody></voice></speak>',
    E'Que doit apporter le patient au rendez-vous ?',
    E'Le message précise : « Merci d''apporter votre carte vitale et votre ordonnance ». La réponse B est correcte. La réponse A oublie l''ordonnance, qui est aussi demandée. La réponse C mélange un mot entendu (« vitale ») avec un élément non mentionné. La réponse D invente un document qui n''est pas demandé.',
    '[
      {"label": "Sa carte vitale uniquement", "is_correct": false, "display_order": 1},
      {"label": "Sa carte vitale et son ordonnance", "is_correct": true, "display_order": 2},
      {"label": "Sa carte vitale et sa pièce d''identité", "is_correct": false, "display_order": 3},
      {"label": "Son ordonnance et un chèque", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q4 : RESTAURATION — Dialogue restaurant (commande)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0004-0000-0000-000000000004', 'A2', 'co_comprendre_dialogue',
    '22222222-0000-0000-0000-000000000001',
    E'— Bonjour, vous avez choisi ?\n— Oui, je voudrais le menu du jour s''il vous plaît.\n— Très bien. Avec quelle entrée ? Salade verte ou soupe de légumes ?\n— La soupe, merci.\n— Et comme plat ?\n— Le poulet rôti avec des frites.\n— Parfait, et comme boisson ?\n— Juste une carafe d''eau, merci.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, vous avez choisi ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je voudrais le menu du jour s''il vous plaît.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Très bien.<break time="300ms"/> Avec quelle entrée ? Salade verte ou soupe de légumes ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La soupe, merci.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et comme plat ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le poulet rôti avec des frites.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Parfait, et comme boisson ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Juste une carafe d''eau, merci.</prosody></voice></speak>',
    E'Quelle entrée la cliente a-t-elle choisie ?',
    E'La cliente répond « La soupe, merci » quand on lui propose le choix. La réponse C est correcte. La réponse A est piégeuse : la salade verte a été proposée mais refusée. La réponse B est inventée (le serveur ne propose pas de salade composée). La réponse D mélange le plat principal (poulet) avec une entrée.',
    '[
      {"label": "Une salade verte", "is_correct": false, "display_order": 1},
      {"label": "Une salade composée", "is_correct": false, "display_order": 2},
      {"label": "Une soupe de légumes", "is_correct": true, "display_order": 3},
      {"label": "Du poulet en entrée", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q5 : LOGEMENT — Message agence immobilière (visite)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0005-0000-0000-000000000005', 'A2', 'co_comprendre_message',
    '22222222-0000-0000-0000-000000000001',
    E'Bonjour Madame Petit, c''est Julie de l''agence Habitat Plus. Je vous confirme la visite de l''appartement situé rue Pasteur, samedi prochain à 11 heures. L''appartement est au troisième étage, sans ascenseur. À samedi !',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Bonjour Madame Petit, c''est Julie de l''agence Habitat Plus.<break time="400ms"/> Je vous confirme la visite de l''appartement situé rue Pasteur, samedi prochain à 11 heures.<break time="500ms"/> L''appartement est au troisième étage, sans ascenseur.<break time="400ms"/> À samedi !</prosody></voice></speak>',
    E'À quel étage se trouve l''appartement ?',
    E'Le message indique clairement : « L''appartement est au troisième étage, sans ascenseur ». La réponse C est correcte. La réponse A confond avec 11 heures (l''horaire de la visite). La réponse B est inventée. La réponse D inverse le chiffre (3 vs 4).',
    '[
      {"label": "Au 11e étage", "is_correct": false, "display_order": 1},
      {"label": "Au 2e étage", "is_correct": false, "display_order": 2},
      {"label": "Au 3e étage", "is_correct": true, "display_order": 3},
      {"label": "Au 4e étage", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q6 : TRAVAIL — Annonce bureau (réunion)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0006-0000-0000-000000000006', 'A2', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Chers collègues, petit rappel : la réunion d''équipe initialement prévue mardi est déplacée à mercredi 16 heures, en salle 12. Merci de venir avec vos rapports mensuels. Bonne journée à tous.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="0.95">Chers collègues, petit rappel :<break time="400ms"/> la réunion d''équipe initialement prévue mardi est déplacée à mercredi 16 heures, en salle 12.<break time="500ms"/> Merci de venir avec vos rapports mensuels.<break time="400ms"/> Bonne journée à tous.</prosody></voice></speak>',
    E'Quand a lieu la réunion ?',
    E'L''annonce précise que la réunion est « déplacée à mercredi 16 heures ». La réponse C est correcte. La réponse A reprend le jour initial (mardi), avant le changement — piège pour qui n''écoute pas la suite. La réponse B mélange mercredi avec une heure inventée. La réponse D mélange salle 12 et un horaire.',
    '[
      {"label": "Mardi à 16h", "is_correct": false, "display_order": 1},
      {"label": "Mercredi à 12h", "is_correct": false, "display_order": 2},
      {"label": "Mercredi à 16h", "is_correct": true, "display_order": 3},
      {"label": "Mardi à 12h", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-HenriNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q7 : ÉCOLE — Annonce école (sortie scolaire)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0007-0000-0000-000000000007', 'A2', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Chers parents, l''école organise une sortie au zoo de Vincennes vendredi 5 avril. Le départ est prévu à 9 heures et le retour à 17 heures. Le prix est de 12 euros par enfant. Merci de bien vouloir signer l''autorisation avant lundi.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Chers parents, l''école organise une sortie au zoo de Vincennes vendredi 5 avril.<break time="400ms"/> Le départ est prévu à 9 heures et le retour à 17 heures.<break time="400ms"/> Le prix est de 12 euros par enfant.<break time="500ms"/> Merci de bien vouloir signer l''autorisation avant lundi.</prosody></voice></speak>',
    E'Combien coûte la sortie par enfant ?',
    E'L''annonce précise : « Le prix est de 12 euros par enfant ». La réponse B est correcte. La réponse A confond avec le 5 avril (la date). La réponse C confond avec 9 heures (le départ). La réponse D confond avec 17 heures (le retour).',
    '[
      {"label": "5 euros", "is_correct": false, "display_order": 1},
      {"label": "12 euros", "is_correct": true, "display_order": 2},
      {"label": "9 euros", "is_correct": false, "display_order": 3},
      {"label": "17 euros", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q8 : LOISIRS — Annonce radio (concert)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0008-0000-0000-000000000008', 'A2', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Ce samedi soir, ne manquez pas le grand concert de jazz au parc des Expositions ! Trois groupes seront sur scène à partir de 20 heures. L''entrée est gratuite, mais attention : il faut réserver votre place sur notre site internet avant vendredi soir.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-VivienneMultilingualNeural"><prosody rate="1.0">Ce samedi soir, ne manquez pas le grand concert de jazz au parc des Expositions !<break time="400ms"/> Trois groupes seront sur scène à partir de 20 heures.<break time="400ms"/> L''entrée est gratuite, mais attention :<break time="300ms"/> il faut réserver votre place sur notre site internet avant vendredi soir.</prosody></voice></speak>',
    E'Comment peut-on assister au concert ?',
    E'L''annonce précise : « L''entrée est gratuite, mais (...) il faut réserver votre place sur notre site internet avant vendredi soir ». La réponse C est correcte. La réponse A oublie la condition de réservation. La réponse B invente un prix (l''entrée est gratuite). La réponse D mélange gratuit + une autre démarche (téléphone) non mentionnée.',
    '[
      {"label": "Il suffit de venir, c''est gratuit", "is_correct": false, "display_order": 1},
      {"label": "Il faut payer à l''entrée", "is_correct": false, "display_order": 2},
      {"label": "Il faut réserver sur internet, c''est gratuit", "is_correct": true, "display_order": 3},
      {"label": "Il faut téléphoner pour réserver", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-VivienneMultilingualNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q9 : VOYAGE — Annonce aéroport (embarquement)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0009-0000-0000-000000000009', 'A2', 'co_comprendre_annonce',
    '22222222-0000-0000-0000-000000000001',
    E'Mesdames et Messieurs, l''embarquement du vol AF237 à destination de Montréal va commencer dans cinq minutes, porte numéro 14. Merci de préparer votre carte d''embarquement et votre passeport.',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Mesdames et Messieurs,<break time="300ms"/> l''embarquement du vol AF237 à destination de Montréal va commencer dans cinq minutes, porte numéro 14.<break time="500ms"/> Merci de préparer votre carte d''embarquement et votre passeport.</prosody></voice></speak>',
    E'Quelle est la destination du vol ?',
    E'L''annonce précise clairement : « à destination de Montréal ». La réponse B est correcte. La réponse A propose une autre ville canadienne plausible (piège géographique). La réponse C confond avec le numéro de vol (AF237 pourrait évoquer Paris). La réponse D est une autre ville américaine francophone potentiellement entendue.',
    '[
      {"label": "Toronto", "is_correct": false, "display_order": 1},
      {"label": "Montréal", "is_correct": true, "display_order": 2},
      {"label": "Paris", "is_correct": false, "display_order": 3},
      {"label": "New York", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);


-- ============================================================================
-- Q10 : VIE QUOTIDIENNE — Messagerie vocale (invitation dîner)
-- ============================================================================
INSERT INTO audio_question_draft (
    id, difficulty, competence_code, theme_id,
    transcript_text, ssml_text,
    statement, explanation, choices, voice_recommended, status
) VALUES (
    '66666666-0010-0000-0000-000000000010', 'A2', 'co_comprendre_message',
    '22222222-0000-0000-0000-000000000001',
    E'Salut Camille, c''est Léa ! Je t''appelle pour t''inviter à dîner chez moi samedi soir, vers 19 heures 30. J''ai préparé une grande lasagne ! Apporte juste une bouteille de vin si tu veux. Rappelle-moi pour confirmer. Bisous !',
    E'<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="1.05">Salut Camille, c''est Léa !<break time="300ms"/> Je t''appelle pour t''inviter à dîner chez moi samedi soir, vers 19 heures 30.<break time="400ms"/> J''ai préparé une grande lasagne !<break time="300ms"/> Apporte juste une bouteille de vin si tu veux.<break time="300ms"/> Rappelle-moi pour confirmer.<break time="300ms"/> Bisous !</prosody></voice></speak>',
    E'Que demande Léa à Camille d''apporter ?',
    E'Léa précise : « Apporte juste une bouteille de vin si tu veux ». La réponse C est correcte. La réponse A est piégeuse : la lasagne est mentionnée mais c''est Léa qui l''a préparée, pas Camille qui doit l''apporter. La réponse B invente le dessert (non mentionné). La réponse D mélange deux éléments dont aucun n''est demandé.',
    '[
      {"label": "Une lasagne", "is_correct": false, "display_order": 1},
      {"label": "Un dessert", "is_correct": false, "display_order": 2},
      {"label": "Une bouteille de vin", "is_correct": true, "display_order": 3},
      {"label": "Du pain et du fromage", "is_correct": false, "display_order": 4}
    ]'::jsonb,
    'fr-FR-DeniseNeural', 'TEXT_VALIDATED'
);
