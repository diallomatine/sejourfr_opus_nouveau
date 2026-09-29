-- ============================================================================
-- V873 — TCF CO B2 — lot 11 (thème : opinion nuancée (débat))
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : interventions de débat (monologues
-- argumentatifs ou dialogues denses, ~120-200 mots), opinion nuancée du
-- locuteur + question implicite (position, intention, idée principale,
-- point d''accord). Table audio_question_draft. status='TEXT_VALIDATED',
-- colonnes audio NULL (remplies par le batch admin Azure). Contenu 100%
-- original, situations et locuteurs inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c00b-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Wei Lan, je suis professeure de mathématiques à Limoges et mère de deux collégiens, et je voudrais réagir aux interventions précédentes. On nous demande de choisir un camp : interdire totalement le téléphone au collège, ou laisser faire. Permettez-moi de refuser cette alternative. En classe, oui, l''interdiction me paraît indispensable : aucun adolescent ne résiste à une notification pendant un cours de géométrie, et les enseignants ne peuvent pas rivaliser avec un écran. Mais confisquer les appareils dès la grille du collège, comme certains le réclament ce soir, me semble une fausse victoire. D''abord parce que les élèves contournent déjà les casiers ; ensuite parce qu''on ne forme pas des citoyens numériques en faisant disparaître l''objet. Le téléphone reviendra à seize heures, avec les mêmes pièges. Je plaide donc pour une interdiction stricte en cours, assortie d''ateliers où l''on apprend à se servir de cet outil, plutôt que pour un bannissement spectaculaire et, je le crains, inefficace.

Quelle est la position de la locutrice ?

A. Elle souhaite laisser chaque élève libre d''utiliser son téléphone au collège.
B. Elle approuve l''interdiction en classe mais juge le bannissement total inefficace.
C. Elle réclame la confiscation des téléphones dès l''entrée de l''établissement.
D. Elle estime que l''éducation au numérique relève uniquement des familles.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Wei Lan, je suis professeure de mathématiques à Limoges et mère de deux collégiens, et je voudrais réagir aux interventions précédentes. On nous demande de choisir un camp : interdire totalement le téléphone au collège, ou laisser faire. Permettez-moi de refuser cette alternative. En classe, oui, l''interdiction me paraît indispensable : aucun adolescent ne résiste à une notification pendant un cours de géométrie, et les enseignants ne peuvent pas rivaliser avec un écran. Mais confisquer les appareils dès la grille du collège, comme certains le réclament ce soir, me semble une fausse victoire. D''abord parce que les élèves contournent déjà les casiers ; ensuite parce qu''on ne forme pas des citoyens numériques en faisant disparaître l''objet. Le téléphone reviendra à seize heures, avec les mêmes pièges. Je plaide donc pour une interdiction stricte en cours, assortie d''ateliers où l''on apprend à se servir de cet outil, plutôt que pour un bannissement spectaculaire et, je le crains, inefficace.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la position de la locutrice ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Elle souhaite laisser chaque élève libre d''utiliser son téléphone au collège.<break time="700ms"/>B.<break time="300ms"/>Elle approuve l''interdiction en classe mais juge le bannissement total inefficace.<break time="700ms"/>C.<break time="300ms"/>Elle réclame la confiscation des téléphones dès l''entrée de l''établissement.<break time="700ms"/>D.<break time="300ms"/>Elle estime que l''éducation au numérique relève uniquement des familles.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Wei refuse l''alternative binaire posée par le débat : « oui » à l''interdiction en classe (« indispensable »), « non » au bannissement total (« une fausse victoire », « inefficace »). Il faut **reconstruire une position nuancée à partir de deux mouvements opposés du discours** — mécanisme B2 typique. B restitue ce double mouvement. A ne retient que le refus du bannissement et gomme l''interdiction en cours qu''elle juge indispensable — lecture partielle. C lui attribue **la position de ses adversaires** (« comme certains le réclament ce soir »), piège d''attribution des opinions dans un débat. D invente une délégation aux familles jamais évoquée : elle propose au contraire des ateliers au collège.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00b-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Accorder le droit de vote à seize ans, Inès, ce n''est pas un caprice : à cet âge, on peut travailler, payer des cotisations, conduire accompagné. Décider de son avenir politique me paraît cohérent.
[Femme] Cohérent sur le papier, Bakary. Mais regardez l''abstention des jeunes majeurs : on n''élargit pas un droit que les premiers concernés n''exercent déjà pas. Sans préparation, on fabriquerait surtout des abstentionnistes plus précoces.
[Homme] L''argument se retourne : c''est justement parce qu''on vote pour la première fois loin du lycée, seul, sans accompagnement, que l''abstention explose. À seize ans, l''élève est encore en classe ; son premier vote pourrait s''apprendre, s''entourer, se discuter.
[Femme] Là-dessus, je vous rejoins volontiers : tant que l''éducation civique restera une heure sacrifiée en fin d''emploi du temps, votre débat sur l''âge restera secondaire. Commençons par former de vrais électeurs ; nous reparlerons ensuite du calendrier.

