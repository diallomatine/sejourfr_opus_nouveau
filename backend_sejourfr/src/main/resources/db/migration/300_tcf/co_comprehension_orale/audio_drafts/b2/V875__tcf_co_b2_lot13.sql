-- ============================================================================
-- V875 — TCF CO B2 — lot 13 (thème : présentation culturelle)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue expositif long (~120-200 mots)
-- + question implicite (propos vs thème, intention du locuteur, idée principale,
-- conséquence non dite). Table audio_question_draft. status='TEXT_VALIDATED',
-- colonnes audio NULL (remplies par le batch admin Azure). Contenu 100% original,
-- œuvres, fêtes et locuteurs inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00d-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonsoir, je suis Wei Lin, commissaire de l''exposition Rives, qui ouvre demain à la galerie du Quai, à Perpignan. Pendant trois ans, la photographe ukrainienne Olena Vasylenko a longé quatre fleuves européens, du delta jusqu''à la source. On m''a souvent demandé si son travail dénonçait la pollution des berges ; certaines images la montrent, c''est vrai, mais s''arrêter là serait passer à côté de l''essentiel. Regardez les tirages de la première salle : des pêcheurs qui discutent à l''aube, des enfants qui plongent depuis un ponton, une fanfare qui répète sous un pont. Ce que ces photographies racontent, c''est que le fleuve n''est pas un décor : c''est une place publique liquide, un endroit où une ville entière se croise, se parle, se dispute parfois. Olena ne photographie pas l''eau, elle photographie ce que l''eau rend possible entre les gens. Voilà le fil qui relie les quatre-vingts images que vous allez découvrir.

Quel est le propos de cette exposition ?

A. Dénoncer la dégradation des berges des fleuves européens.
B. Montrer que le fleuve est un espace de vie sociale partagé.
C. Retracer l''évolution des techniques de la photographie de paysage.
D. Inciter le public à protéger les milieux aquatiques.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonsoir, je suis Wei Lin, commissaire de l''exposition Rives, qui ouvre demain à la galerie du Quai, à Perpignan. Pendant trois ans, la photographe ukrainienne Olena Vasylenko a longé quatre fleuves européens, du delta jusqu''à la source. On m''a souvent demandé si son travail dénonçait la pollution des berges ; certaines images la montrent, c''est vrai, mais s''arrêter là serait passer à côté de l''essentiel. Regardez les tirages de la première salle : des pêcheurs qui discutent à l''aube, des enfants qui plongent depuis un ponton, une fanfare qui répète sous un pont. Ce que ces photographies racontent, c''est que le fleuve n''est pas un décor : c''est une place publique liquide, un endroit où une ville entière se croise, se parle, se dispute parfois. Olena ne photographie pas l''eau, elle photographie ce que l''eau rend possible entre les gens. Voilà le fil qui relie les quatre-vingts images que vous allez découvrir.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le propos de cette exposition ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Dénoncer la dégradation des berges des fleuves européens.<break time="700ms"/>B.<break time="300ms"/>Montrer que le fleuve est un espace de vie sociale partagé.<break time="700ms"/>C.<break time="300ms"/>Retracer l''évolution des techniques de la photographie de paysage.<break time="700ms"/>D.<break time="300ms"/>Inciter le public à protéger les milieux aquatiques.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Wei Lin écarte elle-même la lecture écologique (« s''arrêter là serait passer à côté de l''essentiel ») et formule le propos : le fleuve est « une place publique liquide », un endroit où la ville « se croise, se parle ». B reformule cette **idée principale**. A élève un **détail secondaire** admis (« certaines images la montrent, c''est vrai ») au rang de propos — piège entre détail et idée principale. C confond le sujet des images avec un discours sur l''évolution des **techniques photographiques**, jamais tenu. D prête à l''exposition une **intention militante** (protéger les milieux aquatiques) que la commissaire ne revendique nulle part : elle parle de lien social, pas d''écologie.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00d-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, Tarek Belkacem, musicologue. Avant que le concert commence, quelques mots sur ce que vous allez entendre ce soir à Foix. Le cant de palanca — le chant de la passerelle — est une polyphonie née dans les vallées voisines, que l''on entonne à plusieurs voix, sans chef et sans partition. Beaucoup imaginent un répertoire figé, réservé à des spécialistes en costume. C''est exactement l''inverse. Ici, personne n''a jamais écrit ces chants : chacun les apprend en chantant à côté d''un aîné, au café, lors d''un mariage, après une fête de village. Et il n''existe pas de frontière entre la scène et la salle : tout à l''heure, les chanteurs descendront parmi vous et certains d''entre vous, peut-être, tiendront une voix sans l''avoir prévu. Si cette musique a traversé les siècles, ce n''est pas parce qu''on l''a protégée dans des archives, c''est parce qu''elle ne s''est jamais séparée de la vie ordinaire des habitants.

