-- ============================================================================
-- V481 — TCF CO : drafts audio A2 (lot 2)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2). Table audio_question_draft.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-0022-3000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu fais, ce soir ?
[Femme] ...

A. Avec deux copines du lycée.
B. Pour mon anniversaire de demain.
C. Je vais au restaurant japonais.
D. Au quartier Bastille, sûrement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu fais, ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux copines du lycée.<break time="700ms"/>B.<break time="300ms"/>Pour mon anniversaire de demain.<break time="700ms"/>C.<break time="300ms"/>Je vais au restaurant japonais.<break time="700ms"/>D.<break time="300ms"/>Au quartier Bastille, sûrement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que tu fais ce soir ? » porte sur **l''activité prévue**. Seule C « je vais au restaurant japonais » décrit une activité. A donne **les accompagnantes**. B donne **la raison / l''occasion**. D donne **le lieu / le quartier**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Il fait quoi dans la vie, ton père ?
[Homme] ...

A. Dans une grande entreprise du nord.
B. Depuis bientôt vingt-cinq ans.
C. Avec une équipe d''une dizaine de personnes.
D. Il est ingénieur en informatique.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Il fait quoi dans la vie, ton père ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans une grande entreprise du nord.<break time="700ms"/>B.<break time="300ms"/>Depuis bientôt vingt-cinq ans.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe d''une dizaine de personnes.<break time="700ms"/>D.<break time="300ms"/>Il est ingénieur en informatique.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Il fait quoi dans la vie ? » porte sur **le métier / la profession**. Seule D « il est ingénieur en informatique » nomme un métier. A donne **le lieu de travail**. B donne **l''ancienneté**. C donne **les collègues / l''équipe**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez combien d''enfants, finalement ?
[Femme] ...

A. Trois, deux filles et un garçon.
B. À l''école primaire du quartier.
C. Avec une grande différence d''âge.
D. Pour agrandir la famille bientôt.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez combien d''enfants, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois, deux filles et un garçon.<break time="700ms"/>B.<break time="300ms"/>À l''école primaire du quartier.<break time="700ms"/>C.<break time="300ms"/>Avec une grande différence d''âge.<break time="700ms"/>D.<break time="300ms"/>Pour agrandir la famille bientôt.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien d''enfants ? » porte sur **le nombre**. Seule A « trois » donne une quantité. B donne **le lieu** où ils sont scolarisés. C donne **un trait** descriptif (l''écart d''âge). D donne **un projet futur**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Ton appartement fait combien de pièces ?
[Homme] ...

A. Au quatrième étage avec ascenseur.
B. Quatre pièces, plus la cuisine.
C. Pour environ neuf cents euros par mois.
D. Avec mon frère qui partage le loyer.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton appartement fait combien de pièces ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au quatrième étage avec ascenseur.<break time="700ms"/>B.<break time="300ms"/>Quatre pièces, plus la cuisine.<break time="700ms"/>C.<break time="300ms"/>Pour environ neuf cents euros par mois.<break time="700ms"/>D.<break time="300ms"/>Avec mon frère qui partage le loyer.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de pièces ? » porte sur **le nombre de pièces**. Seule B « quatre pièces » donne une quantité de pièces. A donne **l''étage**. C donne **le prix du loyer**. D donne **le colocataire**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] À quel étage tu habites, dans l''immeuble ?
[Femme] ...

A. Avec une belle vue sur la cour.
B. Pour profiter du calme du dernier étage.
C. Au cinquième, juste sous les toits.
D. Depuis le mois de janvier dernier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quel étage tu habites, dans l''immeuble ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une belle vue sur la cour.<break time="700ms"/>B.<break time="300ms"/>Pour profiter du calme du dernier étage.<break time="700ms"/>C.<break time="300ms"/>Au cinquième, juste sous les toits.<break time="700ms"/>D.<break time="300ms"/>Depuis le mois de janvier dernier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quel étage ? » porte sur **le numéro d''étage**. Seule C « au cinquième » donne un étage précis. A donne **un élément descriptif** (la vue). B donne **la raison du choix**. D donne **depuis quand**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000010', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Le billet de train pour Lyon, ça coûte combien ?
[Homme] ...

