-- ============================================================================
-- V811 — TCF CO A2 — lot 09 (thème : travail (gestes simples du quotidien professionnel))
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « travail (gestes simples du quotidien professionnel) », scènes toutes
-- différentes :
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
  -- 1. [Format A] Au bureau : une employée tape un document sur l'ordinateur
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#15296B"/><rect x="240" y="25" width="60" height="50" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="85" y="115" width="175" height="10" fill="#1E3A8C"/><rect x="95" y="125" width="10" height="35" fill="#0F1839"/><rect x="240" y="125" width="10" height="35" fill="#0F1839"/><rect x="165" y="70" width="70" height="42" rx="3" fill="#0F1839"/><rect x="170" y="75" width="60" height="32" fill="#FFFFFF"/><rect x="195" y="112" width="12" height="3" fill="#0F1839"/><rect x="120" y="107" width="40" height="8" rx="2" fill="#0F1839"/><circle cx="105" cy="68" r="13" fill="#E8A317"/><rect x="95" y="81" width="20" height="34" fill="#1E3A8C"/><rect x="115" y="98" width="22" height="7" fill="#E8A317"/><rect x="98" y="125" width="14" height="35" fill="#0F1839"/></svg>',
   NULL,
   'Dans un bureau, une employée assise tape sur le clavier d''un ordinateur posé sur son bureau, devant un écran allumé.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle fait du vélo en ville.
B. Elle dort sur le canapé du salon.
C. Elle tape un document sur l''ordinateur.
D. Elle lave la vaisselle dans l''évier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle fait du vélo en ville.<break time="700ms"/>B.<break time="300ms"/>Elle dort sur le canapé du salon.<break time="700ms"/>C.<break time="300ms"/>Elle tape un document sur l''ordinateur.<break time="700ms"/>D.<break time="300ms"/>Elle lave la vaisselle dans l''évier.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme assise à un bureau, les mains sur un clavier, devant un écran allumé : elle **tape un document sur l''ordinateur**. Seule C correspond. A (faire du vélo) se passerait dans la rue avec un vélo, B (dormir) montrerait un canapé ou un lit, D (laver la vaisselle) un évier et des assiettes — rien de tout cela n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] À l'entrepôt : un employé porte un carton devant les étagères
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="25" y="45" width="6" height="115" fill="#0F1839"/><rect x="135" y="45" width="6" height="115" fill="#0F1839"/><rect x="25" y="45" width="116" height="8" fill="#1E3A8C"/><rect x="25" y="100" width="116" height="8" fill="#1E3A8C"/><rect x="38" y="62" width="32" height="38" fill="#E8A317"/><rect x="78" y="70" width="28" height="30" fill="#0F6E45"/><rect x="38" y="120" width="36" height="40" fill="#E8A317"/><rect x="84" y="126" width="30" height="34" fill="#168F5B"/><circle cx="225" cy="68" r="13" fill="#0F1839"/><rect x="213" y="81" width="24" height="50" fill="#168F5B"/><rect x="216" y="131" width="8" height="29" fill="#0F1839"/><rect x="228" y="131" width="8" height="29" fill="#0F1839"/><rect x="237" y="88" width="38" height="32" fill="#E8A317" stroke="#0F1839" stroke-width="2"/><rect x="233" y="95" width="10" height="7" fill="#E8A317"/></svg>',
   NULL,
   'Dans un entrepôt, un employé porte un grand carton devant des étagères remplies de boîtes.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il porte un carton dans l''entrepôt.