Quelle est l''idée principale de cette présentation ?

A. Ce chant a survécu grâce au travail patient des archivistes.
B. Cette polyphonie est interprétée par des chanteurs professionnels en costume.
C. Ce répertoire ancien est aujourd''hui reconstitué d''après des partitions retrouvées.
D. Cette tradition reste vivante parce qu''elle se transmet dans la vie quotidienne.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, Tarek Belkacem, musicologue. Avant que le concert commence, quelques mots sur ce que vous allez entendre ce soir à Foix. Le cant de palanca — le chant de la passerelle — est une polyphonie née dans les vallées voisines, que l''on entonne à plusieurs voix, sans chef et sans partition. Beaucoup imaginent un répertoire figé, réservé à des spécialistes en costume. C''est exactement l''inverse. Ici, personne n''a jamais écrit ces chants : chacun les apprend en chantant à côté d''un aîné, au café, lors d''un mariage, après une fête de village. Et il n''existe pas de frontière entre la scène et la salle : tout à l''heure, les chanteurs descendront parmi vous et certains d''entre vous, peut-être, tiendront une voix sans l''avoir prévu. Si cette musique a traversé les siècles, ce n''est pas parce qu''on l''a protégée dans des archives, c''est parce qu''elle ne s''est jamais séparée de la vie ordinaire des habitants.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale de cette présentation ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Ce chant a survécu grâce au travail patient des archivistes.<break time="700ms"/>B.<break time="300ms"/>Cette polyphonie est interprétée par des chanteurs professionnels en costume.<break time="700ms"/>C.<break time="300ms"/>Ce répertoire ancien est aujourd''hui reconstitué d''après des partitions retrouvées.<break time="700ms"/>D.<break time="300ms"/>Cette tradition reste vivante parce qu''elle se transmet dans la vie quotidienne.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tout le discours oppose les idées reçues (« répertoire figé, réservé à des spécialistes ») à la réalité : apprentissage « en chantant à côté d''un aîné », absence de partition, frontière scène-salle abolie, et conclusion « elle ne s''est jamais séparée de la vie ordinaire des habitants ». D synthétise cette **idée principale** : une tradition vivante par transmission orale quotidienne. A pratique une **inversion de cause** : la musique a survécu « pas parce qu''on l''a protégée dans des archives ». B reprend l''image que Tarek qualifie d''« exactement l''inverse ». C contredit « personne n''a jamais écrit ces chants » : il n''existe aucune partition à reconstituer.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00d-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Merci d''être venus si nombreux ce soir au cinéma Le Cormoran, à Lorient. Je suis Ingrid Halvorsen et je vais vous présenter en quelques mots Les mains d''abord, le documentaire que vous allez voir. Pendant quatorze mois, j''ai filmé Joana, l''une des dernières marionnettistes à fabriquer entièrement ses personnages, du bloc de tilleul jusqu''au costume. Quand le film est sorti, plusieurs journalistes ont écrit qu''il s''agissait d''un cri d''alarme sur un métier qui disparaît. Je comprends cette lecture, mais ce n''est pas mon sujet. Ce qui m''a retenue chez Joana, c''est sa relation au temps : elle passe trois semaines sur un visage de bois, recommence un regard qui ne lui plaît pas, refuse de compter ses heures. Mon film est une invitation à ralentir avec elle, à éprouver la durée d''un geste, dans un monde où tout doit aller vite. Si vous sortez de la salle avec ce léger vertige-là, alors le film aura trouvé son public.

Quelle est l''intention de la réalisatrice ?

