-- ============================================================================
-- V867 — TCF CO B2 — lot 05 (thème : chronique & point de vue)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : chronique parlée longue (~120-200 mots),
-- un chroniqueur ou une chroniqueuse défend un point de vue personnel sur un
-- fait de société quotidien + question implicite (thèse, intention, idée
-- principale, distinction concession/réfutation). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, chroniqueurs et situations inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c005-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, ici Olena Tkachenko, pour ma chronique du mercredi. Cette semaine, j''ai retrouvé au fond d''un tiroir le cahier où je notais, à dix-sept ans, mes premières idées d''articles. Et j''entends déjà certains soupirer : encore une chronique nostalgique sur le bon vieux temps du stylo. Détrompez-vous. Je tape mes textes sur un clavier, comme tout le monde, et je ne le regrette pas. Ce que je veux défendre, c''est autre chose. Quand j''écris à la main, je suis obligée de ralentir, et ce ralentissement m''oblige à choisir : un mot plutôt que trois, une idée plutôt que dix. Les chercheurs le confirment, paraît-il, mais je n''ai pas besoin d''eux pour le constater : mes meilleures idées naissent sur le papier, jamais sur l''écran. Alors non, je ne demande pas de débrancher les ordinateurs. Je dis simplement : gardez un carnet. Pas par fidélité au passé, mais parce que la main, en ralentissant la phrase, donne du temps à la pensée.

Quelle idée la chroniqueuse défend-elle ?

A. Il faudrait revenir au stylo et renoncer aux claviers.
B. Écrire à la main aide à mieux penser, parce que le geste ralentit la réflexion.
C. L''écriture manuscrite mérite d''être conservée par respect pour le passé.
D. Les chercheurs devraient étudier davantage les effets des écrans.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, ici Olena Tkachenko, pour ma chronique du mercredi. Cette semaine, j''ai retrouvé au fond d''un tiroir le cahier où je notais, à dix-sept ans, mes premières idées d''articles. Et j''entends déjà certains soupirer : encore une chronique nostalgique sur le bon vieux temps du stylo. Détrompez-vous. Je tape mes textes sur un clavier, comme tout le monde, et je ne le regrette pas. Ce que je veux défendre, c''est autre chose. Quand j''écris à la main, je suis obligée de ralentir, et ce ralentissement m''oblige à choisir : un mot plutôt que trois, une idée plutôt que dix. Les chercheurs le confirment, paraît-il, mais je n''ai pas besoin d''eux pour le constater : mes meilleures idées naissent sur le papier, jamais sur l''écran. Alors non, je ne demande pas de débrancher les ordinateurs. Je dis simplement : gardez un carnet. Pas par fidélité au passé, mais parce que la main, en ralentissant la phrase, donne du temps à la pensée.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle idée la chroniqueuse défend-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il faudrait revenir au stylo et renoncer aux claviers.<break time="700ms"/>B.<break time="300ms"/>Écrire à la main aide à mieux penser, parce que le geste ralentit la réflexion.<break time="700ms"/>C.<break time="300ms"/>L''écriture manuscrite mérite d''être conservée par respect pour le passé.<break time="700ms"/>D.<break time="300ms"/>Les chercheurs devraient étudier davantage les effets des écrans.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La chroniqueuse écarte d''emblée la lecture nostalgique (« encore une chronique nostalgique… détrompez-vous ») et formule sa thèse à la fin : « la main, en ralentissant la phrase, donne du temps à la pensée » — B reformule ce **lien entre lenteur du geste et qualité de la réflexion** ; mécanisme B2 d''identification du point de vue réel derrière une concession. A force le propos : elle précise « je ne demande pas de débrancher les ordinateurs » et tape elle-même ses textes. C reprend exactement la lecture nostalgique qu''elle rejette (« pas par fidélité au passé »). D gonfle une **incise secondaire** (« les chercheurs le confirment, paraît-il ») en recommandation qu''elle ne formule jamais.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir, Diego Almeida, pour ma chronique hebdomadaire. Un auditeur m''a écrit cette semaine : depuis son déménagement à Angers, il n''arrive plus à se faire d''amis. Il a trente-huit ans et il croyait que ça viendrait tout seul, comme au collège. Voilà précisément l''illusion que je voudrais démonter ce soir. Enfants, nous vivions dans une machine à fabriquer des amitiés : la classe, la cantine, le club de handball, des heures partagées sans rien décider. Adultes, cette machine s''arrête, et nous continuons pourtant d''attendre que l''amitié tombe du ciel. Elle ne tombera pas. Une amitié adulte se construit comme on entretient un jardin : on propose le premier café, on relance après un silence, on bloque une soirée dans l''agenda même quand on est fatigué. Certains trouvent cela calculé, presque froid. Je crois exactement l''inverse : prévoir une place pour quelqu''un dans une vie saturée, c''est la plus grande preuve d''affection qui soit.

