-- ============================================================================
-- V806 — TCF CO A2 — lot 04 (thème : santé & pharmacie)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « santé & pharmacie », scènes toutes différentes :
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
  -- 1. [Format A] Pharmacie : une cliente achète des médicaments au comptoir
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="118" y="15" width="84" height="44" fill="#FFFFFF" stroke="#168F5B" stroke-width="3"/><rect x="152" y="22" width="16" height="30" fill="#168F5B"/><rect x="145" y="29" width="30" height="16" fill="#168F5B"/><rect x="240" y="60" width="62" height="70" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="246" y="70" width="14" height="18" fill="#E8A317"/><rect x="264" y="70" width="14" height="18" fill="#168F5B"/><rect x="282" y="70" width="14" height="18" fill="#1E3A8C"/><rect x="246" y="98" width="14" height="18" fill="#168F5B"/><rect x="264" y="98" width="14" height="18" fill="#E8A317"/><rect x="282" y="98" width="14" height="18" fill="#0F6E45"/><rect x="80" y="118" width="150" height="42" fill="#1E3A8C"/><circle cx="180" cy="80" r="13" fill="#0F1839"/><rect x="170" y="93" width="20" height="25" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><rect x="130" y="106" width="24" height="12" rx="2" fill="#FFFFFF" stroke="#168F5B" stroke-width="2"/><circle cx="55" cy="78" r="13" fill="#E8A317"/><rect x="45" y="91" width="20" height="50" fill="#0F6E45"/></svg>',
   NULL,
   'Dans une pharmacie avec une croix verte au-dessus du comptoir, une pharmacienne en blouse blanche tend une boîte de médicaments à une cliente ; des boîtes colorées sont rangées sur une étagère.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle retire de l''argent à la banque.
B. Elle achète du pain à la boulangerie.
C. Elle achète des médicaments à la pharmacie.
D. Elle choisit des fleurs chez le fleuriste.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle retire de l''argent à la banque.<break time="700ms"/>B.<break time="300ms"/>Elle achète du pain à la boulangerie.<break time="700ms"/>C.<break time="300ms"/>Elle achète des médicaments à la pharmacie.<break time="700ms"/>D.<break time="300ms"/>Elle choisit des fleurs chez le fleuriste.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une croix verte, un comptoir et une boîte de médicaments : c''est **une pharmacie**. Seule C correspond à la scène. A (retirer de l''argent) décrirait une banque avec un distributeur, B (acheter du pain) une boulangerie avec des baguettes, D (choisir des fleurs) une boutique de fleuriste — aucun de ces lieux n''est représenté.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Cabinet médical : le médecin examine un patient au stéthoscope
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="162" width="320" height="38" fill="#15296B"/><rect x="30" y="25" width="50" height="38" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="50" y="32" width="10" height="24" fill="#1E3A8C"/><rect x="43" y="39" width="24" height="10" fill="#1E3A8C"/><rect x="170" y="118" width="120" height="14" fill="#1E3A8C"/><rect x="180" y="132" width="10" height="30" fill="#0F1839"/><rect x="272" y="132" width="10" height="30" fill="#0F1839"/><circle cx="228" cy="76" r="13" fill="#0F1839"/><rect x="218" y="89" width="20" height="29" fill="#168F5B"/><circle cx="110" cy="66" r="14" fill="#E8A317"/><rect x="98" y="81" width="24" height="58" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><path d="M 122 92 Q 150 104 200 100" stroke="#0F1839" stroke-width="3" fill="none"/><circle cx="203" cy="100" r="5" fill="#0F1839"/></svg>',
   NULL,
   'Dans un cabinet médical, un médecin en blouse blanche écoute avec son stéthoscope un patient assis sur la table d''examen ; une croix bleue est affichée au mur.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Le médecin examine un patient.
