-- ============================================================================
-- V805 — TCF CO A2 — lot 03 (thème : commerces & marché)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « commerces & marché », scènes toutes différentes :
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
  -- 1. [Format A] Boulangerie : la boulangère tend une baguette à une cliente
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="20" y="40" width="120" height="8" fill="#1E3A8C"/><ellipse cx="45" cy="33" rx="18" ry="6" fill="#E8A317"/><ellipse cx="85" cy="33" rx="18" ry="6" fill="#E8A317"/><ellipse cx="120" cy="33" rx="14" ry="6" fill="#E8A317"/><rect x="20" y="72" width="120" height="8" fill="#1E3A8C"/><circle cx="48" cy="63" r="9" fill="#E8A317"/><circle cx="80" cy="63" r="9" fill="#E8A317"/><circle cx="112" cy="63" r="9" fill="#E8A317"/><rect x="20" y="108" width="160" height="10" fill="#FFFFFF"/><rect x="20" y="118" width="160" height="42" fill="#1E3A8C"/><circle cx="155" cy="90" r="12" fill="#0F1839"/><rect x="145" y="62" width="20" height="16" rx="4" fill="#FFFFFF"/><ellipse cx="207" cy="98" rx="21" ry="5" fill="#E8A317" transform="rotate(-22 207 98)"/><circle cx="248" cy="84" r="13" fill="#E8A317"/><rect x="239" y="96" width="18" height="46" fill="#168F5B"/></svg>',
   NULL,
   'Dans une boulangerie, une boulangère avec une toque, derrière le comptoir, tend une baguette à une cliente ; des pains et des boules sont posés sur des étagères.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle gare sa voiture sur le parking.
B. Elle lave les vitres de sa maison.
C. Elle achète du pain à la boulangerie.
D. Elle promène son chien dans la rue.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle gare sa voiture sur le parking.<break time="700ms"/>B.<break time="300ms"/>Elle lave les vitres de sa maison.<break time="700ms"/>C.<break time="300ms"/>Elle achète du pain à la boulangerie.<break time="700ms"/>D.<break time="300ms"/>Elle promène son chien dans la rue.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une cliente devant le comptoir d''une boulangerie, avec des pains sur les étagères et une boulangère qui tend une baguette : elle **achète du pain**. Seule C correspond. A (garer sa voiture) montrerait un parking et une voiture, B (laver les vitres) une fenêtre et une éponge, D (promener son chien) une rue avec un chien en laisse.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Marché : le vendeur pèse des fruits sur une balance
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="30" y="30" width="180" height="14" fill="#168F5B"/><rect x="32" y="44" width="6" height="116" fill="#0F1839"/><rect x="202" y="44" width="6" height="116" fill="#0F1839"/><rect x="40" y="110" width="160" height="50" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="115" y="70" width="6" height="40" fill="#0F1839"/><rect x="85" y="66" width="66" height="5" fill="#0F1839"/><line x1="90" y1="71" x2="90" y2="84" stroke="#0F1839" stroke-width="2"/><line x1="146" y1="71" x2="146" y2="84" stroke="#0F1839" stroke-width="2"/><ellipse cx="90" cy="87" rx="14" ry="4" fill="#1E3A8C"/><ellipse cx="146" cy="87" rx="14" ry="4" fill="#1E3A8C"/><circle cx="85" cy="82" r="4" fill="#168F5B"/><circle cx="94" cy="82" r="4" fill="#168F5B"/><rect x="50" y="118" width="44" height="16" fill="#E8A317"/><circle cx="58" cy="116" r="6" fill="#0F6E45"/><circle cx="72" cy="116" r="6" fill="#168F5B"/><circle cx="86" cy="116" r="6" fill="#0F6E45"/><circle cx="62" cy="92" r="12" fill="#0F1839"/><circle cx="250" cy="92" r="13" fill="#E8A317"/><rect x="241" y="104" width="18" height="42" fill="#1E3A8C"/><rect x="265" y="125" width="22" height="18" rx="3" fill="#0F6E45"/><path d="M 265 125 Q 276 112 287 125" stroke="#0F1839" stroke-width="3" fill="none"/></svg>',
   NULL,
   'Au marché, sous un auvent vert, un vendeur pèse des fruits sur une balance à deux plateaux posée sur l''étal ; un client avec un sac attend devant.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Le vendeur pèse des fruits sur la balance.
