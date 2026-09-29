-- ============================================================================
-- V804 — TCF CO A2 — lot 02 (thème : transports & rue)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « transports & rue », scènes toutes différentes :
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
  -- 1. [Format A] Arrêt de bus : une femme attend sous l'abribus, panneau BUS
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="55" y="55" width="140" height="10" fill="#1E3A8C"/><rect x="60" y="65" width="6" height="95" fill="#0F1839"/><rect x="184" y="65" width="6" height="95" fill="#0F1839"/><rect x="70" y="128" width="70" height="7" fill="#1E3A8C"/><rect x="74" y="135" width="6" height="25" fill="#0F1839"/><rect x="130" y="135" width="6" height="25" fill="#0F1839"/><rect x="248" y="70" width="6" height="90" fill="#0F1839"/><rect x="226" y="42" width="50" height="28" rx="4" fill="#1E3A8C"/><text x="251" y="62" font-family="Arial" font-size="14" font-weight="bold" fill="#FFFFFF" text-anchor="middle">BUS</text><circle cx="160" cy="88" r="12" fill="#E8A317"/><rect x="152" y="100" width="16" height="38" fill="#168F5B"/><rect x="154" y="138" width="5" height="22" fill="#0F1839"/><rect x="161" y="138" width="5" height="22" fill="#0F1839"/></svg>',
   NULL,
   'Une femme attend debout sous un abribus avec un banc, à côté d''un panneau « BUS », au bord de la rue.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle nage à la piscine municipale.
B. Elle achète du pain à la boulangerie.
C. Elle attend le bus à l''arrêt.
D. Elle lit un roman à la bibliothèque.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle nage à la piscine municipale.<break time="700ms"/>B.<break time="300ms"/>Elle achète du pain à la boulangerie.<break time="700ms"/>C.<break time="300ms"/>Elle attend le bus à l''arrêt.<break time="700ms"/>D.<break time="300ms"/>Elle lit un roman à la bibliothèque.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme debout sous un abribus, à côté d''un panneau « BUS » : elle **attend le bus**. Seule C correspond à la scène. A (nager) se passerait dans une piscine, B (acheter du pain) dans une boulangerie, D (lire un roman) dans une bibliothèque — aucun de ces lieux n''apparaît sur l''image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Passage piéton : feu rouge, voiture arrêtée, piéton qui traverse
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="140" width="320" height="60" fill="#15296B"/><rect x="130" y="150" width="16" height="42" fill="#FFFFFF"/><rect x="158" y="150" width="16" height="42" fill="#FFFFFF"/><rect x="186" y="150" width="16" height="42" fill="#FFFFFF"/><rect x="214" y="150" width="16" height="42" fill="#FFFFFF"/><rect x="30" y="96" width="44" height="18" rx="4" fill="#1E3A8C"/><rect x="34" y="99" width="36" height="12" fill="#E8ECF8"/><rect x="14" y="112" width="78" height="24" rx="6" fill="#1E3A8C"/><circle cx="32" cy="138" r="9" fill="#0F1839"/><circle cx="32" cy="138" r="3" fill="#FFFFFF"/><circle cx="78" cy="138" r="9" fill="#0F1839"/><circle cx="78" cy="138" r="3" fill="#FFFFFF"/><rect x="108" y="74" width="6" height="66" fill="#0F1839"/><rect x="98" y="34" width="26" height="40" rx="5" fill="#0F1839"/><circle cx="111" cy="46" r="7" fill="#E1372F"/><circle cx="111" cy="62" r="7" fill="#E8ECF8"/><circle cx="180" cy="92" r="12" fill="#0F1839"/><rect x="172" y="104" width="16" height="36" fill="#E8A317"/><rect x="174" y="140" width="5" height="22" fill="#0F1839"/><rect x="181" y="140" width="5" height="22" fill="#0F1839"/></svg>',
   NULL,
   'Au feu rouge, une voiture est arrêtée et un piéton traverse la rue sur les bandes blanches du passage piéton.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Un piéton traverse au passage piéton.