B. Le boulanger prépare des baguettes.
C. Le mécanicien change une roue.
D. Le peintre repeint un mur.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le médecin examine un patient.<break time="700ms"/>B.<break time="300ms"/>Le boulanger prépare des baguettes.<break time="700ms"/>C.<break time="300ms"/>Le mécanicien change une roue.<break time="700ms"/>D.<break time="300ms"/>Le peintre repeint un mur.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un médecin en blouse blanche avec un stéthoscope devant un patient assis sur la table d''examen : il **examine un patient**. Seule A correspond. B (le boulanger) évoquerait un fournil et du pain, C (le mécanicien) un garage et une voiture, D (le peintre) un pinceau et un pot de peinture — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] À la maison : un homme malade reste couché au lit
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="165" width="320" height="35" fill="#15296B"/><rect x="35" y="78" width="14" height="87" fill="#0F1839"/><rect x="240" y="100" width="12" height="65" fill="#0F1839"/><rect x="42" y="105" width="200" height="45" fill="#1E3A8C"/><rect x="52" y="92" width="44" height="18" rx="6" fill="#FFFFFF"/><circle cx="74" cy="84" r="13" fill="#E8A317"/><ellipse cx="150" cy="105" rx="45" ry="10" fill="#15296B"/><rect x="262" y="118" width="44" height="47" fill="#0F6E45"/><rect x="270" y="104" width="10" height="14" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="1"/><rect x="286" y="108" width="16" height="10" fill="#E8A317"/><rect x="120" y="25" width="60" height="44" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><circle cx="150" cy="47" r="12" fill="#E8A317"/></svg>',
   NULL,
   'Dans une chambre, un homme est couché dans son lit sous une couverture bleue ; sur la table de chevet, il y a un verre d''eau et une boîte de médicaments.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il court dans le parc.
B. Il lave sa voiture.
C. Il danse à une fête.
D. Il est malade et reste au lit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il court dans le parc.<break time="700ms"/>B.<break time="300ms"/>Il lave sa voiture.<break time="700ms"/>C.<break time="300ms"/>Il danse à une fête.<break time="700ms"/>D.<break time="300ms"/>Il est malade et reste au lit.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme couché dans son lit avec un verre d''eau et des médicaments sur la table de chevet : il est **malade et se repose**. Seule D correspond. A (courir) se passerait dehors dans un parc, B (laver sa voiture) dans la rue avec un seau et une éponge, C (danser) debout, dans une salle de fête — l''homme est allongé, immobile.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Chez le dentiste : une patiente allongée sur le fauteuil
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="150" y="18" width="6" height="32" fill="#0F1839"/><ellipse cx="153" cy="56" rx="22" ry="10" fill="#E8A317"/><polygon points="75,122 195,100 202,118 82,140" fill="#1E3A8C"/><rect x="128" y="135" width="16" height="25" fill="#0F1839"/><rect x="60" y="138" width="34" height="8" fill="#0F1839"/><circle cx="190" cy="88" r="12" fill="#0F1839"/><rect x="160" y="98" width="32" height="12" fill="#0F6E45"/><circle cx="252" cy="72" r="13" fill="#E8A317"/><rect x="241" y="86" width="22" height="52" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="222" y="96" width="20" height="6" fill="#E8A317"/></svg>',
   NULL,
   'Chez le dentiste, une patiente est allongée sur le fauteuil incliné sous une grande lampe ; le dentiste en blouse blanche se penche vers elle avec un instrument.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle essaie un manteau au magasin.
