-- ============================================================================
-- V810 — TCF CO A2 — lot 08 (thème : météo & saisons)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (A2), table audio_question_draft. 10 items, tous dans le
-- thème « météo & saisons », scènes toutes différentes :
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
  -- 1. [Format A] Jour de pluie : une femme marche sous un parapluie, nuages, gouttes
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000001', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="165" width="320" height="35" fill="#15296B"/><ellipse cx="80" cy="35" rx="45" ry="18" fill="#1E3A8C"/><ellipse cx="155" cy="28" rx="50" ry="20" fill="#15296B"/><ellipse cx="245" cy="38" rx="46" ry="17" fill="#1E3A8C"/><line x1="58" y1="62" x2="50" y2="88" stroke="#1E3A8C" stroke-width="3"/><line x1="105" y1="68" x2="97" y2="94" stroke="#1E3A8C" stroke-width="3"/><line x1="225" y1="64" x2="217" y2="90" stroke="#1E3A8C" stroke-width="3"/><line x1="272" y1="58" x2="264" y2="84" stroke="#1E3A8C" stroke-width="3"/><line x1="248" y1="100" x2="240" y2="126" stroke="#1E3A8C" stroke-width="3"/><line x1="72" y1="104" x2="64" y2="130" stroke="#1E3A8C" stroke-width="3"/><path d="M 113 96 A 47 47 0 0 1 207 96 Z" fill="#E8A317"/><line x1="160" y1="96" x2="160" y2="120" stroke="#0F1839" stroke-width="4"/><circle cx="160" cy="118" r="12" fill="#0F1839"/><rect x="150" y="130" width="20" height="35" rx="4" fill="#168F5B"/></svg>',
   NULL,
   'Sous un ciel couvert de gros nuages bleus, la pluie tombe ; une personne marche en s''abritant sous un grand parapluie jaune.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Elle bronze au soleil sur la plage.
B. Elle fait du vélo par beau temps.
C. Elle marche sous la pluie avec un parapluie.
D. Elle nage à la piscine couverte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle bronze au soleil sur la plage.<break time="700ms"/>B.<break time="300ms"/>Elle fait du vélo par beau temps.<break time="700ms"/>C.<break time="300ms"/>Elle marche sous la pluie avec un parapluie.<break time="700ms"/>D.<break time="300ms"/>Elle nage à la piscine couverte.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre de gros nuages, des gouttes qui tombent et une personne abritée sous un parapluie : **il pleut**. Seule C décrit cette scène. A (bronzer au soleil) montrerait une plage et un grand soleil, B (faire du vélo par beau temps) un vélo sous un ciel dégagé, D (nager à la piscine) un bassin d''eau — rien de tout cela n''apparaît sur l''image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 2. [Format A] Hiver : un enfant fait un bonhomme de neige, flocons dans le ciel
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000002', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#1E3A8C"/><rect x="0" y="150" width="320" height="50" fill="#FFFFFF"/><circle cx="50" cy="38" r="4" fill="#FFFFFF"/><circle cx="115" cy="62" r="3" fill="#FFFFFF"/><circle cx="170" cy="30" r="4" fill="#FFFFFF"/><circle cx="240" cy="55" r="3" fill="#FFFFFF"/><circle cx="290" cy="32" r="4" fill="#FFFFFF"/><circle cx="70" cy="92" r="3" fill="#FFFFFF"/><circle cx="265" cy="100" r="3" fill="#FFFFFF"/><circle cx="195" cy="128" r="32" fill="#FFFFFF" stroke="#15296B" stroke-width="2"/><circle cx="195" cy="80" r="22" fill="#FFFFFF" stroke="#15296B" stroke-width="2"/><circle cx="188" cy="75" r="3" fill="#0F1839"/><circle cx="202" cy="75" r="3" fill="#0F1839"/><polygon points="195,82 195,88 212,85" fill="#E8A317"/><rect x="177" y="50" width="36" height="8" fill="#0F1839"/><rect x="183" y="34" width="24" height="18" fill="#0F1839"/><rect x="177" y="96" width="36" height="9" fill="#E8A317"/><circle cx="85" cy="112" r="12" fill="#E8A317"/><rect x="75" y="124" width="20" height="34" rx="4" fill="#168F5B"/><line x1="95" y1="132" x2="160" y2="120" stroke="#0F1839" stroke-width="3"/></svg>',
   NULL,
   'Sous un ciel bleu plein de flocons, un enfant en manteau vert termine un bonhomme de neige avec un chapeau noir, un nez orange et une écharpe.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Un enfant fait un bonhomme de neige.