B. Un jardinier tond la pelouse du parc.
C. Un client paie ses courses à la caisse.
D. Un enfant joue au ballon dans le jardin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un piéton traverse au passage piéton.<break time="700ms"/>B.<break time="300ms"/>Un jardinier tond la pelouse du parc.<break time="700ms"/>C.<break time="300ms"/>Un client paie ses courses à la caisse.<break time="700ms"/>D.<break time="300ms"/>Un enfant joue au ballon dans le jardin.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un feu rouge, une voiture arrêtée et une personne qui marche sur les bandes blanches : **un piéton traverse au passage piéton**. Seule A décrit la scène. B (tondre la pelouse) se passerait dans un parc avec une tondeuse, C (payer ses courses) dans un magasin devant une caisse, D (jouer au ballon) dans un jardin avec un enfant et un ballon.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Vélo en ville : une cycliste roule dans la rue entre les immeubles
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="15" y="40" width="60" height="110" fill="#1E3A8C"/><rect x="25" y="52" width="14" height="14" fill="#FFFFFF"/><rect x="49" y="52" width="14" height="14" fill="#FFFFFF"/><rect x="25" y="80" width="14" height="14" fill="#FFFFFF"/><rect x="49" y="80" width="14" height="14" fill="#FFFFFF"/><rect x="25" y="108" width="14" height="14" fill="#FFFFFF"/><rect x="49" y="108" width="14" height="14" fill="#FFFFFF"/><rect x="245" y="55" width="60" height="95" fill="#0F1839"/><rect x="255" y="67" width="14" height="14" fill="#E8ECF8"/><rect x="279" y="67" width="14" height="14" fill="#E8ECF8"/><rect x="255" y="95" width="14" height="14" fill="#E8ECF8"/><rect x="279" y="95" width="14" height="14" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><circle cx="125" cy="158" r="22" fill="none" stroke="#0F1839" stroke-width="5"/><circle cx="200" cy="158" r="22" fill="none" stroke="#0F1839" stroke-width="5"/><path d="M 125 158 L 160 118 L 200 158" fill="none" stroke="#1E3A8C" stroke-width="5"/><line x1="160" y1="118" x2="170" y2="158" stroke="#1E3A8C" stroke-width="5"/><circle cx="170" cy="76" r="11" fill="#0F1839"/><rect x="160" y="87" width="16" height="33" fill="#E8A317"/><line x1="168" y1="95" x2="198" y2="130" stroke="#E8A317" stroke-width="5"/><line x1="166" y1="120" x2="158" y2="148" stroke="#0F1839" stroke-width="5"/></svg>',
   NULL,
   'Une femme roule à vélo sur la chaussée d''une rue bordée de deux immeubles avec des fenêtres.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle étend le linge dans le jardin.
B. Elle téléphone assise sur un banc.
C. Elle peint les murs de sa chambre.
D. Elle fait du vélo dans la rue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle étend le linge dans le jardin.<break time="700ms"/>B.<break time="300ms"/>Elle téléphone assise sur un banc.<break time="700ms"/>C.<break time="300ms"/>Elle peint les murs de sa chambre.<break time="700ms"/>D.<break time="300ms"/>Elle fait du vélo dans la rue.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme sur un vélo, entre des immeubles, sur la chaussée : elle **fait du vélo dans la rue**. Seule D correspond. A (étendre le linge) montrerait un fil et du linge dans un jardin, B (téléphoner sur un banc) une personne assise avec un téléphone, C (peindre des murs) un rouleau et un pot de peinture à l''intérieur d''une chambre.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Station de tramway : la rame arrive, deux passagers sur le quai
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><line x1="0" y1="52" x2="320" y2="52" stroke="#0F1839" stroke-width="2"/><rect x="0" y="158" width="320" height="6" fill="#0F1839"/><rect x="0" y="164" width="320" height="36" fill="#15296B"/><path d="M 70 75 L 95 52 L 120 75" fill="none" stroke="#0F1839" stroke-width="3"/><rect x="15" y="75" width="190" height="80" rx="12" fill="#1E3A8C"/><rect x="30" y="88" width="28" height="26" rx="3" fill="#FFFFFF"/><rect x="68" y="88" width="28" height="26" rx="3" fill="#FFFFFF"/><rect x="106" y="88" width="28" height="26" rx="3" fill="#FFFFFF"/><rect x="144" y="88" width="28" height="26" rx="3" fill="#FFFFFF"/><rect x="178" y="88" width="20" height="58" fill="#E8ECF8"/><circle cx="198" cy="142" r="5" fill="#E8A317"/><circle cx="250" cy="105" r="11" fill="#E8A317"/><rect x="242" y="116" width="16" height="48" fill="#168F5B"/><circle cx="288" cy="112" r="11" fill="#0F1839"/><rect x="280" y="123" width="16" height="41" fill="#1E3A8C"/></svg>',
   NULL,
   'Un tramway bleu avec de grandes fenêtres arrive le long du quai d''une station ; deux personnes attendent debout sur le quai.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Les élèves écoutent le professeur en classe.