A. Au guichet de la gare de Lyon.
B. Pour partir vendredi prochain.
C. Avec une réduction étudiante incluse.
D. Soixante-cinq euros, en seconde classe.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le billet de train pour Lyon, ça coûte combien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet de la gare de Lyon.<break time="700ms"/>B.<break time="300ms"/>Pour partir vendredi prochain.<break time="700ms"/>C.<break time="300ms"/>Avec une réduction étudiante incluse.<break time="700ms"/>D.<break time="300ms"/>Soixante-cinq euros, en seconde classe.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Ça coûte combien ? » porte sur **le prix**. Seule D « soixante-cinq euros » donne un montant. A donne **le lieu d''achat**. B donne **la date du voyage**. C donne **un avantage tarifaire** (réduction), mais pas le prix lui-même.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000011', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] La boulangerie, c''est loin d''ici ?
[Femme] ...

A. À deux cents mètres, pas plus.
B. Avec un grand choix de pains.
C. Pour acheter une baguette tradition.
D. Du lundi au samedi, toute la journée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La boulangerie, c''est loin d''ici ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À deux cents mètres, pas plus.<break time="700ms"/>B.<break time="300ms"/>Avec un grand choix de pains.<break time="700ms"/>C.<break time="300ms"/>Pour acheter une baguette tradition.<break time="700ms"/>D.<break time="300ms"/>Du lundi au samedi, toute la journée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« C''est loin ? » porte sur **la distance**. Seule A « à deux cents mètres » donne une distance. B donne **un atout** du magasin. C donne **le but** de la visite. D donne **les horaires d''ouverture**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000012', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu viens de quel pays, à l''origine ?
[Homme] ...

A. Depuis bientôt douze ans à Paris.
B. Du Sénégal, plus précisément de Dakar.
C. Pour mes études supérieures.
D. Avec toute ma famille, à l''époque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu viens de quel pays, à l''origine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis bientôt douze ans à Paris.<break time="700ms"/>B.<break time="300ms"/>Du Sénégal, plus précisément de Dakar.<break time="700ms"/>C.<break time="300ms"/>Pour mes études supérieures.<break time="700ms"/>D.<break time="300ms"/>Avec toute ma famille, à l''époque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« De quel pays tu viens ? » porte sur **le pays d''origine**. Seule B « du Sénégal » nomme un pays. A donne **depuis quand** la personne vit en France. C donne **la raison de la venue**. D donne **l''accompagnement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000013', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu loges dans quel type de logement, là-bas ?
[Femme] ...

A. Avec deux autres étudiantes en colocation.
B. Pour environ six cents euros mensuels.
C. Un petit studio meublé, très pratique.
D. À côté de la gare centrale.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu loges dans quel type de logement, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec deux autres étudiantes en colocation.<break time="700ms"/>B.<break time="300ms"/>Pour environ six cents euros mensuels.<break time="700ms"/>C.<break time="300ms"/>Un petit studio meublé, très pratique.<break time="700ms"/>D.<break time="300ms"/>À côté de la gare centrale.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel type de logement ? » porte sur **la nature du logement**. Seule C « un petit studio meublé » nomme un type de logement. A donne **les colocataires**. B donne **le prix mensuel**. D donne **le lieu / la proximité**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000014', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Le concert, ça finit à quelle heure, ce soir ?
[Homme] ...

A. À la salle Pleyel, dans le huitième.
B. Pour deux heures de musique environ.
C. Avec un groupe que j''adore.
D. Vers vingt-trois heures trente, normalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le concert, ça finit à quelle heure, ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la salle Pleyel, dans le huitième.<break time="700ms"/>B.<break time="300ms"/>Pour deux heures de musique environ.<break time="700ms"/>C.<break time="300ms"/>Avec un groupe que j''adore.<break time="700ms"/>D.<break time="300ms"/>Vers vingt-trois heures trente, normalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Ça finit à quelle heure ? » porte sur **l''heure de fin** précise. Seule D « vers vingt-trois heures trente » donne une heure. A donne **le lieu** du concert. B donne **la durée** totale (« combien de temps ? »). C donne **l''accompagnant**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000015', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu es le combientième dans la file d''attente ?
[Femme] ...