Que veut faire comprendre le chroniqueur ?

A. Les amitiés nouées à l''école restent les plus solides de la vie.
B. Déménager dans une nouvelle ville fait perdre tous ses amis.
C. Planifier ses relations rend les amitiés froides et calculées.
D. À l''âge adulte, l''amitié ne survient plus spontanément : elle demande un effort volontaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir, Diego Almeida, pour ma chronique hebdomadaire. Un auditeur m''a écrit cette semaine : depuis son déménagement à Angers, il n''arrive plus à se faire d''amis. Il a trente-huit ans et il croyait que ça viendrait tout seul, comme au collège. Voilà précisément l''illusion que je voudrais démonter ce soir. Enfants, nous vivions dans une machine à fabriquer des amitiés : la classe, la cantine, le club de handball, des heures partagées sans rien décider. Adultes, cette machine s''arrête, et nous continuons pourtant d''attendre que l''amitié tombe du ciel. Elle ne tombera pas. Une amitié adulte se construit comme on entretient un jardin : on propose le premier café, on relance après un silence, on bloque une soirée dans l''agenda même quand on est fatigué. Certains trouvent cela calculé, presque froid. Je crois exactement l''inverse : prévoir une place pour quelqu''un dans une vie saturée, c''est la plus grande preuve d''affection qui soit.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que veut faire comprendre le chroniqueur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les amitiés nouées à l''école restent les plus solides de la vie.<break time="700ms"/>B.<break time="300ms"/>Déménager dans une nouvelle ville fait perdre tous ses amis.<break time="700ms"/>C.<break time="300ms"/>Planifier ses relations rend les amitiés froides et calculées.<break time="700ms"/>D.<break time="300ms"/>À l''âge adulte, l''amitié ne survient plus spontanément : elle demande un effort volontaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le chroniqueur oppose l''enfance (« une machine à fabriquer des amitiés ») à l''âge adulte, où « cette machine s''arrête » : il faut **inférer la thèse** — l''amitié adulte « se construit » (premier café, relance, soirée bloquée dans l''agenda) — que D synthétise. A déforme l''image de la machine : Diego décrit la facilité des amitiés d''enfance, pas leur supériorité. B érige le **cas particulier** de l''auditeur d''Angers en loi générale — confusion entre l''exemple introductif et le propos. C reprend l''objection rapportée (« certains trouvent cela calculé ») que le chroniqueur réfute aussitôt : « je crois exactement l''inverse » — piège B2 classique de la **concession suivie d''une réfutation**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour à tous, Fatou Ndiaye au micro pour ma chronique familiale du samedi. Samedi dernier, ma nièce de huit ans m''a lancé la phrase que tous les parents redoutent : je m''ennuie. Et j''ai observé autour de moi la panique habituelle : on lui a proposé un dessin animé, un atelier de pâtisserie, une sortie au parc, le tout en moins de trois minutes. Voilà ce qui m''inquiète. Nous traitons l''ennui de nos enfants comme une panne qu''il faudrait réparer d''urgence. Or, souvenez-vous de vos propres étés : c''est dans les après-midis vides que nous inventions des cabanes, des langues secrètes, des spectacles entiers. L''ennui n''est pas le contraire de l''activité, il en est la source. Un enfant qui ne s''ennuie jamais apprend seulement à consommer des occupations préparées par d''autres. Alors je ne vous demande pas de supprimer les activités, ni de culpabiliser. Je vous propose un geste minuscule : la prochaine fois, attendez. Laissez le vide faire son travail.

Quelle est l''intention de la chroniqueuse ?

