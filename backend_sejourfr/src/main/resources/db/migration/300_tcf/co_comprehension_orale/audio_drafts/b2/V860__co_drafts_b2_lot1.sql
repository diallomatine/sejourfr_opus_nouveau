-- ============================================================================
-- V486 — TCF CO : drafts audio B2 (lot 1)
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
  ('66666666-00b2-1000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as enfin osé demander à Mathieu une augmentation ?
[Homme] Oui, je lui en ai parlé lundi matin.
[Femme] Et au juste, comment a-t-il pris la chose ?
[Homme] ...

A. Avec une étonnante ouverture d''esprit.
B. Au cours de notre point hebdomadaire.
C. Parce que mes résultats parlent d''eux-mêmes.
D. En soulignant fermement les enjeux pour l''équipe.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as enfin osé demander à Mathieu une augmentation ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je lui en ai parlé lundi matin.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et au juste, comment a-t-il pris la chose ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec une étonnante ouverture d''esprit.<break time="700ms"/>B.<break time="300ms"/>Au cours de notre point hebdomadaire.<break time="700ms"/>C.<break time="300ms"/>Parce que mes résultats parlent d''eux-mêmes.<break time="700ms"/>D.<break time="300ms"/>En soulignant fermement les enjeux pour l''équipe.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (la demande d''augmentation a eu lieu) prépare une question sur **la réaction de Mathieu**. « Comment a-t-il pris la chose ? » porte sur la réaction émotionnelle/disposition du destinataire de la demande. Seule A « avec une étonnante ouverture d''esprit » décrit cette réaction. B donne le **cadre temporel** de la discussion (« lors de quel rendez-vous ? »). C donne la **cause / justification** de la demande (« pourquoi en as-tu fait la demande ? »). D donne **la manière dont l''homme a présenté sa demande** — piège B2 majeur : « en soulignant » est un gérondif de manière, mais le sujet implicite est le locuteur, pas Mathieu ; D répond à « comment as-tu présenté ta demande ? ».',
   '[{"label": "Avec une étonnante ouverture d''esprit.", "is_correct": true, "display_order": 1}, {"label": "Au cours de notre point hebdomadaire.", "is_correct": false, "display_order": 2}, {"label": "Parce que mes résultats parlent d''eux-mêmes.", "is_correct": false, "display_order": 3}, {"label": "En soulignant fermement les enjeux pour l''équipe.", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/67d8c125-1e9a-440d-8a57-1a8565376d1e.mp3',
   '36', 'fr-FR-DeniseNeural', '2026-05-31 16:49:12.379732+02', '6b8e1725-3032-47da-8277-408e2b812adf',
   '2026-05-27 17:40:30.3066+02', '2026-05-31 16:49:39.036487+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Vous avez réussi à boucler le dossier de subvention pour le projet ?
[Homme] Oui, on a eu confirmation lundi.
[Femme] Bravo. Et concrètement, à quoi va servir cet argent en priorité ?
[Homme] ...

A. À recruter deux profils techniques dès septembre.
B. Grâce au soutien d''un partenaire allemand.
C. Sous réserve d''une évaluation à mi-parcours.
D. Au moment où les recrutements seront finalisés.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez réussi à boucler le dossier de subvention pour le projet ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on a eu confirmation lundi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Bravo. Et concrètement, à quoi va servir cet argent en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À recruter deux profils techniques dès septembre.<break time="700ms"/>B.<break time="300ms"/>Grâce au soutien d''un partenaire allemand.<break time="700ms"/>C.<break time="300ms"/>Sous réserve d''une évaluation à mi-parcours.<break time="700ms"/>D.<break time="300ms"/>Au moment où les recrutements seront finalisés.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours valident l''obtention du financement. La question implicite « à quoi va servir cet argent en priorité ? » porte sur **la finalité, l''usage prioritaire**. Seule A « à recruter deux profils » (à + infinitif = finalité) y répond. B donne la **cause / le moyen de l''obtention** (« comment l''avez-vous obtenu ? »). C donne une **condition** sur l''usage (« sous quelles conditions est-il alloué ? ») — piège fin B2 : C est cohérente avec un budget mais ne désigne pas un usage. D donne un **moment** (« quand pourra-t-il être pleinement utilisé ? »).',
   '[{"label": "À recruter deux profils techniques dès septembre.", "is_correct": true, "display_order": 1}, {"label": "Grâce au soutien d''un partenaire allemand.", "is_correct": false, "display_order": 2}, {"label": "Sous réserve d''une évaluation à mi-parcours.", "is_correct": false, "display_order": 3}, {"label": "Au moment où les recrutements seront finalisés.", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/04cdf315-c604-4e58-93b9-b488b8c951a1.mp3',
   '41', 'fr-FR-DeniseNeural', '2026-05-31 16:49:13.650578+02', '6b8e1725-3032-47da-8277-408e2b812adf',
   '2026-05-27 17:40:30.3066+02', '2026-05-31 16:49:40.370681+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu sais quoi, j''ai été prise dans la formation de Polytechnique !
[Homme] Félicitations, c''est extraordinaire !
[Femme] Oui, ils m''ont rappelée hier.
[Homme] Mais à ton avis, qu''est-ce qui a fait pencher la balance ?
[Femme] ...

A. Mon parcours associatif, je pense.
B. Dès la fin de l''été dernier, en réalité.
C. Devant un jury de cinq personnes.
D. Plutôt avec une certaine émotion, à vrai dire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu sais quoi, j''ai été prise dans la formation de Polytechnique !</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Félicitations, c''est extraordinaire !</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ils m''ont rappelée hier.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais à ton avis, qu''est-ce qui a fait pencher la balance ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Mon parcours associatif, je pense.<break time="700ms"/>B.<break time="300ms"/>Dès la fin de l''été dernier, en réalité.<break time="700ms"/>C.<break time="300ms"/>Devant un jury de cinq personnes.<break time="700ms"/>D.<break time="300ms"/>Plutôt avec une certaine émotion, à vrai dire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les trois premiers tours installent le contexte (admission obtenue, annonce récente). La question finale « qu''est-ce qui a fait pencher la balance ? » demande **le critère décisif, le facteur différenciant** dans la sélection. Seule A « mon parcours associatif » désigne ce critère. B donne un **moment** (« depuis quand est-ce engagé ? »). C donne le **cadre / les acteurs** de la sélection (« qui t''a auditionnée ? »). D donne la **réaction émotionnelle** à la nouvelle (« comment as-tu reçu la réponse ? ») — piège B2 récurrent : confondre la cause du choix et la réaction à son annonce.',
   '[{"label": "Mon parcours associatif, je pense.", "is_correct": true, "display_order": 1}, {"label": "Dès la fin de l''été dernier, en réalité.", "is_correct": false, "display_order": 2}, {"label": "Devant un jury de cinq personnes.", "is_correct": false, "display_order": 3}, {"label": "Plutôt avec une certaine émotion, à vrai dire.", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/fb25c036-40d7-457c-b374-29ce4e6d84c7.mp3',
   '42', 'fr-FR-HenriNeural', '2026-05-31 16:49:14.050156+02', '6b8e1725-3032-47da-8277-408e2b812adf', '2026-05-27 17:40:30.3066+02',
   '2026-05-31 16:49:35.349529+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] J''ai vu que tu parles couramment japonais maintenant.
[Femme] Pas couramment, mais je me débrouille très bien.
[Homme] Comment tu t''y es prise pour atteindre ce niveau-là ?
[Femme] ...

A. En combinant cours du soir et applications mobiles.
B. Au bout de presque cinq années de pratique.
C. Pour pouvoir travailler à Tokyo un jour.
D. Avec une professeure particulièrement exigeante.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai vu que tu parles couramment japonais maintenant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Pas couramment, mais je me débrouille très bien.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment tu t''y es prise pour atteindre ce niveau-là ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En combinant cours du soir et applications mobiles.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque cinq années de pratique.<break time="700ms"/>C.<break time="300ms"/>Pour pouvoir travailler à Tokyo un jour.<break time="700ms"/>D.<break time="300ms"/>Avec une professeure particulièrement exigeante.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (niveau actuel solide en japonais) pose le décor. La question « comment tu t''y es prise pour atteindre... » interroge **la méthode, les moyens employés**. Seule A « en combinant cours du soir et applications mobiles » (gérondif de moyen) désigne la démarche. B donne une **durée** (« combien de temps cela t''a-t-il pris ? »). C donne un **but** (« dans quel objectif l''as-tu appris ? »). D donne un **accompagnement / une personne ressource** (« avec qui as-tu appris ? ») — piège B2 fin : D semble répondre à « comment » mais désigne en réalité un compagnon d''apprentissage et non la méthode.',
   '[{"label": "En combinant cours du soir et applications mobiles.", "is_correct": true, "display_order": 1}, {"label": "Au bout de presque cinq années de pratique.", "is_correct": false, "display_order": 2}, {"label": "Pour pouvoir travailler à Tokyo un jour.", "is_correct": false, "display_order": 3}, {"label": "Avec une professeure particulièrement exigeante.", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/fa066516-9f9c-4ada-9d54-38de8e0c7a25.mp3',
   '37', 'fr-FR-HenriNeural', '2026-05-31 16:49:14.397793+02', '6b8e1725-3032-47da-8277-408e2b812adf', '2026-05-27 17:40:30.3066+02',
   '2026-05-31 16:49:41.253008+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as fini par quitter ton ancien poste, finalement ?
[Homme] Oui, à la rentrée dernière.
[Femme] Et qu''est-ce que ça a changé concrètement dans ton quotidien ?
[Homme] ...

A. Un bien meilleur équilibre entre vie pro et vie perso.
B. Une lassitude profonde envers ma hiérarchie.
C. Après une longue réflexion en famille, tout de même.
D. À titre personnel, plus qu''à titre professionnel.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as fini par quitter ton ancien poste, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, à la rentrée dernière.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et qu''est-ce que ça a changé concrètement dans ton quotidien ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un bien meilleur équilibre entre vie pro et vie perso.<break time="700ms"/>B.<break time="300ms"/>Une lassitude profonde envers ma hiérarchie.<break time="700ms"/>C.<break time="300ms"/>Après une longue réflexion en famille, tout de même.<break time="700ms"/>D.<break time="300ms"/>À titre personnel, plus qu''à titre professionnel.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours établissent le fait (le départ a eu lieu). La question « qu''est-ce que ça a changé... ? » porte sur **la conséquence, l''effet observé après coup**. Seule A « un bien meilleur équilibre » décrit ce changement. B donne **la cause antérieure** du départ (« pourquoi es-tu parti ? ») — piège B2 majeur : cause et conséquence sont symétriques autour de l''événement, il faut entendre la temporalité de la question (« a changé » = après). C donne **le processus de décision** (« comment as-tu pris la décision ? »). D précise **le registre / le périmètre** du changement (« dans quel domaine est-ce surtout vrai ? »), pas le changement lui-même.',
   '[{"label": "Un bien meilleur équilibre entre vie pro et vie perso.", "is_correct": true, "display_order": 1}, {"label": "Une lassitude profonde envers ma hiérarchie.", "is_correct": false, "display_order": 2}, {"label": "Après une longue réflexion en famille, tout de même.", "is_correct": false, "display_order": 3}, {"label": "À titre personnel, plus qu''à titre professionnel.", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/d93e01ce-41b6-489a-9a1b-6537309e3cff.mp3',
   '39', 'fr-FR-DeniseNeural', '2026-05-31 16:49:14.849933+02', '6b8e1725-3032-47da-8277-408e2b812adf',
   '2026-05-27 17:40:30.3066+02', '2026-05-31 16:49:36.506171+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as l''air vraiment satisfaite de ta dernière exposition.
[Femme] Oui, c''est sans doute la mieux reçue jusqu''à présent.
[Homme] À quoi tient ce succès, selon toi ?
[Femme] ...

A. À la cohérence d''ensemble entre les œuvres présentées.
B. Tout près du quai Branly, dans le septième arrondissement.
C. Jusqu''à la toute fin du mois de mars.
D. À l''occasion d''un long week-end férié, finalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air vraiment satisfaite de ta dernière exposition.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est sans doute la mieux reçue jusqu''à présent.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quoi tient ce succès, selon toi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la cohérence d''ensemble entre les œuvres présentées.<break time="700ms"/>B.<break time="300ms"/>Tout près du quai Branly, dans le septième arrondissement.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à la toute fin du mois de mars.<break time="700ms"/>D.<break time="300ms"/>À l''occasion d''un long week-end férié, finalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours installent le constat (exposition très bien reçue). La formulation indirecte « à quoi tient... ? » demande **un facteur explicatif, ce qui cause / explique le succès**. Seule A « à la cohérence entre les œuvres » désigne ce facteur. B donne le **lieu** de l''exposition (« où se tient-elle ? »). C donne **la durée jusqu''à terme** (« jusqu''à quand est-elle ouverte ? »). D donne **le moment du vernissage** (« quand a-t-elle eu lieu ? ») — piège B2 fin : la préposition « à » se retrouve aussi dans D, ce qui peut tromper, mais « à l''occasion de » est temporel, pas explicatif.',
   '[{"label": "À la cohérence d''ensemble entre les œuvres présentées.", "is_correct": true, "display_order": 1}, {"label": "Tout près du quai Branly, dans le septième arrondissement.", "is_correct": false, "display_order": 2}, {"label": "Jusqu''à la toute fin du mois de mars.", "is_correct": false, "display_order": 3}, {"label": "À l''occasion d''un long week-end férié, finalement.", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/5bbe2198-647b-4918-bb3f-ff0971b4fde0.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:15.224529+02', '6b8e1725-3032-47da-8277-408e2b812adf', '2026-05-27 17:40:30.3066+02',
   '2026-05-31 16:49:42.618956+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as postulé chez Renault, finalement ?
[Homme] Oui, je dois passer les entretiens la semaine prochaine.
[Femme] Au fait, par quel biais tu as eu vent du poste ?
[Homme] ...

A. Par l''intermédiaire d''un ancien collègue à moi.
B. Pour un salaire légèrement plus avantageux.
C. Au bout de plusieurs mois d''attente, en fait.
D. Avec un enthousiasme assez modéré, je dois dire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as postulé chez Renault, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je dois passer les entretiens la semaine prochaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Au fait, par quel biais tu as eu vent du poste ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par l''intermédiaire d''un ancien collègue à moi.<break time="700ms"/>B.<break time="300ms"/>Pour un salaire légèrement plus avantageux.<break time="700ms"/>C.<break time="300ms"/>Au bout de plusieurs mois d''attente, en fait.<break time="700ms"/>D.<break time="300ms"/>Avec un enthousiasme assez modéré, je dois dire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours valident le fait (candidature posée, entretiens à venir). « Par quel biais tu as eu vent du poste ? » est une formulation soutenue interrogeant **la source / l''intermédiaire qui t''a renseigné**. Seule A « par l''intermédiaire d''un ancien collègue » désigne cet intermédiaire. B donne une **motivation / avantage** (« pourquoi postules-tu ? »). C donne une **durée d''attente** (« depuis combien de temps cherches-tu ? »). D donne **l''état d''esprit** du candidat (« dans quelle disposition postules-tu ? ») — piège B2 : la préposition « par » de A et la préposition « avec » de D peuvent toutes deux suggérer une manière, mais seule A désigne une source.',
   '[{"label": "Par l''intermédiaire d''un ancien collègue à moi.", "is_correct": true, "display_order": 1}, {"label": "Pour un salaire légèrement plus avantageux.", "is_correct": false, "display_order": 2}, {"label": "Au bout de plusieurs mois d''attente, en fait.", "is_correct": false, "display_order": 3}, {"label": "Avec un enthousiasme assez modéré, je dois dire.", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/c3b0f227-781f-4754-86ad-6f01e926f6e8.mp3',
   '39', 'fr-FR-DeniseNeural', '2026-05-31 16:49:15.583973+02', '6b8e1725-3032-47da-8277-408e2b812adf',
   '2026-05-27 17:40:30.3066+02', '2026-05-31 16:49:37.404074+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez réussi à organiser ce mariage entièrement vous-mêmes ?
[Femme] Avec quelques aides, mais oui, en grande partie.
[Homme] Comment vous vous y êtes pris pour financer une réception pareille ?
[Femme] ...

A. En économisant patiemment pendant près de trois ans.
B. Auprès de nos familles les plus proches, surtout.
C. Plus de cent cinquante invités, je crois.
D. Dans une jolie bâtisse au bord de la Loire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez réussi à organiser ce mariage entièrement vous-mêmes ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Avec quelques aides, mais oui, en grande partie.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment vous vous y êtes pris pour financer une réception pareille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En économisant patiemment pendant près de trois ans.<break time="700ms"/>B.<break time="300ms"/>Auprès de nos familles les plus proches, surtout.<break time="700ms"/>C.<break time="300ms"/>Plus de cent cinquante invités, je crois.<break time="700ms"/>D.<break time="300ms"/>Dans une jolie bâtisse au bord de la Loire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le sujet (organisation autonome du mariage, avec quelques aides). « Comment vous vous y êtes pris pour financer ? » porte sur **le moyen financier, la méthode pour réunir l''argent**. Seule A « en économisant patiemment » (gérondif de moyen) répond. B donne **l''origine des aides** (« auprès de qui ? ») — piège B2 majeur : le deuxième tour mentionne « quelques aides », ce qui rend B très tentante, mais B identifie un soutien, pas la méthode principale de financement. C donne **le nombre d''invités**. D donne **le lieu** de la réception.',
   '[{"label": "En économisant patiemment pendant près de trois ans.", "is_correct": true, "display_order": 1}, {"label": "Auprès de nos familles les plus proches, surtout.", "is_correct": false, "display_order": 2}, {"label": "Plus de cent cinquante invités, je crois.", "is_correct": false, "display_order": 3}, {"label": "Dans une jolie bâtisse au bord de la Loire.", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/332244d9-3873-4a24-9813-962c5c51da3b.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:15.939763+02', '6b8e1725-3032-47da-8277-408e2b812adf', '2026-05-27 17:40:30.3066+02',
   '2026-05-31 16:49:43.304004+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu reviens tout juste de ton entretien à la mairie ?
[Homme] Oui, je suis sorti il y a une heure environ.
[Femme] Et dans quel état d''esprit tu en ressors ?
[Homme] ...

A. Plutôt confiant, je dois bien dire.
B. Au bout de presque deux heures de discussion.
C. Face à un panel de trois élus locaux.
D. Pour un poste de chargé de mission culture.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens tout juste de ton entretien à la mairie ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis sorti il y a une heure environ.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et dans quel état d''esprit tu en ressors ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Plutôt confiant, je dois bien dire.<break time="700ms"/>B.<break time="300ms"/>Au bout de presque deux heures de discussion.<break time="700ms"/>C.<break time="300ms"/>Face à un panel de trois élus locaux.<break time="700ms"/>D.<break time="300ms"/>Pour un poste de chargé de mission culture.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent le décor (entretien terminé, très récent). « Dans quel état d''esprit tu en ressors ? » porte sur **la disposition intérieure, le ressenti subjectif après l''épreuve**. Seule A « plutôt confiant » décrit cette disposition. B donne **la durée de l''entretien** (« combien de temps a duré l''entretien ? »). C donne **les interlocuteurs** (« face à qui étais-tu ? »). D donne **le but / l''objet de la candidature** (« pour quel poste postules-tu ? ») — piège B2 fin : la préposition « dans » dans la question et la préposition « pour » dans D peuvent toutes deux évoquer un contexte, mais D ne décrit pas un état mental.',
   '[{"label": "Plutôt confiant, je dois bien dire.", "is_correct": true, "display_order": 1}, {"label": "Au bout de presque deux heures de discussion.", "is_correct": false, "display_order": 2}, {"label": "Face à un panel de trois élus locaux.", "is_correct": false, "display_order": 3}, {"label": "Pour un poste de chargé de mission culture.", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/71609eba-40d8-4c50-b508-670d7671808f.mp3',
   '37', 'fr-FR-DeniseNeural', '2026-05-31 16:49:16.405619+02', '6b8e1725-3032-47da-8277-408e2b812adf',
   '2026-05-27 17:40:30.3066+02', '2026-05-31 16:49:38.062614+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-1000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu te souviens de cette histoire d''héritage compliqué chez les Dubois ?
[Femme] Oui, ça s''éternisait depuis des années.
[Homme] Justement, je me demandais ce qu''il en était advenu, au final ?
[Femme] ...

A. Un accord à l''amiable, signé l''été dernier.
B. À cause de différends entre frères et sœurs.
C. Par l''intermédiaire d''un notaire de Bordeaux.
D. Avec une amertume durable, paraît-il.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu te souviens de cette histoire d''héritage compliqué chez les Dubois ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça s''éternisait depuis des années.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Justement, je me demandais ce qu''il en était advenu, au final ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un accord à l''amiable, signé l''été dernier.<break time="700ms"/>B.<break time="300ms"/>À cause de différends entre frères et sœurs.<break time="700ms"/>C.<break time="300ms"/>Par l''intermédiaire d''un notaire de Bordeaux.<break time="700ms"/>D.<break time="300ms"/>Avec une amertume durable, paraît-il.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours posent une affaire d''héritage qui traînait. La formulation indirecte « ce qu''il en était advenu, au final » demande **le dénouement, l''issue de l''affaire**. Seule A « un accord à l''amiable, signé l''été dernier » désigne ce dénouement. B donne **la cause originelle** du conflit (« pourquoi cela durait-il ? »). C donne **l''intermédiaire / l''acteur** qui a aidé (« par qui cela a-t-il été résolu ? ») — piège B2 fin : un notaire est lié à un règlement d''héritage, ce qui rend C plausible, mais elle ne dit pas comment l''affaire s''est terminée. D donne **le climat émotionnel** post-résolution (« dans quelle ambiance cela s''est-il fini ? »).',
   '[{"label": "Un accord à l''amiable, signé l''été dernier.", "is_correct": true, "display_order": 1}, {"label": "À cause de différends entre frères et sœurs.", "is_correct": false, "display_order": 2}, {"label": "Par l''intermédiaire d''un notaire de Bordeaux.", "is_correct": false, "display_order": 3}, {"label": "Avec une amertume durable, paraît-il.", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/18bd1516-5bb5-4604-a003-0395697a96d4.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:16.798947+02', '6b8e1725-3032-47da-8277-408e2b812adf', '2026-05-27 17:40:30.3066+02',
   '2026-05-31 16:49:44.088189+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu te lèves vraiment à six heures tous les matins pour courir ?
[Femme] Oui, ça fait deux mois maintenant.
[Homme] Mais qu''est-ce qui te motive autant à tenir, dans la durée ?
[Femme] ...

A. Au lever du jour, dans le parc en bas.
B. La sensation d''énergie qui rythme toute ma journée.
C. Sur les conseils insistants de ma médecin.
D. Pendant trois bons quarts d''heure environ.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu te lèves vraiment à six heures tous les matins pour courir ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça fait deux mois maintenant.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui te motive autant à tenir, dans la durée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lever du jour, dans le parc en bas.<break time="700ms"/>B.<break time="300ms"/>La sensation d''énergie qui rythme toute ma journée.<break time="700ms"/>C.<break time="300ms"/>Sur les conseils insistants de ma médecin.<break time="700ms"/>D.<break time="300ms"/>Pendant trois bons quarts d''heure environ.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (assiduité depuis deux mois) prépare une question sur **la motivation intérieure**. « Qu''est-ce qui te motive à tenir, dans la durée ? » appelle un ressort intrinsèque. Seule B « la sensation d''énergie qui rythme ma journée » décrit ce ressort. A donne **le moment et le lieu** de la pratique. C donne **l''origine extérieure** de la décision (« qui te l''a recommandé ? ») — piège B2 : C est une cause initiale, pas la motivation qui fait tenir au quotidien. D donne **la durée d''une sortie**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/b34b92f8-4389-4e43-aabe-5a20c7edccc4.mp3',
   '37', 'fr-FR-HenriNeural', '2026-05-31 16:49:47.209257+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:08.267866+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu vas accepter le poste de directeur qu''on te propose ?
[Homme] Sans doute, mais avec quelques réserves quand même.
[Femme] Justement, quelles sont tes réserves principales ?
[Homme] ...

A. Une équipe d''environ vingt personnes à encadrer.
B. La charge horaire trop importante annoncée.
C. À partir du début du trimestre prochain.
D. Pour relever un vrai défi de carrière.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vas accepter le poste de directeur qu''on te propose ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sans doute, mais avec quelques réserves quand même.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Justement, quelles sont tes réserves principales ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une équipe d''environ vingt personnes à encadrer.<break time="700ms"/>B.<break time="300ms"/>La charge horaire trop importante annoncée.<break time="700ms"/>C.<break time="300ms"/>À partir du début du trimestre prochain.<break time="700ms"/>D.<break time="300ms"/>Pour relever un vrai défi de carrière.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (acceptation probable, mais avec réserves) cadre la question. « Quelles sont tes réserves principales ? » appelle **un point négatif, une limite, un frein**. Seule B « la charge horaire trop importante » formule une réserve. A donne un **fait neutre** sur le poste (taille de l''équipe). C donne le **moment de prise de fonction**. D donne la **motivation à accepter** (« pourquoi acceptes-tu ? ») — piège B2 : D est le contraire d''une réserve.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/5f219caf-07d9-482d-8c4c-1204e3c56b18.mp3',
   '38', 'fr-FR-DeniseNeural', '2026-05-31 16:49:47.597067+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:09.250152+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous publiez un nouvel ouvrage le mois prochain, c''est cela ?
[Femme] Oui, sur les enjeux du numérique en santé.
[Homme] À qui s''adresse-t-il prioritairement, selon vous ?
[Femme] ...

A. Aux professionnels de la santé en exercice.
B. Sur la base d''une longue enquête de terrain.
C. Aux éditions du Seuil, comme toujours.
D. Pour éclairer un débat encore confus.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous publiez un nouvel ouvrage le mois prochain, c''est cela ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, sur les enjeux du numérique en santé.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À qui s''adresse-t-il prioritairement, selon vous ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Aux professionnels de la santé en exercice.<break time="700ms"/>B.<break time="300ms"/>Sur la base d''une longue enquête de terrain.<break time="700ms"/>C.<break time="300ms"/>Aux éditions du Seuil, comme toujours.<break time="700ms"/>D.<break time="300ms"/>Pour éclairer un débat encore confus.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À qui s''adresse-t-il prioritairement ? » porte sur **le public cible, les destinataires-lecteurs**. Seule A « aux professionnels de la santé » désigne ce public. B donne **la méthode / la source** de l''ouvrage. C donne **l''éditeur** (« qui publie ? ») — piège B2 majeur : C utilise « aux » comme A, ce qui mime la structure de la question, mais l''éditeur n''est pas le destinataire. D donne **le but** de l''ouvrage.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/a3fd687e-b413-4435-a883-6728406a214a.mp3',
   '38', 'fr-FR-HenriNeural', '2026-05-31 16:49:48.089329+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:13.769526+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu te souviens du recrutement de notre nouveau directeur, l''an dernier ?
[Homme] Bien sûr, ça avait fait beaucoup parler.
[Femme] Surtout que la concurrence interne était particulièrement rude.
[Homme] C''est vrai. Et avec le recul, qu''est-ce qui a justifié ce choix ?
[Femme] ...

A. Au terme de trois rounds d''entretiens approfondis.
B. Son expérience internationale, vraiment unique en son genre.
C. Devant un comité de sélection paritaire.
D. Pour un démarrage effectif en septembre suivant.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu te souviens du recrutement de notre nouveau directeur, l''an dernier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bien sûr, ça avait fait beaucoup parler.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Surtout que la concurrence interne était particulièrement rude.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est vrai. Et avec le recul, qu''est-ce qui a justifié ce choix ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au terme de trois rounds d''entretiens approfondis.<break time="700ms"/>B.<break time="300ms"/>Son expérience internationale, vraiment unique en son genre.<break time="700ms"/>C.<break time="300ms"/>Devant un comité de sélection paritaire.<break time="700ms"/>D.<break time="300ms"/>Pour un démarrage effectif en septembre suivant.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les trois premiers tours établissent l''enjeu (recrutement disputé, concurrence interne forte). « Qu''est-ce qui a justifié ce choix ? » porte sur **le critère / l''atout qui a fait pencher la décision**. Seule B « son expérience internationale unique » désigne cet atout différenciant. A donne **la durée et l''ampleur de la procédure**. C donne **les acteurs de la décision** (« qui a choisi ? »). D donne **le moment de prise de fonction**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/48617840-2078-45e9-b3f2-2bd5568e6bd1.mp3',
   '46', 'fr-FR-HenriNeural', '2026-05-31 16:49:48.440819+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:10.201662+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] J''ai goûté ton nouveau yaourt fermenté, c''est étonnant.
[Femme] Oui, ça change vraiment des yaourts classiques.
[Homme] En quoi est-ce différent au goût, exactement ?
[Femme] ...

A. Une légère acidité, vraiment originale en bouche.
B. Depuis presque six mois que j''en achète.
C. Chez un producteur installé près du marché.
D. Pour environ trois euros le pot, tout de même.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai goûté ton nouveau yaourt fermenté, c''est étonnant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça change vraiment des yaourts classiques.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">En quoi est-ce différent au goût, exactement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une légère acidité, vraiment originale en bouche.<break time="700ms"/>B.<break time="300ms"/>Depuis presque six mois que j''en achète.<break time="700ms"/>C.<break time="300ms"/>Chez un producteur installé près du marché.<break time="700ms"/>D.<break time="300ms"/>Pour environ trois euros le pot, tout de même.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« En quoi est-ce différent au goût ? » demande **un trait gustatif distinctif**. Seule A « une légère acidité, originale » qualifie le goût. B donne la **durée de la pratique d''achat**. C donne le **lieu d''achat**. D donne le **prix unitaire**. Piège B2 : C et D restent dans le champ thématique du produit alimentaire, mais aucune ne porte sur le goût.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/86c6c837-fdb4-42a9-9b7b-aedb7db22869.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:48.898792+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:15.087025+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu reviens tout juste de ta mission humanitaire au Mali ?
[Homme] Oui, je suis rentré il y a tout juste une semaine.
[Femme] Quelle a été la principale difficulté sur place ?
[Homme] ...

A. L''accès à l''eau potable, malgré tous nos efforts.
B. Pendant près de quatre mois consécutifs.
C. Avec une équipe internationale très soudée.
D. À l''invitation d''une ONG locale réputée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu reviens tout juste de ta mission humanitaire au Mali ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, je suis rentré il y a tout juste une semaine.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle a été la principale difficulté sur place ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''accès à l''eau potable, malgré tous nos efforts.<break time="700ms"/>B.<break time="300ms"/>Pendant près de quatre mois consécutifs.<break time="700ms"/>C.<break time="300ms"/>Avec une équipe internationale très soudée.<break time="700ms"/>D.<break time="300ms"/>À l''invitation d''une ONG locale réputée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question porte sur **l''obstacle majeur rencontré pendant la mission**. Seule A « l''accès à l''eau potable » désigne un obstacle. B donne **la durée** de la mission. C donne **les coéquipiers** (note : « soudée » est positif, donc clairement pas une difficulté). D donne **l''origine de l''invitation** (« par qui es-tu venu ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/f9b9e308-4965-491c-a80f-b470ca39e6e6.mp3',
   '39', 'fr-FR-DeniseNeural', '2026-05-31 16:49:49.303074+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:11.203783+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu passes ton oral d''agrégation dans deux semaines, c''est ça ?
[Femme] Oui, ça approche à grands pas.
[Homme] Comment tu te prépares concrètement à l''exercice ?
[Femme] ...

A. À cause d''un programme particulièrement dense cette année.
B. Pour devenir titulaire dans le secondaire enfin.
C. Au bout de deux ans de préparation très intensive.
D. En enchaînant des oraux blancs devant un jury simulé.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu passes ton oral d''agrégation dans deux semaines, c''est ça ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça approche à grands pas.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment tu te prépares concrètement à l''exercice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''un programme particulièrement dense cette année.<break time="700ms"/>B.<break time="300ms"/>Pour devenir titulaire dans le secondaire enfin.<break time="700ms"/>C.<break time="300ms"/>Au bout de deux ans de préparation très intensive.<break time="700ms"/>D.<break time="300ms"/>En enchaînant des oraux blancs devant un jury simulé.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Comment tu te prépares concrètement ? » porte sur **la méthode de préparation actuelle**. Seule D « en enchaînant des oraux blancs » (gérondif de moyen) décrit la méthode. A donne **une cause externe** (« pourquoi est-ce dur ? »). B donne **le but ultime** (« pourquoi passes-tu l''oral ? »). C donne **la durée totale de préparation**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/b2ca709b-8ed8-4321-8184-60051aa1eb7c.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:49.702704+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:11.852348+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Vous avez eu un gros problème de plomberie au bureau, non ?
[Homme] Oui, une fuite énorme la semaine dernière.
[Femme] Et par quel moyen avez-vous résolu cela rapidement ?
[Homme] ...

A. En faisant appel à un plombier d''urgence le soir même.
B. Dans la salle de réunion du deuxième étage.
C. À la suite d''une canalisation vraiment vétuste.
D. Avec des dégâts plutôt limités, finalement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez eu un gros problème de plomberie au bureau, non ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, une fuite énorme la semaine dernière.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et par quel moyen avez-vous résolu cela rapidement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En faisant appel à un plombier d''urgence le soir même.<break time="700ms"/>B.<break time="300ms"/>Dans la salle de réunion du deuxième étage.<break time="700ms"/>C.<break time="300ms"/>À la suite d''une canalisation vraiment vétuste.<break time="700ms"/>D.<break time="300ms"/>Avec des dégâts plutôt limités, finalement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Par quel moyen avez-vous résolu... » porte sur **la solution mise en œuvre**. Seule A « en faisant appel à un plombier » décrit l''action concrète de résolution. B donne **le lieu** du problème. C donne **la cause** de la fuite (« pourquoi cela est-il arrivé ? »). D donne **les conséquences atténuées** (« quel bilan ? »).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/5c5ff9b2-8991-490b-a3a2-6aa913af26e5.mp3',
   '39', 'fr-FR-DeniseNeural', '2026-05-31 16:49:50.020027+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:12.552148+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu joues encore tous les dimanches aux échecs avec ton père ?
[Femme] Oui, c''est devenu un vrai rituel entre nous.
[Homme] Et ça remonte à quand, cette habitude ?
[Femme] ...

A. Sur un échiquier en bois qu''il m''avait offert.
B. Plutôt avec des parties relativement courtes.
C. À mes premières années de lycée, je dirais.
D. Pour qu''on reste connectés malgré tout.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu joues encore tous les dimanches aux échecs avec ton père ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''est devenu un vrai rituel entre nous.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et ça remonte à quand, cette habitude ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur un échiquier en bois qu''il m''avait offert.<break time="700ms"/>B.<break time="300ms"/>Plutôt avec des parties relativement courtes.<break time="700ms"/>C.<break time="300ms"/>À mes premières années de lycée, je dirais.<break time="700ms"/>D.<break time="300ms"/>Pour qu''on reste connectés malgré tout.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Ça remonte à quand ? » porte sur **l''origine temporelle d''une habitude**. Seule C « à mes premières années de lycée » fixe un point d''origine. A donne **l''objet utilisé** (« avec quoi ? »). B donne **la durée d''une partie** (« combien de temps ? »). D donne **le but / l''intention** du rituel (« pourquoi ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/16e79c38-0e3b-400f-a5ca-f550701e68c1.mp3',
   '37', 'fr-FR-HenriNeural', '2026-05-31 16:49:50.448754+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:27.038588+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as décidé d''accepter cette offre de prêt, finalement ?
[Homme] Pas encore, j''attends de voir.
[Femme] Tu l''accepterais à quelles conditions, précisément ?
[Homme] ...

A. Pour financer l''achat de notre future maison.
B. Si le taux baisse et que les frais sont supprimés.
C. Auprès de cette banque en ligne assez récente.
D. Au plus tard à la fin du mois prochain.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as décidé d''accepter cette offre de prêt, finalement ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pas encore, j''attends de voir.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu l''accepterais à quelles conditions, précisément ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour financer l''achat de notre future maison.<break time="700ms"/>B.<break time="300ms"/>Si le taux baisse et que les frais sont supprimés.<break time="700ms"/>C.<break time="300ms"/>Auprès de cette banque en ligne assez récente.<break time="700ms"/>D.<break time="300ms"/>Au plus tard à la fin du mois prochain.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« À quelles conditions ? » appelle **des exigences préalables**. Seule B « si le taux baisse et que les frais sont supprimés » (subordonnées conditionnelles cumulées) répond. A donne **le but** du prêt. C donne **l''interlocuteur bancaire**. D donne une **échéance**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/e201ce02-5675-4991-8785-30ea9b1fb23e.mp3',
   '37', 'fr-FR-DeniseNeural', '2026-05-31 16:49:50.760226+02', 'b8540e6a-3c43-4b27-8b72-e7749806ac57',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:25.727328+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000b', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous avez bouclé la phase de tests de votre application ?
[Femme] Oui, tout est validé depuis vendredi.
[Homme] Quelle est la prochaine étape, du coup ?
[Femme] ...

A. Le déploiement en production, sans plus attendre.
B. Grâce à une équipe particulièrement réactive.
C. Pendant près de six mois de développement.
D. Avec un budget assez serré, je l''avoue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous avez bouclé la phase de tests de votre application ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, tout est validé depuis vendredi.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle est la prochaine étape, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le déploiement en production, sans plus attendre.<break time="700ms"/>B.<break time="300ms"/>Grâce à une équipe particulièrement réactive.<break time="700ms"/>C.<break time="300ms"/>Pendant près de six mois de développement.<break time="700ms"/>D.<break time="300ms"/>Avec un budget assez serré, je l''avoue.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle est la prochaine étape ? » porte sur **l''action ou la phase qui suit immédiatement**. Seule A « le déploiement en production » désigne cette étape suivante. B donne **la cause du succès passé**. C donne **la durée déjà écoulée**. D donne **une contrainte rétrospective**.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/159daee6-52a7-43fb-803e-3b9e1901bbaa.mp3',
   '37', 'fr-FR-HenriNeural', '2026-05-31 16:49:55.165535+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:19.832188+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000c', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que tes enfants se disputaient sur les vacances ?
[Homme] Oui, c''était un vrai casse-tête à la maison.
[Femme] Vous avez fini par trouver quel compromis, du coup ?
[Homme] ...

A. À cause de leurs goûts vraiment opposés.
B. Après plusieurs soirées de discussion animée.
C. Avec l''aide précieuse de leur grand-mère.
D. Une semaine à la mer, puis une semaine à la montagne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que tes enfants se disputaient sur les vacances ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, c''était un vrai casse-tête à la maison.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Vous avez fini par trouver quel compromis, du coup ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause de leurs goûts vraiment opposés.<break time="700ms"/>B.<break time="300ms"/>Après plusieurs soirées de discussion animée.<break time="700ms"/>C.<break time="300ms"/>Avec l''aide précieuse de leur grand-mère.<break time="700ms"/>D.<break time="300ms"/>Une semaine à la mer, puis une semaine à la montagne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel compromis ? » porte sur **la solution médiane retenue**. Seule D « une semaine à la mer, puis une semaine à la montagne » formule la solution équilibrée. A donne **la cause initiale du conflit**. B donne **la durée et la manière du processus**. C donne **l''aide reçue**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/b63ad4a8-eeef-4ff3-b998-e609630a0f89.mp3',
   '38', 'fr-FR-DeniseNeural', '2026-05-31 16:49:55.597032+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:07.195154+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000d', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as l''air vraiment convaincu par cette voiture d''occasion.
[Femme] Oui, elle paraît en parfait état.
[Homme] Mais qu''est-ce qui te garantit que ce n''est pas une arnaque ?
[Femme] ...

A. Auprès d''un concessionnaire de la région, je précise.
B. Un rapport d''expert indépendant, fourni par écrit.
C. Pour environ dix mille euros, négociation comprise.
D. À la suite de longues recherches en ligne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as l''air vraiment convaincu par cette voiture d''occasion.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, elle paraît en parfait état.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui te garantit que ce n''est pas une arnaque ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Auprès d''un concessionnaire de la région, je précise.<break time="700ms"/>B.<break time="300ms"/>Un rapport d''expert indépendant, fourni par écrit.<break time="700ms"/>C.<break time="300ms"/>Pour environ dix mille euros, négociation comprise.<break time="700ms"/>D.<break time="300ms"/>À la suite de longues recherches en ligne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui te garantit... ? » porte sur **un élément de preuve / une caution objective**. Seule B « un rapport d''expert indépendant, fourni par écrit » désigne une garantie tangible. A donne **le vendeur / le canal d''achat**. C donne **le prix**. D donne **le processus préalable** (« comment t''es-tu renseigné ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/640707e2-0b40-40fe-ba11-a73c07bee6b2.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:56.018807+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:05.961024+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000e', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu enseignes l''histoire dans un lycée parisien, c''est cela ?
[Homme] Oui, depuis bientôt huit ans déjà.
[Femme] En quoi ton approche se distingue-t-elle de tes collègues ?
[Homme] ...

A. Par un usage très régulier d''archives sonores.
B. Auprès d''élèves majoritairement issus de la banlieue.
C. Pour environ vingt heures hebdomadaires en classe.
D. Grâce à un master en didactique de l''histoire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu enseignes l''histoire dans un lycée parisien, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, depuis bientôt huit ans déjà.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quoi ton approche se distingue-t-elle de tes collègues ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par un usage très régulier d''archives sonores.<break time="700ms"/>B.<break time="300ms"/>Auprès d''élèves majoritairement issus de la banlieue.<break time="700ms"/>C.<break time="300ms"/>Pour environ vingt heures hebdomadaires en classe.<break time="700ms"/>D.<break time="300ms"/>Grâce à un master en didactique de l''histoire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« En quoi ton approche se distingue-t-elle ? » porte sur **un trait pédagogique distinctif**. Seule A « par un usage régulier d''archives sonores » désigne un trait spécifique. B donne **le public** d''élèves. C donne **la charge horaire**. D donne **la formation initiale** (« comment t''es-tu formé ? ») — piège B2 : D peut sembler expliquer la spécificité, mais une formation partagée par d''autres collègues n''est pas en soi distinctive.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/ad7e9fc7-882d-43bc-8666-dcfadea23765.mp3',
   '39', 'fr-FR-DeniseNeural', '2026-05-31 16:49:56.365316+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:16.288047+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-00000000000f', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as déposé ta demande de naturalisation il y a longtemps ?
[Femme] Oui, ça fait presque un an déjà.
[Homme] Sous quel délai peux-tu espérer une réponse, normalement ?
[Femme] ...

A. À la préfecture de Bobigny, en l''occurrence.
B. Pour pouvoir voter aux prochaines élections.
C. Entre douze et dix-huit mois, en moyenne.
D. Avec l''aide d''une avocate spécialisée.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as déposé ta demande de naturalisation il y a longtemps ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, ça fait presque un an déjà.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sous quel délai peux-tu espérer une réponse, normalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la préfecture de Bobigny, en l''occurrence.<break time="700ms"/>B.<break time="300ms"/>Pour pouvoir voter aux prochaines élections.<break time="700ms"/>C.<break time="300ms"/>Entre douze et dix-huit mois, en moyenne.<break time="700ms"/>D.<break time="300ms"/>Avec l''aide d''une avocate spécialisée.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Sous quel délai peux-tu espérer une réponse ? » porte sur **un délai d''attente prévisible**. Seule C « entre douze et dix-huit mois » fournit un délai. A donne **le lieu** du dépôt. B donne **le but final** de la démarche. D donne **l''accompagnement** dans la procédure.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/8faa7b36-77b6-468a-ba02-edbb1b810104.mp3',
   '38', 'fr-FR-HenriNeural', '2026-05-31 16:49:56.814816+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:21.836813+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000010', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu envisages de quitter ton entreprise pour monter ta propre boîte ?
[Homme] J''y pense très sérieusement, oui.
[Femme] Mais qu''est-ce que ça risque de te coûter, concrètement ?
[Homme] ...

A. La sécurité financière des trois premières années.
B. À cause d''une opportunité commerciale qui se présente.
C. Pour devenir enfin maître de mes choix.
D. Avec le soutien total de ma compagne, heureusement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu envisages de quitter ton entreprise pour monter ta propre boîte ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''y pense très sérieusement, oui.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Mais qu''est-ce que ça risque de te coûter, concrètement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La sécurité financière des trois premières années.<break time="700ms"/>B.<break time="300ms"/>À cause d''une opportunité commerciale qui se présente.<break time="700ms"/>C.<break time="300ms"/>Pour devenir enfin maître de mes choix.<break time="700ms"/>D.<break time="300ms"/>Avec le soutien total de ma compagne, heureusement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que ça risque de te coûter ? » porte sur **un coût futur, une conséquence négative redoutée**. Seule A « la sécurité financière des trois premières années » désigne ce coût. B donne **la cause / opportunité déclenchante**. C donne **le bénéfice attendu** (l''opposé d''un coût). D donne **un soutien** (un atout, pas un coût).',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/8f8611ec-529b-4345-adfc-849f1e8cc868.mp3',
   '40', 'fr-FR-DeniseNeural', '2026-05-31 16:49:57.305954+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:17.335278+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000011', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu reviens enfin du festival d''Avignon ?
[Femme] Oui, dix jours assez intenses.
[Homme] Qu''est-ce qui t''a le plus marquée, sur place ?
[Femme] ...

A. Pendant à peu près une dizaine de jours.
B. Avec une amie costumière de l''Opéra.
C. Sous une chaleur parfois écrasante en journée.
D. Une mise en scène d''Hamlet vraiment inoubliable.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu reviens enfin du festival d''Avignon ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, dix jours assez intenses.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce qui t''a le plus marquée, sur place ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pendant à peu près une dizaine de jours.<break time="700ms"/>B.<break time="300ms"/>Avec une amie costumière de l''Opéra.<break time="700ms"/>C.<break time="300ms"/>Sous une chaleur parfois écrasante en journée.<break time="700ms"/>D.<break time="300ms"/>Une mise en scène d''Hamlet vraiment inoubliable.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui t''a le plus marquée ? » porte sur **un souvenir saillant, le moment fort retenu**. Seule D « une mise en scène d''Hamlet vraiment inoubliable » désigne ce moment fort. A donne **la durée** du séjour. B donne **l''accompagnante**. C donne **les conditions climatiques** — piège B2 : « écrasante » est marqué émotionnellement mais reste une description du contexte, pas du moment culturel marquant.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/eab24584-bd70-4988-a099-5f663895c7d4.mp3',
   '36', 'fr-FR-HenriNeural', '2026-05-31 16:49:57.693677+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:23.404486+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000012', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu vis dans ton nouvel appartement depuis combien de temps ?
[Homme] Trois mois pleins, maintenant.
[Femme] Et quel en est le principal inconvénient, finalement ?
[Homme] ...

A. Un bruit constant venant de la rue.
B. Près du parc de Belleville, au cinquième étage.
C. Pour un loyer plutôt raisonnable, c''est vrai.
D. À la suite d''un déménagement franchement éprouvant.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu vis dans ton nouvel appartement depuis combien de temps ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Trois mois pleins, maintenant.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et quel en est le principal inconvénient, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un bruit constant venant de la rue.<break time="700ms"/>B.<break time="300ms"/>Près du parc de Belleville, au cinquième étage.<break time="700ms"/>C.<break time="300ms"/>Pour un loyer plutôt raisonnable, c''est vrai.<break time="700ms"/>D.<break time="300ms"/>À la suite d''un déménagement franchement éprouvant.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel est le principal inconvénient ? » porte sur **un défaut, un point négatif du logement actuel**. Seule A « un bruit constant venant de la rue » désigne un inconvénient. B donne la **localisation**. C donne un **avantage** (loyer raisonnable) — piège B2 : C est le contraire d''un inconvénient. D donne un **désagrément antérieur lié au déménagement**, pas un défaut du logement lui-même.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/4839fd40-f6a8-4a01-9b6e-2861c464740e.mp3',
   '37', 'fr-FR-DeniseNeural', '2026-05-31 16:49:58.097012+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:18.655022+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000013', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Vous aviez un fort taux d''absentéisme, m''as-tu dit ?
[Femme] Oui, c''était devenu très préoccupant chez nous.
[Homme] Qu''as-tu concrètement mis en place pour y remédier ?
[Femme] ...

A. À cause d''un management trop pyramidal au départ.
B. Des entretiens individuels mensuels avec chaque salarié.
C. Auprès de ma direction, qui a soutenu la démarche.
D. Pour retrouver une dynamique d''équipe positive.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Vous aviez un fort taux d''absentéisme, m''as-tu dit ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, c''était devenu très préoccupant chez nous.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''as-tu concrètement mis en place pour y remédier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À cause d''un management trop pyramidal au départ.<break time="700ms"/>B.<break time="300ms"/>Des entretiens individuels mensuels avec chaque salarié.<break time="700ms"/>C.<break time="300ms"/>Auprès de ma direction, qui a soutenu la démarche.<break time="700ms"/>D.<break time="300ms"/>Pour retrouver une dynamique d''équipe positive.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''as-tu mis en place pour y remédier ? » porte sur **l''action / le dispositif concret installé**. Seule B « des entretiens individuels mensuels » désigne cette action. A donne **la cause du problème initial**. C donne **le soutien hiérarchique obtenu** (« auprès de qui as-tu obtenu un appui ? »). D donne **l''objectif visé** par les actions, pas les actions elles-mêmes.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/bdf45efb-357c-42c1-8f23-8e426c466adf.mp3',
   '39', 'fr-FR-HenriNeural', '2026-05-31 16:49:58.400439+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:24.566266+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-2000-0000-000000000014', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as dit que ton fils avait beaucoup changé dernièrement.
[Homme] Oui, on le retrouve presque méconnaissable.
[Femme] Qu''est-ce qui a évolué chez lui, précisément ?
[Homme] ...

A. Depuis son entrée en classe de seconde.
B. Grâce à un professeur particulier remarquable.
C. Une autonomie nouvelle dans tous ses choix.
D. Avec parfois encore quelques moments de doute.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as dit que ton fils avait beaucoup changé dernièrement.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on le retrouve presque méconnaissable.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Qu''est-ce qui a évolué chez lui, précisément ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Depuis son entrée en classe de seconde.<break time="700ms"/>B.<break time="300ms"/>Grâce à un professeur particulier remarquable.<break time="700ms"/>C.<break time="300ms"/>Une autonomie nouvelle dans tous ses choix.<break time="700ms"/>D.<break time="300ms"/>Avec parfois encore quelques moments de doute.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui a évolué chez lui ? » porte sur **la nature du changement observé**. Seule C « une autonomie nouvelle dans tous ses choix » nomme ce changement. A donne **le moment d''origine** du changement (« depuis quand ? »). B donne **le facteur explicatif / la cause** (« grâce à quoi ? »). D donne **une nuance / réserve** sur le changement, pas le changement lui-même.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'PUBLISHED',
   'https://pub-a92171f43ec34a52807a396f17f58ba9.r2.dev/audio/0c7ba4b8-73e1-4d08-9e1c-63c1b53ac4b6.mp3',
   '37', 'fr-FR-DeniseNeural', '2026-05-31 16:49:58.834954+02', '388c0a60-291a-4aa6-ad0e-5acd104065cf',
   '2026-05-27 17:40:30.319281+02', '2026-05-31 16:50:20.753149+02', 'aaaaaaaa-0000-0000-0000-000000000001', NULL),

  ('66666666-00b2-3000-0000-000000000001', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu travailles désormais comme consultant indépendant, c''est cela ?
[Homme] Oui, j''ai quitté mon statut de salarié l''an dernier.
[Femme] En quoi cela diffère-t-il vraiment du portage salarial, finalement ?
[Homme] ...

A. À partir du début de l''année civile dernière, en réalité.
B. Par une autonomie de gestion bien plus large, fondamentalement.
C. Pour développer des missions à plus forte valeur ajoutée.
D. Avec un soulagement assez net, je dois l''avouer.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu travailles désormais comme consultant indépendant, c''est cela ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, j''ai quitté mon statut de salarié l''an dernier.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">En quoi cela diffère-t-il vraiment du portage salarial, finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À partir du début de l''année civile dernière, en réalité.<break time="700ms"/>B.<break time="300ms"/>Par une autonomie de gestion bien plus large, fondamentalement.<break time="700ms"/>C.<break time="300ms"/>Pour développer des missions à plus forte valeur ajoutée.<break time="700ms"/>D.<break time="300ms"/>Avec un soulagement assez net, je dois l''avouer.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Les deux premiers tours établissent le statut actuel (consultant indépendant). « En quoi cela diffère-t-il du portage salarial ? » demande **le trait distinctif entre deux statuts proches**. Seule B « par une autonomie de gestion bien plus large » désigne cette spécificité comparative. A donne le **moment du basculement** (« depuis quand ? »). C donne le **but visé** par le changement (« pour quoi faire ? »). D donne **l''état d''esprit** ressenti (« comment te sens-tu ? ») — piège B2 fin : la préposition « par » de B suggère un moyen, mais sert ici à désigner le critère différenciant.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000002', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu rentres tout juste de ton année d''échange en Argentine ?
[Femme] Oui, je suis arrivée à Paris la semaine dernière.
[Homme] Avec un peu de recul, quel bilan tires-tu de cette expérience ?
[Femme] ...

A. Globalement très enrichissante, malgré quelques difficultés.
B. À Buenos Aires, surtout dans le quartier de Palermo.
C. Grâce à une bourse Erasmus mundus, en réalité.
D. Pendant douze mois pleins, sans aucune interruption.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu rentres tout juste de ton année d''échange en Argentine ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je suis arrivée à Paris la semaine dernière.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec un peu de recul, quel bilan tires-tu de cette expérience ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Globalement très enrichissante, malgré quelques difficultés.<break time="700ms"/>B.<break time="300ms"/>À Buenos Aires, surtout dans le quartier de Palermo.<break time="700ms"/>C.<break time="300ms"/>Grâce à une bourse Erasmus mundus, en réalité.<break time="700ms"/>D.<break time="300ms"/>Pendant douze mois pleins, sans aucune interruption.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel bilan tires-tu ? » porte sur **une évaluation globale et nuancée d''une expérience révolue**. Seule A « globalement très enrichissante, malgré quelques difficultés » formule un jugement d''ensemble équilibré (positif/nuance). B donne le **lieu** du séjour (« où étais-tu ? »). C donne le **moyen de financement** (« comment as-tu financé ? »). D donne la **durée totale** (« combien de temps ? ») — piège B2 fin : « avec un peu de recul » dans la question peut évoquer un temps écoulé, mais le recul est posture d''évaluation, pas durée mesurée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000003', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu m''as parlé d''un échange marquant avec cette philosophe l''an dernier ?
[Homme] Oui, à l''occasion d''un séminaire à Lyon.
[Femme] Et qu''est-ce que cette rencontre t''a vraiment apporté ?
[Homme] ...

A. Au sein d''un petit séminaire d''une vingtaine de chercheurs.
B. Au cours d''un long dîner après sa conférence, plutôt.
C. Une autre manière d''aborder mes propres recherches.
D. Par l''intermédiaire d''un ami commun, en fait.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu m''as parlé d''un échange marquant avec cette philosophe l''an dernier ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, à l''occasion d''un séminaire à Lyon.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et qu''est-ce que cette rencontre t''a vraiment apporté ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au sein d''un petit séminaire d''une vingtaine de chercheurs.<break time="700ms"/>B.<break time="300ms"/>Au cours d''un long dîner après sa conférence, plutôt.<break time="700ms"/>C.<break time="300ms"/>Une autre manière d''aborder mes propres recherches.<break time="700ms"/>D.<break time="300ms"/>Par l''intermédiaire d''un ami commun, en fait.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce que cette rencontre t''a apporté ? » porte sur **le gain intellectuel ou personnel retiré**. Seule C « une autre manière d''aborder mes recherches » désigne un apport transformateur. A donne le **cadre** de l''événement (« où, dans quel contexte ? »). B donne le **moment précis** de l''échange (« à quel moment ? »). D donne **l''entremetteur** de la rencontre (« par qui as-tu été mis en contact ? ») — piège B2 : A et B sont déjà saturées par le 2e tour qui mentionne Lyon, ce qui doit pousser le candidat à chercher autre chose dans la réponse.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000004', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] J''ai entendu que tu avais radicalement changé tes habitudes alimentaires ?
[Femme] Oui, je suis devenue presque entièrement végétale.
[Homme] C''est un sacré virage, tout de même.
[Femme] Oui, je l''assume pleinement aujourd''hui.
[Homme] Mais qu''est-ce qui a vraiment déclenché cette prise de conscience ?
[Femme] ...

A. Au moment de mes trente ans, plus précisément.
B. Avec un peu d''appréhension au début, je l''avoue.
C. Pour préserver durablement ma santé cardiovasculaire.
D. Un documentaire saisissant sur l''élevage industriel.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">J''ai entendu que tu avais radicalement changé tes habitudes alimentaires ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je suis devenue presque entièrement végétale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">C''est un sacré virage, tout de même.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, je l''assume pleinement aujourd''hui.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais qu''est-ce qui a vraiment déclenché cette prise de conscience ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au moment de mes trente ans, plus précisément.<break time="700ms"/>B.<break time="300ms"/>Avec un peu d''appréhension au début, je l''avoue.<break time="700ms"/>C.<break time="300ms"/>Pour préserver durablement ma santé cardiovasculaire.<break time="700ms"/>D.<break time="300ms"/>Un documentaire saisissant sur l''élevage industriel.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue installe un changement assumé. « Qu''est-ce qui a déclenché cette prise de conscience ? » porte sur **l''événement déclencheur, l''élément précis qui a provoqué le basculement**. Seule D « un documentaire saisissant sur l''élevage industriel » désigne ce déclencheur ponctuel. A donne le **moment** du basculement (« quand ? »). B donne **l''état d''esprit initial** (« comment l''as-tu vécu au début ? »). C donne la **finalité poursuivie** (« pour quel objectif ? ») — piège B2 majeur : la cause-déclencheur et le but cible sont souvent confondus, mais le déclencheur précède la décision tandis que le but la justifie après.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000005', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu viens de quitter l''entreprise où tu étais depuis quinze ans ?
[Homme] Oui, mon dernier jour, c''était vendredi.
[Femme] Et là, qu''est-ce qui domine, comme sentiment ?
[Homme] ...

A. Un mélange étrange de soulagement et de nostalgie.
B. À cause d''un climat devenu vraiment pesant.
C. Vers une petite structure beaucoup plus humaine.
D. Au bout de plus de quinze années de service.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu viens de quitter l''entreprise où tu étais depuis quinze ans ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, mon dernier jour, c''était vendredi.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Et là, qu''est-ce qui domine, comme sentiment ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un mélange étrange de soulagement et de nostalgie.<break time="700ms"/>B.<break time="300ms"/>À cause d''un climat devenu vraiment pesant.<break time="700ms"/>C.<break time="300ms"/>Vers une petite structure beaucoup plus humaine.<break time="700ms"/>D.<break time="300ms"/>Au bout de plus de quinze années de service.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Qu''est-ce qui domine, comme sentiment ? » porte sur **l''émotion principale ressentie maintenant**. Seule A « un mélange de soulagement et de nostalgie » nomme un état affectif. B donne **la cause du départ** (« pourquoi es-tu parti ? »). C donne **la destination professionnelle** (« vers où ? »). D donne **la durée passée dans l''entreprise** (« depuis combien de temps ? ») — piège B2 fin : le 1er tour évoque déjà « quinze ans », ce qui rend D redondante par rapport au contexte.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000006', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu hésitais entre rester à Lyon et partir t''installer à Berlin ?
[Femme] Oui, j''ai retourné la question dans tous les sens.
[Homme] Alors, qu''as-tu fini par décider, au bout du compte ?
[Femme] ...

A. Après plus de six mois de tergiversations, tout de même.
B. De partir à Berlin, dès le mois d''octobre prochain.
C. À cause d''une offre d''emploi vraiment exceptionnelle.
D. Avec une vraie peur de tout quitter, je l''avoue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu hésitais entre rester à Lyon et partir t''installer à Berlin ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai retourné la question dans tous les sens.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Alors, qu''as-tu fini par décider, au bout du compte ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Après plus de six mois de tergiversations, tout de même.<break time="700ms"/>B.<break time="300ms"/>De partir à Berlin, dès le mois d''octobre prochain.<break time="700ms"/>C.<break time="300ms"/>À cause d''une offre d''emploi vraiment exceptionnelle.<break time="700ms"/>D.<break time="300ms"/>Avec une vraie peur de tout quitter, je l''avoue.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le contexte (hésitation longue entre deux villes) prépare une question sur **le contenu de la décision finale**. « Qu''as-tu fini par décider ? » appelle l''énoncé du choix retenu. Seule B « de partir à Berlin » formule la décision elle-même. A donne **la durée du processus** de décision (« combien de temps as-tu hésité ? »). C donne **la cause du choix** (« pourquoi ce choix ? ») — piège B2 majeur : la cause justifie la décision mais n''est pas la décision. D donne **l''état d''esprit** accompagnant le choix (« comment le vis-tu ? »).',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000007', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Votre entreprise a vraiment redressé la barre cette année ?
[Homme] Oui, on a renoué avec les bénéfices au troisième trimestre.
[Femme] Quelle stratégie avez-vous adoptée, fondamentalement ?
[Homme] ...

A. À l''échelle de l''ensemble du groupe européen, en réalité.
B. Pour rassurer durablement nos actionnaires historiques.
C. Un recentrage assumé sur nos métiers les plus rentables.
D. Avec une confiance grandissante au fil des mois.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Votre entreprise a vraiment redressé la barre cette année ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, on a renoué avec les bénéfices au troisième trimestre.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Quelle stratégie avez-vous adoptée, fondamentalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À l''échelle de l''ensemble du groupe européen, en réalité.<break time="700ms"/>B.<break time="300ms"/>Pour rassurer durablement nos actionnaires historiques.<break time="700ms"/>C.<break time="300ms"/>Un recentrage assumé sur nos métiers les plus rentables.<break time="700ms"/>D.<break time="300ms"/>Avec une confiance grandissante au fil des mois.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle stratégie avez-vous adoptée ? » porte sur **l''axe directeur, l''orientation choisie**. Seule C « un recentrage assumé sur nos métiers les plus rentables » nomme une stratégie. A donne le **périmètre** d''application (« à quel niveau ? »). B donne le **but visé** (« dans quel objectif ? »). D donne **l''état d''esprit** des dirigeants (« dans quelle disposition ? ») — piège B2 fin : B et C sont proches (une stratégie a un but), mais B nomme la finalité alors que C nomme la méthode.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000008', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as eu un professeur de mathématiques marquant au lycée ?
[Femme] Oui, monsieur Lefèvre, en classe de terminale.
[Homme] Tu en parles souvent, je trouve.
[Femme] C''est vrai, il a beaucoup compté.
[Homme] Mais concrètement, en quoi t''a-t-il vraiment influencée ?
[Femme] ...

A. Au lycée Henri-IV, à Paris, dans le cinquième.
B. Pendant deux années consécutives, en première et terminale.
C. À cause d''une approche très exigeante des démonstrations.
D. Dans ma façon de raisonner, encore aujourd''hui.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as eu un professeur de mathématiques marquant au lycée ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, monsieur Lefèvre, en classe de terminale.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu en parles souvent, je trouve.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">C''est vrai, il a beaucoup compté.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Mais concrètement, en quoi t''a-t-il vraiment influencée ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au lycée Henri-IV, à Paris, dans le cinquième.<break time="700ms"/>B.<break time="300ms"/>Pendant deux années consécutives, en première et terminale.<break time="700ms"/>C.<break time="300ms"/>À cause d''une approche très exigeante des démonstrations.<break time="700ms"/>D.<break time="300ms"/>Dans ma façon de raisonner, encore aujourd''hui.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le dialogue insiste sur l''importance d''un enseignant. « En quoi t''a-t-il vraiment influencée ? » porte sur **le domaine concret de l''influence durable**. Seule D « dans ma façon de raisonner, encore aujourd''hui » désigne ce domaine. A donne le **lieu** d''enseignement. B donne la **durée** de la relation pédagogique. C donne la **cause** de son charisme (« pourquoi t''a-t-il marquée ? ») — piège B2 majeur : cause de l''influence et nature de l''influence sont distinctes, l''une explique l''autre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-000000000009', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Femme] Tu as passé toute ton enfance chez tes grands-parents à la campagne ?
[Homme] Oui, presque chaque vacances scolaires.
[Femme] De cette époque, quel souvenir tu chéris le plus ?
[Homme] ...

A. Les longues parties de cartes du dimanche soir.
B. Dans une vieille ferme normande, à dire vrai.
C. Au tout début des années quatre-vingt-dix, surtout.
D. À cause de parents très souvent en déplacement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Tu as passé toute ton enfance chez tes grands-parents à la campagne ?</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Oui, presque chaque vacances scolaires.</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">De cette époque, quel souvenir tu chéris le plus ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les longues parties de cartes du dimanche soir.<break time="700ms"/>B.<break time="300ms"/>Dans une vieille ferme normande, à dire vrai.<break time="700ms"/>C.<break time="300ms"/>Au tout début des années quatre-vingt-dix, surtout.<break time="700ms"/>D.<break time="300ms"/>À cause de parents très souvent en déplacement.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quel souvenir tu chéris le plus ? » porte sur **un souvenir précis, une image affectivement chargée**. Seule A « les longues parties de cartes du dimanche soir » nomme un souvenir concret. B donne le **lieu** (« où était-ce ? »). C donne **l''époque** (« quand ? »). D donne **la cause** du séjour chez les grands-parents (« pourquoi y étais-tu ? ») — piège B2 fin : D paraît cohérente avec le contexte familial mais ne désigne pas un souvenir.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL),

  ('66666666-00b2-3000-0000-00000000000a', 'B2', 'co_dialogue_b2_implicite', '22222222-0000-0000-0000-000000000001',
   'Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.

[Homme] Tu as fini par réussir ce marathon que tu visais depuis trois ans ?
[Femme] Oui, j''ai franchi la ligne à Berlin en septembre.
[Homme] Quelle difficulté a-t-il fallu surmonter en priorité ?
[Femme] ...

A. Au prix d''un entraînement vraiment quotidien sur la fin.
B. La douleur tenace au genou droit, en seconde moitié de course.
C. Avec une fierté immense en franchissant la ligne, c''est sûr.
D. À l''occasion du marathon de Berlin de septembre dernier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez l''extrait sonore et les quatre propositions. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Tu as fini par réussir ce marathon que tu visais depuis trois ans ?</prosody></voice><voice name="fr-FR-DeniseNeural"><prosody rate="1.0">Oui, j''ai franchi la ligne à Berlin en septembre.</prosody></voice><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle difficulté a-t-il fallu surmonter en priorité ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au prix d''un entraînement vraiment quotidien sur la fin.<break time="700ms"/>B.<break time="300ms"/>La douleur tenace au genou droit, en seconde moitié de course.<break time="700ms"/>C.<break time="300ms"/>Avec une fierté immense en franchissant la ligne, c''est sûr.<break time="700ms"/>D.<break time="300ms"/>À l''occasion du marathon de Berlin de septembre dernier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   '« Quelle difficulté a-t-il fallu surmonter ? » porte sur **l''obstacle majeur rencontré dans l''épreuve elle-même**. Seule B « la douleur tenace au genou droit » nomme un obstacle vécu. A donne **le sacrifice consenti** (« à quel prix ? ») — piège B2 majeur : sacrifice et difficulté sont voisins mais l''un est volontaire, l''autre subi. C donne **l''émotion finale** (« qu''as-tu ressenti ? »). D donne **le lieu et le moment** de l''épreuve.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL,
   NULL, NULL, NULL, NULL, '2026-05-27 17:40:30.407219+02', NULL, NULL, NULL);
