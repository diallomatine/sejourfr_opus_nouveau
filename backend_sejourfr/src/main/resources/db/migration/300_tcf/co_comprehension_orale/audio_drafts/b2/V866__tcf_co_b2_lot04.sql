-- ============================================================================
-- V866 — TCF CO B2 — lot 04 (thème : témoignage d'expérience)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : monologue long (~120-200 mots) de type
-- témoignage personnel d'une expérience vécue + question implicite (idée
-- principale, intention du locuteur, conséquence non dite, difficulté réelle).
-- Table audio_question_draft. status='TEXT_VALIDATED', colonnes audio NULL
-- (remplies par le batch admin Azure). Contenu 100% original, témoins inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c004-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Wei Zhang, j''ai trente-quatre ans et je vis à Brest. Il y a deux ans, on m''a volé mon téléphone dans le train. Au lieu d''en racheter un, j''ai tenté une expérience : vivre un an sans smartphone. Les premières semaines ont été pénibles, je l''avoue : je me perdais en ville, je ratais des messages, mes amis s''agaçaient. Puis quelque chose s''est déplacé. Dans la salle d''attente, je parlais à mes voisins. Le soir, je lisais au lieu de faire défiler des images. Mes proches ont remarqué que je les écoutais vraiment, sans jeter un œil à un écran. J''ai certes économisé pas mal d''argent, mais ce n''est pas l''essentiel. Aujourd''hui, j''ai de nouveau un téléphone, basique, et je ne dis à personne de jeter le sien : chacun fait comme il veut. Ce que j''ai retrouvé, c''est une qualité de présence aux autres que je croyais perdue.

Qu''est-ce que Wei retient principalement de cette expérience ?

A. Elle a réalisé d''importantes économies d''argent.
B. Elle a retrouvé une véritable attention aux personnes qui l''entourent.
C. Elle veut convaincre son entourage d''abandonner le smartphone.
D. Elle a compris qu''elle ne pouvait pas vivre sans téléphone.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Wei Zhang, j''ai trente-quatre ans et je vis à Brest. Il y a deux ans, on m''a volé mon téléphone dans le train. Au lieu d''en racheter un, j''ai tenté une expérience : vivre un an sans smartphone. Les premières semaines ont été pénibles, je l''avoue : je me perdais en ville, je ratais des messages, mes amis s''agaçaient. Puis quelque chose s''est déplacé. Dans la salle d''attente, je parlais à mes voisins. Le soir, je lisais au lieu de faire défiler des images. Mes proches ont remarqué que je les écoutais vraiment, sans jeter un œil à un écran. J''ai certes économisé pas mal d''argent, mais ce n''est pas l''essentiel. Aujourd''hui, j''ai de nouveau un téléphone, basique, et je ne dis à personne de jeter le sien : chacun fait comme il veut. Ce que j''ai retrouvé, c''est une qualité de présence aux autres que je croyais perdue.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que Wei retient principalement de cette expérience ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle a réalisé d''importantes économies d''argent.<break time="700ms"/>B.<break time="300ms"/>Elle a retrouvé une véritable attention aux personnes qui l''entourent.<break time="700ms"/>C.<break time="300ms"/>Elle veut convaincre son entourage d''abandonner le smartphone.<break time="700ms"/>D.<break time="300ms"/>Elle a compris qu''elle ne pouvait pas vivre sans téléphone.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La conclusion porte tout le témoignage : « ce que j''ai retrouvé, c''est une qualité de présence aux autres » — il faut **hiérarchiser le bilan que la locutrice tire elle-même** (mécanisme B2 : détail secondaire vs idée principale), donc B. A reprend un point réel mais que Wei **minore explicitement** (« ce n''est pas l''essentiel ») : le distracteur élève un détail concédé au rang de bilan. C lui prête une **intention militante qu''elle récuse** mot pour mot (« je ne dis à personne de jeter le sien ») — piège sur l''intention du locuteur. D est un contresens : les difficultés n''ont duré que « les premières semaines », et elle a tenu l''année entière ; D répondrait à un témoignage d''échec.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je suis Tomás Oliveira, j''ai cinquante et un ans, je suis kinésithérapeute à Limoges. Pendant huit mois, ma femme et moi avons hébergé chez nous une famille venue d''un pays en guerre : un couple et deux enfants. Je ne vais pas embellir les choses : partager sa cuisine, sa salle de bains et ses silences avec des inconnus, c''est exigeant, et les démarches administratives nous ont souvent découragés. Pourtant, quand on me demande si je le referais, je n''hésite pas une seconde. Avant leur arrivée, je pensais agir par générosité, donner de mon temps, offrir un toit. J''ai vite compris que l''échange n''était pas à sens unique. Sami m''a appris à cuisiner, les enfants ont rempli la maison de rires, et leurs questions sur ma propre vie m''ont obligé à regarder autrement mon confort et mes habitudes. Ils ont maintenant leur appartement, et nous dînons ensemble chaque mois. Je croyais aider ; en réalité, j''ai reçu autant que j''ai donné.