Sur quel point les deux interlocuteurs finissent-ils par s''accorder ?

A. La nécessité d''abaisser sans attendre l''âge du droit de vote.
B. L''inutilité de faire voter des jeunes qui s''abstiendront de toute façon.
C. Le fait que travailler à seize ans justifie de voter au même âge.
D. L''urgence de renforcer l''éducation civique avant de trancher le débat.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Accorder le droit de vote à seize ans, Inès, ce n''est pas un caprice : à cet âge, on peut travailler, payer des cotisations, conduire accompagné. Décider de son avenir politique me paraît cohérent.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Cohérent sur le papier, Bakary. Mais regardez l''abstention des jeunes majeurs : on n''élargit pas un droit que les premiers concernés n''exercent déjà pas. Sans préparation, on fabriquerait surtout des abstentionnistes plus précoces.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">L''argument se retourne : c''est justement parce qu''on vote pour la première fois loin du lycée, seul, sans accompagnement, que l''abstention explose. À seize ans, l''élève est encore en classe ; son premier vote pourrait s''apprendre, s''entourer, se discuter.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Là-dessus, je vous rejoins volontiers : tant que l''éducation civique restera une heure sacrifiée en fin d''emploi du temps, votre débat sur l''âge restera secondaire. Commençons par former de vrais électeurs ; nous reparlerons ensuite du calendrier.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Sur quel point les deux interlocuteurs finissent-ils par s''accorder ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>La nécessité d''abaisser sans attendre l''âge du droit de vote.<break time="700ms"/>B.<break time="300ms"/>L''inutilité de faire voter des jeunes qui s''abstiendront de toute façon.<break time="700ms"/>C.<break time="300ms"/>Le fait que travailler à seize ans justifie de voter au même âge.<break time="700ms"/>D.<break time="300ms"/>L''urgence de renforcer l''éducation civique avant de trancher le débat.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le point de convergence se construit dans les deux dernières répliques : Bakary affirme que « le premier vote pourrait s''apprendre » en classe, et Inès conclut « là-dessus, je vous rejoins volontiers… commençons par former de vrais électeurs ». Il faut **repérer le terrain d''entente au-delà du désaccord affiché** — pas une information littérale, mais une convergence à inférer. D la reformule. A reste la position de Bakary seul, qu''Inès renvoie explicitement à plus tard (« nous reparlerons ensuite du calendrier »). B durcit l''argument d''Inès en **conclusion qu''elle ne tire pas** : elle critique l''absence de préparation, pas le principe du vote des jeunes. C reprend un argument initial de Bakary jamais repris ni validé par Inès — détail d''ouverture, pas point d''accord final.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00b-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Marek Nowak, j''habite ce quartier depuis trente et un ans, et je veux apporter une voix un peu moins tranchée que celles qu''on entend depuis le début de ce débat. Non, les caméras ne sont pas l''arme absolue : les études qu''on nous a distribuées montrent qu''elles déplacent souvent les trafics deux rues plus loin, et personne, derrière un écran, n''a jamais consolé une victime. Mais elles ne sont pas non plus le gadget liberticide que dénoncent certains : sous le tunnel de la gare, là où aucune patrouille ne passe après vingt-deux heures, une caméra a permis d''identifier les auteurs de trois agressions l''an dernier. Ce que je conteste, ce n''est donc pas l''outil, c''est l''idée qu''il dispenserait d''embaucher des médiateurs et des îlotiers. Une caméra constate ; elle ne prévient rien. Installons-en aux points aveugles, d''accord, mais à condition de ne pas y consacrer l''argent qui manque déjà à la présence humaine.