A. Le septième, juste après cette dame.
B. Pour un rendez-vous à la préfecture.
C. Depuis presque une heure déjà.
D. Avec mon dossier de naturalisation.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu es le combientième dans la file d''attente ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le septième, juste après cette dame.<break time="700ms"/>B.<break time="300ms"/>Pour un rendez-vous à la préfecture.<break time="700ms"/>C.<break time="300ms"/>Depuis presque une heure déjà.<break time="700ms"/>D.<break time="300ms"/>Avec mon dossier de naturalisation.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu es le combientième ? » porte sur **la position / le rang dans la file**. Seule A « le septième » donne un rang ordinal. B donne **le motif de la venue**. C donne **la durée d''attente**. D donne **un objet apporté**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-3000-0000-000000000016', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu es en quelle classe, cette année ?
[Homme] ...

A. Au lycée Voltaire, dans le onzième.
B. En classe de seconde générale.
C. Pour préparer le bac dans deux ans.
D. Avec une trentaine d''élèves au total.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu es en quelle classe, cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lycée Voltaire, dans le onzième.<break time="700ms"/>B.<break time="300ms"/>En classe de seconde générale.<break time="700ms"/>C.<break time="300ms"/>Pour préparer le bac dans deux ans.<break time="700ms"/>D.<break time="300ms"/>Avec une trentaine d''élèves au total.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« En quelle classe ? » porte sur **le niveau scolaire**. Seule B « en classe de seconde générale » nomme un niveau. A donne **l''établissement / le lieu**. C donne **l''objectif futur**. D donne **le nombre de camarades**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.351794+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000001', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu préfères courir le matin ou le soir ?
[Femme] ...