B. Un enfant se baigne dans la mer.
C. Un enfant cueille des fleurs au printemps.
D. Un enfant ramasse des champignons en forêt.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un enfant fait un bonhomme de neige.<break time="700ms"/>B.<break time="300ms"/>Un enfant se baigne dans la mer.<break time="700ms"/>C.<break time="300ms"/>Un enfant cueille des fleurs au printemps.<break time="700ms"/>D.<break time="300ms"/>Un enfant ramasse des champignons en forêt.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre des flocons, un sol blanc et un enfant à côté d''un bonhomme avec chapeau et écharpe : **c''est l''hiver et il fait un bonhomme de neige**. Seule A correspond. B (se baigner dans la mer) est une scène d''été avec de l''eau, C (cueillir des fleurs) montrerait des fleurs de printemps, D (ramasser des champignons) une forêt d''automne — aucune de ces saisons n''est représentée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 3. [Format A] Canicule : grand soleil, thermomètre très haut, homme qui boit
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000003', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#FDECEB"/><rect x="0" y="160" width="320" height="40" fill="#E8A317"/><circle cx="70" cy="52" r="26" fill="#E8A317"/><line x1="70" y1="10" x2="70" y2="22" stroke="#E8A317" stroke-width="4"/><line x1="70" y1="82" x2="70" y2="94" stroke="#E8A317" stroke-width="4"/><line x1="28" y1="52" x2="40" y2="52" stroke="#E8A317" stroke-width="4"/><line x1="100" y1="52" x2="112" y2="52" stroke="#E8A317" stroke-width="4"/><line x1="40" y1="22" x2="49" y2="31" stroke="#E8A317" stroke-width="4"/><line x1="91" y1="73" x2="100" y2="82" stroke="#E8A317" stroke-width="4"/><line x1="100" y1="22" x2="91" y2="31" stroke="#E8A317" stroke-width="4"/><line x1="49" y1="73" x2="40" y2="82" stroke="#E8A317" stroke-width="4"/><rect x="250" y="40" width="16" height="90" rx="8" fill="#FFFFFF" stroke="#0F1839" stroke-width="2"/><rect x="255" y="52" width="6" height="76" fill="#E1372F"/><circle cx="258" cy="136" r="13" fill="#E1372F"/><circle cx="160" cy="92" r="13" fill="#0F1839"/><rect x="150" y="105" width="20" height="50" rx="4" fill="#1E3A8C"/><rect x="178" y="96" width="9" height="24" rx="2" fill="#FFFFFF" stroke="#1E3A8C" stroke-width="2"/><line x1="170" y1="112" x2="178" y2="104" stroke="#0F1839" stroke-width="4"/></svg>',
   NULL,
   'Sous un grand soleil, un thermomètre affiche une température très élevée ; un homme boit une bouteille d''eau pour se rafraîchir.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il déneige le trottoir devant chez lui.
