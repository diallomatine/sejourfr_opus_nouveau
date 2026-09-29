-- ============================================================================
-- V814 — TCF CO A2 — lot 12 (thème : voyages (gare/aéroport))
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « voyages (gare/aéroport) », scènes toutes différentes :
--   - 5 items format A (CO_IMAGE, competence_code='co_image_proposition') :
--     une IMAGE est affichée (inline_svg + image_alt_text), l'audio lit
--     uniquement l'intro + les 4 propositions (mono-voix Denise).
--   - 5 items format B (competence_code='co_question_reponse') : l'audio lit
--     une question courte (Henri ou Vivienne) puis 4 réponses (Denise).
--     inline_svg / image_alt_text NULL.
-- Compréhension EXPLICITE (A2) : bonne réponse littérale, distracteurs
-- nettement distincts (autre lieu / action / moment).
-- statut TEXT_VALIDATED : l'audio sera généré par le batch admin.
-- Toutes colonnes audio NULL. Données déterministes, rejouables (dev + recette).
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id,
   inline_svg, image_url, image_alt_text,
   transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES

  -- ----------------------------------------------------------------------------
  -- 1. [Format A] Hall de gare : voyageuse avec valise devant le tableau des départs
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="90" y="20" width="140" height="70" rx="4" fill="#0F1839"/><rect x="100" y="32" width="80" height="8" fill="#E8A317"/><rect x="190" y="32" width="30" height="8" fill="#FFFFFF"/><rect x="100" y="48" width="80" height="8" fill="#E8A317"/><rect x="190" y="48" width="30" height="8" fill="#FFFFFF"/><rect x="100" y="64" width="80" height="8" fill="#E8A317"/><rect x="190" y="64" width="30" height="8" fill="#FFFFFF"/><circle cx="280" cy="45" r="18" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><line x1="280" y1="45" x2="280" y2="33" stroke="#0F1839" stroke-width="2"/><line x1="280" y1="45" x2="289" y2="48" stroke="#0F1839" stroke-width="2"/><circle cx="140" cy="115" r="13" fill="#E8A317"/><rect x="131" y="127" width="18" height="35" fill="#1E3A8C"/><rect x="160" y="135" width="22" height="28" rx="3" fill="#0F6E45"/><rect x="167" y="125" width="8" height="10" fill="#0F1839"/></svg>',
   NULL,
   'Dans le hall d''une gare, une voyageuse avec une valise regarde le grand tableau des horaires de départ ; une horloge est accrochée au mur.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle nage à la piscine municipale.
B. Elle plante des fleurs dans le jardin.
C. Elle regarde les horaires des trains à la gare.
D. Elle peint un tableau dans son atelier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle nage à la piscine municipale.<break time="700ms"/>B.<break time="300ms"/>Elle plante des fleurs dans le jardin.<break time="700ms"/>C.<break time="300ms"/>Elle regarde les horaires des trains à la gare.<break time="700ms"/>D.<break time="300ms"/>Elle peint un tableau dans son atelier.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une voyageuse avec sa valise devant le grand panneau d''affichage d''une gare : elle **consulte les horaires des trains**. Seule C correspond. A (nager) se passerait dans une piscine avec de l''eau, B (planter des fleurs) dans un jardin avec des outils, D (peindre) devant un chevalet dans un atelier — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Quai de gare : un homme monte dans le train avec son sac
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><rect x="120" y="55" width="200" height="85" rx="8" fill="#1E3A8C"/><rect x="140" y="65" width="40" height="75" fill="#0F1839"/><rect x="200" y="70" width="30" height="25" rx="3" fill="#E8ECF8"/><rect x="245" y="70" width="30" height="25" rx="3" fill="#E8ECF8"/><rect x="285" y="70" width="30" height="25" rx="3" fill="#E8ECF8"/><circle cx="160" cy="145" r="10" fill="#0F1839"/><circle cx="240" cy="145" r="10" fill="#0F1839"/><circle cx="295" cy="145" r="10" fill="#0F1839"/><circle cx="90" cy="85" r="13" fill="#0F1839"/><rect x="81" y="97" width="18" height="38" fill="#168F5B"/><rect x="60" y="115" width="24" height="18" rx="3" fill="#E8A317"/><path d="M 60 115 Q 72 103 84 115" stroke="#0F1839" stroke-width="3" fill="none"/></svg>',
   NULL,
   'Sur le quai d''une gare, un homme avec un sac de voyage s''avance vers la porte ouverte d''un train bleu.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il monte dans le train avec son sac.