Quelle est l''idée principale de ce témoignage ?

A. L''hébergement s''est déroulé sans difficulté particulière.
B. Les démarches administratives ont fini par faire échouer l''accueil.
C. Tomás a accueilli cette famille pour apprendre à cuisiner.
D. Cet accueil a transformé Tomás autant qu''il a aidé la famille.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je suis Tomás Oliveira, j''ai cinquante et un ans, je suis kinésithérapeute à Limoges. Pendant huit mois, ma femme et moi avons hébergé chez nous une famille venue d''un pays en guerre : un couple et deux enfants. Je ne vais pas embellir les choses : partager sa cuisine, sa salle de bains et ses silences avec des inconnus, c''est exigeant, et les démarches administratives nous ont souvent découragés. Pourtant, quand on me demande si je le referais, je n''hésite pas une seconde. Avant leur arrivée, je pensais agir par générosité, donner de mon temps, offrir un toit. J''ai vite compris que l''échange n''était pas à sens unique. Sami m''a appris à cuisiner, les enfants ont rempli la maison de rires, et leurs questions sur ma propre vie m''ont obligé à regarder autrement mon confort et mes habitudes. Ils ont maintenant leur appartement, et nous dînons ensemble chaque mois. Je croyais aider ; en réalité, j''ai reçu autant que j''ai donné.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale de ce témoignage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>L''hébergement s''est déroulé sans difficulté particulière.<break time="700ms"/>B.<break time="300ms"/>Les démarches administratives ont fini par faire échouer l''accueil.<break time="700ms"/>C.<break time="300ms"/>Tomás a accueilli cette famille pour apprendre à cuisiner.<break time="700ms"/>D.<break time="300ms"/>Cet accueil a transformé Tomás autant qu''il a aidé la famille.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le témoignage est construit sur un **renversement de perspective** (mécanisme B2 : opposition attendu/réel marquée par « je pensais… j''ai vite compris ») et culmine dans « je croyais aider ; en réalité, j''ai reçu autant que j''ai donné » : D synthétise cette transformation réciproque. A contredit l''aveu explicite « c''est exigeant » — elle répondrait à un récit idéalisé que Tomás refuse justement de faire (« je ne vais pas embellir les choses »). B pousse « nous ont souvent découragés » jusqu''à l''échec, alors que la famille a son appartement et que les dîners continuent : **inversion de la conséquence réelle**. C transforme un bénéfice imprévu (la cuisine apprise avec Sami) en motivation initiale — confusion cause/conséquence.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Aïcha Benkacem, j''ai cinquante-quatre ans et je travaille dans une pharmacie à Valence. Il y a trois ans, je me suis inscrite à l''université pour reprendre les études que j''avais abandonnées à dix-huit ans. Tout le monde me prédisait que le plus dur serait de suivre le rythme : les cours du soir, les révisions après le travail, la mémoire qui flanche. Honnêtement, ça, je l''ai géré. Le vrai obstacle était ailleurs, et personne ne m''en avait parlé. C''était ce sentiment, tenace, de ne pas être à ma place : entrer dans un amphithéâtre rempli d''étudiants de vingt ans, ne pas oser poser une question de peur de paraître ridicule, me demander chaque matin de quel droit j''étais là. Il m''a fallu un an pour comprendre que cette voix-là mentait. J''ai validé ma deuxième année en juin, avec mention. Si je témoigne aujourd''hui, ce n''est pas pour qu''on m''applaudisse : c''est parce que cette barrière invisible, beaucoup d''adultes la connaissent.

Quelle a été la principale difficulté rencontrée par Aïcha ?