B. Le peintre repeint le mur de la chambre.
C. Le musicien joue de la guitare sur scène.
D. Le coiffeur coupe les cheveux d''un client.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le vendeur pèse des fruits sur la balance.<break time="700ms"/>B.<break time="300ms"/>Le peintre repeint le mur de la chambre.<break time="700ms"/>C.<break time="300ms"/>Le musicien joue de la guitare sur scène.<break time="700ms"/>D.<break time="300ms"/>Le coiffeur coupe les cheveux d''un client.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un étal de marché avec une balance à deux plateaux sur laquelle le vendeur **pèse des fruits** pour un client. Seule A décrit cette scène. B (repeindre un mur) montrerait un rouleau et un mur de chambre, C (jouer de la guitare) une scène et un instrument, D (couper les cheveux) un salon de coiffure avec des ciseaux.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Magasin de vêtements : un client essaie une veste devant le miroir
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="25" y="50" width="120" height="5" fill="#0F1839"/><rect x="30" y="55" width="6" height="105" fill="#0F1839"/><rect x="134" y="55" width="6" height="105" fill="#0F1839"/><rect x="42" y="58" width="22" height="36" fill="#1E3A8C"/><rect x="70" y="58" width="22" height="36" fill="#168F5B"/><rect x="98" y="58" width="22" height="36" fill="#E8A317"/><rect x="215" y="40" width="70" height="110" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="3"/><rect x="240" y="150" width="20" height="10" fill="#1E3A8C"/><circle cx="250" cy="74" r="11" fill="#0F1839"/><rect x="240" y="86" width="20" height="34" fill="#E8A317"/><circle cx="180" cy="70" r="13" fill="#0F1839"/><rect x="167" y="84" width="26" height="42" fill="#E8A317"/><rect x="170" y="126" width="9" height="30" fill="#0F1839"/><rect x="182" y="126" width="9" height="30" fill="#0F1839"/></svg>',
   NULL,
   'Dans un magasin de vêtements, un client essaie une veste jaune devant un grand miroir où l''on voit son reflet ; des habits sont suspendus à un portant.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il plante des tomates dans le potager.
B. Il lit le journal sur un banc.
C. Il peint un tableau dans son atelier.
D. Il essaie une veste devant le miroir.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il plante des tomates dans le potager.<break time="700ms"/>B.<break time="300ms"/>Il lit le journal sur un banc.<break time="700ms"/>C.<break time="300ms"/>Il peint un tableau dans son atelier.<break time="700ms"/>D.<break time="300ms"/>Il essaie une veste devant le miroir.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un client en veste devant un grand miroir, à côté d''un portant de vêtements : il **essaie un vêtement** au magasin. Seule D correspond. A (planter des tomates) se passerait dehors avec une bêche, B (lire le journal) sur un banc avec un journal ouvert, C (peindre un tableau) devant un chevalet avec un pinceau.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Fleuriste : une cliente choisit un bouquet parmi les pots
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="20" y="78" width="130" height="8" fill="#1E3A8C"/><rect x="35" y="58" width="18" height="20" fill="#E8A317"/><line x1="44" y1="58" x2="44" y2="46" stroke="#0F6E45" stroke-width="2"/><circle cx="44" cy="42" r="6" fill="#FFFFFF"/><rect x="75" y="58" width="18" height="20" fill="#E8A317"/><line x1="84" y1="58" x2="84" y2="46" stroke="#0F6E45" stroke-width="2"/><circle cx="84" cy="42" r="6" fill="#FDECEB"/><rect x="115" y="58" width="18" height="20" fill="#E8A317"/><line x1="124" y1="58" x2="124" y2="46" stroke="#0F6E45" stroke-width="2"/><circle cx="124" cy="42" r="6" fill="#FFFFFF"/><rect x="40" y="125" width="30" height="35" fill="#E8A317"/><line x1="55" y1="125" x2="55" y2="103" stroke="#0F6E45" stroke-width="3"/><circle cx="55" cy="97" r="9" fill="#FDECEB"/><rect x="95" y="125" width="30" height="35" fill="#E8A317"/><line x1="110" y1="125" x2="110" y2="103" stroke="#0F6E45" stroke-width="3"/><circle cx="110" cy="97" r="9" fill="#FFFFFF"/><circle cx="235" cy="72" r="13" fill="#0F1839"/><rect x="226" y="84" width="18" height="50" fill="#1E3A8C"/><polygon points="196,118 216,118 206,140" fill="#FDECEB"/><line x1="202" y1="118" x2="200" y2="106" stroke="#0F6E45" stroke-width="2"/><line x1="210" y1="118" x2="212" y2="106" stroke="#0F6E45" stroke-width="2"/><circle cx="199" cy="101" r="6" fill="#E8A317"/><circle cx="213" cy="101" r="6" fill="#FFFFFF"/><circle cx="206" cy="95" r="6" fill="#E8A317"/></svg>',
   NULL,
   'Chez le fleuriste, une cliente tient un bouquet de fleurs emballé dans un papier rose ; des pots de fleurs sont alignés sur une étagère et au sol.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle répare son vélo sur le trottoir.