A. Inviter les parents à ne pas combler systématiquement l''ennui de leurs enfants.
B. Reprocher aux enfants d''aujourd''hui leur manque d''imagination.
C. Conseiller des activités créatives comme la pâtisserie ou le dessin.
D. Faire culpabiliser les parents qui occupent trop leurs enfants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour à tous, Fatou Ndiaye au micro pour ma chronique familiale du samedi. Samedi dernier, ma nièce de huit ans m''a lancé la phrase que tous les parents redoutent : je m''ennuie. Et j''ai observé autour de moi la panique habituelle : on lui a proposé un dessin animé, un atelier de pâtisserie, une sortie au parc, le tout en moins de trois minutes. Voilà ce qui m''inquiète. Nous traitons l''ennui de nos enfants comme une panne qu''il faudrait réparer d''urgence. Or, souvenez-vous de vos propres étés : c''est dans les après-midis vides que nous inventions des cabanes, des langues secrètes, des spectacles entiers. L''ennui n''est pas le contraire de l''activité, il en est la source. Un enfant qui ne s''ennuie jamais apprend seulement à consommer des occupations préparées par d''autres. Alors je ne vous demande pas de supprimer les activités, ni de culpabiliser. Je vous propose un geste minuscule : la prochaine fois, attendez. Laissez le vide faire son travail.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''intention de la chroniqueuse ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Inviter les parents à ne pas combler systématiquement l''ennui de leurs enfants.<break time="700ms"/>B.<break time="300ms"/>Reprocher aux enfants d''aujourd''hui leur manque d''imagination.<break time="700ms"/>C.<break time="300ms"/>Conseiller des activités créatives comme la pâtisserie ou le dessin.<break time="700ms"/>D.<break time="300ms"/>Faire culpabiliser les parents qui occupent trop leurs enfants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Fatou critique la « panique habituelle » des adultes qui traitent l''ennui « comme une panne qu''il faudrait réparer d''urgence » et conclut par un conseil : « attendez. Laissez le vide faire son travail ». Son **intention** est donc d''inviter les parents à laisser l''ennui exister — A ; mécanisme B2 d''inférence d''intention à partir de la chute. B inverse les acteurs : elle ne reproche rien aux enfants, dont l''imagination naît justement du vide ; ce sont les adultes qu''elle interpelle. C est un contresens : dessin animé et pâtisserie illustrent précisément le réflexe qu''elle met en cause. D est explicitement écartée (« je ne vous demande pas… de culpabiliser ») — **précaution oratoire** à repérer.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir, ici Wei Chen pour ma chronique du vendredi. Cet été, au sommet d''un col pyrénéen, j''ai vu une randonneuse photographier le lever du soleil, puis passer vingt minutes, dos au paysage, à choisir un filtre et rédiger une légende. Facile de se moquer, n''est-ce pas ? Trop facile, justement. Car le procès qu''on fait aux photos me semble mal instruit. Photographier n''abîme rien : cadrer un paysage, c''est déjà le regarder avec attention, et nos grands-parents mitraillaient bien leurs vacances avec leurs petits appareils. Non, le poison est ailleurs : c''est la publication immédiate. Au moment où je partage, je quitte le col pour rejoindre mon public ; je guette les réactions, je compare, je corrige. L''expérience continue sans moi. Alors je me suis fixé une règle, que je vous confie : photographiez tant que vous voulez, mais publiez le soir, ou la semaine suivante. Le paysage mérite votre présence ; vos abonnés, eux, peuvent attendre.

Quel est le point de vue du chroniqueur ?

