-- ============================================================================
-- V877 — TCF CO B2 — lot 15 (thème : enjeu environnemental)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : document parlé long (~120-200 mots),
-- monologue expositif OU dialogue dense + question implicite (idée principale,
-- intention du locuteur, conséquence non dite). 6 situations environnementales
-- toutes différentes et inventées. Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00f-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir à tous. Je suis Wei Lin, glaciologue, et je reviens d''une campagne de mesures dans le massif des Écrins. Quand on parle du recul des glaciers, on pense d''abord aux paysages : les photos d''avant et d''après émeuvent, et c''est normal. Mais je voudrais déplacer votre regard ce soir. Un glacier, c''est avant tout un réservoir. Il stocke la neige de l''hiver et la restitue en eau tout l''été, précisément au moment où il ne pleut presque plus. Les rivières alpines, les cultures des vallées, les centrales hydroélectriques et même certaines villes dépendent de ce robinet naturel. Or nos relevés montrent que les glaciers que nous suivons ont perdu un tiers de leur volume en vingt-cinq ans. Le jour où ils auront disparu, le problème ne sera pas la carte postale : ce seront des étés entiers avec des rivières à sec, et il faudra choisir entre irriguer, produire de l''électricité et boire.

Quelle est l''idée principale développée par le conférencier ?

A. Le recul des glaciers dégrade surtout la beauté des paysages alpins.
B. La baisse du débit des rivières accélère la fonte des glaciers.
C. La disparition des glaciers menace d''abord l''approvisionnement en eau l''été.
D. Les centrales hydroélectriques consomment trop d''eau en montagne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir à tous. Je suis Wei Lin, glaciologue, et je reviens d''une campagne de mesures dans le massif des Écrins. Quand on parle du recul des glaciers, on pense d''abord aux paysages : les photos d''avant et d''après émeuvent, et c''est normal. Mais je voudrais déplacer votre regard ce soir. Un glacier, c''est avant tout un réservoir. Il stocke la neige de l''hiver et la restitue en eau tout l''été, précisément au moment où il ne pleut presque plus. Les rivières alpines, les cultures des vallées, les centrales hydroélectriques et même certaines villes dépendent de ce robinet naturel. Or nos relevés montrent que les glaciers que nous suivons ont perdu un tiers de leur volume en vingt-cinq ans. Le jour où ils auront disparu, le problème ne sera pas la carte postale : ce seront des étés entiers avec des rivières à sec, et il faudra choisir entre irriguer, produire de l''électricité et boire.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale développée par le conférencier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le recul des glaciers dégrade surtout la beauté des paysages alpins.<break time="700ms"/>B.<break time="300ms"/>La baisse du débit des rivières accélère la fonte des glaciers.<break time="700ms"/>C.<break time="300ms"/>La disparition des glaciers menace d''abord l''approvisionnement en eau l''été.<break time="700ms"/>D.<break time="300ms"/>Les centrales hydroélectriques consomment trop d''eau en montagne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le conférencier écarte lui-même la lecture esthétique (« le problème ne sera pas la carte postale ») pour recentrer sur la fonction de réservoir : l''eau restituée l''été, dont dépendent rivières, cultures, centrales et villes. C synthétise cette **idée principale** — mécanisme B2 de distinction entre **thème apparent (le paysage) et propos réel (la ressource en eau)**. A reprend précisément l''angle que Wei Lin demande d''abandonner (« déplacer votre regard »). B **inverse la cause et l''effet** : c''est la fonte des glaciers qui fera baisser les rivières, pas l''inverse. D détourne un détail : les centrales sont citées comme dépendantes du « robinet naturel », jamais comme consommatrices excessives.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00f-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Aïcha, je ne comprends plus rien. J''ai déplacé mes ruches loin des grandes cultures, comme on me l''avait conseillé, et pourtant mes colonies restent fragiles. J''ai perdu un quart de mes abeilles cet hiver.
[Femme] Ce que vous observez, Bogdan, on le retrouve partout. On a longtemps cherché un coupable unique, et les traitements chimiques en font évidemment partie. Mais nos relevés racontent autre chose : autour de vos ruches, il y a du tournesol en juillet, et presque rien le reste de l''année. Vos abeilles connaissent trois semaines d''abondance, puis des mois de disette. Une colonie mal nourrie résiste mal aux parasites, au froid, au moindre traitement. Ce n''est pas un poison qui les tue d''un coup, c''est un paysage devenu monotone qui les affaiblit lentement.
[Homme] Donc même sans pesticides, elles resteraient en danger ?
[Femme] Tant que les haies, les prairies fleuries et les jachères n''auront pas retrouvé leur place, oui. C''est tout l''équilibre du paysage qu''il faut soigner, pas seulement les bidons qu''on interdit.