A. Faire éprouver au spectateur un autre rapport au temps.
B. Alerter le public sur la disparition d''un métier d''art.
C. Apprendre aux spectateurs à fabriquer des marionnettes.
D. Retracer son propre parcours de cinéaste documentaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Merci d''être venus si nombreux ce soir au cinéma Le Cormoran, à Lorient. Je suis Ingrid Halvorsen et je vais vous présenter en quelques mots Les mains d''abord, le documentaire que vous allez voir. Pendant quatorze mois, j''ai filmé Joana, l''une des dernières marionnettistes à fabriquer entièrement ses personnages, du bloc de tilleul jusqu''au costume. Quand le film est sorti, plusieurs journalistes ont écrit qu''il s''agissait d''un cri d''alarme sur un métier qui disparaît. Je comprends cette lecture, mais ce n''est pas mon sujet. Ce qui m''a retenue chez Joana, c''est sa relation au temps : elle passe trois semaines sur un visage de bois, recommence un regard qui ne lui plaît pas, refuse de compter ses heures. Mon film est une invitation à ralentir avec elle, à éprouver la durée d''un geste, dans un monde où tout doit aller vite. Si vous sortez de la salle avec ce léger vertige-là, alors le film aura trouvé son public.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention de la réalisatrice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Faire éprouver au spectateur un autre rapport au temps.<break time="700ms"/>B.<break time="300ms"/>Alerter le public sur la disparition d''un métier d''art.<break time="700ms"/>C.<break time="300ms"/>Apprendre aux spectateurs à fabriquer des marionnettes.<break time="700ms"/>D.<break time="300ms"/>Retracer son propre parcours de cinéaste documentaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Ingrid récuse explicitement la lecture du « cri d''alarme » (« ce n''est pas mon sujet ») et formule son projet : « une invitation à ralentir », « éprouver la durée d''un geste ». A reformule cette **intention de la réalisatrice** : faire vivre un autre rapport au temps. B reprend la lecture des journalistes qu''elle rejette — piège B2 entre **l''intention prêtée par d''autres et l''intention revendiquée** par la locutrice. C transforme le contenu filmé (la fabrication des personnages) en visée pédagogique : le film montre un geste, il n''enseigne pas une technique. D est hors sujet : elle parle de Joana et de ce film précis, jamais de sa carrière.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00d-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir à tous. Mateo Vargas, conservateur du patrimoine. Nous sommes réunis dans la chapelle Saint-Aubin de Vernoux pour un moment assez rare. Depuis dix-huit mois, une équipe de restaurateurs nettoie la grande fresque du chœur, centimètre par centimètre. Or, le mois dernier, en retirant un repeint du dix-neuvième siècle, ils ont mis au jour, dans l''angle inférieur droit, une inscription : un nom, Étiennette de Brassac, et une date, 1462. Jusqu''ici, tous les ouvrages dataient cette fresque des années 1560 et l''attribuaient à un atelier itinérant venu d''Italie. La voilà donc plus ancienne d''un siècle, et signée — chose exceptionnelle — par une femme. Je vous laisse mesurer ce que cela implique : les notices des manuels, les panneaux de la chapelle, les chronologies régionales, tout ce qui s''appuyait sur la datation admise devra être repris. C''est le travail discret de la restauration : parfois, en nettoyant une œuvre, on déplace tout un pan de l''histoire de l''art.

Que peut-on déduire de cette découverte ?

A. La fresque a été endommagée pendant les travaux de restauration.
B. La chapelle devra bientôt fermer ses portes au public.
C. Les connaissances établies sur cette fresque doivent être révisées.
D. L''œuvre est en réalité une copie réalisée au dix-neuvième siècle.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir à tous. Mateo Vargas, conservateur du patrimoine. Nous sommes réunis dans la chapelle Saint-Aubin de Vernoux pour un moment assez rare. Depuis dix-huit mois, une équipe de restaurateurs nettoie la grande fresque du chœur, centimètre par centimètre. Or, le mois dernier, en retirant un repeint du dix-neuvième siècle, ils ont mis au jour, dans l''angle inférieur droit, une inscription : un nom, Étiennette de Brassac, et une date, 1462. Jusqu''ici, tous les ouvrages dataient cette fresque des années 1560 et l''attribuaient à un atelier itinérant venu d''Italie. La voilà donc plus ancienne d''un siècle, et signée — chose exceptionnelle — par une femme. Je vous laisse mesurer ce que cela implique : les notices des manuels, les panneaux de la chapelle, les chronologies régionales, tout ce qui s''appuyait sur la datation admise devra être repris. C''est le travail discret de la restauration : parfois, en nettoyant une œuvre, on déplace tout un pan de l''histoire de l''art.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que peut-on déduire de cette découverte ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La fresque a été endommagée pendant les travaux de restauration.<break time="700ms"/>B.<break time="300ms"/>La chapelle devra bientôt fermer ses portes au public.<break time="700ms"/>C.<break time="300ms"/>Les connaissances établies sur cette fresque doivent être révisées.<break time="700ms"/>D.<break time="300ms"/>L''œuvre est en réalité une copie réalisée au dix-neuvième siècle.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conséquence n''est jamais énoncée mot pour mot, mais Mateo l''impose : datation reculée d''un siècle, attribution bouleversée, « tout ce qui s''appuyait sur la datation admise devra être repris ». C explicite cette **conséquence implicite** : les connaissances établies doivent être révisées. A est un contresens d''**inversion cause-effet** : le nettoyage a révélé l''inscription, il n''a rien abîmé. B n''est jamais évoquée — la conférence se tient dans la chapelle et rien n''annonce une fermeture. D confond le **repeint du dix-neuvième siècle** (une couche ajoutée par-dessus l''original) avec une copie : la fresque elle-même date justement de 1462.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00d-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonsoir, et merci à la librairie L''Encre Marine de Sète de m''accueillir. Je suis Khadija Mansouri et je viens vous parler de mon roman, La Lessive des autres. Tout se passe dans une laverie automatique d''un quartier de Saint-Étienne, entre une machine numéro sept capricieuse et des bancs en plastique orange. Depuis la sortie du livre, on me présente parfois comme la romancière des petits commerces. Je souris, mais c''est un malentendu. La laverie n''est qu''un prétexte, un huis clos commode où mes personnages sont obligés d''attendre ensemble. Pendant que le linge tourne, une étudiante interroge un vieux mineur, une mère traduit pour sa voisine les lettres de l''administration, et des souvenirs que personne n''avait demandés remontent à la surface. Ce que j''ai voulu écrire, c''est la façon dont la mémoire d''un quartier — l''usine fermée, les exils, les arrivées — circule de bouche en bouche entre trois générations qui, sans cette attente partagée, ne se seraient jamais adressé la parole.