A. Plutôt le matin, vers sept heures.
B. Au parc, près de chez moi.
C. Pour garder la forme et dormir mieux.
D. Avec une amie du quartier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu préfères courir le matin ou le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt le matin, vers sept heures.<break time="700ms"/>B.<break time="300ms"/>Au parc, près de chez moi.<break time="700ms"/>C.<break time="300ms"/>Pour garder la forme et dormir mieux.<break time="700ms"/>D.<break time="300ms"/>Avec une amie du quartier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Le matin ou le soir ? » porte sur **la période de la journée préférée**. Seule A « plutôt le matin » choisit une période. B donne **le lieu** (« où ? »). C donne **le but / la raison** (« pourquoi ? »). D donne **l''accompagnant** (« avec qui ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000002', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quelle langue tu parles avec tes parents à la maison ?
[Homme] ...

A. Depuis tout petit, déjà.
B. L''arabe, surtout avec ma mère.
C. Pour ne pas oublier mes origines.
D. Au téléphone, presque tous les jours.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle langue tu parles avec tes parents à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis tout petit, déjà.<break time="700ms"/>B.<break time="300ms"/>L''arabe, surtout avec ma mère.<break time="700ms"/>C.<break time="300ms"/>Pour ne pas oublier mes origines.<break time="700ms"/>D.<break time="300ms"/>Au téléphone, presque tous les jours.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle langue tu parles ? » porte sur **la langue utilisée**. Seule B « l''arabe » nomme une langue. A donne **depuis quand**. C donne **la raison / le but**. D donne **le canal et la fréquence**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000003', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quel siège tu prends au cinéma, en général ?
[Femme] ...

A. Au cinéma Pathé du centre-ville.
B. Pour mieux voir les sous-titres.
C. Au milieu de la salle, rangée H.
D. Avec un grand pop-corn salé.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel siège tu prends au cinéma, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cinéma Pathé du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Pour mieux voir les sous-titres.<break time="700ms"/>C.<break time="300ms"/>Au milieu de la salle, rangée H.<break time="700ms"/>D.<break time="300ms"/>Avec un grand pop-corn salé.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel siège ? » porte sur **la place dans la salle**. Seule C « au milieu de la salle, rangée H » localise un siège précis. A donne **le cinéma fréquenté**. B donne **la raison**. D donne **un accompagnement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000004', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Dans quel quartier tu habites, maintenant ?
[Homme] ...

A. Depuis le mois de janvier.
B. Pour être près de mes parents.
C. Avec deux colocataires sympas.
D. Dans le quartier de la Croix-Rousse.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Dans quel quartier tu habites, maintenant ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis le mois de janvier.<break time="700ms"/>B.<break time="300ms"/>Pour être près de mes parents.<break time="700ms"/>C.<break time="300ms"/>Avec deux colocataires sympas.<break time="700ms"/>D.<break time="300ms"/>Dans le quartier de la Croix-Rousse.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Dans quel quartier ? » porte sur **le nom du quartier**. Seule D « le quartier de la Croix-Rousse » nomme un quartier. A donne **depuis quand**. B donne **la raison du choix**. C donne **les colocataires**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000005', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quel est ton loisir préféré, le week-end ?
[Femme] ...

A. Tous les samedis après-midi.
B. La peinture à l''aquarelle, sans hésiter.
C. Pour me détendre après la semaine.
D. À la maison, dans mon atelier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel est ton loisir préféré, le week-end ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Tous les samedis après-midi.<break time="700ms"/>B.<break time="300ms"/>La peinture à l''aquarelle, sans hésiter.<break time="700ms"/>C.<break time="300ms"/>Pour me détendre après la semaine.<break time="700ms"/>D.<break time="300ms"/>À la maison, dans mon atelier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton loisir préféré ? » porte sur **l''activité choisie**. Seule B « la peinture à l''aquarelle » nomme un loisir. A donne **la fréquence**. C donne **le but / la raison**. D donne **le lieu de pratique**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000006', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Qu''est-ce qu''il y a comme plat du jour aujourd''hui ?
[Homme] ...

A. Un blanquette de veau avec du riz.
B. Pour douze euros cinquante, boisson comprise.
C. Dans la salle du fond, à droite.
D. Vers midi et demi, en général.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qu''il y a comme plat du jour aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un blanquette de veau avec du riz.<break time="700ms"/>B.<break time="300ms"/>Pour douze euros cinquante, boisson comprise.<break time="700ms"/>C.<break time="300ms"/>Dans la salle du fond, à droite.<break time="700ms"/>D.<break time="300ms"/>Vers midi et demi, en général.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qu''il y a comme plat du jour ? » porte sur **l''identité du plat servi**. Seule A « une blanquette de veau avec du riz » nomme un plat. B donne **le prix**. C donne **le lieu dans le restaurant**. D donne **l''heure du service**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000007', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu bois à table, le soir ?
[Femme] ...

A. Pour bien digérer mon repas.
B. Au verre, en général un seul.
C. Avec mes enfants à table.
D. Une carafe d''eau bien fraîche.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu bois à table, le soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour bien digérer mon repas.<break time="700ms"/>B.<break time="300ms"/>Au verre, en général un seul.<break time="700ms"/>C.<break time="300ms"/>Avec mes enfants à table.<break time="700ms"/>D.<break time="300ms"/>Une carafe d''eau bien fraîche.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que tu bois à table ? » porte sur **la boisson consommée**. Seule D « une carafe d''eau bien fraîche » nomme une boisson. A donne **la raison**. B donne **le contenant et la quantité**. C donne **l''accompagnant**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000008', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel est ton surnom à la maison ?
[Homme] ...

A. Depuis que je suis tout petit.
B. Par mes frères et sœurs, surtout.
C. Loulou, c''est ma mère qui l''a choisi.
D. Pour rire, en général.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton surnom à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis que je suis tout petit.<break time="700ms"/>B.<break time="300ms"/>Par mes frères et sœurs, surtout.<break time="700ms"/>C.<break time="300ms"/>Loulou, c''est ma mère qui l''a choisi.<break time="700ms"/>D.<break time="300ms"/>Pour rire, en général.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton surnom ? » porte sur **le surnom lui-même**. Seule C « Loulou » nomme un surnom. A donne **depuis quand**. B donne **par qui tu es appelé ainsi**. D donne **dans quel esprit**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000009', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quel jour tu fêtes ton anniversaire ?
[Femme] ...

A. Le quinze mai, chaque année.
B. Avec toute ma famille réunie.
C. Au restaurant, comme d''habitude.
D. Pour mes trente ans, cette fois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel jour tu fêtes ton anniversaire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le quinze mai, chaque année.<break time="700ms"/>B.<break time="300ms"/>Avec toute ma famille réunie.<break time="700ms"/>C.<break time="300ms"/>Au restaurant, comme d''habitude.<break time="700ms"/>D.<break time="300ms"/>Pour mes trente ans, cette fois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel jour tu fêtes ton anniversaire ? » porte sur **la date**. Seule A « le quinze mai » donne une date. B donne **avec qui**. C donne **le lieu**. D donne **l''âge fêté / la raison spéciale**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000a', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Dans quelle pièce tu travailles à la maison ?
[Homme] ...

A. Pour être au calme, surtout.
B. Pendant toute la matinée.
C. Avec mon ordinateur portable.
D. Dans le bureau du premier étage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Dans quelle pièce tu travailles à la maison ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour être au calme, surtout.<break time="700ms"/>B.<break time="300ms"/>Pendant toute la matinée.<break time="700ms"/>C.<break time="300ms"/>Avec mon ordinateur portable.<break time="700ms"/>D.<break time="300ms"/>Dans le bureau du premier étage.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Dans quelle pièce ? » porte sur **la pièce de la maison utilisée**. Seule D « dans le bureau du premier étage » nomme une pièce. A donne **la raison**. B donne **la durée**. C donne **l''outil utilisé**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000b', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu fais le dimanche, en général ?
[Femme] ...

A. Au parc à côté de chez moi.
B. Une grande balade en forêt.
C. Pour profiter du grand air.
D. Avec mon mari et les enfants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu fais le dimanche, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au parc à côté de chez moi.<break time="700ms"/>B.<break time="300ms"/>Une grande balade en forêt.<break time="700ms"/>C.<break time="300ms"/>Pour profiter du grand air.<break time="700ms"/>D.<break time="300ms"/>Avec mon mari et les enfants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que tu fais le dimanche ? » porte sur **l''activité pratiquée**. Seule B « une grande balade en forêt » nomme une activité. A donne **le lieu**. C donne **le but**. D donne **avec qui**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000c', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quel sport tu regardes le plus à la télé ?
[Homme] ...

A. Sur la chaîne sport, en direct.
B. Avec mes copains, le samedi soir.
C. Le rugby, surtout les matchs internationaux.
D. Pour soutenir l''équipe de France.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel sport tu regardes le plus à la télé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la chaîne sport, en direct.<break time="700ms"/>B.<break time="300ms"/>Avec mes copains, le samedi soir.<break time="700ms"/>C.<break time="300ms"/>Le rugby, surtout les matchs internationaux.<break time="700ms"/>D.<break time="300ms"/>Pour soutenir l''équipe de France.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel sport tu regardes ? » porte sur **le sport regardé**. Seule C « le rugby » nomme un sport. A donne **la chaîne / le canal**. B donne **avec qui et quand**. D donne **la raison**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000d', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] De quelle couleur sont les murs de ton salon ?
[Femme] ...

A. Pour donner une impression de lumière.
B. Avec mon mari, en deux jours.
C. Dans la grande pièce du fond.
D. Beige clair, presque crème.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">De quelle couleur sont les murs de ton salon ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour donner une impression de lumière.<break time="700ms"/>B.<break time="300ms"/>Avec mon mari, en deux jours.<break time="700ms"/>C.<break time="300ms"/>Dans la grande pièce du fond.<break time="700ms"/>D.<break time="300ms"/>Beige clair, presque crème.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« De quelle couleur sont les murs ? » porte sur **la couleur de la peinture**. Seule D « beige clair, presque crème » donne une couleur. A donne **la raison du choix**. B donne **avec qui et en combien de temps tu as peint**. C donne **la pièce concernée**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000e', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quelle chambre on vous a donnée à l''hôtel ?
[Homme] ...

A. La deux cent quatorze, au deuxième étage.
B. Pour deux nuits seulement.
C. Avec une jolie vue sur la mer.
D. À l''Hôtel des Voyageurs, près de la gare.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle chambre on vous a donnée à l''hôtel ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La deux cent quatorze, au deuxième étage.<break time="700ms"/>B.<break time="300ms"/>Pour deux nuits seulement.<break time="700ms"/>C.<break time="300ms"/>Avec une jolie vue sur la mer.<break time="700ms"/>D.<break time="300ms"/>À l''Hôtel des Voyageurs, près de la gare.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle chambre ? » porte sur **le numéro de la chambre**. Seule A « la deux cent quatorze » donne un numéro. B donne **la durée du séjour**. C donne **une caractéristique de la chambre**. D donne **le nom de l''hôtel et son lieu**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-00000000000f', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quelle forme a ta nouvelle table de salon ?
[Femme] ...

A. En bois clair, très naturel.
B. Ronde, avec un pied central.
C. Pour environ trois cents euros.
D. Au magasin de meubles du centre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle forme a ta nouvelle table de salon ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En bois clair, très naturel.<break time="700ms"/>B.<break time="300ms"/>Ronde, avec un pied central.<break time="700ms"/>C.<break time="300ms"/>Pour environ trois cents euros.<break time="700ms"/>D.<break time="300ms"/>Au magasin de meubles du centre.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle forme ? » porte sur **la forme géométrique**. Seule B « ronde » indique une forme. A donne **la matière**. C donne **le prix**. D donne **le lieu d''achat**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000010', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] En quelle matière est ton nouveau pull ?
[Homme] ...

A. Pour l''hiver, surtout.
B. Dans une boutique en ligne.
C. En laine douce, cent pour cent.
D. Avec un col roulé, très chaud.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quelle matière est ton nouveau pull ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour l''hiver, surtout.<break time="700ms"/>B.<break time="300ms"/>Dans une boutique en ligne.<break time="700ms"/>C.<break time="300ms"/>En laine douce, cent pour cent.<break time="700ms"/>D.<break time="300ms"/>Avec un col roulé, très chaud.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« En quelle matière ? » porte sur **la matière textile**. Seule C « en laine douce, cent pour cent » donne une matière. A donne **la saison d''usage**. B donne **le lieu d''achat**. D donne **la coupe du vêtement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000011', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu fais quelle taille pour les chemises ?
[Femme] ...

A. Du trente-huit, en général.
B. Dans la boutique du centre commercial.
C. Pour aller au bureau, surtout.
D. Avec un col bien classique.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fais quelle taille pour les chemises ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du trente-huit, en général.<break time="700ms"/>B.<break time="300ms"/>Dans la boutique du centre commercial.<break time="700ms"/>C.<break time="300ms"/>Pour aller au bureau, surtout.<break time="700ms"/>D.<break time="300ms"/>Avec un col bien classique.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle taille pour les chemises ? » porte sur **la taille vestimentaire**. Seule A « du trente-huit » donne une taille. B donne **le lieu d''achat**. C donne **l''usage**. D donne **un détail de coupe**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000012', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Quelle marque de voiture tu as achetée ?
[Homme] ...

A. Pour les longs trajets familiaux.
B. Une Renault, le modèle Clio.
C. Chez un concessionnaire en banlieue.
D. Avec ma femme, samedi dernier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle marque de voiture tu as achetée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour les longs trajets familiaux.<break time="700ms"/>B.<break time="300ms"/>Une Renault, le modèle Clio.<break time="700ms"/>C.<break time="300ms"/>Chez un concessionnaire en banlieue.<break time="700ms"/>D.<break time="300ms"/>Avec ma femme, samedi dernier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle marque de voiture ? » porte sur **la marque du véhicule**. Seule B « une Renault, le modèle Clio » nomme une marque. A donne **l''usage prévu**. C donne **le lieu d''achat**. D donne **avec qui et quand**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000013', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Quel genre de vacances tu préfères ?
[Femme] ...

A. En juillet, plutôt qu''en août.
B. À la montagne, dans les Alpes.
C. Avec mes deux enfants, toujours.
D. Des vacances tranquilles à la mer.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel genre de vacances tu préfères ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En juillet, plutôt qu''en août.<break time="700ms"/>B.<break time="300ms"/>À la montagne, dans les Alpes.<break time="700ms"/>C.<break time="300ms"/>Avec mes deux enfants, toujours.<break time="700ms"/>D.<break time="300ms"/>Des vacances tranquilles à la mer.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel genre de vacances ? » porte sur **le type de séjour préféré**. Seule D « des vacances tranquilles à la mer » qualifie un genre. A donne **le mois**. B donne **un lieu géographique précis**. C donne **avec qui**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000014', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] À quelle heure on mange ce soir ?
[Homme] ...

A. Dans la cuisine, comme d''habitude.
B. Vers vingt heures, je dirais.
C. Avec les voisins du dessous.
D. Pour terminer mon dossier avant.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À quelle heure on mange ce soir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la cuisine, comme d''habitude.<break time="700ms"/>B.<break time="300ms"/>Vers vingt heures, je dirais.<break time="700ms"/>C.<break time="300ms"/>Avec les voisins du dessous.<break time="700ms"/>D.<break time="300ms"/>Pour terminer mon dossier avant.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quelle heure on mange ? » porte sur **l''heure du repas**. Seule B « vers vingt heures » donne une heure. A donne **le lieu**. C donne **avec qui**. D donne **la raison du retard / l''attente**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000015', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu fais quelle pointure de chaussures ?
[Femme] ...

A. Dans le magasin à côté de la mairie.
B. Pour aller marcher en forêt, surtout.
C. Du quarante, parfois quarante et un.
D. Avec des semelles confortables dedans.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu fais quelle pointure de chaussures ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans le magasin à côté de la mairie.<break time="700ms"/>B.<break time="300ms"/>Pour aller marcher en forêt, surtout.<break time="700ms"/>C.<break time="300ms"/>Du quarante, parfois quarante et un.<break time="700ms"/>D.<break time="300ms"/>Avec des semelles confortables dedans.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle pointure ? » porte sur **la taille des pieds en chiffre**. Seule C « du quarante, parfois quarante et un » donne une pointure. A donne **le lieu d''achat**. B donne **l''usage prévu**. D donne **un accessoire complémentaire**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL),

  ('66666666-0022-4000-0000-000000000016', 'A2', 'co_dialogue_court_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as vu ce film combien de fois déjà ?
[Homme] ...

A. Trois fois, je crois bien.
B. Au cinéma, et deux fois à la télé.
C. Avec mon frère, à chaque fois.
D. Parce que j''adore l''acteur principal.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as vu ce film combien de fois déjà ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Trois fois, je crois bien.<break time="700ms"/>B.<break time="300ms"/>Au cinéma, et deux fois à la télé.<break time="700ms"/>C.<break time="300ms"/>Avec mon frère, à chaque fois.<break time="700ms"/>D.<break time="300ms"/>Parce que j''adore l''acteur principal.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Combien de fois ? » porte sur **le nombre total de visionnages**. Seule A « trois fois » donne un nombre clair de répétitions. B donne **les lieux / supports de visionnage** (« où ? ») et mélange deux infos sans total clair. C donne **avec qui**. D donne **la raison** de l''aimer.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.36171+02', NULL, NULL, NULL);