Que cherche à faire comprendre la chercheuse ?

A. L''appauvrissement du paysage agricole affaiblit durablement les abeilles.
B. Les traitements chimiques sont l''unique cause de la mortalité des colonies.
C. Les apiculteurs devraient déplacer leurs ruches plus souvent.
D. Le tournesol assure aux abeilles une nourriture suffisante toute l''année.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Aïcha, je ne comprends plus rien. J''ai déplacé mes ruches loin des grandes cultures, comme on me l''avait conseillé, et pourtant mes colonies restent fragiles. J''ai perdu un quart de mes abeilles cet hiver.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Ce que vous observez, Bogdan, on le retrouve partout. On a longtemps cherché un coupable unique, et les traitements chimiques en font évidemment partie. Mais nos relevés racontent autre chose : autour de vos ruches, il y a du tournesol en juillet, et presque rien le reste de l''année. Vos abeilles connaissent trois semaines d''abondance, puis des mois de disette. Une colonie mal nourrie résiste mal aux parasites, au froid, au moindre traitement. Ce n''est pas un poison qui les tue d''un coup, c''est un paysage devenu monotone qui les affaiblit lentement.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Donc même sans pesticides, elles resteraient en danger ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Tant que les haies, les prairies fleuries et les jachères n''auront pas retrouvé leur place, oui. C''est tout l''équilibre du paysage qu''il faut soigner, pas seulement les bidons qu''on interdit.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que cherche à faire comprendre la chercheuse ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''appauvrissement du paysage agricole affaiblit durablement les abeilles.<break time="700ms"/>B.<break time="300ms"/>Les traitements chimiques sont l''unique cause de la mortalité des colonies.<break time="700ms"/>C.<break time="300ms"/>Les apiculteurs devraient déplacer leurs ruches plus souvent.<break time="700ms"/>D.<break time="300ms"/>Le tournesol assure aux abeilles une nourriture suffisante toute l''année.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La chercheuse reconnaît le rôle des traitements chimiques mais déplace l''explication : « ce n''est pas un poison qui les tue d''un coup, c''est un paysage devenu monotone qui les affaiblit lentement », puis conclut sur « tout l''équilibre du paysage ». A reformule cette **idée principale** : appauvrissement floral, donc affaiblissement durable des colonies. B transforme une cause partielle reconnue en **cause unique**, ce que le document réfute expressément (« on a longtemps cherché un coupable unique »). C prend pour conclusion une **solution déjà essayée et inefficace** : Bogdan a déplacé ses ruches sans résultat. D est un contresens sur un détail : le tournesol n''offre que « trois semaines d''abondance », suivies de « mois de disette ».',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00f-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Avancez doucement, nous arrivons au cœur du marais de Lonzac. Je m''appelle Carlos Ribeiro et je guide des visites ici depuis neuf ans. Il y a encore quinze ans, ce site était une prairie drainée, presque sèche, traversée par un fossé rectiligne. Une commune voisine avait dépensé des sommes considérables pour creuser des bassins censés retenir l''eau : ils se vidaient chaque été. Puis une famille de castors s''est installée, sans que personne ne l''invite. En trois ans, leurs barrages de branchages ont fait remonter le niveau de l''eau, ralenti le courant, recréé des mares. Les libellules sont revenues, puis les hérons, puis les brochets. Regardez autour de vous : aucun engin de chantier n''a produit ce résultat. Si je raconte cette histoire à chaque groupe, ce n''est pas par tendresse pour les castors. C''est parce qu''elle montre qu''un milieu retrouve souvent sa santé quand on cesse de vouloir tout aménager à sa place.