B. Il tond la pelouse devant la maison.
C. Il lit un roman dans son lit.
D. Il lave la vaisselle dans la cuisine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il monte dans le train avec son sac.<break time="700ms"/>B.<break time="300ms"/>Il tond la pelouse devant la maison.<break time="700ms"/>C.<break time="300ms"/>Il lit un roman dans son lit.<break time="700ms"/>D.<break time="300ms"/>Il lave la vaisselle dans la cuisine.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme, sac de voyage à la main, devant la porte ouverte d''un train à quai : il **monte dans le train**. Seule A décrit la scène. B (tondre la pelouse) se passerait dans un jardin avec une tondeuse, C (lire au lit) dans une chambre, D (laver la vaisselle) devant un évier de cuisine — aucun de ces lieux n''est représenté.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Aéroport : une voyageuse enregistre sa valise au comptoir
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="200" y="20" width="110" height="60" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><ellipse cx="252" cy="50" rx="30" ry="8" fill="#1E3A8C"/><polygon points="245,50 225,66 256,53" fill="#15296B"/><polygon points="278,48 290,35 282,51" fill="#15296B"/><rect x="30" y="110" width="110" height="50" fill="#1E3A8C"/><circle cx="70" cy="85" r="12" fill="#0F1839"/><rect x="62" y="96" width="16" height="16" fill="#FFFFFF"/><rect x="150" y="135" width="60" height="10" fill="#0F1839"/><rect x="165" y="105" width="28" height="30" rx="3" fill="#E8A317"/><rect x="174" y="96" width="10" height="10" fill="#0F1839"/><circle cx="240" cy="105" r="13" fill="#E8A317"/><rect x="231" y="117" width="18" height="40" fill="#0F6E45"/></svg>',
   NULL,
   'Au comptoir d''enregistrement d''un aéroport, une voyageuse dépose sa valise sur le tapis devant l''agent ; un avion est visible par la fenêtre.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle promène son chien dans le parc.
B. Elle écrit une carte postale au café.
C. Elle coupe du pain à la boulangerie.
D. Elle enregistre sa valise à l''aéroport.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle promène son chien dans le parc.<break time="700ms"/>B.<break time="300ms"/>Elle écrit une carte postale au café.<break time="700ms"/>C.<break time="300ms"/>Elle coupe du pain à la boulangerie.<break time="700ms"/>D.<break time="300ms"/>Elle enregistre sa valise à l''aéroport.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une voyageuse qui pose sa valise sur le tapis d''un comptoir, avec un avion derrière la fenêtre : elle **enregistre son bagage à l''aéroport**. Seule D correspond. A (promener un chien) se passerait dans un parc avec un animal, B (écrire une carte postale) à une table de café avec un stylo, C (couper du pain) dans une boulangerie — rien de cela n''est visible.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Salle d'embarquement : passagers assis, avion derrière la baie vitrée
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="165" width="320" height="35" fill="#15296B"/><rect x="20" y="20" width="280" height="75" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><ellipse cx="160" cy="60" rx="55" ry="14" fill="#1E3A8C"/><polygon points="150,60 115,86 162,65" fill="#15296B"/><polygon points="205,56 222,38 210,60" fill="#15296B"/><circle cx="140" cy="58" r="3" fill="#FFFFFF"/><circle cx="158" cy="58" r="3" fill="#FFFFFF"/><circle cx="176" cy="58" r="3" fill="#FFFFFF"/><rect x="50" y="135" width="220" height="10" fill="#1E3A8C"/><rect x="60" y="145" width="8" height="20" fill="#0F1839"/><rect x="250" y="145" width="8" height="20" fill="#0F1839"/><circle cx="90" cy="110" r="12" fill="#0F1839"/><rect x="82" y="121" width="16" height="14" fill="#168F5B"/><circle cx="160" cy="110" r="12" fill="#E8A317"/><rect x="152" y="121" width="16" height="14" fill="#1E3A8C"/><circle cx="230" cy="110" r="12" fill="#0F1839"/><rect x="222" y="121" width="16" height="14" fill="#0F6E45"/><rect x="280" y="115" width="20" height="26" rx="3" fill="#E8A317"/></svg>',
   NULL,
   'Dans la salle d''embarquement d''un aéroport, trois passagers assis sur un banc attendent ; un avion est visible derrière la grande baie vitrée.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils dansent pendant une fête de mariage.
