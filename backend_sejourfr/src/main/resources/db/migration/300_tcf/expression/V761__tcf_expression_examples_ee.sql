-- ============================================================================
-- V761 — TCF Expression : exemples-modèles EE (Expression écrite)
-- ----------------------------------------------------------------------------
-- Table production_examples (FK -> production_tasks). Réponses modèles EE :
-- texte écrit uniquement, donc PAS d'audio (audio_url NULL, audio_status 'NONE',
-- ssml_text NULL) — cf. ProductionExampleDto : "audioUrl renseigné pour l'EO,
-- NULL pour l'EE". Pendant longtemps seul l'EO (V760) était seedé : l'onglet
-- « Exemples » des tâches EE (web + mobile) revenait donc vide. On ajoute ici
-- 3 modèles par tâche (A2 / B1 / B2), rattachés au sujet EE du niveau
-- correspondant (V700 / V710 / V720). L'endpoint /api/production-examples
-- filtre par (epreuve, tache_numero), pas par niveau : les 3 remontent ensemble.
-- Données déterministes (ids fixes), rejouables dev + recette.
-- ============================================================================

INSERT INTO production_examples
  (id, task_id, titre, resume, contenu, explications, plan_points, niveau_indicatif,
   display_order, audio_status, created_at)
VALUES
  -- ------------------------------------------------------------------------
  -- Tâche 1 — Message court (annoncer / raconter / réclamer)
  -- ------------------------------------------------------------------------
  ('a1f1e1d1-0001-4a01-9b01-1a1a1a1a0001',
   '48b8be40-994f-4afb-b03c-b9a56b670cd1',
   'Annoncer son déménagement à un ami',
   'Un message simple et chaleureux qui annonce le déménagement, décrit le logement et invite l''ami.',
   'Salut Karim,

J''ai une très bonne nouvelle : j''ai enfin déménagé ! J''habite maintenant dans un nouveau quartier, tout près du parc. Mon appartement est petit mais très lumineux : il y a deux pièces, une cuisine équipée et un petit balcon. Le quartier est calme, et il y a des commerces juste en bas de l''immeuble.

Est-ce que tu serais libre un week-end ce mois-ci ? J''aimerais beaucoup te faire visiter mon nouveau chez-moi et prendre un café ensemble. Dis-moi quel jour t''arrange.

À très bientôt,
Sophie',
   'Ce modèle traite les trois consignes dans l''ordre : (1) il annonce la nouvelle, (2) il décrit le logement avec quelques détails concrets (pièces, lumière, balcon) et le quartier, (3) il invite clairement et propose de fixer une date. Au niveau A2, on attend des phrases courtes mais correctes, reliées par des connecteurs simples (« mais », « et », « tout près de »). Remarquez le format message : formule d''ouverture, corps, question, formule de clôture et signature.',
   '["Salutation + annonce du déménagement", "Décrire le logement (pièces, lumière, balcon)", "Décrire le quartier (calme, commerces)", "Inviter pour un week-end", "Proposer de fixer une date + clôture + signature"]',
   'A2', 0, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0001-4a01-9b01-1a1a1a1a0002',
   '84941b89-6ec6-4ae6-91b9-0cc26a83e5df',
   'Raconter une panne d''électricité dans le quartier',
   'Un message qui raconte un événement marquant et explique comment on l''a vécu.',
   'Bonjour Léa,

Je voulais te raconter ce qui s''est passé hier soir chez moi. Vers vingt heures, il y a eu une grosse panne d''électricité dans tout le quartier. D''un coup, plus de lumière, plus de chauffage, et même le réseau du téléphone ne marchait plus très bien.

Au début, j''étais un peu inquiète, parce que je ne savais pas combien de temps cela allait durer. Puis, finalement, c''est devenu un moment plutôt agréable : j''ai allumé des bougies, et je suis descendue discuter avec mes voisins dans la cour. On a ri ensemble et on s''est enfin parlé ! L''électricité est revenue vers minuit.

Au fond, cette panne m''a montré qu''on peut très bien vivre sans écran de temps en temps. Et toi, ça t''est déjà arrivé ?

Je t''embrasse,
Inès',
   'À B1, on attend un récit structuré au passé et l''expression d''un ressenti, pas seulement les faits. Ce modèle situe l''événement dans le temps (« vers vingt heures », « finalement », « vers minuit »), enchaîne les actions au passé composé et à l''imparfait, puis exprime une émotion qui évolue (inquiétude → moment agréable) et tire une petite conclusion personnelle. La question finale relance l''échange, ce qui est naturel dans un message à un proche.',
   '["Ouverture + annonce de ce qu''on va raconter", "Situer l''événement (quand, quoi)", "Raconter le déroulé au passé", "Exprimer le ressenti et son évolution", "Conclusion personnelle + question + clôture"]',
   'B1', 1, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0001-4a01-9b01-1a1a1a1a0003',
   '26b5d842-04c6-46b6-92e2-c324a9c39490',
   'Réclamation courtoise après un séjour décevant',
   'Une lettre de réclamation polie mais ferme : faits précis, demande de compensation, attente claire.',
   'Madame, Monsieur,

Je me permets de vous écrire à la suite du séjour que j''ai passé dans votre hôtel du 3 au 5 juin dernier (réservation n° 48217). Si j''ai apprécié l''accueil du personnel, plusieurs points ne correspondaient malheureusement pas à ce qui était annoncé sur votre site.

La chambre, présentée comme « calme et rénovée », donnait en réalité sur une rue très bruyante, et la climatisation est restée en panne pendant tout mon séjour, malgré mes deux signalements à la réception. Pour un établissement de cette catégorie, cela me paraît difficilement acceptable.

Je souhaiterais donc obtenir un geste commercial à hauteur du préjudice subi, par exemple le remboursement partiel d''une nuit. Je reste naturellement à votre disposition pour en discuter et vous remercie par avance de l''attention que vous porterez à ma demande.

Dans l''attente de votre réponse, je vous prie d''agréer, Madame, Monsieur, mes salutations distinguées.

Camille Roussel',
   'À B2, le registre est formel et la nuance compte : le ton doit rester courtois tout en étant ferme. Ce modèle commence par reconnaître un point positif (l''accueil) avant d''exposer les faits, ce qui crédibilise la plainte. Les reproches sont précis et factuels (référence de réservation, dates, panne signalée deux fois), la demande de compensation est explicite mais raisonnable, et les formules d''ouverture et de clôture respectent les codes de la lettre formelle. Remarquez le conditionnel de politesse (« je souhaiterais »).',
   '["Objet : référence du séjour + dates", "Reconnaître un point positif (crédibilité)", "Exposer les faits précis qui posent problème", "Formuler une demande de compensation claire et raisonnable", "Indiquer son attente + formule de politesse formelle"]',
   'B2', 2, 'NONE', '2026-06-10 10:00:00+02'),

  -- ------------------------------------------------------------------------
  -- Tâche 2 — Récit / description d'une expérience
  -- ------------------------------------------------------------------------
  ('a1f1e1d1-0002-4a02-9b02-2a2a2a2a0001',
   '85ae18b5-b014-426f-a15a-059cae856f8d',
   'Raconter une sortie au restaurant',
   'Un court récit au passé : quand, avec qui, ce qu''on a mangé et si on a aimé.',
   'Samedi dernier, je suis allé au restaurant avec deux amis pour fêter un anniversaire. Nous avons choisi un petit restaurant italien dans le centre-ville, parce que nous adorons les pâtes.

J''ai pris une pizza aux légumes et un tiramisu en dessert. Mes amis ont commandé des lasagnes. Tout était délicieux, et le serveur était très gentil avec nous.

Nous avons beaucoup parlé et beaucoup ri pendant le repas. J''ai passé une très bonne soirée et j''aimerais bien y retourner bientôt.',
   'À A2, le récit reste simple mais doit répondre à toutes les questions de la consigne : quand, avec qui, quoi, et l''appréciation. Ce modèle utilise le passé composé pour les actions (« je suis allé », « j''ai pris », « nous avons parlé ») et donne des détails concrets (le type de restaurant, les plats). La dernière phrase exprime clairement l''avis et un souhait. Des connecteurs simples (« parce que », « et », « pendant ») suffisent à ce niveau.',
   '["Situer : quand + avec qui + pourquoi", "Décrire le lieu choisi", "Dire ce qu''on a mangé", "Donner son appréciation (l''ambiance, le service)", "Conclure (bonne soirée, envie de revenir)"]',
   'A2', 0, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0002-4a02-9b02-2a2a2a2a0002',
   '89436b56-7ebb-4ee9-8504-7677fe1164fe',
   'Une expérience qui m''a appris quelque chose',
   'Un récit structuré : contexte, déroulé, et leçon que l''on en a retirée.',
   'Il y a deux ans, j''ai accepté un travail d''été comme animateur dans une colonie de vacances. À l''époque, j''étais quelqu''un de plutôt timide et je n''avais jamais encadré de groupe. Honnêtement, j''avais un peu peur de ne pas y arriver.

Les premiers jours ont été difficiles : les enfants étaient très énergiques et je ne savais pas comment me faire écouter. Mais petit à petit, j''ai appris à rester calme, à poser des règles claires et surtout à écouter chaque enfant. À la fin du séjour, un petit garçon m''a dit qu''il ne voulait pas partir : ce moment m''a vraiment touché.

Cette expérience m''a appris que je pouvais sortir de ma zone de confort. Depuis, j''ai beaucoup plus confiance en moi, que ce soit dans mes études ou dans ma vie de tous les jours.',
   'À B1, on attend un vrai récit avec une progression et une réflexion personnelle. Ce modèle suit le schéma demandé : le contexte (un premier job, une personnalité timide), le déroulé avec un obstacle puis une évolution (« les premiers jours… mais petit à petit… »), un moment marquant concret, puis la leçon retenue reliée au présent. L''alternance imparfait / passé composé situe bien la durée et les événements ponctuels.',
   '["Poser le contexte (quand, quoi, état d''esprit de départ)", "Décrire la difficulté rencontrée", "Montrer l''évolution / le moment marquant", "Expliquer ce qu''on en a retiré", "Faire le lien avec aujourd''hui"]',
   'B1', 1, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0002-4a02-9b02-2a2a2a2a0003',
   '08e3acd5-c88e-4ba3-8166-520862865128',
   'Une décision difficile et ses conséquences',
   'Un récit nuancé : contexte, cheminement intérieur, et regard porté aujourd''hui sur le choix.',
   'À vingt-huit ans, j''occupais un poste stable et bien payé dans une grande entreprise. Pourtant, je me sentais de plus en plus vide : je faisais chaque jour les mêmes tâches, sans y trouver le moindre sens. C''est là que j''ai pris la décision la plus difficile de ma vie : démissionner pour me reconvertir dans l''enseignement.

Le choix n''a pas été simple. Pendant des mois, j''ai hésité, pesé le pour et le contre, et beaucoup de proches m''ont mis en garde contre la perte de sécurité financière. J''ai fini par me lancer, malgré la peur, parce que je voulais un métier en accord avec mes valeurs.

Avec le recul, je ne regrette absolument pas. Les débuts ont été précaires et fatigants, c''est vrai, mais je me lève aujourd''hui avec l''envie de travailler. Cette décision m''a surtout appris qu''un confort qui rend malheureux n''en est pas vraiment un.',
   'À B2, la consigne demande un récit réflexif : il ne s''agit pas seulement de raconter, mais de montrer un cheminement et un regard rétrospectif. Ce modèle expose la tension de départ (sécurité contre sens), détaille l''hésitation (« pendant des mois », « pesé le pour et le contre »), assume la décision malgré la peur, puis nuance le bilan (« les débuts ont été précaires… mais »). Le lexique est riche et les connecteurs logiques articulent clairement la réflexion.',
   '["Situer le contexte et la tension de départ", "Présenter la décision difficile", "Décrire le cheminement et les hésitations", "Assumer le choix et sa raison profonde", "Porter un regard nuancé aujourd''hui + leçon"]',
   'B2', 2, 'NONE', '2026-06-10 10:00:00+02'),

  -- ------------------------------------------------------------------------
  -- Tâche 3 — Opinion argumentée
  -- ------------------------------------------------------------------------
  ('a1f1e1d1-0003-4a03-9b03-3a3a3a3a0001',
   '7c323ad8-639f-4122-be5c-44badb65b010',
   'Vivre en ville ou à la campagne ?',
   'Une opinion claire défendue par deux raisons simples.',
   'Pour moi, il est préférable de vivre en ville plutôt qu''à la campagne. J''ai deux raisons principales.

D''abord, en ville, tout est plus pratique. Il y a des magasins, des hôpitaux et des transports en commun tout près de chez soi. On peut se déplacer facilement, même sans voiture.

Ensuite, il y a beaucoup plus d''activités. On peut aller au cinéma, au restaurant ou voir des amis facilement. La vie est plus animée et on s''ennuie moins.

Bien sûr, la campagne est plus calme et plus verte. Mais personnellement, je préfère le confort et la vie active de la ville.',
   'À A2, on attend une opinion nettement annoncée et deux raisons clairement séparées. Ce modèle pose la position dès la première phrase, puis utilise des connecteurs d''énumération simples (« d''abord », « ensuite ») pour structurer les deux arguments. La petite concession finale (« bien sûr… mais ») montre une nuance accessible à ce niveau, sans complexité. Les phrases restent courtes et correctes.',
   '["Annoncer son opinion clairement", "Premier argument (côté pratique) + exemple", "Deuxième argument (activités) + exemple", "Petite concession (la campagne est calme)", "Réaffirmer son choix"]',
   'A2', 0, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0003-4a03-9b03-3a3a3a3a0002',
   '67837e55-303b-437a-a513-e8f33125de06',
   'Faut-il limiter le temps d''écran des enfants ?',
   'Une prise de position défendue par deux arguments concrets et un exemple vécu.',
   'À mon avis, il est vraiment nécessaire de limiter le temps d''écran des enfants, même s''il ne faut pas tout interdire.

Premièrement, trop d''écran nuit à la santé et au sommeil. Un enfant qui regarde des vidéos jusque tard le soir dort mal et se concentre moins bien à l''école. Les médecins le répètent souvent.

Deuxièmement, les écrans prennent la place d''autres activités importantes, comme le sport, la lecture ou les jeux avec les amis. Or, c''est aussi comme cela qu''un enfant apprend à vivre avec les autres.

Je le constate dans ma propre famille : depuis que mon neveu n''a plus le droit à la tablette après le dîner, il dort mieux et il lit beaucoup plus. Pour moi, la solution n''est donc pas d''interdire, mais de fixer des règles claires et adaptées à l''âge de l''enfant.',
   'À B1, on attend deux arguments développés (pas seulement énoncés) et au moins un exemple concret. Ce modèle annonce une position nuancée dès le début, structure le raisonnement (« premièrement », « deuxièmement »), justifie chaque argument par une conséquence, puis appuie le propos sur un exemple personnel vérifiable (le neveu). La conclusion reformule la position en proposant une solution équilibrée plutôt qu''un simple « oui / non ».',
   '["Annoncer une position nuancée", "Argument 1 (santé / sommeil) développé", "Argument 2 (autres activités) développé", "Exemple personnel concret", "Conclusion : une solution équilibrée (des règles, pas l''interdiction)"]',
   'B1', 1, 'NONE', '2026-06-10 10:00:00+02'),

  ('a1f1e1d1-0003-4a03-9b03-3a3a3a3a0003',
   '525cc021-4103-4260-8c7b-695f152eea8b',
   'L''IA va-t-elle améliorer ou dégrader l''éducation ?',
   'Une thèse nuancée, deux arguments, et une objection explicitement discutée.',
   'La place grandissante de l''intelligence artificielle dans l''éducation suscite autant d''espoirs que d''inquiétudes. Selon moi, l''IA améliorera l''enseignement à condition qu''elle reste un outil au service des enseignants, et non un substitut.

D''une part, l''IA permet une personnalisation inédite des apprentissages. Un logiciel peut s''adapter au rythme de chaque élève, proposer des exercices ciblés et libérer du temps à l''enseignant pour accompagner ceux qui en ont le plus besoin. D''autre part, elle facilite l''accès au savoir : des millions de personnes éloignées des grandes villes peuvent désormais suivre des cours de qualité.

On pourrait toutefois m''objecter que cette technologie risque d''appauvrir l''esprit critique : à force de demander la réponse à une machine, les élèves cesseraient de réfléchir par eux-mêmes. L''argument est sérieux, mais il dépend surtout de l''usage : c''est précisément le rôle de l''école d''apprendre à questionner les outils plutôt qu''à les subir.

En définitive, l''IA ne dégradera pas l''éducation par nature ; tout dépendra de l''encadrement humain que nous saurons maintenir autour d''elle.',
   'À B2, la consigne exige une thèse nuancée, au moins deux arguments et une objection réellement discutée (pas seulement mentionnée). Ce modèle pose une thèse conditionnelle dès l''introduction (« à condition que… »), développe deux arguments distincts avec des connecteurs d''articulation (« d''une part / d''autre part »), introduit une objection forte (« on pourrait m''objecter que… ») puis y répond au lieu de l''ignorer, et conclut en reprenant la nuance de départ. Le lexique est précis et le raisonnement progresse logiquement.',
   '["Introduire le débat + thèse nuancée", "Argument 1 (personnalisation) développé", "Argument 2 (accès au savoir) développé", "Objection sérieuse explicitement posée", "Réponse à l''objection", "Conclusion qui reprend la nuance"]',
   'B2', 2, 'NONE', '2026-06-10 10:00:00+02');