Pourquoi le guide raconte-t-il cette histoire à chaque groupe ?

A. Pour montrer son attachement personnel à ces animaux.
B. Pour dénoncer les dépenses inutiles de la commune voisine.
C. Pour expliquer la technique de construction des barrages.
D. Pour illustrer qu''un milieu se régénère mieux sans aménagements humains.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Avancez doucement, nous arrivons au cœur du marais de Lonzac. Je m''appelle Carlos Ribeiro et je guide des visites ici depuis neuf ans. Il y a encore quinze ans, ce site était une prairie drainée, presque sèche, traversée par un fossé rectiligne. Une commune voisine avait dépensé des sommes considérables pour creuser des bassins censés retenir l''eau : ils se vidaient chaque été. Puis une famille de castors s''est installée, sans que personne ne l''invite. En trois ans, leurs barrages de branchages ont fait remonter le niveau de l''eau, ralenti le courant, recréé des mares. Les libellules sont revenues, puis les hérons, puis les brochets. Regardez autour de vous : aucun engin de chantier n''a produit ce résultat. Si je raconte cette histoire à chaque groupe, ce n''est pas par tendresse pour les castors. C''est parce qu''elle montre qu''un milieu retrouve souvent sa santé quand on cesse de vouloir tout aménager à sa place.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi le guide raconte-t-il cette histoire à chaque groupe ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour montrer son attachement personnel à ces animaux.<break time="700ms"/>B.<break time="300ms"/>Pour dénoncer les dépenses inutiles de la commune voisine.<break time="700ms"/>C.<break time="300ms"/>Pour expliquer la technique de construction des barrages.<break time="700ms"/>D.<break time="300ms"/>Pour illustrer qu''un milieu se régénère mieux sans aménagements humains.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le guide dévoile son intention à la fin : il ne raconte pas l''anecdote « par tendresse pour les castors », mais parce qu''elle « montre qu''un milieu retrouve souvent sa santé quand on cesse de vouloir tout aménager à sa place ». D reformule cette **intention du locuteur** — mécanisme B2 d''inférence du propos derrière l''exemple. A reprend exactement la motivation que le guide **écarte lui-même**. B confond un élément du récit (l''échec coûteux des bassins) avec le but du discours : le guide illustre une idée générale, il ne polémique pas contre la commune. C transforme le document en mode d''emploi technique, alors que les barrages des castors sont décrits comme un phénomène spontané, pas comme un modèle à reproduire.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00f-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Anya, tu as signé la pétition pour éteindre les lampadaires du village après minuit ? Moi, ça m''inquiète, je rentre tard du travail.
[Femme] Je l''ai signée, oui, mais pas pour les raisons que tu imagines. Tout le monde croit que les astronomes amateurs comme moi veulent simplement revoir les étoiles. Sincèrement, ce n''est pas l''essentiel. Depuis que j''observe le ciel sur ma terrasse, c''est surtout le jardin que j''ai vu changer. Les papillons de nuit tournent autour des lampadaires jusqu''à mourir d''épuisement, au lieu de polliniser. Les chauves-souris ne chassent plus dans la rue éclairée. Même les merles chantent en plein hiver à trois heures du matin, complètement déréglés. Pour la faune nocturne, la lumière permanente, c''est comme un bruit qui ne s''arrêterait jamais.
[Homme] Et pour la sécurité, alors ?
[Femme] Les communes voisines qui éteignent déjà n''ont pas vu les cambriolages augmenter. Ce que je te demande, ce n''est pas d''aimer les étoiles : c''est de laisser la nuit faire son travail.

Quelle est l''intention d''Anya dans cette conversation ?