B. Elle achète un bouquet chez le fleuriste.
C. Elle nettoie le tableau de la classe.
D. Elle photographie un vieux monument.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle répare son vélo sur le trottoir.<break time="700ms"/>B.<break time="300ms"/>Elle achète un bouquet chez le fleuriste.<break time="700ms"/>C.<break time="300ms"/>Elle nettoie le tableau de la classe.<break time="700ms"/>D.<break time="300ms"/>Elle photographie un vieux monument.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une cliente, bouquet à la main, au milieu de pots de fleurs alignés dans une boutique : elle **achète des fleurs chez le fleuriste**. Seule B correspond. A (réparer un vélo) montrerait un vélo et des outils sur un trottoir, C (nettoyer le tableau) une salle de classe, D (photographier un monument) un appareil photo et un bâtiment ancien.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Supermarché : un homme pousse un chariot dans une allée
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="20" y="30" width="110" height="110" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="20" y="62" width="110" height="5" fill="#1E3A8C"/><rect x="20" y="100" width="110" height="5" fill="#1E3A8C"/><rect x="30" y="44" width="16" height="18" fill="#E8A317"/><rect x="52" y="44" width="16" height="18" fill="#168F5B"/><rect x="74" y="44" width="16" height="18" fill="#15296B"/><rect x="96" y="44" width="16" height="18" fill="#E8A317"/><rect x="30" y="82" width="16" height="18" fill="#168F5B"/><rect x="52" y="82" width="16" height="18" fill="#E8A317"/><rect x="74" y="82" width="16" height="18" fill="#168F5B"/><rect x="96" y="82" width="16" height="18" fill="#15296B"/><rect x="30" y="120" width="16" height="18" fill="#15296B"/><rect x="52" y="120" width="16" height="18" fill="#E8A317"/><rect x="74" y="120" width="16" height="18" fill="#0F6E45"/><rect x="96" y="120" width="16" height="18" fill="#E8A317"/><circle cx="178" cy="68" r="13" fill="#0F1839"/><rect x="167" y="81" width="20" height="48" fill="#168F5B"/><line x1="187" y1="92" x2="208" y2="100" stroke="#168F5B" stroke-width="6"/><line x1="208" y1="100" x2="216" y2="108" stroke="#0F1839" stroke-width="3"/><rect x="212" y="106" width="55" height="28" fill="#1E3A8C"/><line x1="226" y1="106" x2="226" y2="134" stroke="#FFFFFF" stroke-width="2"/><line x1="240" y1="106" x2="240" y2="134" stroke="#FFFFFF" stroke-width="2"/><line x1="254" y1="106" x2="254" y2="134" stroke="#FFFFFF" stroke-width="2"/><circle cx="222" cy="144" r="7" fill="#0F1839"/><circle cx="258" cy="144" r="7" fill="#0F1839"/><rect x="220" y="96" width="14" height="12" fill="#E8A317"/><rect x="240" y="94" width="12" height="14" fill="#0F6E45"/></svg>',
   NULL,
   'Dans une allée de supermarché, un homme pousse un chariot contenant des produits, devant un grand rayon rempli de boîtes colorées.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il conduit un bus dans la ville.
B. Il tond l''herbe de son jardin.
C. Il pousse un chariot au supermarché.
D. Il peint le plafond de la cuisine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il conduit un bus dans la ville.<break time="700ms"/>B.<break time="300ms"/>Il tond l''herbe de son jardin.<break time="700ms"/>C.<break time="300ms"/>Il pousse un chariot au supermarché.<break time="700ms"/>D.<break time="300ms"/>Il peint le plafond de la cuisine.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un homme qui pousse un chariot de courses devant un rayon de supermarché rempli de produits : il **fait ses courses**. Seule C décrit la scène. A (conduire un bus) montrerait un bus et une route, B (tondre l''herbe) un jardin et une tondeuse, D (peindre le plafond) une échelle et un rouleau de peinture.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « À quelle heure ferme votre boutique ? » (heure) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] À quelle heure ferme votre boutique, s''il vous plaît ?

A. Juste à côté de la pharmacie.
B. À dix-neuf heures trente, ce soir.
C. Depuis quinze ans déjà.
D. Des croissants et des baguettes.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure ferme votre boutique, s''il vous plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Juste à côté de la pharmacie.<break time="700ms"/>B.<break time="300ms"/>À dix-neuf heures trente, ce soir.<break time="700ms"/>C.<break time="300ms"/>Depuis quinze ans déjà.<break time="700ms"/>D.<break time="300ms"/>Des croissants et des baguettes.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure ferme votre boutique ? » porte sur **l''heure de fermeture**. Seule B « à dix-neuf heures trente » donne une heure. A indique un emplacement et répondrait à « où se trouve la boutique ? », C donne une durée et répondrait à « depuis quand existe-t-elle ? », D nomme des produits et répondrait à « que vendez-vous ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Combien coûtent vos fraises ? » (prix) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Bonjour, combien coûtent vos fraises, s''il vous plaît ?