B. Ils attendent leur avion dans la salle d''embarquement.
C. Ils visitent un vieux château.
D. Ils cueillent des pommes dans un verger.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils dansent pendant une fête de mariage.<break time="700ms"/>B.<break time="300ms"/>Ils attendent leur avion dans la salle d''embarquement.<break time="700ms"/>C.<break time="300ms"/>Ils visitent un vieux château.<break time="700ms"/>D.<break time="300ms"/>Ils cueillent des pommes dans un verger.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre des passagers assis sur un banc face à une baie vitrée derrière laquelle on voit un avion : ils **attendent leur vol**. Seule B correspond. A (danser à un mariage) montrerait une piste de danse et de la musique, C (visiter un château) de vieilles pierres et des tours, D (cueillir des pommes) des arbres fruitiers en extérieur.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Guichet de gare : un client achète un billet à l'agent
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="40" y="40" width="120" height="120" fill="#1E3A8C"/><rect x="55" y="55" width="90" height="60" fill="#E8ECF8" stroke="#0F1839" stroke-width="2"/><circle cx="100" cy="85" r="12" fill="#0F1839"/><rect x="92" y="97" width="16" height="18" fill="#FFFFFF"/><rect x="50" y="115" width="100" height="8" fill="#0F1839"/><rect x="115" y="106" width="20" height="9" fill="#E8A317"/><circle cx="210" cy="80" r="13" fill="#E8A317"/><rect x="201" y="92" width="18" height="45" fill="#0F6E45"/><rect x="170" y="100" width="32" height="7" fill="#0F6E45"/><rect x="240" y="120" width="24" height="30" rx="3" fill="#1E3A8C"/><rect x="248" y="110" width="8" height="10" fill="#0F1839"/></svg>',
   NULL,
   'Au guichet d''une gare, un client accompagné d''une valise tend la main vers le comptoir où l''agent lui donne un billet.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il achète un billet au guichet de la gare.
B. Il prépare un gâteau dans la cuisine.
C. Il accroche un cadre au mur du salon.
D. Il lave sa voiture devant le garage.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il achète un billet au guichet de la gare.<break time="700ms"/>B.<break time="300ms"/>Il prépare un gâteau dans la cuisine.<break time="700ms"/>C.<break time="300ms"/>Il accroche un cadre au mur du salon.<break time="700ms"/>D.<break time="300ms"/>Il lave sa voiture devant le garage.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un client avec une valise devant le guichet d''une gare, où l''agent lui tend un billet : il **achète son billet de train**. Seule A correspond. B (préparer un gâteau) se passerait dans une cuisine avec un four, C (accrocher un cadre) dans un salon avec un marteau, D (laver une voiture) dehors avec un seau d''eau.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « À quelle heure part le prochain train pour Lyon ? » (heure) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] À quelle heure part le prochain train pour Lyon ?

A. Du quai numéro sept.
B. Avec ma sœur Lucia.
C. À seize heures dix.
D. Parce que je vais voir un ami.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure part le prochain train pour Lyon ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Du quai numéro sept.<break time="700ms"/>B.<break time="300ms"/>Avec ma sœur Lucia.<break time="700ms"/>C.<break time="300ms"/>À seize heures dix.<break time="700ms"/>D.<break time="300ms"/>Parce que je vais voir un ami.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure part le train ? » porte sur **l''heure de départ**. Seule C « à seize heures dix » donne une heure. A indique le quai et répondrait à « d''où part le train ? », B désigne une personne et répondrait à « avec qui voyages-tu ? », D exprime une cause et répondrait à « pourquoi vas-tu à Lyon ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Où se trouve la porte d'embarquement douze ? » (lieu) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pardon, où se trouve la porte d''embarquement numéro douze ?