Quelle est l''idée principale défendue par le locuteur ?

A. Les caméras sont inefficaces et doivent être retirées du quartier.
B. Les caméras peuvent compléter la présence humaine, jamais la remplacer.
C. La vidéosurveillance a fait disparaître la délinquance près de la gare.
D. Le quartier doit financer des caméras plutôt que des médiateurs.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Marek Nowak, j''habite ce quartier depuis trente et un ans, et je veux apporter une voix un peu moins tranchée que celles qu''on entend depuis le début de ce débat. Non, les caméras ne sont pas l''arme absolue : les études qu''on nous a distribuées montrent qu''elles déplacent souvent les trafics deux rues plus loin, et personne, derrière un écran, n''a jamais consolé une victime. Mais elles ne sont pas non plus le gadget liberticide que dénoncent certains : sous le tunnel de la gare, là où aucune patrouille ne passe après vingt-deux heures, une caméra a permis d''identifier les auteurs de trois agressions l''an dernier. Ce que je conteste, ce n''est donc pas l''outil, c''est l''idée qu''il dispenserait d''embaucher des médiateurs et des îlotiers. Une caméra constate ; elle ne prévient rien. Installons-en aux points aveugles, d''accord, mais à condition de ne pas y consacrer l''argent qui manque déjà à la présence humaine.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''idée principale défendue par le locuteur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les caméras sont inefficaces et doivent être retirées du quartier.<break time="700ms"/>B.<break time="300ms"/>Les caméras peuvent compléter la présence humaine, jamais la remplacer.<break time="700ms"/>C.<break time="300ms"/>La vidéosurveillance a fait disparaître la délinquance près de la gare.<break time="700ms"/>D.<break time="300ms"/>Le quartier doit financer des caméras plutôt que des médiateurs.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Marek écarte les deux camps (« ni arme absolue, ni gadget liberticide ») et formule sa thèse : « ce que je conteste… c''est l''idée qu''il dispenserait d''embaucher des médiateurs », « à condition de ne pas y consacrer l''argent qui manque à la présence humaine ». Il faut **dégager l''idée directrice d''un raisonnement en concession** — B la synthétise : l''outil complète, ne remplace pas. A ne garde que la première concession et oublie l''exemple favorable du tunnel de la gare — confusion entre **un argument partiel et la thèse**. C gonfle ce même exemple : la caméra a permis d''« identifier » des auteurs, pas de faire disparaître la délinquance — d''autant qu''il signale le déplacement des trafics. D inverse exactement sa hiérarchie des priorités, qui place la présence humaine avant l''équipement.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00b-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Idriss, quand je rends une copie notée huit sur vingt, la plupart de mes élèves regardent le chiffre et jamais mes remarques. La note écrase tout : ce que l''élève sait faire, ce qui lui manque, le chemin pour progresser.
[Homme] Je l''entends, Joana, mais pour le père que je suis, ce chiffre reste le seul repère. Les pastilles de couleur de l''école primaire, je ne les ai jamais vraiment déchiffrées. Et au lycée, puis dans le supérieur, les notes reviendront de toute façon : autant que mes filles s''y habituent.
[Femme] C''est pourquoi je ne défends pas leur disparition pure et simple. Pendant l''apprentissage, j''évalue par compétences : l''élève ose se tromper, recommence, progresse sans craindre la sanction. Puis, en fin de trimestre, une note vient valider l''ensemble du parcours. Supprimer la note-couperet quotidienne, oui ; priver les familles et les institutions de tout repère chiffré, non. C''est cette voie médiane que je défendrai jeudi au conseil pédagogique.