B. Il nage à la piscine municipale.
C. Il lit le journal à la terrasse d''un café.
D. Il plante des fleurs dans le jardin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il porte un carton dans l''entrepôt.<break time="700ms"/>B.<break time="300ms"/>Il nage à la piscine municipale.<break time="700ms"/>C.<break time="300ms"/>Il lit le journal à la terrasse d''un café.<break time="700ms"/>D.<break time="300ms"/>Il plante des fleurs dans le jardin.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un employé, un grand carton dans les bras, devant des étagères pleines de boîtes : il **porte un carton dans l''entrepôt**. Seule A correspond. B (nager) se passerait dans une piscine, C (lire le journal) montrerait un café et un journal, D (planter des fleurs) un jardin avec des outils — aucun de ces lieux n''est représenté.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Entretien : une agente passe le balai à franges, seau à côté
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="150" width="320" height="50" fill="#15296B"/><circle cx="115" cy="58" r="13" fill="#0F1839"/><rect x="103" y="71" width="24" height="48" fill="#1E3A8C"/><rect x="106" y="119" width="8" height="31" fill="#0F1839"/><rect x="116" y="119" width="8" height="31" fill="#0F1839"/><line x1="127" y1="85" x2="168" y2="78" stroke="#E8A317" stroke-width="6"/><line x1="168" y1="78" x2="185" y2="148" stroke="#E8A317" stroke-width="5"/><rect x="172" y="146" width="36" height="10" rx="4" fill="#1E3A8C"/><rect x="240" y="126" width="36" height="26" fill="#1E3A8C"/><path d="M 240 126 Q 258 108 276 126" stroke="#0F1839" stroke-width="3" fill="none"/><ellipse cx="150" cy="170" rx="30" ry="5" fill="#FFFFFF"/><ellipse cx="230" cy="180" rx="22" ry="4" fill="#FFFFFF"/></svg>',
   NULL,
   'Une agente d''entretien passe un balai à franges sur le sol brillant d''un couloir, à côté d''un seau bleu.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle conduit un camion sur la route.
B. Elle chante sur une scène de concert.
C. Elle coupe du pain dans la cuisine.
D. Elle nettoie le sol avec un balai.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle conduit un camion sur la route.<break time="700ms"/>B.<break time="300ms"/>Elle chante sur une scène de concert.<break time="700ms"/>C.<break time="300ms"/>Elle coupe du pain dans la cuisine.<break time="700ms"/>D.<break time="300ms"/>Elle nettoie le sol avec un balai.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre une femme qui pousse un balai à franges, avec un seau d''eau à côté : elle **nettoie le sol**. Seule D correspond. A (conduire un camion) montrerait un véhicule et une route, B (chanter) une scène et un micro, C (couper du pain) une cuisine et une baguette — aucune de ces scènes n''apparaît.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Chantier : un peintre peint un mur en bleu, échelle à côté
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="0" width="145" height="160" fill="#1E3A8C"/><rect x="0" y="160" width="320" height="40" fill="#0F1839"/><rect x="252" y="55" width="6" height="105" fill="#E8A317"/><rect x="284" y="55" width="6" height="105" fill="#E8A317"/><rect x="252" y="75" width="38" height="6" fill="#E8A317"/><rect x="252" y="105" width="38" height="6" fill="#E8A317"/><rect x="252" y="135" width="38" height="6" fill="#E8A317"/><circle cx="190" cy="78" r="13" fill="#E8A317"/><rect x="178" y="91" width="24" height="44" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="181" y="135" width="8" height="25" fill="#0F1839"/><rect x="191" y="135" width="8" height="25" fill="#0F1839"/><line x1="178" y1="98" x2="152" y2="68" stroke="#E8A317" stroke-width="5"/><rect x="132" y="48" width="30" height="16" rx="6" fill="#168F5B"/><rect x="210" y="138" width="30" height="22" fill="#1E3A8C"/><path d="M 210 138 Q 225 124 240 138" stroke="#0F1839" stroke-width="3" fill="none"/></svg>',
   NULL,
   'Un ouvrier peint un mur en bleu avec un rouleau ; une échelle et un pot de peinture sont posés à côté.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il joue de la guitare dans sa chambre.