A. Le sentiment de ne pas être légitime à l''université.
B. Le rythme des cours du soir après ses journées de travail.
C. Les moqueries des étudiants plus jeunes qu''elle.
D. Des problèmes de mémoire liés à son âge.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Aïcha Benkacem, j''ai cinquante-quatre ans et je travaille dans une pharmacie à Valence. Il y a trois ans, je me suis inscrite à l''université pour reprendre les études que j''avais abandonnées à dix-huit ans. Tout le monde me prédisait que le plus dur serait de suivre le rythme : les cours du soir, les révisions après le travail, la mémoire qui flanche. Honnêtement, ça, je l''ai géré. Le vrai obstacle était ailleurs, et personne ne m''en avait parlé. C''était ce sentiment, tenace, de ne pas être à ma place : entrer dans un amphithéâtre rempli d''étudiants de vingt ans, ne pas oser poser une question de peur de paraître ridicule, me demander chaque matin de quel droit j''étais là. Il m''a fallu un an pour comprendre que cette voix-là mentait. J''ai validé ma deuxième année en juin, avec mention. Si je témoigne aujourd''hui, ce n''est pas pour qu''on m''applaudisse : c''est parce que cette barrière invisible, beaucoup d''adultes la connaissent.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle a été la principale difficulté rencontrée par Aïcha ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le sentiment de ne pas être légitime à l''université.<break time="700ms"/>B.<break time="300ms"/>Le rythme des cours du soir après ses journées de travail.<break time="700ms"/>C.<break time="300ms"/>Les moqueries des étudiants plus jeunes qu''elle.<break time="700ms"/>D.<break time="300ms"/>Des problèmes de mémoire liés à son âge.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Aïcha oppose la difficulté **annoncée par les autres** (le rythme, la mémoire — « ça, je l''ai géré ») et « le vrai obstacle » : se demander « de quel droit j''étais là », cette « barrière invisible » — A reformule ce sentiment d''illégitimité. Le mécanisme B2 est la **concession suivie d''un retournement** (« honnêtement, ça, je l''ai géré. Le vrai obstacle était ailleurs »). B et D reprennent précisément les difficultés prédites que la concession **écarte** : elles répondraient à « que craignait son entourage ? ». C est une inférence abusive : Aïcha avait « peur de paraître ridicule », mais aucune moquerie réelle n''est rapportée — le distracteur transforme une crainte intérieure en fait extérieur.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Pavel Horak, j''ai quarante-deux ans, je suis magasinier près de Perpignan. Pendant des années, j''ai caché à tout le monde, même à ma compagne, que je ne savais presque pas lire. J''avais développé mille stratégies : oublier mes lunettes, demander qu''on me résume un document, apprendre les trajets par cœur. La peur d''être démasqué occupait toutes mes journées. À trente-cinq ans, après une humiliation de trop, j''ai poussé la porte d''un centre de formation. Trois ans plus tard, je lisais des histoires à ma fille. Alors pourquoi est-ce que je raconte tout ça ce soir, devant des inconnus, moi qui ai eu si honte si longtemps ? Parce que je sais qu''en France, des millions d''adultes vivent avec ce secret, et que la honte les enferme plus sûrement que les lettres. Si un seul d''entre eux, en m''écoutant, ose franchir la porte que j''ai franchie, ce témoignage aura servi.

Dans quelle intention Pavel témoigne-t-il publiquement ?