Quel est, selon l''autrice, le véritable sujet de son roman ?

A. Les difficultés économiques des petits commerces de quartier.
B. Le fonctionnement quotidien d''une laverie automatique.
C. La circulation de la mémoire d''un quartier entre les générations.
D. Le combat d''une étudiante pour faire rouvrir une usine.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonsoir, et merci à la librairie L''Encre Marine de Sète de m''accueillir. Je suis Khadija Mansouri et je viens vous parler de mon roman, La Lessive des autres. Tout se passe dans une laverie automatique d''un quartier de Saint-Étienne, entre une machine numéro sept capricieuse et des bancs en plastique orange. Depuis la sortie du livre, on me présente parfois comme la romancière des petits commerces. Je souris, mais c''est un malentendu. La laverie n''est qu''un prétexte, un huis clos commode où mes personnages sont obligés d''attendre ensemble. Pendant que le linge tourne, une étudiante interroge un vieux mineur, une mère traduit pour sa voisine les lettres de l''administration, et des souvenirs que personne n''avait demandés remontent à la surface. Ce que j''ai voulu écrire, c''est la façon dont la mémoire d''un quartier — l''usine fermée, les exils, les arrivées — circule de bouche en bouche entre trois générations qui, sans cette attente partagée, ne se seraient jamais adressé la parole.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est, selon l''autrice, le véritable sujet de son roman ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les difficultés économiques des petits commerces de quartier.<break time="700ms"/>B.<break time="300ms"/>Le fonctionnement quotidien d''une laverie automatique.<break time="700ms"/>C.<break time="300ms"/>La circulation de la mémoire d''un quartier entre les générations.<break time="700ms"/>D.<break time="300ms"/>Le combat d''une étudiante pour faire rouvrir une usine.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Khadija désamorce le malentendu (« la romancière des petits commerces… c''est un malentendu », « la laverie n''est qu''un prétexte ») puis livre son vrai sujet : la mémoire du quartier qui « circule de bouche en bouche entre trois générations ». C reformule ce **propos, distinct du décor** — mécanisme B2 de distinction entre thème apparent et propos réel. A reprend l''étiquette qu''elle refuse explicitement. B s''arrête au **cadre matériel** (la machine numéro sept, les bancs orange), simple décor du huis clos. D fabrique une intrigue à partir de deux détails (l''étudiante, l''usine fermée) : l''usine appartient aux souvenirs racontés, personne ne se bat pour la rouvrir.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00d-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir. Pavel Morand, historien. Pour ouvrir ce cycle de conférences à Draguignan, j''ai choisi une fête que vous croyez tous connaître : la Nuit des Chaudrons, qui illumine la ville chaque fin février. Les dépliants d''aujourd''hui en font un rendez-vous familial, avec défilé aux lampions et marrons grillés. Mais ouvrons les registres du dix-huitième siècle, et la fête change de visage. À l''époque, les ouvriers des tanneries élisaient un roi d''un soir, un apprenti coiffé d''une couronne de papier, qui paradait dans les rues en imitant la démarche du gouverneur. Derrière lui, les masques caricaturaient le juge, le percepteur, le maître de corporation. Pendant une nuit, et une seule, les humbles disaient tout haut ce qu''ils taisaient le reste de l''année, sans risquer la prison. Les autorités toléraient ce désordre réglé, car elles savaient qu''une moquerie autorisée prévient les révoltes véritables. Voilà ce que notre aimable défilé a oublié de ses origines : il fut, longtemps, la seule tribune des sans-voix.