A. Rassurer son voisin sur la qualité du ciel étoilé du village.
B. Le convaincre que l''extinction nocturne protège avant tout la faune.
C. Démontrer que l''éclairage public favorise les cambriolages.
D. Obtenir qu''il rentre plus tôt de son travail.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Anya, tu as signé la pétition pour éteindre les lampadaires du village après minuit ? Moi, ça m''inquiète, je rentre tard du travail.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je l''ai signée, oui, mais pas pour les raisons que tu imagines. Tout le monde croit que les astronomes amateurs comme moi veulent simplement revoir les étoiles. Sincèrement, ce n''est pas l''essentiel. Depuis que j''observe le ciel sur ma terrasse, c''est surtout le jardin que j''ai vu changer. Les papillons de nuit tournent autour des lampadaires jusqu''à mourir d''épuisement, au lieu de polliniser. Les chauves-souris ne chassent plus dans la rue éclairée. Même les merles chantent en plein hiver à trois heures du matin, complètement déréglés. Pour la faune nocturne, la lumière permanente, c''est comme un bruit qui ne s''arrêterait jamais.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et pour la sécurité, alors ?</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Les communes voisines qui éteignent déjà n''ont pas vu les cambriolages augmenter. Ce que je te demande, ce n''est pas d''aimer les étoiles : c''est de laisser la nuit faire son travail.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention d''Anya dans cette conversation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Rassurer son voisin sur la qualité du ciel étoilé du village.<break time="700ms"/>B.<break time="300ms"/>Le convaincre que l''extinction nocturne protège avant tout la faune.<break time="700ms"/>C.<break time="300ms"/>Démontrer que l''éclairage public favorise les cambriolages.<break time="700ms"/>D.<break time="300ms"/>Obtenir qu''il rentre plus tôt de son travail.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Anya le dit elle-même : elle n''a pas signé « pour les raisons que tu imagines » — revoir les étoiles « n''est pas l''essentiel » — et conclut « ce n''est pas d''aimer les étoiles, c''est de laisser la nuit faire son travail ». Toute son argumentation (papillons épuisés, chauves-souris, merles déréglés) vise à convaincre Mehdi que l''extinction protège la **faune nocturne** : B. Le mécanisme B2 est l''**inférence de l''intention** derrière les exemples. A reprend le **motif de surface** (l''astronomie) qu''Anya désamorce explicitement. C déforme l''argument sécurité : les communes qui éteignent « n''ont pas vu les cambriolages augmenter » — elle neutralise une objection, elle n''accuse pas l''éclairage. D confond l''**objection de Mehdi** (rentrer tard) avec la demande d''Anya, qui ne porte jamais sur ses horaires.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00f-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, je suis Ousmane Traoré, pédologue : j''étudie les sols. On m''a demandé de vous parler de ce qu''il y a sous vos pieds, et je commence toujours par le même chiffre : il faut entre deux cents et mille ans pour former un seul centimètre de sol fertile. Un centimètre. Pendant ce temps, sur une parcelle laissée nue face aux orages, ce même centimètre peut disparaître en une dizaine d''années, emporté vers les rivières. Or le sol n''est pas une simple poussière : une poignée de terre vivante contient plus d''organismes que la planète ne compte d''habitants. Ce sont ces vers, ces champignons, ces bactéries qui fabriquent la fertilité, retiennent l''eau et stockent le carbone. Quand cette vie disparaît, on peut compenser quelques années avec des engrais, mais on ne répare pas le support lui-même. Comparez la vitesse de formation et la vitesse de perte : vous comprendrez pourquoi je refuse de parler du sol comme d''une ressource renouvelable.

Quelle conclusion peut-on tirer de cet exposé ?

