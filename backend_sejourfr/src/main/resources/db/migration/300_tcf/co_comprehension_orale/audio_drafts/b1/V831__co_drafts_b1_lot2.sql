-- ============================================================================
-- V484 — TCF CO : drafts audio B1 (lot 2)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B1). Table audio_question_draft.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-00b1-3000-0000-00000000000b', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] On m''a dit que tu cuisinais beaucoup le week-end.
[Homme] Oui, c''est mon vrai moment de détente.
[Femme] Et tu aimes préparer quelle recette par-dessus tout ?
[Homme] ...

A. Pendant deux bonnes heures à chaque fois.
B. Avec ma fille aînée, qui adore m''aider.
C. Un bœuf bourguignon mijoté tout l''après-midi.
D. Pour me changer complètement les idées.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On m''a dit que tu cuisinais beaucoup le week-end.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est mon vrai moment de détente.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu aimes préparer quelle recette par-dessus tout ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux bonnes heures à chaque fois.<break time="700ms"/>B.<break time="300ms"/>Avec ma fille aînée, qui adore m''aider.<break time="700ms"/>C.<break time="300ms"/>Un bœuf bourguignon mijoté tout l''après-midi.<break time="700ms"/>D.<break time="300ms"/>Pour me changer complètement les idées.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent l''habitude (cuisine = détente du week-end) ; la question « tu aimes préparer quelle recette par-dessus tout ? » porte sur **l''identification d''une recette précise**. Seule C « un bœuf bourguignon mijoté tout l''après-midi » nomme une recette. A donne **la durée habituelle** (« combien de temps ? »). B donne **l''accompagnant** (« avec qui ? »). D donne **le but / bénéfice** (« pour quoi faire ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-00000000000c', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] On a enfin posé nos congés d''été cette année.
[Femme] Super ! Vous partez où, du coup ?
[Homme] ...

A. Pendant trois semaines complètes, en août.
B. Avec les enfants et les grands-parents.
C. Pour vraiment couper du quotidien parisien.
D. Sur une petite île de la côte croate.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a enfin posé nos congés d''été cette année.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Super ! Vous partez où, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant trois semaines complètes, en août.<break time="700ms"/>B.<break time="300ms"/>Avec les enfants et les grands-parents.<break time="700ms"/>C.<break time="300ms"/>Pour vraiment couper du quotidien parisien.<break time="700ms"/>D.<break time="300ms"/>Sur une petite île de la côte croate.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le premier tour pose le contexte (congés d''été posés) ; la question « vous partez où ? » porte sur **la destination des vacances**. Seule D « sur une petite île de la côte croate » désigne un lieu. A donne **la durée et le moment** (« combien de temps, quand ? »). B donne **les accompagnants** (« avec qui ? »). C donne **le but du voyage** (« pour quoi faire ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-00000000000d', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as donné ta démission la semaine dernière, c''est sûr ?
[Homme] Oui, j''ai posé ma lettre lundi matin.
[Femme] Mais qu''est-ce qui t''a vraiment décidé, à la fin ?
[Homme] ...

A. Une discussion très franche avec ma compagne, un soir.
B. Pour me lancer enfin dans mon propre projet.
C. Après plusieurs mois d''hésitation, quand même.
D. Avec mon manager, juste avant les vacances.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as donné ta démission la semaine dernière, c''est sûr ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai posé ma lettre lundi matin.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais qu''est-ce qui t''a vraiment décidé, à la fin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une discussion très franche avec ma compagne, un soir.<break time="700ms"/>B.<break time="300ms"/>Pour me lancer enfin dans mon propre projet.<break time="700ms"/>C.<break time="300ms"/>Après plusieurs mois d''hésitation, quand même.<break time="700ms"/>D.<break time="300ms"/>Avec mon manager, juste avant les vacances.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours confirment la démission ; la question « qu''est-ce qui t''a vraiment décidé ? » porte sur **l''élément déclencheur de la décision**. Seule A « une discussion très franche avec ma compagne » identifie un élément déclencheur. B donne **le but visé** (« pour quoi faire ? »). C donne **la durée d''hésitation** (« depuis combien de temps ? »). D donne **un interlocuteur et un moment** (« avec qui, quand ? »), pas la cause du choix.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-00000000000e', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] On parlait des grandes figures qu''on aime. Toi, tu admires vraiment qui, dans ta famille ?
[Femme] ...

A. Pour son courage face à la maladie, surtout.
B. Ma tante Hélène, sans la moindre hésitation.
C. Depuis que je suis toute petite, je crois.
D. Avec mon oncle, on parle souvent d''elle.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On parlait des grandes figures qu''on aime. Toi, tu admires vraiment qui, dans ta famille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour son courage face à la maladie, surtout.<break time="700ms"/>B.<break time="300ms"/>Ma tante Hélène, sans la moindre hésitation.<break time="700ms"/>C.<break time="300ms"/>Depuis que je suis toute petite, je crois.<break time="700ms"/>D.<break time="300ms"/>Avec mon oncle, on parle souvent d''elle.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « tu admires vraiment qui, dans ta famille ? » porte sur **l''identité de la personne admirée**. Seule B « ma tante Hélène » désigne une personne. A donne **la raison de l''admiration** (« pourquoi ? »). C donne **la durée du sentiment** (« depuis quand ? »). D donne **un interlocuteur** avec qui on en parle (« avec qui en parles-tu ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-00000000000f', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu suis bien des cours du soir depuis la rentrée ?
[Femme] Oui, deux fois par semaine, le mardi et le jeudi.
[Homme] Et tu as appris quoi de concret, jusqu''à présent ?
[Femme] ...

A. Avec un petit groupe de huit adultes motivés.
B. Pendant deux heures à chaque séance.
C. À tenir une conversation simple en espagnol.
D. Pour pouvoir voyager seule en Amérique latine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu suis bien des cours du soir depuis la rentrée ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, deux fois par semaine, le mardi et le jeudi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu as appris quoi de concret, jusqu''à présent ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un petit groupe de huit adultes motivés.<break time="700ms"/>B.<break time="300ms"/>Pendant deux heures à chaque séance.<break time="700ms"/>C.<break time="300ms"/>À tenir une conversation simple en espagnol.<break time="700ms"/>D.<break time="300ms"/>Pour pouvoir voyager seule en Amérique latine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le cadre (cours du soir, deux fois par semaine) ; la question « tu as appris quoi de concret ? » porte sur **le contenu réellement acquis**. Seule C « à tenir une conversation simple en espagnol » nomme un acquis concret. A donne **la composition du groupe** (« avec qui ? »). B donne **la durée d''une séance** (« combien de temps ? »). D donne **le but de l''apprentissage** (« pour quoi faire ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000010', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as l''air bien plus serein qu''avant, je trouve.
[Homme] Oui, je crois que j''ai vraiment changé quelque chose dans mes journées.
[Femme] Tu as commencé quoi, comme nouvelle habitude ?
[Homme] ...

A. Avec un ami qui fait pareil, pour se motiver.
B. Pour mieux gérer le stress du bureau, surtout.
C. Depuis environ deux mois, sans trop de mal.
D. Une petite méditation tous les matins, au réveil.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air bien plus serein qu''avant, je trouve.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je crois que j''ai vraiment changé quelque chose dans mes journées.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as commencé quoi, comme nouvelle habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec un ami qui fait pareil, pour se motiver.<break time="700ms"/>B.<break time="300ms"/>Pour mieux gérer le stress du bureau, surtout.<break time="700ms"/>C.<break time="300ms"/>Depuis environ deux mois, sans trop de mal.<break time="700ms"/>D.<break time="300ms"/>Une petite méditation tous les matins, au réveil.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours mettent en avant un changement positif ; la question « tu as commencé quoi, comme nouvelle habitude ? » porte sur **la nature de l''habitude prise**. Seule D « une petite méditation tous les matins, au réveil » nomme l''habitude. A donne **un partenaire de pratique** (« avec qui ? »). B donne **le but / motif** (« pour quoi faire ? »). C donne **la durée depuis le début** (« depuis quand ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000011', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as l''air en pleine forme, ces derniers temps !
[Homme] Oui, j''ai laissé tomber une mauvaise habitude. Et toi, qu''est-ce que tu as arrêté récemment ?
[Femme] ...

A. Le café après quatorze heures, et je dors mille fois mieux.
B. Depuis bientôt trois semaines, sans rechute.
C. Pour retrouver enfin un vrai sommeil réparateur.
D. À cause des conseils de ma médecin traitante.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air en pleine forme, ces derniers temps !</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai laissé tomber une mauvaise habitude. Et toi, qu''est-ce que tu as arrêté récemment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le café après quatorze heures, et je dors mille fois mieux.<break time="700ms"/>B.<break time="300ms"/>Depuis bientôt trois semaines, sans rechute.<break time="700ms"/>C.<break time="300ms"/>Pour retrouver enfin un vrai sommeil réparateur.<break time="700ms"/>D.<break time="300ms"/>À cause des conseils de ma médecin traitante.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question retournée « qu''est-ce que tu as arrêté récemment ? » porte sur **la nature de l''habitude abandonnée**. Seule A « le café après quatorze heures » identifie l''habitude arrêtée. B donne **la durée depuis l''arrêt** (« depuis quand ? »). C donne **le but visé** (« pour quoi faire ? »). D donne **la cause / déclencheur** (« pourquoi ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000012', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Depuis ton passage au temps partiel, ton quotidien doit être très différent.
[Femme] Oh oui, complètement.
[Homme] Concrètement, qu''est-ce qui a changé pour toi ?
[Femme] ...

A. Pour passer plus de temps avec mes enfants.
B. J''ai désormais tous mes mercredis libres, et c''est précieux.
C. À cause d''un trajet devenu trop fatigant.
D. Avec l''accord de mon manager, qui a été compréhensif.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Depuis ton passage au temps partiel, ton quotidien doit être très différent.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oh oui, complètement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Concrètement, qu''est-ce qui a changé pour toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour passer plus de temps avec mes enfants.<break time="700ms"/>B.<break time="300ms"/>J''ai désormais tous mes mercredis libres, et c''est précieux.<break time="700ms"/>C.<break time="300ms"/>À cause d''un trajet devenu trop fatigant.<break time="700ms"/>D.<break time="300ms"/>Avec l''accord de mon manager, qui a été compréhensif.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le changement (passage au temps partiel) ; la question « qu''est-ce qui a changé pour toi ? » porte sur **la nature concrète du changement de rythme**. Seule B « j''ai désormais tous mes mercredis libres » décrit un changement concret. A donne **le but du passage au temps partiel** (« pour quoi faire ? »). C donne **la cause** (« pourquoi ce changement ? »). D donne **les conditions / accord obtenu** (« avec qui as-tu négocié ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000013', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Ton fils va avoir dix ans la semaine prochaine, non ?
[Homme] Oui, samedi exactement.
[Femme] Vous allez fêter ça comment, vous deux ?
[Homme] ...

A. Pour qu''il garde un souvenir vraiment unique.
B. Avec une douzaine de ses petits copains, surtout.
C. En passant la journée entière au parc d''attractions.
D. Chez nous, dans le jardin du fond.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton fils va avoir dix ans la semaine prochaine, non ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, samedi exactement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous allez fêter ça comment, vous deux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour qu''il garde un souvenir vraiment unique.<break time="700ms"/>B.<break time="300ms"/>Avec une douzaine de ses petits copains, surtout.<break time="700ms"/>C.<break time="300ms"/>En passant la journée entière au parc d''attractions.<break time="700ms"/>D.<break time="300ms"/>Chez nous, dans le jardin du fond.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent l''occasion (10 ans du fils samedi) ; la question « vous allez fêter ça comment ? » porte sur **la manière de célébrer**. Seule C « en passant la journée entière au parc d''attractions » (gérondif décrivant le mode) décrit comment. A donne **le but** (« pour quoi faire ? »). B donne **les invités** (« avec qui ? »). D donne **le lieu** (« où ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000014', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Moi, l''hiver, je le supporte vraiment de moins en moins.
[Femme] Et toi, du coup, tu préfères quelle saison et pourquoi ?
[Homme] ...

A. Pendant à peu près trois mois dans l''année.
B. Au bord de la mer, surtout en septembre.
C. Avec ma famille du sud, qui aime la chaleur.
D. L''automne, pour ses couleurs et sa douceur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Moi, l''hiver, je le supporte vraiment de moins en moins.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et toi, du coup, tu préfères quelle saison et pourquoi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant à peu près trois mois dans l''année.<break time="700ms"/>B.<break time="300ms"/>Au bord de la mer, surtout en septembre.<break time="700ms"/>C.<break time="300ms"/>Avec ma famille du sud, qui aime la chaleur.<break time="700ms"/>D.<break time="300ms"/>L''automne, pour ses couleurs et sa douceur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le premier tour pose le rejet de l''hiver ; la question « tu préfères quelle saison et pourquoi ? » attend **une saison nommée avec sa raison**. Seule D « l''automne, pour ses couleurs et sa douceur » répond aux deux volets. A donne **une durée de saison** (« combien de temps dure-t-elle ? »). B donne **un lieu et un moment** (« où, quand ? »). C donne **un accompagnement** (« avec qui ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000015', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as vécu à Lyon comme à Bordeaux, finalement.
[Homme] Oui, plusieurs années dans chacune.
[Femme] Alors, tu préfères laquelle, entre les deux ?
[Homme] ...

A. Bordeaux, sans hésiter, je m''y suis senti chez moi.
B. À cause du climat océanique, plus doux.
C. Pendant quatre années passionnantes là-bas.
D. Avec mes deux meilleurs amis de l''époque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as vécu à Lyon comme à Bordeaux, finalement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, plusieurs années dans chacune.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, tu préfères laquelle, entre les deux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Bordeaux, sans hésiter, je m''y suis senti chez moi.<break time="700ms"/>B.<break time="300ms"/>À cause du climat océanique, plus doux.<break time="700ms"/>C.<break time="300ms"/>Pendant quatre années passionnantes là-bas.<break time="700ms"/>D.<break time="300ms"/>Avec mes deux meilleurs amis de l''époque.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le choix binaire (Lyon vs Bordeaux) ; la question « tu préfères laquelle, entre les deux ? » attend **la désignation explicite d''une des deux villes**. Seule A « Bordeaux, sans hésiter » nomme la ville choisie. B donne **une raison possible** (« pourquoi ? ») mais ne désigne pas la ville. C donne **la durée passée dans une ville** (« combien de temps ? »). D donne **des accompagnants de l''époque** (« avec qui ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-3000-0000-000000000016', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez enfin fixé tous les détails du baptême de la petite ?
[Femme] Oui ! Et toi, tu sais où aura lieu la cérémonie ?
[Homme] ...

A. Avec une centaine d''invités de toute la famille.
B. Dans la petite chapelle du village de ses grands-parents.
C. Pour célébrer ses six mois en famille élargie.
D. Le dernier samedi de juin, normalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez enfin fixé tous les détails du baptême de la petite ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui ! Et toi, tu sais où aura lieu la cérémonie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une centaine d''invités de toute la famille.<break time="700ms"/>B.<break time="300ms"/>Dans la petite chapelle du village de ses grands-parents.<break time="700ms"/>C.<break time="300ms"/>Pour célébrer ses six mois en famille élargie.<break time="700ms"/>D.<break time="300ms"/>Le dernier samedi de juin, normalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le premier tour pose le contexte (baptême en préparation) ; la question retournée « tu sais où aura lieu la cérémonie ? » porte sur **le lieu de la cérémonie**. Seule B « dans la petite chapelle du village de ses grands-parents » désigne un lieu. A donne **le nombre d''invités** (« combien ? »). C donne **le motif / but** (« pour quoi faire ? »). D donne **la date** (« quand ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.375755+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000001', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu reviens enfin de ton premier voyage au Japon !
[Femme] Oui, c''était absolument incroyable.
[Homme] Qu''est-ce qui t''a le plus étonnée, là-bas ?
[Femme] ...

A. La propreté impeccable des rues, partout.
B. Pendant deux semaines pleines de découvertes.
C. Avec une amie passionnée de culture nippone.
D. À Tokyo et à Kyoto principalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens enfin de ton premier voyage au Japon !</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''était absolument incroyable.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus étonnée, là-bas ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La propreté impeccable des rues, partout.<break time="700ms"/>B.<break time="300ms"/>Pendant deux semaines pleines de découvertes.<break time="700ms"/>C.<break time="300ms"/>Avec une amie passionnée de culture nippone.<break time="700ms"/>D.<break time="300ms"/>À Tokyo et à Kyoto principalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''a le plus étonnée ? » porte sur **l''élément précis qui a provoqué l''étonnement** durant le voyage. Seule A « la propreté impeccable des rues » désigne un tel élément. B donne **la durée du séjour** (« combien de temps ? »). C donne **l''accompagnante** (« avec qui es-tu partie ? »). D donne **les lieux visités** (« où es-tu allée ? »). Piège B1 : tous les distracteurs restent cohérents avec un voyage au Japon mais aucun n''identifie ce qui a surpris.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000002', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] On annonce de la pluie tout le week-end. Tu fais quoi quand il pleut comme ça ?
[Femme] ...

A. Plutôt mal, je dois l''avouer.
B. Je regarde des films sous un plaid.
C. Pendant des heures, parfois.
D. Avec mes enfants si possible.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On annonce de la pluie tout le week-end. Tu fais quoi quand il pleut comme ça ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt mal, je dois l''avouer.<break time="700ms"/>B.<break time="300ms"/>Je regarde des films sous un plaid.<break time="700ms"/>C.<break time="300ms"/>Pendant des heures, parfois.<break time="700ms"/>D.<break time="300ms"/>Avec mes enfants si possible.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu fais quoi quand il pleut ? » porte sur **l''activité menée par temps de pluie**. Seule B « je regarde des films sous un plaid » nomme une activité concrète. A donne **une appréciation / un ressenti** (« comment supportes-tu la pluie ? »). C donne **une durée** (« combien de temps ? »). D donne **un accompagnement** (« avec qui ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000003', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Ton patron t''a annoncé que tu partais à l''étranger pour six mois.
[Homme] Oui, hier en fin de journée.
[Femme] Et tu as réagi comment, sur le moment ?
[Homme] ...

A. Vers dix-sept heures, environ.
B. À cause d''un nouveau gros contrat.
C. Avec un mélange d''excitation et d''angoisse.
D. Dans son bureau, en tête-à-tête.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Ton patron t''a annoncé que tu partais à l''étranger pour six mois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, hier en fin de journée.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as réagi comment, sur le moment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers dix-sept heures, environ.<break time="700ms"/>B.<break time="300ms"/>À cause d''un nouveau gros contrat.<break time="700ms"/>C.<break time="300ms"/>Avec un mélange d''excitation et d''angoisse.<break time="700ms"/>D.<break time="300ms"/>Dans son bureau, en tête-à-tête.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu as réagi comment, sur le moment ? » porte sur **la réaction émotionnelle** à la nouvelle. Seule C « avec un mélange d''excitation et d''angoisse » décrit un état émotionnel. A donne **le moment précis** (« à quelle heure ? »). B donne **la cause de la mission** (« pourquoi ce départ ? »). D donne **le lieu de l''annonce** (« où te l''a-t-il dit ? »). Piège B1 : la confusion classique entre réaction et cause de la décision.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000004', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu m''as dit que ta région avait une cuisine très riche.
[Femme] Oui, et j''en suis très fière.
[Homme] Et quel plat de chez toi tu préfères ?
[Femme] ...

A. Près de Lyon, dans le Beaujolais.
B. Pour les fêtes de famille, surtout.
C. Avec beaucoup d''herbes fraîches du jardin.
D. La quenelle de brochet, sans hésiter.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que ta région avait une cuisine très riche.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, et j''en suis très fière.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et quel plat de chez toi tu préfères ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Près de Lyon, dans le Beaujolais.<break time="700ms"/>B.<break time="300ms"/>Pour les fêtes de famille, surtout.<break time="700ms"/>C.<break time="300ms"/>Avec beaucoup d''herbes fraîches du jardin.<break time="700ms"/>D.<break time="300ms"/>La quenelle de brochet, sans hésiter.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel plat de chez toi tu préfères ? » porte sur **l''identification du plat favori**. Seule D « la quenelle de brochet » nomme un plat précis. A donne **la localisation de la région** (« où est-ce ? »). B donne **l''occasion de consommation** (« quand le mange-t-on ? »). C donne **un ingrédient / mode de préparation** (« avec quoi est-il fait ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000005', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as l''air enthousiaste ces derniers temps. Qu''as-tu découvert récemment ?
[Homme] ...

A. Un petit café littéraire dans mon quartier.
B. Plutôt par hasard, en me promenant.
C. Pendant ma pause déjeuner, souvent.
D. Avec un collègue qui m''a accompagné.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as l''air enthousiaste ces derniers temps. Qu''as-tu découvert récemment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un petit café littéraire dans mon quartier.<break time="700ms"/>B.<break time="300ms"/>Plutôt par hasard, en me promenant.<break time="700ms"/>C.<break time="300ms"/>Pendant ma pause déjeuner, souvent.<break time="700ms"/>D.<break time="300ms"/>Avec un collègue qui m''a accompagné.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''as-tu découvert récemment ? » porte sur **la nature de la découverte**, l''objet ou le lieu trouvé. Seule A « un petit café littéraire dans mon quartier » identifie ce qui a été découvert. B donne **la manière** (« comment l''as-tu trouvé ? »). C donne **le moment habituel** d''y aller (« quand ? »). D donne **l''accompagnant** (« avec qui ? »). Piège B1 : sans la voix Denise dernière, attention à la cohérence — ici, c''est bien Denise qui pose la seule question du dialogue.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000006', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] On a beaucoup parlé de modèles ce soir, dans notre groupe.
[Femme] Oui, le débat était passionnant.
[Homme] Et toi, qui t''inspire vraiment, au fond ?
[Femme] ...

A. Pour son courage et sa persévérance.
B. Ma grand-mère, sans aucune hésitation.
C. Dès que j''ai des décisions difficiles à prendre.
D. Pendant toute mon enfance, déjà.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On a beaucoup parlé de modèles ce soir, dans notre groupe.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, le débat était passionnant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et toi, qui t''inspire vraiment, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour son courage et sa persévérance.<break time="700ms"/>B.<break time="300ms"/>Ma grand-mère, sans aucune hésitation.<break time="700ms"/>C.<break time="300ms"/>Dès que j''ai des décisions difficiles à prendre.<break time="700ms"/>D.<break time="300ms"/>Pendant toute mon enfance, déjà.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qui t''inspire vraiment ? » porte sur **l''identité de la personne** inspirante. Seule B « ma grand-mère » désigne une personne. A donne **la raison de l''inspiration** (« pourquoi t''inspire-t-elle ? »). C donne **le moment où l''on pense à elle** (« quand penses-tu à elle ? »). D donne **la période où l''inspiration a commencé** (« depuis quand ? »). Piège B1 : A est très tentant car il prolonge l''idée mais ne nomme personne.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000007', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tes journées au bureau ont l''air bien remplies.
[Homme] Oui, je ne vois pas le temps passer.
[Femme] Et tu fais quoi en sortant du travail, en général ?
[Homme] ...

A. À cause de la fatigue accumulée.
B. Vers dix-neuf heures, le plus souvent.
C. Je passe à la salle de sport.
D. Avec deux collègues du même service.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tes journées au bureau ont l''air bien remplies.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je ne vois pas le temps passer.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu fais quoi en sortant du travail, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause de la fatigue accumulée.<break time="700ms"/>B.<break time="300ms"/>Vers dix-neuf heures, le plus souvent.<break time="700ms"/>C.<break time="300ms"/>Je passe à la salle de sport.<break time="700ms"/>D.<break time="300ms"/>Avec deux collègues du même service.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu fais quoi en sortant du travail ? » porte sur **l''activité post-bureau habituelle**. Seule C « je passe à la salle de sport » nomme une activité. A donne **une cause / motif** (« pourquoi rentrer ? »). B donne **l''heure de sortie** (« à quelle heure ? »). D donne **les accompagnants** (« avec qui ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000008', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Avec tout ce que tu portes en ce moment au boulot, tu gères ton stress comment ?
[Femme] ...

A. Pendant les périodes vraiment intenses.
B. À cause des délais toujours plus serrés.
C. Avec mon mari qui me soutient beaucoup.
D. En faisant de la méditation tous les matins.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec tout ce que tu portes en ce moment au boulot, tu gères ton stress comment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les périodes vraiment intenses.<break time="700ms"/>B.<break time="300ms"/>À cause des délais toujours plus serrés.<break time="700ms"/>C.<break time="300ms"/>Avec mon mari qui me soutient beaucoup.<break time="700ms"/>D.<break time="300ms"/>En faisant de la méditation tous les matins.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu gères ton stress comment ? » porte sur **la méthode employée** pour gérer le stress. Seule D « en faisant de la méditation tous les matins » (gérondif de moyen) décrit une méthode. A donne **le moment où le stress apparaît** (« quand est-il fort ? »). B donne **la cause du stress** (« pourquoi es-tu stressée ? »). C donne **le soutien reçu** (« avec qui en parles-tu ? »). Piège B1 : C est crédible (« qui aide ? ») mais ne décrit pas une technique de gestion.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000009', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu es toujours au courant de l''actualité, c''est impressionnant.
[Femme] Je suis assez curieuse, c''est vrai.
[Homme] Et tu t''informes où, en général ?
[Femme] ...

A. Sur le site du journal Le Monde, surtout.
B. Pendant ma pause de midi, généralement.
C. Pour rester active dans les débats.
D. Avec ma sœur qui adore en discuter.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu es toujours au courant de l''actualité, c''est impressionnant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Je suis assez curieuse, c''est vrai.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et tu t''informes où, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur le site du journal Le Monde, surtout.<break time="700ms"/>B.<break time="300ms"/>Pendant ma pause de midi, généralement.<break time="700ms"/>C.<break time="300ms"/>Pour rester active dans les débats.<break time="700ms"/>D.<break time="300ms"/>Avec ma sœur qui adore en discuter.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu t''informes où ? » porte sur **la source d''information consultée**. Seule A « sur le site du journal Le Monde » désigne une source. B donne **le moment** (« quand t''informes-tu ? »). C donne **le but** (« pourquoi t''informer ? »). D donne **l''accompagnant pour discuter** (« avec qui en parles-tu ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000a', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que tu visitais beaucoup de musées en voyage.
[Homme] Au moins deux par séjour, oui.
[Femme] Et tu préfères quel type de musée ?
[Homme] ...

A. Pour deux heures de visite à chaque fois.
B. Les musées d''histoire naturelle, de loin.
C. Avec un audioguide, c''est plus riche.
D. Surtout les samedis matin, peu fréquentés.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu visitais beaucoup de musées en voyage.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins deux par séjour, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu préfères quel type de musée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour deux heures de visite à chaque fois.<break time="700ms"/>B.<break time="300ms"/>Les musées d''histoire naturelle, de loin.<break time="700ms"/>C.<break time="300ms"/>Avec un audioguide, c''est plus riche.<break time="700ms"/>D.<break time="300ms"/>Surtout les samedis matin, peu fréquentés.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu préfères quel type de musée ? » porte sur **la catégorie de musée privilégiée**. Seule B « les musées d''histoire naturelle » nomme un type. A donne **la durée de visite** (« combien de temps ? »). C donne **la manière de visiter** (« comment ? »). D donne **le moment habituel** (« quand ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000b', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu sors souvent le soir avec tes amis ?
[Homme] Deux ou trois fois par semaine.
[Femme] Et quelle est ta sortie préférée ?
[Homme] ...

A. Plutôt vers vingt-deux heures, en général.
B. Avec mes amis d''enfance, fidèlement.
C. Le concert dans une petite salle intimiste.
D. Pour décompresser après une longue semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sors souvent le soir avec tes amis ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Deux ou trois fois par semaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle est ta sortie préférée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt vers vingt-deux heures, en général.<break time="700ms"/>B.<break time="300ms"/>Avec mes amis d''enfance, fidèlement.<break time="700ms"/>C.<break time="300ms"/>Le concert dans une petite salle intimiste.<break time="700ms"/>D.<break time="300ms"/>Pour décompresser après une longue semaine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle est ta sortie préférée ? » porte sur **le type de sortie favorite**. Seule C « le concert dans une petite salle intimiste » nomme un type d''activité de sortie. A donne **l''heure habituelle** (« à quelle heure sors-tu ? »). B donne **les accompagnants** (« avec qui ? »). D donne **le but** (« pourquoi sors-tu ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000c', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Ton anniversaire approche à grands pas, dis-moi.
[Femme] Oui, à la fin du mois.
[Homme] Quel cadeau te ferait vraiment plaisir, cette année ?
[Femme] ...

A. Pendant le grand week-end de mai.
B. Avec toute la famille réunie chez moi.
C. À la campagne, dans un endroit calme.
D. Un beau carnet de voyage en cuir.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ton anniversaire approche à grands pas, dis-moi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, à la fin du mois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel cadeau te ferait vraiment plaisir, cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant le grand week-end de mai.<break time="700ms"/>B.<break time="300ms"/>Avec toute la famille réunie chez moi.<break time="700ms"/>C.<break time="300ms"/>À la campagne, dans un endroit calme.<break time="700ms"/>D.<break time="300ms"/>Un beau carnet de voyage en cuir.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel cadeau te ferait vraiment plaisir ? » porte sur **la nature du cadeau souhaité**. Seule D « un beau carnet de voyage en cuir » nomme un objet. A donne **le moment de la fête** (« quand fêteras-tu ? »). B donne **les invités** (« avec qui ? »). C donne **le lieu** (« où fêteras-tu ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000d', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu lisais encore un guide de voyage, hier soir.
[Homme] J''adore préparer mes prochaines escapades.
[Femme] Quel voyage tu rêverais vraiment de faire ?
[Homme] ...

A. Une grande traversée de l''Amérique du Sud.
B. Pendant au moins trois bons mois.
C. Avec un sac à dos très léger.
D. Pour me sentir libre et déconnecté.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lisais encore un guide de voyage, hier soir.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''adore préparer mes prochaines escapades.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel voyage tu rêverais vraiment de faire ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une grande traversée de l''Amérique du Sud.<break time="700ms"/>B.<break time="300ms"/>Pendant au moins trois bons mois.<break time="700ms"/>C.<break time="300ms"/>Avec un sac à dos très léger.<break time="700ms"/>D.<break time="300ms"/>Pour me sentir libre et déconnecté.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel voyage tu rêverais de faire ? » porte sur **la nature / la destination du voyage rêvé**. Seule A « une grande traversée de l''Amérique du Sud » décrit un voyage précis. B donne **la durée envisagée** (« combien de temps ? »). C donne **les bagages** (« avec quoi voyagerais-tu ? »). D donne **le but / la motivation** (« pourquoi rêver de ce voyage ? »). Piège B1 : la voix Denise pose la question — c''est son tour final qui appelle la destination.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000e', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu sembles toujours bien organisée le matin. Tu as quelle astuce pour gagner du temps ?
[Femme] ...

A. Pendant les jours d''école, surtout.
B. Je prépare tout la veille au soir.
C. Pour être à l''heure au bureau.
D. Avec mes deux enfants, c''est nécessaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu sembles toujours bien organisée le matin. Tu as quelle astuce pour gagner du temps ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les jours d''école, surtout.<break time="700ms"/>B.<break time="300ms"/>Je prépare tout la veille au soir.<break time="700ms"/>C.<break time="300ms"/>Pour être à l''heure au bureau.<break time="700ms"/>D.<break time="300ms"/>Avec mes deux enfants, c''est nécessaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu as quelle astuce pour gagner du temps ? » porte sur **la stratégie concrète employée**. Seule B « je prépare tout la veille au soir » décrit une stratégie. A donne **le moment d''application** (« quand cela sert-il ? »). C donne **le but** (« pourquoi gagner du temps ? »). D donne **le contexte familial** (« avec qui dois-tu t''organiser ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-00000000000f', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as eu beaucoup de mentors dans ton parcours.
[Homme] Oui, et chacun m''a apporté quelque chose.
[Femme] Mais quel conseil tu retiens vraiment, parmi tous ?
[Homme] ...

A. Pendant mes années de stage, principalement.
B. Par mon premier maître de stage, à l''hôpital.
C. De toujours rester humble face à l''inconnu.
D. Avec une réelle bienveillance, à chaque fois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as eu beaucoup de mentors dans ton parcours.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, et chacun m''a apporté quelque chose.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais quel conseil tu retiens vraiment, parmi tous ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant mes années de stage, principalement.<break time="700ms"/>B.<break time="300ms"/>Par mon premier maître de stage, à l''hôpital.<break time="700ms"/>C.<break time="300ms"/>De toujours rester humble face à l''inconnu.<break time="700ms"/>D.<break time="300ms"/>Avec une réelle bienveillance, à chaque fois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel conseil tu retiens vraiment ? » porte sur **le contenu du conseil retenu**. Seule C « de toujours rester humble face à l''inconnu » formule un conseil. A donne **la période** où le conseil a été reçu (« quand ? »). B donne **l''auteur du conseil** (« par qui ? »). D donne **la manière dont les conseils étaient donnés** (« comment ? »). Piège B1 : confusion classique entre l''auteur d''un conseil (B) et le conseil lui-même (C).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000010', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tes gâteaux sont toujours moelleux à la perfection. Tu as une astuce pour réussir tes pâtes ?
[Femme] ...

A. Pendant les anniversaires, surtout.
B. Avec une vieille recette de ma mère.
C. Pour faire plaisir à tous mes invités.
D. J''ajoute toujours un yaourt nature.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tes gâteaux sont toujours moelleux à la perfection. Tu as une astuce pour réussir tes pâtes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les anniversaires, surtout.<break time="700ms"/>B.<break time="300ms"/>Avec une vieille recette de ma mère.<break time="700ms"/>C.<break time="300ms"/>Pour faire plaisir à tous mes invités.<break time="700ms"/>D.<break time="300ms"/>J''ajoute toujours un yaourt nature.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu as une astuce pour réussir tes pâtes ? » porte sur **le truc concret utilisé**. Seule D « j''ajoute toujours un yaourt nature » décrit une astuce. A donne **l''occasion de cuisiner** (« quand cuisines-tu ? »). B donne **l''origine de la recette** (« d''où vient ta recette ? »). C donne **le but** (« pourquoi cuisiner ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000011', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu fais beaucoup de sport, je crois.
[Homme] Plusieurs fois par semaine, oui.
[Femme] Tu préfères les sports en équipe ou plutôt individuels ?
[Homme] ...

A. Plutôt individuels, pour mon propre rythme.
B. Dans le club au bout de la rue.
C. Pour évacuer mon stress du bureau.
D. Avec quelques amis fidèles, parfois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu fais beaucoup de sport, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Plusieurs fois par semaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu préfères les sports en équipe ou plutôt individuels ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt individuels, pour mon propre rythme.<break time="700ms"/>B.<break time="300ms"/>Dans le club au bout de la rue.<break time="700ms"/>C.<break time="300ms"/>Pour évacuer mon stress du bureau.<break time="700ms"/>D.<break time="300ms"/>Avec quelques amis fidèles, parfois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question oppose deux catégories et appelle **un choix entre les deux**, avec sa justification. Seule A « plutôt individuels, pour mon propre rythme » désigne une des deux options et la motive. B donne **le lieu de pratique** (« où ? »). C donne **le but général du sport** (« pourquoi en faire ? »). D donne **les partenaires occasionnels** (« avec qui ? »). Piège B1 : D évoque des « amis », ce qui pourrait tromper sur un sport collectif, mais la question demande la préférence du locuteur.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000012', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que tu lisais énormément.
[Homme] Au moins un livre par semaine, oui.
[Femme] Et quel type de livre tu lis, en général ?
[Homme] ...

A. Pendant mes trajets en métro, surtout.
B. Des romans policiers contemporains.
C. À la médiathèque de mon quartier.
D. Pour m''évader un peu du quotidien.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu lisais énormément.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins un livre par semaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel type de livre tu lis, en général ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant mes trajets en métro, surtout.<break time="700ms"/>B.<break time="300ms"/>Des romans policiers contemporains.<break time="700ms"/>C.<break time="300ms"/>À la médiathèque de mon quartier.<break time="700ms"/>D.<break time="300ms"/>Pour m''évader un peu du quotidien.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel type de livre tu lis ? » porte sur **le genre littéraire**. Seule B « des romans policiers contemporains » nomme un genre. A donne **le moment de lecture** (« quand lis-tu ? »). C donne **le lieu où trouver les livres** (« où les empruntes-tu ? »). D donne **le but de la lecture** (« pourquoi lis-tu ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000013', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu lis beaucoup de littérature étrangère, on dirait.
[Homme] J''aime beaucoup voyager par les livres.
[Femme] Et quel auteur tu préfères, dans tout ça ?
[Homme] ...

A. Pour la beauté de son écriture, sincèrement.
B. Toujours en version originale anglaise.
C. Haruki Murakami, depuis des années.
D. Avec un grand café, le dimanche matin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu lis beaucoup de littérature étrangère, on dirait.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''aime beaucoup voyager par les livres.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel auteur tu préfères, dans tout ça ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour la beauté de son écriture, sincèrement.<break time="700ms"/>B.<break time="300ms"/>Toujours en version originale anglaise.<break time="700ms"/>C.<break time="300ms"/>Haruki Murakami, depuis des années.<break time="700ms"/>D.<break time="300ms"/>Avec un grand café, le dimanche matin.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel auteur tu préfères ? » porte sur **l''identité de l''écrivain favori**. Seule C « Haruki Murakami » nomme un auteur. A donne **la raison de la préférence** (« pourquoi l''aimes-tu ? »). B donne **la langue de lecture** (« comment le lis-tu ? »). D donne **les conditions de lecture** (« quand et avec quoi ? »). Piège B1 : A est très tentant car il prolonge l''idée mais ne nomme aucun auteur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000014', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as enfin terminé d''aménager ton nouvel appartement ?
[Femme] Oui, après des mois de travaux.
[Homme] Tu as choisi quel style de déco, finalement ?
[Femme] ...

A. Pendant tout le printemps dernier.
B. Avec l''aide d''une décoratrice professionnelle.
C. À Paris, dans un quartier très calme.
D. Un style scandinave, épuré et lumineux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as enfin terminé d''aménager ton nouvel appartement ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, après des mois de travaux.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as choisi quel style de déco, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant tout le printemps dernier.<break time="700ms"/>B.<break time="300ms"/>Avec l''aide d''une décoratrice professionnelle.<break time="700ms"/>C.<break time="300ms"/>À Paris, dans un quartier très calme.<break time="700ms"/>D.<break time="300ms"/>Un style scandinave, épuré et lumineux.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Tu as choisi quel style de déco ? » porte sur **le style décoratif retenu**. Seule D « un style scandinave, épuré et lumineux » désigne un style. A donne **la période des travaux** (« quand ? »). B donne **l''aide reçue** (« avec qui ? »). C donne **la localisation du logement** (« où ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000015', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as une longue liste de pays sur ta carte murale.
[Homme] Au moins une trentaine, oui.
[Femme] Mais quel pays tu voudrais visiter en priorité ?
[Homme] ...

A. L''Islande, vraiment depuis longtemps.
B. Pour découvrir des paysages extrêmes.
C. Pendant deux ou trois semaines pleines.
D. Avec un guide local, idéalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as une longue liste de pays sur ta carte murale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Au moins une trentaine, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais quel pays tu voudrais visiter en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''Islande, vraiment depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour découvrir des paysages extrêmes.<break time="700ms"/>C.<break time="300ms"/>Pendant deux ou trois semaines pleines.<break time="700ms"/>D.<break time="300ms"/>Avec un guide local, idéalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel pays tu voudrais visiter en priorité ? » porte sur **l''identification du pays prioritaire**. Seule A « l''Islande » nomme un pays. B donne **la motivation** (« pourquoi y aller ? »). C donne **la durée envisagée** (« combien de temps ? »). D donne **les conditions de visite** (« avec qui ? »). Piège B1 : B est souvent confondu avec A car il explique le choix mais ne le nomme pas.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL),

  ('66666666-00b1-4000-0000-000000000016', 'B1', 'co_dialogue_b1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] On parlait des objets dont on ne pourrait plus se passer. Et toi, quel objet t''est vraiment indispensable au quotidien ?
[Femme] ...

A. Pendant toute la journée, sans exception.
B. Mon petit carnet à spirale, toujours sur moi.
C. Avec mes proches, surtout en déplacement.
D. Pour ne rien oublier d''important.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">On parlait des objets dont on ne pourrait plus se passer. Et toi, quel objet t''est vraiment indispensable au quotidien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant toute la journée, sans exception.<break time="700ms"/>B.<break time="300ms"/>Mon petit carnet à spirale, toujours sur moi.<break time="700ms"/>C.<break time="300ms"/>Avec mes proches, surtout en déplacement.<break time="700ms"/>D.<break time="300ms"/>Pour ne rien oublier d''important.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel objet t''est indispensable au quotidien ? » porte sur **l''identification d''un objet précis**. Seule B « mon petit carnet à spirale » nomme un objet. A donne **la durée d''usage** (« quand l''utilises-tu ? »). C donne **les personnes associées** (« avec qui ? »). D donne **la fonction / le but** de l''objet (« pourquoi en as-tu besoin ? »). Piège B1 : D décrit l''utilité d''un tel objet sans le nommer, ce qui le rend crédible.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.390948+02', NULL, NULL, NULL);