Quelle position l''enseignante défend-elle finalement ?

A. Supprimer toute note chiffrée, du collège jusqu''au supérieur.
B. Maintenir la notation quotidienne pour rassurer les familles.
C. Évaluer par compétences au quotidien et noter en fin de trimestre.
D. Laisser chaque famille choisir le mode d''évaluation de ses enfants.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Idriss, quand je rends une copie notée huit sur vingt, la plupart de mes élèves regardent le chiffre et jamais mes remarques. La note écrase tout : ce que l''élève sait faire, ce qui lui manque, le chemin pour progresser.</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je l''entends, Joana, mais pour le père que je suis, ce chiffre reste le seul repère. Les pastilles de couleur de l''école primaire, je ne les ai jamais vraiment déchiffrées. Et au lycée, puis dans le supérieur, les notes reviendront de toute façon : autant que mes filles s''y habituent.</prosody></voice><break time="400ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">C''est pourquoi je ne défends pas leur disparition pure et simple. Pendant l''apprentissage, j''évalue par compétences : l''élève ose se tromper, recommence, progresse sans craindre la sanction. Puis, en fin de trimestre, une note vient valider l''ensemble du parcours. Supprimer la note-couperet quotidienne, oui ; priver les familles et les institutions de tout repère chiffré, non. C''est cette voie médiane que je défendrai jeudi au conseil pédagogique.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle position l''enseignante défend-elle finalement ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Supprimer toute note chiffrée, du collège jusqu''au supérieur.<break time="700ms"/>B.<break time="300ms"/>Maintenir la notation quotidienne pour rassurer les familles.<break time="700ms"/>C.<break time="300ms"/>Évaluer par compétences au quotidien et noter en fin de trimestre.<break time="700ms"/>D.<break time="300ms"/>Laisser chaque famille choisir le mode d''évaluation de ses enfants.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La position finale de Joana est une **« voie médiane » qu''il faut reconstituer à partir de sa dernière réplique** : compétences « pendant l''apprentissage », puis « en fin de trimestre, une note vient valider l''ensemble » — exactement C. A radicalise sa critique initiale en oubliant sa concession explicite (« je ne défends pas leur disparition pure et simple ») — piège entre **première impression et position finale** d''un locuteur qui nuance. B lui prête la conclusion d''Idriss : c''est lui qui tient au chiffre comme « seul repère », elle veut justement supprimer la note-couperet quotidienne. D invente un libre choix des familles que personne n''évoque ; la décision se jouera au conseil pédagogique, instance collective.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00b-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Je m''appelle Yusuf Demir, j''ai vingt-trois ans, et je termine deux années d''engagement dans une maison de retraite de Saint-Étienne ; on me présente donc souvent, sur ce genre de plateau, comme le défenseur naturel du service obligatoire pour tous les jeunes. Je vais peut-être vous surprendre : je ne le suis pas. Non pas que l''engagement m''ait peu apporté, au contraire : j''y ai trouvé un métier, des amis, une confiance que l''école ne m''avait pas donnée. Mais tout cela est né d''un choix. Le matin où je n''avais pas envie d''y aller, c''est ma décision initiale qui me remettait debout, pas la crainte d''une sanction. Rendre le dispositif obligatoire, c''est transformer un élan en corvée, et je vois mal un adolescent contraint apporter autre chose que sa présence physique. Faisons connaître les missions dans tous les lycées, indemnisons-les mieux, levons les obstacles financiers qui découragent les plus modestes — et laissons l''obligation au vestiaire.

Quelle est la position du locuteur ?