B. Il peint le mur avec un rouleau.
C. Il photographie un vieux monument.
D. Il pêche au bord de la rivière.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il joue de la guitare dans sa chambre.<break time="700ms"/>B.<break time="300ms"/>Il peint le mur avec un rouleau.<break time="700ms"/>C.<break time="300ms"/>Il photographie un vieux monument.<break time="700ms"/>D.<break time="300ms"/>Il pêche au bord de la rivière.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un ouvrier, rouleau à la main, devant un mur à moitié peint en bleu, avec une échelle et un pot de peinture : il **peint le mur**. Seule B correspond. A (jouer de la guitare) montrerait un instrument de musique, C (photographier) un appareil photo et un monument, D (pêcher) une rivière et une canne à pêche.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Réunion : un collègue présente un graphique au tableau
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="158" width="320" height="42" fill="#15296B"/><rect x="228" y="35" width="74" height="58" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><rect x="238" y="70" width="12" height="18" fill="#168F5B"/><rect x="256" y="58" width="12" height="30" fill="#E8A317"/><rect x="274" y="46" width="12" height="42" fill="#1E3A8C"/><line x1="240" y1="93" x2="232" y2="158" stroke="#0F1839" stroke-width="4"/><line x1="290" y1="93" x2="298" y2="158" stroke="#0F1839" stroke-width="4"/><circle cx="200" cy="72" r="12" fill="#0F1839"/><rect x="190" y="84" width="20" height="42" fill="#1E3A8C"/><line x1="210" y1="92" x2="228" y2="80" stroke="#E8A317" stroke-width="5"/><rect x="40" y="118" width="130" height="10" fill="#1E3A8C"/><rect x="95" y="128" width="12" height="30" fill="#0F1839"/><circle cx="70" cy="88" r="12" fill="#E8A317"/><rect x="60" y="100" width="20" height="18" fill="#0F6E45"/><circle cx="140" cy="88" r="12" fill="#E8A317"/><rect x="130" y="100" width="20" height="18" fill="#15296B"/></svg>',
   NULL,
   'En réunion, un collègue debout présente un graphique affiché sur un tableau à deux personnes assises à une table.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils sont en réunion devant un graphique.
B. Ils dansent à une fête de quartier.
C. Ils font la queue devant le cinéma.
D. Ils jouent aux cartes dans le salon.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils sont en réunion devant un graphique.<break time="700ms"/>B.<break time="300ms"/>Ils dansent à une fête de quartier.<break time="700ms"/>C.<break time="300ms"/>Ils font la queue devant le cinéma.<break time="700ms"/>D.<break time="300ms"/>Ils jouent aux cartes dans le salon.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un collègue debout qui montre un graphique sur un tableau, devant deux personnes assises à une table : ils **sont en réunion de travail**. Seule A correspond. B (danser) évoquerait une fête et de la musique, C (faire la queue) une file devant un cinéma, D (jouer aux cartes) des cartes posées sur la table — on ne voit rien de tout cela.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « À quelle heure commence ta journée de travail ? » (heure) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] À quelle heure commence ta journée de travail demain ?

A. Avec mon collègue Amadou.
B. Au dépôt, près du port.
C. Parce qu''il y a une livraison.
D. À huit heures et quart.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">À quelle heure commence ta journée de travail demain ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Avec mon collègue Amadou.<break time="700ms"/>B.<break time="300ms"/>Au dépôt, près du port.<break time="700ms"/>C.<break time="300ms"/>Parce qu''il y a une livraison.<break time="700ms"/>D.<break time="300ms"/>À huit heures et quart.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « À quelle heure commence ta journée ? » porte sur **l''heure de début du travail**. Seule D « à huit heures et quart » donne un horaire. A désigne une personne et répondrait à « avec qui travailles-tu ? », B indique un lieu et répondrait à « où travailles-tu ? », C exprime une cause et répondrait à « pourquoi commences-tu si tôt ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Où ranges-tu les dossiers des clients ? » (lieu) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Où est-ce que tu ranges les dossiers des clients ?

A. Tous les vendredis matin.
B. Dans l''armoire grise, au fond du couloir.
C. C''est Lucia qui s''en occupe.
D. Une vingtaine par semaine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Où est-ce que tu ranges les dossiers des clients ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Tous les vendredis matin.<break time="700ms"/>B.<break time="300ms"/>Dans l''armoire grise, au fond du couloir.<break time="700ms"/>C.<break time="300ms"/>C''est Lucia qui s''en occupe.<break time="700ms"/>D.<break time="300ms"/>Une vingtaine par semaine.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Où ranges-tu les dossiers ? » porte sur **le lieu de rangement**. Seule B « dans l''armoire grise, au fond du couloir » indique un endroit. A donne un moment et répondrait à « quand fais-tu le classement ? », C désigne une personne et répondrait à « qui s''occupe des dossiers ? », D donne une quantité et répondrait à « combien de dossiers traites-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Qui répond au téléphone à l'accueil ? » (personne) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Qui répond au téléphone à l''accueil cet après-midi ?