A. Un sol dégradé est pratiquement irrécupérable à l''échelle d''une vie humaine.
B. Les engrais permettent de restaurer durablement la fertilité perdue.
C. Les rivières s''enrichissent de la terre emportée par l''érosion.
D. Les sols cultivés abritent plus d''organismes que les sols laissés nus.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, je suis Ousmane Traoré, pédologue : j''étudie les sols. On m''a demandé de vous parler de ce qu''il y a sous vos pieds, et je commence toujours par le même chiffre : il faut entre deux cents et mille ans pour former un seul centimètre de sol fertile. Un centimètre. Pendant ce temps, sur une parcelle laissée nue face aux orages, ce même centimètre peut disparaître en une dizaine d''années, emporté vers les rivières. Or le sol n''est pas une simple poussière : une poignée de terre vivante contient plus d''organismes que la planète ne compte d''habitants. Ce sont ces vers, ces champignons, ces bactéries qui fabriquent la fertilité, retiennent l''eau et stockent le carbone. Quand cette vie disparaît, on peut compenser quelques années avec des engrais, mais on ne répare pas le support lui-même. Comparez la vitesse de formation et la vitesse de perte : vous comprendrez pourquoi je refuse de parler du sol comme d''une ressource renouvelable.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle conclusion peut-on tirer de cet exposé ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Un sol dégradé est pratiquement irrécupérable à l''échelle d''une vie humaine.<break time="700ms"/>B.<break time="300ms"/>Les engrais permettent de restaurer durablement la fertilité perdue.<break time="700ms"/>C.<break time="300ms"/>Les rivières s''enrichissent de la terre emportée par l''érosion.<break time="700ms"/>D.<break time="300ms"/>Les sols cultivés abritent plus d''organismes que les sols laissés nus.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''exposé met en regard deux vitesses : « entre deux cents et mille ans » pour former un centimètre de sol, « une dizaine d''années » pour le perdre, et conclut par le refus de parler d''« une ressource renouvelable ». La **conséquence non dite** à déduire : un sol dégradé ne se reconstitue pas à l''échelle d''une vie humaine — A. B contredit le texte : les engrais « compensent quelques années » mais « on ne répare pas le support lui-même » — piège entre **palliatif provisoire et restauration durable**. C inverse la valeur d''un détail : la terre « emportée vers les rivières » illustre une perte, pas un enrichissement. D déforme la comparaison réelle (une poignée de terre vivante contre les habitants de la planète) en une comparaison entre types de sols jamais formulée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00f-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Madame Nguyen, expliquez-moi quand même : j''habite au bord de la Cisselle depuis quarante ans, et la rivière déborde maintenant presque chaque hiver. Pourtant, on ne peut pas dire qu''il pleuve tellement plus qu''avant.
[Femme] Vous avez raison, et c''est exactement ce que montrent nos mesures : les précipitations annuelles ont peu changé ici. Ce qui a changé, c''est le chemin que prend l''eau. Regardez la carte : en trente ans, les parkings, les lotissements et les zones commerciales ont recouvert l''équivalent de mille terrains de football sur le bassin. Avant, une averse s''infiltrait dans les prairies et mettait plusieurs jours à rejoindre la rivière. Aujourd''hui, elle glisse sur le bitume et arrive en quelques heures, toute en même temps.
[Homme] Donc ce n''est pas le ciel, le problème.
[Femme] Le ciel n''a presque pas changé ; c''est le sol qui ne fait plus son travail d''éponge. Tant qu''on continuera d''imperméabiliser les terres en amont, surélever vos digues ne fera que déplacer les débordements chez vos voisins d''aval.

Qu''est-ce que l''hydrologue cherche à faire comprendre au riverain ?