A. Il regrette que son engagement lui ait finalement peu apporté.
B. Il réclame des sanctions contre les jeunes qui refusent de s''engager.
C. Il défend l''engagement volontaire mais rejette toute obligation.
D. Il veut réserver ce dispositif aux jeunes en difficulté scolaire.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Je m''appelle Yusuf Demir, j''ai vingt-trois ans, et je termine deux années d''engagement dans une maison de retraite de Saint-Étienne ; on me présente donc souvent, sur ce genre de plateau, comme le défenseur naturel du service obligatoire pour tous les jeunes. Je vais peut-être vous surprendre : je ne le suis pas. Non pas que l''engagement m''ait peu apporté, au contraire : j''y ai trouvé un métier, des amis, une confiance que l''école ne m''avait pas donnée. Mais tout cela est né d''un choix. Le matin où je n''avais pas envie d''y aller, c''est ma décision initiale qui me remettait debout, pas la crainte d''une sanction. Rendre le dispositif obligatoire, c''est transformer un élan en corvée, et je vois mal un adolescent contraint apporter autre chose que sa présence physique. Faisons connaître les missions dans tous les lycées, indemnisons-les mieux, levons les obstacles financiers qui découragent les plus modestes, et laissons l''obligation au vestiaire.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est la position du locuteur ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il regrette que son engagement lui ait finalement peu apporté.<break time="700ms"/>B.<break time="300ms"/>Il réclame des sanctions contre les jeunes qui refusent de s''engager.<break time="700ms"/>C.<break time="300ms"/>Il défend l''engagement volontaire mais rejette toute obligation.<break time="700ms"/>D.<break time="300ms"/>Il veut réserver ce dispositif aux jeunes en difficulté scolaire.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Yusuf déjoue l''attente du plateau (« je vais peut-être vous surprendre : je ne le suis pas ») : il valorise son engagement mais en attribue toute la valeur au choix (« tout cela est né d''un choix », l''obligation « transforme un élan en corvée »). Il faut **distinguer l''adhésion à une pratique du refus de sa généralisation contrainte** — C restitue cette nuance. A contredit frontalement « au contraire : j''y ai trouvé un métier, des amis, une confiance ». B prend le contre-pied de son raisonnement : la sanction est précisément ce qui, selon lui, ne fait pas tenir un engagement. D déforme un **détail autobiographique** (la confiance que l''école ne lui avait pas donnée) en critère d''accès — il propose au contraire d''ouvrir l''information à « tous les lycées ».',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c00b-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Je m''appelle Carmen Ojeda et je modère depuis neuf ans un grand forum d''entraide entre patients ; le débat de ce soir, faut-il interdire l''anonymat sur Internet, me semble mal posé. On voudrait nous faire croire que le pseudonyme fabrique la haine. Mon expérience raconte autre chose : sur mon forum, des femmes décrivent une maladie qu''elles cachent à leur employeur, des adolescents posent les questions qu''ils n''osent poser à personne. Exiger leur vrai nom, ce serait les faire taire, eux, et certainement pas les harceleurs. Car les harceleurs, je les vois aussi : la moitié écrit sous identité réelle, sans la moindre gêne. Le problème n''est donc pas le masque, c''est l''impunité. Aujourd''hui déjà, un juge peut exiger d''une plateforme l''identité qui se cache derrière un pseudonyme ; encore faut-il que la procédure aboutisse en quelques semaines, pas en deux ans. Gardons le pseudonymat, qui protège les plus fragiles, et donnons enfin à la justice les moyens d''identifier rapidement ceux qui en abusent.

Quelle solution la locutrice défend-elle ?

