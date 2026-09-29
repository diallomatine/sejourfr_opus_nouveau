-- ============================================================================
-- V762 — TCF IRN Expression écrite : exemples dans les bornes de chaque tâche
-- ----------------------------------------------------------------------------
-- Les exemples doivent montrer une réponse réaliste dans le volume demandé,
-- et non suggérer qu'un dépassement est attendu pour atteindre B1 ou B2.
-- Comptage identique au backend : contenu.trim().split("\\s+").length.
-- ============================================================================

UPDATE production_examples
SET contenu = $ee$Salut Karim,

J’ai enfin déménagé dans un appartement près du parc. Il est petit, mais très lumineux, avec deux pièces et un balcon. Le quartier est calme et les commerces sont juste en bas. Es-tu libre samedi prochain ? J’aimerais te montrer mon nouveau logement et prendre un café avec toi.

À bientôt,
Sophie$ee$
WHERE id = 'a1f1e1d1-0001-4a01-9b01-1a1a1a1a0001';

UPDATE production_examples
SET contenu = $ee$Bonjour Léa,

Hier soir, une panne d’électricité a touché tout le quartier. J’étais inquiète, car le chauffage et le téléphone ne fonctionnaient plus. Puis les voisins se sont retrouvés dans la cour avec des bougies. Nous avons discuté et ri ensemble jusqu’au retour du courant. Finalement, j’ai vécu un moment surprenant et chaleureux.

Je t’embrasse,
Inès$ee$
WHERE id = 'a1f1e1d1-0001-4a01-9b01-1a1a1a1a0002';

UPDATE production_examples
SET contenu = $ee$Madame, Monsieur,

Lors de mon séjour du 3 au 5 juin, la chambre était très bruyante et la climatisation est restée en panne malgré mes deux signalements. Ces conditions ne correspondaient pas à votre annonce. Je souhaiterais donc obtenir le remboursement partiel d’une nuit. Je vous remercie de m’indiquer rapidement la suite donnée à ma demande.

Cordialement,
Camille Roussel$ee$
WHERE id = 'a1f1e1d1-0001-4a01-9b01-1a1a1a1a0003';

UPDATE production_examples
SET contenu = $ee$Salut Samir,

Samedi dernier, je suis allé au restaurant avec deux amis pour fêter un anniversaire. Nous avons choisi un petit restaurant italien du centre-ville. J’ai mangé une pizza aux légumes et un tiramisu, tandis que mes amis ont pris des lasagnes. Tout était délicieux et le serveur était très gentil. Nous avons beaucoup parlé et ri. J’ai passé une excellente soirée et j’aimerais y retourner bientôt.

À bientôt !$ee$
WHERE id = 'a1f1e1d1-0002-4a02-9b02-2a2a2a2a0001';

UPDATE production_examples
SET contenu = $ee$Bonjour Nadia,

Il y a deux ans, j’ai travaillé comme animateur dans une colonie de vacances. Au début, j’étais timide et je craignais de ne pas savoir encadrer les enfants. Les premiers jours ont été difficiles, mais j’ai progressivement appris à rester calme, à poser des règles claires et à écouter chacun. À la fin du séjour, un enfant m’a remercié avec émotion. Cette expérience m’a appris que je pouvais dépasser mes peurs, et j’ai aujourd’hui beaucoup plus confiance en moi.

Amicalement,
Yanis$ee$
WHERE id = 'a1f1e1d1-0002-4a02-9b02-2a2a2a2a0002';

UPDATE production_examples
SET contenu = $ee$Bonjour Claire,

À vingt-huit ans, j’occupais un poste stable mais dépourvu de sens. Après plusieurs mois d’hésitation, j’ai décidé de démissionner pour devenir enseignant. Mes proches m’alertaient sur la perte de sécurité financière ; pourtant, je voulais exercer un métier conforme à mes valeurs. Les débuts ont été précaires et fatigants, mais je ne regrette pas ce choix. Aujourd’hui, je me lève avec l’envie de travailler. Cette décision m’a appris qu’un confort qui rend malheureux n’en est pas vraiment un.

À bientôt,
Malik$ee$
WHERE id = 'a1f1e1d1-0002-4a02-9b02-2a2a2a2a0003';

UPDATE production_examples
SET contenu = $ee$Bonjour à tous,

Je préfère vivre en ville pour deux raisons. D’abord, les magasins, les médecins et les transports sont proches, donc la vie quotidienne est plus facile sans voiture. Ensuite, on peut faire beaucoup d’activités : aller au cinéma, pratiquer un sport ou retrouver des amis. La campagne est plus calme et plus verte, mais je choisis la ville parce que j’aime sa vie animée et son côté pratique.$ee$
WHERE id = 'a1f1e1d1-0003-4a03-9b03-3a3a3a3a0001';

UPDATE production_examples
SET contenu = $ee$Bonjour à tous,

À mon avis, il faut limiter le temps d’écran des enfants sans tout interdire. D’abord, trop d’écran nuit au sommeil et à la concentration. Mon neveu dort mieux depuis qu’il laisse sa tablette après le dîner. Ensuite, les vidéos remplacent souvent le sport, la lecture et les jeux avec les autres. Les outils numériques peuvent être utiles pour apprendre, c’est vrai, mais ils doivent rester encadrés. Des règles adaptées à l’âge me semblent donc plus efficaces qu’une interdiction totale.$ee$
WHERE id = 'a1f1e1d1-0003-4a03-9b03-3a3a3a3a0002';

UPDATE production_examples
SET contenu = $ee$Bonjour à tous,

Selon moi, l’intelligence artificielle améliorera l’éducation si elle reste un outil au service des enseignants. Elle peut adapter les exercices au rythme de chaque élève et rendre les cours accessibles partout. Certains craignent toutefois qu’elle affaiblisse l’esprit critique, puisque les élèves pourraient attendre toutes les réponses d’une machine. Cette objection est sérieuse, mais elle justifie surtout un meilleur encadrement : l’école doit apprendre à vérifier et questionner les outils. Le progrès dépendra donc moins de la technologie que de l’usage humain qui en sera fait.$ee$
WHERE id = 'a1f1e1d1-0003-4a03-9b03-3a3a3a3a0003';