A. Les pluies hivernales sont devenues nettement plus abondantes.
B. La surélévation des digues mettra durablement sa maison à l''abri.
C. Le lit de la rivière déborde parce qu''il n''est plus entretenu.
D. L''imperméabilisation des sols en amont aggrave les crues de la rivière.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Madame Nguyen, expliquez-moi quand même : j''habite au bord de la Cisselle depuis quarante ans, et la rivière déborde maintenant presque chaque hiver. Pourtant, on ne peut pas dire qu''il pleuve tellement plus qu''avant.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Vous avez raison, et c''est exactement ce que montrent nos mesures : les précipitations annuelles ont peu changé ici. Ce qui a changé, c''est le chemin que prend l''eau. Regardez la carte : en trente ans, les parkings, les lotissements et les zones commerciales ont recouvert l''équivalent de mille terrains de football sur le bassin. Avant, une averse s''infiltrait dans les prairies et mettait plusieurs jours à rejoindre la rivière. Aujourd''hui, elle glisse sur le bitume et arrive en quelques heures, toute en même temps.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Donc ce n''est pas le ciel, le problème.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Le ciel n''a presque pas changé ; c''est le sol qui ne fait plus son travail d''éponge. Tant qu''on continuera d''imperméabiliser les terres en amont, surélever vos digues ne fera que déplacer les débordements chez vos voisins d''aval.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que l''hydrologue cherche à faire comprendre au riverain ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les pluies hivernales sont devenues nettement plus abondantes.<break time="700ms"/>B.<break time="300ms"/>La surélévation des digues mettra durablement sa maison à l''abri.<break time="700ms"/>C.<break time="300ms"/>Le lit de la rivière déborde parce qu''il n''est plus entretenu.<break time="700ms"/>D.<break time="300ms"/>L''imperméabilisation des sols en amont aggrave les crues de la rivière.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''hydrologue répond à l''énigme posée par Marc (plus de crues sans plus de pluie) en déplaçant la cause : « le ciel n''a presque pas changé ; c''est le sol qui ne fait plus son travail d''éponge », après avoir décrit trente ans d''imperméabilisation du bassin. D synthétise ce **diagnostic implicite** — mécanisme B2 d''**inversion cause/effet déjouée** : ce ne sont pas les pluies, c''est le ruissellement accéléré. A contredit les mesures citées (« les précipitations annuelles ont peu changé »). B contredit la mise en garde finale : surélever les digues « ne fera que déplacer les débordements » chez les voisins d''aval. C est plausible dans le contexte mais **jamais évoquée** : l''entretien du lit de la rivière n''apparaît nulle part dans le dialogue.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes 66666666-c00f-1000-0000-000000000001..06.
-- [x] Format C exclusif (co_document_question), documents parlés longs :
--     longueurs comptées (voix Henri/Vivienne uniquement, hors intro/question/
--     propositions) = 152 / 163 / 152 / 159 / 156 / 161 mots — toutes dans la
--     fourchette 120-200 mots B2. 3 monologues (items 1, 3, 5) +
--     3 dialogues denses (items 2, 4, 6).
-- [x] Thème unique « enjeu environnemental », 6 situations inventées toutes
--     différentes : conférence glaciologie / eau d''été (Écrins), dialogue
--     apicultrice-chercheuse sur la monotonie du paysage agricole, visite
--     guidée d''un marais restauré par des castors (Lonzac), conversation de
--     voisinage sur la pollution lumineuse et la faune nocturne, exposé
--     pédologie sur l''irréversibilité de la perte des sols, dialogue
--     hydrologue-riverain sur l''imperméabilisation et les crues (Cisselle).
--     Aucun thème interdit (pas de présentation d''organisme/service, pas de
--     communiqué, pas de chronique, pas de conseil d''expert, pas d''enjeu
--     économique, etc.). Prénoms variés : Wei, Aïcha, Bogdan, Carlos, Anya,
--     Mehdi, Ousmane, Marc, Mme Nguyen.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     pos1 (A) ×2 (items 2, 5), pos2 (B) ×1 (item 4), pos3 (C) ×1 (item 1),
--     pos4 (D) ×2 (items 3, 6) — max 2 par position, 4 positions utilisées.
-- [x] Compréhension implicite B2 : idée principale (items 1, 2), intention du
--     locuteur (items 3, 4), conséquence non dite (item 5), cause réelle
--     inférée (item 6) ; distracteurs tous plausibles (thème vs propos, détail
--     secondaire vs idée principale, inversion cause/effet, motif de surface).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré : monologues 4 <voice>/4 </voice>, dialogues
--     7 <voice>/7 </voice> (et autant de <prosody>), pauses conformes
--     (1500ms / 400ms entre répliques / 1000ms / 700ms / 300ms), voix Denise
--     (0.95) + Henri/Vivienne (1.0), voice_recommended = voix dominante du
--     document (Henri ×3, Vivienne ×3).
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