B. Il s''abrite de l''orage sous un arbre.
C. Il patine sur un lac gelé.
D. Il boit de l''eau parce qu''il fait très chaud.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il déneige le trottoir devant chez lui.<break time="700ms"/>B.<break time="300ms"/>Il s''abrite de l''orage sous un arbre.<break time="700ms"/>C.<break time="300ms"/>Il patine sur un lac gelé.<break time="700ms"/>D.<break time="300ms"/>Il boit de l''eau parce qu''il fait très chaud.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un grand soleil, un thermomètre au maximum et un homme qui boit une bouteille d''eau : **il fait très chaud**. Seule D décrit la scène. A (déneiger) montrerait de la neige et une pelle, B (s''abriter de l''orage) des éclairs et de la pluie, C (patiner) de la glace et des patins — ce sont des temps froids ou pluvieux, contraires à l''image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 4. [Format A] Grand vent : arbre penché, feuilles qui volent, homme tenant son chapeau
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000004', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="158" width="320" height="42" fill="#168F5B"/><path d="M 60 158 Q 72 110 95 85" stroke="#15296B" stroke-width="9" fill="none"/><ellipse cx="112" cy="74" rx="34" ry="22" fill="#0F6E45" transform="rotate(18 112 74)"/><path d="M 150 45 Q 185 38 215 45" stroke="#1E3A8C" stroke-width="3" fill="none"/><path d="M 140 70 Q 180 62 225 70" stroke="#1E3A8C" stroke-width="3" fill="none"/><path d="M 155 95 Q 190 88 220 95" stroke="#1E3A8C" stroke-width="3" fill="none"/><ellipse cx="190" cy="52" rx="6" ry="3" fill="#E8A317" transform="rotate(-25 190 52)"/><ellipse cx="232" cy="80" rx="6" ry="3" fill="#E8A317" transform="rotate(20 232 80)"/><ellipse cx="160" cy="108" rx="6" ry="3" fill="#E8A317" transform="rotate(-15 160 108)"/><circle cx="255" cy="100" r="13" fill="#0F1839"/><rect x="245" y="113" width="20" height="45" rx="4" fill="#1E3A8C"/><rect x="242" y="84" width="28" height="7" rx="3" fill="#E8A317"/><line x1="245" y1="105" x2="248" y2="90" stroke="#0F1839" stroke-width="4"/></svg>',
   NULL,
   'Le vent souffle très fort : un arbre est penché, des feuilles volent dans l''air et un homme retient son chapeau avec la main.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Il se promène sous un ciel calme et ensoleillé.
B. Il tient son chapeau à cause du vent très fort.
C. Il regarde la neige tomber par la fenêtre.
D. Il se baigne dans la rivière en été.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il se promène sous un ciel calme et ensoleillé.<break time="700ms"/>B.<break time="300ms"/>Il tient son chapeau à cause du vent très fort.<break time="700ms"/>C.<break time="300ms"/>Il regarde la neige tomber par la fenêtre.<break time="700ms"/>D.<break time="300ms"/>Il se baigne dans la rivière en été.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un arbre penché, des feuilles qui volent et un homme qui retient son chapeau : **il y a beaucoup de vent**. Seule B correspond. A décrit un temps calme et ensoleillé, c''est le contraire de la scène ; C (regarder la neige) montrerait des flocons et une fenêtre ; D (se baigner) une rivière et un maillot de bain — rien de cela n''est sur l''image.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 5. [Format A] Après la pluie : arc-en-ciel, nuage, deux personnes qui regardent
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000005', 'A2', 'co_image_proposition', '22222222-0000-0000-0000-000000000001',
   '<svg viewBox="0 0 320 200" xmlns="http://www.w3.org/2000/svg"><rect width="320" height="200" fill="#E8ECF8"/><rect x="0" y="158" width="320" height="42" fill="#168F5B"/><path d="M 55 158 A 105 105 0 0 1 265 158" stroke="#1E3A8C" stroke-width="10" fill="none"/><path d="M 68 158 A 92 92 0 0 1 252 158" stroke="#168F5B" stroke-width="10" fill="none"/><path d="M 81 158 A 79 79 0 0 1 239 158" stroke="#E8A317" stroke-width="10" fill="none"/><ellipse cx="55" cy="58" rx="30" ry="14" fill="#FFFFFF"/><ellipse cx="78" cy="50" rx="22" ry="11" fill="#FFFFFF"/><line x1="48" y1="76" x2="44" y2="90" stroke="#1E3A8C" stroke-width="3"/><line x1="66" y1="78" x2="62" y2="92" stroke="#1E3A8C" stroke-width="3"/><circle cx="140" cy="122" r="11" fill="#0F1839"/><rect x="131" y="133" width="18" height="28" rx="4" fill="#1E3A8C"/><circle cx="180" cy="122" r="11" fill="#E8A317"/><rect x="171" y="133" width="18" height="28" rx="4" fill="#0F6E45"/></svg>',
   NULL,
   'Après la pluie, un grand arc-en-ciel traverse le ciel à côté d''un nuage qui laisse encore tomber quelques gouttes ; deux personnes le regardent.',
   'Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.