A. Il faut renoncer à photographier ses voyages pour en profiter pleinement.
B. Les réseaux sociaux permettent de prolonger agréablement les souvenirs de vacances.
C. Ce n''est pas la photo qui gâche le moment, c''est le partage immédiat.
D. Les appareils photo d''autrefois prenaient de meilleures images que les téléphones.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir, ici Wei Chen pour ma chronique du vendredi. Cet été, au sommet d''un col pyrénéen, j''ai vu une randonneuse photographier le lever du soleil, puis passer vingt minutes, dos au paysage, à choisir un filtre et rédiger une légende. Facile de se moquer, n''est-ce pas ? Trop facile, justement. Car le procès qu''on fait aux photos me semble mal instruit. Photographier n''abîme rien : cadrer un paysage, c''est déjà le regarder avec attention, et nos grands-parents mitraillaient bien leurs vacances avec leurs petits appareils. Non, le poison est ailleurs : c''est la publication immédiate. Au moment où je partage, je quitte le col pour rejoindre mon public ; je guette les réactions, je compare, je corrige. L''expérience continue sans moi. Alors je me suis fixé une règle, que je vous confie : photographiez tant que vous voulez, mais publiez le soir, ou la semaine suivante. Le paysage mérite votre présence ; vos abonnés, eux, peuvent attendre.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quel est le point de vue du chroniqueur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il faut renoncer à photographier ses voyages pour en profiter pleinement.<break time="700ms"/>B.<break time="300ms"/>Les réseaux sociaux permettent de prolonger agréablement les souvenirs de vacances.<break time="700ms"/>C.<break time="300ms"/>Ce n''est pas la photo qui gâche le moment, c''est le partage immédiat.<break time="700ms"/>D.<break time="300ms"/>Les appareils photo d''autrefois prenaient de meilleures images que les téléphones.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Wei distingue deux gestes : photographier, qu''il défend (« cadrer un paysage, c''est déjà le regarder avec attention »), et publier sur-le-champ (« le poison est ailleurs : c''est la publication immédiate »). C restitue cette **distinction entre l''acte et son partage instantané** — mécanisme B2 de repérage du déplacement argumentatif (« facile de se moquer… trop facile, justement »). A reprend le « procès » qu''il juge « mal instruit » : il invite au contraire à photographier « tant que vous voulez ». B est un contresens : publier immédiatement lui fait « quitter le col », l''expérience « continue sans » lui — le partage interrompt le moment, il ne le prolonge pas. D détourne un **détail concessif** (les grands-parents et leurs petits appareils) en comparaison technique jamais faite.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Bonjour, Priya Sharma, pour ma chronique du lundi. Hier soir, j''ai hésité dix minutes devant deux restaurants de ma rue : l''un affichait quatre virgule six étoiles, l''autre quatre virgule deux. J''ai choisi le premier, évidemment. Il était quelconque. Et en rentrant, je me suis demandé à quel moment j''avais cessé de faire confiance à mon propre jugement. Comprenez-moi bien : je ne dis pas que les avis mentent, ni qu''il faudrait fermer ces plateformes, qui rendent parfois service. Ce qui me dérange, c''est la note elle-même. Un dîner, c''est une lumière, un serveur fatigué ou charmant, une conversation : comment résumer tout cela par un chiffre ? À force de noter les restaurants, les médecins, les chauffeurs et même les plombiers, nous déléguons nos choix à une moyenne calculée par des inconnus. Je propose un exercice modeste : la prochaine fois, poussez la porte du restaurant à quatre virgule deux. Vous découvrirez peut-être que votre palais vaut mieux qu''un classement.

Que reproche la chroniqueuse aux notes en ligne ?

A. Elles sont rédigées par de faux clients payés par les restaurants.
B. Elles réduisent des expériences complexes à un chiffre et affaiblissent le jugement personnel.
C. Elles devraient être interdites parce qu''elles ne rendent aucun service.
D. Elles favorisent injustement les restaurants les plus chers.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Bonjour, Priya Sharma, pour ma chronique du lundi. Hier soir, j''ai hésité dix minutes devant deux restaurants de ma rue : l''un affichait quatre virgule six étoiles, l''autre quatre virgule deux. J''ai choisi le premier, évidemment. Il était quelconque. Et en rentrant, je me suis demandé à quel moment j''avais cessé de faire confiance à mon propre jugement. Comprenez-moi bien : je ne dis pas que les avis mentent, ni qu''il faudrait fermer ces plateformes, qui rendent parfois service. Ce qui me dérange, c''est la note elle-même. Un dîner, c''est une lumière, un serveur fatigué ou charmant, une conversation : comment résumer tout cela par un chiffre ? À force de noter les restaurants, les médecins, les chauffeurs et même les plombiers, nous déléguons nos choix à une moyenne calculée par des inconnus. Je propose un exercice modeste : la prochaine fois, poussez la porte du restaurant à quatre virgule deux. Vous découvrirez peut-être que votre palais vaut mieux qu''un classement.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que reproche la chroniqueuse aux notes en ligne ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elles sont rédigées par de faux clients payés par les restaurants.<break time="700ms"/>B.<break time="300ms"/>Elles réduisent des expériences complexes à un chiffre et affaiblissent le jugement personnel.<break time="700ms"/>C.<break time="300ms"/>Elles devraient être interdites parce qu''elles ne rendent aucun service.<break time="700ms"/>D.<break time="300ms"/>Elles favorisent injustement les restaurants les plus chers.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Priya cible « la note elle-même » : « comment résumer tout cela par un chiffre ? », « nous déléguons nos choix à une moyenne calculée par des inconnus » — et son anecdote illustre un jugement personnel atrophié (« à quel moment j''avais cessé de faire confiance à mon propre jugement »). B condense ce **double reproche : réduction chiffrée + perte de jugement** ; mécanisme B2 de synthèse de l''idée principale. A contredit sa précaution explicite « je ne dis pas que les avis mentent » — aucune fraude payée n''est évoquée. C force le trait : elle refuse de « fermer ces plateformes, qui rendent parfois service » — piège sur la **concession**. D invente un biais en faveur des restaurants chers : son exemple oppose deux notes, jamais deux prix.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonsoir à tous, Rachid Meziane pour ma chronique du jeudi. Ce matin, à la boulangerie de mon quartier de Tours, la nouvelle borne de commande m''a fait gagner, montre en main, quatre minutes. Quatre minutes, et une perte que personne ne mesure. Avec la boulangère, je parlais de la pluie, du prix de la farine, de rien. Des conversations minuscules, je vous l''accorde, et certains les jugent hypocrites : pourquoi commenter la météo avec des inconnus ? Voici pourquoi. Ces échanges sans enjeu sont des exercices d''attention à l''autre. C''est par eux qu''un visage devient familier, qu''un quartier devient un village, qu''une vieille dame sait qu''on remarquera son absence. Les grandes solidarités ne naissent pas dans les grandes déclarations : elles germent dans dix ans de bonjours échangés. Je ne condamne pas les bornes, qui dépannent les gens pressés. Je dis seulement : de temps en temps, choisissez la file d''attente. On y perd quatre minutes, on y gagne des voisins.