A. Elles viennent de la région.
B. Sur la place, près de la fontaine.
C. Jusqu''à midi seulement.
D. Quatre euros la barquette.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, combien coûtent vos fraises, s''il vous plaît ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elles viennent de la région.<break time="700ms"/>B.<break time="300ms"/>Sur la place, près de la fontaine.<break time="700ms"/>C.<break time="300ms"/>Jusqu''à midi seulement.<break time="700ms"/>D.<break time="300ms"/>Quatre euros la barquette.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien coûtent vos fraises ? » porte sur **le prix**. Seule D « quatre euros la barquette » donne un montant. A indique l''origine des fruits et répondrait à « d''où viennent-elles ? », B donne un lieu et répondrait à « où est votre étal ? », C donne un horaire et répondrait à « jusqu''à quelle heure vendez-vous ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Où est le rayon des produits laitiers ? » (lieu) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Excusez-moi, où se trouve le rayon des produits laitiers ?

A. Au fond du magasin, près des surgelés.
B. Trois euros le litre, environ.
C. Tous les matins à neuf heures.
D. Avec ma carte de fidélité.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Excusez-moi, où se trouve le rayon des produits laitiers ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Au fond du magasin, près des surgelés.<break time="700ms"/>B.<break time="300ms"/>Trois euros le litre, environ.<break time="700ms"/>C.<break time="300ms"/>Tous les matins à neuf heures.<break time="700ms"/>D.<break time="300ms"/>Avec ma carte de fidélité.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où se trouve le rayon des produits laitiers ? » porte sur **le lieu dans le magasin**. Seule A « au fond du magasin, près des surgelés » indique un endroit. B donne un prix et répondrait à « combien coûte le lait ? », C donne une fréquence et répondrait à « quand est-il livré ? », D indique un moyen et répondrait à « comment payez-vous ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Qu'as-tu acheté au marché, Lucia ? » (objet) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qu''est-ce que tu as acheté au marché ce matin, Lucia ?

A. Avec mon voisin Amadou.
B. Du fromage et des olives.
C. À huit heures et demie.
D. Parce que c''est moins cher.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qu''est-ce que tu as acheté au marché ce matin, Lucia ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mon voisin Amadou.<break time="700ms"/>B.<break time="300ms"/>Du fromage et des olives.<break time="700ms"/>C.<break time="300ms"/>À huit heures et demie.<break time="700ms"/>D.<break time="300ms"/>Parce que c''est moins cher.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qu''est-ce que tu as acheté ? » porte sur **les produits achetés**. Seule B « du fromage et des olives » nomme des achats. A désigne une personne et répondrait à « avec qui es-tu allée au marché ? », C donne une heure et répondrait à « à quelle heure y es-tu allée ? », D exprime une cause et répondrait à « pourquoi fais-tu tes courses au marché ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Comment voulez-vous payer ? » (moyen de paiement) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a003-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Comment voulez-vous payer, monsieur ?

A. Un paquet de café, merci.
B. Demain après-midi, si possible.
C. Par carte bancaire, s''il vous plaît.
D. Dans un sac en papier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Comment voulez-vous payer, monsieur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un paquet de café, merci.<break time="700ms"/>B.<break time="300ms"/>Demain après-midi, si possible.<break time="700ms"/>C.<break time="300ms"/>Par carte bancaire, s''il vous plaît.<break time="700ms"/>D.<break time="300ms"/>Dans un sac en papier.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Comment voulez-vous payer ? » porte sur **le moyen de paiement**. Seule C « par carte bancaire » indique une façon de payer. A nomme un produit et répondrait à « que voulez-vous acheter ? », B donne un moment et répondrait à « quand passerez-vous ? », D désigne un emballage et répondrait à « comment voulez-vous emporter vos achats ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a003-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « commerces & marché », 10 scènes toutes différentes :
--     boulangerie (achat de pain), marché (pesée des fruits), magasin de
--     vêtements (essayage), fleuriste (bouquet), supermarché (chariot),
--     boutique (heure de fermeture), fraises (prix), rayon laitier (lieu),
--     achats au marché (objet), caisse (moyen de paiement). Aucun thème
--     interdit (pas de repas & cuisine, transports, santé, école, maison,
--     loisirs, météo, travail, famille, services, voyages, fêtes, nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×2 : items 6,9) /
--     Vivienne (×3 : items 7,8,10) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=2 (items 2,8), B=3 (items 4,6,9),
--     C=3 (items 1,5,10), D=2 (items 3,7) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question ou la scène à laquelle chacun
--     correspondrait), point clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, pas de texte,
--     rouge absent (aucun élément critique requis), scène lisible en < 2 s,
--     alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Lucia, Amadou).
-- ============================================================================