A. Ils observent les étoiles pendant la nuit.
B. Ils se protègent de la grêle sous un abri.
C. Ils ramassent des feuilles mortes en automne.
D. Ils regardent l''arc-en-ciel après la pluie.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l''image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ils observent les étoiles pendant la nuit.<break time="700ms"/>B.<break time="300ms"/>Ils se protègent de la grêle sous un abri.<break time="700ms"/>C.<break time="300ms"/>Ils ramassent des feuilles mortes en automne.<break time="700ms"/>D.<break time="300ms"/>Ils regardent l''arc-en-ciel après la pluie.</prosody></voice></speak>',
   'Écoutez les propositions et choisissez celle qui correspond à l''image.',
   'L''image montre un grand arc-en-ciel, un nuage avec les dernières gouttes et deux personnes qui lèvent les yeux : **ils regardent l''arc-en-ciel après la pluie**. Seule D correspond. A (observer les étoiles) se passerait la nuit, avec un ciel sombre ; B (se protéger de la grêle) montrerait un abri et des grêlons ; C (ramasser des feuilles mortes) un sol couvert de feuilles d''automne.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-DeniseNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 6. [Format B] « Quel temps annonce la météo pour demain à Brest ? » (prévision) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000006', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Quel temps annonce la météo pour demain à Brest ?

A. À la radio, ce matin.
B. Des orages dans l''après-midi.
C. Depuis trois jours déjà.
D. Avec mon frère Amadou.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quel temps annonce la météo pour demain à Brest ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>À la radio, ce matin.<break time="700ms"/>B.<break time="300ms"/>Des orages dans l''après-midi.<break time="700ms"/>C.<break time="300ms"/>Depuis trois jours déjà.<break time="700ms"/>D.<break time="300ms"/>Avec mon frère Amadou.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quel temps annonce la météo ? » porte sur **le temps prévu**. Seule B « des orages dans l''après-midi » décrit une météo. A indique où on a entendu la météo et répondrait à « où l''as-tu écoutée ? », C donne une durée et répondrait à « depuis quand pleut-il ? », D désigne une personne et répondrait à « avec qui as-tu écouté ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 7. [Format B] « Quelle est ta saison préférée, Olena ? » (saison) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000007', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quelle est ta saison préférée, Olena ?

A. L''automne, pour les couleurs des arbres.
B. Au mois de janvier, en général.
C. Dans le sud de l''Espagne.
D. Avec une bonne écharpe chaude.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quelle est ta saison préférée, Olena ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''automne, pour les couleurs des arbres.<break time="700ms"/>B.<break time="300ms"/>Au mois de janvier, en général.<break time="700ms"/>C.<break time="300ms"/>Dans le sud de l''Espagne.<break time="700ms"/>D.<break time="300ms"/>Avec une bonne écharpe chaude.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quelle est ta saison préférée ? » attend **le nom d''une saison**. Seule A « l''automne » en nomme une. B donne un mois et répondrait à « quand pars-tu en vacances ? », C indique un lieu et répondrait à « où vas-tu en hiver ? », D décrit un vêtement et répondrait à « comment te protèges-tu du froid ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 8. [Format B] « Quelle température fait-il dehors ce matin ? » (température) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000008', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Quelle température fait-il dehors ce matin ?

A. Jusqu''à la fin de la semaine.
B. Devant la porte du garage.
C. Moins deux degrés, il gèle.
D. Mon voisin Rachid me l''a dit.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Quelle température fait-il dehors ce matin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Jusqu''à la fin de la semaine.<break time="700ms"/>B.<break time="300ms"/>Devant la porte du garage.<break time="700ms"/>C.<break time="300ms"/>Moins deux degrés, il gèle.<break time="700ms"/>D.<break time="300ms"/>Mon voisin Rachid me l''a dit.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quelle température fait-il ? » attend **un nombre de degrés**. Seule C « moins deux degrés, il gèle » donne une température. A indique une durée et répondrait à « jusqu''à quand fera-t-il froid ? », B donne un lieu et répondrait à « où as-tu vu le verglas ? », D désigne une personne et répondrait à « qui t''a donné l''information ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 9. [Format B] « Quand commence l'hiver cette année ? » (date) — Henri
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-000000000009', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Homme] Quand commence l''hiver cette année ?