B. Elle se fait soigner les dents chez le dentiste.
C. Elle nage à la piscine municipale.
D. Elle plante des tomates au jardin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle essaie un manteau au magasin.<break time="700ms"/>B.<break time="300ms"/>Elle se fait soigner les dents chez le dentiste.<break time="700ms"/>C.<break time="300ms"/>Elle nage à la piscine municipale.<break time="700ms"/>D.<break time="300ms"/>Elle plante des tomates au jardin.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une patiente allongée sur un fauteuil incliné sous une grande lampe, avec un praticien en blouse blanche : c''est **un soin chez le dentiste**. Seule B correspond. A (essayer un manteau) se passerait devant un miroir de magasin, C (nager) dans l''eau d''une piscine, D (planter des tomates) dehors, dans un potager — aucune de ces scènes n''est visible.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Vaccination : une infirmière fait une piqûre au bras d'un patient
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="162" width="320" height="38" fill="#15296B"/><circle cx="100" cy="74" r="13" fill="#0F1839"/><rect x="88" y="88" width="24" height="42" fill="#168F5B"/><rect x="112" y="98" width="42" height="10" fill="#E8A317"/><rect x="84" y="130" width="34" height="8" fill="#0F1839"/><rect x="90" y="138" width="8" height="24" fill="#0F1839"/><rect x="104" y="138" width="8" height="24" fill="#0F1839"/><circle cx="210" cy="66" r="13" fill="#E8A317"/><rect x="198" y="80" width="24" height="58" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="205" y="90" width="10" height="4" fill="#1E3A8C"/><rect x="208" y="87" width="4" height="10" fill="#1E3A8C"/><rect x="166" y="99" width="28" height="8" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="166" y1="103" x2="154" y2="103" stroke="#0F1839" stroke-width="2"/></svg>',
   NULL,
   'Dans un centre de santé, une infirmière en blouse blanche fait une piqûre avec une seringue dans le bras tendu d''un patient assis sur une chaise.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. La serveuse apporte un café au client.
B. La maîtresse écrit au tableau.
C. L''infirmière fait un vaccin au patient.
D. La vendeuse emballe un cadeau.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La serveuse apporte un café au client.<break time="700ms"/>B.<break time="300ms"/>La maîtresse écrit au tableau.<break time="700ms"/>C.<break time="300ms"/>L''infirmière fait un vaccin au patient.<break time="700ms"/>D.<break time="300ms"/>La vendeuse emballe un cadeau.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme en blouse blanche qui tient une seringue près du bras tendu d''un patient assis : elle **fait un vaccin**. Seule C correspond. A (apporter un café) montrerait un plateau et une tasse dans un café, B (écrire au tableau) une salle de classe, D (emballer un cadeau) un paquet et du ruban dans une boutique — la seringue exclut ces trois situations.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Où se trouve la pharmacie la plus proche ? » (lieu) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Où se trouve la pharmacie la plus proche, s''il vous plaît ?

A. Elle ouvre à neuf heures du matin.
B. Juste après la mairie, sur la place.
C. Pour acheter de l''aspirine.
D. Avec ma carte vitale.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Où se trouve la pharmacie la plus proche, s''il vous plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle ouvre à neuf heures du matin.<break time="700ms"/>B.<break time="300ms"/>Juste après la mairie, sur la place.<break time="700ms"/>C.<break time="300ms"/>Pour acheter de l''aspirine.<break time="700ms"/>D.<break time="300ms"/>Avec ma carte vitale.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où se trouve la pharmacie ? » porte sur **le lieu**. Seule B « juste après la mairie, sur la place » indique un endroit. A donne un horaire et répondrait à « à quelle heure ouvre-t-elle ? », C exprime un but et répondrait à « pourquoi y vas-tu ? », D indique un moyen et répondrait à « comment payes-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Combien de fois par jour prendre ce sirop ? » (fréquence) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Combien de fois par jour est-ce que je dois prendre ce sirop ?

A. À la pharmacie de la gare.
B. Depuis lundi dernier.
C. Parce que je tousse beaucoup.
D. Trois fois, après chaque repas.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Combien de fois par jour est-ce que je dois prendre ce sirop ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la pharmacie de la gare.<break time="700ms"/>B.<break time="300ms"/>Depuis lundi dernier.<break time="700ms"/>C.<break time="300ms"/>Parce que je tousse beaucoup.<break time="700ms"/>D.<break time="300ms"/>Trois fois, après chaque repas.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien de fois par jour ? » porte sur **la fréquence**. Seule D « trois fois, après chaque repas » donne un nombre de prises. A indique un lieu et répondrait à « où as-tu acheté le sirop ? », B donne un point de départ dans le temps et répondrait à « depuis quand le prends-tu ? », C exprime une cause et répondrait à « pourquoi prends-tu ce sirop ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Quand le docteur peut-il me recevoir ? » (moment) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quand est-ce que le docteur Morel peut me recevoir ?