Quelle est l''idée principale de cette chronique ?

A. Les bornes de commande devraient être retirées des commerces.
B. Parler de la météo avec des inconnus est une habitude hypocrite.
C. Les commerces de quartier font gagner du temps à leurs clients.
D. Les petites conversations du quotidien construisent, à long terme, le lien social d''un quartier.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonsoir à tous, Rachid Meziane pour ma chronique du jeudi. Ce matin, à la boulangerie de mon quartier de Tours, la nouvelle borne de commande m''a fait gagner, montre en main, quatre minutes. Quatre minutes, et une perte que personne ne mesure. Avec la boulangère, je parlais de la pluie, du prix de la farine, de rien. Des conversations minuscules, je vous l''accorde, et certains les jugent hypocrites : pourquoi commenter la météo avec des inconnus ? Voici pourquoi. Ces échanges sans enjeu sont des exercices d''attention à l''autre. C''est par eux qu''un visage devient familier, qu''un quartier devient un village, qu''une vieille dame sait qu''on remarquera son absence. Les grandes solidarités ne naissent pas dans les grandes déclarations : elles germent dans dix ans de bonjours échangés. Je ne condamne pas les bornes, qui dépannent les gens pressés. Je dis seulement : de temps en temps, choisissez la file d''attente. On y perd quatre minutes, on y gagne des voisins.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale de cette chronique ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les bornes de commande devraient être retirées des commerces.<break time="700ms"/>B.<break time="300ms"/>Parler de la météo avec des inconnus est une habitude hypocrite.<break time="700ms"/>C.<break time="300ms"/>Les commerces de quartier font gagner du temps à leurs clients.<break time="700ms"/>D.<break time="300ms"/>Les petites conversations du quotidien construisent, à long terme, le lien social d''un quartier.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Tout converge vers la formule finale « on y perd quatre minutes, on y gagne des voisins » et vers « les grandes solidarités… germent dans dix ans de bonjours échangés » : D dégage cette **idée principale** — les micro-conversations fabriquent du lien durable ; mécanisme B2 de distinction entre thème (la borne) et propos (le lien social). A force la position du chroniqueur : « je ne condamne pas les bornes, qui dépannent les gens pressés ». B reprend l''objection des sceptiques (« certains les jugent hypocrites ») que Rachid réfute ensuite point par point. C s''arrête au **détail introductif** (les quatre minutes gagnées) et passe à côté du propos, qui valorise précisément ce temps « perdu ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c005-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Bonjour, Amadou Traoré pour ma chronique dominicale. On me demande souvent pourquoi je traverse Strasbourg à pied chaque matin, alors que le tramway passe au bas de mon immeuble. Et chaque fois, mes interlocuteurs devancent ma réponse : c''est pour la planète, ou alors pour la ligne. Eh bien non, désolé de les décevoir : je ne marche ni par vertu ni par régime. Je marche parce que c''est le dernier moment de ma journée où personne ne peut rien me demander. Quarante minutes sans écran, sans réunion, sans sollicitation. C''est en marchant que mes problèmes de la veille se dénouent tout seuls, que les phrases de mes chroniques se mettent en place. Les philosophes grecs enseignaient en se promenant ; ils avaient compris quelque chose que nos agendas ont oublié : le corps qui avance aide l''esprit à avancer. Alors si vous croisez un marcheur au regard absent, ne le plaignez pas d''avoir raté son tramway. Il est peut-être en plein travail.