A. Jusqu''à dix-huit heures.
B. Au premier étage, bureau douze.
C. C''est Rachid, le nouveau stagiaire.
D. Pour noter les rendez-vous.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Qui répond au téléphone à l''accueil cet après-midi ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à dix-huit heures.<break time="700ms"/>B.<break time="300ms"/>Au premier étage, bureau douze.<break time="700ms"/>C.<break time="300ms"/>C''est Rachid, le nouveau stagiaire.<break time="700ms"/>D.<break time="300ms"/>Pour noter les rendez-vous.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qui répond au téléphone ? » porte sur **la personne**. Seule C « Rachid, le nouveau stagiaire » désigne quelqu''un. A donne un horaire et répondrait à « jusqu''à quelle heure l''accueil est-il ouvert ? », B indique un lieu et répondrait à « où se trouve l''accueil ? », D exprime un but et répondrait à « pourquoi répond-on au téléphone ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Que fais-tu en premier à l'atelier ? » (action) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Qu''est-ce que tu fais en premier quand tu arrives à l''atelier ?

A. Je mets ma tenue et je vérifie les machines.
B. À six heures et demie du matin.
C. Avec le chef d''équipe, Wei.
D. Depuis presque trois ans.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Qu''est-ce que tu fais en premier quand tu arrives à l''atelier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Je mets ma tenue et je vérifie les machines.<break time="700ms"/>B.<break time="300ms"/>À six heures et demie du matin.<break time="700ms"/>C.<break time="300ms"/>Avec le chef d''équipe, Wei.<break time="700ms"/>D.<break time="300ms"/>Depuis presque trois ans.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Qu''est-ce que tu fais en premier ? » porte sur **la première action de la journée**. Seule A « je mets ma tenue et je vérifie les machines » décrit une action. B donne une heure et répondrait à « à quelle heure arrives-tu ? », C désigne une personne et répondrait à « avec qui travailles-tu ? », D donne une durée et répondrait à « depuis combien de temps travailles-tu ici ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Combien d'heures travailles-tu par semaine ? » (quantité) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a009-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Combien d''heures travailles-tu par semaine ?

A. Dans un garage du centre-ville.
B. Depuis le mois de janvier.
C. Trente-cinq heures, du lundi au vendredi.
D. Avec deux autres mécaniciens, Diego et Priya.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Combien d''heures travailles-tu par semaine ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dans un garage du centre-ville.<break time="700ms"/>B.<break time="300ms"/>Depuis le mois de janvier.<break time="700ms"/>C.<break time="300ms"/>Trente-cinq heures, du lundi au vendredi.<break time="700ms"/>D.<break time="300ms"/>Avec deux autres mécaniciens, Diego et Priya.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Combien d''heures travailles-tu ? » porte sur **le nombre d''heures**. Seule C « trente-cinq heures » donne une quantité. A indique un lieu et répondrait à « où travailles-tu ? », B donne un point de départ et répondrait à « depuis quand travailles-tu là ? », D désigne des personnes et répondrait à « avec qui travailles-tu ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a009-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « travail (gestes simples du quotidien professionnel) »,
--     10 scènes toutes différentes : bureau/ordinateur, entrepôt/carton,
--     entretien/balai, peinture/rouleau, réunion/graphique, heure d'embauche,
--     rangement des dossiers (lieu), accueil téléphonique (personne),
--     première action à l'atelier, heures hebdomadaires (quantité).
--     Aucun thème interdit (pas de repas, transports, commerces, santé,
--     école, maison, loisirs, météo, famille, services, voyages, fêtes,
--     nature).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Henri (×3 : items 6,8,10)
--     / Vivienne (×2 : items 7,9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 2,5,9), B=2 (items 4,7),
--     C=3 (items 1,8,10), D=2 (items 3,6) — 4 lettres utilisées, max 3.
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
--     valide. Contenu 100 % original (prénoms variés : Amadou, Lucia,
--     Rachid, Wei, Diego, Priya).
-- ============================================================================