A. Conserver les pseudonymes tout en permettant à la justice d''identifier vite leurs auteurs.
B. Obliger chaque internaute à publier sous son identité réelle.
C. Garantir un anonymat absolu, sans aucune exception possible.
D. Confier aux plateformes le soin de juger elles-mêmes les messages haineux.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Je m''appelle Carmen Ojeda et je modère depuis neuf ans un grand forum d''entraide entre patients ; le débat de ce soir, faut-il interdire l''anonymat sur Internet, me semble mal posé. On voudrait nous faire croire que le pseudonyme fabrique la haine. Mon expérience raconte autre chose : sur mon forum, des femmes décrivent une maladie qu''elles cachent à leur employeur, des adolescents posent les questions qu''ils n''osent poser à personne. Exiger leur vrai nom, ce serait les faire taire, eux, et certainement pas les harceleurs. Car les harceleurs, je les vois aussi : la moitié écrit sous identité réelle, sans la moindre gêne. Le problème n''est donc pas le masque, c''est l''impunité. Aujourd''hui déjà, un juge peut exiger d''une plateforme l''identité qui se cache derrière un pseudonyme ; encore faut-il que la procédure aboutisse en quelques semaines, pas en deux ans. Gardons le pseudonymat, qui protège les plus fragiles, et donnons enfin à la justice les moyens d''identifier rapidement ceux qui en abusent.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle solution la locutrice défend-elle ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Conserver les pseudonymes tout en permettant à la justice d''identifier vite leurs auteurs.<break time="700ms"/>B.<break time="300ms"/>Obliger chaque internaute à publier sous son identité réelle.<break time="700ms"/>C.<break time="300ms"/>Garantir un anonymat absolu, sans aucune exception possible.<break time="700ms"/>D.<break time="300ms"/>Confier aux plateformes le soin de juger elles-mêmes les messages haineux.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La solution se lit dans la double conclusion : « gardons le pseudonymat… et donnons enfin à la justice les moyens d''identifier rapidement ceux qui en abusent » — A en est la paraphrase. Le mécanisme B2 consiste à **reconstituer une position médiane entre deux camps qu''elle renvoie dos à dos**. B est la thèse qu''elle combat : exiger le vrai nom ferait taire les fragiles « et certainement pas les harceleurs ». C durcit son propos en absolu : elle rappelle au contraire qu''« un juge peut exiger d''une plateforme l''identité » — l''exception judiciaire fait partie de sa solution. D déplace le pouvoir de juger vers les plateformes, alors qu''elle confie explicitement l''identification et la sanction **à la justice**, la plateforme ne faisant que fournir l''identité sur réquisition.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 6 items, UUID déterministes 66666666-c00b-1000-0000-000000000001..06.
-- [x] Thème unique « opinion nuancée (débat) », format C exclusif
--     (co_document_question) : 4 monologues d''intervention en débat +
--     2 dialogues denses de débat radiophonique.
-- [x] Longueurs comptées (document parlé hors intro/question/propositions) =
--     156 / 137 / 153 / 153 / 152 / 160 mots — toutes dans 120-200 (B2).
-- [x] 6 situations inventées, toutes différentes : téléphone au collège
--     (Wei Lan, Limoges), vote à 16 ans (Bakary/Inès, dialogue), caméras de
--     quartier (Marek Nowak, débat public), notes à l''école (Joana/Idriss,
--     dialogue), service civique obligatoire (Yusuf Demir, plateau TV),
--     anonymat en ligne (Carmen Ojeda, débat citoyen). Aucun thème interdit
--     (pas de présentation d''organisme, témoignage, chronique, conseil
--     d''expert, enjeu environnemental/économique, etc.).
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes
--     réponses : A ×1, B ×2, C ×2, D ×1 — max 2 par position, 4 positions.
-- [x] Compréhension implicite B2 : position nuancée à reconstruire, point
--     d''accord à inférer, idée principale d''un raisonnement en concession ;
--     pièges = position des adversaires attribuée au locuteur, première
--     impression vs position finale, argument partiel vs thèse, détail
--     secondaire élevé en objectif.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (monologues : 4 <voice>/4 </voice> ; dialogues :
--     7 <voice>/7 </voice> — autant de <prosody> fermées), pauses conformes
--     (1500ms après intro, 400ms entre répliques, 1000ms avant/après la
--     question, 700ms entre propositions, 300ms après la lettre), Denise
--     0.95 + Henri/Vivienne 1.0, voice_recommended = voix principale.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