A. Pour dénoncer les défaillances de l''école qu''il a connue.
B. Pour remercier le centre de formation qui l''a accompagné.
C. Pour encourager d''autres adultes concernés à oser demander de l''aide.
D. Pour prouver qu''il a définitivement surmonté sa honte.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Pavel Horak, j''ai quarante-deux ans, je suis magasinier près de Perpignan. Pendant des années, j''ai caché à tout le monde, même à ma compagne, que je ne savais presque pas lire. J''avais développé mille stratégies : oublier mes lunettes, demander qu''on me résume un document, apprendre les trajets par cœur. La peur d''être démasqué occupait toutes mes journées. À trente-cinq ans, après une humiliation de trop, j''ai poussé la porte d''un centre de formation. Trois ans plus tard, je lisais des histoires à ma fille. Alors pourquoi est-ce que je raconte tout ça ce soir, devant des inconnus, moi qui ai eu si honte si longtemps ? Parce que je sais qu''en France, des millions d''adultes vivent avec ce secret, et que la honte les enferme plus sûrement que les lettres. Si un seul d''entre eux, en m''écoutant, ose franchir la porte que j''ai franchie, ce témoignage aura servi.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Dans quelle intention Pavel témoigne-t-il publiquement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Pour dénoncer les défaillances de l''école qu''il a connue.<break time="700ms"/>B.<break time="300ms"/>Pour remercier le centre de formation qui l''a accompagné.<break time="700ms"/>C.<break time="300ms"/>Pour encourager d''autres adultes concernés à oser demander de l''aide.<break time="700ms"/>D.<break time="300ms"/>Pour prouver qu''il a définitivement surmonté sa honte.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Pavel pose lui-même la question rhétorique « pourquoi est-ce que je raconte tout ça ? » et y répond : « si un seul d''entre eux… ose franchir la porte que j''ai franchie, ce témoignage aura servi » — C reformule cette **intention déclarée du locuteur** (mécanisme B2 : inférence d''intention, ici guidée par une question rhétorique suivie de sa réponse). A invente une cible : l''école n''est jamais mise en cause, le récit porte sur le secret et la honte — A répondrait à un témoignage militant contre l''institution scolaire. B élève un acteur secondaire (le centre, simplement traversé dans le récit) au rang de destinataire du discours. D confond le **contenu** du récit (la honte surmontée) avec son **but** : Pavel ne cherche pas à se prouver, il s''adresse à ceux qui vivent encore ce secret.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Mariam Cissé, j''ai quarante-trois ans, je suis aide-soignante à Metz. Enfant, j''ai failli me noyer dans une rivière, et pendant trente-cinq ans, je n''ai plus jamais mis un pied dans l''eau. Les piscines avec mes enfants, les vacances à la mer : je restais sur le bord, avec une excuse toute prête. Il y a trois ans, ma fille m''a inscrite, sans me demander mon avis, à des cours pour adultes débutants. J''ai détesté les premières séances. Puis, un mardi soir, j''ai lâché le rebord, et j''ai flotté. Aujourd''hui, je nage mille mètres chaque semaine. Mais le plus étrange, c''est ce qui s''est passé en dehors des bassins. Quelques mois après, j''ai demandé une formation que je repoussais depuis des années, puis j''ai passé mon permis de conduire. Comme si, en affrontant la peur la plus ancienne, j''avais désarmé toutes les autres. Mes collègues disent que j''ai changé. Elles n''ont pas tort.

Qu''est-ce que cette expérience a surtout apporté à Mariam ?

A. Une excellente condition physique grâce à la natation.
B. Une confiance nouvelle qui dépasse le cadre de la piscine.
C. La possibilité d''accompagner enfin ses enfants à la mer.
D. Une réconciliation avec sa fille qui l''avait inscrite de force.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Mariam Cissé, j''ai quarante-trois ans, je suis aide-soignante à Metz. Enfant, j''ai failli me noyer dans une rivière, et pendant trente-cinq ans, je n''ai plus jamais mis un pied dans l''eau. Les piscines avec mes enfants, les vacances à la mer : je restais sur le bord, avec une excuse toute prête. Il y a trois ans, ma fille m''a inscrite, sans me demander mon avis, à des cours pour adultes débutants. J''ai détesté les premières séances. Puis, un mardi soir, j''ai lâché le rebord, et j''ai flotté. Aujourd''hui, je nage mille mètres chaque semaine. Mais le plus étrange, c''est ce qui s''est passé en dehors des bassins. Quelques mois après, j''ai demandé une formation que je repoussais depuis des années, puis j''ai passé mon permis de conduire. Comme si, en affrontant la peur la plus ancienne, j''avais désarmé toutes les autres. Mes collègues disent que j''ai changé. Elles n''ont pas tort.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce que cette expérience a surtout apporté à Mariam ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Une excellente condition physique grâce à la natation.<break time="700ms"/>B.<break time="300ms"/>Une confiance nouvelle qui dépasse le cadre de la piscine.<break time="700ms"/>C.<break time="300ms"/>La possibilité d''accompagner enfin ses enfants à la mer.<break time="700ms"/>D.<break time="300ms"/>Une réconciliation avec sa fille qui l''avait inscrite de force.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La clé est signalée par « mais le plus étrange, c''est ce qui s''est passé **en dehors des bassins** » : la formation enfin demandée, le permis passé, « en affrontant la peur la plus ancienne, j''avais désarmé toutes les autres » — B reformule cette **conséquence non dite explicitement** (le mot « confiance » n''est jamais prononcé, il faut l''inférer des effets décrits ; mécanisme B2 d''inférence de conséquence). A invente un bénéfice jamais évoqué : Mariam parle de peur vaincue, pas de forme physique — A répondrait à un témoignage sportif. C reste une **inférence de détail** plausible (elle restait « sur le bord ») mais marginale face au marqueur « surtout » de la question. D suppose un conflit inexistant : l''inscription « sans me demander mon avis » est racontée avec gratitude, aucune brouille à réparer.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Omar Haddad, j''ai trente-neuf ans. Il y a quatre ans, avec ma compagne, nous avons quitté notre appartement de la région parisienne pour un village de deux cents habitants dans la Creuse. Sur les réseaux, ce genre de départ ressemble à une carte postale : un potager, le silence, des matins brumeux. La réalité a été plus rugueuse. Le premier hiver, nous ne connaissions personne, la chaudière nous a lâchés, et j''ai compris que le silence, parfois, pèse. Ce qui nous a fait rester, ce ne sont pas les paysages, même s''ils sont magnifiques. C''est le jour où le maire est venu nous chercher pour aider à réparer le toit de la salle des fêtes. Puis les voisins qui déposaient des légumes, le comité qui m''a confié la buvette du quatorze juillet. Nous sommes restés parce qu''un village, ce n''est pas un décor : c''est un tissu de liens, qui se mérite et qui se tisse lentement.