Que veut montrer le chroniqueur ?

A. La marche est avant tout, pour lui, un espace de réflexion préservé des sollicitations.
B. Marcher permet de réduire son impact sur la planète.
C. La marche reste le meilleur moyen de garder la forme.
D. Les transports en commun sont trop souvent en retard.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Bonjour, Amadou Traoré pour ma chronique dominicale. On me demande souvent pourquoi je traverse Strasbourg à pied chaque matin, alors que le tramway passe au bas de mon immeuble. Et chaque fois, mes interlocuteurs devancent ma réponse : c''est pour la planète, ou alors pour la ligne. Eh bien non, désolé de les décevoir : je ne marche ni par vertu ni par régime. Je marche parce que c''est le dernier moment de ma journée où personne ne peut rien me demander. Quarante minutes sans écran, sans réunion, sans sollicitation. C''est en marchant que mes problèmes de la veille se dénouent tout seuls, que les phrases de mes chroniques se mettent en place. Les philosophes grecs enseignaient en se promenant ; ils avaient compris quelque chose que nos agendas ont oublié : le corps qui avance aide l''esprit à avancer. Alors si vous croisez un marcheur au regard absent, ne le plaignez pas d''avoir raté son tramway. Il est peut-être en plein travail.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que veut montrer le chroniqueur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La marche est avant tout, pour lui, un espace de réflexion préservé des sollicitations.<break time="700ms"/>B.<break time="300ms"/>Marcher permet de réduire son impact sur la planète.<break time="700ms"/>C.<break time="300ms"/>La marche reste le meilleur moyen de garder la forme.<break time="700ms"/>D.<break time="300ms"/>Les transports en commun sont trop souvent en retard.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Amadou écarte lui-même les deux motifs attendus (« je ne marche ni par vertu ni par régime ») et définit la marche comme « le dernier moment… où personne ne peut rien me demander », où « les phrases… se mettent en place » : A reformule ce **temps de pensée à l''abri des sollicitations** — mécanisme B2 d''inférence du point de vue après une double réfutation. B reprend le motif écologique (« pour la planète ») qu''il refuse explicitement. C reprend le motif de la forme physique (« pour la ligne »), écarté de la même façon. D tire une **inférence abusive** de la chute (« raté son tramway ») : le tramway passe au bas de chez lui et il choisit de ne pas le prendre ; aucune critique des transports n''est formulée.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c005-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), chronique parlée longue :
--     longueurs comptées = 157 / 149 / 156 / 151 / 156 / 157 / 160 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « chronique & point de vue », 7 chroniques inventées toutes
--     différentes : écriture manuscrite vs clavier (Olena), amitié à l''âge
--     adulte (Diego, Angers), éloge de l''ennui des enfants (Fatou), photo vs
--     publication immédiate (Wei, Pyrénées), tyrannie des notes en ligne
--     (Priya), micro-conversations de quartier (Rachid, Tours), marche comme
--     temps de pensée (Amadou, Strasbourg). Aucun thème interdit du bon de
--     commande (pas d''organisme, pas de débat, pas d''enjeu éco/environnement,
--     pas de conseil d''expert, etc.).
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     B, D, A, C, B, D, A — A ×2, B ×2, C ×1, D ×2 (max 2 par lettre,
--     4 lettres utilisées).
-- [x] Compréhension implicite B2 : thèse défendue, intention de la
--     chroniqueuse, point de vue derrière la concession, idée principale ;
--     distracteurs tous plausibles (thème vs propos, détail secondaire vs idée
--     principale, concession réfutée prise pour la thèse, inférence abusive).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé
--     (concession/réfutation, inférence d''intention, thème vs propos).
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise (0.95) pour
--     intro/question/propositions, Henri/Vivienne (1.0) pour le document,
--     voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