A. Demain matin, à neuf heures et quart.
B. Au deuxième étage, porte douze.
C. Vingt-cinq euros la consultation.
D. Avec mon fils Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quand est-ce que le docteur Morel peut me recevoir ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Demain matin, à neuf heures et quart.<break time="700ms"/>B.<break time="300ms"/>Au deuxième étage, porte douze.<break time="700ms"/>C.<break time="300ms"/>Vingt-cinq euros la consultation.<break time="700ms"/>D.<break time="300ms"/>Avec mon fils Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quand est-ce que le docteur peut me recevoir ? » porte sur **le moment du rendez-vous**. Seule A « demain matin, à neuf heures et quart » donne une date et une heure. B indique un lieu et répondrait à « où se trouve le cabinet ? », C donne un prix et répondrait à « combien coûte la consultation ? », D désigne une personne et répondrait à « avec qui viens-tu ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Pourquoi tu vas chez le médecin ? » (cause) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi est-ce que tu vas chez le médecin cet après-midi ?

A. En bus, c''est plus rapide.
B. À seize heures précises.
C. Parce que j''ai mal à la gorge depuis trois jours.
D. Chez le docteur Keita, près du marché.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi est-ce que tu vas chez le médecin cet après-midi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>En bus, c''est plus rapide.<break time="700ms"/>B.<break time="300ms"/>À seize heures précises.<break time="700ms"/>C.<break time="300ms"/>Parce que j''ai mal à la gorge depuis trois jours.<break time="700ms"/>D.<break time="300ms"/>Chez le docteur Keita, près du marché.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi est-ce que tu vas chez le médecin ? » porte sur **la cause de la visite**. Seule C « parce que j''ai mal à la gorge » donne une raison. A indique un moyen de transport et répondrait à « comment y vas-tu ? », B donne une heure et répondrait à « à quelle heure est ton rendez-vous ? », D indique le lieu et répondrait à « chez quel médecin vas-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Qui va chercher tes médicaments ? » (personne) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a004-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qui va chercher tes médicaments à la pharmacie ?

A. Deux boîtes de comprimés.
B. Mon voisin Rachid, ce soir.
C. Avant la fermeture, à dix-neuf heures.
D. Avec l''ordonnance du médecin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui va chercher tes médicaments à la pharmacie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Deux boîtes de comprimés.<break time="700ms"/>B.<break time="300ms"/>Mon voisin Rachid, ce soir.<break time="700ms"/>C.<break time="300ms"/>Avant la fermeture, à dix-neuf heures.<break time="700ms"/>D.<break time="300ms"/>Avec l''ordonnance du médecin.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qui va chercher tes médicaments ? » porte sur **la personne**. Seule B « mon voisin Rachid » désigne quelqu''un. A nomme la quantité de médicaments et répondrait à « qu''est-ce qu''il faut acheter ? », C donne un moment et répondrait à « quand faut-il y aller ? », D indique un document et répondrait à « avec quoi peut-on les obtenir ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a004-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « santé & pharmacie », 10 scènes toutes différentes :
--     pharmacie (achat au comptoir), cabinet médical (examen), malade au lit,
--     dentiste (soin), vaccination (piqûre), pharmacie (lieu), sirop
--     (fréquence), rendez-vous docteur (moment), visite médecin (cause),
--     médicaments (personne). Aucun thème interdit (repas & cuisine,
--     transports, commerces, école, maison, loisirs, météo, travail,
--     famille, services, voyages, fêtes, nature exclus).
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
-- [x] SVG : viewBox 320×200, palette charte uniquement, pas de texte,
--     rouge absent (la croix de pharmacie est verte #168F5B, conforme),
--     scène lisible en < 2 s, alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Amadou, Rachid ;
--     docteurs fictifs Morel, Keita).
-- ============================================================================