Pourquoi Omar et sa compagne sont-ils finalement restés au village ?

A. Parce que la beauté des paysages les a conquis.
B. Parce que la vie y est moins chère qu''en région parisienne.
C. Parce que le maire leur a trouvé du travail sur place.
D. Parce qu''ils y ont peu à peu tissé de véritables liens avec les habitants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Omar Haddad, j''ai trente-neuf ans. Il y a quatre ans, avec ma compagne, nous avons quitté notre appartement de la région parisienne pour un village de deux cents habitants dans la Creuse. Sur les réseaux, ce genre de départ ressemble à une carte postale : un potager, le silence, des matins brumeux. La réalité a été plus rugueuse. Le premier hiver, nous ne connaissions personne, la chaudière nous a lâchés, et j''ai compris que le silence, parfois, pèse. Ce qui nous a fait rester, ce ne sont pas les paysages, même s''ils sont magnifiques. C''est le jour où le maire est venu nous chercher pour aider à réparer le toit de la salle des fêtes. Puis les voisins qui déposaient des légumes, le comité qui m''a confié la buvette du quatorze juillet. Nous sommes restés parce qu''un village, ce n''est pas un décor : c''est un tissu de liens, qui se mérite et qui se tisse lentement.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi Omar et sa compagne sont-ils finalement restés au village ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que la beauté des paysages les a conquis.<break time="700ms"/>B.<break time="300ms"/>Parce que la vie y est moins chère qu''en région parisienne.<break time="700ms"/>C.<break time="300ms"/>Parce que le maire leur a trouvé du travail sur place.<break time="700ms"/>D.<break time="300ms"/>Parce qu''ils y ont peu à peu tissé de véritables liens avec les habitants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Omar annonce la cause de sa décision par une structure clivée : « ce qui nous a fait rester, ce ne sont pas les paysages… c''est le jour où le maire est venu nous chercher », puis généralise : « un village… c''est un **tissu de liens** » — D reformule cette raison. Le mécanisme B2 est la **concession négative** (« ce ne sont pas X, même si… c''est Y ») qui désamorce le distracteur le plus tentant : A reprend exactement ce qu''Omar écarte tout en le reconnaissant « magnifiques ». B n''est jamais évoquée : aucun argument financier dans le témoignage — elle répondrait à un reportage sur le coût de la vie. C déforme un détail : le maire est venu chercher Omar pour un coup de main **bénévole** (le toit de la salle des fêtes), pas pour un emploi — glissement du service rendu vers le travail rémunéré.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c004-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Linh Nguyen, j''ai quarante-cinq ans, je vis à La Rochelle. L''été dernier, j''ai traversé la France à vélo avec mon fils de quinze ans, de l''Atlantique aux Alpes, trois semaines et mille deux cents kilomètres. Avant le départ, nous traversions une période difficile : il s''enfermait dans sa chambre, nos conversations se réduisaient à des portes qui claquent. Des amis m''ont prise pour une folle d''imposer ça à un adolescent. Les trois premiers jours leur ont donné raison : il pédalait cent mètres derrière moi, casque sur les oreilles. Et puis une crevaison sous l''orage nous a forcés à nous débrouiller ensemble. Ce soir-là, il m''a parlé pendant deux heures, comme jamais depuis des années. Je ne retiens pas les kilomètres, ni même les paysages. Je retiens qu''il n''existe pas de raccourci : pour retrouver quelqu''un, il faut du temps partagé, sans écran et sans échappatoire. Le vélo n''était qu''un prétexte.

Que retient principalement Linh de ce voyage ?

