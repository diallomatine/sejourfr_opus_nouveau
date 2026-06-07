-- ============================================================================
-- V871 — TCF CO B2 — lot 09 (thème : bulletin d'information local)
-- ----------------------------------------------------------------------------
-- Brouillons audio CO (B2), format C : bulletin radio local long (~120-200 mots)
-- + question implicite (idée principale, intention du journaliste, conséquence
-- non dite, état d'une situation à inférer). Table audio_question_draft.
-- status='TEXT_VALIDATED', colonnes audio NULL (remplies par le batch admin
-- Azure). Contenu 100% original, radios, villes et journalistes inventés.
-- ============================================================================

INSERT INTO audio_question_draft
  (id, difficulty, competence_code, theme_id, transcript_text, ssml_text, statement, explanation,
   choices, voice_recommended, status, audio_url, audio_duration_sec, audio_voice_used,
   audio_generated_at, batch_id, created_at, audio_validated_at, audio_validated_by,
   rejection_reason)
VALUES
  ('66666666-c009-1000-0000-000000000001', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Il est huit heures, voici le journal de Radio Isle. L''information principale ce matin, c''est bien sûr la fermeture du pont Saint-Front, décidée hier soir en urgence. Lors d''une inspection de routine, les techniciens ont découvert des fissures importantes sur deux piliers de l''ouvrage, construit en mille neuf cent soixante-deux. Par précaution, la circulation est interdite dans les deux sens jusqu''à nouvel ordre, y compris pour les piétons. Conséquence immédiate : les douze mille véhicules qui empruntent chaque jour ce pont doivent passer par le pont des Barris, où de longs ralentissements sont déjà signalés ce matin. Les lignes de bus trois et sept sont déviées, et la mairie conseille à ceux qui le peuvent de reporter leurs déplacements. Une expertise complète est attendue d''ici une dizaine de jours ; elle dira si une simple réparation suffit, ou s''il faudra fermer l''ouvrage pendant plusieurs mois.

Quelle est l''information principale de ce bulletin ?

A. Le pont Saint-Front sera détruit puis reconstruit dans les prochains mois.
B. La fermeture préventive d''un pont perturbe fortement la circulation de la ville.
C. La municipalité a programmé la rénovation complète d''un pont ancien.
D. Les lignes de bus de la ville changent d''itinéraire pour la saison estivale.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Il est huit heures, voici le journal de Radio Isle. L''information principale ce matin, c''est bien sûr la fermeture du pont Saint-Front, décidée hier soir en urgence. Lors d''une inspection de routine, les techniciens ont découvert des fissures importantes sur deux piliers de l''ouvrage, construit en mille neuf cent soixante-deux. Par précaution, la circulation est interdite dans les deux sens jusqu''à nouvel ordre, y compris pour les piétons. Conséquence immédiate : les douze mille véhicules qui empruntent chaque jour ce pont doivent passer par le pont des Barris, où de longs ralentissements sont déjà signalés ce matin. Les lignes de bus trois et sept sont déviées, et la mairie conseille à ceux qui le peuvent de reporter leurs déplacements. Une expertise complète est attendue d''ici une dizaine de jours ; elle dira si une simple réparation suffit, ou s''il faudra fermer l''ouvrage pendant plusieurs mois.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle est l''information principale de ce bulletin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le pont Saint-Front sera détruit puis reconstruit dans les prochains mois.<break time="700ms"/>B.<break time="300ms"/>La fermeture préventive d''un pont perturbe fortement la circulation de la ville.<break time="700ms"/>C.<break time="300ms"/>La municipalité a programmé la rénovation complète d''un pont ancien.<break time="700ms"/>D.<break time="300ms"/>Les lignes de bus de la ville changent d''itinéraire pour la saison estivale.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le bulletin articule une cause (des fissures découvertes lors d''une inspection, une fermeture « décidée hier soir en urgence ») et ses effets (déviations, ralentissements, bus déviés) : l''**idée principale** est la perturbation majeure causée par une fermeture préventive, donc B. A anticipe au-delà du document : l''expertise « dira si une simple réparation suffit », rien n''annonce une démolition — piège de **sur-interprétation**. C inverse la **cause** : la fermeture est une mesure d''urgence consécutive à une inspection, pas une rénovation programmée par la municipalité. D promeut un **détail secondaire** (les lignes trois et sept déviées) au rang d''information principale, et invente un motif saisonnier jamais évoqué.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000002', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Et l''on termine ce journal par une bonne nouvelle, celle que tout Vesoul attendait. La librairie du Lion d''Or, ouverte en mille neuf cent trois et menacée de disparition depuis l''annonce du départ à la retraite de son propriétaire, ne fermera finalement pas. Faute d''acheteur, le rideau devait tomber à la fin du mois. C''était sans compter sur les habitants : en huit semaines, plus de neuf cents d''entre eux ont participé à une collecte qui a réuni cent quatre-vingt mille euros, de quoi permettre à deux jeunes libraires de reprendre les murs et le fonds. Les nouvelles gérantes promettent de conserver le café littéraire du samedi et d''ouvrir un rayon jeunesse. La réouverture est prévue le quinze septembre, après un mois de travaux. Le maire, qui n''a pas mis un centime dans l''opération, a salué, je cite, « une victoire des lecteurs, et seulement des lecteurs ».

Qu''est-ce qui a permis de sauver cette librairie ?

A. Le rachat du commerce par la municipalité.
B. La décision du propriétaire de repousser son départ à la retraite.
C. Une subvention exceptionnelle accordée par la région.
D. Une collecte d''argent organisée par les habitants de la ville.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Et l''on termine ce journal par une bonne nouvelle, celle que tout Vesoul attendait. La librairie du Lion d''Or, ouverte en mille neuf cent trois et menacée de disparition depuis l''annonce du départ à la retraite de son propriétaire, ne fermera finalement pas. Faute d''acheteur, le rideau devait tomber à la fin du mois. C''était sans compter sur les habitants : en huit semaines, plus de neuf cents d''entre eux ont participé à une collecte qui a réuni cent quatre-vingt mille euros, de quoi permettre à deux jeunes libraires de reprendre les murs et le fonds. Les nouvelles gérantes promettent de conserver le café littéraire du samedi et d''ouvrir un rayon jeunesse. La réouverture est prévue le quinze septembre, après un mois de travaux. Le maire, qui n''a pas mis un centime dans l''opération, a salué, je cite, « une victoire des lecteurs, et seulement des lecteurs ».</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Qu''est-ce qui a permis de sauver cette librairie ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le rachat du commerce par la municipalité.<break time="700ms"/>B.<break time="300ms"/>La décision du propriétaire de repousser son départ à la retraite.<break time="700ms"/>C.<break time="300ms"/>Une subvention exceptionnelle accordée par la région.<break time="700ms"/>D.<break time="300ms"/>Une collecte d''argent organisée par les habitants de la ville.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut relier deux informations : « faute d''acheteur, le rideau devait tomber », puis « plus de neuf cents [habitants] ont participé à une collecte » qui a permis à deux libraires de reprendre le commerce — c''est la **mobilisation financière des habitants** qui sauve la librairie, donc D. A inverse l''**acteur** : le maire « n''a pas mis un centime dans l''opération », la citation finale (« une victoire des lecteurs, et seulement des lecteurs ») le martèle. B est un contresens : le départ à la retraite a bien lieu, c''est même la cause de la menace de fermeture. C est plausible mais jamais mentionnée : aucune aide publique n''apparaît dans le bulletin — distracteur qui répondrait à un autre scénario de sauvetage.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": true, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000003', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Sept heures trente sur Radio Adour, et nous commençons par le mouvement social qui touche la collecte des déchets. Les agents du centre technique entament aujourd''hui leur quatrième journée de grève pour demander le remplacement des camions les plus anciens et une révision des tournées de nuit. Résultat, près de quatre cents tonnes d''ordures attendent déjà sur les trottoirs, et l''odeur commence à incommoder les riverains du centre ancien. Pour limiter les dégâts, la communauté d''agglomération a ouvert hier six points de dépôt provisoires, surveillés et vidés deux fois par jour ; la liste est disponible sur notre site. Une réunion de négociation est prévue cet après-midi à dix-sept heures. Selon nos informations, la direction serait prête à avancer le calendrier de renouvellement des véhicules, mais refuse pour l''instant de toucher aux horaires. Les syndicats, eux, annoncent qu''ils consulteront leur base ce soir avant de décider de la suite du mouvement.

Où en est le conflit au moment de ce bulletin ?

A. Il n''est pas réglé, mais une issue est possible grâce aux négociations.
B. La grève est terminée et la collecte reprend dès aujourd''hui.
C. La direction a accepté toutes les revendications des agents.
D. Les habitants n''ont plus aucun moyen de déposer leurs déchets.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Sept heures trente sur Radio Adour, et nous commençons par le mouvement social qui touche la collecte des déchets. Les agents du centre technique entament aujourd''hui leur quatrième journée de grève pour demander le remplacement des camions les plus anciens et une révision des tournées de nuit. Résultat, près de quatre cents tonnes d''ordures attendent déjà sur les trottoirs, et l''odeur commence à incommoder les riverains du centre ancien. Pour limiter les dégâts, la communauté d''agglomération a ouvert hier six points de dépôt provisoires, surveillés et vidés deux fois par jour ; la liste est disponible sur notre site. Une réunion de négociation est prévue cet après-midi à dix-sept heures. Selon nos informations, la direction serait prête à avancer le calendrier de renouvellement des véhicules, mais refuse pour l''instant de toucher aux horaires. Les syndicats, eux, annoncent qu''ils consulteront leur base ce soir avant de décider de la suite du mouvement.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Où en est le conflit au moment de ce bulletin ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Il n''est pas réglé, mais une issue est possible grâce aux négociations.<break time="700ms"/>B.<break time="300ms"/>La grève est terminée et la collecte reprend dès aujourd''hui.<break time="700ms"/>C.<break time="300ms"/>La direction a accepté toutes les revendications des agents.<break time="700ms"/>D.<break time="300ms"/>Les habitants n''ont plus aucun moyen de déposer leurs déchets.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Aucune phrase ne résume explicitement la situation : il faut **inférer l''état du conflit** à partir d''indices — « quatrième journée de grève », réunion « prévue cet après-midi », direction « prête à avancer le calendrier », syndicats qui « consulteront leur base ». Le conflit est en cours mais une sortie se dessine : A. B contredit le présent du bulletin : les agents « entament leur quatrième journée », rien n''annonce une reprise. C déforme une concession partielle : la direction céderait sur les camions mais « refuse pour l''instant de toucher aux horaires » — piège de l''**accord partiel pris pour un accord total**. D est démentie par les six points de dépôt provisoires ouverts par l''agglomération.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000004', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Place au sport, et c''est une page d''histoire qui s''écrit pour le handball local. En s''imposant samedi vingt-neuf à vingt-quatre sur le parquet de Niort, les joueuses de l''Étoile castelroussine ont décroché la montée en deuxième division nationale, une première en cinquante-six ans d''existence du club. Mais derrière la fête, un casse-tête attend déjà les dirigeantes : la salle Jean-Vilar, avec ses six cents places et son éclairage vieillissant, ne répond pas aux exigences de la fédération pour ce niveau de compétition. En attendant les travaux de mise aux normes, qui ne débuteront pas avant le printemps, l''équipe disputera donc ses matchs à domicile... à quarante kilomètres d''ici, dans le palais des sports d''Issoudun. La présidente espère que les supporters feront le déplacement, et rappelle qu''un bus gratuit sera affrété pour chaque rencontre. Premier rendez-vous le sept septembre, face à Besançon.

Pourquoi l''équipe jouera-t-elle ses prochains matchs à Issoudun ?

A. Parce que le club a été sanctionné par la fédération.
B. Parce que les travaux de la salle Jean-Vilar ont déjà commencé.
C. Parce que sa salle actuelle ne respecte pas les normes de la deuxième division.
D. Parce que les supporters sont plus nombreux à Issoudun.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Place au sport, et c''est une page d''histoire qui s''écrit pour le handball local. En s''imposant samedi vingt-neuf à vingt-quatre sur le parquet de Niort, les joueuses de l''Étoile castelroussine ont décroché la montée en deuxième division nationale, une première en cinquante-six ans d''existence du club. Mais derrière la fête, un casse-tête attend déjà les dirigeantes : la salle Jean-Vilar, avec ses six cents places et son éclairage vieillissant, ne répond pas aux exigences de la fédération pour ce niveau de compétition. En attendant les travaux de mise aux normes, qui ne débuteront pas avant le printemps, l''équipe disputera donc ses matchs à domicile... à quarante kilomètres d''ici, dans le palais des sports d''Issoudun. La présidente espère que les supporters feront le déplacement, et rappelle qu''un bus gratuit sera affrété pour chaque rencontre. Premier rendez-vous le sept septembre, face à Besançon.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Pourquoi l''équipe jouera-t-elle ses prochains matchs à Issoudun ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Parce que le club a été sanctionné par la fédération.<break time="700ms"/>B.<break time="300ms"/>Parce que les travaux de la salle Jean-Vilar ont déjà commencé.<break time="700ms"/>C.<break time="300ms"/>Parce que sa salle actuelle ne respecte pas les normes de la deuxième division.<break time="700ms"/>D.<break time="300ms"/>Parce que les supporters sont plus nombreux à Issoudun.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'La cause n''est pas formulée dans la question du journaliste : il faut **relier la montée en division et la phrase clé** — la salle « ne répond pas aux exigences de la fédération pour ce niveau de compétition ». C''est cette non-conformité qui impose de jouer à Issoudun : C. A transforme une contrainte réglementaire en **sanction** : le club n''est pas puni, il est au contraire promu. B inverse la chronologie : les travaux « ne débuteront pas avant le printemps », ils n''ont donc pas commencé — piège sur la **concordance des temps**. D invente une motivation jamais évoquée : le bus gratuit sert précisément à amener les supporters castelroussins jusqu''à Issoudun, pas l''inverse.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000005', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Huit heures à Radio Gascogne, et c''est la découverte dont toute la ville parle. Sur le chantier du futur parking souterrain de la place de la Cathédrale, les pelleteuses ont mis au jour mardi les vestiges de thermes gallo-romains : des bassins, des fragments de mosaïque et un système de chauffage par le sol remarquablement conservé. Comme la loi l''impose, les travaux sont suspendus le temps d''une fouille préventive, confiée à une équipe d''archéologues qui s''installera dès lundi pour au moins quatre mois. La livraison du parking, initialement annoncée pour mars prochain, n''interviendra donc pas avant l''automne, au mieux. La maire, interrogée hier, refuse de parler de mauvaise nouvelle : elle imagine déjà présenter les plus belles pièces au musée municipal, et n''exclut pas d''intégrer une partie des vestiges au parking lui-même, derrière une paroi vitrée. Les automobilistes, eux, devront patienter encore un peu.

Quelle conséquence cette découverte a-t-elle pour le chantier ?

A. Le projet de parking souterrain est définitivement abandonné.
B. La fin des travaux est repoussée de plusieurs mois, le temps des fouilles.
C. Le parking sera finalement transformé en musée municipal.
D. Les travaux vont s''accélérer pour rattraper le retard pris.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Huit heures à Radio Gascogne, et c''est la découverte dont toute la ville parle. Sur le chantier du futur parking souterrain de la place de la Cathédrale, les pelleteuses ont mis au jour mardi les vestiges de thermes gallo-romains : des bassins, des fragments de mosaïque et un système de chauffage par le sol remarquablement conservé. Comme la loi l''impose, les travaux sont suspendus le temps d''une fouille préventive, confiée à une équipe d''archéologues qui s''installera dès lundi pour au moins quatre mois. La livraison du parking, initialement annoncée pour mars prochain, n''interviendra donc pas avant l''automne, au mieux. La maire, interrogée hier, refuse de parler de mauvaise nouvelle : elle imagine déjà présenter les plus belles pièces au musée municipal, et n''exclut pas d''intégrer une partie des vestiges au parking lui-même, derrière une paroi vitrée. Les automobilistes, eux, devront patienter encore un peu.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Quelle conséquence cette découverte a-t-elle pour le chantier ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Le projet de parking souterrain est définitivement abandonné.<break time="700ms"/>B.<break time="300ms"/>La fin des travaux est repoussée de plusieurs mois, le temps des fouilles.<break time="700ms"/>C.<break time="300ms"/>Le parking sera finalement transformé en musée municipal.<break time="700ms"/>D.<break time="300ms"/>Les travaux vont s''accélérer pour rattraper le retard pris.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Il faut combiner deux données : la fouille préventive « pour au moins quatre mois » et la livraison « initialement annoncée pour mars » qui « n''interviendra pas avant l''automne ». La **conséquence à déduire** est un report de plusieurs mois : B. A confond **suspension et abandon** : les travaux sont « suspendus le temps d''une fouille », et la maire évoque déjà la suite du projet. C exagère une simple hypothèse : la maire « n''exclut pas » d''exposer une partie des vestiges derrière une vitre, le parking reste un parking — piège entre **éventualité évoquée et décision actée**. D affirme l''inverse du document : le chantier est à l''arrêt, rien n''annonce une accélération.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": true, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000006', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Homme] Sept heures quarante-cinq, l''heure de prendre des nouvelles du marché hebdomadaire, déplacé depuis deux mois sur le parking des Cordeliers pendant la rénovation de la halle. Souvenez-vous : en juin, les commerçants redoutaient une catastrophe. Un emplacement excentré, moins de passage, pas d''abri en cas de pluie... certains parlaient même de suspendre leur activité jusqu''à la fin des travaux. Deux mois plus tard, le bilan déjoue les pronostics. Selon le comptage réalisé samedi dernier par l''association des commerçants elle-même, la fréquentation n''a reculé que de cinq pour cent, et plusieurs étals, notamment les producteurs de fromage et le poissonnier, disent avoir gagné de nouveaux clients venus des quartiers sud, plus proches du site provisoire. La navette gratuite mise en place entre le centre et le parking y est sans doute pour beaucoup : elle transporte chaque samedi près de trois cents personnes. La halle rénovée doit rouvrir en février.

Que veut montrer le journaliste dans ce reportage ?

A. Que le déplacement du marché s''est finalement mieux passé que prévu.
B. Que les commerçants ont eu raison de craindre le déménagement.
C. Que la rénovation de la halle a pris beaucoup de retard.
D. Que la fréquentation du marché s''est effondrée depuis juin.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">Sept heures quarante-cinq, l''heure de prendre des nouvelles du marché hebdomadaire, déplacé depuis deux mois sur le parking des Cordeliers pendant la rénovation de la halle. Souvenez-vous : en juin, les commerçants redoutaient une catastrophe. Un emplacement excentré, moins de passage, pas d''abri en cas de pluie... certains parlaient même de suspendre leur activité jusqu''à la fin des travaux. Deux mois plus tard, le bilan déjoue les pronostics. Selon le comptage réalisé samedi dernier par l''association des commerçants elle-même, la fréquentation n''a reculé que de cinq pour cent, et plusieurs étals, notamment les producteurs de fromage et le poissonnier, disent avoir gagné de nouveaux clients venus des quartiers sud, plus proches du site provisoire. La navette gratuite mise en place entre le centre et le parking y est sans doute pour beaucoup : elle transporte chaque samedi près de trois cents personnes. La halle rénovée doit rouvrir en février.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que veut montrer le journaliste dans ce reportage ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Que le déplacement du marché s''est finalement mieux passé que prévu.<break time="700ms"/>B.<break time="300ms"/>Que les commerçants ont eu raison de craindre le déménagement.<break time="700ms"/>C.<break time="300ms"/>Que la rénovation de la halle a pris beaucoup de retard.<break time="700ms"/>D.<break time="300ms"/>Que la fréquentation du marché s''est effondrée depuis juin.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'Le reportage est construit sur un **contraste** : les craintes de juin (« les commerçants redoutaient une catastrophe ») contre le bilan actuel (« le bilan déjoue les pronostics », fréquentation quasi stable, nouveaux clients, navette qui fonctionne). L''**intention du journaliste** est de montrer que le déplacement s''est mieux passé qu''annoncé : A. B ne retient que la première moitié du reportage en ignorant le retournement — piège classique du **début pris pour le propos**. C n''est pas évoquée : la réouverture reste annoncée pour février, aucun retard n''est signalé. D contredit le chiffre central : la fréquentation « n''a reculé que de cinq pour cent », ce qui est tout sauf un effondrement.',
   '[{"label": "A", "is_correct": true, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": false, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-HenriNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL),

  ('66666666-c009-1000-0000-000000000007', 'B2', 'co_document_question', '22222222-0000-0000-0000-000000000001',
   'Écoutez le document puis la question. Choisissez la bonne réponse.

[Femme] Il est sept heures, voici votre point d''information spécial. La neige tombée cette nuit sur les hauteurs, jusqu''à trente centimètres par endroits, perturbe fortement la vie du département ce mardi matin. Commençons par ce qui concerne les familles : tous les circuits de ramassage scolaire du département sont suspendus pour la journée, par décision du conseil départemental. Attention, cela ne signifie pas que les établissements sont fermés : collèges et lycées accueillent normalement les élèves qui peuvent s''y rendre par leurs propres moyens, et les absences liées à la météo seront excusées, aucun contrôle n''est prévu aujourd''hui. Côté routes, les axes principaux restent praticables avec des équipements spéciaux, mais plusieurs routes secondaires sont coupées, notamment vers le col de la Croix-Neuve. Les chasse-neige sont à l''œuvre depuis quatre heures du matin. Enfin, sachez que le redoux est annoncé pour demain après-midi : la situation devrait revenir à la normale d''ici jeudi. Prudence sur les routes, et restez à l''écoute.

Que doivent comprendre les parents d''élèves ?

A. Les collèges et les lycées sont fermés pour la journée.
B. Les élèves absents devront fournir un justificatif médical.
C. Les bus scolaires ne circulent pas, mais les établissements restent ouverts.
D. Toutes les routes du département sont impraticables.',
   '<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">Il est sept heures, voici votre point d''information spécial. La neige tombée cette nuit sur les hauteurs, jusqu''à trente centimètres par endroits, perturbe fortement la vie du département ce mardi matin. Commençons par ce qui concerne les familles : tous les circuits de ramassage scolaire du département sont suspendus pour la journée, par décision du conseil départemental. Attention, cela ne signifie pas que les établissements sont fermés : collèges et lycées accueillent normalement les élèves qui peuvent s''y rendre par leurs propres moyens, et les absences liées à la météo seront excusées, aucun contrôle n''est prévu aujourd''hui. Côté routes, les axes principaux restent praticables avec des équipements spéciaux, mais plusieurs routes secondaires sont coupées, notamment vers le col de la Croix-Neuve. Les chasse-neige sont à l''œuvre depuis quatre heures du matin. Enfin, sachez que le redoux est annoncé pour demain après-midi : la situation devrait revenir à la normale d''ici jeudi. Prudence sur les routes, et restez à l''écoute.</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Que doivent comprendre les parents d''élèves ?</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>Les collèges et les lycées sont fermés pour la journée.<break time="700ms"/>B.<break time="300ms"/>Les élèves absents devront fournir un justificatif médical.<break time="700ms"/>C.<break time="300ms"/>Les bus scolaires ne circulent pas, mais les établissements restent ouverts.<break time="700ms"/>D.<break time="300ms"/>Toutes les routes du département sont impraticables.</prosody></voice></speak>',
   'Écoutez le document sonore, puis choisissez la bonne réponse parmi les propositions A, B, C ou D.',
   'L''information utile aux parents est répartie en deux temps qu''il faut **synthétiser** : les circuits de ramassage « sont suspendus pour la journée », mais « cela ne signifie pas que les établissements sont fermés » — donc C. A reprend exactement l''interprétation que la journaliste prend soin d''écarter (« attention, cela ne signifie pas que... ») — piège sur la **négation corrective**, typique du B2. B contredit le bulletin : les absences liées à la météo « seront excusées, aucun contrôle n''est prévu », aucun justificatif n''est demandé. D généralise abusivement : seules « plusieurs routes secondaires sont coupées », les axes principaux « restent praticables » — piège entre **quelques-unes et toutes**.',
   '[{"label": "A", "is_correct": false, "display_order": 1}, {"label": "B", "is_correct": false, "display_order": 2}, {"label": "C", "is_correct": true, "display_order": 3}, {"label": "D", "is_correct": false, "display_order": 4}]',
   'fr-FR-VivienneNeural', 'TEXT_VALIDATED',
   NULL, NULL, NULL, NULL, NULL,
   '2026-06-07 12:00:00+02', NULL, NULL, NULL);

-- ============================================================================
-- CHECKLIST (contrôles passés avant livraison)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes 66666666-c009-1000-0000-000000000001..07.
-- [x] Format C exclusif (co_document_question), bulletin radio local long :
--     longueurs comptées = 143 / 146 / 150 / 140 / 142 / 147 / 156 mots
--     (toutes dans la fourchette 120-200 mots B2).
-- [x] Thème unique « bulletin d''information local », 7 situations inventées et
--     toutes différentes : fermeture d''urgence d''un pont (Périgueux), librairie
--     sauvée par une collecte d''habitants (Vesoul), grève de la collecte des
--     déchets (Bayonne), montée d''un club de handball et salle non conforme
--     (Châteauroux), découverte archéologique sur un chantier de parking (Auch),
--     marché hebdomadaire déplacé pendant travaux (Lons-le-Saunier), épisode
--     neigeux et transports scolaires (Mende). Radios et lieux fictifs ou usage
--     générique ; aucun des thèmes interdits du bon de commande.
-- [x] 4 propositions / 1 correcte par item ; distribution des bonnes réponses :
--     pos1 (A) ×2 (items 3, 6), pos2 (B) ×2 (items 1, 5), pos3 (C) ×2
--     (items 4, 7), pos4 (D) ×1 (item 2) — max 2 par position, 4 positions.
-- [x] Compréhension implicite B2 : idée principale (1), inférence cause/
--     conséquence (2, 4, 5), état d''une situation à inférer (3), intention du
--     journaliste (6), synthèse avec négation corrective (7). Distracteurs tous
--     plausibles : thème vs propos, détail secondaire vs idée principale,
--     inversion cause/effet, sur-interprétation, accord partiel vs total.
-- [x] explanation ≥ 80 caractères, justifie la bonne réponse + les 3
--     distracteurs, point clé en **gras**, mécanisme linguistique nommé.
-- [x] SSML équilibré (4 <voice>/4 </voice>, 4 <prosody>/4 </prosody> par item),
--     pauses conformes (1500ms / 1000ms / 700ms / 300ms), Denise (0.95) en
--     narratrice + Vivienne/Henri (1.0) en alternance V-H-V-H-V-H-V,
--     voice_recommended = voix du document.
-- [x] status='TEXT_VALIDATED', toutes colonnes audio NULL,
--     created_at '2026-06-07 12:00:00+02'.
-- [x] Apostrophes SQL doublées partout, JSONB valide, contenu 100% original.
-- ============================================================================