B. Des passagers attendent le tramway sur le quai.
C. Des musiciens donnent un concert sur scène.
D. Des ouvriers réparent le toit d''une maison.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les élèves écoutent le professeur en classe.<break time="700ms"/>B.<break time="300ms"/>Des passagers attendent le tramway sur le quai.<break time="700ms"/>C.<break time="300ms"/>Des musiciens donnent un concert sur scène.<break time="700ms"/>D.<break time="300ms"/>Des ouvriers réparent le toit d''une maison.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une rame bleue le long d''un quai et deux personnes debout qui patientent : **des passagers attendent le tramway**. Seule B correspond. A (écouter le professeur) se passerait dans une salle de classe, C (donner un concert) sur une scène avec des instruments, D (réparer un toit) sur une maison avec une échelle et des outils.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Taxi : un homme lève la main pour arrêter un taxi (panneau TAXI)
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><rect x="145" y="60" width="48" height="18" rx="3" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><text x="169" y="74" font-family="Arial" font-size="12" font-weight="bold" fill="#1E3A8C" text-anchor="middle">TAXI</text><rect x="125" y="80" width="85" height="28" rx="6" fill="#E8A317"/><rect x="131" y="85" width="73" height="20" rx="3" fill="#FFFFFF"/><rect x="95" y="105" width="160" height="38" rx="8" fill="#E8A317"/><circle cx="125" cy="145" r="10" fill="#0F1839"/><circle cx="125" cy="145" r="3" fill="#FFFFFF"/><circle cx="225" cy="145" r="10" fill="#0F1839"/><circle cx="225" cy="145" r="3" fill="#FFFFFF"/><circle cx="45" cy="82" r="12" fill="#0F1839"/><rect x="37" y="94" width="16" height="42" fill="#1E3A8C"/><line x1="42" y1="98" x2="24" y2="68" stroke="#1E3A8C" stroke-width="6"/><rect x="39" y="136" width="5" height="14" fill="#0F1839"/><rect x="47" y="136" width="5" height="14" fill="#0F1839"/></svg>',
   NULL,
   'Dans la rue, un homme lève la main pour arrêter un taxi qui porte un panneau « TAXI » sur le toit.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il arrose les fleurs de son balcon.
B. Il joue de la guitare dans le salon.
C. Il appelle un taxi dans la rue.
D. Il nage à la piscine du quartier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il arrose les fleurs de son balcon.<break time="700ms"/>B.<break time="300ms"/>Il joue de la guitare dans le salon.<break time="700ms"/>C.<break time="300ms"/>Il appelle un taxi dans la rue.<break time="700ms"/>D.<break time="300ms"/>Il nage à la piscine du quartier.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme qui lève la main vers une voiture portant un panneau « TAXI » : il **appelle un taxi dans la rue**. Seule C correspond. A (arroser des fleurs) se passerait sur un balcon avec un arrosoir, B (jouer de la guitare) dans un salon avec l''instrument, D (nager) dans une piscine — rien de tout cela n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Comment vas-tu au travail le matin ? » (moyen) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Comment est-ce que tu vas au travail le matin ?

A. À huit heures moins le quart.
B. Je prends le bus, la ligne douze.
C. Dans le centre-ville, près de la mairie.
D. Avec mon collègue Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Comment est-ce que tu vas au travail le matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À huit heures moins le quart.<break time="700ms"/>B.<break time="300ms"/>Je prends le bus, la ligne douze.<break time="700ms"/>C.<break time="300ms"/>Dans le centre-ville, près de la mairie.<break time="700ms"/>D.<break time="300ms"/>Avec mon collègue Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Comment est-ce que tu vas au travail ? » porte sur **le moyen de transport**. Seule B « je prends le bus, la ligne douze » indique un moyen de déplacement. A donne une heure et répondrait à « à quelle heure pars-tu ? », C indique un lieu et répondrait à « où travailles-tu ? », D désigne une personne et répondrait à « avec qui voyages-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « À quelle heure passe le prochain tramway ? » (heure) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] À quelle heure passe le prochain tramway ?