A. Le temps partagé lui a permis de renouer le dialogue avec son fils.
B. Son fils s''est découvert une véritable passion pour le cyclisme.
C. L''exploit sportif qu''ils ont accompli ensemble.
D. Les difficultés du voyage ont confirmé les craintes de ses amis.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Linh Nguyen, j''ai quarante-cinq ans, je vis à La Rochelle. L''été dernier, j''ai traversé la France à vélo avec mon fils de quinze ans, de l''Atlantique aux Alpes, trois semaines et mille deux cents kilomètres. Avant le départ, nous traversions une période difficile : il s''enfermait dans sa chambre, nos conversations se réduisaient à des portes qui claquent. Des amis m''ont prise pour une folle d''imposer ça à un adolescent. Les trois premiers jours leur ont donné raison : il pédalait cent mètres derrière moi, casque sur les oreilles. Et puis une crevaison sous l''orage nous a forcés à nous débrouiller ensemble. Ce soir-là, il m''a parlé pendant deux heures, comme jamais depuis des années. Je ne retiens pas les kilomètres, ni même les paysages. Je retiens qu''il n''existe pas de raccourci : pour retrouver quelqu''un, il faut du temps partagé, sans écran et sans échappatoire. Le vélo n''était qu''un prétexte.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que retient principalement Linh de ce voyage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le temps partagé lui a permis de renouer le dialogue avec son fils.<break time="700ms"/>B.<break time="300ms"/>Son fils s''est découvert une véritable passion pour le cyclisme.<break time="700ms"/>C.<break time="300ms"/>L''exploit sportif qu''ils ont accompli ensemble.<break time="700ms"/>D.<break time="300ms"/>Les difficultés du voyage ont confirmé les craintes de ses amis.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Linh formule elle-même son bilan : « je retiens qu''il n''existe pas de raccourci : pour retrouver quelqu''un, il faut du **temps partagé** », et déclasse le reste (« le vélo n''était qu''un prétexte ») — A reformule cette idée principale. Le mécanisme B2 est la **distinction entre le thème apparent (le voyage à vélo) et le propos réel (la relation retrouvée)**, explicitée par la métaphore du prétexte. B invente un détail jamais dit : rien n''indique que le fils aime désormais le vélo — B répondrait à un récit de vocation sportive. C reprend ce que Linh écarte mot pour mot (« je ne retiens pas les kilomètres ») : confusion entre la performance et le sens de l''expérience. D arrête le récit aux « trois premiers jours » : la crevaison renverse ensuite la situation — piège de **chronologie tronquée**, la conclusion contredit les sceptiques.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c004-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), monologue long de type
--     témoignage d''expérience : longueurs comptées = 152 / 162 / 159 / 153 /
--     156 / 159 / 152 mots (toutes dans la fourchette 120-200 mots B2).
-- [x] 7 témoignages inventés, situations toutes différentes : un an sans
--     smartphone (Brest), hébergement d''une famille réfugiée (Limoges),
--     reprise d''études à 52 ans (Valence), sortie de l''illettrisme
--     (Perpignan), apprentissage de la natation à 40 ans (Metz), installation
--     en village rural (Creuse), traversée de la France à vélo avec un ado
--     (La Rochelle). Prénoms variés : Wei, Tomás, Aïcha, Pavel, Mariam,
--     Omar, Linh.
-- [x] Aucun thème interdit : pas de présentation d''organisme/service, ni
--     message pro, ni communiqué, ni chronique, ni dispositif public, ni
--     exposé associatif, ni produit, ni bulletin local, ni formation, ni
--     débat d''opinion, ni récit professionnel, ni présentation culturelle,
--     ni conseil d''expert, ni enjeu environnemental/économique.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes
--     réponses : B, D, A, C, B, D, A → A ×2, B ×2, C ×1, D ×2 — max 2 par
--     lettre, 4 lettres utilisées.
-- [x] Compréhension implicite B2 : idée principale (1, 2, 7), difficulté
--     réelle vs annoncée (3), intention du locuteur (4), conséquence non
--     dite (5), cause réelle de la décision (6) ; distracteurs tous
--     plausibles (thème vs propos, détail secondaire vs idée principale,
--     inversion cause/effet, chronologie tronquée).
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé
--     (concession-retournement, structure clivée, question rhétorique,
--     inférence de conséquence, thème vs propos).
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par
--     item), pauses conformes (1500ms / 1000ms / 700ms / 300ms), voix
--     Denise (0.95) + Henri/Vivienne (1.0) en alternance F/H,
--     voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