Quelle était, à l''origine, la fonction de cette fête ?

A. Offrir au peuple un espace pour critiquer symboliquement les autorités.
B. Attirer des visiteurs afin de soutenir le commerce de la ville.
C. Célébrer la fin de l''hiver par un défilé familial aux lampions.
D. Couronner chaque année le meilleur apprenti des tanneries.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir. Pavel Morand, historien. Pour ouvrir ce cycle de conférences à Draguignan, j''ai choisi une fête que vous croyez tous connaître : la Nuit des Chaudrons, qui illumine la ville chaque fin février. Les dépliants d''aujourd''hui en font un rendez-vous familial, avec défilé aux lampions et marrons grillés. Mais ouvrons les registres du dix-huitième siècle, et la fête change de visage. À l''époque, les ouvriers des tanneries élisaient un roi d''un soir, un apprenti coiffé d''une couronne de papier, qui paradait dans les rues en imitant la démarche du gouverneur. Derrière lui, les masques caricaturaient le juge, le percepteur, le maître de corporation. Pendant une nuit, et une seule, les humbles disaient tout haut ce qu''ils taisaient le reste de l''année, sans risquer la prison. Les autorités toléraient ce désordre réglé, car elles savaient qu''une moquerie autorisée prévient les révoltes véritables. Voilà ce que notre aimable défilé a oublié de ses origines : il fut, longtemps, la seule tribune des sans-voix.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle était, à l''origine, la fonction de cette fête ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Offrir au peuple un espace pour critiquer symboliquement les autorités.<break time="700ms"/>B.<break time="300ms"/>Attirer des visiteurs afin de soutenir le commerce de la ville.<break time="700ms"/>C.<break time="300ms"/>Célébrer la fin de l''hiver par un défilé familial aux lampions.<break time="700ms"/>D.<break time="300ms"/>Couronner chaque année le meilleur apprenti des tanneries.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Pavel oppose la fête actuelle (« rendez-vous familial ») à sa fonction d''origine : caricaturer le juge, le percepteur, le gouverneur — « la seule tribune des sans-voix », tolérée car « une moquerie autorisée prévient les révoltes véritables ». A synthétise ce **rituel d''inversion sociale**, la fonction première que demande la question. B projette sur le passé la **fonction touristique actuelle** — piège d''anachronisme entre hier et aujourd''hui. C décrit l''apparence moderne (lampions, défilé familial), exactement ce que le conférencier invite à dépasser. D est un contresens sur le « roi d''un soir » : l''apprenti à la couronne de papier est une figure de **dérision**, pas la récompense du meilleur artisan.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes 66666666-c00d-1000-0000-000000000001..06.
-- [x] Format C exclusif (co_document_question), monologue expositif long :
--     longueurs comptées = 149 / 150 / 157 / 153 / 159 / 159 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « présentation culturelle », 6 situations toutes différentes
--     et inventées : vernissage d''une exposition photo (Perpignan), présentation
--     d''une polyphonie traditionnelle avant concert (Foix), avant-première d''un
--     documentaire (Lorient), conférence sur une fresque restaurée (Vernoux),
--     rencontre littéraire en librairie (Sète), conférence d''histoire sur un
--     carnaval (Draguignan). Aucun thème interdit (pas d''organisme/service, pas
--     de produit, pas de formation, pas de communiqué, pas de débat d''opinion).
--     Prénoms variés : Wei, Tarek, Ingrid, Mateo, Khadija, Pavel (+ Olena, Joana,
--     Étiennette en personnages cités).
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     A ×2 (items 3, 6), B ×1 (item 1), C ×2 (items 4, 5), D ×1 (item 2) —
--     max 2 par position, 4 positions utilisées.
-- [x] Compréhension implicite B2 : propos vs thème apparent (1, 5), idée
--     principale (2), intention du locuteur (3), conséquence non dite (4),
--     fonction d''origine vs apparence actuelle (6). Distracteurs tous plausibles
--     en reformulation (détail secondaire vs idée principale, inversion
--     cause/effet, anachronisme, intention prêtée vs revendiquée).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise (0.95) pour
--     intro/question/propositions, Vivienne/Henri (1.0) en alternance pour le
--     document, voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