A. Devant la station Liberté.
B. Un euro soixante le ticket.
C. Avec mon frère Rachid.
D. À neuf heures dix exactement.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">À quelle heure passe le prochain tramway ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Devant la station Liberté.<break time="700ms"/>B.<break time="300ms"/>Un euro soixante le ticket.<break time="700ms"/>C.<break time="300ms"/>Avec mon frère Rachid.<break time="700ms"/>D.<break time="300ms"/>À neuf heures dix exactement.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure passe le prochain tramway ? » porte sur **l''heure**. Seule D « à neuf heures dix » donne un horaire. A indique un lieu et répondrait à « où s''arrête-t-il ? », B donne un prix et répondrait à « combien coûte le ticket ? », C désigne une personne et répondrait à « avec qui prends-tu le tramway ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Où se trouve l'arrêt de bus le plus proche ? » (lieu) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où se trouve l''arrêt de bus le plus proche ?

A. Sur la place de la Fontaine, à gauche.
B. C''est le bus numéro sept.
C. Dans une vingtaine de minutes.
D. Avec ma voisine Lucia.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où se trouve l''arrêt de bus le plus proche ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la place de la Fontaine, à gauche.<break time="700ms"/>B.<break time="300ms"/>C''est le bus numéro sept.<break time="700ms"/>C.<break time="300ms"/>Dans une vingtaine de minutes.<break time="700ms"/>D.<break time="300ms"/>Avec ma voisine Lucia.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où se trouve l''arrêt de bus ? » porte sur **le lieu**. Seule A « sur la place de la Fontaine » indique un endroit. B nomme une ligne et répondrait à « quel bus faut-il prendre ? », C donne un délai et répondrait à « quand passe le prochain bus ? », D désigne une personne et répondrait à « avec qui attends-tu le bus ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Combien coûte un ticket de métro ? » (prix) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien coûte un ticket de métro ?

A. Au guichet ou à la machine.
B. Il est valable pendant une heure.
C. Un euro quatre-vingt-dix à l''unité.
D. Toutes les quatre minutes environ.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien coûte un ticket de métro ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au guichet ou à la machine.<break time="700ms"/>B.<break time="300ms"/>Il est valable pendant une heure.<break time="700ms"/>C.<break time="300ms"/>Un euro quatre-vingt-dix à l''unité.<break time="700ms"/>D.<break time="300ms"/>Toutes les quatre minutes environ.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûte un ticket de métro ? » porte sur **le prix**. Seule C « un euro quatre-vingt-dix » donne un montant. A indique le point de vente et répondrait à « où achète-t-on le ticket ? », B précise la durée de validité et répondrait à « combien de temps est-il valable ? », D donne une fréquence et répondrait à « tous les combien passe le métro ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Pourquoi prends-tu ton vélo pour aller en ville ? » (cause) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a002-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Pourquoi est-ce que tu prends ton vélo pour aller en ville ?

A. Sur la piste cyclable du boulevard.
B. Parce que c''est plus rapide que la voiture.
C. Depuis le mois de mars.
D. Un quart d''heure environ.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Pourquoi est-ce que tu prends ton vélo pour aller en ville ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Sur la piste cyclable du boulevard.<break time="700ms"/>B.<break time="300ms"/>Parce que c''est plus rapide que la voiture.<break time="700ms"/>C.<break time="300ms"/>Depuis le mois de mars.<break time="700ms"/>D.<break time="300ms"/>Un quart d''heure environ.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi est-ce que tu prends ton vélo ? » porte sur **la cause**. Seule B « parce que c''est plus rapide que la voiture » donne une raison. A indique un lieu et répondrait à « où roules-tu ? », C donne un point de départ dans le temps et répondrait à « depuis quand fais-tu du vélo ? », D donne une durée et répondrait à « combien de temps dure le trajet ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a002-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « transports & rue », 10 scènes toutes différentes :
--     arrêt de bus (attente), passage piéton (feu rouge), vélo en ville,
--     station de tramway (quai), taxi (hélé dans la rue), trajet travail
--     (moyen), prochain tramway (heure), arrêt le plus proche (lieu),
--     ticket de métro (prix), vélo en ville (cause). Aucun thème interdit
--     (pas de repas, commerces, santé, école, logement, loisirs, météo,
--     travail, famille, services, voyages gare/aéroport, fêtes, nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×3 : items 6,8,10)
--     / Vivienne (×2 : items 7,9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=2 (items 2,8), B=3 (items 4,6,10),
--     C=3 (items 1,5,9), D=2 (items 3,7) — 4 positions utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / cause).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, texte seulement
--     quand il fait partie de la scène (panneaux « BUS » et « TAXI »,
--     police Arial), rouge #E1372F utilisé uniquement pour le feu rouge
--     (élément critique, item 2), scène lisible en < 2 s, alt_text présent
--     sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Amadou, Rachid,
--     Lucia).
-- ============================================================================
