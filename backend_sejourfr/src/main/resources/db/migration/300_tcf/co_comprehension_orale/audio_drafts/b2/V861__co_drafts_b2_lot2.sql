-- ============================================================================
-- V487 — TCF CO : drafts audio B2 (lot 2)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2). Table audio_question_draft.
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-00b2-3000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] La réunion de ce matin avec l''équipe marketing s''est mal passée ?
[Homme] Vraiment très mal, oui.
[Femme] Tu m''avais pourtant dit que tout était calé d''avance.
[Homme] Je le pensais sincèrement.
[Femme] Alors, d''où vient réellement le désaccord ?
[Homme] ...

A. Vers la fin de la réunion, juste avant la pause.
B. Au sein d''une équipe pourtant très compétente.
C. D''une divergence profonde sur le ciblage des clients.
D. Avec une amertume qui risque de durer un moment.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">La réunion de ce matin avec l''équipe marketing s''est mal passée ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vraiment très mal, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''avais pourtant dit que tout était calé d''avance.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je le pensais sincèrement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Alors, d''où vient réellement le désaccord ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers la fin de la réunion, juste avant la pause.<break time="700ms"/>B.<break time="300ms"/>Au sein d''une équipe pourtant très compétente.<break time="700ms"/>C.<break time="300ms"/>D''une divergence profonde sur le ciblage des clients.<break time="700ms"/>D.<break time="300ms"/>Avec une amertume qui risque de durer un moment.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue insiste sur la surprise du conflit (tout semblait calé). « D''où vient réellement le désaccord ? » porte sur **l''origine substantielle du désaccord, son objet de fond**. Seule C « d''une divergence profonde sur le ciblage des clients » identifie cette source. A donne **le moment** où le désaccord est apparu dans la réunion (« quand ? »). B donne **le cadre humain** (« dans quelle équipe ? »). D donne **les conséquences émotionnelles** (« avec quelles séquelles ? ») — piège B2 fin : la préposition « de » au début de C reprend exactement la formulation « d''où vient », alors que la préposition « avec » de D suggère une simple circonstance.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] La négociation avec le syndicat semblait vraiment dans l''impasse, non ?
[Femme] On l''a pourtant débloquée jeudi en fin de soirée.
[Homme] Qu''est-ce qui a fait basculer la situation, alors ?
[Femme] ...