A. Le vingt et un décembre.
B. Il fera moins cinq degrés.
C. Dans les montagnes du Jura.
D. Pendant trois mois entiers.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Quand commence l''hiver cette année ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le vingt et un décembre.<break time="700ms"/>B.<break time="300ms"/>Il fera moins cinq degrés.<break time="700ms"/>C.<break time="300ms"/>Dans les montagnes du Jura.<break time="700ms"/>D.<break time="300ms"/>Pendant trois mois entiers.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Quand commence l''hiver ? » porte sur **une date de début**. Seule A « le vingt et un décembre » donne une date. B annonce une température et répondrait à « quel temps fera-t-il ? », C indique un lieu et répondrait à « où neige-t-il le plus ? », D donne une durée et répondrait à « combien de temps dure l''hiver ? ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  -- ----------------------------------------------------------------------------
  -- 10. [Format B] « Pourquoi est-ce que tu prends ton parapluie ? » (cause) — Vivienne
  -- ----------------------------------------------------------------------------
  ('66666666-a008-1000-0000-00000000000a', 'A2', 'co_question_reponse', '22222222-0000-0000-0000-000000000001',
   NULL, NULL, NULL,
   'Écoutez la question et les quatre réponses. Choisissez la bonne réponse.

[Femme] Pourquoi est-ce que tu prends ton parapluie ?

A. Le grand parapluie bleu de Wei.
B. Dans le placard de l''entrée.
C. Parce que la pluie arrive cet après-midi.
D. Douze euros au magasin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Pourquoi est-ce que tu prends ton parapluie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le grand parapluie bleu de Wei.<break time="700ms"/>B.<break time="300ms"/>Dans le placard de l''entrée.<break time="700ms"/>C.<break time="300ms"/>Parce que la pluie arrive cet après-midi.<break time="700ms"/>D.<break time="300ms"/>Douze euros au magasin.</prosody></voice></speak>',
   'Écoutez la question, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La question « Pourquoi prends-tu ton parapluie ? » attend **une cause**. Seule C « parce que la pluie arrive » donne une raison, introduite par « parce que ». A décrit l''objet et répondrait à « quel parapluie prends-tu ? », B donne un lieu et répondrait à « où le ranges-tu ? », D indique un prix et répondrait à « combien l''as-tu payé ? ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED', NULL,
   NULL, NULL, NULL, NULL, '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 10 items, UUID déterministes '66666666-a008-1000-0000-0000000000NN'
--     (NN = 01..09, 0a), tous uniques.
-- [x] Thème unique « météo & saisons », 10 scènes toutes différentes :
--     pluie/parapluie, neige/bonhomme, canicule/thermomètre, grand vent,
--     arc-en-ciel, prévision météo (demain), saison préférée, température
--     du matin, date de début de l'hiver, cause (parapluie/pluie).
--     Aucun thème interdit (repas, transports, commerces, santé, école,
--     maison, loisirs, travail, famille, services, voyages, fêtes, nature/parc).
-- [x] 5 × format A (co_image_proposition, inline_svg + image_alt_text,
--     SSML mono-voix Denise) + 5 × format B (co_question_reponse,
--     inline_svg/image_alt_text NULL, SSML Denise → Vivienne (×3 : items
--     6, 8, 10) / Henri (×2 : items 7, 9) → Denise).
-- [x] 4 propositions / exactement 1 correcte par item. Distribution des
--     bonnes réponses : A=3 (items 2,7,9), B=2 (items 4,6), C=3 (items
--     1,8,10), D=2 (items 3,5) — 4 lettres utilisées, max 3.
-- [x] Compréhension explicite A2 : bonne réponse littérale, distracteurs
--     nettement distincts (autre lieu / action / moment / personne / cause).
-- [x] explanation ≥ 80 caractères : justifie la bonne réponse ET les 3
--     distracteurs (avec la question à laquelle chacun répondrait), point
--     clé en **gras**.
-- [x] SVG : viewBox 320×200, palette charte uniquement, pas de texte,
--     rouge #E1372F utilisé une seule fois et à bon escient (thermomètre
--     de canicule, item 3 — signal critique), scènes lisibles en < 2 s,
--     alt_text présent sur les 5 CO_IMAGE.
-- [x] SSML : balises <voice>/<prosody> équilibrées, pauses 1500/1000/700/
--     300 ms conformes, voix Denise 0.95 / Henri & Vivienne 1.0.
-- [x] voice_recommended cohérent (Denise format A ; voix de la question
--     format B). status='TEXT_VALIDATED', colonnes audio toutes NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] SQL : apostrophes doublées partout (SSML/SVG/JSONB inclus), JSONB
--     valide. Contenu 100 % original (prénoms variés : Amadou, Olena,
--     Rachid, Wei ; villes : Brest, le Jura, l'Espagne).
-- ============================================================================