A. Dans deux heures environ.
B. Au fond du couloir, à droite.
C. Un petit sac et une valise.
D. Avec mon passeport et mon billet.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pardon, où se trouve la porte d''embarquement numéro douze ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans deux heures environ.<break time="700ms"/>B.<break time="300ms"/>Au fond du couloir, à droite.<break time="700ms"/>C.<break time="300ms"/>Un petit sac et une valise.<break time="700ms"/>D.<break time="300ms"/>Avec mon passeport et mon billet.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où se trouve la porte d''embarquement ? » porte sur **un lieu**. Seule B « au fond du couloir, à droite » indique une direction. A donne un délai et répondrait à « quand embarquez-vous ? », C énumère des bagages et répondrait à « qu''emportez-vous ? », D cite des documents et répondrait à « avec quoi voyagez-vous ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Combien coûte un aller-retour pour Nantes ? » (prix) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Combien coûte un billet aller-retour pour Nantes ?

A. Le train direct de neuf heures.
B. En première classe, près de la fenêtre.
C. Trois fois par semaine.
D. Quarante-deux euros, monsieur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Combien coûte un billet aller-retour pour Nantes ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le train direct de neuf heures.<break time="700ms"/>B.<break time="300ms"/>En première classe, près de la fenêtre.<break time="700ms"/>C.<break time="300ms"/>Trois fois par semaine.<break time="700ms"/>D.<break time="300ms"/>Quarante-deux euros, monsieur.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte un billet ? » porte sur **le prix**. Seule D « quarante-deux euros » donne un montant. A désigne un train précis et répondrait à « quel train prenez-vous ? », B décrit la place et répondrait à « où voulez-vous vous asseoir ? », C indique une fréquence et répondrait à « combien de fois voyagez-vous ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Combien de bagages emportes-tu ? » (quantité) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien de bagages est-ce que tu emportes pour ton voyage ?

A. Une valise et un sac à dos.
B. À l''aéroport de Bordeaux.
C. Demain matin, très tôt.
D. Avec mon cousin Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien de bagages est-ce que tu emportes pour ton voyage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une valise et un sac à dos.<break time="700ms"/>B.<break time="300ms"/>À l''aéroport de Bordeaux.<break time="700ms"/>C.<break time="300ms"/>Demain matin, très tôt.<break time="700ms"/>D.<break time="300ms"/>Avec mon cousin Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien de bagages emportes-tu ? » porte sur **le nombre de bagages**. Seule A « une valise et un sac à dos » énumère des bagages. B indique un lieu et répondrait à « d''où décolles-tu ? », C donne un moment et répondrait à « quand pars-tu ? », D désigne une personne et répondrait à « avec qui voyages-tu ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Avec qui pars-tu à Marseille ? » (personne) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a00c-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Avec qui est-ce que tu pars à Marseille ?

A. Par le train de nuit.
B. Pendant une semaine.
C. Avec ma collègue Wei.
D. Pour me reposer au bord de la mer.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avec qui est-ce que tu pars à Marseille ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Par le train de nuit.<break time="700ms"/>B.<break time="300ms"/>Pendant une semaine.<break time="700ms"/>C.<break time="300ms"/>Avec ma collègue Wei.<break time="700ms"/>D.<break time="300ms"/>Pour me reposer au bord de la mer.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Avec qui pars-tu ? » porte sur **la personne qui accompagne**. Seule C « avec ma collègue Wei » désigne quelqu''un. A indique le moyen de transport et répondrait à « comment voyages-tu ? », B donne une durée et répondrait à « combien de temps restes-tu ? », D exprime un but et répondrait à « pourquoi pars-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a00c-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « voyages (gare/aéroport) », 10 scènes toutes différentes :
--     hall de gare (tableau des départs), quai (montée dans le train),
--     comptoir d'enregistrement aéroport, salle d'embarquement, guichet
--     (achat de billet), heure de départ du train, porte d'embarquement
--     (lieu), prix d'un aller-retour, nombre de bagages, compagnon de voyage.
--     Aucun thème interdit (repas, transports & rue, commerces, santé, école,
--     maison, loisirs, météo, travail, famille, services, fêtes, nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×3 : items 6,8,10)
--     / Vivienne (×2 : items 7,9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 2,5,9), B=2 (items 4,7),
--     C=3 (items 1,6,10), D=2 (items 3,8) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, pas de texte,
--     rouge absent (aucun élément critique requis), scène lisible en < 2 s,
--     alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Lucia, Amadou, Wei ;
--     villes : Lyon, Nantes, Bordeaux, Marseille).
-- ============================================================================