A. Vers vingt-trois heures, après des heures de discussion serrée.
B. Avec une satisfaction très partagée des deux côtés.
C. Au siège social, dans la grande salle du conseil.
D. L''arrivée inattendue du directeur général en personne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La négociation avec le syndicat semblait vraiment dans l''impasse, non ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On l''a pourtant débloquée jeudi en fin de soirée.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui a fait basculer la situation, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Vers vingt-trois heures, après des heures de discussion serrée.<break time="700ms"/>B.<break time="300ms"/>Avec une satisfaction très partagée des deux côtés.<break time="700ms"/>C.<break time="300ms"/>Au siège social, dans la grande salle du conseil.<break time="700ms"/>D.<break time="300ms"/>L''arrivée inattendue du directeur général en personne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui a fait basculer la situation ? » porte sur **l''élément précis qui a débloqué une impasse**. Seule D « l''arrivée inattendue du directeur général » identifie ce facteur de bascule. A donne **l''heure** du déblocage (« à quelle heure ? »). B donne **le climat** post-accord (« avec quel ressenti ? »). C donne **le lieu** de la négociation (« où ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu envisages sérieusement de te lancer dans cette reconversion en pâtisserie ?
[Homme] Oui, je n''attends presque plus que le bon moment.
[Femme] Quel est ton principal doute, alors, aujourd''hui ?
[Homme] ...

A. La viabilité économique à moyen terme, avant tout.
B. Pour vivre enfin d''une activité qui me passionne vraiment.
C. À l''école Ferrandi, dès septembre prochain, idéalement.
D. Avec un enthousiasme presque enfantin, je dois dire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu envisages sérieusement de te lancer dans cette reconversion en pâtisserie ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je n''attends presque plus que le bon moment.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel est ton principal doute, alors, aujourd''hui ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La viabilité économique à moyen terme, avant tout.<break time="700ms"/>B.<break time="300ms"/>Pour vivre enfin d''une activité qui me passionne vraiment.<break time="700ms"/>C.<break time="300ms"/>À l''école Ferrandi, dès septembre prochain, idéalement.<break time="700ms"/>D.<break time="300ms"/>Avec un enthousiasme presque enfantin, je dois dire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton principal doute ? » porte sur **l''inquiétude majeure, le point d''incertitude qui retient encore**. Seule A « la viabilité économique à moyen terme » formule un doute concret. B donne **la motivation** profonde (« pourquoi te lances-tu ? ») — piège B2 majeur : motivation et doute sont symétriques, l''un pousse, l''autre retient. C donne **le lieu et le moment** d''une éventuelle formation. D donne **l''état d''esprit positif** (« comment l''abordes-tu ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as vraiment changé de méthode de travail depuis cette formation ?
[Femme] Du tout au tout, on dirait une autre personne.
[Homme] Quel conseil a tout changé, finalement ?
[Femme] ...

A. Par l''intermédiaire d''une coach que je consulte depuis.
B. De toujours commencer par la tâche la plus ingrate.
C. Pour me sentir enfin pleinement maîtresse de mon temps.
D. Au tout début du printemps de l''année dernière, déjà.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as vraiment changé de méthode de travail depuis cette formation ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Du tout au tout, on dirait une autre personne.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel conseil a tout changé, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par l''intermédiaire d''une coach que je consulte depuis.<break time="700ms"/>B.<break time="300ms"/>De toujours commencer par la tâche la plus ingrate.<break time="700ms"/>C.<break time="300ms"/>Pour me sentir enfin pleinement maîtresse de mon temps.<break time="700ms"/>D.<break time="300ms"/>Au tout début du printemps de l''année dernière, déjà.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel conseil a tout changé ? » porte sur **le contenu du conseil reçu, sa formulation pratique**. Seule B « de toujours commencer par la tâche la plus ingrate » formule le conseil lui-même. A donne **la source** du conseil (« par qui ? ») — piège B2 majeur : on confond souvent le messager et le message. C donne **l''effet recherché** par l''application du conseil (« pour quel ressenti ? »). D donne **le moment** où le conseil a été reçu (« quand ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as adhéré à une association de protection du littoral récemment ?
[Homme] Oui, je viens à peine de signer ma carte.
[Femme] Et à quoi t''es-tu concrètement engagé, vis-à-vis d''eux ?
[Homme] ...

A. Auprès d''une association implantée depuis vingt ans en Bretagne.
B. À cause d''un attachement très ancien à la côte sud.
C. À donner deux week-ends par mois, pour aller sur le terrain.
D. Avec une conviction profonde de l''urgence climatique.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as adhéré à une association de protection du littoral récemment ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je viens à peine de signer ma carte.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et à quoi t''es-tu concrètement engagé, vis-à-vis d''eux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès d''une association implantée depuis vingt ans en Bretagne.<break time="700ms"/>B.<break time="300ms"/>À cause d''un attachement très ancien à la côte sud.<break time="700ms"/>C.<break time="300ms"/>À donner deux week-ends par mois, pour aller sur le terrain.<break time="700ms"/>D.<break time="300ms"/>Avec une conviction profonde de l''urgence climatique.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quoi t''es-tu engagé ? » porte sur **le contenu concret de l''engagement pris**. Seule C « à donner deux week-ends par mois » (préposition « à » + infinitif = objet de l''engagement) formule cet engagement. A donne **l''interlocuteur** (« auprès de qui ? »). B donne **la cause profonde** de l''adhésion (« pourquoi cette cause ? »). D donne **l''état d''esprit** (« dans quelle conviction ? ») — piège B2 fin : la préposition « à » de C reprend exactement celle de la question, alors que les autres options changent de structure.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu viens de prendre la direction de ce nouveau laboratoire, c''est cela ?
[Femme] Oui, j''ai officiellement pris mes fonctions lundi dernier.
[Homme] Quelle mission tu te fixes, eu égard à ce poste ?
[Femme] ...

A. Avec une vingtaine de doctorants à mes côtés, environ.
B. À l''Inserm, sur le campus de Villejuif, désormais.
C. Grâce à un financement européen récemment renouvelé.
D. Faire émerger une équipe de référence en cardiologie cellulaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu viens de prendre la direction de ce nouveau laboratoire, c''est cela ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai officiellement pris mes fonctions lundi dernier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle mission tu te fixes, eu égard à ce poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une vingtaine de doctorants à mes côtés, environ.<break time="700ms"/>B.<break time="300ms"/>À l''Inserm, sur le campus de Villejuif, désormais.<break time="700ms"/>C.<break time="300ms"/>Grâce à un financement européen récemment renouvelé.<break time="700ms"/>D.<break time="300ms"/>Faire émerger une équipe de référence en cardiologie cellulaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle mission tu te fixes ? » porte sur **l''objectif structurant que la personne s''assigne**. Seule D « faire émerger une équipe de référence » formule cette mission ambitieuse. A donne **les effectifs** disponibles (« avec qui ? »). B donne **le lieu** d''exercice (« où ? »). C donne **les moyens financiers** (« grâce à quoi ? ») — piège B2 fin : les moyens permettent la mission mais ne la définissent pas.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu prends ta retraite à la fin de l''année scolaire, c''est cela ?
[Homme] Oui, après quarante ans dans l''enseignement, c''est l''heure.
[Femme] Tu dois être un peu nostalgique, malgré tout.
[Homme] Énormément, oui.
[Femme] Et quelle trace tu aimerais laisser, au fond ?
[Homme] ...

A. Le souvenir d''un professeur qui croyait en chacun de ses élèves.
B. Au lycée Voltaire, où j''ai passé l''essentiel de ma carrière.
C. Dès la rentrée prochaine, pour mes premiers mois de retraite.
D. Avec une infinie reconnaissance envers mes collègues, surtout.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu prends ta retraite à la fin de l''année scolaire, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après quarante ans dans l''enseignement, c''est l''heure.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu dois être un peu nostalgique, malgré tout.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Énormément, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle trace tu aimerais laisser, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le souvenir d''un professeur qui croyait en chacun de ses élèves.<break time="700ms"/>B.<break time="300ms"/>Au lycée Voltaire, où j''ai passé l''essentiel de ma carrière.<break time="700ms"/>C.<break time="300ms"/>Dès la rentrée prochaine, pour mes premiers mois de retraite.<break time="700ms"/>D.<break time="300ms"/>Avec une infinie reconnaissance envers mes collègues, surtout.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue installe une fin de carrière chargée d''affect. « Quelle trace tu aimerais laisser ? » porte sur **l''empreinte symbolique souhaitée, le souvenir qu''on veut laisser de soi**. Seule A « le souvenir d''un professeur qui croyait en chacun » formule cette empreinte. B donne **le lieu** d''exercice (« où ? »). C donne **un moment** futur (« quand ? »). D donne **un sentiment personnel** de gratitude (« que ressens-tu envers eux ? ») — piège B2 majeur : D semble pertinente émotionnellement mais désigne la posture du locuteur, pas la trace laissée aux autres.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu rentres tout juste d''un reportage de plusieurs semaines en Mongolie ?
[Femme] Oui, j''ai retrouvé Paris hier dans la nuit.
[Homme] Quelle image te reste, par-dessus tout, de ce voyage ?
[Femme] ...

A. Ces troupeaux immenses se découpant à l''horizon, au crépuscule.
B. À cause d''un visa obtenu à la dernière minute, en juin.
C. Pour un magazine de reportages géopolitiques européen.
D. Avec une fatigue assez intense, je dois bien l''admettre.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu rentres tout juste d''un reportage de plusieurs semaines en Mongolie ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai retrouvé Paris hier dans la nuit.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle image te reste, par-dessus tout, de ce voyage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ces troupeaux immenses se découpant à l''horizon, au crépuscule.<break time="700ms"/>B.<break time="300ms"/>À cause d''un visa obtenu à la dernière minute, en juin.<break time="700ms"/>C.<break time="300ms"/>Pour un magazine de reportages géopolitiques européen.<break time="700ms"/>D.<break time="300ms"/>Avec une fatigue assez intense, je dois bien l''admettre.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle image te reste ? » porte sur **un souvenir visuel précis, sensoriel, qui marque durablement**. Seule A « ces troupeaux immenses se découpant à l''horizon » décrit une image. B donne **les conditions de départ** (« comment as-tu pu partir ? »). C donne **le commanditaire** du reportage (« pour qui ? »). D donne **l''état physique** au retour (« comment te sens-tu ? ») — piège B2 fin : C et D ressortent du même champ professionnel du reportage mais aucune ne décrit une image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as accepté ce poste très prenant à la direction internationale ?
[Homme] Oui, après mûre réflexion en famille.
[Femme] Et à quoi as-tu dû renoncer, en contrepartie ?
[Homme] ...

A. Au profit d''une rémunération nettement plus confortable.
B. Avec une joie mêlée d''appréhension, je l''avoue.
C. À mes soirées libres et à beaucoup de mes week-ends.
D. Pour assumer plus tôt mes responsabilités familiales.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as accepté ce poste très prenant à la direction internationale ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après mûre réflexion en famille.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et à quoi as-tu dû renoncer, en contrepartie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au profit d''une rémunération nettement plus confortable.<break time="700ms"/>B.<break time="300ms"/>Avec une joie mêlée d''appréhension, je l''avoue.<break time="700ms"/>C.<break time="300ms"/>À mes soirées libres et à beaucoup de mes week-ends.<break time="700ms"/>D.<break time="300ms"/>Pour assumer plus tôt mes responsabilités familiales.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quoi as-tu dû renoncer ? » porte sur **ce qui a été perdu, sacrifié**. Seule C « à mes soirées libres et à beaucoup de mes week-ends » (préposition « à » = objet du renoncement) désigne le sacrifice. A donne **la contrepartie obtenue** (« en échange de quoi ? ») — piège B2 majeur : la préposition « au profit de » dans A peut sembler proche d''un renoncement, mais elle nomme le gain, pas la perte. B donne **l''état émotionnel** lors de la décision. D donne **la motivation** d''acceptation (« pour quoi faire ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez du mal à vous mettre d''accord pour les vacances d''été ?
[Femme] On vise des choses très différentes, mon mari et moi.
[Homme] Quel compromis serait acceptable, à tes yeux ?
[Femme] ...

A. Auprès de mes beaux-parents, en Provence, comme souvent.
B. À cause d''une fatigue accumulée toute l''année par tous les deux.
C. Au mois d''août, dès la fermeture annuelle du cabinet.
D. Dix jours à la mer, suivis d''une semaine en montagne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez du mal à vous mettre d''accord pour les vacances d''été ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On vise des choses très différentes, mon mari et moi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quel compromis serait acceptable, à tes yeux ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès de mes beaux-parents, en Provence, comme souvent.<break time="700ms"/>B.<break time="300ms"/>À cause d''une fatigue accumulée toute l''année par tous les deux.<break time="700ms"/>C.<break time="300ms"/>Au mois d''août, dès la fermeture annuelle du cabinet.<break time="700ms"/>D.<break time="300ms"/>Dix jours à la mer, suivis d''une semaine en montagne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (envies divergentes dans le couple) cadre la question. « Quel compromis serait acceptable ? » porte sur **une solution intermédiaire combinant les attentes des deux parties**. Seule D « dix jours à la mer, suivis d''une semaine en montagne » formule un vrai compromis (deux univers combinés). A donne **le lieu** habituel d''hébergement. B donne **la cause** du besoin de vacances. C donne **le moment** du départ.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000015', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu reviens enfin d''Australie après cinq mois d''absence ?
[Homme] Oui, je suis rentré dimanche dernier, épuisé mais heureux.
[Femme] Et quelle promesse as-tu tenue, là-bas, finalement ?
[Homme] ...

A. D''aller me recueillir sur la tombe de mon grand-père, à Sydney.
B. Au bout de presque cinq mois loin de la maison, c''est long.
C. Avec une émotion qui m''a vraiment surpris sur place.
D. À cause d''un héritage familial qui me tenait à cœur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens enfin d''Australie après cinq mois d''absence ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis rentré dimanche dernier, épuisé mais heureux.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quelle promesse as-tu tenue, là-bas, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>D''aller me recueillir sur la tombe de mon grand-père, à Sydney.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque cinq mois loin de la maison, c''est long.<break time="700ms"/>C.<break time="300ms"/>Avec une émotion qui m''a vraiment surpris sur place.<break time="700ms"/>D.<break time="300ms"/>À cause d''un héritage familial qui me tenait à cœur.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle promesse as-tu tenue ? » porte sur **le contenu concret de l''engagement honoré**. Seule A « d''aller me recueillir sur la tombe de mon grand-père » formule la promesse elle-même (« promesse de + infinitif »). B donne **la durée** du séjour. C donne **l''état émotionnel** vécu sur place. D donne **la motivation profonde** du voyage (« pourquoi y es-tu allé ? ») — piège B2 majeur : motivation et promesse sont liées (on s''engage parce qu''on est motivé), mais l''une nomme la cause intérieure, l''autre l''acte verbal d''engagement.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000016', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu pilotes un projet à cheval sur trois pays, désormais ?
[Femme] Oui, depuis le début de l''année fiscale.
[Homme] Cela doit ajouter pas mal de coordination.
[Femme] Énormément, et pas toujours de la plus simple.
[Homme] Mais qu''est-ce qui est le plus complexe à gérer, au fond ?
[Femme] ...

A. À l''échelle de trois pays européens, oui, c''est cela.
B. La conciliation des fuseaux horaires, en réalité, plus que tout.
C. Pendant près de douze mois consécutifs, sans interruption.
D. Avec une équipe internationale d''une trentaine de personnes.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu pilotes un projet à cheval sur trois pays, désormais ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, depuis le début de l''année fiscale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cela doit ajouter pas mal de coordination.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Énormément, et pas toujours de la plus simple.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui est le plus complexe à gérer, au fond ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''échelle de trois pays européens, oui, c''est cela.<break time="700ms"/>B.<break time="300ms"/>La conciliation des fuseaux horaires, en réalité, plus que tout.<break time="700ms"/>C.<break time="300ms"/>Pendant près de douze mois consécutifs, sans interruption.<break time="700ms"/>D.<break time="300ms"/>Avec une équipe internationale d''une trentaine de personnes.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue cadre la complexité d''un projet multi-pays. « Qu''est-ce qui est le plus complexe à gérer ? » porte sur **la difficulté opérationnelle la plus aiguë**. Seule B « la conciliation des fuseaux horaires » identifie un problème concret de gestion. A donne le **périmètre géographique** (déjà mentionné dans le premier tour, donc redondant). C donne **la durée** prévue. D donne la **composition** de l''équipe — piège B2 fin : A, C, D décrivent toutes des caractéristiques du projet, mais seule B nomme une difficulté à gérer au quotidien.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu sais que les ventes ont chuté de quinze pour cent ce mois-ci ?
[Homme] Oui, c''est préoccupant.
[Femme] Qu''est-ce qui expliquerait ce recul, à ton avis ?
[Homme] ...

A. L''arrivée brutale d''un concurrent agressif sur le marché.
B. Pendant trois semaines consécutives, surtout.
C. Avec une baisse plus marquée chez les indépendants.
D. Pour relancer notre stratégie de marque ensuite.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais que les ventes ont chuté de quinze pour cent ce mois-ci ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est préoccupant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui expliquerait ce recul, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''arrivée brutale d''un concurrent agressif sur le marché.<break time="700ms"/>B.<break time="300ms"/>Pendant trois semaines consécutives, surtout.<break time="700ms"/>C.<break time="300ms"/>Avec une baisse plus marquée chez les indépendants.<break time="700ms"/>D.<break time="300ms"/>Pour relancer notre stratégie de marque ensuite.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui expliquerait ce recul ? » appelle **une hypothèse explicative, une cause vraisemblable**. Seule A « l''arrivée d''un concurrent agressif » formule une hypothèse causale. B donne la **période** du recul. C donne **le segment le plus touché**. D donne **une action future** (« pour relancer » = but post-constat), pas une explication.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu vas devoir négocier avec ton fournisseur principal ?
[Femme] Oui, lundi matin sans faute.
[Homme] Quelle marge de manœuvre tu te donnes, exactement ?
[Femme] ...

A. Au bout de deux mois de tensions accumulées.
B. Une réduction de cinq à huit pour cent, pas davantage.
C. Pour préserver notre relation à long terme.
D. Avec mon directeur financier en soutien.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu vas devoir négocier avec ton fournisseur principal ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, lundi matin sans faute.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle marge de manœuvre tu te donnes, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de deux mois de tensions accumulées.<break time="700ms"/>B.<break time="300ms"/>Une réduction de cinq à huit pour cent, pas davantage.<break time="700ms"/>C.<break time="300ms"/>Pour préserver notre relation à long terme.<break time="700ms"/>D.<break time="300ms"/>Avec mon directeur financier en soutien.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle marge de manœuvre tu te donnes ? » porte sur **les bornes chiffrées / l''amplitude de négociation envisagée**. Seule B « une réduction de cinq à huit pour cent » donne cette marge. A donne **le contexte temporel préalable**. C donne **le but supérieur** de la négociation. D donne **l''accompagnement**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Notre taux de désabonnement augmente régulièrement.
[Homme] C''est inquiétant pour le trimestre.
[Femme] Et concrètement, sur quoi peux-tu agir en priorité ?
[Homme] ...

A. À cause d''une concurrence devenue plus agressive.
B. Auprès de la direction commerciale uniquement.
C. Sur l''expérience d''onboarding, principalement.
D. Pour ramener le taux sous les cinq pour cent.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Notre taux de désabonnement augmente régulièrement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est inquiétant pour le trimestre.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et concrètement, sur quoi peux-tu agir en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une concurrence devenue plus agressive.<break time="700ms"/>B.<break time="300ms"/>Auprès de la direction commerciale uniquement.<break time="700ms"/>C.<break time="300ms"/>Sur l''expérience d''onboarding, principalement.<break time="700ms"/>D.<break time="300ms"/>Pour ramener le taux sous les cinq pour cent.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Sur quoi peux-tu agir en priorité ? » porte sur **le levier opérationnel mobilisable**. Seule C « sur l''expérience d''onboarding » désigne un levier concret. A donne **la cause du problème**. B donne **les interlocuteurs / les acteurs auprès desquels agir** (« auprès de qui ? »). D donne **l''objectif chiffré visé**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Je crois que Sophie ne se sent pas à l''aise dans son nouveau poste.
[Femme] Vraiment ? Elle n''en a pourtant rien dit.
[Homme] Justement. Qu''est-ce qui te fait penser ça, alors ?
[Femme] ...

A. Au bout d''un mois et demi de prise de fonction.
B. Pour pouvoir l''aider à se réorienter, peut-être.
C. Avec son ancien chef, qui me l''a confié récemment.
D. Une fatigue inhabituelle et des silences répétés.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je crois que Sophie ne se sent pas à l''aise dans son nouveau poste.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vraiment ? Elle n''en a pourtant rien dit.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement. Qu''est-ce qui te fait penser ça, alors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout d''un mois et demi de prise de fonction.<break time="700ms"/>B.<break time="300ms"/>Pour pouvoir l''aider à se réorienter, peut-être.<break time="700ms"/>C.<break time="300ms"/>Avec son ancien chef, qui me l''a confié récemment.<break time="700ms"/>D.<break time="300ms"/>Une fatigue inhabituelle et des silences répétés.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui te fait penser ça ? » porte sur **les indices observés qui fondent l''intuition**. Seule D « une fatigue inhabituelle et des silences répétés » liste ces indices. A donne **la durée écoulée dans le poste**. B donne **le but** de l''interrogation. C donne **la source d''une information rapportée** — piège B2 fin : C est une source possible (le « par qui je le sais »), mais la question demande les indices propres, pas l''origine d''une rumeur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as fini par accepter de passer au télétravail intégral ?
[Homme] Oui, après bien des hésitations.
[Femme] Quel argument t''a finalement convaincu ?
[Homme] ...

A. La perspective de récupérer deux heures de trajet par jour.
B. Pour une période d''essai de six mois seulement.
C. À condition de garder un bureau partagé en backup.
D. Avec l''accord express de mon manager direct.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par accepter de passer au télétravail intégral ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, après bien des hésitations.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel argument t''a finalement convaincu ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La perspective de récupérer deux heures de trajet par jour.<break time="700ms"/>B.<break time="300ms"/>Pour une période d''essai de six mois seulement.<break time="700ms"/>C.<break time="300ms"/>À condition de garder un bureau partagé en backup.<break time="700ms"/>D.<break time="300ms"/>Avec l''accord express de mon manager direct.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel argument t''a convaincu ? » porte sur **le bénéfice perçu qui a emporté la décision**. Seule A « la perspective de récupérer deux heures de trajet » désigne cet argument. B donne **la durée d''essai** (modalité, pas argument). C donne **une condition d''acceptation** (« sous quelles réserves ? »). D donne **une validation hiérarchique** (« qui a dû dire oui ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu vis seule dans cette nouvelle ville, je crois.
[Femme] Oui, depuis presque six mois maintenant.
[Homme] Qu''est-ce qui te manque le plus, finalement ?
[Femme] ...

A. À cause d''une mutation un peu brutale.
B. Les longues soirées partagées avec mes vieux amis.
C. Pour me rapprocher d''un projet professionnel.
D. Avec mes parents qui sont restés à Lyon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu vis seule dans cette nouvelle ville, je crois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, depuis presque six mois maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui te manque le plus, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une mutation un peu brutale.<break time="700ms"/>B.<break time="300ms"/>Les longues soirées partagées avec mes vieux amis.<break time="700ms"/>C.<break time="300ms"/>Pour me rapprocher d''un projet professionnel.<break time="700ms"/>D.<break time="300ms"/>Avec mes parents qui sont restés à Lyon.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui te manque le plus ? » porte sur **l''objet du manque, ce qui fait défaut au quotidien**. Seule B « les longues soirées partagées avec mes vieux amis » nomme ce manque. A donne **la cause du déménagement**. C donne **le but** du changement. D donne **les proches restés en arrière** — piège B2 : D évoque la famille éloignée, donc thématiquement proche du manque, mais ne nomme pas un manque vécu actuellement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu vas postuler à ce poste de directrice d''agence ?
[Homme] Oui, c''est une opportunité rare.
[Femme] Et selon toi, quel est ton principal atout face aux autres candidats ?
[Homme] ...

A. Pendant les six prochaines semaines d''évaluation.
B. Auprès d''un jury composé exclusivement de cadres seniors.
C. Une expérience de terrain peu commune dans ce secteur.
D. À l''approche d''un changement complet de carrière.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vas postuler à ce poste de directrice d''agence ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est une opportunité rare.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et selon toi, quel est ton principal atout face aux autres candidats ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant les six prochaines semaines d''évaluation.<break time="700ms"/>B.<break time="300ms"/>Auprès d''un jury composé exclusivement de cadres seniors.<break time="700ms"/>C.<break time="300ms"/>Une expérience de terrain peu commune dans ce secteur.<break time="700ms"/>D.<break time="300ms"/>À l''approche d''un changement complet de carrière.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est ton principal atout ? » porte sur **la qualité différenciante valorisée**. Seule C « une expérience de terrain peu commune » nomme un atout. A donne **la période d''évaluation**. B donne **les évaluateurs**. D donne **le contexte personnel** de la candidature.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as fait ton bilan de mi-année avec ton manager ?
[Femme] Oui, ce matin, c''était plutôt constructif.
[Homme] Quelle faiblesse il a identifiée chez toi, principalement ?
[Femme] ...

A. Au cours d''un entretien d''une heure et demie.
B. Pour viser une promotion à plus long terme.
C. Avec beaucoup de bienveillance, je dois dire.
D. Un manque de leadership dans les réunions élargies.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as fait ton bilan de mi-année avec ton manager ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ce matin, c''était plutôt constructif.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle faiblesse il a identifiée chez toi, principalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au cours d''un entretien d''une heure et demie.<break time="700ms"/>B.<break time="300ms"/>Pour viser une promotion à plus long terme.<break time="700ms"/>C.<break time="300ms"/>Avec beaucoup de bienveillance, je dois dire.<break time="700ms"/>D.<break time="300ms"/>Un manque de leadership dans les réunions élargies.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle faiblesse a-t-il identifiée ? » porte sur **le point faible précis pointé du doigt**. Seule D « un manque de leadership dans les réunions élargies » nomme cette faiblesse. A donne **la durée de l''entretien**. B donne **l''objectif** du bilan. C donne **la manière** dont la critique a été formulée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Le marché du livre numérique stagne, m''as-tu dit ?
[Homme] Oui, depuis deux ans environ.
[Femme] Comment cela va-t-il évoluer, selon les analystes ?
[Homme] ...

A. Une lente reprise tirée par les abonnements illimités.
B. À cause d''une saturation progressive du marché.
C. Pour relancer la lecture chez les jeunes adultes.
D. Auprès des éditeurs indépendants surtout.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le marché du livre numérique stagne, m''as-tu dit ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, depuis deux ans environ.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Comment cela va-t-il évoluer, selon les analystes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une lente reprise tirée par les abonnements illimités.<break time="700ms"/>B.<break time="300ms"/>À cause d''une saturation progressive du marché.<break time="700ms"/>C.<break time="300ms"/>Pour relancer la lecture chez les jeunes adultes.<break time="700ms"/>D.<break time="300ms"/>Auprès des éditeurs indépendants surtout.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment cela va-t-il évoluer ? » appelle **une projection / tendance future**. Seule A « une lente reprise tirée par les abonnements illimités » décrit cette évolution. B donne **la cause de la stagnation actuelle**. C donne **un but de relance**. D donne **un segment d''acteurs concernés**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez réussi à boucler ce dossier complexe ?
[Femme] Oui, mais ça n''a pas été sans mal.
[Homme] Qui a joué le rôle clé dans la résolution, finalement ?
[Femme] ...

A. Au bout de trois mois de négociations difficiles.
B. Notre juriste interne, vraiment décisive.
C. Pour éviter un contentieux long et coûteux.
D. Avec un budget largement dépassé, malheureusement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez réussi à boucler ce dossier complexe ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, mais ça n''a pas été sans mal.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui a joué le rôle clé dans la résolution, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de trois mois de négociations difficiles.<break time="700ms"/>B.<break time="300ms"/>Notre juriste interne, vraiment décisive.<break time="700ms"/>C.<break time="300ms"/>Pour éviter un contentieux long et coûteux.<break time="700ms"/>D.<break time="300ms"/>Avec un budget largement dépassé, malheureusement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qui a joué le rôle clé ? » porte sur **l''acteur décisif**. Seule B « notre juriste interne » désigne cette personne. A donne **la durée du processus**. C donne **le but / l''enjeu évité**. D donne **une conséquence budgétaire**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que ta vie professionnelle avait basculé un jour précis.
[Homme] Oui, c''est lié à une rencontre, en fait.
[Femme] Quel a été ce tournant, exactement ?
[Homme] ...

A. À cause d''une frustration accumulée depuis longtemps.
B. Pour mieux concilier vie pro et vie privée, finalement.
C. Une proposition de mission à l''étranger, totalement inattendue.
D. Avec mon ancienne associée, dont je me suis séparée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que ta vie professionnelle avait basculé un jour précis.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''est lié à une rencontre, en fait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quel a été ce tournant, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une frustration accumulée depuis longtemps.<break time="700ms"/>B.<break time="300ms"/>Pour mieux concilier vie pro et vie privée, finalement.<break time="700ms"/>C.<break time="300ms"/>Une proposition de mission à l''étranger, totalement inattendue.<break time="700ms"/>D.<break time="300ms"/>Avec mon ancienne associée, dont je me suis séparée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel a été ce tournant ? » porte sur **l''événement précis qui a marqué la bascule**. Seule C « une proposition de mission à l''étranger » désigne cet événement. A donne **la cause préalable** (l''insatisfaction). B donne **le but général** de la vie post-tournant. D donne **une autre transformation parallèle** (séparation), pas le tournant principal évoqué.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez lancé le produit en juin, comme prévu ?
[Femme] Oui, dans un calendrier impeccable.
[Homme] Et avec le recul, quel risque aviez-vous sous-estimé ?
[Femme] ...

A. Pour une cible un peu plus large que prévu initialement.
B. Au cours de réunions hebdomadaires pourtant rigoureuses.
C. La capacité de notre support à absorber la demande.
D. Avec un investissement très conséquent, pourtant.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez lancé le produit en juin, comme prévu ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, dans un calendrier impeccable.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et avec le recul, quel risque aviez-vous sous-estimé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour une cible un peu plus large que prévu initialement.<break time="700ms"/>B.<break time="300ms"/>Au cours de réunions hebdomadaires pourtant rigoureuses.<break time="700ms"/>C.<break time="300ms"/>La capacité de notre support à absorber la demande.<break time="700ms"/>D.<break time="300ms"/>Avec un investissement très conséquent, pourtant.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel risque aviez-vous sous-estimé ? » porte sur **un point précis mal évalué à l''avance**. Seule C « la capacité de notre support à absorber la demande » désigne ce risque. A donne **une modification de cible**. B donne **le cadre de préparation** (« où en avez-vous parlé ? »). D donne **l''effort financier déployé**, pas un risque.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as terminé ta thèse il y a un an, je crois.
[Homme] Oui, ça paraît loin déjà.
[Femme] Avec le recul, qu''est-ce que tu regrettes le plus dans ce parcours ?
[Homme] ...

A. De ne pas avoir pris davantage de pauses véritables.
B. À la suite d''une soutenance brillante, pourtant.
C. Pour me consacrer enfin à un projet personnel.
D. Avec une directrice de thèse extrêmement présente.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as terminé ta thèse il y a un an, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, ça paraît loin déjà.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec le recul, qu''est-ce que tu regrettes le plus dans ce parcours ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>De ne pas avoir pris davantage de pauses véritables.<break time="700ms"/>B.<break time="300ms"/>À la suite d''une soutenance brillante, pourtant.<break time="700ms"/>C.<break time="300ms"/>Pour me consacrer enfin à un projet personnel.<break time="700ms"/>D.<break time="300ms"/>Avec une directrice de thèse extrêmement présente.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que tu regrettes le plus ? » porte sur **un manquement / une chose qu''on aurait voulu faire autrement**. Seule A « de ne pas avoir pris davantage de pauses » formule ce regret (négation utile). B donne **un fait positif** (la soutenance réussie) qui contredit toute idée de regret. C donne **un but post-thèse**. D donne **un atout** du parcours, pas un regret.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez vendu la maison de famille, finalement ?
[Femme] Oui, l''été dernier, ça a été un déchirement.
[Homme] Et qu''est-ce qui t''a le plus surprise, après coup ?
[Femme] ...

A. Au bout de trois mois de négociations avec les acquéreurs.
B. Le soulagement immédiat ressenti, en réalité.
C. Pour pouvoir investir dans un nouveau projet collectif.
D. Avec mes frères et sœurs, dans la concorde.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez vendu la maison de famille, finalement ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, l''été dernier, ça a été un déchirement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''est-ce qui t''a le plus surprise, après coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de trois mois de négociations avec les acquéreurs.<break time="700ms"/>B.<break time="300ms"/>Le soulagement immédiat ressenti, en réalité.<break time="700ms"/>C.<break time="300ms"/>Pour pouvoir investir dans un nouveau projet collectif.<break time="700ms"/>D.<break time="300ms"/>Avec mes frères et sœurs, dans la concorde.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''a le plus surprise après coup ? » porte sur **un effet inattendu vécu a posteriori**. Seule B « le soulagement immédiat ressenti » désigne cet effet contre-intuitif (par contraste avec « déchirement » du tour précédent). A donne **la durée du processus**. C donne **le but** de la vente. D donne **l''entente familiale** durant la vente, pas une surprise rétrospective.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as bouclé l''audit du département financier ?
[Homme] Globalement oui, mais pas totalement.
[Femme] Qu''est-ce qui reste à éclaircir, à ce stade ?
[Homme] ...

A. Pendant deux semaines supplémentaires si nécessaire.
B. Avec l''aide d''un consultant indépendant.
C. Le mode de calcul des bonus de l''an dernier.
D. Pour rassurer pleinement le comité de direction.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as bouclé l''audit du département financier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Globalement oui, mais pas totalement.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui reste à éclaircir, à ce stade ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant deux semaines supplémentaires si nécessaire.<break time="700ms"/>B.<break time="300ms"/>Avec l''aide d''un consultant indépendant.<break time="700ms"/>C.<break time="300ms"/>Le mode de calcul des bonus de l''an dernier.<break time="700ms"/>D.<break time="300ms"/>Pour rassurer pleinement le comité de direction.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui reste à éclaircir ? » porte sur **le point précis encore en suspens**. Seule C « le mode de calcul des bonus de l''an dernier » identifie cette zone d''ombre. A donne **le délai restant**. B donne **l''aide envisagée pour avancer**. D donne **le but final** de l''éclaircissement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu m''as dit que tu interrogeais la frontière entre persuasion et manipulation, dans ton travail.
[Femme] Oui, c''est un sujet qui me tient à cœur.
[Homme] Et concrètement, où places-tu la limite, toi ?
[Femme] ...

A. À partir du moment où l''autre n''a plus le choix réel.
B. Au cours de mes formations en management.
C. Avec une équipe particulièrement réceptive au sujet.
D. Pour préserver une culture de confiance durable.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu m''as dit que tu interrogeais la frontière entre persuasion et manipulation, dans ton travail.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est un sujet qui me tient à cœur.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et concrètement, où places-tu la limite, toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir du moment où l''autre n''a plus le choix réel.<break time="700ms"/>B.<break time="300ms"/>Au cours de mes formations en management.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe particulièrement réceptive au sujet.<break time="700ms"/>D.<break time="300ms"/>Pour préserver une culture de confiance durable.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Où places-tu la limite ? » porte sur **le critère qui sépare l''acceptable de l''inacceptable**. Seule A « à partir du moment où l''autre n''a plus le choix réel » formule ce critère. B donne **le cadre où s''exprime la réflexion**. C donne **l''auditoire de cette réflexion**. D donne **l''objectif** qui motive de poser une limite.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as fini par créer ton entreprise il y a six mois ?
[Homme] Oui, et le démarrage a été plus rude que prévu.
[Femme] Qu''est-ce qui t''a le plus freiné, de manière inattendue ?
[Homme] ...

A. Au début du printemps, en pleine optimisme.
B. Pour me prouver à moi-même que j''en étais capable.
C. Avec une associée que je connais depuis vingt ans.
D. La lenteur des démarches administratives, vraiment.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par créer ton entreprise il y a six mois ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, et le démarrage a été plus rude que prévu.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus freiné, de manière inattendue ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au début du printemps, en pleine optimisme.<break time="700ms"/>B.<break time="300ms"/>Pour me prouver à moi-même que j''en étais capable.<break time="700ms"/>C.<break time="300ms"/>Avec une associée que je connais depuis vingt ans.<break time="700ms"/>D.<break time="300ms"/>La lenteur des démarches administratives, vraiment.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''a freiné de manière inattendue ? » porte sur **un obstacle non anticipé**. Seule D « la lenteur des démarches administratives » désigne cet obstacle. A donne **le moment du démarrage**. B donne **la motivation initiale**. C donne **l''accompagnement** par l''associée.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Cette mission à l''étranger t''a beaucoup transformée, on dirait.
[Femme] Plus que je ne l''avais imaginé, oui.
[Homme] Et qu''as-tu appris, presque sans le vouloir ?
[Femme] ...

A. À cause d''une équipe particulièrement exigeante.
B. Une humilité nouvelle face à la complexité culturelle.
C. Au cœur de l''Asie du Sud-Est, comme tu sais.
D. Pour me préparer à un poste de direction, plus tard.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cette mission à l''étranger t''a beaucoup transformée, on dirait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Plus que je ne l''avais imaginé, oui.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''as-tu appris, presque sans le vouloir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''une équipe particulièrement exigeante.<break time="700ms"/>B.<break time="300ms"/>Une humilité nouvelle face à la complexité culturelle.<break time="700ms"/>C.<break time="300ms"/>Au cœur de l''Asie du Sud-Est, comme tu sais.<break time="700ms"/>D.<break time="300ms"/>Pour me préparer à un poste de direction, plus tard.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''as-tu appris presque sans le vouloir ? » porte sur **l''acquis non planifié, le résultat humain de l''expérience**. Seule B « une humilité nouvelle face à la complexité culturelle » nomme cet apprentissage. A donne **la cause de la transformation**. C donne **le lieu** de la mission. D donne **le but** de la mission (carrière), pas un apprentissage involontaire.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que tu connaissais Mathilde depuis des années.
[Homme] Oui, presque quinze ans en fait.
[Femme] Et comment vous vous êtes rencontrés, à l''époque ?
[Homme] ...

A. Pour collaborer sur un projet d''écriture, à l''origine.
B. Avec beaucoup d''enthousiasme dès le premier soir.
C. À l''occasion d''une résidence d''écriture en Bretagne.
D. Auprès d''un éditeur parisien qui nous a tous deux publiés.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tu connaissais Mathilde depuis des années.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, presque quinze ans en fait.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et comment vous vous êtes rencontrés, à l''époque ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour collaborer sur un projet d''écriture, à l''origine.<break time="700ms"/>B.<break time="300ms"/>Avec beaucoup d''enthousiasme dès le premier soir.<break time="700ms"/>C.<break time="300ms"/>À l''occasion d''une résidence d''écriture en Bretagne.<break time="700ms"/>D.<break time="300ms"/>Auprès d''un éditeur parisien qui nous a tous deux publiés.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment vous vous êtes rencontrés ? » porte sur **les circonstances / l''occasion de la rencontre**. Seule C « à l''occasion d''une résidence d''écriture en Bretagne » désigne ces circonstances. A donne **un but / une finalité** ultérieure. B donne **la manière** dont la relation a démarré sur le plan affectif (pas le contexte factuel). D donne **un intermédiaire / cadre professionnel** lié, mais ce n''est pas l''occasion de la première rencontre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00b2-4000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as quitté ton ancien employeur en très bons termes ?
[Femme] Oui, complètement.
[Homme] Et qu''est-ce qui t''amènerait à y revenir, un jour ?
[Femme] ...

A. Au bout de plusieurs années d''expérience ailleurs.
B. Pour retrouver une équipe que j''appréciais beaucoup.
C. Avec l''accord express de mon employeur actuel.
D. La création d''un poste vraiment stratégique pour moi.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as quitté ton ancien employeur en très bons termes ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, complètement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et qu''est-ce qui t''amènerait à y revenir, un jour ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au bout de plusieurs années d''expérience ailleurs.<break time="700ms"/>B.<break time="300ms"/>Pour retrouver une équipe que j''appréciais beaucoup.<break time="700ms"/>C.<break time="300ms"/>Avec l''accord express de mon employeur actuel.<break time="700ms"/>D.<break time="300ms"/>La création d''un poste vraiment stratégique pour moi.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''amènerait à y revenir ? » porte sur **la condition / l''événement déclencheur d''un retour**. Seule D « la création d''un poste vraiment stratégique pour moi » désigne cette condition concrète. A donne **un délai préalable nécessaire**. B donne **une motivation affective générale** (« pourquoi y reviendrais-tu sentimentalement ? »), pas un événement déclencheur. C donne **une validation pratique** (accord employeur actuel), modalité et non déclencheur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.422156+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000001', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu dis que ce que tu fais relève de la médiation, pas de la négociation. La distinction me semble subtile.
[Femme] Et pourtant, dans ma pratique quotidienne, elle est fondamentale.
[Homme] Vraiment ? Tout le monde tend pourtant à confondre les deux.
[Femme] À tort. En quoi est-ce subtilement différent, selon toi ?
[Homme] ...

A. Le médiateur ne défend aucune partie, il restaure un dialogue ; le négociateur, lui, arrache un accord.
B. Sous couvert de neutralité, le médiateur impose en réalité ses propres vues.
C. À l''aune des conventions internationales, la médiation a vu son cadre se durcir.
D. Moyennant une formation longue, on peut basculer d''un métier à l''autre sans grande difficulté.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu dis que ce que tu fais relève de la médiation, pas de la négociation. La distinction me semble subtile.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et pourtant, dans ma pratique quotidienne, elle est fondamentale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vraiment ? Tout le monde tend pourtant à confondre les deux.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">À tort. En quoi est-ce subtilement différent, selon toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le médiateur ne défend aucune partie, il restaure un dialogue ; le négociateur, lui, arrache un accord.<break time="700ms"/>B.<break time="300ms"/>Sous couvert de neutralité, le médiateur impose en réalité ses propres vues.<break time="700ms"/>C.<break time="300ms"/>À l''aune des conventions internationales, la médiation a vu son cadre se durcir.<break time="700ms"/>D.<break time="300ms"/>Moyennant une formation longue, on peut basculer d''un métier à l''autre sans grande difficulté.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le contraste médiation/négociation que l''interlocuteur juge subtil ; le troisième en renforce la confusion ordinaire ; la question finale (« en quoi est-ce subtilement différent ? ») demande **la nuance opératoire fine entre les deux notions**. Seule A formule cette nuance pragmatique exacte : finalité (restaurer un dialogue vs arracher un accord) et posture (neutre vs partisane). B fait un **procès d''intention** au médiateur (« sous couvert de neutralité... ») et répond à « qu''est-ce qu''on peut reprocher à la médiation ? ». C donne **un cadre juridique évolutif** (« comment le droit a-t-il fait évoluer la médiation ? »). D évoque la **passerelle professionnelle** entre les deux métiers (« peut-on passer de l''un à l''autre ? ») — piège fin C1 car elle accepte implicitement la distinction sans la définir.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000002', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Les chiffres du bénévolat n''ont jamais été aussi élevés dans la région.
[Homme] Étonnant, dans une période où chacun se replie sur soi.
[Femme] Justement, c''est ce qui m''intrigue : on n''a jamais autant dénoncé l''individualisme, et pourtant les associations ne désemplissent pas.
[Homme] Où est le paradoxe, exactement ?
[Femme] ...

A. Le bénévolat finit par essouffler ceux qui s''y dévouent trop longtemps.
B. On déplore un repli généralisé là même où, en pratique, les gens s''engagent comme jamais pour autrui.
C. Les jeunes générations se montrent plus engagées que leurs aînés ne le furent à leur âge.
D. Les associations souffrent malgré tout d''un manque chronique de financements publics.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Les chiffres du bénévolat n''ont jamais été aussi élevés dans la région.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Étonnant, dans une période où chacun se replie sur soi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Justement, c''est ce qui m''intrigue : on n''a jamais autant dénoncé l''individualisme, et pourtant les associations ne désemplissent pas.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où est le paradoxe, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le bénévolat finit par essouffler ceux qui s''y dévouent trop longtemps.<break time="700ms"/>B.<break time="300ms"/>On déplore un repli généralisé là même où, en pratique, les gens s''engagent comme jamais pour autrui.<break time="700ms"/>C.<break time="300ms"/>Les jeunes générations se montrent plus engagées que leurs aînés ne le furent à leur âge.<break time="700ms"/>D.<break time="300ms"/>Les associations souffrent malgré tout d''un manque chronique de financements publics.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue construit en quatre tours une tension entre **discours dominant** (individualisme déploré) et **réalité observée** (bénévolat record). La question « où est le paradoxe ? » demande **l''identification précise de la contradiction logique entre les deux faits intégrés**. Seule B reformule cette tension exacte (déplorer le repli ≠ observer l''engagement effectif). A énonce **une limite du bénévolat** (« quel risque court le bénévole ? »). C apporte **une nuance générationnelle** (« qui s''engage le plus ? ») — piège C1 fin car elle aussi semble paradoxale, mais elle ne porte pas sur la même opposition. D dénonce **un déficit structurel** (« de quoi souffrent les associations ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000003', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] J''ai dîné chez les parents de Camille hier soir.
[Femme] Et tu as réussi à leur parler de votre projet de mariage ?
[Homme] Pas vraiment. Sa mère a longuement insisté pour que je reprenne du dessert, son père m''a resservi du vin trois fois.
[Femme] Et tu en as conclu quelque chose ? Qu''est-ce qu''on comprend sans le dire, dans ce genre de soirée ?
[Homme] ...

A. Qu''ils trouvent l''occasion encore trop précoce pour aborder un sujet aussi sérieux.
B. Qu''ils manquent cruellement de sujets de conversation avec un futur gendre.
C. Qu''ils m''acceptent dans la famille sans avoir besoin de le formuler explicitement.
D. Qu''ils cherchent à me mettre à l''épreuve par un excès de prévenance feinte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai dîné chez les parents de Camille hier soir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu as réussi à leur parler de votre projet de mariage ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pas vraiment. Sa mère a longuement insisté pour que je reprenne du dessert, son père m''a resservi du vin trois fois.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et tu en as conclu quelque chose ? Qu''est-ce qu''on comprend sans le dire, dans ce genre de soirée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''ils trouvent l''occasion encore trop précoce pour aborder un sujet aussi sérieux.<break time="700ms"/>B.<break time="300ms"/>Qu''ils manquent cruellement de sujets de conversation avec un futur gendre.<break time="700ms"/>C.<break time="300ms"/>Qu''ils m''acceptent dans la famille sans avoir besoin de le formuler explicitement.<break time="700ms"/>D.<break time="300ms"/>Qu''ils cherchent à me mettre à l''épreuve par un excès de prévenance feinte.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue cumule deux informations clés : le sujet du mariage n''a **pas** été abordé verbalement, **mais** l''hôte a multiplié les gestes d''hospitalité. La question « qu''est-ce qu''on comprend sans le dire ? » demande **le contenu de l''implicite culturel français porté par ces gestes d''accueil**. Seule C lit correctement ces gestes comme un signe tacite d''adoption. A propose **une explication évitante** (« pourquoi le sujet n''a-t-il pas été abordé ? ») — distracteur très proche car cohérent avec « pas vraiment ». B donne **une explication psychologisante triviale**. D bascule dans **une lecture défiante** (« et si c''était une mise à l''épreuve ? »), interprétation possible mais qui contredit la dimension chaleureuse des gestes.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000004', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Le directeur a conclu ton entretien annuel par une formule étrange.
[Homme] Oui, il m''a dit : « Vos qualités finiront par être reconnues, à leur juste mesure. »
[Femme] Sur le moment, tu as souri poliment, mais tu as l''air contrarié maintenant.
[Homme] Plus j''y repense, plus je m''interroge. Qu''est-ce qu''il faut entendre derrière ces mots, à ton avis ?
[Femme] ...

A. Qu''il faut prendre cette phrase pour ce qu''elle est : un compliment maladroitement formulé.
B. Qu''il prépare en réalité une promotion imminente pour toi.
C. Qu''il souligne discrètement ton manque d''autorité face à l''équipe.
D. Qu''à ses yeux, ta reconnaissance attendra encore, sans qu''il s''en sente responsable.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Le directeur a conclu ton entretien annuel par une formule étrange.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, il m''a dit : « Vos qualités finiront par être reconnues, à leur juste mesure. »</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sur le moment, tu as souri poliment, mais tu as l''air contrarié maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Plus j''y repense, plus je m''interroge. Qu''est-ce qu''il faut entendre derrière ces mots, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Qu''il faut prendre cette phrase pour ce qu''elle est : un compliment maladroitement formulé.<break time="700ms"/>B.<break time="300ms"/>Qu''il prépare en réalité une promotion imminente pour toi.<break time="700ms"/>C.<break time="300ms"/>Qu''il souligne discrètement ton manque d''autorité face à l''équipe.<break time="700ms"/>D.<break time="300ms"/>Qu''à ses yeux, ta reconnaissance attendra encore, sans qu''il s''en sente responsable.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue isole la formule « finiront par être reconnues » (futur indéterminé) et « à leur juste mesure » (jugement implicite sur la valeur réelle des qualités) ; le tour 3 souligne que l''homme, après réflexion, s''en inquiète. La question « qu''est-ce qu''il faut entendre derrière ces mots ? » exige **le décodage de ce non-dit hiérarchique**. Seule D restitue la lecture pragmatique : promesse différée + déresponsabilisation du locuteur. A propose une **lecture naïve** qui ignore la contrariété du tour 3. B sur-interprète **dans le sens positif inverse** (« promotion imminente »), pas étayé. C glisse vers **un autre type de reproche** (manque d''autorité) qui n''est pas dans la formule.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000005', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] La direction propose de revoir l''organigramme pour « simplifier les circuits de décision ».
[Femme] On nous l''a déjà servie, celle-là, il y a trois ans.
[Homme] Cette fois, ils invoquent l''agilité et l''efficacité.
[Femme] Bien sûr. Mais derrière le vocabulaire choisi, qu''est-ce qui se joue vraiment, au-delà du visible ?
[Homme] ...

A. Une recentralisation discrète du pouvoir au sommet, sous couvert de fluidification.
B. Une simplification authentique des processus, attendue de longue date.
C. Une volonté affichée d''ouvrir davantage de postes à responsabilité.
D. Une réponse mesurée à la pression des actionnaires sur les coûts fixes.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">La direction propose de revoir l''organigramme pour « simplifier les circuits de décision ».</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">On nous l''a déjà servie, celle-là, il y a trois ans.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Cette fois, ils invoquent l''agilité et l''efficacité.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bien sûr. Mais derrière le vocabulaire choisi, qu''est-ce qui se joue vraiment, au-delà du visible ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une recentralisation discrète du pouvoir au sommet, sous couvert de fluidification.<break time="700ms"/>B.<break time="300ms"/>Une simplification authentique des processus, attendue de longue date.<break time="700ms"/>C.<break time="300ms"/>Une volonté affichée d''ouvrir davantage de postes à responsabilité.<break time="700ms"/>D.<break time="300ms"/>Une réponse mesurée à la pression des actionnaires sur les coûts fixes.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Cinq tours installent une **lecture critique du discours managérial** : déjà-vu, vocabulaire suspect (« agilité », « efficacité »). La question « qu''est-ce qui se joue vraiment, au-delà du visible ? » demande **le véritable enjeu, dissimulé derrière l''argumentaire officiel**. Seule A nomme un mécanisme de pouvoir caché (recentralisation sous couvert de fluidification), cohérent avec l''ironie de la femme. B prend **le discours officiel pour argent comptant** — distracteur très proche en surface, mais incompatible avec « au-delà du visible ». C propose **un autre projet (ouverture de postes)** qui n''est pas suggéré. D donne **une cause externe vraisemblable** (pression actionnariale) mais ne décrit pas ce que la réforme produit en interne.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000006', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu dois choisir entre les deux candidats pour diriger le laboratoire.
[Homme] L''un est un chercheur brillant mais peu enclin au management ; l''autre, un gestionnaire chevronné, plus éloigné de la recherche pure.
[Femme] Les deux profils sont défendus avec ardeur en interne.
[Homme] Effectivement. Mais où est la véritable tension, in fine ?
[Femme] ...

A. Dans la difficulté à les départager équitablement sans froisser les soutiens de chacun.
B. Entre préserver l''excellence scientifique et garantir la viabilité opérationnelle du laboratoire.
C. Dans le fait qu''aucun des deux ne souhaite réellement endosser cette responsabilité.
D. Entre la pression du conseil et la résistance attendue des équipes en place.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu dois choisir entre les deux candidats pour diriger le laboratoire.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''un est un chercheur brillant mais peu enclin au management ; l''autre, un gestionnaire chevronné, plus éloigné de la recherche pure.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Les deux profils sont défendus avec ardeur en interne.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Effectivement. Mais où est la véritable tension, in fine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans la difficulté à les départager équitablement sans froisser les soutiens de chacun.<break time="700ms"/>B.<break time="300ms"/>Entre préserver l''excellence scientifique et garantir la viabilité opérationnelle du laboratoire.<break time="700ms"/>C.<break time="300ms"/>Dans le fait qu''aucun des deux ne souhaite réellement endosser cette responsabilité.<break time="700ms"/>D.<break time="300ms"/>Entre la pression du conseil et la résistance attendue des équipes en place.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le tour 2 caractérise deux profils incarnant deux **valeurs incompatibles** (excellence scientifique vs efficacité gestionnaire) ; la question finale demande **la tension de fond**, pas la tension de surface. Seule B nomme l''arbitrage stratégique réel (excellence vs viabilité). A désigne **une tension politique interne** (« comment trancher sans heurter ? ») — distracteur très proche car aussi présente, mais c''est une conséquence, pas la tension de fond. C propose **un retournement non étayé** (« et s''ils refusaient ? »). D évoque **une tension verticale conseil/équipes** qui ne figure pas dans l''échange.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000007', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Ma sœur a passé tout le dîner à évoquer les souvenirs de la maison de campagne.
[Femme] Tu n''y vas plus que rarement, je crois.
[Homme] Depuis trois ans, à peine deux week-ends. Elle l''a rappelé à plusieurs reprises devant tout le monde.
[Femme] Sans jamais te le dire en face. Qu''est-ce qu''on te reproche en filigrane, dans ce genre d''insistance ?
[Homme] ...

A. De ne plus aimer cette maison autant qu''elle aimerait que je l''aime.
B. D''avoir voulu vendre cette maison contre l''avis de la fratrie.
C. De m''être éloigné d''un patrimoine familial qu''on attendait que je continue à faire vivre.
D. De manquer de gratitude envers les parents qui l''ont entretenue durant des années.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Ma sœur a passé tout le dîner à évoquer les souvenirs de la maison de campagne.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu n''y vas plus que rarement, je crois.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Depuis trois ans, à peine deux week-ends. Elle l''a rappelé à plusieurs reprises devant tout le monde.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Sans jamais te le dire en face. Qu''est-ce qu''on te reproche en filigrane, dans ce genre d''insistance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>De ne plus aimer cette maison autant qu''elle aimerait que je l''aime.<break time="700ms"/>B.<break time="300ms"/>D''avoir voulu vendre cette maison contre l''avis de la fratrie.<break time="700ms"/>C.<break time="300ms"/>De m''être éloigné d''un patrimoine familial qu''on attendait que je continue à faire vivre.<break time="700ms"/>D.<break time="300ms"/>De manquer de gratitude envers les parents qui l''ont entretenue durant des années.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue combine deux indices : peu de visites depuis trois ans **et** insistance répétée devant témoins. La question « qu''est-ce qu''on te reproche en filigrane ? » demande **l''accusation tacite portée par cette stratégie indirecte**. Seule C formule le reproche pragmatique exact : l''éloignement d''un patrimoine familial qu''on attendait qu''il continue à faire vivre. A propose **un reproche affectif diffus** (« tu n''aimes plus assez la maison ») — très proche de C, mais ne porte pas la dimension d''engagement attendu. B invente **un projet de vente** non mentionné. D bascule **vers les parents** (« tu manques de gratitude ») alors que le sujet implicite reste la maison.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL),

  ('66666666-00c1-1000-0000-000000000008', 'B2', 'co_dialogue_c1_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as fini par signer le compromis avec les acheteurs.
[Homme] Oui, hier soir, au bout de huit heures de discussion.
[Femme] Tu avais pourtant juré que tu ne céderais sur aucun point essentiel.
[Homme] C''est ce que j''ai prétendu publiquement. Qu''as-tu dû concéder discrètement, à ton avis ?
[Femme] ...

A. Un report de la date d''entrée dans les lieux, ce qui n''engage à rien.
B. Une exigence de garanties bancaires renforcées, dont tu te félicites.
C. La présence d''un notaire imposé par l''autre partie, ce qui reste anecdotique.
D. Une révision à la baisse du prix sur la pièce que tu refusais absolument de toucher.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par signer le compromis avec les acheteurs.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, hier soir, au bout de huit heures de discussion.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu avais pourtant juré que tu ne céderais sur aucun point essentiel.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est ce que j''ai prétendu publiquement. Qu''as-tu dû concéder discrètement, à ton avis ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un report de la date d''entrée dans les lieux, ce qui n''engage à rien.<break time="700ms"/>B.<break time="300ms"/>Une exigence de garanties bancaires renforcées, dont tu te félicites.<break time="700ms"/>C.<break time="300ms"/>La présence d''un notaire imposé par l''autre partie, ce qui reste anecdotique.<break time="700ms"/>D.<break time="300ms"/>Une révision à la baisse du prix sur la pièce que tu refusais absolument de toucher.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''homme a soutenu publiquement n''avoir rien cédé d''essentiel, mais reconnaît implicitement une concession « discrète ». La question demande **la concession non avouée portant précisément sur un point essentiel**. Seule D désigne une vraie concession sur la ligne rouge déclarée (« la pièce que tu refusais absolument de toucher »). A propose **une concession volontairement minimisée** (« n''engage à rien ») — proche par la forme, mais l''autoderision de la phrase indique qu''elle ne portait pas sur un point essentiel. B est **un gain, pas une concession**. C est **un détail relationnel** présenté comme anecdotique.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL, NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.437065+02', NULL, NULL, NULL);
